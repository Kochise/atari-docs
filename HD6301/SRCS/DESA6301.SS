; /// > HD6301V1 Desassembler - KOSS 2000 < ///
;

; *** Equates Zone ************************************************************

	; *** Commands for Assembly

	OPT	p=68030/68882
	comment	HEAD=7	; FastLoad

; /////////////////////////////////////////////////////////////////////////////	
	SECTION	TEXT
; /////////////////////////////////////////////////////////////////////////////	
	
	movea.l	(4,SP),A6	; Adresse de la BASEPAGE
	move.l	($C,A6),D0	; Taille du SEGMENT TEXT
	add.l	($14,A6),D0	; Additionne la taille du SEGMENT DATA … D0
	add.l	($1C,A6),D0	; Additionne la taille du SEGMENT BSS … D0
	addi.l	#$100,D0	; Additionne la taille de la BASEPAGE … D0
	addi.l	#$400,D0	; Additionne la taille de la future PILE (Ici, 256 positions longues (1024 OCTETS))
	move.l	D0,D1	; Copie D0 dans D1 (Taille … r‚server)
	move.l	D0,D7
	add.l	A6,D1	; Additionne l'adresse du d‚but du programme avec D1 (La taille … r‚server)
	andi.l	#-2,D1	; Rend D1 pair (Au cas o— il ne l'‚tait pas)
	subq.l	#8,D1	; Garde de la place pour l'adresse de la BASEPAGE
	move.l	(4,SP),D2	; Sauvegarde l'adresse de la BASEPAGE
	movea.l	D1,SP	; Installe l'adresse de fin du programme+place nouvelle PILE dans la PILE
	move.l	D2,(4,SP)	; R‚installe l'adresse de la BASEPAGE
	move.l	D0,-(SP)	; EmPILE la taille … r‚server
	move.l	A6,-(SP)	; EmPILE l'adresse du programme
	clr.w	-(SP)	; R‚serv‚
	move.w	#$4A,-(SP)	; - M_SHRINK -
	trap	#1	; *** GEMDOS ***
	lea	(12,SP),SP

	move.w	D0,-(SP)
	move.w	#$4C,-(SP)	; - P_TERM -
	trap	#1	; *** GEMDOS ***

; /////////////////////////////////////////////////////////////////////////////	
	SECTION	DATA
; /////////////////////////////////////////////////////////////////////////////	

Text_6301_OpCodeBank	dc.b	"??? "	; 0
	dc.b	"NOP "	; 1
	dc.b	"??? "	; 2
	dc.b	"??? "	; 3
	dc.b	"lsrD"	; 4
	dc.b	"aslD"	; 5
	dc.b	"tap "	; 6
	dc.b	"tpa "	; 7
	dc.b	"inx "	; 8
	dc.b	"dex "	; 9
	dc.b	"clv "	; A
	dc.b	"sev "	; B
	dc.b	"clc "	; C
	dc.b	"sec "	; D
	dc.b	"cli "	; E
	dc.b	"sei "	; F
	dc.b	"sba "	; 10
	dc.b	"cba "	; 11
	dc.b	"??? "	; 12
	dc.b	"??? "	; 13
	dc.b	"??? "	; 14
	dc.b	"??? "	; 15
	dc.b	"tab "	; 16
	dc.b	"tba "	; 17
	dc.b	"xgdx"	; 18
	dc.b	"daa "	; 19
	dc.b	"slp "	; 1A
	dc.b	"aBA "	; 1B
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
	dc.b	"tsx "	; 30
	dc.b	"ins "	; 31
	dc.b	"pulA"	; 32
	dc.b	"pulB"	; 33
	dc.b	"des "	; 34
	dc.b	"txs "	; 35
	dc.b	"pshA"	; 36
	dc.b	"pshB"	; 37
	dc.b	"pulX"	; 38
	dc.b	"RTS "	; 39
	dc.b	"abX "	; 3A
	dc.b	"RTI "	; 3B
	dc.b	"pshX"	; 3C
	dc.b	"mul "	; 3D
	dc.b	"WAI "	; 3E
	dc.b	"SWI "	; 3F
	dc.b	"negA"	; 40
	dc.b	"??? "	; 41
	dc.b	"??? "	; 42
	dc.b	"comA"	; 43
	dc.b	"lsrA"	; 44
	dc.b	"??? "	; 45
	dc.b	"rorA"	; 46
	dc.b	"asrA"	; 47
	dc.b	"aslA"	; 48
	dc.b	"rolA"	; 49
	dc.b	"decA"	; 4A
	dc.b	"??? "	; 4B
	dc.b	"incA"	; 4C
	dc.b	"tstA"	; 4D
	dc.b	"??? "	; 4E
	dc.b	"clrA"	; 4F
	dc.b	"negB"	; 50
	dc.b	"??? "	; 51
	dc.b	"??? "	; 52
	dc.b	"comB"	; 53
	dc.b	"lsrB"	; 54
	dc.b	"??? "	; 55
	dc.b	"rorB"	; 56
	dc.b	"asrB"	; 57
	dc.b	"aslB"	; 58
	dc.b	"rolB"	; 59
	dc.b	"decB"	; 5A
	dc.b	"??? "	; 5B
	dc.b	"incB"	; 5C
	dc.b	"tstB"	; 5D
	dc.b	"??? "	; 5E
	dc.b	"clrB"	; 5F
	dc.b	"neg "	; 60 vvv Indexed
	dc.b	"aim "	; 61
	dc.b	"oim "	; 62
	dc.b	"com "	; 63
	dc.b	"lsr "	; 64
	dc.b	"eim "	; 65
	dc.b	"ror "	; 66
	dc.b	"asr "	; 67
	dc.b	"asl "	; 68
	dc.b	"rol "	; 69
	dc.b	"dec "	; 6A
	dc.b	"tim "	; 6B
	dc.b	"inc "	; 6C
	dc.b	"tst "	; 6D
	dc.b	"JMP "	; 6E
	dc.b	"clr "	; 6F ^^^ Indexed
	dc.b	"neg "	; 70 vvv Extended
	dc.b	"aim "	; 71
	dc.b	"oim "	; 72
	dc.b	"com "	; 73
	dc.b	"lsr "	; 74
	dc.b	"eim "	; 75
	dc.b	"ror "	; 76
	dc.b	"asr "	; 77
	dc.b	"asl "	; 78
	dc.b	"rol "	; 79
	dc.b	"dec "	; 7A
	dc.b	"tim "	; 7B
	dc.b	"inc "	; 7C
	dc.b	"tst "	; 7D
	dc.b	"JMP "	; 7E
	dc.b	"clr "	; 7F ^^^ Extended
	dc.b	"subA"	; 80 vvv Immediat
	dc.b	"cmpA"	; 81
	dc.b	"sbcA"	; 82
	dc.b	"SUBD"	; 83
	dc.b	"andA"	; 84
	dc.b	"bitA"	; 85
	dc.b	"ldaA"	; 86
	dc.b	"??? "	; 87
	dc.b	"eorA"	; 88
	dc.b	"adcA"	; 89
	dc.b	"oraA"	; 8A
	dc.b	"addA"	; 8B
	dc.b	"cpx "	; 8C
	dc.b	"BSR "	; 8D Relative
	dc.b	"lds "	; 8E
	dc.b	"??? "	; 8F ^^^ Immediat
	dc.b	"subA"	; 90 vvv Direct
	dc.b	"cmpA"	; 91
	dc.b	"sbcA"	; 92
	dc.b	"SUBD"	; 93
	dc.b	"andA"	; 94
	dc.b	"bitA"	; 95
	dc.b	"ldaA"	; 96
	dc.b	"STAA"	; 97
	dc.b	"eorA"	; 98
	dc.b	"adcA"	; 99
	dc.b	"oraA"	; 9A
	dc.b	"addA"	; 9B
	dc.b	"cpx "	; 9C
	dc.b	"JSR "	; 9D
	dc.b	"lds "	; 9E
	dc.b	"STS "	; 9F ^^^ Direct
	dc.b	"subA"	; A0 vvv Indexed
	dc.b	"cmpA"	; A1
	dc.b	"sbcA"	; A2
	dc.b	"SUBD"	; A3
	dc.b	"andA"	; A4
	dc.b	"bitA"	; A5
	dc.b	"ldaA"	; A6
	dc.b	"STAA"	; A7
	dc.b	"eorA"	; A8
	dc.b	"adcA"	; A9
	dc.b	"oraA"	; AA
	dc.b	"addA"	; AB
	dc.b	"cpx "	; AC
	dc.b	"JSR "	; AD
	dc.b	"lds "	; AE
	dc.b	"STS "	; AF ^^^ Indexed
	dc.b	"subA"	; B0 vvv Extended
	dc.b	"cmpA"	; B1
	dc.b	"sbcA"	; B2
	dc.b	"SUBD"	; B3
	dc.b	"andA"	; B4
	dc.b	"bitA"	; B5
	dc.b	"ldaA"	; B6
	dc.b	"STAA"	; B7
	dc.b	"eorA"	; B8
	dc.b	"adcA"	; B9
	dc.b	"oraA"	; BA
	dc.b	"addA"	; BB
	dc.b	"cpx "	; BC
	dc.b	"JSR "	; BD
	dc.b	"lds "	; BE
	dc.b	"STS "	; BF ^^^ Extended
	dc.b	"subB"	; C0 vvv Immediat
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
	dc.b	"subB"	; D0 vvv Direct
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
	dc.b	"subB"	; E0 vvv Indexed
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
	dc.b	"subB"	; F0 vvv Extended
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

	
; /////////////////////////////////////////////////////////////////////////////	
	SECTION	BSS
; /////////////////////////////////////////////////////////////////////////////	
