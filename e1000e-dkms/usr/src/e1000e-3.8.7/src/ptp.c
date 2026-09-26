/* ptp.c — stubbed out for kernel 6.x compatibility */
/* PTP/hardware timestamping disabled; not required for basic NIC operation */
#include "e1000.h"

void e1000e_ptp_init(struct e1000_adapter *adapter) { }
void e1000e_ptp_remove(struct e1000_adapter *adapter) { }
void e1000e_ptp_reset(struct e1000_adapter *adapter) { }
void e1000e_ptp_tx_work(struct work_struct *work) { }
void e1000e_ptp_tx_hang(struct e1000_adapter *adapter) { }
void e1000e_ptp_tx_hwtstamp(struct e1000_adapter *adapter) { }
int e1000e_get_base_timinca(struct e1000_adapter *adapter, u32 *timinca) { return 0; }
