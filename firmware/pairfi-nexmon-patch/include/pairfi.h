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

#ifndef PAIRFI_H
#define PAIRFI_H

#define PAIRFI_DEFAULT_SRC_PORT  52066
#define PAIRFI_DEFAULT_DST_PORT  52067

enum pairfi_messages {
    /* App -> Nexmon: Start Transmission (includes data)
     * Includes up to 255 bytes of data. The length of the data is specified in the Length field.
     * +---------------------+-------------------------------+---------------------+
     * | Type (1 byte: 0x01) | Length (1 byte: 0x00 to 0xFF) | Data (Length bytes) | 
     * +---------------------+-------------------------------+---------------------+
     */
    PS_TX_START = 0x1,
    /* App -> Nexmon: Stop Transmission 
     * +---------------------+
     * | Type (1 byte: 0x02) | 
     * +---------------------+
     */
    PS_TX_STOP = 0x2,
    /* App -> Nexmon: Receive next message
     * +---------------------+
     * | Type (1 byte: 0x03) |
     * +---------------------+
     */
    PS_RX_NEXT = 0x3,
    /* Nexmon -> App: Response with received message
     * Analogous to the Start Transmission message. The response must be sent to the same port from which the Receive next message packet was received.
     * +---------------------+-------------------------------+---------------------+
     * | Type (1 byte: 0x04) | Length (1 byte: 0x00 to 0xFF) | Data (Length bytes) | 
     * +---------------------+-------------------------------+---------------------+
     */
    PS_RX_DATA = 0x4,
    /* Nexmon <-> App: Ping request
     * To check if the other side is still alive and able to handle other packets; the sequence number is used to match a response to the request.
     * +---------------------+--------------------------+
     * | Type (1 byte: 0x05) | Sequence number (1 byte) |
     * +---------------------+--------------------------+
     */
    PS_PING = 0x5,
    /* Nexmon <-> App: Ping reply
     * Response to a ping request; the sequence number MUST match the sequence number from the request.
     * +---------------------+--------------------------+
     * | Type (1 byte: 0x06) | Sequence number (1 byte) |
     * +---------------------+--------------------------+
     */
    PS_PONG = 0x6,
    /* App -> Nexmon: Set config
     * Configures Nexmon with some settings. The interpretation of the content (data) is up to the implementation. The length is to be given in network order.
     * +---------------------+------------------------------------+---------------------+
     * | Type (1 byte: 0x07) | Length (2 bytes: 0x0000 to 0xFFFF) | Data (Length bytes) |
     * +---------------------+------------------------------------+---------------------+
     */
    PS_CONFIG = 0x7
};

struct pairfi_msg {
    uint8 type;
} __attribute__((packed));

struct pairfi_tlv {
    struct pairfi_msg msg;
    uint8 length;
    uint8 data[];
} __attribute__((packed));

struct pairfi_ping_pong {
    struct pairfi_msg msg;
    uint8 seq_number;
} __attribute__((packed));


#define OBJR_PAIRFI_CTX 0x7D

struct pairfi_ctx {
    struct wlc_info *wlc;
    struct msg_handler {
        struct wl_info *wl;
        uint16 src_port;
        uint16 dst_port;
        bool active;
    } msg_handler;
    int16 pending_seq_num;
    bool tx_active;
    struct config {
        uint16 chanspec;
        int8 txgain_index;
    } config;
    struct tmp {
        uint16 orig_chanspec;
        uint16 fineclockgatecontrol;
        uint8 stall_val;
        uint8 suspend;
    } tmp;
};

#define LOW_SAMPS 20
#define HIGH_SAMPS 480

/* ucode config shared mempry addresses */
#define	M_CONFIG_BASE   0x3200
#define	M_CONFIG(id)    (M_CONFIG_BASE+2*id)

#define	M_OOK_ENABLE    M_CONFIG(0)
#define	M_OOK_STOP      M_CONFIG(1)
#define	M_OOK_N_LOW     M_CONFIG(2)
#define	M_OOK_LOW_IDX   M_CONFIG(3)
#define	M_OOK_N_HIGH    M_CONFIG(4)
#define	M_OOK_HIGH_IDX  M_CONFIG(5)
#define	M_OOK_MSG_LEN   M_CONFIG(6)
#define	M_OOK_MSG(idx)  (M_CONFIG(7)+2*idx)

#endif /*PAIRFI_H*/
