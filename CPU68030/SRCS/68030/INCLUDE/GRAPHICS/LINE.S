; ATTENTION !!!!! Ligne.s doit etre inclut dans le programme principal   
;			AVEC UN INCLUDE.
; Cette routine doit IMPERATIVEMENT etre appel‚e EN MODE SUPERVISEUR.
; Les variables suivantes doivent IMPERATIVEMENT figur‚es DANS LE
; PROGRAMME PRINCIPAL.
; a0=adresse de l'‚cran.
;****************************************************************
Line:		movem.l		d0-d7/a0,-(sp)

		movem.w		X1_ln,d0-d3

		move.l		d2,d4 ; x2&.
		move.l		d3,d5 ; y2&.

		sub.l		d0,d4 ; dx&.
		beq		Verti_ln
		sub.l		d1,d5 ; dy&.
		beq		Hori_ln
		swap		d5
		clr.w		d5
		divs.l		d4,d5 ; dy&/dx&.


		bpl.s		DX_ok
		neg.w		d2 ; Si n‚gatif, alors on inverse les points.
		move.w		d4,d0 ; x1&=x2&.
		exg		d1,d3 ; y1&=y2& et y2&=y1&.

DX_ok:		move.l		Ln_size,d4
		move.l		d4,d5
		sub.w		d1,d3 ; dy&.
		bpl.s		DY_ok
		neg.w		d3 ; dy&=-dy&.
		neg.l		d5

DY_ok:		adda.l		([Ln_tbl],d1.w*4),a0 ; Adresse de la 1Šre ligne.
		lea		(a0,d0.w*2),a0 ; Adresse du 1er pixel.

		move.w 		Col_ln,d0 ; Couleur de la ligne.

		cmp.w		d2,d3 ; dy&>dx&?
		bgt.s		Dygt_ln ; If dy&>dx& goto Dygt_ln.

		move.w		d0,d7 ; For i&=0 to dx&-1.

		moveq		#0,d6

Trace_lnX:	add.w		d1,d6 ; y&=y&+dy&.
		cmp.w		d0,d6 ; y&>dx&?
		ble.s		Plot_lnX
		sub.w		d0,d6 ; y&=y&-dx&.
		adda.l		d5,a0 ; Ligne suivante sur l'‚cran(selon le signe).
Plot_lnX:	move.w		d3,(a0)+ ; Affiche pixel.

		dbf		d7,Trace_lnX ; Next i&.
		movem.l		(sp)+,d0-d7/a0
		rts

Dygt_ln:	move.w		d1,d7 ; ...Else...for i&=0 to dy&-1.
		subq.w		#1,d7

		move.w		#%11010100010101,d6 ; On utilise les caches.
		movec		d6,cacr
		moveq		#0,d6 ; x&=0.

Trace_lnY:	add.w		d0,d6 ; x&=x&+dx&.
		cmp.w		d1,d6 ; x&>dy&?
		ble.s		Plot_lnY
		sub.w		d1,d6 ; x&=x&-dy&.
		adda.l		d4,a0 ; Pixel suivant sur l'‚cran(selon le signe).

Plot_lnY:	rol.l		#1,d2
		bcc.s		No_plot_lnY
		move.w		d3,(a0) ; Affiche pixel.

No_plot_lnY:	adda.l		d5,a0 ; Ligne suivante sur l'‚cran(selon le signe).
		dbf		d7,Trace_lnY ; Next i&.
		movem.l		(sp)+,d0-d7/a0
		rts

Hori_ln:	ext.l		d2
		add.l		d2,d2
		muls.w		d5,d3
		adda.l		d2,a0
		adda.l		d3,a0 ; Adresse sur l'‚cran en (x1&;y1&).

		move.l		Mask_ln,d2 ; Masque de la ligne.
		move.w 		Col_ln,d3 ; Couleur de la ligne.

		move.w		#%11010100010101,d6 ; On utilise les caches.
		movec		d6,cacr
Plot_hori_ln:	rol.l		#1,d2
		bcc.s		No_plot_hori_ln
		move.w		d3,(a0)
No_plot_hori_ln: adda.l		d4,a0
		dbf		d0,Plot_hori_ln
		movem.l		(sp)+,d0-d7/a0
		rts

Verti_ln:	move.w		d5,d6
		sub.w		d3,d1 ; dy&.
		bpl.s		Verti_DY_ok
		neg.l		d5
		neg.w		d1

Verti_DY_ok:	ext.l		d2
		add.l		d2,d2
		muls.w		d6,d3
		adda.l		d2,a0
		adda.l		d3,a0 ; Adresse sur l'‚cran en (x1&;y1&).

		move.l		Mask_ln,d2 ; Masque de la ligne.
		move.w 		Col_ln,d3 ; Couleur de la ligne.

		move.w		#%11010100010101,d6 ; On utilise les caches.
		movec		d6,cacr
Plot_verti_ln:	rol.l		#1,d2
		bcc.s		No_plot_verti_ln
		move.w		d3,(a0)
No_plot_verti_ln: adda.l	d5,a0
		dbf		d1,Plot_verti_ln
		movem.l		(sp)+,d0-d7/a0
		rts
Mask_ln:	dc.l		0
Col_ln:		dc.w		0
X1_ln:		dc.w		0
Y1_ln:		dc.w		0
X2_ln:		dc.w		0
Y2_ln:		dc.w		0
;****************************************************************