#ifndef V1495_PULSER_H
#define V1495_PULSER_H

#define PULSER_NUM_MAX			256
#define PULSER_NUM				56

#define PULSER_TICK_PERIOD_NS	10

#define PULSER_ID				0x50554C53

#define DAUGHTERBOARD_ID_A395A	0x0
#define DAUGHTERBOARD_ID_A395B	0x1
#define DAUGHTERBOARD_ID_A395C	0x2
#define DAUGHTERBOARD_ID_A395D	0x3

#define PULSER_IDX_C(n)			(0+n)
#define PULSER_IDX_D(n)			(31+n)
#define PULSER_IDX_E(n)			(39+n)
#define PULSER_IDX_F(n)			(47+n)

typedef struct
{
/* 0x0000-0x0003 */ unsigned int Period;
/* 0x0004-0x0007 */ unsigned int Width;
/* 0x0008-0x000B */ unsigned int NPulses;
/* 0x000C-0x000F */ unsigned int Reserved0;
} PulserPeriph;

typedef struct
{
/****************** USER FPGA Registers ****************/
/* 0x0000-0x0FFF */ unsigned int Reserved0[(0x1000-0x0000)/4];
/* 0x1000-0x1003 */ unsigned int PulserId;
/* 0x1004-0x1007 */ unsigned int FirmwareRev;
/* 0x1008-0x100B */ unsigned int DaughterBoardId;
/* 0x100C-0x100F */ unsigned int Jumpers;
/* 0x1010-0x1013 */ unsigned int PulserStatusH;
/* 0x1014-0x1017 */ unsigned int PulserStatusL;
/* 0x1018-0x101B */ unsigned int PulserStartMaskH;
/* 0x101C-0x101F */ unsigned int PulserStartMaskL;
/* 0x1020-0x1023 */ unsigned int PulserStopMaskH;
/* 0x1024-0x1027 */ unsigned int PulserStopMaskL;
/* 0x1028-0x102B */ unsigned int PulserGinMaskH;
/* 0x102C-0x102F */ unsigned int PulserGinMaskL;
/* 0x1030-0x1033 */ unsigned int PulserStartStop;
/* 0x1034-0x10FF */ unsigned int Reserved1[(0x1100-0x1034)/4];
/* 0x1100-0x1103 */ unsigned int MasterOrDelay;
/* 0x1104-0x1107 */ unsigned int MasterOrWidth;
/* 0x1108-0x1FFF */ unsigned int Reserved2[(0x2000-0x1108)/4];
/* 0x2000-0x2FFF */ PulserPeriph Pulsers[PULSER_NUM_MAX];
/* 0x3000-0x7FFF */ unsigned int Reserved3[(0x8000-0x3000)/4];
/****************** VME FPGA Registers ****************/
/* 0x8000-0x8001 */ unsigned short control;
/* 0x8002-0x8003 */ unsigned short status;
/* 0x8004-0x8005 */ unsigned short intLevel;
/* 0x8006-0x8007 */ unsigned short intVector;
/* 0x8008-0x8009 */ unsigned short geoAddr;
/* 0x800A-0x800B */ unsigned short moduleReset;
/* 0x800C-0x800D */ unsigned short firmwareRev;
/* 0x800E-0x800F */ unsigned short selflashVME;
/* 0x8010-0x8011 */ unsigned short flashVME;
/* 0x8012-0x8013 */ unsigned short selflashUSER;
/* 0x8014-0x8015 */ unsigned short flashUSER;
/* 0x8016-0x8017 */ unsigned short configUSER;
/* 0x8018-0x8019 */ unsigned short scratch16;
/* 0x801A-0x801F */ unsigned short res1[3];
/* 0x8020-0x8023 */ unsigned int scratch32;
/* 0x8024-0x81FF */ unsigned short res2[110];
/* 0x8100-0x81FD */ unsigned short configROM[127];
} V1495_Pulser_regs;

int V1495PulserInit(unsigned int a24_base);
void V1495PulserStatus();
void V1495PulserGetCfg(int pulser);
void V1495PulserSetCfg(int pulser, unsigned int period, unsigned int highcycles, unsigned int npulses);
void V1495PulserStart(unsigned int maskL, unsigned int maskH);
void V1495PulserStop(unsigned int maskL, unsigned int maskH);

#endif
