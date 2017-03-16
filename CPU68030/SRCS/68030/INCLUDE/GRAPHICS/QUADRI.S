;*******************************************************************
;		Routine de remplissage de quadrilatŠre.
;*******************************************************************
Quadri:		movem.l		d0-d7/a0-a6,-(sp)

;----------------------------------------------------------------
; Calcul de la borne Y inf‚rieure et sup‚rieure du polygone ainsi que des intersections
; avec chaque arete du quadrilatŠre.
;----------------------------------------------------------------
; Efface le buffer des flags d'intersection.
		lea		Quadri_itsc_fg,a3
		lea		(19*13*4.w,a4),a4
		moveq		#$ff,d0
		move.l		d0,d1
		move.l		d0,d2
		move.l		d0,d3
		move.l		d0,d4
		move.l		d0,d5
		move.l		d0,d6
		move.l		d0,d7
		movea.l		d0,a0
		movea.l		d0,a1
		movea.l		d0,a2
		movea.l		d0,a3
		movea.l		d0,a6
		rept		19
		movem.l		d0-d7/a0-a3/a6,-(a4)
		endr

		lea		Quadri_sum,a0 ; Adresse des sommets.		
		lea		Quadri_itsc,a1 ; Adresse du buffer pour les intersections.

		move.l		(a0)+,d0 ; xe&(0), ye&(0).
		move.l		d0,(3*4.w,a0) ; xe&(4)=xe&(0), ye&(4)=ye&(0).
		move.w		d0,d6 ; borne_inf&=ye&(0).
		move.w		d6,d7 ; borne_sup&=ye&(0).
		move.w		d0,d1 ; ye&(0).
		swap		d0 ; xe&(0).

		bsr		Quadri_calc_itsc
		bsr		Quadri_calc_itsc
		bsr		Quadri_calc_itsc
		bsr		Quadri_calc_itsc


;----------------------------------------------------------------
;		Test du clipping Y.
;----------------------------------------------------------------
		move.w		Ymin_clip,d0
		move.w		Ymax_clip,d1
		cmp.w		d0,d7 ; if borne_sup&<Ymin_clip
		blt		Quadri_end ; Fin.
		cmp.w		d1,d6 ; if borne_inf&>Ymax_clip
		bgt		Quadri_end ; Fin.
		cmp.w		d6,d0 ; if borne_inf&<Ymin_clip
		ble.s		Quadri_Ymin_clip_ok
		move.w		d0,d6 ; borne_inf&=Ymin_clip.
Quadri_Ymin_clip_ok: cmp.w	d7,d1 ; if borne_sup&>Ymax_clip
		bge.s		Quadri_Ymax_clip_ok
		move.w		d1,d7 ; borne_sup&=Ymax_clip.
Quadri_Ymax_clip_ok:


;----------------------------------------------------------------
;		Balayage de l'‚cran.
;----------------------------------------------------------------
		movea.l		Logic_scr,a5 ; Adresse de la 1Šre ligne du
		adda.l		([Ln_tbl],d6.w*4),a5 ; polygone.

		sub.w		d6,d7 ; for l&=borne_inf& to borne_sup&
		move.w		Quadri_col,d6
		move.w		d6,d5
		swap		d6
		move.w		d5,d6
Quadri_blank_lp: tst.b		(a3)+
		beq		Quadri_1_pix
		move.w		(a1)+,d0
		move.w		(a1)+,d1

;		Tri des abscisses d'intersection.
		cmp.w		d1,d0
		blt.s		Quadri_blank_ok0
		exg		d0,d1
Quadri_blank_ok0: 

;		Affichage sur la ligne de balayage.
; Test du clipping X.
		movem.w		Xmin_clip,d2-d3
		cmp.w		d3,d0 ; if xmin&>Xmax_clip
		bgt.s		Quadri_draw_ok ; Prochaine ligne.
		cmp.w		d2,d1 ; if xmax&<Xmin_clip
		blt.s		Quadri_draw_ok ; Prochaine ligne.
		cmp.w		d2,d0 ; if xmin&<Xmin_clip
		bge.s		Quadri_Xmin_clip_ok
		move.w		d2,d0 ; xmin&=Xmin_clip.
Quadri_Xmin_clip_ok:
		cmp.w		d3,d1 ; if xmax&>Xmax_clip
		ble.s		Quadri_Xmax_clip_ok
		move.w		d3,d1
Quadri_Xmax_clip_ok:


;		Affichage … proprement parler.
		lea		(a5,d0.w*2),a6
		sub.w		d0,d1 ; Largeur de la ligne horizontale.

; Affiche de (largeur de la ligne mod 16) pixels.
		move.w		d1,d0
		andi.w		#$f,d1 ; Modulo 16.
		neg.w		d1
		jmp		(Quadri_mod1.b,pc,d1.w*2)
		rept		15
		move.w		d6,-(a6)
		endr
Quadri_mod1:

; Affichage du reste.
		lsr.w		#4,d0
		beq.s		Quadri_draw_ok

		move.w		d0,d1
		andi.w		#$f,d1
		neg.w		d1
		lea		(Quadri_mod2.b,pc,d1.w*4),a4

		lsr.w		#4,d0
		move.l		d6,d1
		move.l		d6,d2
		move.l		d6,d3
		move.l		d6,d4
		move.l		d6,d5
		movea.l		d6,a0
		movea.l		d6,a2
		jmp		(a5)
Quadri_hline_lp: rept		15
		movem.l		d1-d6/a0/a2,-(a1)
		endr
Quadri_mod2:


Quadri_blank_ok: adda.l		Ln_size,a6 ; Prochaine ligne sur l'‚cran.
		dbf		d7,Quadri_blank_lp ; next l&.
Quadri_end:	movem.l		(sp)+,d0-d7/a0-a6
		rts

Quadri_calc_itsc:
;		D‚finit les bornes sup‚rieure et inf‚rieure du quadrilatŠre.
		move.w		(a0)+,d2 ; xe&(i&).
		move.w		(a0)+,d3 ; ye&(i&).
		cmp.w		d6,d3 ; if ye&(i&)<borne_inf&
		bge.s		*+4
		move.w		d3,d6 ; borne_inf&=ye&(i&).
		cmp.w		d7,d3 ; if ye&(i&)>borne_sup&
		ble.s		*+4
		move.w		d3,d7 ; borne_sup&=ye&(i&).

;		Calcul du coefficient directeur.
		move.w		d0,d4 ; xe&(i&).
		move.w		d1,d5 ; ye&(i&).
		sub.w		d2,d0 ; -dx&=-(xe&(i&)-xe&(i&-1)).
		sub.w		d3,d1 ; -dy&=-(ye&(i&)-ye&(i&-1)).
		beq		Quadri_no_itsc
		bpl.s		Quadri_itsc_ok0
		neg.w		d0
		neg.w		d1
		move.w		d2,d4 ; xe&(i&-1).
		move.w		d3,d5 ; ye&(i&-1).
Quadri_itsc_ok0: ext.l		d1
		swap		d0
		clr.w		d0
		divs.l		d1,d0 ; dx&/dy&.
		
		swap		d4
		clr.w		d4
		add.l		d0,d4
		lea		(2.b,a1,d5.w*2),a2
		lea		(1.b,a3,d5.w),a4
		subq.w		#1,d1
		move.w		d1,d5
		lsl.w		#2,d1 ; dx&*4.
		add.w		d5,d1 ; dx&*5
		neg.w		d1
		jmp		(Quadri_itsc_calc.w,pc,d1.w*2)
		rept		600
		add.l		d0,d4
		swap		d4
		addq.b		#1,(a4)+
		beq.s		*+4
		move.w		d4,(2.w,a2)
		bra.s		*+4
		move.w		d4,(a2)
		swap		d4
		addq.l		#4,a2
		endr
Quadri_itsc_calc:
Quadri_no_itsc: move.w		d2,d0 ; xe&(i&).
		move.w		d3,d1 ; ye&(i&).
		rts

Quadri_col:	dc.w		0
Quadri_sum:	ds.w		5*2
Quadri_itsc:	ds.w		1024*2
Quadri_itsc_fg	ds.b		1024