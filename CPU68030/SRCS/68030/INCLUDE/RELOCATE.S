;****************************************************************
;		Relocation d'un programme en m‚moire.
; a0: Adresse du programme … reloger(avec l'entete).
;****************************************************************
Relocate:	movem.l		d0-d7/a0-a6,-(sp)

; Recherche de la table de relocation.
		lea		(28.w,a0),a1
		move.l		a1,d0
		addq.l		#2,a0 ; Saute le $601a traditionnel.
		move.l		(a0)+,d1 ; TEXT segment.
		add.l		(a0)+,d1 ; DATA segment.
		add.l		(a0)+,d1 ; BSS segment.
		add.l		(a0),d1 ; Symbol table.
		movea.l		d1,a0
		adda.l		a1,a0 ; Adresse de d‚but de la table de relocation.

; Relocation des mots longs du programme.
		add.l		(a0)+,a1 ; Adresse du premier mot long … reloger.
		add.l		d0,(a1) ; Reloge ce mot long.
		moveq		#0,d1
Relocate_lp:	move.b		(a0)+,d1 ; Offset jusqu'au prochain mot long.
		beq.s		Relocate_end
		cmpi.b		#1,d1 ; Si 1 alors on va 254 octets plus loin.
		bne.s		Relocate_ok0
		lea		(254.w,a1),a1
		bra.s		Relocate_lp
Relocate_ok0:	adda.l		d1,a1 ; Sinon on ajoute l'offset
		add.l		d0,(a1) ; et on reloge.
		bra.s		Relocate_lp

Relocate_end:	movem.l		(sp)+,d0-d7/a0-a6
		rts
;****************************************************************