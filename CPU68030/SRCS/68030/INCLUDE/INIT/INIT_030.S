;****************************************************************
;		Sauvegarde et r‚tablissement du contexte.
;****************************************************************
;----------------------------------------------------------------
;		Initialise tout.
;----------------------------------------------------------------
Set_all:	move		ccr,-(sp)
		movem.l		d0-d7/a0-a6,-(sp)

		move.l		Init_fgs,d7
		moveq		#0,d6

		bsr		Set_super

;		Ecran.
		if		use_scr=true ; Utilisation des routines ‚cran.
		bsr		Save_scr
		btst.l		#init_scr_fg,d7
		beq.s		Init_scr_ok
		bsr		Init_scr
		bne.s		Set_all_err
		bset.l		#init_scr_fg,d6
Init_scr_ok:	endif

;		Son.
		if		use_snd=true
		bsr		Save_snd
		btst.l		#init_snd_fg,d7
		beq.s		Init_snd_ok
		bsr		Init_snd
		bne.s		Set_all_err
		bset.l		#init_snd_fg,d6
Init_snd_ok:	endif

;		Interruptions.
		if		use_it=true
		bsr		Save_IT
		btst.l		#init_it_fg,d7
		beq.s		Init_IT_ok
		bsr		Init_IT ; Doit se situer dans le programme principal.
		bset.l		#init_it_fg,d6 ; Interruptions initialis‚es.
;		bne.s		Set_all_err
Init_IT_ok:	endif

Set_all_ok:	bsr		Set_user
		move.l		d6,Init_status_fgs
		movem.l		(sp)+,d0-d7/a0-a6
		bset		#2,(1.w,sp) ; Z=1: OK.
		rtr
Set_all_err:	bsr		Set_user
		move.l		d6,Init_status_fgs
		movem.l		(sp)+,d0-d7/a0-a6
		bclr		#2,(1.w,sp) ; Z=0: erreur.
		rtr

;----------------------------------------------------------------
;		R‚tablit tout.
;----------------------------------------------------------------
Restore_all:	bsr		Set_super
;		Interruptions.
		if		use_it=true
		bsr		Restore_IT
		endif

;		Son.
		if		use_snd=true
		bsr		Restore_snd
		endif

;		Ecran.
		if		use_scr=true
		bsr		Restore_scr
		endif

		bsr		Set_user
		rts

;----------------------------------------------------------------
;		Quelques routines.
;----------------------------------------------------------------
;		Place le processeur en mode superviseur.
Set_super:	movem.l		d0-d2/a0-a2,-(sp)
		Supervisor	#1 ; Teste si l'on est d‚j… en superviseur.
		tst.l		d0 ; Si d0<>0, on est d‚j… en superviseur.
		bne.s		Set_super_ok

		Supervisor	#0 ; Place le processeur en superviseur.
		move.l		d0,Sav_stack

Set_super_ok:	addq.l		#1,Super_cnt
		movem.l		(sp)+,d0-d2/a0-a2
		rts

;		Place le processeur en mode utilisateur.
Set_user:	movem.l		d0-d2/a0-a2,-(sp)
		Supervisor	#1 ; Teste si l'on est d‚j… en utilisateur.
		tst.l		d0 ; Si d0=0, on est d‚j… en utilisateur.
		beq.s		Set_user_ok

		subq.w		#1,Super_cnt
		beq.s		Set_user_ok0
		bpl.s		Set_user_ok
		clr.l		Super_cnt
		bra.s		Set_user_ok

Set_user_ok0:	Supervisor	Sav_stack ; Passage en superviseur.

Set_user_ok:	movem.l		(sp)+,d0-d2/a0-a2
		rts
;****************************************************************


;****************************************************************
;		DATAS.
;****************************************************************
;----------------------------------------------------------------
;
;----------------------------------------------------------------
Init_fgs:	dc.l		0
Init_status_fgs: dc.l		0
init_scr_fg:	equ		0
init_snd_fg:	equ		1
init_it_fg:	equ		2

;----------------------------------------------------------------
;		Sauvegarde du contexte.
;----------------------------------------------------------------
Sav_stack:	dc.l		0 ; Sauvegarde de la pile en cas de passage en mode superviseur.
Super_cnt:	dc.l		0 ; Compteur: nombre de passages en superviseur.

;----------------------------------------------------------------
;		Includes.
;----------------------------------------------------------------
;		Includes d'initialisation.
		incdir		E:\ASSEMBLE\INCLUDE\INIT
; Routines d'‚cran.
		if		use_scr=true
		include		E:\ASSEMBLE\INCLUDE\INIT\SCREEN.S
		endif
; Routines d'interruptions.
		if		use_it=true
		include		E:\ASSEMBLE\INCLUDE\INIT\IT.S
		endif
; Routines de son.
		if		use_snd=true
		include		E:\ASSEMBLE\INCLUDE\INIT\SOUND.S
		endif

;		Autres includes.
		include		E:\ASSEMBLE\INCLUDE\COOKIE.S
;****************************************************************