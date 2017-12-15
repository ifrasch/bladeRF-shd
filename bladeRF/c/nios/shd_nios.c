#include <stdbool.h>
#include "nios_pkt_shd_control.h"
#include "nios_pkt_shd_params.h"
#include "shd_defines.h"
#include "devices.h"
#include "band_select.h"
#include "shd_nios.h"

#define CONFIG_REG_SHD_START_BIT (1 << 23)

static bool low_band;
static struct lms_freq f;

static uint8_t num_freqs;
//Index of the next frequency parameters to prepare
static uint8_t freq_index;
static bool shd_run = false;	//initialize to false

uint8_t shd_fparams_list[SHD_MAX_NUM_FREQS*SHD_PARAMS_SUBPKT_SIZE];

/* Tells the FPGA datapath to process samples for the current frequency until done
*/
static inline void pulse_start(void){
	uint32_t control_data;
	//Assert the start bit, (do read-modify-write)
	control_data = control_reg_read();
	control_data |= CONFIG_REG_SHD_START_BIT;
	control_reg_write(control_data);
	//Deassert the start bit
	control_data &= ~CONFIG_REG_SHD_START_BIT;
	control_reg_write(control_data);
}

/* This function is called when the Nios receives a falling edge interrupt
from the SHD state register, meaning the FPGA datapath just completed processing for a
single frequency
*/
void shd_change_frequency(void){
	if (shd_run){
		uint16_t nint;
		uint32_t nfrac;
		uint8_t  freqsel;
		uint8_t  vcocap;
		//set current frequency
		lms_set_precalculated_frequency(NULL, BLADERF_MODULE_RX, &f);
		//select band (low or high)
		band_select(NULL, BLADERF_MODULE_RX, low_band);
		//pulse start
		pulse_start();
		if (freq_index >= num_freqs){
			//reset freq index
			freq_index = 0;
		}
		//Unpack the parameters for the next frequency
		nios_pkt_shd_params_subpkt_unpack(&shd_fparams_list[freq_index*SHD_PARAMS_SUBPKT_SIZE],
											&nint,
											&nfrac,
											&freqsel,
											&vcocap,
											&low_band);
		f.nint = nint;
		f.nfrac = nfrac;
		f.freqsel = freqsel;
		f.vcocap = vcocap;
		f.flags = 0x00;
		if (low_band){
			f.flags |= LMS_FREQ_FLAGS_LOW_BAND;
		}
		freq_index++;
	}
}

void handle_shd_control_pkt(struct pkt_buf *b){
	uint16_t nint;
	uint32_t nfrac;
	uint8_t  freqsel;
	uint8_t  vcocap;
	
	//Store the 'run' bit and number of frequencies tune to
    nios_pkt_shd_control_unpack(b->req, &shd_run, &num_freqs);
	if (shd_run){
		//Unpack and configure the first frequency
		nios_pkt_shd_params_subpkt_unpack(&shd_fparams_list[0],
										&nint,
										&nfrac,
										&freqsel,
										&vcocap,
										&low_band);
		f.nint = nint;
		f.nfrac = nfrac;
		f.freqsel = freqsel;
		f.vcocap = vcocap;
		f.flags = 0x00;
		if (low_band){
			f.flags |= LMS_FREQ_FLAGS_LOW_BAND;
		}
		lms_set_precalculated_frequency(NULL, BLADERF_MODULE_RX, &f);
		//select band
		band_select(NULL, BLADERF_MODULE_RX, low_band);
		//Pulse the 'start' bit to the SHD FPGA datapath
		pulse_start();
		//Unpack the parameters for the next frequency
		nios_pkt_shd_params_subpkt_unpack(&shd_fparams_list[1*SHD_PARAMS_SUBPKT_SIZE],
											&nint,
											&nfrac,
											&freqsel,
											&vcocap,
											&low_band);
		f.nint = nint;
		f.nfrac = nfrac;
		f.freqsel = freqsel;
		f.vcocap = vcocap;
		f.flags = 0x00;
		if (low_band){
			f.flags |= LMS_FREQ_FLAGS_LOW_BAND;
		}
		//Index of next frequency to prepare
		freq_index = 2;
	}
	nios_pkt_shd_start_resp_pack(b->resp, true);
}

void handle_shd_params_pkt(struct pkt_buf *b){
	//Get the frequency index
	nios_pkt_shd_params_unpack(b->req, &freq_index);
	//Copy the shd_fparams subpacket into the list
	memcpy(&shd_fparams_list[freq_index*SHD_PARAMS_SUBPKT_SIZE],
				&(b->req[NIOS_PKT_SHD_PARAMS_IDX_FPARAMS]),
				SHD_PARAMS_SUBPKT_SIZE);
	//Pack response packet
	nios_pkt_shd_params_resp_pack(b->resp, true);
}
