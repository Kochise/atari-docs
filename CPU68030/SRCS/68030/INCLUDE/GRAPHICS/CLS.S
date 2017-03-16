;****************************************************************
;		Routine de CLS(CLear Screen).
;
; Cette routine doit etre int‚gr‚e dans le programme avec un include.
; L'appel doit se faire en superviseur:
;		movea.l		Screen_addr,a0
;		jsr 		Cls
; a0.l contient l'adresse de l'‚cran … remplir.
;
; Tous les registres utilis‚s sont sauvegard‚s.
;****************************************************************
;----------------------------------------------------------------
;		Cls software.
;----------------------------------------------------------------
cls_reg		reg		d0-d7/a0-a6
Cls:		tst.b		Cls_blit_fg
		bne		Cls_blit
		movem.l		cls_reg,-(sp)
		move.w		Cls_color,d0
		move.w		d0,d1
		swap		d0
		move.w		d1,d0
		move.l		d0,d1
		move.l		d0,d2
		move.l		d0,d3
		move.l		d0,d4
		move.l		d0,d5
		movea.l		d0,a1
		movea.l		d0,a2
		movea.l		d0,a3
		movea.l		d0,a4
		movea.l		d0,a5
		movea.l		d0,a6
		move.l		Scr_size,d7 ; Taille de l'‚cran.
		adda.l		d7,a0 ; Adresse de la fin de l'‚cran.
		moveq		#10,d6
		lsr.l		d6,d7 ; taille de l'‚cran /1024.
		move.l		d0,d6
		bra.s		Cls_ok
Cls_bcl:	rept		19
		movem.l		d0-d6/a1-a6,-(a0) ; 19*52=988.
		endr
		movem.l		d0-d6/a1-a2,-(a0) ; 988+36=1024.
Cls_ok:		dbf		d7,Cls_bcl
		movem.l		(sp)+,cls_reg
		rts

;----------------------------------------------------------------
;		Cls avec le blitter.
;----------------------------------------------------------------
Cls_blit:	movem.l		d0-d1/a1,-(sp)
		lea		$ff8a20,a1
		moveq		#7,d0
Cls_blit_wait:	btst.b		d0,($1c.w,a1)
		bne.s		Cls_blit_wait

;		lea		$ff8a00,a1
;		Couleur: remplissage de la RAM demi-teinte.
;		move.w		Cls_color,d1
;		move.w		d1,d2
;		swap		d1
;		move.w		d2,d1
;		move.l		d1,(a1)+
;		move.l		d1,(a1)+
;		move.l		d1,(a1)+
;		move.l		d1,(a1)+
;		move.l		d1,(a1)+
;		move.l		d1,(a1)+
;		move.l		d1,(a1)+
;		move.l		d1,(a1)+
;		ParamŠtres.
		clr.l		(a1)+ ; Source X and Y increment=0.
		clr.l		(a1)+ ; Source Address=0.
		move.l		#$ffffffff,(a1)+ ; Endmask 1 and 2.
		move.l		#$ffff0002,(a1)+ ; Endmask 3; Destination X increment=2.
		move.w		#2,(a1)+ ; Destination Y increment.
		move.l		a0,(a1)+ ; Destination adress.
		move.w		Xrez,(a1)+ ; X count.
		move.w		Yrez,(a1)+ ; Y count.
		move.w		#$0100,(a1)+ ; HOP=01(source) ; OP=00(0).
		clr.b		(1.w,a1) ; 0.
		move.b		#%1000000,(a1) ; HOG=0 ; BUSY=1: d‚marrage du blitter.
Cls_blit_restart: bset.b	d0,(a1) ; Red‚marrage du Blitter+test.
		nop
		bne.s		Cls_blit_restart

		movem.l		(sp)+,d0-d1/a1
		rts

;----------------------------------------------------------------
;		DATAS.
;----------------------------------------------------------------
Cls_blit_fg:	dc.b		0,0 ; Flag d'utilisation du Blitter.

Cls_color:	dc.w		0 ; Couleur … afficher.
;****************************************************************
