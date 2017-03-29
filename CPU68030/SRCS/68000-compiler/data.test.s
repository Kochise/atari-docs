	DATA
toto:	DC.B	5		; ATTENTION:le label ne doit pas contenir de
titi:	DC.W	15		;  chiffres, et pas d'espace avant le :	
	DC.L	2
;titi:			
	
	CODE
cd:	
	DC.W	8252		; code assembleur brut
	DC.W	2  		; MOVE #2, D0

	MOVE.L	toto, D0	; 0x202D, 0x0000
	MOVE.L	#12, titi       ; 0x2B7C, 0x0000, 0x000C, 0x0002
	ADD.L	titi, D0	; 0xD1AD, 0x0002
	MOVE.L  D0, d		; 0x2B40, 0x0008
	;; d = 12+2 = 14
	
	DC.W    20085		; RTS
			
	DATA
d:	DC.L	9		; inclu l'instruction dont le code machine
	                        ; est 9 

