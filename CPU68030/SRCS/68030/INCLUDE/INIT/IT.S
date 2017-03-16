;****************************************************************
;		Initialisation des Interruptions.
;****************************************************************

;****************************************************************
;		Sauvegarde des interruptions.
;****************************************************************
Save_IT:	movem.l		d0-d7/a0-a6,-(sp)
		move.l		$70.w,Sav_VBL
		move.l		$10c.w,Sav_BLITTER
		move.l		$114.w,Sav_TC
		move.l		$118.w,Sav_IKBD
		move.l		$134.w,Sav_DMA_TA
		move.l		$13c.w,Sav_DMA_MFP7
		lea		Sav_MFP,a0
		move.b		$fffa07,(a0)+
		move.b		$fffa09,(a0)+
		move.b		$fffa13,(a0)+
		move.b		$fffa15,(a0)+
		move.b		$fffa17,(a0)
		move.b		$484.w,Sav_conterm
		movem.l		(sp)+,d0-d7/a0-a6
		rts

;****************************************************************
;		Restoration des interruptions.
;****************************************************************
Restore_IT:	move.w		#$2700,sr
		move.l		Sav_VBL,$70.w
		move.l		Sav_BLITTER,$10c.w
		move.l		Sav_TC,$114.w
		move.l		Sav_IKBD,$118.w
		move.l		Sav_DMA_TA,$134.w
		move.l		Sav_DMA_MFP7,$13c.w
		lea		Sav_MFP,a0
		move.b		(a0)+,$fffa07
		move.b		(a0)+,$fffa09
		move.b		(a0)+,$fffa13
		move.b		(a0)+,$fffa15
		move.b		(a0),$fffa17
		move.b		Sav_conterm,$484.w
		move.w		#$2300,sr
		rts
;****************************************************************


;****************************************************************
;		DATAs.
;****************************************************************
;----------------------------------------------------------------
;		Sauvegarde du contexte.
;----------------------------------------------------------------
Sav_VBL:	dc.l		0
Sav_BLITTER:	dc.l		0
Sav_TC:		dc.l		0
Sav_IKBD:	dc.l		0
Sav_DMA_TA:	dc.l		0
Sav_DMA_MFP7:	dc.l		0
Sav_MFP:	ds.b		6
Sav_conterm:	dc.b		0
		even
;****************************************************************