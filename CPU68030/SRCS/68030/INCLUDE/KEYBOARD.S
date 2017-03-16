;****************************************************************
;		Routine de gestion du clavier.
;****************************************************************
;----------------------------------------------------------------
;		Routine principale.
;----------------------------------------------------------------
Keyboard:	lea		IKBD_param,a0
		move.b		(ikbd.key_code.w,a0),d0
		bpl.s		Key_ok0
		clr.b		Key_pressed
		rts

; Teste si l'on doit r‚peter ou non.
Key_ok0:	move.l		Hz_200,d1
		cmp.b		Key_pressed,d0
		beq.s		Key_ok1
		move.l		d1,Key_time ; Temps initial (lors de l'appui sur la touche).
		bra.s		Key_ok2

; D‚lai avant r‚p‚tition.
Key_ok1:	move.l		d1,d2
		sub.l		Key_time,d2
		cmp.l		Key_delay,d2
		ble		Key_ok

; D‚lai entre 2 r‚p‚titions.
		move.l		d1,d2
		sub.l		Key_rept_time,d2
		cmp.l		Key_rept_delay,d2
		ble		Key_ok

Key_ok2:	move.b		d0,Key_pressed
		move.l		d1,Key_rept_time
		
		ext.w		d0
		movea.l		([Key_addr.l],d0.w*4),a1
		jmp		(a1) ; Saute … la routine.
Key_ok:		rts

;----------------------------------------------------------------
;		DATAs.
;----------------------------------------------------------------
Key_addr:	dc.l		0 ; Adresse de la table des touches.

Key_delay:	dc.l		92 ; D‚lai en 1/200 de seconde avant r‚p‚tition.
Key_time:	dc.l		0 ; Moment o— la touche a ‚t‚ press‚e.
Key_rept_delay:	dc.l		8 ; D‚lai de r‚p‚tition en 1/200 de seconde.
Key_rept_time:	dc.l		0 ; Moment du d‚but de le r‚p‚tition.
Key_pressed:	dc.b		0,0
;****************************************************************
