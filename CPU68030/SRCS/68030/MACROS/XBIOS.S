;****************************************************************
;		Macros du XBIOS.
;****************************************************************
Initmous	macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.w		\3,-(sp)
		clr.w		-(sp)
		trap		#14
		lea		(12.w,sp),sp
		endm

Ssbrk		macro
		move.w		\1,-(sp)
		move.w		#1,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

Physbase	macro
		move.w		#2,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

Logbase		macro
		move.w		#3,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

Getrez		macro
		move.w		#4,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

Setscreen	macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.l		\3,-(sp)
		move.w		#5,-(sp)
		trap		#14
		lea		(12.w,sp),sp
		endm

VsetScreen	macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.l		\3,-(sp)
		move.l		\4,-(sp)
		move.w		#5,-(sp)
		trap		#14
		lea		(14.w,sp),sp
		endm

Setpalette	macro
		move.l		\1,-(sp)
		move.w		#6,-(sp)
		trap		#14
		addq.l		#6,sp
		endm

Setcolor	macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#7,-(sp)
		trap		#14
		addq.l		#6,sp
		endm

Floprd		macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		\3,-(sp)
		move.w		\4,-(sp)
		move.w		\5,-(sp)
		move.l		\6,-(sp)
		move.l		\7,-(sp)
		move.w		#8,-(sp)
		trap		#14
		lea		(20.w,sp),sp
		endm

Flopwr		macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		\3,-(sp)
		move.w		\4,-(sp)
		move.w		\5,-(sp)
		move.l		\6,-(sp)
		move.l		\7,-(sp)
		move.w		#9,-(sp)
		trap		#14
		lea		(20.w,sp),sp
		endm

Flopfmt		macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.w		\3,-(sp)
		move.w		\4,-(sp)
		move.w		\5,-(sp)
		move.w		\6,-(sp)
		move.w		\7,-(sp)
		move.l		\8,-(sp)
		move.l		\9,-(sp)
		move.w		#10,-(sp)
		trap		#14
		lea		(26.w,sp),sp
		endm

Dbmsg		macro
		move.l		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#5,-(sp)
		move.w		#11,-(sp)
		trap		#14
		lea		(10.w,sp),sp
		endm

Midiws		macro
		move.l		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#12,-(sp)
		trap		#14
		addq.l		#8,sp
		endm

Mfpint		macro
		move.l		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#13,-(sp)
		trap		#14
		addq.l		#8,sp
		endm

Iorec		macro
		move.w		\1,-(sp)
		move.w		#14,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

Rsconf		macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		\3,-(sp)
		move.w		\4,-(sp)
		move.w		\5,-(sp)
		move.w		\6,-(sp)
		move.w		#15,-(sp)
		trap		#14
		lea		(14.w,sp),sp
		endm

Keytbl		macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.l		\3,-(sp)
		move.w		#16,-(sp)
		trap		#14
		lea		(14.w,sp),sp
		endm

Random		macro
		move.w		#17,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

Protobt		macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.l		\3,-(sp)
		move.l		\4,-(sp)
		move.w		#18,-(sp)
		trap		#14
		lea		(14.w,sp),sp
		endm

Flopver		macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		\3,-(sp)
		move.w		\4,-(sp)
		move.w		\5,-(sp)
		move.l		\6,-(sp)
		move.l		\7,-(sp)
		move.w		#19,-(sp)
		trap		#14
		lea		(20.w,sp),sp
		endm

Scrdump		macro
		move.w		#20,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

Cursconf	macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#21,-(sp)
		trap		#14
		addq.l		#6,sp
		endm

Settime		macro
		move.l		\1,-(sp)
		move.w		#22,-(sp)
		trap		#14
		addq.l		#8,sp
		endm

Gettime		macro
		move.w		#23,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

Bioskeys	macro
		move.w		\1,-(sp)
		move.w		#24,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

Ikbdws		macro
		move.l		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#25,-(sp)
		trap		#14
		addq.l		#8,sp
		endm

Jdisint		macro
		move.w		\1,-(sp)
		move.w		#26,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

Jenabint	macro
		move.w		\1,-(sp)
		move.w		#27,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

Giaccess	macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#28,-(sp)
		trap		#14
		addq.l		#6,sp
		endm

Offgibit	macro
		move.w		\1,-(sp)
		move.w		#29,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

Ongibit		macro
		move.w		\1,-(sp)
		move.w		#30,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

Xbtimer		macro
		move.l		\1,-(sp)
		move.w		\2,-(sp)
		move.w		\3,-(sp)
		move.w		\4,-(sp)
		move.w		#31,-(sp)
		trap		#14
		lea		(12.w,sp),sp
		endm

Dosound		macro
		move.l		\1,-(sp)
		move.w		#32,-(sp)
		trap		#14
		addq.l		#6,sp
		endm

Setprt		macro
		move.w		\1,-(sp)
		move.w		#33,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

Kbdvbase	macro
		move.w		#34,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

Kbrate		macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#35,-(sp)
		trap		#14
		addq.l		#6,sp
		endm

Prtblk		macro
		move.l		\1,-(sp)
		move.w		#36,-(sp)
		trap		#14
		addq.l		#6,sp
		endm

Vsync		macro
		move.w		#37,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

Supexec		macro
		move.l		\1,-(sp)
		move.w		#38,-(sp)
		trap		#14
		addq.l		#6,sp
		endm

Puntaes		macro
		move.w		#39,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

Floprate	macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#41,-(sp)
		trap		#14
		addq.l		#6,sp
		endm

DMAread		macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.w		\3,-(sp)
		move.l		\4,-(sp)
		move.w		#42,-(sp)
		trap		#14
		lea		(14.w,sp),sp
		endm

DMAwrite	macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.w		\3,-(sp)
		move.l		\4,-(sp)
		move.w		#43,-(sp)
		trap		#14
		lea		(14.w,sp),sp
		endm

Bconmap		macro
		move.w		\1,-(sp)
		move.w		#44,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

NVMaccess	macro
		move.l		\1,-(sp)
		move.w		\2,-(sp)
		move.w		\3,-(sp)
		move.w		\4,-(sp)
		move.w		#46,-(sp)
		trap		#14
		lea		(12.w,sp),sp
		endm

Metainit	macro
		move.l		\1,-(sp)
		move.w		#48,-(sp)
		trap		#14
		addq.l		#6,sp
		endm

Blitmode	macro
		move.w		\1,-(sp)
		move.w		#64,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

EsetShift	macro
		move.w		\1,-(sp)
		move.w		#80,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

EgetShift	macro
		move.w		#81,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

EsetBank	macro
		move.w		\1,-(sp)
		move.w		#82,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

EsetColor	macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#83,-(sp)
		trap		#14
		addq.l		#6,sp
		endm

EsetPalette	macro
		move.l		\1,-(sp)
		move.w		\2,-(sp)
		move.w		\3,-(sp)
		move.w		#84,-(sp)
		trap		#14
		lea		(10.w,sp),sp
		endm

EgetPalette	macro
		move.l		\1,-(sp)
		move.w		\2,-(sp)
		move.w		\3,-(sp)
		move.w		#85,-(sp)
		trap		#14
		lea		(10.w,sp),sp
		endm

EsetGray	macro
		move.w		\1,-(sp)
		move.w		#86,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

EsetSmear	macro
		move.w		\1,-(sp)
		move.w		#87,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

VsetMode	macro
		move.w		\1,-(sp)
		move.w		#88,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

VgetMonitor	macro
		move.w		#89,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

VsetSync	macro
		move.w		\1,-(sp)
		move.w		#90,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

VgetSize	macro
		move.w		\1,-(sp)
		move.w		#91,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

VsetRGB		macro
		move.l		\1,-(sp)
		move.w		\2,-(sp)
		move.w		\3,-(sp)
		move.w		#93,-(sp)
		trap		#14
		lea		(10.w,sp),sp
		endm

VgetRGB		macro
		move.l		\1,-(sp)
		move.w		\2,-(sp)
		move.w		\3,-(sp)
		move.w		#94,-(sp)
		trap		#14
		lea		(10.w,sp),sp
		endm


Dsp_DoBlock	macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.l		\3,-(sp)
		move.l		\4,-(sp)
		move.w		#96,-(sp)
		trap		#14
		lea		(18.w,sp),sp
		endm

Dsp_BlkHandShake macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.l		\3,-(sp)
		move.l		\4,-(sp)
		move.w		#97,-(sp)
		trap		#14
		lea		(18.w,sp),sp
		endm

Dsp_BlkUnpacked	macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.l		\3,-(sp)
		move.l		\4,-(sp)
		move.w		#98,-(sp)
		trap		#14
		lea		(18.w,sp),sp
		endm

Dsp_InStream	macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.l		\3,-(sp)
		move.l		\4,-(sp)
		move.w		#99,-(sp)
		trap		#14
		lea		(18.w,sp),sp
		endm

Dsp_OutStream	macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.l		\3,-(sp)
		move.l		\4,-(sp)
		move.w		#100,-(sp)
		trap		#14
		lea		(18.w,sp),sp
		endm

Dsp_IOStream	macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.l		\3,-(sp)
		move.l		\4,-(sp)
		move.l		\5,-(sp)
		move.l		\6,-(sp)
		move.w		#101,-(sp)
		trap		#14
		lea		(26.w,sp),sp
		endm

Dsp_RemoveInterrupts macro
		move.w		\1,-(sp)
		move.w		#102,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

Dsp_GetWordSize	macro
		move.w		#103,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

Dsp_Lock	macro
		move.w		#104,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

Dsp_Unlock	macro
		move.w		#105,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

Dsp_Available	macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.w		#106,-(sp)
		trap		#14
		lea		(10.w,sp),sp
		endm

Dsp_Reserve	macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.w		#107,-(sp)
		trap		#14
		lea		(10.w,sp),sp
		endm

Dsp_LoadProg	macro
		move.l		\1,-(sp)
		move.w		\2,-(sp)
		move.l		\3,-(sp)
		move.w		#108,-(sp)
		trap		#14
		lea		(12.w,sp),sp
		endm

Dsp_ExecProg	macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.l		\3,-(sp)
		move.w		#109,-(sp)
		trap		#14
		lea		(12.w,sp),sp
		endm

Dsp_ExecBoot	macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.l		\3,-(sp)
		move.w		#110,-(sp)
		trap		#14
		lea		(12.w,sp),sp
		endm

Dsp_LodToBinary	macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.w		#111,-(sp)
		trap		#14
		lea		(10.w,sp),sp
		endm

Dsp_TriggerHC	macro
		move.w		\1,-(sp)
		move.w		#112,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

Dsp_RequestUniqueAbility macro
		move.w		#113,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

Dsp_GetProgAbility macro
		move.w		#114,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

Dsp_FlushSubroutines macro
		move.w		#115,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

Dsp_LoadSubroutine macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.l		\3,-(sp)
		move.w		#116,-(sp)
		trap		#14
		lea		(12.w,sp),sp
		endm

Dsp_InqSubrAbility macro
		move.w		\1,-(sp)
		move.w		#117,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

Dsp_RunSubroutine macro
		move.w		\1,-(sp)
		move.w		#118,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

Dsp_Hf0		macro
		move.w		\1,-(sp)
		move.w		#119,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

Dsp_Hf1		macro
		move.w		\1,-(sp)
		move.w		#120,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

Dsp_Hf2		macro
		move.w		#121,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

Dsp_Hf3		macro
		move.w		#122,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

Dsp_BlkWords	macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.l		\3,-(sp)
		move.l		\4,-(sp)
		move.w		#123,-(sp)
		trap		#14
		lea		(18.w,sp),sp
		endm

Dsp_BlkBytes	macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.l		\3,-(sp)
		move.l		\4,-(sp)
		move.w		#124,-(sp)
		trap		#14
		lea		(18.w,sp),sp
		endm

Dsp_HStat	macro
		move.w		#125,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

Dsp_SetVectors	macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.w		#126,-(sp)
		trap		#14
		lea		(10.w,sp),sp
		endm

Dsp_MultBlocks	macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.l		\3,-(sp)
		move.l		\4,-(sp)
		move.w		#127,-(sp)
		trap		#14
		lea		(18.w,sp),sp
		endm

Locksnd		macro
		move.w		#128,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

Unlocksnd	macro
		move.w		#129,-(sp)
		trap		#14
		addq.l		#2,sp
		endm

Soundcmd	macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#130,-(sp)
		trap		#14
		addq.l		#6,sp
		endm

Setbuffer	macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.w		\3,-(sp)
		move.w		#131,-(sp)
		trap		#14
		lea		(12.w,sp),sp
		endm

Setmode		macro
		move.w		\1,-(sp)
		move.w		#132,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

Settracks	macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#133,-(sp)
		trap		#14
		addq.l		#6,sp
		endm

Setmontracks	macro
		move.w		\1,-(sp)
		move.w		#134,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

Setinterrupt	macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#135,-(sp)
		trap		#14
		addq.l		#6,sp
		endm

Buffoper	macro
		move.w		\1,-(sp)
		move.w		#136,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

Dsptristate	macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#137,-(sp)
		trap		#14
		addq.l		#6,sp
		endm

Gpio		macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		#138,-(sp)
		trap		#14
		addq.l		#6,sp
		endm

Devconnect	macro
		move.w		\1,-(sp)
		move.w		\2,-(sp)
		move.w		\3,-(sp)
		move.w		\4,-(sp)
		move.w		\5,-(sp)
		move.w		#139,-(sp)
		trap		#14
		lea		(12.w,sp),sp
		endm

Sndstatus	macro
		move.w		\1,-(sp)
		move.w		#140,-(sp)
		trap		#14
		addq.l		#4,sp
		endm

Buffptr		macro
		move.l		\1,-(sp)
		move.w		#141,-(sp)
		trap		#14
		addq.l		#6,sp
		endm

VsetMask	macro
		move.w		\1,-(sp)
		move.l		\2,-(sp)
		move.l		\3,-(sp)
		move.w		#150,-(sp)
		trap		#14
		lea		(12.w,sp),sp
		endm

WavePlay	macro
		move.l		\1,-(sp)
		move.l		\2,-(sp)
		move.l		\3,-(sp)
		move.w		\4,-(sp)
		move.w		#165,-(sp)
		trap		#14
		lea		(16.w,sp),sp
		endm
