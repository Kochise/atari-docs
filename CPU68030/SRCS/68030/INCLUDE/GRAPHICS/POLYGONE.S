;*******************************************************************
;		Routine de remplissage de polygone.
;*******************************************************************
Polygone:	movem.l		d0-d7/a0-a6,-(sp)
		lea		Poly_sum,a0 ; Adresse des sommets.
		move.w		Poly_sum_nb,d5
		cmpi.w		#1,d5 ; Si c'est un point.
		beq		Poly_end
		cmpi.w		#2,d5 ; Si c'est une ligne.

; Calcul de la borne Y inf‚rieure et sup‚rieure du polygone ainsi que des coefficients
;directeurs de chaque arete.
		lea		Poly_coef_buf,a2
		lea		(a2),a3
		lea		(a0),a1
		move.l		(a1)+,d0 ; xe&(0), ye&(0).
		move.l		d0,(a0,d5.w*4) ; xe&(nb_som&)=xe&(0), ye&(nb_som&)=ye&(0).
		move.w		d0,d6 ; borne_inf&=ye&(0).
		move.w		d6,d7 ; borne_sup&=ye&(0).
		move.w		d0,d1 ; ye&(0).
		swap		d0 ; xe&(0).
		move.w		d5,d4 ; for i&=0 to nb_som&-2
		subq.w		#2,d4
Poly_bornes_Y:	move.w		(a1)+,d2 ; xe&(i&).
		move.w		(a1)+,d3 ; ye&(i&).
		cmp.w		d6,d3 ; if ye&(i&)<borne_inf&
		bge.s		Poly_bornes_ok0
		move.w		d3,d6 ; borne_inf&=ye&(i&).
Poly_bornes_ok0: cmp.w		d7,d3 ; if ye&(i&)>borne_sup&
		ble.s		Poly_bornes_ok1
		move.w		d3,d7 ; borne_sup&=ye&(i&).

; Calcul des coefficients directeurs.
Poly_bornes_ok1: sub.w		d2,d0 ; dx&=xe&(i&-1)-xe&(i&).
		sub.w		d3,d1 ; dy&=ye&(i&-1)-ye&(i&).
		ext.l		d1
		swap		d0
		clr.w		d0
		divs.l		d1,d0 ; dx&/dy&.
		move.l		d0,(a3)+
		move.w		d2,d0 ; xe&(i&).
		move.w		d3,d1 ; ye&(i&).
		dbf		d4,Poly_bornes_Y ; next i&
; Calcul du coefficient directeur de la derniŠre arete.
		sub.w		(a1)+,d0 
		sub.w		(a1)+,d1
		ext.l		d1
		swap		d0
		clr.w		d0
		divs.l		d1,d0
		move.l		d0,(a3)+

; Test du clipping Y.
		move.w		Scr_Ymin_clip,d0
		move.w		Scr_Ymax_clip,d1
		cmp.w		d0,d7 ; if borne_sup&<Ymin_clip
		blt		Poly_end ; Fin.
		cmp.w		d1,d6 ; if borne_inf&>Ymax_clip
		bgt		Poly_end ; Fin.
		cmp.w		d6,d0 ; if borne_inf&<Ymin_clip
		ble.s		Poly_Ymin_clip_ok
		move.w		d0,d6 ; borne_inf&=Ymin_clip.
Poly_Ymin_clip_ok: cmp.w	d7,d1 ; if borne_sup&>Ymax_clip
		bge.s		Poly_Ymax_clip_ok
		move.w		d1,d7 ; borne_sup&=Ymax_clip.
Poly_Ymax_clip_ok:

; Balayage de l'‚cran.
		movea.l		Logic_scr,a6 ; Adresse de la 1Šre ligne du
		adda.l		([Ln_tbl.l],d6.w*4),a6 ; polygone.

		lea		Poly_inters_buf,a4
		subq.w		#1,d5
		sub.w		d6,d7 ; for l&=borne_inf& to borne_sup&
Poly_blank_lp:
; Recherche des intersections sur la ligne de balayage.
		moveq		#0,d3 ; Nb_inters&=0.
		lea		(a0),a1 ; Sommets.
		lea		(a2),a3 ; Coefficients directeurs.
		lea		(a4),a5 ; Buffer pour les intersections.
		move.w		d5,d4 ; for i&=0 to nb_som&-1
Poly_inters_lp:	move.l		(a1)+,d0 ; xe&(i&), ye&(i&)(=ymin&).
		move.l		(a1),d1 ; xe&(i&+1), ye&(i&+1)(=ymax&).
		cmp.w		d0,d1 ; if ye&(i&)>ye&(i&+1)
		bgt.s		Poly_inters_ok0
		exg		d0,d1 ; ymin&=ye&(i&+1), ymax&=ye&(i&).

Poly_inters_ok0: sub.w		d6,d0 ; -l&+ymin&.
		neg.w		d0 ; l&-ymin&.
		sub.w		d6,d1 ; -l&+ymax&.
		neg.w		d1 ; l&-ymax&.
		eor.w		d0,d1 ; if ((l&-ymin&) xor (l&-ymax&))<0
		bpl.s		Poly_inters_ok
		
		addq.w		#1,d3 ; inc nb_inters&.
		moveq		#0,d1
		move.w		d0,d1 ; l&-ymin&.
		muls.l		(a3),d1
		swap		d1
		swap		d0
		add.w		d0,d1
		move.w		d1,(a5)+ ; Coordonn‚e X de l'intersection sur la ligne.
Poly_inters_ok:	addq.l		#4,a3
		dbf		d4,Poly_inters_lp

; Tri des abscisses d'intersection.
		lea		(a4),a5 ; Intersections.
		move.w		d3,d4 ; for i&=0 to nb_inters-2.
		subq.w		#2,d4
		bmi		Poly_blank_ok
Poly_tri0_lp:	move.w		(a5),d0 ; m&=t&(i&).
		move.w		d0,d1 ; Sauvegarde pour plus tard.
		lea		(a5),a1 ; r&=i&.

		lea		(2.w,a5),a3
		move.w		d4,d2 ; for j&=i&+1 to nb_inters&
Poly_tri1_lp:	cmp.w		(a3),d0 ; if m&>t&(j&)(a4)
		ble.s		Poly_tri1_ok
		move.w		(a3),d0 ; m&=t&(j&).
		lea		(a3),a1 ; r&=j&.
Poly_tri1_ok:	addq.l		#2,a3
		dbf		d2,Poly_tri1_lp

		move.w		d1,(a1) ; t&(r&)=t&(i&).
		move.w		d0,(a5)+ ; t&(i&)=m&.
Poly_tri0_ok:	dbf		d4,Poly_tri0_lp ; next i&.

; Affichage sur la ligne de balayage.
		move.w		Poly_col,d0
		lea		(a4),a5
		lsr.w		#1,d3 ; nb_inters&/2.
		bra		Poly_draw_ok
Poly_draw_lp:	move.w		(a5)+,d1 ; xmin&.
		move.w		(a5)+,d2 ; xmax&.

; Test du clipping X.
		move.w		Scr_Xmin_clip,d4
		cmp.w		d4,d2 ; if xmax&<Xmin_clip
		blt		Poly_draw_ok ; Prochaine ligne.
		cmp.w		d4,d1 ; if xmin&>Xmax_clip
		bge.s		Poly_Xmin_clip_ok
		move.w		d4,d1 ; xmin&=Xmin_clip.
Poly_Xmin_clip_ok: move.w	Scr_Xmax_clip,d4
		cmp.w		d4,d1 ; if xmin&>Xmax_clip
		bgt		Poly_draw_ok ; Prochaine ligne.
		cmp.w		d4,d2 ; if xmax&>Xmax_clip
		ble.s		Poly_Xmax_clip_ok
		move.w		d4,d2
Poly_Xmax_clip_ok:

; Affichage … proprement parler.
		lea		(a6,d2.w*2),a1
		sub.w		d1,d2 ; Largeur de la ligne horizontale.
		move.w		d2,d1
		andi.w		#$f,d1 ; Modulo 16.
		neg.w		d1
		jmp		(Poly_mod1.b,pc,d1.w*2)
		rept		15
		move.w		d0,-(a1)
		endr
Poly_mod1:

		lsr.w		#4,d2
		beq.s		Poly_draw_ok
		movem.l		d3/d5-d7/a5,-(sp)

		move.w		d2,d3
		andi.w		#$f,d3
		neg.w		d3
		lea		(Poly_mod2.b,pc,d3.w*4),a5

		lsr.w		#4,d2
		move.w		d0,d1
		swap		d0
		move.w		d1,d0
		move.l		d0,d1
		move.l		d0,d3
		move.l		d0,d4
		move.l		d0,d5
		move.l		d0,d6
		move.l		d0,d7
		movea.l		d0,a3
		jmp		(a5)
Poly_hline_lp:	rept		16
		movem.l		d0-d1/d3-d7/a3,-(a1)
		endr
Poly_mod2:
Poly_hline_ok:	dbf		d2,Poly_hline_lp

		movem.l		(sp)+,d3/d5-d7/a5

Poly_draw_ok:	dbf		d3,Poly_draw_lp

Poly_blank_ok:	adda.l		Ln_size,a6 ; Prochaine ligne sur l'‚cran.
		addq.w		#1,d6
		dbf		d7,Poly_blank_lp ; next l&.
Poly_end:	movem.l		(sp)+,d0-d7/a0-a6
		rts

Poly_sum_nb:	dc.w		0
Poly_col:	dc.w		0
Poly_sum:	ds.l		256
Poly_coef_buf:	ds.l		256
Poly_inters_buf: ds.l		256
