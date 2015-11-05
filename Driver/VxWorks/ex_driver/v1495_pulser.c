#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <vxWorks.h>
#include "v1495_pulser.h"

#define EIEIO    __asm__ volatile ("eieio")
#define SYNC     __asm__ volatile ("sync")

#define DEBUG_REG_RW	0

V1495_Pulser_regs *pPulser;

unsigned short ReadReg16(unsigned short *pAddr)
{
	unsigned short result;

	EIEIO;
	SYNC;
	result = *pAddr;
#if DEBUG_REG_RW
	printf("ReadReg16 @ 0x%08X = 0x%04hX\n", (unsigned int)pAddr, result);
#endif
	return result;
}

void WriteReg16(unsigned short *pAddr, unsigned short val)
{
	EIEIO;
	SYNC;
	*pAddr = val;
#if DEBUG_REG_RW
	printf("WriteReg16 @ 0x%08X = 0x%04hX\n", (unsigned int)pAddr, val);
#endif
}

unsigned int ReadReg32(unsigned int *pAddr)
{
	unsigned int result;

	EIEIO;
	SYNC;
	result = *pAddr;
#if DEBUG_REG_RW
	printf("ReadReg32 @ 0x%08X = 0x%08X\n", (unsigned int)pAddr, result);
#endif
	return result;
}

void WriteReg32(unsigned int *pAddr, unsigned int val)
{
	EIEIO;
	SYNC;
	*pAddr = val;
#if DEBUG_REG_RW
	printf("WriteReg32 @ 0x%08X = 0x%08X\n", (unsigned int)pAddr, val);
#endif
}

int V1495PulserInit(unsigned int a32_base)
{
	unsigned int result;

	printf("\nV1495PulserInit() started...\n");

	sysBusToLocalAdrs(0x39, a32_base, &pPulser);
	printf("   V1495Pulser A32 VME Address 0x%08X mapped to CPU Address 0x%08X\n", a32_base, (unsigned int)pPulser);
	
	result = ReadReg32(&pPulser->PulserId);
	printf("   V1495Pulser Pulser Id registers = 0x%08X\n", result);
	if(result != PULSER_ID)
	{
		printf("Error: V1495PulserInit() failed to find V1495Pulser @ A32 VME Address 0x%08X\n", a32_base);
		return -1;
	}

	V1495PulserStatus();

	return 0;
}

void V1495PulserUserReload()
{
	WriteReg16(&pPulser->configUSER, 1);
}

void V1495PulserStatus()
{
	unsigned int result;

	printf("\nV1495PulserStatus:\n");

	printf("   V1495Pulser VME Firmware Revision = 0x%08X\n", ReadReg16(&pPulser->firmwareRev));
	printf("   V1495Pulser Pulser Firmware Revision = 0x%08X\n", ReadReg32(&pPulser->FirmwareRev));

	result = ReadReg32(&pPulser->DaughterBoardId);
	printf("   V1495Pulser Pulser Daughtercard Id: D=%d, E=%d, F=%d\n", (result>>0) & 0x7,
	                                                                    (result>>4) & 0x7,
	                                                                    (result>>8) & 0x7);

	printf("   Pulser Status:          0x%08X_%08X\n", ReadReg32(&pPulser->PulserStatusH),
	                                                   ReadReg32(&pPulser->PulserStatusL));
	printf("   Pulser Start Mask:      0x%08X_%08X\n", ReadReg32(&pPulser->PulserStartMaskH),
	                                                   ReadReg32(&pPulser->PulserStartMaskL));
	printf("   Pulser Stop Mask:       0x%08X_%08X\n", ReadReg32(&pPulser->PulserStopMaskH),
	                                                   ReadReg32(&pPulser->PulserStopMaskL));
	printf("   Pulser GIN OR Mask:     0x%08X_%08X\n", ReadReg32(&pPulser->PulserGinMaskH),
	                                                   ReadReg32(&pPulser->PulserGinMaskL));
	printf("   Pulser Master OR Delay: 0x%08X (%uns)\n", ReadReg32(&pPulser->MasterOrDelay),
	                                                     ReadReg32(&pPulser->MasterOrDelay)*PULSER_TICK_PERIOD_NS);
	printf("   Pulser Master OR Width: 0x%08X (%uns)\n", ReadReg32(&pPulser->MasterOrWidth),
	                                                     ReadReg32(&pPulser->MasterOrWidth)*PULSER_TICK_PERIOD_NS);
	printf("   Pulser Jumpers:         0x%08X\n", ReadReg32(&pPulser->Jumpers));
}

void V1495PulserGetCfg(int pulser)
{
	unsigned int result;

	printf("\nV1495PulserGetCfg(%d)\n", pulser);
	
	if((pulser < 0) || (pulser >= PULSER_NUM))
	{
		printf("Error: V1495PulserGetCfg() invalid pulser id %d\n", pulser);
		return;
	}

	result = ReadReg32(&pPulser->Pulsers[pulser].Period);
	printf("   Period     = 0x%08X (%uns)\n", result, (result-1)*PULSER_TICK_PERIOD_NS);

	result = ReadReg32(&pPulser->Pulsers[pulser].Width);
	printf("   HighCycles = 0x%08X (%uns)\n", result, result*PULSER_TICK_PERIOD_NS);

	result = ReadReg32(&pPulser->Pulsers[pulser].NPulses);
	printf("   NPulses    = 0x%08X (%u)\n", result, result);
}

void V1495PulserSetMasterOrCfg(unsigned int width, unsigned int delay)
{
	WriteReg32(&pPulser->MasterOrWidth, width);
	WriteReg32(&pPulser->MasterOrDelay, delay);
}

void V1495PulserSetGinOrMask(unsigned int maskL, unsigned int maskH)
{
	WriteReg32(&pPulser->PulserGinMaskH, maskH);
	WriteReg32(&pPulser->PulserGinMaskL, maskL);
}

void V1495PulserSetCfg(int pulser, unsigned int period_ticks, unsigned int width, unsigned int npulses)
{
	WriteReg32(&pPulser->Pulsers[pulser].NPulses, npulses);
	WriteReg32(&pPulser->Pulsers[pulser].Width, width);
	WriteReg32(&pPulser->Pulsers[pulser].Period, period_ticks);
}

void V1495PulserSetCfgAll(unsigned int period_ticks, unsigned int width, unsigned int npulses)
{
	int pulser;
	for(pulser = 0; pulser < PULSER_NUM; pulser++)
		V1495PulserSetCfg(pulser, period_ticks, width, npulses);
}


void V1495PulserStart(unsigned int maskL, unsigned int maskH)
{
	WriteReg32(&pPulser->PulserStartMaskH, maskH);
	WriteReg32(&pPulser->PulserStartMaskL, maskL);
	WriteReg32(&pPulser->PulserStartStop, 0x1);
}

void V1495PulserStop(unsigned int maskL, unsigned int maskH)
{
	WriteReg32(&pPulser->PulserStopMaskH, maskH);
	WriteReg32(&pPulser->PulserStopMaskL, maskL);
	WriteReg32(&pPulser->PulserStartStop, 0x0);
}

