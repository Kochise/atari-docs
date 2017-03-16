;****************************************************************
;		Routines d'affichage d'une souris en True Color.
;****************************************************************
; Routine d'affichage de la souris.
Show_mouse:	tst.b		Show_mouse_flag
		beq		Show_mouse_end

		movem.l		d0-d7/a0-a3,-(sp)
		movea.l		Logic_scr,a0
		movem.w		Mouse_spriteX,d0-d1

; Clipping.
;		cmp.w		Scr_Xmax_clip,d0


		move.l		([Ln_tbl.l],d1.w*4),d1
		adda.l		d1,a0 ; Adresse de la 1Šre ligne.
		lea		(a0,d0.w*2),a0 ; Adresse du 1er pixel.
		lea		(a0),a2
		move.l		Ln_size,d0 ; Taille d'1 ligne.

		lea		Mouse_back,a1
count		set		0
		rept		16 ; 16*16 pixels.
		movem.l		(a0),d1-d7/a3
		movem.l		d1-d7/a3,(count.w,a1) ; 16 pixels.
		adda.l		d0,a0
count		set		count+2*16
		endr

		st		Hide_mouse_flag ; Il faudra r‚tablir le fond.

; Affichage du sprite de la souris.
		movea.l		Mouse_sprite,a1
		subi.l		#2*16,d0
		rept		16 ; Sprite de 16*16.
		rept		16
		move.w		(a1)+,d1
		beq.s		*+4
		move.w		d1,(a2)
		addq.l		#2,a2
		endr
		adda.l		d0,a2 ; Ligne suivante.
		endr
		movem.l		(sp)+,d0-d7/a0-a3
Show_mouse_end:	rts

; R‚tablissement du fond.
Hide_mouse:	tst.b		Hide_mouse_flag ; Doit-on r‚tablir le fond?
		beq		Hide_mouse_end

		movem.l		d0-d7/a0-a2,-(sp)
		movea.l		Logic_scr,a0
		lea		Mouse_back,a1 ; Buffer pour le fond.
		movem.w		Mouse_spriteX,d0-d1 ; Coordonn‚es du sprite.
		move.l		([Ln_tbl.l],d1.w*4),d1
		adda.l		d1,a0 ; Adresse de la 1Šre ligne.
		lea		(a0,d0.w*2),a0 ; Adresse du 1er pixel.
		move.l		Ln_size,d0 ; Taille d'1 ligne.

		rept		16
		movem.l		(a1)+,d1-d7/a2
		movem.l		d1-d7/a2,(a0)
		adda.l		d0,a0
		endr

		sf		Hide_mouse_flag ; Fond r‚tablit.
		movem.l		(sp)+,d0-d7/a0-a2
Hide_mouse_end:	rts

Show_mouse_flag: dc.b		0
Hide_mouse_flag: dc.b		0
Mouse_sprite:	dc.l		0
Mouse_spriteX:	dc.w		0
Mouse_spriteY:	dc.w		0
Mouse_back:	ds.w		16*16