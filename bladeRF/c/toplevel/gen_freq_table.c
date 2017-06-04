/*Compile:
gcc gen_freq_table.c -o gen_freq_table -Wall -Wextra
*/
#include <stdio.h>
#include <math.h>
#include <unistd.h>
#include <libbladeRF.h>

#define START_FREQ 314000000	//314000000
#define NUM_FREQUENCIES 125		//125
#define BANDWIDTH 28000000

/* Write IQ samples to binary file (for debug)*/
// static int write_bin_sc16q11(char *filename, int16_t *samples, size_t n_samples){
    // size_t nwritten;
	// FILE *outfile = fopen(filename, "wb");
	// if (outfile == NULL){
		// perror("fopen");
	// }
    // nwritten = fwrite(samples, sizeof(int16_t), 2*n_samples, outfile);

	// fclose(outfile);
	// if (nwritten != (2 * n_samples)){
		// return -1;
	// }else{
		// return 0;
	// }
// }

int main(){
	FILE *outfile = NULL;
	int i;
	uint32_t freq;

	//Open outfile
	outfile = fopen("freq_table.txt", "w");
	if (outfile == NULL){
		perror("fopen");
		return 1;
	}
	freq = START_FREQ;
	for (i = 0; i < NUM_FREQUENCIES; i++){
		fprintf(outfile, "%u\n", freq);
		freq += BANDWIDTH;
	}
	fclose(outfile);
	return 0;
}