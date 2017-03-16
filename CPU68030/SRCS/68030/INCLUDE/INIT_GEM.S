;****************************************************************
;		Gestion du GEM au d‚marrage et … la fin de l'application.
;		Utilise les macros AES et VDI d'Assemble de Brainstorm½.
;
; Marche … suivre pour l'utilisation de cet include:
;	-Positionnez le flag Init_VDI_fg si vous voulez initialiser le VDI
;et le flag Load_RSC_fg si vous voulez charger le fichier RSC. Il doit alors
;exister dans le programme principal le label RSC_filename qui pointe sur le
;nom du fichier RSC. Vous pouvez aussi utiliser un fichier RSC inclus dans
;le programme, il est alors n‚cessaire de les fixer. Il faut pour cela
;positionner le flag Fix_RSC_fg. Si Fix_RSC_fg est positionn‚, Load_RSC_fg
;n'est pas pris en compte.
;	-Appelez ensuite GEM_init au d‚but du programme, avant tout appel
;AES et VDI. Les flags AES_inited_fg, VDI_inited_fg, RSC_loaded_fg et
;RSC_fixed_fg sont positionn‚s attestant respectivement l'initialisation de
;l'AES, de la VDI, du chargement du fichier RSC ou de sa fixation. Ces 4
;flags sont surtout internes et l'application ne devrait pas en tenir compte.
; S'il s'est produit une erreur, tout est r‚tablit et le bit Z du registre CCR
;est effac‚, une boite d'alerte s'affiche si l'AES a pu etre initialis‚.
; Si tout s'est bien pass‚, le bit Z du registre CCR est positionn‚.
;	-A la fin du programme, juste avant de quitter, appelez GEM_exit.
;****************************************************************
;----------------------------------------------------------------
;		Initialisation du GEM.
;----------------------------------------------------------------
GEM_init:	move		ccr,-(sp)
		movem.l		d0-d7/a0-a6,-(sp)

		sf		AES_inited_fg
		sf		VDI_inited_fg
		sf		RSC_loaded_fg
		sf		RSC_fixed_fg

; Initialise l'AES.
		appl_init
		cmpi.w		#-1,d0
		bmi		Init_GEM_err
		move.w		d0,AES_ap_id
		st		AES_inited_fg
		graf_mouse	#0,#0

; Initialise le VDI: Ouvre une station de travail.
		tst.b		Init_VDI_fg
		beq.s		No_init_VDI
		Getrez
		addq.w		#2,d0
		lea		Work_in,a0
		move.w		d0,(a0)
		lea		intin,a1
		moveq		#11-1,d7
Fill_intin:	move.w		(a0)+,(a1)+
		dbf		d7,Fill_intin
		v_opnvwk ; Open a virtual workstation.
		tst.w		vdi_handle
		beq		Init_GEM_err
		st		VDI_inited_fg
No_init_VDI:

; Teste si l'on doit fixer le ressource ou si on doit le charger.
		tst.b		Fix_RSC_fg
		beq.s		Load_RSC
		movea.l		RSC_addr,a0
		bsr		Fix_RSC
		bra.s		GEM_init_ok

; Charge le fichier ressource.
Load_RSC:	tst.b		Load_RSC_fg
		beq.s		GEM_init_ok
		rsrc_load	#RSC_filename
		tst.l		d0
		beq.s		Init_GEM_err
		st		RSC_loaded_fg

GEM_init_ok:	movem.l		(sp)+,d0-d7/a0-a6
		bset		#2,(1.w,sp) ; Z=1: OK.
		rtr

; Fixe un RSC. a0 contient l'adresse du RSC.
Fix_RSC:	movem.l		d0-d7/a1-a6,-(sp)
		
		movem.l		(sp)+,d0-d7/a1-a6
		rts

;----------------------------------------------------------------
;		Quitte le GEM.
;----------------------------------------------------------------
GEM_exit:	movem.l		d0-d7/a0-a6,-(sp)

		tst.b		RSC_fixed_fg
		beq.s		GEM_exit_ok0
		sf		RSC_fixed_fg

GEM_exit_ok0:	tst.b		RSC_loaded_fg
		beq.s		GEM_exit_ok1
		rsrc_free
		sf		RSC_loaded_fg

GEM_exit_ok1:	tst.b		VDI_inited_fg
		beq.s		GEM_exit_ok2
		v_clsvwk
		sf		VDI_inited_fg

GEM_exit_ok2:	tst.b		AES_inited_fg
		beq.s		GEM_exit_ok3
		appl_exit
		sf		AES_inited_fg
GEM_exit_ok3:
		movem.l		(sp)+,d0-d7/a0-a6
		rts

;----------------------------------------------------------------
;		Gestion des erreurs.
;----------------------------------------------------------------
;		Diverses erreurs.
; Impossible d'initialiser l'AES.
Init_GEM_err:	tst.b		AES_inited_fg
		bne.s		Init_GEM_err_ok0
		bra		Init_GEM_err_end0

; Impossible d'initialiser la VDI.
Init_GEM_err_ok0: tst.b		Init_VDI_fg
		beq.s		Init_GEM_err_ok1
		tst.b		VDI_inited_fg
		bne.s		Init_GEM_err_ok00
		lea		Txt_err_VDI,a6
		bra		Init_GEM_err_end
Init_GEM_err_ok00: v_clsvwk

; Impossible de charger le fichier RSC.
Init_GEM_err_ok1: tst.b		Load_RSC_fg
		beq.s		Init_GEM_err_ok2
		tst.b		RSC_loaded_fg
		bne.s		Init_GEM_err_ok01
		lea		Txt_err_no_RSC,a6
		bra		Init_GEM_err_end
Init_GEM_err_ok01: rsrc_free

; Erreur inconnue(en g‚n‚ral, bug dans le programme).
Init_GEM_err_ok2: lea		Txt_err_unknow,a6

;		Fin.
Init_GEM_err_end: form_alert	#1,a6 ; Avertit l'utilisateur.
		appl_exit
		sf		AES_inited_fg
		sf		VDI_inited_fg
		sf		RSC_loaded_fg
Init_GEM_err_end0: movem.l	(sp)+,d0-d7/a0-a6
		bclr		#2,(1.w,sp) ; Z=0: erreur.
		rtr
;****************************************************************


;****************************************************************
;		DATAs et BSSs.
;****************************************************************
;----------------------------------------------------------------
;		G‚n‚ral.
;----------------------------------------------------------------
;		Donn‚es.
RSC_addr:	dc.l		0 ; Adresse du RSC.

;		Flags.
; Flags … positionner avant l'appel.
Init_VDI_fg:	dc.b		0 ; Flag d'initialisation du VDI.
Load_RSC_fg:	dc.b		0 ; Flag de chargement du fichier RSC.
Fix_RSC_fg:	dc.b		0 ; Flag de fixation du RSC.
; Flags positionn‚s aprŠs l'appel.
AES_inited_fg:	dc.b		0 ; Flag attestant l'initialisation de l'AES.
VDI_inited_fg:	dc.b		0 ; Flag attestant l'initialisation du VDI.
RSC_loaded_fg:	dc.b		0 ; Flag attestant le chargement du fichier RSC.
RSC_fixed_fg:	dc.b		0 ; Flag attestant la fixation du RSC.

;		Boites d'alerte.
; Textes d'erreur.
Txt_err_VDI:	asciiz		"[3][GEM is unable|to allocate a worstation.|The program must abort.][ OK ]"
Txt_err_no_RSC:	asciiz		"[3][The program cannot locate|the RSC file. Please ensure|that it resides in the same|directory as the PRG file.][ OK ]"
Txt_err_unknow:	asciiz		"[3][Unknow system error.][ OK ]"
		even

;----------------------------------------------------------------
;		AES.
;----------------------------------------------------------------
AES_ap_id:	dc.w		0

;----------------------------------------------------------------
;		VDI.
;----------------------------------------------------------------
;		Environnement de travail.
Work_in:	dc.w		1,1,1,1,1,1,1,1,1,1,2 ; Initial defaults for the workstation.
Work_out:	ds.w		57
; Equs du Work_out(wo).
wo_xrez		equ		0
wo_yrez		equ		2
wo_noscale	equ		4
wo_wpixel	equ		6
wo_hpixel	equ		8
wo_cheights	equ		10
wo_linetypes	equ		12
wo_linewidths	equ		14
wo_markertypes	equ		16
wo_markersizes	equ		18
wo_faces	equ		20
wo_patterns	equ		22
wo_hatches	equ		24
wo_colors	equ		26
wo_ngdps	equ		28
wo_cangdps	equ		30
wo_gdpattr	equ		50
wo_cancolor	equ		70
wo_cantextrot	equ		72
wo_canfillarea	equ		74
wo_cancellarray	equ		76
wo_palette	equ		78
wo_locators	equ		80
wo_valuators	equ		82
wo_choicedevs	equ		84
wo_stringdevs	equ		86
wo_wstype	equ		88
wo_minwchar	equ		90
wo_minhchar	equ		92
wo_maxwchar	equ		94
wo_maxhchar	equ		96
wo_minwline	equ		98
wo_zero5	equ		100
wo_maxwline	equ		102
wo_zero7	equ		104
wo_minwmark	equ		106
wo_minhmark	equ		108
wo_maxwmark	equ		110
wo_maxhmark	equ		112
;****************************************************************

