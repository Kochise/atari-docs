;****************************************************************
;		.
;****************************************************************
;----------------------------------------------------------------
;		Fait flasher une ligne de texte.
; -a0: Adresse du texte … faire flasher.
;----------------------------------------------------------------
Txt_flash:	movem.l		d0-d7/a1-a6,-(sp)
		lea		(a0),a6

		move.w		Txt_flash_nb,d7
		subq.w		#1,d7
Txt_flash_lp:	Vsync
		lea		CR_txt,a0
		bsr		Print
		lea		Enable_inverse,a0
		bsr		Print
		lea		(a6),a0
		bsr		Print

		Vsync
		lea		CR_txt,a0
		bsr		Print
		lea		Disable_inverse,a0
		bsr		Print
		lea		(a6),a0
		bsr		Print

		dbf		d7,Txt_flash_lp
		movem.l		(sp)+,d0-d7/a1-a6
		rts
Txt_flash_nb:	dc.w		4

Print:		Cconws		a0
		rts

;----------------------------------------------------------------
;		DATAs
;----------------------------------------------------------------
Return_txt:	dc.b		13,10,0 ; Line Feed+Carriage Return.
CR_txt:		dc.b		13,0 ; Carriage Return.
LF_txt:		dc.b		10,0 ; Line Feed.
Enable_inverse:	dc.b		27,"p",0 ; Active inverse vid‚o.
Disable_inverse: dc.b		27,"q",0 ; D‚sactive inverse vid‚o.
		even
;****************************************************************
