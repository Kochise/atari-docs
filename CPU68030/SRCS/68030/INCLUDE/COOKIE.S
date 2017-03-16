;****************************************************************
;		Routines pour chercher et installer un cookie.
;****************************************************************
;----------------------------------------------------------------
;		Recherche d'un cookie.
; En entr‚e:
; -d0: contient le cookie … rechercher.
; En sortie:
; -d0: contient la valeur assign‚e au cookie ou -1 si non trouv‚.
; -Z est plac‚ si le cookie a ‚t‚ trouv‚.
;----------------------------------------------------------------
Get_cookie:	move		ccr,-(sp)
		movem.l		d1-d7/a0-a6,-(sp)

		jsr		Set_super
		movea.l		$5a0.w,a0 ; Adresse du cookie jar.
Get_cookie_lp:	move.l		(a0)+,d1 ; Nom du cookie.
		beq.s		Get_cookie_fail ; Si nul cookie pas trouv‚.
		move.l		(a0)+,d2 ; Valeur assign‚e au cookie.
		cmp.l		d0,d1 ; Compare les noms.
		bne.s		Get_cookie_lp
		move.l		d2,d0 ; Valeur assign‚e au cookie dans d0.

		jsr		Set_user
		movem.l		(sp)+,d1-d7/a0-a6
		bset		#2,(1.w,sp) ; Z=1: trouv‚.
		rtr
Get_cookie_fail: jsr		Set_user
		moveq		#-1,d0
		movem.l		(sp)+,d1-d7/a0-a6
		bclr		#2,(1.w,sp) ; Z=0: non trouv‚.
		rtr

;----------------------------------------------------------------
;		Placement d'un cookie.
; En entr‚e:
; -d0: contient le nom cookie … placer.
; -d1: contient la valeur assign‚e au cookie.
; En sortie:
; -Z est plac‚ si le cookie a bien ‚t‚ plac‚.
;----------------------------------------------------------------
Put_cookie:	move		ccr,-(sp)
		movem.l		d2-d7/a0-a6,-(sp)
		jsr		Set_super

		tst.l		$5a0.w
		beq		Put_cookie_err

;		Recherche d'un emplacement vide.
		movea.l		$5a0.w,a0
		lea		(a0),a1
		moveq		#0,d2
		bra.s		Put_cookie_lp_ok
Put_cookie_lp:	addq.l		#8,a1
Put_cookie_lp_ok: addq.l	#1,d2
		tst.l		(a1)
		bne.s		Put_cookie_lp

;		Place le cookie.
		move.l		(4.w,a1),d3 ; Nombre de slots max du cookie jar.
		cmp.l		d2,d3 ; Sommes-nous … la fin du cookie jar?
		bgt.s		Put_cookie_ok0

; Reloge et agrandit le cookie jar dans le cas o— il serait satur‚.
		move.l		d3,d2
		move.l		d3,d4
		addi.l		#32,d4 ; 32 slots en plus.
		move.l		d4,d3 ; Sauve pour plus tard.
		lsl.l		#3,d4 ; *8.
		movem.l		d0-d2/a0-a2,-(sp)
		Malloc		d4 ; Reserve de la m‚moire pour le nouveau cookie jar.
		move.l		d0,d4
		movem.l		(sp)+,d0-d2/a0-a2
		bmi		Put_cookie_err
		movea.l		d4,a1
		move.l		a1,$5a0.w ; Nouvelle adresse du cookie jar.

; Recopie le cookie jar.
		bra.s		Put_cookie_lp1_ok
Put_cookie_lp1:	move.l		(a0)+,(a1)+
		move.l		(a0)+,(a1)+
Put_cookie_lp1_ok: subq.l	#1,d2
		bne.s		Put_cookie_lp1

; Place le cookie.
Put_cookie_ok0:	move.l		d0,(a1)+ ; Nom du cooike.
		move.l		d1,(a1)+ ; Valeur assign‚e au cookie.
		clr.l		(a1)+ ; Cookie nul.
		move.l		d3,(a1) ; Taille du cookie jar.


		jsr		Set_user
		movem.l		(sp)+,d2-d7/a0-a6
		bset		#2,(1.w,sp) ; Z=1: bien plac‚.
		rtr
Put_cookie_err:	jsr		Set_user
		movem.l		(sp)+,d2-d7/a0-a6
		bclr		#2,(1.w,sp) ; Z=0: erreur.
		rtr
;****************************************************************
