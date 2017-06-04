#ifndef SHD_DEFINES_H
#define SHD_DEFINES_H

/*Max number of frequencies for the SHD to tune to. This controls the size of a
memory buffer inside the Nios II RAM which stores all frequency information.
If this is increased beyond 127, more bits must be allocated for the num_frequencies
parameter in nios_pkt_shd_start.h and the freq_index parameter in nios_pkt_shd_params.h
*/
#define SHD_MAX_NUM_FREQS 125

#endif