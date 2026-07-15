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

#ifndef REGISTERS_H
#define REGISTERS_H

#define wreg32(r, v)    (*(volatile uint32*)(r) = (uint32)(v))
#define rreg32(r)       (*(volatile uint32*)(r))
#define wreg16(r, v)    (*(volatile uint16*)(r) = (uint16)(v))
#define rreg16(r)       (*(volatile uint16*)(r))
#define wreg8(r, v)     (*(volatile uint8*)(r) = (uint8)(v))
#define rreg8(r)        (*(volatile uint8*)(r))

#define BCM_REFERENCE(data) ((void)(data))

#define W_REG(osh, r, v) do { \
    BCM_REFERENCE(osh); \
    switch (sizeof(*(r))) { \
    case sizeof(uint8): wreg8((void *)(r), (v)); break; \
    case sizeof(uint16): wreg16((void *)(r), (v)); break; \
    case sizeof(uint32): wreg32((void *)(r), (v)); break; \
    } \
} while (0)

#define R_REG(osh, r) ({ \
    __typeof(*(r)) __osl_v; \
    BCM_REFERENCE(osh); \
    switch (sizeof(*(r))) { \
    case sizeof(uint8): __osl_v = rreg8((void *)(r)); break; \
    case sizeof(uint16): __osl_v = rreg16((void *)(r)); break; \
    case sizeof(uint32): __osl_v = rreg32((void *)(r)); break; \
    } \
    __osl_v; \
})

#define ACPHY_fineclockgatecontrol 0x16b
#define ACPHY_fineclockgatecontrol_forceRfSeqgatedClksOn_SHIFT 13
#define ACPHY_fineclockgatecontrol_forceRfSeqgatedClksOn_MASK (0x1 << ACPHY_fineclockgatecontrol_forceRfSeqgatedClksOn_SHIFT)

#define ACPHY_RxFeCtrl1 0x19e
#define ACPHY_RxFeCtrl1_disable_stalls_SHIFT 1
#define ACPHY_RxFeCtrl1_disable_stalls_MASK (0x1 << ACPHY_RxFeCtrl1_disable_stalls_SHIFT)

#define ACPHY_sampleCmd 0x460
#define ACPHY_sampleCmd_stop_SHIFT 1
#define ACPHY_sampleCmd_stop_MASK (0x1 << ACPHY_sampleCmd_stop_SHIFT)

#define ACPHY_sampleDepthCount 0x463
#define ACPHY_sampleDepthCount_DepthCount_SHIFT 0
#define ACPHY_sampleDepthCount_DepthCount_MASK (0x1ff << ACPHY_sampleDepthCount_DepthCount_SHIFT)

#define ACPHY_sampleStartAddr 0x465
#define ACPHY_sampleStartAddr_startAddr_SHIFT 0
#define ACPHY_sampleStartAddr_startAddr_MASK (0x1ff << ACPHY_sampleStartAddr_startAddr_SHIFT)

#define ACPHY_AdcDataCollect 0x467
#define ACPHY_AdcDataCollect_adcDataCollectEn_SHIFT 0
#define ACPHY_AdcDataCollect_adcDataCollectEn_MASK (0x1 << ACPHY_AdcDataCollect_adcDataCollectEn_SHIFT)

#endif /*REGISTERS_H*/
