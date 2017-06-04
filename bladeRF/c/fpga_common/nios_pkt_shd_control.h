#ifndef BLADERF_NIOS_PKT_SHD_CONTROL_H_
#define BLADERF_NIOS_PKT_SHD_CONTROL_H_

#ifndef BLADERF_NIOS_BUILD
#   include <libbladeRF.h>
#else
#   include "libbladeRF_nios_compat.h"
#endif

#include <stdint.h>

/* This file defines the Host <-> FPGA (NIOS II) packet format for
 * SHD control packets. This packet is formatted, as follows. All values are
 * little-endian.
 *
 *                              Request
 *                      ----------------------
 *
 * +================+=========================================================+
 * |  Byte offset   |                       Description                       |
 * +================+=========================================================+
 * |        0       | Magic Value                                             |
 * +----------------+---------------------------------------------------------+
 * |        1       | RUN, num_freqs[6:0]  (Note 1)                           |
 * +----------------+---------------------------------------------------------+
 * |     15:2       | Unused (don't care)                                     |
 * +----------------+---------------------------------------------------------+
 * 
 * (Note 1) RUN=1 tells the SHD to begin detecting, RUN=0 tells the SHD to stop
 *			num_freqs is the number of frequencies for the SHD to tune to.
 *          If RUN=0, the num_freqs parameter is unused
 *			The maximum number of frequencies is defined by SHD_MAX_NUM_FREQS in
 *          shd_defines.h.
 */

#define NIOS_PKT_SHD_CONTROL_IDX_MAGIC    0
#define NIOS_PKT_SHD_CONTROL_IDX_NUMFREQ  1

#define NIOS_PKT_SHD_CONTROL_MAGIC        0x81


/* Pack the shd_control buffer with the provided parameters */
static inline void nios_pkt_shd_control_pack(uint8_t *buf,
										bool run,
										uint8_t num_freqs)
{
	buf[NIOS_PKT_SHD_CONTROL_IDX_MAGIC]   = NIOS_PKT_SHD_CONTROL_MAGIC;
	if (run){
		buf[NIOS_PKT_SHD_CONTROL_IDX_NUMFREQ] = (1 << 7);
	}else{
		buf[NIOS_PKT_SHD_CONTROL_IDX_NUMFREQ] = 0x00;
	}
	buf[NIOS_PKT_SHD_CONTROL_IDX_NUMFREQ] |= num_freqs & 0x7f;
}

/* Unpack a SHD control request */
static inline void nios_pkt_shd_control_unpack(const uint8_t *buf,
											bool *run,
											uint8_t *num_freqs)
{
	*run = (buf[NIOS_PKT_SHD_CONTROL_IDX_NUMFREQ] & (1 << 7)) != 0;
	*num_freqs = buf[NIOS_PKT_SHD_CONTROL_IDX_NUMFREQ] & 0x7f;
}

/*
 *                             Response
 *                      ----------------------
 *
 * +================+===========================================+
 * |  Byte offset   |              Description                  |
 * +================+===========================================+
 * |        0       | Magic Value                               |
 * +----------------+-------------------------------------------+
 * |        1       | Status Flags (bit0: 1=success, 0=failure) |
 * +----------------+-------------------------------------------+
 * |      15:2      | Unused (don't care)                       |
 * +----------------+-------------------------------------------+
 *
 */

#define NIOS_PKT_SHD_CONTROLRESP_IDX_MAGIC   0
#define NIOS_PKT_SHD_CONTROLRESP_IDX_STATUS  1

#define NIOS_PKT_SHD_CONTROL_FLAG_SUCCESS    (1 << 0)

static inline void nios_pkt_shd_control_resp_pack(uint8_t *buf,
												bool success)
{
    buf[NIOS_PKT_SHD_CONTROLRESP_IDX_MAGIC] = NIOS_PKT_SHD_CONTROL_MAGIC;
    buf[NIOS_PKT_SHD_CONTROLRESP_IDX_STATUS] = 0x00;
    if (success) {
        buf[NIOS_PKT_SHD_CONTROLRESP_IDX_STATUS] |= NIOS_PKT_SHD_CONTROL_FLAG_SUCCESS;
    }
}

static inline void nios_pkt_shd_control_resp_unpack(const uint8_t *buf,
												bool *success)
{
    if ((buf[NIOS_PKT_SHD_CONTROLRESP_IDX_STATUS] & NIOS_PKT_SHD_CONTROL_FLAG_SUCCESS) != 0){
        *success = true;
    } else {
        *success = false;
    }
}

#endif
