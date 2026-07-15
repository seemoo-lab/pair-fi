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

#pragma NEXMON targetregion "patch"

#include <firmware_version.h>   // definition of firmware version macros
#include <wrapper.h>            // wrapper definitions for functions that already exist in the firmware
#include <structs.h>            // structures that are used by the code in the firmware
#include <helper.h>             // useful helper functions
#include <patcher.h>            // macros used to create patches such as BLPatch, BPatch, ...
#include <nexioctls.h>          // ioctls added in the nexmon patch
#include <local_wrapper.h>
#include <local_structs.h>
#include <pairfi.h>

extern struct pairfi_ctx *pairfi_get_ctx_objr(struct wlc_info *wlc);

uint32 offset = 0;
uint32 mask = 0x3f;
uint8 gain_type = 4;

/* route ioctl to specific core
 * 0: use original caller
 * 2: core 1 (2.4 GHz)
 * 5: core 0 (5 and 6 GHz)
 * 0xf: scan core
 */
uint32 ioctl_mac = 0;

static void
init(struct wlc_info *wlc)
{
    wl_down(wlc->wl);
    wlc_iovar_setint(wlc, "mpc", 0);
    wl_up(wlc->wl);
}

#define IOV_SET                     1
#define WL_TXPWR_OVERRIDE           (1U<<31)
#define PHY_PERICAL_DRIVERUP        1
#define INTERFERE_NONE              0
void
wlc_force_phy_cal(struct wlc_info *wlc)
{
    uint8 wait_ctr = 0;
    int val2;
    wlc_iovar_setint(wlc, "phy_forcecal", PHY_PERICAL_DRIVERUP);
    hnd_delay(1000 * 100);
    wait_ctr = 0;
    while (wait_ctr < 5) {
        wlc_iovar_getint(wlc, "phy_activecal", &val2);
        if (val2 == 0)
            break;
        else
            hnd_delay(1000 * 10);
        wait_ctr++;
    }
    if (wait_ctr == 5) {
        printf("%s: calib fail\n", __func__);
    }
}

void
init_extended(struct wlc_info *wlc)
{
    wl_down(wlc->wl);
    wlc_iovar_setint(wlc, "mpc", 0);
    wlc_iovar_setint(wlc, "obss_coex", 0);
    wlc_iovar_setint(wlc, "stbc_tx", 0);
    wlc_iovar_setint(wlc, "stbc_rx", 0);
    wlc_iovar_setint(wlc, "txbf", 0);
    wlc_set(wlc, WLC_SET_INTERFERENCE_MODE, INTERFERE_NONE);
    wlc_iovar_setint(wlc, "tempsense_disable", 1);
    wlc_iovar_setint(wlc, "ampdu", 0);
    wl_up(wlc->wl);
    wlc_iovar_setint(wlc, "phy_txpwr_ovrinitbaseidx", 1);
    wlc_set(wlc, WLC_SET_PM, 0);
    wlc_force_phy_cal(wlc);
    wlc_iovar_setint(wlc, "phy_percal", 0);
    wlc_iovar_setint(wlc, "phy_txpwrctrl", 1);
}

int
wlc_doioctl_hook(struct wlc_info *wlc, int cmd, char *arg, int len, void *wlc_if)
{
    int ret = IOCTL_ERROR;

    struct wlc_info *wlc_2g;
    struct wlc_info *wlc_5g;
    wlc_rsdb_get_wlcs(wlc, (void **)&wlc_2g, (void **)&wlc_5g);
    wlc = (ioctl_mac == 5) ? wlc_5g : (ioctl_mac == 2) ? wlc_2g : wlc;

    switch (cmd) {

        case NEX_GET_CONSOLE:
        {
            uint32 offset, read_len;
            struct hnd_debug *hnd_debug = (struct hnd_debug *)hnd_debug_info_get();
            if (len >= sizeof(uint32)) {
                offset = *(uint32 *)arg;
                if (offset >= hnd_debug->console->buf_size)
                    break;
                read_len = ((offset + len) >= hnd_debug->console->buf_size) ? (hnd_debug->console->buf_size - offset) : len;
                memcpy(arg, hnd_debug->console->buf + offset, read_len);
                ret = IOCTL_SUCCESS;
            }
            break;
        }

        case 1000: /* choose default band */
        {
            if (len >= sizeof(uint32)) {
                if (*(uint32 *)arg == 5)
                    ioctl_mac = 5;
                else if (*(uint32 *)arg == 2)
                    ioctl_mac = 2;
                else 
                    ioctl_mac = 0;
                ret = IOCTL_SUCCESS;
            }
            break;
        }

        case 1001:
        {
            offset = *(uint32 *)arg;
            ret = IOCTL_SUCCESS;
            break;
        }
        case 1002:
        {
            mask = *(uint32 *)arg;
            ret = IOCTL_SUCCESS;
            break;
        }
        case 1003:
        {
            struct pairfi_ctx *ctx = pairfi_get_ctx_objr(wlc);
            uint32 tmp32 = *(uint32 *)arg;
            ctx->config.txgain_index = (int8)tmp32;
            ret = IOCTL_SUCCESS;
            break;
        }
        case 1004:
        {
            uint32 tmp32 = *(uint32 *)arg;
            gain_type = (uint8)tmp32;
            ret = IOCTL_SUCCESS;
            break;
        }

        default:
            ret = wlc_doioctl(wlc, cmd, arg, len, wlc_if);
    }

    return ret;
}

__attribute__((at(0x34C618, "", CHIP_VER_BCM4389c1, FW_VER_20_101_57_r1035009)))
GenericPatch4(wlc_doioctl_hook, wlc_doioctl_hook + 1);

//__attribute__((at(0x263056, "", CHIP_VER_BCM4389c1, FW_VER_20_101_57_r1035009)))
//__attribute__((naked))
//void
//sc_mode_override(void)
//{
//    asm(
//        //"movs r3,0x14\n" // mode 5 (iq_comp)
//        //"movs r3,0x18\n" // mode 6 (dc_filt)
//        //"movs r3,0x1c\n" // mode 7 (rx_filt) (default)
//        //"movs r3,0x20\n" // mode 8 (rssi) -> that would be cool but it produces 8 values per sample point, which wastes BM space
//       );
//}
