;----------------------------------------------------------------
;		Calcul de la racine carr‚e de M sur 64 bits par la m‚thode
;de Newton (appel‚e aussi m‚thode des tangentes).
; -d0(L): poids faible.
; -d1(L): poids fort.
;----------------------------------------------------------------
SQR:		tst.l		d1
		bne.s		SQR_ok0 ; Si le poids fort est nul, le calcul est plus simple.

; Calcul de x(0) avec M sur 32 bits.
		bfffo		d0{0:0},d3 ; Cherche 1er bit … 1: n=INT(ln(M)/ln(2)).
		neg.w		d3 ; bfffo donne le d‚placement par rapport au bit 31, il faut donc le
		addi.w		#31+1,d3 ; calculer par rapport au bit 0. +1->nombre de bits.
		lsr.l		#1,d3 ; La moiti‚ des bits.
		move.l		d0,d2
		lsr.l		d3,d2 ; x(0)=M/(2^(INT(ln(M)/ln(2))/2))
		addq.l		#1,d2 ; x(0)=M/(2^(INT(ln(M)/ln(2))/2))+1
		bra.s		SQR_ok1

; Calcul de x(0) avec M sur 64 bits: le r‚sultat tient sur 32 bits.
SQR_ok0:	move.l		d0,d2
		move.w		d1,d2
		swap		d2 ; D‚cale d‚j… de 16 bits.
		bfffo		d1{0:0},d3 ; Voir plus haut.
		neg.w		d3
		addi.w		#31+1,d3
		lsr.l		#1,d3
		beq.s		SQR_ok1
		lsr.l		d3,d2 ; D‚cale ce qu'il faut.
		swap		d1
		bfins		d1,d2{0:d3} ; Introduit les bits.
		swap		d1
		addq.l		#1,d2 ; x(0)=M/(2^(INT(ln(M)/ln(2))/2))+1

SQR_ok1:	rept		4
		move.l		d0,d3 ; M: poids faible.
		move.l		d1,d4 ; M: poids fort.
		divu.l		d2,d4:d3 ; M/x(n).
		add.l		d3,d2 ; x(n)+M/x(n)
		lsr.l		#1,d2 ; x(n+1)=(x(n)+M/x(n))/2.
		endr
		rts

;----------------------------------------------------------------
;
;----------------------------------------------------------------
