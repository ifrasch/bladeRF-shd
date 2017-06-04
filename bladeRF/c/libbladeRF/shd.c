#include "libbladeRF.h"
#include "bladerf_priv.h"
#include "shd.h"
#include "log.h"

#define LMS_REFERENCE_HZ    (38400000u)

#define VCO4_LOW    3800000000ull
#define VCO4_HIGH   4535000000ull
#define VCO3_LOW    VCO4_HIGH
#define VCO3_HIGH   5408000000ull
#define VCO2_LOW    VCO3_HIGH
#define VCO2_HIGH   6480000000ull
#define VCO1_LOW    VCO2_HIGH
#define VCO1_HIGH   7600000000ull
/* SELVCO values */
#define VCO4 (4 << 3)
#define VCO3 (5 << 3)
#define VCO2 (6 << 3)
#define VCO1 (7 << 3)
/* FRANGE values */
#define DIV2  0x4
#define DIV4  0x5
#define DIV8  0x6
#define DIV16 0x7
/* Frequency Range table. Corresponds to the LMS FREQSEL table.
 * Per feedback from the LMS google group, the last entry, listed as 3.72G
 * in the programming manual, can be applied up to 3.8G */
static const struct freq_range {
    uint32_t    low;
    uint32_t    high;
    uint8_t     value;
} freqsel_table[] = {
    {BLADERF_FREQUENCY_MIN,	VCO4_HIGH/16,			VCO4 | DIV16},
    {VCO3_LOW/16,			VCO3_HIGH/16,			VCO3 | DIV16},
    {VCO2_LOW/16,			VCO2_HIGH/16,           VCO2 | DIV16},
    {VCO1_LOW/16,			VCO1_HIGH/16,           VCO1 | DIV16},
    {VCO4_LOW/8,			VCO4_HIGH/8,            VCO4 | DIV8},
    {VCO3_LOW/8,			VCO3_HIGH/8,            VCO3 | DIV8},
    {VCO2_LOW/8,			VCO2_HIGH/8,            VCO2 | DIV8},
    {VCO1_LOW/8,			VCO1_HIGH/8,            VCO1 | DIV8},
    {VCO4_LOW/4,			VCO4_HIGH/4,            VCO4 | DIV4},
    {VCO3_LOW/4,			VCO3_HIGH/4,            VCO3 | DIV4},
    {VCO2_LOW/4,			VCO2_HIGH/4,            VCO2 | DIV4},
    {VCO1_LOW/4,			VCO1_HIGH/4,            VCO1 | DIV4},
    {VCO4_LOW/2,			VCO4_HIGH/2,            VCO4 | DIV2},
    {VCO3_LOW/2,			VCO3_HIGH/2,            VCO3 | DIV2},
    {VCO2_LOW/2,			VCO2_HIGH/2,            VCO2 | DIV2},
    {VCO1_LOW/2,			BLADERF_FREQUENCY_MAX,  VCO1 | DIV2},
};

struct freq_params{
	uint8_t     freqsel;    /**< Choice of VCO and division ratio */
    uint8_t     vcocap;     /**< VCOCAP hint */
    uint16_t    nint;       /**< Integer portion of f_LO given f_REF */
    uint32_t    nfrac;      /**< Fractional portion of f_LO given nint and f_REF */
	bool		low_band;	//True -> use low band, false -> use high band
};

#define VCOCAP_MAX_VALUE 0x3f
#define VCOCAP_EST_MIN 15
#define VCOCAP_EST_MAX 55
#define VCOCAP_EST_RANGE (VCOCAP_EST_MAX - VCOCAP_EST_MIN)
/*
Estimate LMS VCOCAP value for frequency tuning.
Adapted from nuand code which is part of the bladeRF codebase:
fpga_common/src/lms.c -> estimate_vcocap()
*/
uint8_t lms_estimate_vcocap(unsigned int f_target, unsigned int f_low,
							unsigned int f_high)
{
    unsigned int vcocap;
    const float denom = (float) (f_high - f_low);
    const float num = VCOCAP_EST_RANGE;
    const float f_diff = (float) (f_target - f_low);

    vcocap = (unsigned int) ((num / denom * f_diff) + 0.5 + VCOCAP_EST_MIN);

    if (vcocap > VCOCAP_MAX_VALUE){
        vcocap = VCOCAP_MAX_VALUE;
    }
    return (uint8_t) vcocap;
}

/*
Calculate frequency tuning parameters for tuning the LMS6002D
Adapted from nuand code which is part of the bladeRF codebase:
fpga_common/src/lms.c -> lms_calculate_tuning_params()
*/
int calc_tuning_params(uint32_t freq, struct freq_params *params){
    uint64_t vco_x;
    uint64_t temp;
    uint16_t nint;
    uint32_t nfrac;
    uint8_t freqsel;
    uint8_t i = 0;
    const uint64_t ref_clock = LMS_REFERENCE_HZ;

    //check for out of range value
    if (freq < BLADERF_FREQUENCY_MIN || freq > BLADERF_FREQUENCY_MAX) {
		log_critical("Frequency value '%u' is out of range\n", freq);
		return -1;
    }
    //Figure out FREQSEL
    while (i < sizeof(freqsel_table)/sizeof(freqsel_table[0])){
        if ((freq >= freqsel_table[i].low) && (freq <= freqsel_table[i].high)) {
            freqsel = freqsel_table[i].value;
            break;
        }
        i++;
    }
    if (i >= sizeof(freqsel_table)/sizeof(freqsel_table[0])){
        log_critical("Failed to select frequency band\n");
		return -1;
    }
    // Estimate our target VCOCAP value.
    params->vcocap = lms_estimate_vcocap(freq, freqsel_table[i].low, freqsel_table[i].high);
    // Calculate integer portion of the frequency value
    vco_x = ((uint64_t)1) << ((freqsel & 7) - 3);
    temp = (vco_x * freq) / ref_clock;
    assert(temp <= UINT16_MAX);
    nint = (uint16_t)temp;
	//Calculate fractional portion of the frequency value
    temp = (1 << 23) * (vco_x * freq - nint * ref_clock);
    temp = (temp + ref_clock / 2) / ref_clock;
    assert(temp <= UINT32_MAX);
    nfrac = (uint32_t)temp;
	//Assign to output struct
    assert(vco_x <= UINT8_MAX);
    params->nint = nint;
    params->nfrac = nfrac;
    params->freqsel = freqsel;
    assert(ref_clock <= UINT32_MAX);

    if (freq < BLADERF_BAND_HIGH) {
        params->low_band = true;
    }else{
		params->low_band = false;
	}
    return 0;
}

int shd_send_params(struct bladerf *dev,
						uint32_t freq,
						uint8_t freq_index)
{
	struct freq_params fparams;
	int status;
	//calculate tuning parameters
	status = calc_tuning_params(freq, &fparams);
	if (status != 0){
		log_critical("Couldn't calculate tuning parameters\n");
		return BLADERF_ERR_UNEXPECTED;
	}
	log_debug("shd params for frequency %u:\n", freq);
	log_debug("  freqsel = 0x%02x\n", fparams.freqsel);
	log_debug("  vcocap = %u\n", fparams.vcocap);
	log_debug("  nint = %d\n", fparams.nint);
	log_debug("  nfrac = %u\n", fparams.nfrac);
	log_debug("  low_band = %d\n", fparams.low_band);
	log_debug("  index = %d\n", freq_index);
	
	//Write params
	return dev->fn->shd_write_params(dev,
									fparams.nint,
									fparams.nfrac,
									fparams.freqsel,
									fparams.vcocap,
									fparams.low_band,
									freq_index);
}

int shd_send_control(struct bladerf *dev,
				bool run,
				uint8_t num_freqs)
{
	//Send start packet
	return dev->fn->shd_write_control(dev, run, num_freqs);
}
				