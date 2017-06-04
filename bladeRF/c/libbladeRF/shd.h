#ifndef SHD_H
#define SHD_H

#include "bladerf_priv.h"
#include <stdbool.h>

int shd_send_params(struct bladerf *dev,
						uint32_t freq,
						uint8_t freq_index);

int shd_send_control(struct bladerf *dev,
				bool run,
				uint8_t num_freqs);

#endif