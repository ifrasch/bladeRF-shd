/*
bladeRF-shd.c
Top level C file for receiving output samples from bladeRF spectrum holes detector
and writing the samples to a FIFO file.

Compile:
gcc bladeRF-shd.c -o bladeRF-shd -lbladeRF -Wall -Wextra
*/
#include <stdio.h>
#include <stdbool.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>
#include <libbladeRF.h>

#define BUFFER_SIZE 1024*4
#define SAMP_PER_BAND 89
#define MAX_NUM_SAMPLES_RX SAMP_PER_BAND*125
#define INFILE_NAME "freq_table.txt"
#define OUTFILE_NAME "../../../matlab/shd/shd_out.fifo"

struct bladerf *dev = NULL;
int fifo = -1;
FILE *infile = NULL;

void shd_exit(void){
	printf("Exiting...\n");
	if (fifo != -1){
		close(fifo);
	}
	unlink(OUTFILE_NAME);
	if (infile != NULL){
		fclose(infile);
	}
	if (dev != NULL){
		//Disable rx module
		bladerf_enable_module(dev, BLADERF_MODULE_RX, false);
		//Send 'stop' control packet to SHD
		bladerf_shd_send_control(dev, false, 0);
	}
	bladerf_close(dev);
	exit(0);
}

void sig_handler(int sig){
	printf("\n");
	shd_exit();
}

/*
Usage: ./bladeRF-shd [device ID (optional)]
*:serial=xx
*/
int main(int argc, char *argv[]){
	int status;
	uint32_t freq;
	uint8_t freq_index;
	int16_t in_psd_samples[MAX_NUM_SAMPLES_RX*2*sizeof(int16_t)];
	//RX parameter constants
	const uint32_t bandwidth = 28000000;
	const uint32_t samplerate = 40000000;
	const bladerf_lna_gain rx_lna = BLADERF_LNA_GAIN_MAX;
	const int rx_vga1 = 30;
	const int rx_vga2 = 30;
	unsigned int i;
	int nwritten;
	unsigned int num_samples_rx;
	
	//Open outfile
	status = mkfifo(OUTFILE_NAME, 0666);
	if (status != 0){
		perror("mkfifo");
		goto out;
	}
	
	//Register CTRL-C signal handler
	signal(SIGINT, sig_handler);
	
	//Open bladeRF device handle
	if (argc < 2){
		status = bladerf_open(&dev, NULL);
	}else{
		status = bladerf_open(&dev, argv[1]);
	}
	if (status != 0){
		fprintf(stderr, "Couldn't open device handle: %s\n", bladerf_strerror(status));
		goto out;
	}
	//Check if FPGA is loaded
    status = bladerf_is_fpga_configured(dev);
    if (status < 0){
        fprintf(stderr, "Couldn't query FPGA configuration: %s\n",
                bladerf_strerror(status));
        goto out;
    }else if (status == 0){
        fprintf(stderr, "FPGA is not loaded on bladeRF device\n"
						"Please load it with the SHD FPGA bitsream\n");
        goto out;
    }
	
	//set TX frequency to something that will not be within 1 MHz of an RX frequency
	const uint32_t tx_freq = 326000000;
	status = bladerf_set_frequency(dev, BLADERF_MODULE_TX, tx_freq);
	if (status != 0) {
		fprintf(stderr, "Failed to set TX frequency = %u: %s\n",
				tx_freq, bladerf_strerror(status));
		goto out;
	}
	//Set RX parameters
    status = bladerf_set_sample_rate(dev, BLADERF_MODULE_RX, samplerate, NULL);
    if (status != 0) {
        fprintf(stderr, "Failed to set RX samplerate: %s\n", bladerf_strerror(status));
        goto out;
    }
    status = bladerf_set_bandwidth(dev, BLADERF_MODULE_RX, bandwidth, NULL);
    if (status != 0) {
        fprintf(stderr, "Failed to set RX bandwidth: %s\n", bladerf_strerror(status));
        goto out;
    }
	status = bladerf_set_lna_gain(dev, rx_lna);
	if (status != 0) {
		fprintf(stderr, "Failed to set RX LNA gain: %s\n", bladerf_strerror(status));
		goto out;
	}
	status = bladerf_set_rxvga1(dev, rx_vga1);
	if (status != 0) {
		fprintf(stderr, "Failed to set RX VGA1 gain: %s\n", bladerf_strerror(status));
		goto out;
	}
	status = bladerf_set_rxvga2(dev, rx_vga2);
	if (status != 0) {
		fprintf(stderr, "Failed to set RX VGA2 gain: %s\n", bladerf_strerror(status));
		goto out;
	}

	//bladerf_log_set_verbosity(BLADERF_LOG_LEVEL_VERBOSE);

	//Load the frequency table from file
	infile = fopen(INFILE_NAME, "r");
	if (infile == NULL){
		perror("fopen");
		goto out;
	}
	freq_index = 0;
	while(true){
		//get frequency
		status = fscanf(infile, "%u\n", &freq);
		if (status == EOF){
			break;
		}
		//Send the SHD param packet to the Nios II
		status = bladerf_shd_send_params(dev, freq, freq_index);
		if (status != 0){
			fprintf(stderr, "Couldn't send SHD param packet: %s\n",
							bladerf_strerror(status));
			goto out;
		}
		freq_index++;
	}
	printf("Number of SHD frequencies = %hhu\n", freq_index);
	num_samples_rx = freq_index * SAMP_PER_BAND;

	//config synchronous interface for receiving PSD samples
    const unsigned int num_buffers   = 32;
    const unsigned int num_transfers = 16;
    const unsigned int timeout_ms    = 2000;
    status = bladerf_sync_config(dev,
                                 BLADERF_MODULE_RX,
                                 BLADERF_FORMAT_SC16_Q11,
                                 num_buffers,
                                 BUFFER_SIZE,
                                 num_transfers,
                                 timeout_ms);
    if (status != 0) {
        fprintf(stderr, "Failed to configure RX sync interface: %s\n",
                bladerf_strerror(status));
        goto out;
    }
    //Enable RX module
    status = bladerf_enable_module(dev, BLADERF_MODULE_RX, true);
    if (status != 0){
        fprintf(stderr, "Couldn't enable RX module: %s\n", bladerf_strerror(status));
        goto out;
    }
	//Open output FIFO
	printf("Waiting for read process to open output file...\n");
	fifo = open(OUTFILE_NAME, O_WRONLY);
	if (fifo < 0){
		perror("open");
		goto out;
	}
	
	printf("------Press ENTER to run detector...------");
	getchar();
	
	//Send control packet to SHD instructing it to start running
	status = bladerf_shd_send_control(dev, true, freq_index);
	if (status != 0){
		fprintf(stderr, "Couldn't send SHD control packet: %s\n",
				bladerf_strerror(status));
		goto out;
	}
	
	printf("------Press CTRL-C to quit------\n");
	i = 0;
	//Infinite loop to continuously receive SHD output samples
	while (true){
		status = bladerf_sync_rx(dev, in_psd_samples, num_samples_rx, NULL, 2000);
		if (status != 0){
			fprintf(stderr, "Couldn't receive samples for index %u: %s\n", i,
					bladerf_strerror(status));
			goto out;
		}
		//Write to FIFO file
		nwritten = write(fifo, in_psd_samples, num_samples_rx*2*sizeof(int16_t));
		if ((unsigned int)nwritten != num_samples_rx*2*sizeof(int16_t)){
			fprintf(stderr, "Error writing samples for index %u to output file\n", i);
			goto out;
		}
		i++;
	}
	
	out:
		shd_exit();
}