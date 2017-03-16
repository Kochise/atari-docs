; /// SSAVCALL 3.02 - JoyPAD DRIVER - ATARI Falcon030 - KOSS 2000 /////////////

; Author   : Kochise
; Date     : 02/10/07/2000
; Type     : SSAVCALL DRIVER Module
; Language : Assembler (Motorola 68030)
; Sequence : VBL or TIMER
; Purpose  : ATARI Enhanced JoyPAD DRIVER

; Machina  : ATARI Falcon030
; O.S.     : SSAVCALL 3

; Note     : This is PROBABLY the BEST JoyPAD DRIVER * EVER * Coded...
;            FAST, COMPACT, NICELY COMMENTED, another * GOD * Job by KOSS !

; ### HardWare Informations ###################################################
; Address     Size Status Name         Purpose
; $FFFF9200.w WORD READ   JoyButtons   States of the JoyPads Standard Buttons
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                         > ACTIVE LOW <          x x x x x x x x x x x x | | | |
;                                                                         | | | |
;                         PadA FIREA/FIREB/FIREC/OPTION ------------------' | | |
;                         PadA PAUSE ---------------------------------------' | |
;                         PadB FIREA/FIREB/FIREC/OPTION ----------------------' |
;                         PadB PAUSE -------------------------------------------'
;
; -----------------------------------------------------------------------------
;
; $FFFF9202.w WORD READ   JoyMatrix    States of the JoyPads Extended Buttons
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                         > ACTIVE LOW <          | | | | | | | | x x x x x x x x
;                                                 | | | | | | | |
;                         PadA RIGHT/N1/N2/N3 ----' | | | | | | |
;                         PadA LEFT/N4/N5/N6 -------' | | | | | |
;                         PadA LOW/N7/N8/N9 ----------' | | | | |
;                         PadA HI/N*/N0/N# -------------' | | | |
;                                                         | | | |
;                         PadB RIGHT/N1/N2/N3 ------------' | | |
;                         PadB LEFT/N4/N5/N6 ---------------' | |
;                         PadB LOW/N7/N8/N9 ------------------' |
;                         PadB HI/N*/N0/N# ---------------------'
;
; $FFFF9202.w WORD WRITE  JoyMask      Mask of the JoyMatrix
;
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                         > ACTIVE LOW <          x x x x x x x x | | | | | | | |
;                                                                 | | | | | | | |
;                         PadA OPTION/N3/N6/N9/N# ----------------' | | | | | | |
;                         PadA FIREC/N2/N5/N8/N0 -------------------' | | | | | |
;                         PadA FIREB/N1/N4/N7/N* ---------------------' | | | | |
;                         PadA FIREA/PAUSE/DIRECTION -------------------' | | | |
;                                                                         | | | |
;                         PadB OPTION/N3/N6/N9/N# ------------------------' | | |
;                         PadB FIREC/N2/N5/N8/N0 ---------------------------' | |
;                         PadB FIREB/N1/N4/N7/N* -----------------------------' |
;                         PadB FIREA/PAUSE/DIRECTION ---------------------------'

; How to Look for a Button ? For example : PabB OPTION is Held Down...
; 1st Step : bclr.b #3,$FFFF9203.w -> PadB OPTION/N3/N6/N9/N#
; 2nd Step : btst.b #1,$FFFF9201.w -> PadB FIREA/FIREB/FIREC/OPTION 
; 3rd Step : If the Bit is 0, then OPTION is Held Down, else NOT !

; ### DRIVER Informations #####################################################
;
; JOYPAD_A_ADDR_TABLE -> JOYPAD_A_ADDR_DIRECTION -> Routine Invoked on DIRECTION Event
;                        JOYPAD_A_ADDR_FIRE      -> Routine Invoked on FIRE Event
;                        JOYPAD_A_ADDR_SPECIAL   -> Routine Invoked on SPECIAL Event
;                        JOYPAD_A_ADDR_PAUSE     -> Routine Invoked on PAUSE Event
;                        JOYPAD_A_ADDR_OPTION    -> Routine Invoked on OPTION Event
;                        JOYPAD_A_ADDR_RESET     -> Routine Invoked on RESET Event
;                        JOYPAD_A_ADDR_MUSIC     -> Routine Invoked on MUSIC Event
;                        JOYPAD_A_ADDR_NUMERIC   -> Routine Invoked on NUMERIC Event
;
; JOYPAD_B_ADDR_TABLE -> JOYPAD_B_ADDR_DIRECTION -> Routine Invoked on DIRECTION Event
;                        JOYPAD_B_ADDR_FIRE      -> Routine Invoked on FIRE Event
;                        JOYPAD_B_ADDR_SPECIAL   -> Routine Invoked on SPECIAL Event
;                        JOYPAD_B_ADDR_PAUSE     -> Routine Invoked on PAUSE Event
;                        JOYPAD_B_ADDR_OPTION    -> Routine Invoked on OPTION Event
;                        JOYPAD_B_ADDR_RESET     -> Routine Invoked on RESET Event
;                        JOYPAD_B_ADDR_MUSIC     -> Routine Invoked on MUSIC Event
;                        JOYPAD_B_ADDR_NUMERIC   -> Routine Invoked on NUMERIC Event
;
; When a Routine is Invoked, U gad in :
;
;   D0.w : Parameter of the Routine (see just below)
;   D1.w : Status  0 - Same Status
;                 -1 - Released / Status changed to NULL
;               else - Previous Parameter / Different Status
;   D2.w : JoyPAD  1 - PadA
;                  0 - PadB
;
; For the DIRECTION Event, in D0.w :
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                         > ACTIVE HI <           0 0 0 0 0 0 0 0 0 0 0 0 | | | |
;                                                                         | | | |
;                         PadX RIGHT -------------------------------------' | | |
;                         PadX LEFT ----------------------------------------' | |
;                         PadX LOW -------------------------------------------' |
;                         PadX HI ----------------------------------------------'
;
; For the FIRE Event, in D0.w :
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                         > ACTIVE HI <           0 0 0 0 0 0 0 0 0 0 0 0 0 | | |
;                                                                           | | |
;                         PadX FIREC ---------------------------------------' | |
;                         PadX FIREB -----------------------------------------' |
;                         PadX FIREA -------------------------------------------'
;
; For the SPECIAL Event, in D0.w :
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                         > ACTIVE HI <           0 0 0 0 0 0 0 0 0 0 0 0 0 0 | |
;                                                                             | |
;                         PadX OPTION ----------------------------------------' |
;                         PadX PAUSE -------------------------------------------'
;
; For the PAUSE Event, in D0.w :
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                         > ACTIVE HI <           0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 |
;                                                                               |
;                         PadX PAUSE -------------------------------------------'
;
; For the OPTION Event, in D0.w :
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                         > ACTIVE HI <           0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 |
;                                                                               |
;                         PadX OPTION ------------------------------------------'
;
; For the RESET Event, in D0.w :
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                         > ACTIVE HI <           | | | | | | | | | | | | | | | |
;                                                 | | | | | | | | | | | | | | | |
;                         PadX RESET -------------+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-'
;
; For the MUSIC Event, in D0.w :
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                         > ACTIVE HI <           | | | | | | | | | | | | | | | |
;                                                 | | | | | | | | | | | | | | | |
;                         PadX MUSIC -------------+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-'
;
; For the NUMERIC Event, in D0.w :
;                         BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
;                         > ACTIVE HI <           0 0 0 0 | | | | | | | | | | | |
;                                                         | | | | | | | | | | | |
;                         PadX N# ------------------------' | | | | | | | | | | |
;                         PadX N0 --------------------------' | | | | | | | | | |
;                         PadX N* ----------------------------' | | | | | | | | |
;                         PadX N9 ------------------------------' | | | | | | | |
;                         PadX N8 --------------------------------' | | | | | | |
;                         PadX N7 ----------------------------------' | | | | | |
;                         PadX N6 ------------------------------------' | | | | |
;                         PadX N5 --------------------------------------' | | | |
;                         PadX N4 ----------------------------------------' | | |
;                         PadX N3 ------------------------------------------' | |
;                         PadX N2 --------------------------------------------' |
;                         PadX N1 ----------------------------------------------'
;

; Now, the Routine which Convert JoyPadPort into NormalizedBitField
	
	; *** Commands for Assembly

	output	JOYPADS.SOD
	opt	p=68030/68882
	comment	HEAD=7	; FastLoad

; /////////////////////////////////////////////////////////////////////////////	
	SECTION	TEXT
; /////////////////////////////////////////////////////////////////////////////	
;
;JOYPAD_Native_Handler	dc.l	JOYPAD_Header
;	dc.l	JOYPAD_Langage
;	dc.l	JOYPAD_HardWare
;	dc.l	JOYPAD_Identity
;	dc.l	JOYPAD_Interface	
;	dc.l	
;	dc.l	
;
;JOYPAD_Header	dc.b
;
;
;
;JOYPAD_Langage	dc.b	"\MC68030",0
;JOYPAD_HardWare	dc.b	"\Falcon030",0
;JOYPAD_Identity	dc.b	"\JoyPAD",0
;JOYPAD_Interface	dc.w	2
;	dc.l	JOYPAD_InterPadA
;	dc.l	JOYPAD_InterPadB
;
;
;
;
;JOYPAD_InterPadA	dc.w	$0203
;	dc.l	JOYPAD_A_ADDR_TABLE
;	dc.b	"\PadA",0
;JOYPAD_InterPadB	dc.w	$0203
;	dc.l	JOYPAD_B_ADDR_TABLE
;	dc.b	"\PadB",0
;
;
;
;
;
;

JOYPAD_XBRAName	dc.b	"XBRA"
	dc.b	"JPad"
JOYPAD_OldJPadRoutine	ds.l	1
JOYPAD_ConvertRoutine	lea	JOYPAD_ConvertTable,A0

	clr.l	D6	; PadA
	clr.l	D7	; PadB

	clr.l	D2
	clr.l	D3

	moveq.l	#2,D1	; 1/3 Lines

JOYPAD_LineSelect	moveq.l	#-1,D4

	move.l	D1,D2
	addq.l	#1,D2
	bclr.l	D2,D4
	addq.l	#4,D2
	bclr.l	D2,D4

	moveq.w	#4,D0	; 5 Columns

JOYPAD_GrabColumn	move.l	D4,$FFFF9200.w	; JOYPAD
	move.l	$FFFF9200.w,D5	; JOYPAD
		
	move.b	(A0)+,D2	; PadB
	swap	D2
	move.b	(A0)+,D2	; PadA
	move.b	(A0)+,D3

	btst.l	D2,D5	; JOYPAD
	BNE	JOYPAD_CheckPadB
	
	bset.l	D3,D6
		
JOYPAD_CheckPadB	swap	D2
	btst.l	D2,D5	; JOYPAD
	BNE	JOYPAD_CheckPadA
	
	bset.l	D3,D7
		
JOYPAD_CheckPadA	DBF	D0,JOYPAD_GrabColumn
	
	DBF	D1,JOYPAD_LineSelect

	tst.l	D1
	BMI	JOYPAD_CheckSTATUS

	moveq.w	#5,D0
	swap	D1
	move.l	#$FFFFFFEE,D4
	
	BRA	JOYPAD_GrabColumn
	
	; *** Check JOYPAD ***
	
JOYPAD_CheckSTATUS	move.l	D6,JOYPAD_A_DIRECTION
	move.l	D7,JOYPAD_B_DIRECTION

	; *** 0 : Check DIRECTION ***

JOYPAD_CheckDIRECTION	move.w	JOYPAD_A_DIRECTION,D0
	move.w	JOYPAD_A_OLD_DIRECTION,D1
	moveq.w	#1,D2
	movea.l	([JOYPAD_A_ADDR_TABLE]),A0

JOYPAD_LoopDIRECTION	andi.w	#%1111,D0
	andi.w	#%1111,D1
	
	BSR	JOYPAD_CompareStatus
	
	tst.w	D2
	BEQ	JOYPAD_CheckFIRE
	
	move.w	JOYPAD_B_DIRECTION,D0
	move.w	JOYPAD_B_OLD_DIRECTION,D1
	movea.l	([JOYPAD_B_ADDR_TABLE]),A0
	
	DBF	D2,JOYPAD_LoopDIRECTION

	; *** 4 : Check FIRE ***

JOYPAD_CheckFIRE	move.w	JOYPAD_A_BUTTONS,D0
	move.w	JOYPAD_A_OLD_BUTTONS,D1
	moveq.w	#1,D2
	movea.l	([JOYPAD_A_ADDR_TABLE],4),A0

JOYPAD_LoopFIRE	rol.w	#4,D0
	rol.w	#4,D1
	andi.w	#%111,D0
	andi.w	#%111,D1

	BSR	JOYPAD_CompareStatus
	
	tst.w	D2
	BEQ	JOYPAD_CheckSPECIAL
	
	move.w	JOYPAD_B_BUTTONS,D0
	move.w	JOYPAD_B_OLD_BUTTONS,D1
	movea.l	([JOYPAD_B_ADDR_TABLE],4),A0

	DBF	D2,JOYPAD_LoopFIRE

	; *** 8 : Check SPECIAL ***

JOYPAD_CheckSPECIAL	move.w	JOYPAD_A_DIRECTION,D0
	move.w	JOYPAD_A_OLD_DIRECTION,D1
	moveq.w	#1,D2
	movea.l	([JOYPAD_A_ADDR_TABLE],8),A0

JOYPAD_LoopSPECIAL	ror.w	#4,D0
	ror.w	#4,D1
	andi.w	#%11,D0
	andi.w	#%11,D1
		
	BSR	JOYPAD_CompareStatus
	
	tst.w	D2
	BEQ	JOYPAD_CheckPAUSE

	move.w	JOYPAD_B_DIRECTION,D0
	move.w	JOYPAD_B_OLD_DIRECTION,D1
	movea.l	([JOYPAD_B_ADDR_TABLE],8),A0

	DBF	D2,JOYPAD_LoopSPECIAL

	; *** 12 : Check PAUSE ***

JOYPAD_CheckPAUSE	move.w	JOYPAD_A_DIRECTION,D0
	move.w	JOYPAD_A_OLD_DIRECTION,D1
	moveq.w	#1,D2
	movea.l	([JOYPAD_A_ADDR_TABLE],12),A0
	
JOYPAD_LoopPAUSE	ror.w	#4,D0
	ror.w	#4,D1
	andi.w	#%1,D0
	andi.w	#%1,D1

	BSR	JOYPAD_CompareStatus
	
	tst.w	D2
	BEQ	JOYPAD_CheckOPTION

	move.w	JOYPAD_B_DIRECTION,D0
	move.w	JOYPAD_B_OLD_DIRECTION,D1
	movea.l	([JOYPAD_B_ADDR_TABLE],12),A0
	
	DBF	D2,JOYPAD_LoopPAUSE
	
	; *** 16 : Check OPTION ***

JOYPAD_CheckOPTION	move.w	JOYPAD_A_DIRECTION,D0
	move.w	JOYPAD_A_OLD_DIRECTION,D1
	moveq.w	#1,D2
	movea.l	([JOYPAD_A_ADDR_TABLE],16),A0
	
JOYPAD_LoopOPTION	ror.w	#5,D0
	ror.w	#5,D1
	andi.w	#%1,D0
	andi.w	#%1,D1
	
	BSR	JOYPAD_CompareStatus
	
	tst.w	D2
	BEQ	JOYPAD_CheckRESET

	move.w	JOYPAD_B_DIRECTION,D0
	move.w	JOYPAD_B_OLD_DIRECTION,D1
	movea.l	([JOYPAD_B_ADDR_TABLE],16),A0
	
	DBF	D2,JOYPAD_LoopOPTION
	
	; *** 20 : Check RESET ***

JOYPAD_CheckRESET	move.w	JOYPAD_A_BUTTONS,D0
	move.w	JOYPAD_A_OLD_BUTTONS,D1
	moveq.w	#1,D2
	movea.l	([JOYPAD_A_ADDR_TABLE],20),A0
	
JOYPAD_LoopRESET	andi.w	#%111111111111,D0
	andi.w	#%111111111111,D1

	cmpi.w	#%101000000000,D0
	SEQ	D0
	
	cmpi.w	#%101000000000,D1
	SEQ	D1

	ext.w	D0
	ext.w	D1
	
	BSR	JOYPAD_CompareStatus
	
	tst.w	D2
	BEQ	JOYPAD_CheckMUSIC
	
	move.w	JOYPAD_B_BUTTONS,D0
	move.w	JOYPAD_B_OLD_BUTTONS,D1
	movea.l	([JOYPAD_B_ADDR_TABLE],20),A0

	DBF	D2,JOYPAD_LoopRESET

	; *** 24 : Check MUSIC ***

JOYPAD_CheckMUSIC	move.w	JOYPAD_A_BUTTONS,D0
	move.w	JOYPAD_A_OLD_BUTTONS,D1
	moveq.w	#1,D2
	movea.l	([JOYPAD_A_ADDR_TABLE],24),A0

JOYPAD_LoopMUSIC	andi.w	#%111111111111,D0
	andi.w	#%111111111111,D1

	cmpi.w	#%010000000000,D0
	SEQ	D0
	
	cmpi.w	#%010000000000,D1
	SEQ	D1
	
	ext.w	D0
	ext.w	D1
	
	BSR	JOYPAD_CompareStatus
	
	tst.w	D2
	BEQ	JOYPAD_CheckNUMERIC

	move.w	JOYPAD_B_BUTTONS,D0
	move.w	JOYPAD_B_OLD_BUTTONS,D1
	movea.l	([JOYPAD_B_ADDR_TABLE],24),A0

	DBF	D2,JOYPAD_LoopMUSIC

	; *** 28 : Check NUMERIC ***

JOYPAD_CheckNUMERIC	move.w	JOYPAD_A_BUTTONS,D0
	move.w	JOYPAD_A_OLD_BUTTONS,D1
	moveq.w	#1,D2
	movea.l	([JOYPAD_A_ADDR_TABLE],28),A0


JOYPAD_LoopNUMERIC	andi.w	#%111111111111,D0
	andi.w	#%111111111111,D1
			
	BSR	JOYPAD_CompareStatus
	
	tst.w	D2
	BEQ	JOYPAD_NextJPadRout

	move.w	JOYPAD_B_BUTTONS,D0
	move.w	JOYPAD_B_OLD_BUTTONS,D1
	movea.l	([JOYPAD_B_ADDR_TABLE],28),A0

	DBF	D2,JOYPAD_LoopNUMERIC

JOYPAD_NextJPadRout	move.l	JOYPAD_A_DIRECTION,JOYPAD_A_OLD_DIRECTION
	move.l	JOYPAD_B_DIRECTION,JOYPAD_B_OLD_DIRECTION

	JMP	([JOYPAD_OldJPadRoutine])

	; *** Compare Status ***

	; D0.w : Parameters
	; D1.w : Status  0 - Same
	;               -1 - Released
	;             else - Old Status
	; D2.w : JoyPAD  1 - PadA
	;                0 - PadB

JOYPAD_CompareStatus	tst.w	D0
	BNE	JOYPAD_TestStatus

	; NEW State NULL
	; Check if the Previous (OLD) State wasn't
	
	tst.w	D1
	BEQ	JOYPAD_NextStatus
	
	; OLD State wasn't NULL
	; Something RELEASED !
	
	moveq.w	#-1,D1
	
	BRA	JOYPAD_GoStatus
	
JOYPAD_TestStatus	cmp.w	D0,D1
	BNE	JOYPAD_GoStatus
	
	; NO CHANGES
	
	clr.w	D1

JOYPAD_GoStatus	movem.l	D0-D2/A0,JOYPAD_SaveRegisters

	JSR	(A0)
	
	movem.l	JOYPAD_SaveRegisters,D0-D2/A0

JOYPAD_NextStatus	RTS

; /////////////////////////////////////////////////////////////////////////////	
	SECTION	DATA
; /////////////////////////////////////////////////////////////////////////////	

	; *** Conversion Table - KOSS 2000 ***
	; BitNumber of : PadA, PadB, PadBF (of JOYPAD)

JOYPAD_ConvertTable	dc.b	19,17,21	; OPTION
	dc.b	15,11,2	; N3
	dc.b	14,10,5	; N6
	dc.b	13,9,8	; N9
	dc.b	12,8,11	; N#

	dc.b	19,17,14	; FIREC
	dc.b	15,11,1	; N2
	dc.b	14,10,4	; N5
	dc.b	13,9,7	; N8
	dc.b	12,8,10	; N0
	
	dc.b	19,17,13	; FIREB
	dc.b	15,11,0	; N1
	dc.b	14,10,3	; N4
	dc.b	13,9,6	; N7
	dc.b	12,8,9	; N*

	dc.b	19,17,12	; FIREA
	dc.b	18,16,20	; PAUSE
	dc.b	15,11,19	; RIGHT
	dc.b	14,10,18	; LEFT
	dc.b	13,9,17	; LOW
	dc.b	12,8,16	; HI
	
	EVEN
	
; /////////////////////////////////////////////////////////////////////////////	
	SECTION	BSS
; /////////////////////////////////////////////////////////////////////////////	

	; *** Utilities ***
	
JOYPAD_SaveRegisters	ds.l	4

	; *** JOYPAD A ***

JOYPAD_A_DIRECTION	ds.w	1
	; BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
	; > ACTIVE HI <           0 0 0 0 0 0 0 0 0 0 | | | | | |
	;                                             | | | | | |
	; PadA OPTION --------------------------------' | | | | |
	; PadA PAUSE -----------------------------------' | | | |
	; PadA RIGHT -------------------------------------' | | |
	; PadA LEFT ----------------------------------------' | |
	; PadA LOW -------------------------------------------' |
	; PadA HI ----------------------------------------------'
	
JOYPAD_A_BUTTONS	ds.w	1
	; BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
	; > ACTIVE HI <           0 | | | | | | | | | | | | | | |
	;                           | | | | | | | | | | | | | | |
	; PadA FIREC ---------------' | | | | | | | | | | | | | |
	; PadA FIREB -----------------' | | | | | | | | | | | | |
	; PadA FIREA -------------------' | | | | | | | | | | | |
	; PadA N# ------------------------' | | | | | | | | | | |
	; PadA N0 --------------------------' | | | | | | | | | |
	; PadA N* ----------------------------' | | | | | | | | |
	; PadA N9 ------------------------------' | | | | | | | |
	; PadA N8 --------------------------------' | | | | | | |
	; PadA N7 ----------------------------------' | | | | | |
	; PadA N6 ------------------------------------' | | | | |
	; PadA N5 --------------------------------------' | | | |
	; PadA N4 ----------------------------------------' | | |
	; PadA N3 ------------------------------------------' | |
	; PadA N2 --------------------------------------------' |
	; PadA N1 ----------------------------------------------'

JOYPAD_A_OLD_DIRECTION	ds.w	1
JOYPAD_A_OLD_BUTTONS	ds.w	1

JOYPAD_A_ADDR_TABLE	ds.l	1

	; *** JOYPAD B ***

JOYPAD_B_DIRECTION	ds.w	1
	; BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
	; > ACTIVE HI <           0 0 0 0 0 0 0 0 0 0 | | | | | |
	;                                             | | | | | |
	; PadB OPTION --------------------------------' | | | | |
	; PadB PAUSE -----------------------------------' | | | |
	; PadB RIGHT -------------------------------------' | | |
	; PadB LEFT ----------------------------------------' | |
	; PadB LOW -------------------------------------------' |
	; PadB HI ----------------------------------------------'

JOYPAD_B_BUTTONS	ds.w	1
	; BitField            BIT F E D C B A 9 8 7 6 5 4 3 2 1 0
	; > ACTIVE HI <           0 | | | | | | | | | | | | | | |
	;                           | | | | | | | | | | | | | | |
	; PadB FIREC ---------------' | | | | | | | | | | | | | |
	; PadB FIREB -----------------' | | | | | | | | | | | | |
	; PadB FIREA -------------------' | | | | | | | | | | | |
	; PadB N# ------------------------' | | | | | | | | | | |
	; PadB N0 --------------------------' | | | | | | | | | |
	; PadB N* ----------------------------' | | | | | | | | |
	; PadB N9 ------------------------------' | | | | | | | |
	; PadB N8 --------------------------------' | | | | | | |
	; PadB N7 ----------------------------------' | | | | | |
	; PadB N6 ------------------------------------' | | | | |
	; PadB N5 --------------------------------------' | | | |
	; PadB N4 ----------------------------------------' | | |
	; PadB N3 ------------------------------------------' | |
	; PadB N2 --------------------------------------------' |
	; PadB N1 ----------------------------------------------'

JOYPAD_B_OLD_DIRECTION	ds.w	1
JOYPAD_B_OLD_BUTTONS	ds.w	1

JOYPAD_B_ADDR_TABLE	ds.l	1
