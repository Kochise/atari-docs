;****************************************************************
;		Gestion du blitter.
;
; L'adresse parametres … envoyer au BLITTER doit figurer dans a0.
;****************************************************************
Blit:		movem.l		d0-d7/a0-a6,-(sp)

		lea		$ff8a00.w,a6 ; Adresse du blitter.
Blit_wait0:	btst		#7,(blit.line_num.w,a6)
		bne.s		Blit_wait0

; Calcul de Xmax … partir de Xmin et de width pour le calcul des masques.
		move.w		(blit_pb_blk.width.w,a0),d7
		subq.w		#1,d7 ; Width-1.
		bmi		End_blit

		move.w		(blit_pb_src.xmin.w,a0),d0
		move.w		d0,d1
		add.w		d7,d1 ; Src_Xmax.
               
		move.w		(blit_pb_dst.xmin.w,a0),d2
		move.w		d2,d3
		add.w		d7,d3 ; Dst_Xmax.

		moveq		#$f,d6 ; Masque mod 16.

		move.w		d2,d7 ; Dst_Xmin.
		and.w		d6,d7 ; Dst_Xmin mod 16.
		add.w		d7,d7 ; *2.Offset dans la table des masques.               
		move.w		(Blit_mask_lf.w,pc,d7.w),d4 ; Masque d'extr‚mit‚ gauche.

		move.w		d3,d7 ; Dst_Xmax.
		and.w		d6,d7 ; Dst_Xmax mod 16.
		add.w		d7,d7 ; *2.Offset dans la table des masques.               
		move.w		(Blit_mask_rt.b,pc,d7.w),d5 ; Masque d'extr‚mit‚ droit.
		not.w 		d5 ; Inverse.

		move.w		d2,d7 ; Dst_Xmin.
		and.w		d6,d7 ; Dst_Xmin mod 16.
		and.w		d0,d6 ; Src_Xmin mod 16 --> d6.
		sub.w		d6,d7 ; Dst_Xmin mod 16 - Src_Xmin mod 16:
; d‚calage de la source.
		moveq		#0,d6
		addx.w		d6,d6 ; Si Dst_Xmin mod 16 - Src_Xmin mod 16
; est inf‚rieur … z‚ro alors d6=1 et fxsr=1.

		lsr.w		#4,d0 ; Src_Xmin/16.
		lsr.w		#4,d1 ; Src_Xmax/16.
		sub.w		d0,d1 ; Src_Xcount-1(Nombre de mots).

		lsr.w		#4,d2 ; Dst_Xmin/16.
		lsr.w		#4,d3 ; Dst_Xmax/16.
		sub.w		d2,d3 ; Dst_Xcount-1(Nombre de mots).

		bne.s		Set_endmask ; Si il n'y a qu'un mot, les masques
		and.w		d5,d4 ; d'extr‚mit‚ figurent dans endmask 1 et 3
; et endmask 2 est ignor‚.
		addq.w		#4,d6
Set_endmask:	move.w		d4,(Blit_endmask1.w,a6) ; Endmask 1.
		move.w		#$ffff,(Blit_endmask2.w,a6) ; Endmask 2.
		move.w		d5,(Blit_endmask3.w,a6) ; Endmask 3.

		cmp.w		d1,d3
		bne.s		Set_count
		addq.w		#2,d6

Set_count:	move.w		d3,d4 ; Dst_Xcount-1.
		addq.w		#1,d4 ; Dst_Xcount.
		move.w		d4,(Blit_x_count.w,a6) ; X_count.

; D‚terminer adresse source.
		movea.l		(Src_adr.w,a0),a1 ; Adresse source.
		move.w		(Src_Ymin.w,a0),d4 ; Coordonn‚e Y du bloc sur la source.
		move.w		(Src_nxt_ln.w,a0),d5 ; Longueur d'un ligne source.
		mulu.w		d5,d4 ; Offset de la ligne.
		adda.l		d4,a1 ; Adresse de la ligne.

		move.w		(Src_nxt_wd.w,a0),d4 ; Distance au mot suivant.
		move.w		d4,(Blit_src_xinc.w,a6) ; Source X incr‚ment.
		mulu.w		d4,d0 ; Offset du 1er mot source sur la ligne.
		adda.l		d0,a1 ; Adresse du 1er mot source(Xmin, Ymin).

		mulu.w		d4,d1 ; Largeur d'un ligne du bloc en octets.
		sub.w		d1,d5
		move.w		d5,(Blit_src_yinc.w,a6) ; Distance jusqu'… la ligne suivante.

; D‚terminer adresse destination.
		movea.l		(Dst_adr.w,a0),a2 ; Adresse destination.
		move.w		(Dst_Ymin.w,a0),d4 ; Coordonn‚e Y du bloc sur la dest.
		move.w		(Dst_nxt_ln.w,a0),d5 ; Longueur d'un ligne dest.
		mulu.w		d5,d4 ; Offset de la ligne.
		adda.l		d4,a2 ; Adresse de la ligne.

		move.w		(Dst_nxt_wd.w,a0),d4 ; Distance au mot suivant.
		move.w		d4,(Blit_dst_xinc.w,a6) ; Destination X incr‚ment.
		mulu.w		d4,d2 ; Offset du 1er mot dest sur la ligne.
		adda.l		d2,a2 ; Adresse du 1er mot dest(Xmin, Ymin).

		mulu.w		d4,d3 ; Largeur d'un ligne du bloc en octets.
		sub.w		d3,d5
		move.w		d5,(Blit_dst_yinc.w,a6) ; Distance jusqu'… la ligne suivante.

		andi.b		#$f,d7
		or.b		(Skew_flags.b,pc,d6.w),d7
		move.b		d7,(Blit_skew.w,a6) ; (Modes) table, dans le blitter.

		move.b		(HOP.w,a0),(Blit_HOP.w,a6) ; Op‚ration demi-teinte.
		move.b		(OP.w,a0),(Blit_OP.w,a6) ; Op‚ration logique.

		moveq		#0,d2
		move.l		d2,d3
		move.w		(Src_nxt_pl.w,a0),d2
		move.w		(Dst_nxt_pl.w,a0),d3

		move.b		(H_line.w,a0),d0
		bset		#7,d0 ; Bit busy mis.
		lea		(Blit_line_num.w,a6),a3

		move.w		(Nb_plan.w,a0),d7 ; Nombre de plans.
		subq.w		#1,d7
Next_plan:	move.l		a1,(Blit_src_addr.w,a6) ; Adresse source.
		move.l		a2,(Blit_dst_addr.w,a6) ; Adresse destination.
		move.w		(Height.w,a0),(Blit_y_count.w,a6) ; Nombre de lignes.

		move.b		d0,(a3) ; Lancer blitter.
		adda.l		d2,a1 ; D‚but du prochain plan source.
		adda.l		d3,a2 ; D‚but du prochain plan dest.

Wait_blit:	tas		(a3) ; Pas encore termin‚ ?
		nop ; A cause du mode Prefetch(prochaine instruction) du 68000.
		bmi.s		Wait_blit ; Alors on continue.

		dbf		d7,Next_plan

End_blit:	movem.l		(sp)+,d0-d7/a0-a6
		rts

Skew_flags:	dc.b           $40
		dc.b           $80
		dc.b           0
		dc.b           $80+$40
		dc.b           0
		dc.b           $80
		dc.b           0
		dc.b           0


;****************************************************************


;****************************************************************
;
;****************************************************************
Blit_TC:	movem.l		d0-d3/a1,-(sp)
		lea		$ff8a00.w,a1

		move.w		(Width.w,a0),d2
		move.w		d2,d3
		add.w		d2,d3
		subq.w		#2,d3

		move.w		#2,(Blit_src_xinc.w,a1)
		move.w		(Src_nxt_ln.w,a0),d0
		move.w		d0,d1
		sub.w		d3,d1
		move.w		d1,(Blit_src_yinc.w,a1)

		mulu.w		(Src_Ymin.w,a0),d0 ; Calcul de l'adresse source.
		moveq		#0,d1
		move.w		(Src_Xmin.w,a0),d1
		add.l		d1,d1
		add.l		d1,d0
		add.l		(Src_adr.w,a0),d0
		move.l		d0,(Blit_src_addr.w,a1)

		move.l		#$ffffffff,(Blit_endmask1.w,a1)
		move.w		#$ffff,(Blit_endmask3.w,a1)

		move.w		#2,(Blit_dst_xinc.w,a1) ; Calcul de l'adresse destination.
		move.w		(Dst_nxt_ln.w,a0),d0
		move.w		d0,d1
		sub.w		d3,d1
		move.w		d1,(Blit_dst_yinc.w,a1)

		mulu.w		(Dst_Ymin.w,a0),d0 ; Calcul de l'adresse source.
		moveq		#0,d1
		move.w		(Dst_Xmin.w,a0),d1
		add.l		d1,d1
		add.l		d1,d0
		add.l		(Dst_adr.w,a0),d0
		move.l		d0,(Blit_dst_addr.w,a1)

		move.w		d2,(Blit_x_count.w,a1)
		move.w		(Height.w,a0),(Blit_y_count.w,a1)

		move.b		(HOP.w,a0),(Blit_HOP.w,a1)
		move.b		(OP.w,a0),(Blit_OP.w,a1)
		move.b		(H_line.w,a0),(Blit_line_num.w,a1)
		clr.b		(Blit_skew.w,a1)

Wait_blit_TC:	tas		(Blit_line_num.w,a1) ; Pas encore termin‚ ?
		nop ; A cause du mode Prefetch(prochaine instruction) du 68030.
		bmi.s		Wait_blit_TC ; Alors on continue.
		btst		#7,(Blit_line_num.w,a1)
		bne.s		Wait_blit_TC

		movem.l		(sp)+,d0-d3/a1
		rts
;****************************************************************


;****************************************************************
;		DATAS
;****************************************************************
;----------------------------------------------------------------
;		Description des blocs de parametres du blitter:
;----------------------------------------------------------------
; Bloc de paramŠtres source.
blit_pb_src	rsstruct
addr		rs.l		1 ; Adresse(L).
nxt_wd		rs.w		1 ; Nombre d'octets entre 2 mots(W).
nxt_ln		rs.w		1 ; Nombre d'octets entre 2 lignes(W).
nxt_pl		rs.w		1 ; Nombre d'octets entre 2 plans(W).
xmin		rs.w		1 ; Coordonn‚e X du bloc(W).
ymin		rs.w		1 ; Coordonn‚e Y du bloc(W).
		rsend
; Bloc de paramŠtres destination.
blit_pb_dest	rsstruct
addr		rs.l		1 ; Adresse(L).
nxt_wd		rs.w		1 ; Nombre d'octets entre 2 mots(W).
nxt_ln		rs.w		1 ; Nombre d'octets entre 2 lignes(W).
nxt_pl		rs.w		1 ; Nombre d'octets entre 2 plans(W).
xmin		rs.w		1 ; Coordonn‚e X du bloc(W).
ymin		rs.w		1 ; Coordonn‚e Y du bloc(W).
		rsend
; Bloc de paramŠtres du bloc … afficher.
blit_pb_blk	rsstruct
width		rs.w		1 ; Largeur du bloc(W).
height		rs.w		1 ; Hauteur du bloc(W).
plane_nb	rs.w		1 ; Nombre de plans(W).
hop		rs.b		1 ; Op‚ration demi-teinte(B).
op		rs.b		1 ; Op‚ration logique(B).
h_line		rs.b		1 ; Ligne demi-teinte(B).
		rsend

;----------------------------------------------------------------
;		Registres du blitter:
;----------------------------------------------------------------
blit		rsstruct
halftone	rs.w		16
src_xinc	rs.w		1
src_yinc	rs.w		1
src_addr	rs.l		1
endmask1	rs.w		1
endmask2	rs.w		1
endmask3	rs.w		1
dst_xinc	rs.w		1
dst_yinc	rs.w		1
dst_addr	rs.l		1
x_count		rs.w		1
y_count		rs.w		1
hop		rs.b		1
op		rs.b		1
line_num	rs.b		1
skew		rs.b		1
		rsend

;
;
;
Blit_mask_lf:	dc.w		$ffff
Blit_mask_rt:	dc.w		$7fff
		dc.w		$3fff
		dc.w		$1fff
		dc.w		$0fff
		dc.w		$07ff
		dc.w		$03ff
		dc.w		$01ff
		dc.w		$00ff
		dc.w		$007f
		dc.w		$003f
		dc.w		$001f
		dc.w		$000f
		dc.w		$0007
		dc.w		$0003
		dc.w		$0001
		dc.w		$0000
;****************************************************************
