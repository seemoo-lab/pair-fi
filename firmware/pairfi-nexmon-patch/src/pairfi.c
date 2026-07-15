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
#include <patcher.h>            // macros used to create patches such as BLPatch, BPatch, ...
#include <helper.h>
#include <local_wrapper.h>
#include <local_structs.h>
#include <pairfi.h>
#include <registers.h>

/* extern */
extern void prepend_ethernet_ipv4_udp_header(struct sk_buff *p);
extern struct ethernet_ip_udp_header ethernet_ipv4_udp_header;
extern void init_extended(struct wlc_info *wlc);

extern uint32 offset;
extern uint32 mask;
extern uint8 gain_type;

static void pairfi_tx_stop(struct pairfi_ctx *ctx);

const
uint16 byte_to_manchester_table_shm[256] = {
0x5555, // 0x00 -> b01 01 01 01 01 01 01 01
0x5556, // 0x01 -> b01 01 01 01 01 01 01 10
0x5559, // 0x02 -> b01 01 01 01 01 01 10 01
0x555a, // 0x03 -> b01 01 01 01 01 01 10 10
0x5565, // ...
0x5566,
0x5569,
0x556a,
0x5595,
0x5596,
0x5599,
0x559a,
0x55a5,
0x55a6,
0x55a9,
0x55aa,
0x5655,
0x5656,
0x5659,
0x565a,
0x5665,
0x5666,
0x5669,
0x566a,
0x5695,
0x5696,
0x5699,
0x569a,
0x56a5,
0x56a6,
0x56a9,
0x56aa,
0x5955,
0x5956,
0x5959,
0x595a,
0x5965,
0x5966,
0x5969,
0x596a,
0x5995,
0x5996,
0x5999,
0x599a,
0x59a5,
0x59a6,
0x59a9,
0x59aa,
0x5a55,
0x5a56,
0x5a59,
0x5a5a,
0x5a65,
0x5a66,
0x5a69,
0x5a6a,
0x5a95,
0x5a96,
0x5a99,
0x5a9a,
0x5aa5,
0x5aa6,
0x5aa9,
0x5aaa,
0x6555,
0x6556,
0x6559,
0x655a,
0x6565,
0x6566,
0x6569,
0x656a,
0x6595,
0x6596,
0x6599,
0x659a,
0x65a5,
0x65a6,
0x65a9,
0x65aa,
0x6655,
0x6656,
0x6659,
0x665a,
0x6665,
0x6666,
0x6669,
0x666a,
0x6695,
0x6696,
0x6699,
0x669a,
0x66a5,
0x66a6,
0x66a9,
0x66aa,
0x6955,
0x6956,
0x6959,
0x695a,
0x6965,
0x6966,
0x6969,
0x696a,
0x6995,
0x6996,
0x6999,
0x699a,
0x69a5,
0x69a6,
0x69a9,
0x69aa,
0x6a55,
0x6a56,
0x6a59,
0x6a5a,
0x6a65,
0x6a66,
0x6a69,
0x6a6a,
0x6a95,
0x6a96,
0x6a99,
0x6a9a,
0x6aa5,
0x6aa6,
0x6aa9,
0x6aaa,
0x9555,
0x9556,
0x9559,
0x955a,
0x9565,
0x9566,
0x9569,
0x956a,
0x9595,
0x9596,
0x9599,
0x959a,
0x95a5,
0x95a6,
0x95a9,
0x95aa,
0x9655,
0x9656,
0x9659,
0x965a,
0x9665,
0x9666,
0x9669,
0x966a,
0x9695,
0x9696,
0x9699,
0x969a,
0x96a5,
0x96a6,
0x96a9,
0x96aa,
0x9955,
0x9956,
0x9959,
0x995a,
0x9965,
0x9966,
0x9969,
0x996a,
0x9995,
0x9996,
0x9999,
0x999a,
0x99a5,
0x99a6,
0x99a9,
0x99aa,
0x9a55,
0x9a56,
0x9a59,
0x9a5a,
0x9a65,
0x9a66,
0x9a69,
0x9a6a,
0x9a95,
0x9a96,
0x9a99,
0x9a9a,
0x9aa5,
0x9aa6,
0x9aa9,
0x9aaa,
0xa555,
0xa556,
0xa559,
0xa55a,
0xa565,
0xa566,
0xa569,
0xa56a,
0xa595,
0xa596,
0xa599,
0xa59a,
0xa5a5,
0xa5a6,
0xa5a9,
0xa5aa,
0xa655,
0xa656,
0xa659,
0xa65a,
0xa665,
0xa666,
0xa669,
0xa66a,
0xa695,
0xa696,
0xa699,
0xa69a,
0xa6a5,
0xa6a6,
0xa6a9,
0xa6aa,
0xa955,
0xa956,
0xa959,
0xa95a,
0xa965,
0xa966,
0xa969,
0xa96a,
0xa995,
0xa996,
0xa999,
0xa99a,
0xa9a5,
0xa9a6,
0xa9a9,
0xa9aa,
0xaa55,
0xaa56,
0xaa59,
0xaa5a,
0xaa65,
0xaa66,
0xaa69,
0xaa6a,
0xaa95,
0xaa96,
0xaa99,
0xaa9a,
0xaaa5,
0xaaa6,
0xaaa9,
0xaaaa
};

/* decoder block begin */
#define THRESHOLD   80
#define THRESH_SQ   (THRESHOLD*THRESHOLD)
#define MAX_GLITCH  6

int
find_preamble_xcorr(const uint8 *env, int nelem, int slot_samps)
{
    int M = 6 * slot_samps;
    if (nelem < M)
        return -1;
    int16 *templ = mallocz(M * sizeof(*templ));
    if (!templ)
        return -1;
    for (int i = 0; i < M; i++)
        templ[i] = (i < 3*slot_samps) ? +1 : -1;

    int best_idx = -1;
    int best_corr = -2147483648;
    int i, j;
    for (i = 0; i <= nelem - M; i++) {
        int corr = 0;
        for (j = 0; j < M; j++)
            corr += templ[j] * (env[i+j] ? +1 : -1);
        if (corr > best_corr) {
            best_corr = corr;
            best_idx  = i;
        }
    }
    free(templ);
    return best_idx;
}

int
refine_preamble_start(const uint8 *env, int nelem, int rough_p1, int tol_samps)
{
    int lo = rough_p1 - tol_samps;
    int hi = rough_p1 + tol_samps;
    if (lo < 1)
        lo = 1;
    if (hi >= nelem)
        hi = nelem - 1;
    int i;
    for (i = lo; i <= hi; i++) {
        if (env[i-1] == 0 && env[i] == 1)
            return i;
    }
    return rough_p1;
}

int
decode(struct wlc_hw_info *wlc_hw, uint8 *msg, int max_msg_len, uint32 *invalid_slots)
{
    const uint32 nelem = (0x60000-0x10000)/sizeof(cint16);
    const uint32 byte_offset = 0x10000;
    const int Fs = 20000000;
    const int slot_s = (int)(4e-6 * Fs + 0.5); // ~80
    const int tol_s = (int)(1e-6 * Fs + 0.5);  // ~20
    const int margin = slot_s / 10;            // 10 percentage margin
    const int max_off = slot_s - margin;       // on slot minimum samples

    uint8 *env = mallocz(nelem);
    if (!env) {
        printf("%s: env malloc failed\n", __func__);
        return -1;
    }

    /* extract envelope */
    uint32 n;
    uint32 bm_dword;
    uint32 count_on = 0;
    uint32 count_off = 0;
    cint16 *sig = (cint16 *)&bm_dword;
    wlc_bmac_suspend_mac_and_wait(wlc_hw);
    wlc_bmac_templateptr_wreg(wlc_hw, byte_offset);
    for (n = 0; n < nelem; n++) {
        bm_dword = wlc_bmac_templatedata_rreg(wlc_hw);
        int i = sig[0].i, q = sig[0].q;
        env[n] = ((i*i + q*q) > THRESH_SQ) ? 1 : 0;
        (env[n]) ? count_on++ : count_off++;
    }
    wlc_bmac_enable_mac(wlc_hw);

    /* test for minimum preample requirements */
    if (count_off < 5*slot_s) {
        printf("%s: invalid signal\n", __func__);
        if (env)
            free(env);
        return -6;
    }
    if (count_on < 5*slot_s) {
        printf("%s: invalid signal\n", __func__);
        if (env)
            free(env);
        return -7;
    }

    /* glitch smoothing */
    int run_start = 0;
    uint8 curr = env[0];
    int k;
    for (n = 1; n <= nelem; n++) {
        if (n < nelem && env[n] == curr)
            continue;
        int run_len = n - run_start;
        if (run_len <= MAX_GLITCH) {
            uint8 flip_to = run_start>0 ? env[run_start-1] : (curr^1);
            for (k = run_start; k < n; k++)
                env[k] = flip_to;
        }
        if (n < nelem) {
            curr = env[n];
            run_start = n;
        }
    }

    /* find and refine start and stop markers */
    int rough_p1 = find_preamble_xcorr(env, nelem, slot_s);
    if (rough_p1 < 0) {
        printf("%s: start preamble not found\n", __func__);
        if (env)
            free(env);
        return -2;
    }
    int p1 = refine_preamble_start(env, nelem, rough_p1, tol_s);

    int rough_p2 = find_preamble_xcorr(env + p1 + 500, nelem - p1 - 500, slot_s);
    if (rough_p2 < 0) {
        printf("%s: stop marker not found\n", __func__);
        if (env)
            free(env);
        return -3;
    }
    int p2 = refine_preamble_start(env + p1 + 500, nelem - p1 - 500, rough_p2, tol_s) + p1 + 500;

    /* align true end of start preamble */
    int rough_end = p1 + 6*slot_s;
    int best_end = rough_end;
    int best_score = -1;
    int t, i;
    for (t = rough_end - tol_s; t <= rough_end + tol_s; t++) {
        if (t<0 || t+2*slot_s>nelem)
            continue;
        int cntA=0, cntB=0;
        for (i=0;i<slot_s;i++){
            cntA += env[t+i];
            cntB += env[t+slot_s+i];
        }
        int score0 = (slot_s-cntA)+cntB;
        int score1 = cntA+(slot_s-cntB);
        int sc = (score0 > score1) ? score0 : score1;
        if (sc > best_score) {
            best_score=sc;
            best_end=t;
        }
    }
    //printf("%s: DEBUG sample length: %d (%d...%d)\n", __func__, p2 - best_end, best_end, p2);

    /* full-frame adaptive Manchester decode */
    uint32 cur = best_end;
    uint8 val = 0;
    int shift = 0;
    uint8 bit;
    int msg_pos = 0;
    uint32 invalid = 0;
    while (cur + slot_s <= p2) {
        /* predict and find transition */
        int rough_t = cur + slot_s;
        uint32 lo = rough_t - tol_s;
        uint32 hi = rough_t + tol_s;
        if (lo < cur)
            lo = cur;
        if (hi+1 >= nelem)
            hi = nelem-2;

        int t_trans = rough_t;
        for (i = lo; i <= hi; i++) {
            if (env[i] != env[i+1]) {
                t_trans = i+1;
                break;
            }
        }

        /* count in half-slots */
        int lenA = t_trans - cur;
        int cntA=0, cntB=0;
        for (i=cur; i< t_trans; i++)
            cntA += env[i];
        for (i=t_trans; i< t_trans+slot_s; i++)
            cntB += env[i];

        /* decode with margin */
        //bool ok0 = (cntA <= margin) && (cntB >= max_off);
        //bool ok1 = (cntA >= max_off) && (cntB <= margin);
        //if (ok0) {
        //    bit = 0;
        //} else if (ok1) {
        //    bit = 1;
        //} else {
        //    invalid++;
        //    bit = 0;  // placeholder
        //}
        // or more simple:
        if (cntA < lenA/2 && cntB > slot_s/2)
            bit = 0;
        else if (cntA > lenA/2 && cntB < slot_s/2)
            bit = 1;
        else {
            invalid++;
            bit = 0;
        }

        /* pack bits into message */
        val |= (bit << (7-shift));
        shift++;
        if (shift == 8) {
            if (msg) {
                if (msg_pos >= max_msg_len) {
                    printf("%s: output msg buffer too short\n", __func__);
                    if (env)
                        free(env);
                    return -4;
                }
            }
            msg[msg_pos++] = val;
            shift = 0;
            val = 0;
        }

        cur = t_trans + slot_s;
    }

    if (env)
        free(env);

    if (invalid > 0) {
        *invalid_slots = invalid;
        printf("%s: %d invalid slots found\n", __func__, invalid);
        return -5;
    }
    *invalid_slots = 0;

    return msg_pos;
}
/* decoder block end */

/* stall helpers */
static void
disable_stalls(struct phy_info *pi, uint8 *stall_val)
{
    *stall_val = ((phy_reg_read(pi, ACPHY_RxFeCtrl1) & ACPHY_RxFeCtrl1_disable_stalls_MASK) >> ACPHY_RxFeCtrl1_disable_stalls_SHIFT) & 1;
    phy_reg_mod(pi, ACPHY_RxFeCtrl1, ACPHY_RxFeCtrl1_disable_stalls_MASK, 0x1 << ACPHY_RxFeCtrl1_disable_stalls_SHIFT);
}
static void
enable_stalls(struct phy_info *pi, uint8 *stall_val)
{
    phy_reg_mod(pi, ACPHY_RxFeCtrl1, ACPHY_RxFeCtrl1_disable_stalls_MASK, *stall_val << ACPHY_RxFeCtrl1_disable_stalls_SHIFT);
}

/* initialize and start OOK transmission */
static int
pairfi_tx_start(struct pairfi_ctx *ctx, uint8 *msg, size_t msg_len)
{
    struct wlc_info *wlc, *wlc_2g, *wlc_5g;
    struct phy_info *pi;
    uint32 buf_depth;
    uint32 num_samps;
    struct _cint32 *samples;
    uint32 retries = 0;

    wlc_rsdb_get_wlcs(ctx->wlc, (void **)&wlc_2g, (void **)&wlc_5g);
    wlc = ((ctx->config.chanspec & 0xc000) != 0) ? wlc_5g : wlc_2g;
    pi = wlc->pi;

retry:
    /* WAR to prevent tx-cut-off on non-first transmissions */
    pairfi_tx_stop(ctx);

    /* backup current channel */
    ctx->tmp.orig_chanspec = wlc->chanspec;
    /* switch to target channel */
    wlc_set_chanspec__local(wlc, ctx->config.chanspec, 0);

    /* tx power settings */
    int8 index = ctx->config.txgain_index;
    phy_ac_tpc_enable(pi, 0);
    txgain_setting_t gains = { 0 };
    phy_ac_tpc_by_index(pi, (1 << phy_get_current_core(pi)), index);
    phy_ac_tpc_get_txgain_settings_by_index(pi, &gains, index);
    phy_ac_txiqlocal_txgain_cleanup(pi, &gains);

    /* prepare phy */
    disable_stalls(pi, &ctx->tmp.stall_val);
    ctx->tmp.fineclockgatecontrol = phy_reg_read(pi, ACPHY_fineclockgatecontrol);
    phy_reg_mod(pi, ACPHY_fineclockgatecontrol, ACPHY_fineclockgatecontrol_forceRfSeqgatedClksOn_MASK, 1 << ACPHY_fineclockgatecontrol_forceRfSeqgatedClksOn_SHIFT);

    /* pause PSM */
    phy_misc_conditional_suspend(pi, &ctx->tmp.suspend);

    /* go deaf */
    phy_rxgcrs_stay_in_carriersearch(pi->rxgcrs, 1);

    /* config low/high sample index and numbers into SHM for D11 */
    wlc_write_shm(wlc, M_OOK_N_LOW, LOW_SAMPS-1);
    wlc_write_shm(wlc, M_OOK_LOW_IDX, 0);
    wlc_write_shm(wlc, M_OOK_N_HIGH, HIGH_SAMPS-1);
    wlc_write_shm(wlc, M_OOK_HIGH_IDX, LOW_SAMPS);

    /* write manchester encoded message into SHM for D11 */
    wlc_write_shm(wlc, M_OOK_MSG_LEN, msg_len);
    size_t i;
    for (i = 0; i < msg_len; i++) {
        wlc_write_shm(wlc, M_OOK_MSG(i), byte_to_manchester_table_shm[(size_t)msg[i]]);
    }

    /* fill SPB with random samples (low and high) */
    buf_depth = phy_ac_samp_return_spb_depth();
    num_samps = buf_depth;
    if (!(samples = (struct _cint32 *)mallocz(sizeof(struct _cint32) * num_samps))) {
        printf("%s: uuugh, ran into problems allocating sample buffer, canceling tx\n", __func__);
        return -1;
    }
    wlc_getrand(wlc, (uint8 *)samples, sizeof(struct _cint32) * num_samps);
    int j;
    int sign_i, sign_q;
    for (j = 0; j < num_samps; j++) {
        if (j < LOW_SAMPS) {
            samples[j].i = 0;
            samples[j].q = 0;
        } else {
            samples[j].i = (samples[j].i << offset) & mask;
            samples[j].q = (samples[j].q << offset) & mask;
        }
    }
    phy_reg_write(pi, ACPHY_sampleCmd, 0x0000);
    phy_ac_samp_load_table(pi, samples, num_samps, 0);
    if (samples) {
        free(samples);
        samples = 0;
    }

    /* indicate tx active as from here there is no going back */
    ctx->tx_active = 1;

    /* reset play from SPB control register */
    phy_reg_write(pi, ACPHY_sampleCmd, 0x0000); // Nshift 0
    /* enable OOK process in D11 */
    wlc_write_shm(wlc, M_OOK_ENABLE, 1);
    /* kick-off play from SPB */
    phy_ac_samp_run_with_counts(&pi, LOW_SAMPS, 0, 0xffff, 0);
    /* wake up PSM */
    phy_misc_conditional_resume(pi, &ctx->tmp.suspend);

    /* check if transmission failed to kick off based on tssi, retry N times otherwise */
    int16 samp = 0;
    bool is_tssi = 1;
    uint8 log2_nsamps = 10;
    bool init_adc_inside = 0;
    uint16 core = 0;
    phy_ac_txiqlocal_poll_samps(pi, &samp, is_tssi, log2_nsamps, init_adc_inside, core);
    if (samp > -120 && samp < -1) {
        //printf("%s: tssi %d, indicating tx active\n", __func__, samp);
    } else if (samp <= -120) {
        retries++;
        printf("%s: tssi %d, indicating tx failure, run %d\n", __func__, samp, retries);
        if (retries < 10)
            goto retry;
    } else {
        printf("%s: tssi %d, not expected..\n", __func__, samp);
    }

    return 0;
}

/* stop running OOK transmission */
static void
pairfi_tx_stop(struct pairfi_ctx *ctx)
{
    struct wlc_info *wlc, *wlc_2g, *wlc_5g;
    struct phy_info *pi;

    wlc_rsdb_get_wlcs(ctx->wlc, (void **)&wlc_2g, (void **)&wlc_5g);
    wlc = ((ctx->config.chanspec & 0xc000) != 0) ? wlc_5g : wlc_2g;
    pi = wlc->pi;

    phy_reg_or(pi, ACPHY_sampleCmd, ACPHY_sampleCmd_stop_MASK);

    /* tell D11 to stop OOK process */
    wlc_write_shm(wlc, M_OOK_STOP, 1);
    /* spin until D11 is done stopping */
    while (wlc_read_shm(wlc, M_OOK_ENABLE)) {
        /* TODO: add timeout */
        hnd_delay(10);
    }

    /* exit deaf */
    phy_rxgcrs_stay_in_carriersearch(pi->rxgcrs, 0);

    /* clear play from SPB */
    phy_misc_conditional_suspend(pi, &ctx->tmp.suspend);
    phy_ac_samp_stop_playback(pi);
    phy_misc_conditional_resume(pi, &ctx->tmp.suspend);

    /* restore phy */
    phy_reg_write(pi, ACPHY_fineclockgatecontrol, ctx->tmp.fineclockgatecontrol);
    enable_stalls(pi, &ctx->tmp.stall_val);

    /* re-init */
    init_extended(wlc);

    /* restore original chanspec */
    wlc_set_chanspec__local(wlc, ctx->tmp.orig_chanspec, 0);
    ctx->tmp.orig_chanspec = 0;

    /* indicate tx free */
    ctx->tx_active = 0;
}

/* extend object registry count by 1 to make space for pairfi context */
__attribute__((at(0x34A38C, "", CHIP_VER_BCM4389c1, FW_VER_20_101_57_r1035009)))
GenericPatch1(objr_increase_max_count, 0x7E)

/* get pairfi context from object registry */
struct pairfi_ctx *
pairfi_get_ctx_objr(struct wlc_info *wlc)
{
    return (struct pairfi_ctx *)wlc->objr->objr->value[OBJR_PAIRFI_CTX];
}

/* create pairfi context, init and add to object registry */
static void
pairfi_attach(struct wlc_info *wlc)
{
    void *pairfi_ctx = (void *)obj_registry_get(wlc->objr, OBJR_PAIRFI_CTX);
    if (!pairfi_ctx) {
        if ((pairfi_ctx = mallocz(sizeof(struct pairfi_ctx))) == 0) {
            printf("%s: failed to alloc pairfi context\n", __func__);
        } else {
            printf("%s: created pairfi context @0x%08x\n", __func__, pairfi_ctx);
        }
        obj_registry_set(wlc->objr, OBJR_PAIRFI_CTX, pairfi_ctx);
        /* default values */
        ((struct pairfi_ctx *)pairfi_ctx)->wlc = wlc;
        ((struct pairfi_ctx *)pairfi_ctx)->pending_seq_num = -1;
        ((struct pairfi_ctx *)pairfi_ctx)->config.chanspec = 0xd09d; //157/20
        ((struct pairfi_ctx *)pairfi_ctx)->config.txgain_index = 0;
    }
    (void)obj_registry_ref(wlc->objr, OBJR_PAIRFI_CTX);
}

/* add pairfi attach to the very end of wlc_attach_module process */
void *
wlc_rav_qos_attach__hook(struct wlc_info *wlc)
{
    void *ret = wlc_rav_qos_attach(wlc);
    pairfi_attach(wlc);
    return ret;
}
__attribute__((at(0x34C2DE, "", CHIP_VER_BCM4389c1, FW_VER_20_101_57_r1035009)))
BLPatch(wlc_rav_qos_attach__hook, wlc_rav_qos_attach__hook)

/* add ethernet/ip/udp to input buffer and sendup to host */
static void
pairfi_msg_sendup(struct pairfi_ctx *ctx, void *msg, size_t msg_len)
{
    struct wl_info *wl = ctx->msg_handler.wl;
    struct sk_buff *pkt = (struct sk_buff *)hnd_pkt_get(wl->osh, sizeof(struct ethernet_ip_udp_header) + msg_len);
    if (!pkt) {
        printf("%s: failed to get pkt memory (%d bytes)\n", __func__, sizeof(struct ethernet_ip_udp_header) + msg_len);
        return;
    }
    ethernet_ipv4_udp_header.udp.src_port = HTONS(ctx->msg_handler.src_port);
    ethernet_ipv4_udp_header.udp.dst_port = HTONS(ctx->msg_handler.dst_port);
    skb_pull(pkt, sizeof(struct ethernet_ip_udp_header));
    memcpy(pkt->data, msg, msg_len);
    prepend_ethernet_ipv4_udp_header(pkt);
    if (wl->dev->chained->ops->xmit(wl->dev, wl->dev->chained, pkt)) {
        printf("%s: failed to transmit pkt from dongle to host\n", __func__);
        hnd_pkt_free(wl->osh, pkt, 0);
    }
}

/* generate a pairfi ping message and sendup to host */
void
pairfi_msg_send_ping(struct pairfi_ctx *ctx)
{
    uint8 seq_number;

    if (ctx->msg_handler.active) {
        printf("%s: pairfi msg handling in progress, canceling ping request\n", __func__);
        return;
    }

    if (!ctx->wlc) {
        printf("%s: no wlc in pairfi ctx, canceling ping request\n", __func__);
        return;
    }

    wlc_getrand(ctx->wlc, &seq_number, sizeof(seq_number));
    ctx->msg_handler.active = 1;
    struct pairfi_ping_pong pspp = {.msg.type = PS_PING, .seq_number = seq_number};
    ctx->pending_seq_num = seq_number;
    pairfi_msg_sendup(ctx, &pspp, sizeof(pspp));
    ctx->msg_handler.active = 0;
}

/* process pairfi messages that are in TLV format */
static void
pairfi_msg_handler_tlv(struct pairfi_ctx *ctx, struct pairfi_tlv *msg, size_t len)
{
    enum pairfi_messages msg_type;
    struct wlc_info *wlc_2g, *wlc_5g;
    struct wlc_info *wlc;
    struct phy_info *pi;

    if (len < sizeof(struct pairfi_tlv)) {
        printf("%s: pairfi message expecting TLV but payload too short\n", __func__);
        return;
    }

    if (len - sizeof(struct pairfi_tlv) < msg->length) {
        printf("%s: pairfi TLV message length field mismatches actual data length\n", __func__);
        return;
    }

    msg_type = msg->msg.type;
    switch(msg_type) {
        case PS_TX_START:
            printf("%s: PS_TX_START\n", __func__);
            if (pairfi_tx_start(ctx, msg->data, msg->length) != 0) {
                printf("%s: PS_TX_START error\n", __func__);
            }
            break;
        case PS_CONFIG:
            printf("%s: PS_CONFIG\n", __func__);
            printf("%s: PS_CONFIG not implemented yet\n", __func__);
            break;
        default:
            printf("%s: unknown pairfi message type 0x%02x\n", __func__, msg_type);
            return;
    }
}

/* handle pairfi messages that are either ping or pong */
static void
pairfi_msg_handler_ping_pong(struct pairfi_ctx *ctx, struct pairfi_ping_pong *msg, size_t len)
{
    enum pairfi_messages msg_type;
    uint8 seq_number;
    struct pairfi_ping_pong pspp = { .msg.type = 0, .seq_number = 0};

    if (len < sizeof(struct pairfi_ping_pong)) {
        printf("%s: pairfi message expecting sequence number but payload too short\n", __func__);
        return;
    }

    msg_type = msg->msg.type;
    seq_number = msg->seq_number;

    switch(msg_type) {
        case PS_PING:
            pspp.msg.type = PS_PONG;
            pspp.seq_number = seq_number;
            pairfi_msg_sendup(ctx, &pspp, sizeof(pspp));
            break;
        case PS_PONG:
            if (ctx->pending_seq_num != -1) {
                if (msg->seq_number == ctx->pending_seq_num) {
                    printf("%s: got pong for pending ping 0x%01x\n", __func__, msg->seq_number);
                    ctx->pending_seq_num = -1;
                } else {
                    printf("%s: got non-exptected pong 0x%01x\n", __func__, msg->seq_number);
                }
            } else {
                printf("%s: got out-of-context pong 0x%01x\n", __func__, msg->seq_number);
            }
            break;
        default:
            printf("%s: unknown pairfi message type 0x%02x\n", __func__, msg_type);
            return;
    }
}

static int
pairfi_rx_next(struct pairfi_ctx *ctx)
{
    struct wlc_info *wlc, *wlc_2g, *wlc_5g;
    struct phy_info *pi;
    struct phy_ac_info *pi_acphy;
    void *tofi;
    size_t i;

    uint32 start_index = 0x4000; // we loose 819.2us but get less interference
    uint32 stop_index = 0x17fff; // full BM for 5 GHz

    wlc_rsdb_get_wlcs(ctx->wlc, (void **)&wlc_2g, (void **)&wlc_5g);
    wlc = ((ctx->config.chanspec & 0xc000) != 0) ? wlc_5g : wlc_2g;
    pi = wlc->pi;
    pi_acphy = (struct phy_ac_info *)pi->pi_acphy;
    tofi = pi_acphy->tofi;

    /* backup current channel */
    ctx->tmp.orig_chanspec = wlc->chanspec;
    /* switch to target channel */
    wlc_set_chanspec__local(wlc, ctx->config.chanspec, 0);

    /* do CCA reset -> clears FIFOs? */
    phy_ac_chanmgr_resetcca(pi);
        
    /* prepare phy */
    disable_stalls(pi, &ctx->tmp.stall_val);
    ctx->tmp.fineclockgatecontrol = phy_reg_read(pi, ACPHY_fineclockgatecontrol);
    phy_reg_mod(pi, ACPHY_fineclockgatecontrol, ACPHY_fineclockgatecontrol_forceRfSeqgatedClksOn_MASK, 1 << ACPHY_fineclockgatecontrol_forceRfSeqgatedClksOn_SHIFT);

    /* disable PHY watchdog */
    phy_watchdog_suspend(pi);
    /* pause PSM */
    phy_misc_conditional_suspend(pi, &ctx->tmp.suspend);

    /* clear BM */
    wlc_bmac_templateptr_wreg(wlc->hw, start_index<<2);
    for (i = stop_index-start_index; i < stop_index; i++) {
        wlc_bmac_templatedata_wreg(wlc->hw, 0);
    }

    /* go deaf to prevent AGC messing with the raw capture */
    phy_rxgcrs_stay_in_carriersearch(pi->rxgcrs, 1);

    /* rx gain settings */
    uint8 rxgain[16];
    uint8 rxgain_ovrd[16];
    uint8 force_gain_type = gain_type;
    uint16 tot_gain;
    phy_ac_rxgcrs_get_rxgain(pi, rxgain, &tot_gain, force_gain_type);
    phy_ac_rxgcrs_rfctrl_override_rxgain(pi, 0, rxgain, rxgain_ovrd);

    /* kick off raw sample collection */
    phy_reg_write(pi, ACPHY_AdcDataCollect, ACPHY_AdcDataCollect_adcDataCollectEn_MASK);
    phy_ac_tof_sc(pi, 1, start_index, stop_index, 1);
    i = 5000;
    do {
        hnd_delay(1);
        if (!--i) {
            printf("%s: raw IQ rx timeout\n", __func__);
            break;
        }
    } while (phy_ac_tof_read_currptr(tofi) != stop_index);

    /* reset raw sample collection */
    phy_samp_capture_disable(pi);

    /* exit deaf */
    phy_rxgcrs_stay_in_carriersearch(pi->rxgcrs, 0);

    /* wake up PSM */
    phy_misc_conditional_resume(pi, &ctx->tmp.suspend);
    /* wake up PHY watchdog */
    phy_watchdog_resume(pi);

    /* restore phy */
    phy_reg_write(pi, ACPHY_fineclockgatecontrol, ctx->tmp.fineclockgatecontrol);
    enable_stalls(pi, &ctx->tmp.stall_val);

    /* fill parisonic message */
    uint32 max_msg_len = 64;
    uint32 invalid_slots = 0;
    size_t msglen;
    uint8 msg[255];
    int decode_error = decode(wlc->hw, msg, max_msg_len, &invalid_slots);
    if (decode_error < 0) {
        switch (decode_error) {
            case -1:
                memcpy(msg, "ERR: Out of memory", 18);
                msglen = 18;
                break;
            case -2:
                memcpy(msg, "ERR: Preamble not found", 23);
                msglen = 23;
                break;
            case -3:
                memcpy(msg, "ERR: End marker not found", 25);
                msglen = 25;
                break;
            case -4:
                memcpy(msg, "ERR: Message buffer too short", 29);
                msglen = 29;
                break;
            case -5:
                memcpy(msg, "ERR: Invalid symbols detected", 29);
                msglen = 29;
                break;
            case -6:
                memcpy(msg, "ERR: Not enough low energy slots", 32);
                msglen = 32;
                break;
            case -7:
                memcpy(msg, "ERR: Not enough high energy slots", 33);
                msglen = 33;
                break;
            default:
                memcpy(msg, "ERR: Unknown error", 18);
                msglen = 18;
        }
    } else {
        msglen = decode_error;
    }
    struct pairfi_tlv *psrx;
    if (!(psrx = (struct pairfi_tlv*)mallocz(sizeof(struct pairfi_tlv) + msglen))) {
        printf("%s: failed to alloc rx msg\n", __func__);
        return -1;
    }
    psrx->msg.type = PS_RX_DATA;
    psrx->length = msglen;
    memcpy(psrx->data, msg, msglen);

    /* push pairfi message to host */
    pairfi_msg_sendup(ctx, psrx, sizeof(psrx) + msglen);

    /* soft reset */
    init_extended(wlc);

    /* restore original chanspec */
    wlc_set_chanspec__local(wlc, ctx->tmp.orig_chanspec, 0);
    ctx->tmp.orig_chanspec = 0;

    return 0;
}

/* delegate handling of pairfi messages depending on message type */
static void
pairfi_msg_handler(struct pairfi_ctx *ctx, struct pairfi_msg *msg, size_t len)
{
    enum pairfi_messages msg_type;

    if (len < sizeof(struct pairfi_msg))
        return;

    msg_type = msg->type;

    switch(msg_type) {
        case PS_TX_START:
        case PS_CONFIG:
            pairfi_msg_handler_tlv(ctx, (struct pairfi_tlv *)msg, len);
            break;
        case PS_TX_STOP:
            printf("%s: PS_TX_STOP\n", __func__);
            if (!ctx->tx_active) {
                printf("%s: no active pairfi transmission to stop, do nothing\n", __func__);
                break;
            }
            pairfi_tx_stop(ctx);
            break;
        case PS_RX_NEXT:
            printf("%s: PS_RX_NEXT\n", __func__);
            pairfi_rx_next(ctx);
            break;
        case PS_RX_DATA:
            /* nothing to implement here */
            printf("%s: got pairfi message type 0x%02x in wrong direction (app->wifi)\n", __func__, msg_type);
            break;
        case PS_PING:
        case PS_PONG:
            pairfi_msg_handler_ping_pong(ctx, (struct pairfi_ping_pong *)msg, len);
            break;
        default:
            printf("%s: unknown pairfi message type 0x%02x\n", __func__, msg_type);
            break;
    }
}

/* hook that decides if a potential UDP tunneled message shall be fetched by ARM */
bool
wl_tx_pktfetch_required__hook(void *wl, void *wlif, void *bsscfg, struct sk_buff *lb, void *arpi)
{
    bool retval = wl_tx_pktfetch_required(wl, wlif, bsscfg, lb, arpi);
    struct ethernet_header *eh = (struct ethernet_header *)lb->data;
    /* if this is potentially a UDP tunneled message */
    if (!retval && lb->len >= sizeof(struct ethernet_header) && ntohs(eh->type) == 0x0800 && ether_isbcast((void *)eh->dst)) {
        retval |= 1;
    }
    return retval;
}
__attribute__((at(0x27F118, "", CHIP_VER_BCM4389c1, FW_VER_20_101_57_r1035009)))
BLPatch(wl_tx_pktfetch_required__hook, wl_tx_pktfetch_required__hook)

/* pktfetch callback hook
 * process and discard UDP tunneled messages
 * forward to original pktfetch callback otherwise
 */
void
wl_send_cb__hook(struct sk_buff *lbuf, struct lbuf_frag *orig_lfrag, struct pktfetch_info_ctx *ctx, bool cancelled)
{
    struct wl_info *wl = (struct wl_info *)ctx->ctx[0];
    struct pktfetch_info *pinfo = (struct pktfetch_info *)ctx->ctx[3];

    if (!cancelled && lbuf && lbuf->len >= sizeof(struct ethernet_llc_ip_udp_header)) {
        struct ethernet_llc_ip_udp_header *header = (struct ethernet_llc_ip_udp_header*)lbuf->data;
        if (ntohs(header->ethernet.type) < 0x0600
            && ntohs(header->llc.type) == 0x0800
            && ntohs(header->udp.src_port) == 52067
            && ntohs(header->udp.dst_port) == 52066) {
            int16 data_len = ntohs(header->udp.len_chk_cov.length) - sizeof(struct udp_header);
            if (data_len > 0) {
                skb_pull(lbuf, sizeof(struct ethernet_llc_ip_udp_header));
                if (lbuf->len != data_len) {
                    printf("%s: payload length mismatches packet buffer length\n", __func__);
                    skb_push(lbuf, sizeof(struct ethernet_llc_ip_udp_header));
                    goto pktfree;
                }
                struct pairfi_ctx *ps_ctx = pairfi_get_ctx_objr(wl->wlc);
                if (!ps_ctx) {
                    printf("%s: missing pairfi context, discarding message, restart required\n", __func__);
                    skb_push(lbuf, sizeof(struct ethernet_llc_ip_udp_header));
                    goto pktfree;
                }
                if (ps_ctx->msg_handler.active) {
                    printf("%s: pairfi handling in progress, discarding incoming msg\n", __func__);
                    skb_push(lbuf, sizeof(struct ethernet_llc_ip_udp_header));
                    goto pktfree;
                }
                ps_ctx->msg_handler.active = 1;
                ps_ctx->msg_handler.wl = wl;
                /* dst and src switched here intentionally */
                ps_ctx->msg_handler.src_port = ntohs(header->udp.dst_port);
                ps_ctx->msg_handler.dst_port = ntohs(header->udp.src_port);
                pairfi_msg_handler(ps_ctx, (void *)lbuf->data, data_len);
                ps_ctx->msg_handler.src_port = PAIRFI_DEFAULT_SRC_PORT;
                ps_ctx->msg_handler.dst_port = PAIRFI_DEFAULT_DST_PORT;
                ps_ctx->msg_handler.active = 0;
                skb_push(lbuf, sizeof(struct ethernet_llc_ip_udp_header));
            }
pktfree:
            orig_lfrag->flist.finfo[0].ctx.fnum = 0;
            orig_lfrag->flist.flen[0] = 0;
            orig_lfrag->flist.flen[1] = 0;
            orig_lfrag->lbuf.nextid = lbuf->mem.pktid;
            orig_lfrag->lbuf.flags |= 0x40000;
            lbuf->flags = 0x40000;

            if (pinfo)
                free(pinfo);
            if (ctx)
                free(ctx);

            hnd_pkt_free(wl->osh, orig_lfrag, 1);
        } else {
            wl_send_cb(lbuf, orig_lfrag, ctx, cancelled);
        }
    } else {
        wl_send_cb(lbuf, orig_lfrag, ctx, cancelled);
    }
}
__attribute__((at(0x27E57C, "", CHIP_VER_BCM4389c1, FW_VER_20_101_57_r1035009)))
GenericPatch4(wl_send_cb__hook, wl_send_cb__hook+1)
