;Desert Drain V1.52 680x0er Disassembler 15.01.2000 20:34:44
;DATEI: DESA6301.RO 2705 Bytes
;TEXT: 1124 $00464
;DATA: 1538 $00602

; /////////////////////////////////////////////////////////////////////////////
	SECTION TEXT
; /////////////////////////////////////////////////////////////////////////////
	
	BRA	StartDisASM6301

	dc.b	"PHYSENDM"

StartDisASM6301	tst.w	(114,A0)
	BGT	InitDisASM6301

	; WARNING : Reserve Memory on the top of the RAM

;	move.l	#-1,-(SP)
;	move.l	#-1,-(SP)
	move.w	#-1,-(SP)
	move.w	#1,-(SP)	; - Ssbrk -
	trap	#14	; *** XBIOS ***
	lea	(12,SP),SP

InitDisASM6301	dc.w	$A00A	; Line A - HideMouse

	move.l	$FFFF8240.w,OldColor0	; ST Color0
	move.b	D0,D_A64

	; Print the main screen

	lea	Text_MainBoard,A5
	BSR	PrintOnScreen

	; Get the Address of the Logical Screen

	move.w	#3,-(SP)	; - LogBase -
	trap	#14	; *** XBIOS ***
	addq.w	#2,SP
	
	move.l	D0,OldLogicalScreenAddress
	
	; Get the Keyboard Handler
	
	move.w	#$22,-(SP)	; - KbdVBase -
	trap	#14	; *** XBIOS ***
	addq.w	#2,SP
	
	; Modify some Values
	
	movea.l	D0,A0
	move.l	A0,OldACIADispatchHandler

	move.l	(12,A0),OldIKBDStatusPacket
	move.l	#NewIKBDStatusPacket,(12,A0)
	
	; Init some Variables
	
	move.w	#$0D0A,Text_EndOfLine
	
	move.b	#$16,D_A5D

T_76	lea	D_A55,A4
T_7A	sf	(A4)

	; Send Command to the IKBD 6301

	pea	IKBDCommStartReadAtF000
	move.w	#2,-(SP)
	move.w	#$19,-(SP)	; - IKBDWS -
	trap	#14	; *** XBIOS ***
	addq.w	#8,SP

T_8A	move.b	(A4),D0
	BEQ	T_8A

	; Space ?

	cmp.b	#' ',D0
	BNE	T_7A

	; Fill the Table

	lea	D_A30,A0
	moveq.l	#16,D0

T_9A	move.w	#'  ',(A0,D0.w*2)

	DBF	D0,T_9A

	moveq.l	#':',D0
	move.b	D0,(5,A0)
	move.b	D0,(16,A0)
	moveq.l	#0,D6
	moveq.l	#0,D0
	
	lea	D_5DC,A1
	move.w	(A1),D0
	move.b	(A1)+,D7

	BSR	WriteHexOfD7InA0PlusD6

	move.b	(A1),D7

	BSR	WriteHexOfD7InA0PlusD6

	lea	D_A56,A6
	moveq.l	#0,D0
	move.b	(A6),D0
	move.b	D0,D7
	moveq.l	#7,D6

	BSR	WriteHexOfD7InA0PlusD6

	move.w	D0,D1
	move.w	D0,D2
	lsr.w	#2,D1
	lea	D_9DE,A1
	move.b	(A1,D1.w),D1
	andi.b	#3,D2
	add.b	D2,D2
	lsr.b	D2,D1
	andi.b	#3,D1
	lea	D_A5C,A4
	move.b	D1,(A4)

	cmpi.b	#$1F,D0
	BLS	T_130

	cmpi.b	#$30,D0
	BLS	T_106

	cmpi.b	#-$73,D0
	BNE	T_130

T_106	st	D_A5F
	move.b	(1,A6),D1
	ext.w	D1
	move.w	D_5DC,D2
	add.w	D1,D2
	addq.w	#2,D2
	move.b	D2,D7
	moveq.l	#$1C,D6

	BSR	WriteHexOfD7InA0PlusD6

	lsr.w	#8,D2
	move.b	D2,D7
	moveq.l	#$1A,D6

	BSR	WriteHexOfD7InA0PlusD6

	BRA	T_21A

T_130	cmpi.b	#-$33,D0
	BEQ	T_26A

	move.b	D0,D1
	andi.b	#-$10,D1

	cmpi.b	#-$80,D1
	BEQ	T_156

	cmpi.b	#-$40,D1
	BNE	T_160

	move.b	D0,D1
	moveq.l	#7,D2
	and.b	D2,D1

	sub.b	D2,D1
	BEQ	T_26A

T_156	move.w	#'#$',(24,A0)

	BRA	T_21A

T_160	cmpi.b	#-$70,D1
	BEQ	T_16C

	cmpi.b	#-$30,D1
	BNE	T_17E

T_16C	move.l	#' $00',(24,A0)
	lea	D_A5E,A5
	st	(A5)

	BRA	T_21A

T_17E	cmpi.b	#-$60,D1
	BEQ	T_190

	cmpi.b	#-$20,D1
	BEQ	T_190

	cmpi.b	#$60,D1
	BNE	T_196

T_190	move.w	#',X',(28,A0)
T_196	move.b	D0,D1
	ori.b	#$1F,D1

	cmpi.b	#$7F,D1
	BNE	T_21A

	move.b	D0,D1
	andi.b	#15,D1

	cmpi.b	#1,D1
	BEQ	T_1C0

	cmpi.b	#2,D1
	BEQ	T_1C0

	cmpi.b	#5,D1
	BEQ	T_1C0

	cmpi.b	#11,D1
	BNE	T_21A

T_1C0	move.w	#'#$',(24,A0)
	moveq.l	#$1A,D6
	move.b	(1,A6),D7

	BSR	WriteHexOfD7InA0PlusD6

	moveq.l	#10,D6
	move.b	(1,A6),D7

	BSR	WriteHexOfD7InA0PlusD6

	moveq.l	#13,D6
	move.b	(2,A6),D7

	BSR	WriteHexOfD7InA0PlusD6

	cmpi.b	#$71,D0
	BEQ	T_1FC

	cmpi.b	#$72,D0
	BEQ	T_1FC

	cmpi.b	#$75,D0
	BEQ	T_1FC

	cmpi.b	#$7B,D0
	BNE	InitDisASM63018

T_1FC	move.l	#',$00',(28,A0)
	moveq.l	#$20,D6

	BRA	T_262

InitDisASM63018	moveq.l	#$2C,D6
	move.w	#',$',(28,A0)
	move.w	#'+X',(32,A0)
	moveq.l	#$1E,D6

	BRA	T_262

T_21A	move.b	D_A5C,D5

	subq.b	#1,D5
	BEQ	T_26A

	moveq.l	#10,D6
	move.b	(1,A6),D7

	BSR	WriteHexOfD7InA0PlusD6

	move.b	#$24,$19(A0)

	tst.b	D_A5F
	BNE	T_26A

	lea	D_A5E,A1

	tst.b	(A1)
	BMI	T_246

	moveq.l	#$1A,D6

	BRA	T_24A

T_246	moveq.l	#$1C,D6
	sf	(A1)
T_24A	move.b	1(A6),D7

	BSR	WriteHexOfD7InA0PlusD6

	subq.b	#1,D5
	BEQ	T_26A

	moveq.l	#13,D6
	move.b	2(A6),D7

	BSR	WriteHexOfD7InA0PlusD6

	moveq.l	#$1C,D6
T_262	move.b	2(A6),D7

	BSR	WriteHexOfD7InA0PlusD6

T_26A	sf	D_A5F
	lea	Text_6301OpCodeBank,A1
	add.w	D0,D0
	add.w	D0,D0
	move.l	0(A1,D0.w),$12(A0)
	lea	D_A30,A5

	BSR	PrintOnScreen

	lea	D_5DC,A0
	move.b	D_A5C,D0
	ext.w	D0
	add.w	D0,(A0)
	lea	D_A5D,A0

	tst.b	(A0)
	BEQ	T_2AA

	subq.b	#1,(A0)
	BNE	T_76

	lea	Text_EndOfLine,A4
	clr.w	(A4)

	BRA	T_76

T_2AA	BSR	ReadAnyKeyWithoutEcho

	cmpi.b	#$1B,D0
	BEQ	T_2CC

	swap	D0

	cmpi.b	#$50,D0
	BNE	T_2AA

T_2BC	BSR	T_3F2

	lea	Text_GotoPreLastLine,A5

	BSR	PrintOnScreen

	BRA	T_76

T_2CC	lea	Text_EnterNewAddress,A5

	BSR	PrintOnScreen

	moveq.l	#0,D7
	lea	D_A60,A3
	move.l	#'0000',(A3)

	BRA	T_2F4

T_2E2	tst.b	D7
	BEQ	T_2F4

	move.b	#$30,-(A3)
	subq.l	#1,D7
	lea	Text_CursorOnTheLeft,A5

	BSR	PrintOnScreen

T_2F4	BSR	ReadAnyKeyWithoutEcho

	swap	D0

	cmpi.b	#$61,D0
	BNE	T_30A

	lea	Text_EraseEndOfLastLine,A5

	BSR	PrintOnScreen

	BRA	T_2AA

T_30A	swap	D0

	tst.b	D7
	BNE	T_318

	cmpi.b	#$1B,D0
	BEQ	RestoreOldConfiguration

T_318	cmpi.b	#8,D0
	BEQ	T_2E2

	cmpi.b	#13,D0
	BNE	T_326

	BRA	T_35A

T_326	cmpi.b	#4,D7
	BEQ	T_2F4

	cmpi.b	#$30,D0
	BCS	T_2F4

	cmpi.b	#$39,D0
	BLS	T_348

	andi.b	#-$21,D0

	cmpi.b	#$41,D0
	BCS	T_2F4

	cmpi.b	#$46,D0
	BHI	T_2F4

T_348	addq.w	#1,D7
	move.b	D0,(A3)+
	move.w	D0,-(SP)
	pea	$30005	;Bconout
	trap	#13
	addq.w	#6,SP

	BRA	T_2F4

T_35A	lea	Text_EraseEndOfLastLine,A5

	BSR	PrintOnScreen

	subq.w	#4,D7
	neg.w	D7
	lsl.w	#3,D7
	move.l	D_A60,D0
	ror.l	D7,D0
	moveq.l	#0,D1
	moveq.l	#3,D2
T_372	rol.l	#8,D0
	subi.b	#$30,D0

	cmpi.b	#9,D0
	BLS	T_380

	subq.b	#7,D0
T_380	lsl.w	#4,D1
	add.b	D0,D1

	DBRA	D2,T_372

	move.w	D1,D_A1E
	move.w	D1,D_5DC

	BSR	T_3F2

	BSR	T_42C

	BRA	T_2BC

; *****************************************************************************

RestoreOldConfiguration	movea.l	OldACIADispatchHandler,A0
	move.l	OldIKBDStatusPacket,12(A0)
	lea	Text_VideoNormal,A5

	BSR	PrintOnScreen

	move.l	OldColor0,$FFFF8240.w	; ST Color0
	dc.w	$A009	; Line A - Show Mouse

	RTS	

; *****************************************************************************

ReadAnyKeyWithoutEcho	move.w	#7,-(SP)	; - C_RAWCIN -
	trap	#1	; *** GEMDOS ***
	addq.w	#2,SP

	RTS	

; *****************************************************************************

PrintOnScreen	move.l	A5,-(SP)
	move.w	#9,-(SP)	; - C_CONWS -
	trap	#1	; *** GEMDOS ***
	addq.w	#6,SP

	RTS	

; *****************************************************************************

WriteHexOfD7InA0PlusD6	moveq.l	#1,D4

HexOfD7_WorkOnNibble	rol.b	#4,D7
	move.b	D7,D3
	andi.b	#$0F,D3
	addi.b	#'0',D3

	cmpi.b	#'9',D3
	BLS	HexOfD7_Range0To9OK

	addq.b	#7,D3
	
HexOfD7_Range0To9OK	move.b	D3,(A0,D6.w)
	addq.b	#1,D6

	DBRA	D4,HexOfD7_WorkOnNibble

	RTS	

; *****************************************************************************

T_3F2	movea.l	OldLogicalScreenAddress,A0
	lea	($500,A0),A0
	
	move.w	#175,D0
	moveq.l	#88,D3
	move.b	D_A64,D1

	andi.w	#1,D1
	BNE	T_412

	addi.w	#$B0,D0
	moveq.l	#$2C,D3
T_410	move.w	D1,D2
T_412	movem.l	($500,A0),D4-D7/A2-A6
	movem.l	D4-D7/A2-A6,(A0)
	lea	$24(A0),A0

	DBRA	D2,T_412

	adda.w	D3,A0

	DBRA	D0,T_410

	RTS	

T_42C	moveq.l	#0,D4
	moveq.l	#7,D0

	tst.w	D1
	BNE	T_436

	addq.w	#8,D0
T_436	move.w	D1,D2
T_438	move.l	D4,(A0)+
	move.l	D4,(A0)+
	move.l	D4,(A0)+
	move.l	D4,(A0)+
	move.l	D4,(A0)+
	move.l	D4,(A0)+
	move.l	D4,(A0)+
	move.l	D4,(A0)+
	move.l	D4,(A0)+

	DBRA	D2,T_438

	adda.w	D3,A0

	DBRA	D0,T_436

	RTS	

NewIKBDStatusPacket	moveq.l	#6,D0
	lea	D_A55,A1
T_45C	move.b	(A0)+,(A1)+

	DBRA	D0,T_45C

	RTS	
; /////////////////////////////////////////////////////////////////////////////
	SECTION DATA
; /////////////////////////////////////////////////////////////////////////////

Text_MainBoard	dc.b	27,"Y",0+32,0+32	; Goto YX
	dc.b	27,"J"	; Clear Screen
	dc.b	27,"v"	; Wrap Line On
	dc.b	27,"f"	; Disable cursor
	dc.b	27,"p"	; Video Inverse	
	dc.b	"  "
	dc.b	"HITACHI HD6301V1 Micro "
	dc.b	"Processing Unit Disasembler "
	dcb.b	12," "
	dc.b	"06 April 1990 "
	dc.b	" "
	dc.b	27,"j"	; Save Cursor
	dc.b	27,"w"	; Wrap Line Off
	
	dc.b	27,"Y",24+32,0+32	; Goto YX
	dc.b	"  [ESC] New Address"
	dcb.b	41," "
	dc.b	"[ESC] - [ESC] Quit  "
	
	dc.b	27,"q"	; Video Normal
	dc.b	27,"Y",4+32,46+32	; Goto YX
	dc.b	"0000..001F : Internal Registers"
	dc.b	27,"Y",5+32,46+32	; Goto YX
	dc.b	"0080..00FF : Internal Ram"
	dc.b	27,"Y",6+32,46+32	; Goto YX
	dc.b	"F000..FFFF : Internal Rom"
	dc.b	27,"k",0	; Restore Cursor
	
Text_GotoPreLastLine	dc.b	27,"Y",23+32,0+32,0

Text_EnterNewAddress	dc.b	27,"p"
	dc.b	27,"Y86"
	dc.b	"($0000-$FFFF) $____ [UNDO]=Abort"
	dc.b	27,"Y8E"
	dc.b	27,"e",0

Text_CursorOnTheLeft	dc.b	27,"D"	; Cursor Left
	dc.b	"_"
	dc.b	27,"D"	; Cursor Left
	dc.b	0

Text_EraseEndOfLastLine	dc.b	27,"f"	; Disable Cursor
	dc.b	27,"Y",24+32,22+32	; Goto YX
	dcb.b	37," "

Text_VideoNormal	dc.b	27,"q",0	; Video Normal

IKBDCommStartReadAtF000	dc.b	21
	dc.w	$F000
	dc.b	0

D_5DC	dc.w	$F000

Text_6301OpCodeBank	dc.b	"??? "	; 0
	dc.b	"NOP "	; 1
	dc.b	"??? "	; 2
	dc.b	"??? "	; 3
	dc.b	"LSRD"	; 4
	dc.b	"ASLD"	; 5
	dc.b	"TAP "	; 6
	dc.b	"TPA "	; 7
	dc.b	"INX "	; 8
	dc.b	"DEX "	; 9
	dc.b	"CLV "	; A
	dc.b	"SEV "	; B
	dc.b	"CLC "	; C
	dc.b	"SEC "	; D
	dc.b	"CLI "	; E
	dc.b	"SEI "	; F
	dc.b	"SBA "	; 10
	dc.b	"CBA "	; 11
	dc.b	"??? "	; 12
	dc.b	"??? "	; 13
	dc.b	"??? "	; 14
	dc.b	"??? "	; 15
	dc.b	"TAB "	; 16
	dc.b	"TBA "	; 17
	dc.b	"XGDX"	; 18
	dc.b	"DAA "	; 19
	dc.b	"SLP "	; 1A
	dc.b	"ABA "	; 1B
	dc.b	"??? "	; 1C
	dc.b	"??? "	; 1D
	dc.b	"??? "	; 1E
	dc.b	"??? "	; 1F
	dc.b	"BRA "	; 20 vvv Relative
	dc.b	"BRN "	; 21
	dc.b	"BHI "	; 22
	dc.b	"BLS "	; 23
	dc.b	"BCC "	; 24
	dc.b	"BCS "	; 25
	dc.b	"BNE "	; 26
	dc.b	"BEQ "	; 27
	dc.b	"BVC "	; 28
	dc.b	"BVS "	; 29
	dc.b	"BPL "	; 2A
	dc.b	"BMI "	; 2B
	dc.b	"BGE "	; 2C
	dc.b	"BLT "	; 2D
	dc.b	"BGT "	; 2E
	dc.b	"BLE "	; 2F ^^^ Relative
	dc.b	"TSX "	; 30
	dc.b	"INS "	; 31
	dc.b	"PULA"	; 32
	dc.b	"PULB"	; 33
	dc.b	"DES "	; 34
	dc.b	"TXS "	; 35
	dc.b	"PSHA"	; 36
	dc.b	"PSHB"	; 37
	dc.b	"PULX"	; 38
	dc.b	"RTS "	; 39
	dc.b	"ABX "	; 3A
	dc.b	"RTI "	; 3B
	dc.b	"PSHX"	; 3C
	dc.b	"MUL "	; 3D
	dc.b	"WAI "	; 3E
	dc.b	"SWI "	; 3F
	dc.b	"NEGA"	; 40
	dc.b	"??? "	; 41
	dc.b	"??? "	; 42
	dc.b	"COMA"	; 43
	dc.b	"LSRA"	; 44
	dc.b	"??? "	; 45
	dc.b	"RORA"	; 46
	dc.b	"ASRA"	; 47
	dc.b	"ASLA"	; 48
	dc.b	"ROLA"	; 49
	dc.b	"DECA"	; 4A
	dc.b	"??? "	; 4B
	dc.b	"INCA"	; 4C
	dc.b	"TSTA"	; 4D
	dc.b	"??? "	; 4E
	dc.b	"CLRA"	; 4F
	dc.b	"NEGB"	; 50
	dc.b	"??? "	; 51
	dc.b	"??? "	; 52
	dc.b	"COMB"	; 53
	dc.b	"LSRB"	; 54
	dc.b	"??? "	; 55
	dc.b	"RORB"	; 56
	dc.b	"ASRB"	; 57
	dc.b	"ASLB"	; 58
	dc.b	"ROLB"	; 59
	dc.b	"DECB"	; 5A
	dc.b	"??? "	; 5B
	dc.b	"INCB"	; 5C
	dc.b	"TSTB"	; 5D
	dc.b	"??? "	; 5E
	dc.b	"CLRB"	; 5F
	dc.b	"NEG "	; 60 vvv Indexed
	dc.b	"AIM "	; 61
	dc.b	"OIM "	; 62
	dc.b	"COM "	; 63
	dc.b	"LSR "	; 64
	dc.b	"EIM "	; 65
	dc.b	"ROR "	; 66
	dc.b	"ASR "	; 67
	dc.b	"ASL "	; 68
	dc.b	"ROL "	; 69
	dc.b	"DEC "	; 6A
	dc.b	"TIM "	; 6B
	dc.b	"INC "	; 6C
	dc.b	"TST "	; 6D
	dc.b	"JMP "	; 6E
	dc.b	"CLR "	; 6F ^^^ Indexed
	dc.b	"NEG "	; 70 vvv Extended
	dc.b	"AIM "	; 71
	dc.b	"OIM "	; 72
	dc.b	"COM "	; 73
	dc.b	"LSR "	; 74
	dc.b	"EIM "	; 75
	dc.b	"ROR "	; 76
	dc.b	"ASR "	; 77
	dc.b	"ASL "	; 78
	dc.b	"ROL "	; 79
	dc.b	"DEC "	; 7A
	dc.b	"TIM "	; 7B
	dc.b	"INC "	; 7C
	dc.b	"TST "	; 7D
	dc.b	"JMP "	; 7E
	dc.b	"CLR "	; 7F ^^^ Extended
	dc.b	"SUBA"	; 80 vvv Immediat
	dc.b	"CMPA"	; 81
	dc.b	"SBCA"	; 82
	dc.b	"SUBD"	; 83
	dc.b	"ANDA"	; 84
	dc.b	"BITA"	; 85
	dc.b	"LDAA"	; 86
	dc.b	"??? "	; 87
	dc.b	"EORA"	; 88
	dc.b	"ADCA"	; 89
	dc.b	"ORAA"	; 8A
	dc.b	"ADDA"	; 8B
	dc.b	"CPX "	; 8C
	dc.b	"BSR "	; 8D Relative
	dc.b	"LDS "	; 8E
	dc.b	"??? "	; 8F ^^^ Immediat
	dc.b	"SUBA"	; 90 vvv Direct
	dc.b	"CMPA"	; 91
	dc.b	"SBCA"	; 92
	dc.b	"SUBD"	; 93
	dc.b	"ANDA"	; 94
	dc.b	"BITA"	; 95
	dc.b	"LDAA"	; 96
	dc.b	"STAA"	; 97
	dc.b	"EORA"	; 98
	dc.b	"ADCA"	; 99
	dc.b	"ORAA"	; 9A
	dc.b	"ADDA"	; 9B
	dc.b	"CPX "	; 9C
	dc.b	"JSR "	; 9D
	dc.b	"LDS "	; 9E
	dc.b	"STS "	; 9F ^^^ Direct
	dc.b	"SUBA"	; A0 vvv Indexed
	dc.b	"CMPA"	; A1
	dc.b	"SBCA"	; A2
	dc.b	"SUBD"	; A3
	dc.b	"ANDA"	; A4
	dc.b	"BITA"	; A5
	dc.b	"LDAA"	; A6
	dc.b	"STAA"	; A7
	dc.b	"EORA"	; A8
	dc.b	"ADCA"	; A9
	dc.b	"ORAA"	; AA
	dc.b	"ADDA"	; AB
	dc.b	"CPX "	; AC
	dc.b	"JSR "	; AD
	dc.b	"LDS "	; AE
	dc.b	"STS "	; AF ^^^ Indexed
	dc.b	"SUBA"	; B0 vvv Extended
	dc.b	"CMPA"	; B1
	dc.b	"SBCA"	; B2
	dc.b	"SUBD"	; B3
	dc.b	"ANDA"	; B4
	dc.b	"BITA"	; B5
	dc.b	"LDAA"	; B6
	dc.b	"STAA"	; B7
	dc.b	"EORA"	; B8
	dc.b	"ADCA"	; B9
	dc.b	"ORAA"	; BA
	dc.b	"ADDA"	; BB
	dc.b	"CPX "	; BC
	dc.b	"JSR "	; BD
	dc.b	"LDS "	; BE
	dc.b	"STS "	; BF ^^^ Extended
	dc.b	"SUBB"	; C0 vvv Immediat
	dc.b	"CMPB"	; C1
	dc.b	"SBCB"	; C2
	dc.b	"ADDD"	; C3
	dc.b	"ANDB"	; C4
	dc.b	"BITB"	; C5
	dc.b	"LDAB"	; C6
	dc.b	"??? "	; C7
	dc.b	"EORB"	; C8
	dc.b	"ADCB"	; C9
	dc.b	"ORAB"	; CA
	dc.b	"ADDB"	; CB
	dc.b	"LDD "	; CC
	dc.b	"??? "	; CD
	dc.b	"LDX "	; CE
	dc.b	"??? "	; CF ^^^ Immediat
	dc.b	"SUBB"	; D0 vvv Direct
	dc.b	"CMPB"	; D1
	dc.b	"SBCB"	; D2
	dc.b	"ADDD"	; D3
	dc.b	"ANDB"	; D4
	dc.b	"BITB"	; D5
	dc.b	"LDAB"	; D6
	dc.b	"STAB"	; D7
	dc.b	"EORB"	; D8
	dc.b	"ADCB"	; D9
	dc.b	"ORAB"	; DA
	dc.b	"ADDB"	; DB
	dc.b	"LDD "	; DC
	dc.b	"STD "	; DD
	dc.b	"LDX "	; DE
	dc.b	"STX "	; DF ^^^ Direct
	dc.b	"SUBB"	; E0 vvv Indexed
	dc.b	"CMPB"	; E1
	dc.b	"SBCB"	; E2
	dc.b	"ADDD"	; E3
	dc.b	"ANDB"	; E4
	dc.b	"BITB"	; E5
	dc.b	"LDAB"	; E6
	dc.b	"STAB"	; E7
	dc.b	"EORB"	; E8
	dc.b	"ADCB"	; E9
	dc.b	"ORAB"	; EA
	dc.b	"ADDB"	; EB
	dc.b	"LDD "	; EC
	dc.b	"STD "	; ED
	dc.b	"LDX "	; EE
	dc.b	"STX "	; EF ^^^ Indexed
	dc.b	"SUBB"	; F0 vvv Extended
	dc.b	"CMPB"	; F1
	dc.b	"SBCB"	; F2
	dc.b	"ADDD"	; F3
	dc.b	"ANDB"	; F4
	dc.b	"BITB"	; F5
	dc.b	"LDAB"	; F6
	dc.b	"STAB"	; F7
	dc.b	"EORB"	; F8
	dc.b	"ADCB"	; F9
	dc.b	"ORAB"	; FA
	dc.b	"ADDB"	; FB
	dc.b	"LDD "	; FC
	dc.b	"STD "	; FD
	dc.b	"LDX "	; FE
	dc.b	"STX "	; FF ^^^ Extended

D_9DE	dc.b	"UUUUUUUUªªªªUUUUUUUUUUUU¾®"
	dc.b	"êªÿÿÿÿêjª{ªªªªªªªªÿÿÿÿêjªw"
	dc.b	"ªªªªªªªªÿÿÿÿ"

; /////////////////////////////////////////////////////////////////////////////
	SECTION	BSS
; /////////////////////////////////////////////////////////////////////////////

D_A1E	ds.w	1
OldColor0	ds.l	1
OldLogicalScreenAddress	ds.l	1
OldIKBDStatusPacket	ds.l	1
OldACIADispatchHandler	ds.l	1
D_A30	ds.w	17
Text_EndOfLine	ds.b	3
D_A55	ds.b	1
D_A56	ds.w	3
D_A5C	ds.b	1
D_A5D	ds.b	1
D_A5E	ds.b	1
D_A5F	ds.b	1
D_A60	ds.l	1
D_A64	ds.w	1

