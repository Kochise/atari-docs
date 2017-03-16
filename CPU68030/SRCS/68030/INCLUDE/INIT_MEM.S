;****************************************************************
;		Initialise m‚moire: la taille du programme se trouve dans d7.
;****************************************************************
		movea.l		(4.w,sp),a0 ; D‚but de la Basepage.
		move.l		(12.w,a0),d7 ; Taille du code du prg.
		add.l		(20.w,a0),d7 ; + longueur du segment DATA
		add.l		(28.w,a0),d7 ; + longueur du segment BSS
		addi.l		#$1100,d7 ; +Basepage(256)+pile(4Kb)
		move.l		d7,d0 ; Longueur plus...		
		add.l		a0,d0 ; ...adresse...
		andi.l		#-2,d0 ; ...arrondie...
		movea.l		d0,sp ; ...donne le pointeur de pile.
		move.l		a0,-(sp) ; Sauve l'adresse de la Basepage.
		Mshrink		d7,a0,#0
