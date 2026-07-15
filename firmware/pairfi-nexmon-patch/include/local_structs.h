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

#ifndef LOCAL_STRUCTS_H
#define LOCAL_STRUCTS_H

typedef struct {
  uint16 rad_gain;
  uint16 rad_gain_mi;
  uint16 rad_gain_hi;
  uint16 dac_gain;
  uint16 bbmult;
} txgain_setting_t;

#define LB_FRAG_MAX 2
struct lbuf_finfo {
    union {
        struct {
            uint32 pktid;
            uint8 fnum;
            uint8 lfrag_flags;
            uint16 flowid;
        } ctx;
        struct {
            uint32 data_lo;
            uint32 data_hi;
        } frag;
    };
} __attribute__((packed));

struct lbuf_flist {
    struct lbuf_finfo finfo[LB_FRAG_MAX + 1];
    uint16 flen[LB_FRAG_MAX + 1];
    uint16 ring_idx;
} __attribute__((packed));

struct lbuf_frag {
    struct sk_buff lbuf;
    struct lbuf_flist flist;
} __attribute__((packed));

typedef void (*pktfetch_cmplt_cb_t)(void *lbuf, void *orig_lfrag, void *ctx, bool cancelled);
struct pktfetch_info {
  void *osh;
  void *lfrag;
  uint16 headroom;
  int16 host_offset;
  pktfetch_cmplt_cb_t cb;
  void *ctx;
  struct pktfetch_info *next;
} __attribute__((packed));

struct pktfetch_info_ctx {
  uint32 ctx_count;
  void *ctx[];
} __attribute__((packed));

struct llc_header {
  uint8 dsap;
  uint8 ssap;
  uint32 control_field;
  uint16 type;
} __attribute__((packed));

struct ethernet_llc_ip_udp_header {
    struct ethernet_header ethernet;
    struct llc_header llc;
    struct ip_header ip;
    struct udp_header udp;
} __attribute__((packed));

struct _cint32 {
    int32 q;
    int32 i;
};

typedef struct {
    int16 i;
    int16 q;
} __attribute__((packed)) cint16;

struct phy_ac_info {
    uint32 PAD;                       /* 0x000 */
    uint32 PAD;                       /* 0x004 */
    uint32 PAD;                       /* 0x008 */
    uint32 PAD;                       /* 0x00c */
    uint32 PAD;                       /* 0x010 */
    uint32 PAD;                       /* 0x014 */
    uint32 PAD;                       /* 0x018 */
    uint32 PAD;                       /* 0x01c */
    uint32 PAD;                       /* 0x020 */
    uint32 PAD;                       /* 0x024 */
    uint32 PAD;                       /* 0x028 */
    uint32 PAD;                       /* 0x02c */
    uint32 PAD;                       /* 0x030 */
    uint32 PAD;                       /* 0x034 */
    uint32 PAD;                       /* 0x038 */
    uint32 PAD;                       /* 0x03c */
    uint32 PAD;                       /* 0x040 */
    uint32 PAD;                       /* 0x044 */
    uint32 PAD;                       /* 0x048 */
    uint32 PAD;                       /* 0x04c */
    uint32 PAD;                       /* 0x050 */
    uint32 PAD;                       /* 0x054 */
    uint32 PAD;                       /* 0x058 */
    uint32 PAD;                       /* 0x05c */
    uint32 PAD;                       /* 0x060 */
    uint32 PAD;                       /* 0x064 */
    uint32 PAD;                       /* 0x068 */
    uint32 PAD;                       /* 0x06c */
    uint32 PAD;                       /* 0x070 */
    uint32 PAD;                       /* 0x074 */
    uint32 PAD;                       /* 0x078 */
    void *tofi;                       /* 0x07c */
    uint32 PAD;                       /* 0x080 */
    uint32 PAD;                       /* 0x084 */
    uint32 PAD;                       /* 0x088 */
    uint32 PAD;                       /* 0x08c */
    uint32 PAD;                       /* 0x090 */
    uint32 PAD;                       /* 0x094 */
    uint32 PAD;                       /* 0x098 */
    uint32 PAD;                       /* 0x09c */
    uint32 PAD;                       /* 0x0a0 */
    uint32 PAD;                       /* 0x0a4 */
    uint32 PAD;                       /* 0x0a8 */
    uint32 PAD;                       /* 0x0ac */
    uint32 PAD;                       /* 0x0b0 */
    uint32 PAD;                       /* 0x0b4 */
    uint32 PAD;                       /* 0x0b8 */
    uint32 PAD;                       /* 0x0bc */
    uint32 PAD;                       /* 0x0c0 */
    uint32 PAD;                       /* 0x0c4 */
    uint32 PAD;                       /* 0x0c8 */
    uint32 PAD;                       /* 0x0cc */
    uint32 PAD;                       /* 0x0d0 */
    uint32 PAD;                       /* 0x0d4 */
} __attribute__((packed));

#endif /*LOCAL_STRUCTS_H*/
