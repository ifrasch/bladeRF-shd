#ifndef BLADERF_NIOS_PKT_SHD_PARAMS_H_
#define BLADERF_NIOS_PKT_SHD_PARAMS_H_

#ifndef BLADERF_NIOS_BUILD
#   include <libbladeRF.h>
#else
#   include "libbladeRF_nios_compat.h"
#endif

#include <stdint.h>

/* This file defines the Host <-> FPGA (NIOS II) packet format for
 * SHD parameter packets. This packet is formatted, as follows. All values are
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
 * |        1       | Bit 7:       <Unused> (don't care)                      |
 * |                | Bits [6:0]   Frequency Index (Note 1)                   |
 * +----------------+---------------------------------------------------------+
 * |       7:2      | shd_fparams subpacket (Note 2)                          |
 * +----------------+---------------------------------------------------------+
 * |      15:8      | <Unused> (don't care)                                   |
 * +----------------+---------------------------------------------------------+
 *
 * (Note 1) Represents the index of the list of SHD frequencies where 0 is the
 *  lowest frequency. The maximum possible number of frequencies is equal to
 *  SHD_MAX_NUM_FREQS (defined in shd_defines.h)
 * 
 * (Note 2) Packed as follows:
 *
 * +================+=========================================+
 * |  Byte offset   | (MSB)              Value          (LSB) |
 * +================+=========================================+
 * |       0        | NINT[8:1]                               |
 * +----------------+-----------------------------------------+
 * |       1        | NINT[0], NFRAC[22:16]                   |
 * +----------------+-----------------------------------------+
 * |       2        | NFRAC[15:8]                             |
 * +----------------+-----------------------------------------+
 * |       3        | NFRAC[7:0]                              |
 * +----------------+-----------------------------------------+
 * |       4        | <unused>, LOW_BAND, FREQSEL[5:0]        |
 * +----------------+-----------------------------------------+
 * |       5        | <unused>, VCOCAP[5:0]                   |
 * +----------------+-----------------------------------------+
 *
 * (Note 2) Represents the index of the list of SHD frequencies where 0 is the
 *  lowest frequency. The maximum possible number of frequencies is equal to
 *  SHD_MAX_NUM_FREQS (defined in shd_defines.h)
 *  
 */

#define NIOS_PKT_SHD_PARAMS_MAGIC                0x80

#define SHD_PARAMS_SUBPKT_SIZE			6
#define SHD_PARAMS_SUBPKT_IDX_INTFRAC	0
#define SHD_PARAMS_SUBPKT_IDX_FREQSEL	4
#define SHD_PARAMS_SUBPKT_IDX_VCOCAP	5

#define NIOS_PKT_SHD_PARAMS_IDX_MAGIC     0
#define NIOS_PKT_SHD_PARAMS_IDX_FREQIDX   1
#define NIOS_PKT_SHD_PARAMS_IDX_FPARAMS   2
	#define NIOS_PKT_SHD_PARAMS_IDX_INTFRAC  NIOS_PKT_SHD_PARAMS_IDX_FPARAMS + \
												SHD_PARAMS_SUBPKT_IDX_INTFRAC
	#define NIOS_PKT_SHD_PARAMS_IDX_FREQSEL  NIOS_PKT_SHD_PARAMS_IDX_FPARAMS + \
												SHD_PARAMS_SUBPKT_IDX_FREQSEL
	#define NIOS_PKT_SHD_PARAMS_IDX_VCOCAP   NIOS_PKT_SHD_PARAMS_IDX_FPARAMS + \
												SHD_PARAMS_SUBPKT_IDX_VCOCAP

/* Pack the shd_params buffer with the provided parameters. Handles packing of the
   shd_fparams subpacket */
static inline void nios_pkt_shd_params_pack(uint8_t *buf,
											uint16_t nint,
											uint32_t nfrac,
											uint8_t  freqsel,
											uint8_t  vcocap,
											bool     low_band,
											uint8_t  freq_index)
{
	buf[NIOS_PKT_SHD_PARAMS_IDX_MAGIC]  = NIOS_PKT_SHD_PARAMS_MAGIC;

	buf[NIOS_PKT_SHD_PARAMS_IDX_FREQIDX] = freq_index & 0x7f;

    buf[NIOS_PKT_SHD_PARAMS_IDX_INTFRAC + 0]  = (nint >> 1) & 0xff;
    buf[NIOS_PKT_SHD_PARAMS_IDX_INTFRAC + 1]  = (nint & 0x1) << 7;
    buf[NIOS_PKT_SHD_PARAMS_IDX_INTFRAC + 1] |= ((nfrac >> 16) & 0x7f);
    buf[NIOS_PKT_SHD_PARAMS_IDX_INTFRAC + 2]  = (nfrac >> 8) & 0xff;
    buf[NIOS_PKT_SHD_PARAMS_IDX_INTFRAC + 3]  = nfrac & 0xff;

    if (low_band) {
        buf[NIOS_PKT_SHD_PARAMS_IDX_FREQSEL] = (1 << 6);
    } else {
        buf[NIOS_PKT_SHD_PARAMS_IDX_FREQSEL] = 0x00;
    }
    buf[NIOS_PKT_SHD_PARAMS_IDX_FREQSEL] |= freqsel & 0x3f;

	buf[NIOS_PKT_SHD_PARAMS_IDX_VCOCAP] = vcocap & 0x3f;
}

/* Unpack a SHD parameter request. Leaves the shd_fparams subpacket packed*/
static inline void nios_pkt_shd_params_unpack(const uint8_t *buf,
											uint8_t *freq_index)
{
	*freq_index = buf[NIOS_PKT_SHD_PARAMS_IDX_FREQIDX] & 0x7f;
}

/* Unpack the SHD parameters subpacket */
static inline void nios_pkt_shd_params_subpkt_unpack(const uint8_t *buf,
													uint16_t *nint,
													uint32_t *nfrac,
													uint8_t  *freqsel,
													uint8_t  *vcocap,
													bool     *low_band)
{
    *nint  = buf[SHD_PARAMS_SUBPKT_IDX_INTFRAC + 0] << 1;
    *nint |= buf[SHD_PARAMS_SUBPKT_IDX_INTFRAC + 1] >> 7;

    *nfrac  = (buf[SHD_PARAMS_SUBPKT_IDX_INTFRAC + 1] & 0x7f) << 16;
    *nfrac |= buf[SHD_PARAMS_SUBPKT_IDX_INTFRAC + 2] << 8;
    *nfrac |= buf[SHD_PARAMS_SUBPKT_IDX_INTFRAC + 3];

	*low_band = (buf[SHD_PARAMS_SUBPKT_IDX_FREQSEL] & (1 << 6)) != 0;

    *freqsel = buf[SHD_PARAMS_SUBPKT_IDX_FREQSEL] & 0x3f;

	*vcocap  = buf[SHD_PARAMS_SUBPKT_IDX_VCOCAP] & 0x3f;
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
 * |      2-15      | Unused (don't care)                       |
 * +----------------+-------------------------------------------+
 *
 */

#define NIOS_PKT_SHD_PARAMSRESP_IDX_MAGIC   0
#define NIOS_PKT_SHD_PARAMSRESP_IDX_STATUS  1

#define NIOS_PKT_SHD_PARAMS_FLAG_SUCCESS    (1 << 0)

static inline void nios_pkt_shd_params_resp_pack(uint8_t *buf,
												bool success)
{
    buf[NIOS_PKT_SHD_PARAMSRESP_IDX_MAGIC] = NIOS_PKT_SHD_PARAMS_MAGIC;
    buf[NIOS_PKT_SHD_PARAMSRESP_IDX_STATUS] = 0x00;
    if (success) {
        buf[NIOS_PKT_SHD_PARAMSRESP_IDX_STATUS] |= NIOS_PKT_SHD_PARAMS_FLAG_SUCCESS;
    }
}

static inline void nios_pkt_shd_params_resp_unpack(const uint8_t *buf,
												bool *success)
{
    if ((buf[NIOS_PKT_SHD_PARAMSRESP_IDX_STATUS] & NIOS_PKT_SHD_PARAMS_FLAG_SUCCESS) != 0){
        *success = true;
    } else {
        *success = false;
    }
}

#endif
