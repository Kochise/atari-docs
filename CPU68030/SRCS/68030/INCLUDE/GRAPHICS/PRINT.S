;****************************************************************
;		Routine de printing.
;****************************************************************
Print:		movem.l		d0-d7/a0-a6,-(sp)

		movem.l		(sp)+,d0-d7/a0-a6
		rts

Print_txt:	dc.l		0 ; Adresse du texte.
Print_X:	dc.w		0
Print_Y:	dc.w		0
Print_font:	dc.l		0

font_width	equ		0
font_height	equ		2
font_datas	equ		4
;----------------------------------------------------------------
;		
;----------------------------------------------------------------

;		incbin		F:\ASSEMBLE\DATAS\FONT.DAT
;****************************************************************