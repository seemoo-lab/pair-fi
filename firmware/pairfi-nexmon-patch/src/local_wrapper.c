/***************************************************************************
 *                                                                         *
 *          ###########   ###########   ##########    ##########           *
 *         ############  ############  ############  ############          *
 *         ##            ##            ##   ##   ##  ##        ##          *
 *         ##            ##            ##   ##   ##  ##        ##          *
 *         ###########   ####  ######  ##   ##   ##  ##    ######          *
 *          ###########  ####  #       ##   ##   ##  ##    #    #          *
 *                   ##  ##    ######  ##   ##   ##  ##    #    #          *
 *                   ##  ##    #       ##   ##   ##  ##    #    #          *
 *         ############  ##### ######  ##   ##   ##  ##### ######          *
 *         ###########    ###########  ##   ##   ##   ##########           *
 *                                                                         *
 *            S E C U R E   M O B I L E   N E T W O R K I N G              *
 *                                                                         *
 * This file is part of NexMon.                                            *
 *                                                                         *
 * Copyright (c) 2026 NexMon Team                                          *
 * Copyright (c) 2026 Jakob Link <jlink@seemoo.de>                         *
 *                                                                         *
 * NexMon is free software: you can redistribute it and/or modify          *
 * it under the terms of the GNU General Public License as published by    *
 * the Free Software Foundation, either version 3 of the License, or       *
 * (at your option) any later version.                                     *
 *                                                                         *
 * NexMon is distributed in the hope that it will be useful,               *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of          *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           *
 * GNU General Public License for more details.                            *
 *                                                                         *
 * You should have received a copy of the GNU General Public License       *
 * along with NexMon. If not, see <http://www.gnu.org/licenses/>.          *
 *                                                                         *
 **************************************************************************/

#ifndef LOCAL_WRAPPER_C
#define LOCAL_WRAPPER_C

#include <firmware_version.h>
#include <structs.h>
#include <stdarg.h>

#ifndef LOCAL_WRAPPER_H
    // if this file is not included in the local_wrapper.h file, create dummy functions
    #define VOID_DUMMY { ; }
    #define RETURN_DUMMY { ; return 0; }

    #define AT(CHIPVER, FWVER, ADDR) __attribute__((weak, at(ADDR, "dummy", CHIPVER, FWVER)))
#else
    // if this file is included in the wrapper.h file, create prototypes
    #define VOID_DUMMY ;
    #define RETURN_DUMMY ;
    #define AT(CHIPVER, FWVER, ADDR)
#endif

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0xBFE4)
int
ether_isbcast(void *ea)
RETURN_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x7CE50)
void
phy_ac_rxgcrs_rfctrl_override_rxgain(void *pi, uint8 restore, void *rxgain, void *rxgain_ovrd)
VOID_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x7F8C4)
void
phy_ac_samp_modify_bbmult(void *sampi, uint16 max_val, bool modify_bbmult)
VOID_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x7F978)
uint32
phy_ac_samp_return_spb_depth()
RETURN_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x7F980)
void
phy_ac_samp_run_with_counts(void *pipi, uint16 num_samps, uint8 iqmode, uint16 loops, uint16 wait)
VOID_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x7FB80)
int
phy_ac_samp_stop_playback(void *pi)
RETURN_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x81DE4)
void
phy_ac_txiqlocal_txgain_cleanup(void *pi, void *orig_txgain)
VOID_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x8205C)
void
phy_ac_txiqlocal_poll_samps(void *pi, int16 *samp, bool is_tssi, uint8 log2_nsamps, bool init_adc_inside, uint16 core)
VOID_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x83FC8)
uint8
phy_get_current_core(void *pi)
RETURN_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x87F98)
void
phy_watchdog_resume(void *pi)
VOID_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x87FB8)
void
phy_watchdog_suspend(void *pi)
VOID_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0xA3B84)
int
wlc_getrand(void *wlc, uint8 *buf, int buflen)
RETURN_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0xA6F70)
void
wlc_set_chanspec__local(void *wlc, uint16 chanspec, int reason_bitmap)
VOID_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0xE1C70)
void
wlc_bmac_templatedata_wreg(void *wlc_hw, uint32 word)
VOID_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x110FE0)
int
wlc_iovar_getint(void *wlc, const char *name, int *arg)
RETURN_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x1A2070)
void
phy_ac_chanmgr_resetcca(void *pi)
VOID_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x1A2100)
void
phy_misc_conditional_suspend(void *pi, bool *suspend)
VOID_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x1A2110)
void
phy_misc_conditional_resume(void *pi, bool *suspend)
VOID_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x1A22C0)
void
phy_ac_rxgcrs_get_rxgain(void *pi, void *rxgain, int16 *tot_gain, uint8 force_gain_type)
VOID_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x1A2390)
void
phy_ac_samp_load_table(void *pi, void *tone_buf, uint16 num_samps, bool conj)
VOID_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x1A2490)
void
phy_ac_tpc_get_txgain_settings_by_index(void *pi, void *txgain_settings, int8 txpwrindex)
VOID_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x1A24D0)
void
phy_ac_tpc_by_index(void *pi, uint8 core_mask, int8 txpwrindex)
VOID_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x1A2B40)
int
wl_up(void *wl)
RETURN_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x1A2CE0)
void
wl_down(void *wl)
VOID_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x111064)
int
wlc_iovar_setint(void *wlc, const char *name, int arg)
RETURN_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_ALL, 0x111084)
int
wlc_set(void *wlc, int cmd, int arg)
RETURN_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_20_101_57_r1035009, 0x25ED72)
uint32
phy_ac_tof_read_currptr(void *tofi)
RETURN_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_20_101_57_r1035009, 0x263026)
void
phy_ac_tof_sc(void *pi, bool setup, uint32 sc_start, uint32 sc_stop, bool start)
VOID_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_20_101_57_r1035009, 0x26837C)
void
phy_ac_tpc_enable(void *pi, uint8 ctrl_type)
VOID_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_20_101_57_r1035009, 0x26FD44)
int
phy_samp_capture_disable(void *pi)
RETURN_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_20_101_57_r1035009, 0x27F19C)
void
wl_send_cb(void *lbuf, void *orig_lfrag, void *ctx, bool cancelled)
VOID_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_20_101_57_r1035009, 0x2F4C5A)
bool
wl_tx_pktfetch_required(void *wl, void *wlif, void *bsscfg, void *lb, void *arpi)
RETURN_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_20_101_57_r1035009, 0x27E4DC)
void
wl_tx_pktfetch(void *wl, void *lb, void *src, void *dev, void *bsscfg)
VOID_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_20_101_57_r1035009, 0x359D7E)
int
obj_registry_set(void *wlc_objr, uint key, void *value)
RETURN_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_20_101_57_r1035009, 0x359DA0)
void *
obj_registry_get(void *wlc_objr, uint key)
RETURN_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_20_101_57_r1035009, 0x359DBC)
int
obj_registry_ref(void *wlc_objr, uint key)
RETURN_DUMMY

AT(CHIP_VER_BCM4389c1, FW_VER_20_101_57_r1035009, 0x35C0CC)
void *
wlc_rav_qos_attach(void *wlc)
RETURN_DUMMY

#undef VOID_DUMMY
#undef RETURN_DUMMY
#undef AT

#endif /*LOCAL_WRAPPER_C*/
