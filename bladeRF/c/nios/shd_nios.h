#ifndef SHD_NIOS_H
#define SHD_NIOS_H

#include "pkt_handler.h"

void shd_change_frequency(void);
void handle_shd_control_pkt(struct pkt_buf *b);
void handle_shd_params_pkt(struct pkt_buf *b);

#endif