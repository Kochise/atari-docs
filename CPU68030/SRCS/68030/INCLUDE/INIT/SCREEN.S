;****************************************************************
;		Pr‚paration de l'‚cran.
;****************************************************************
;----------------------------------------------------------------
;		Initialisation de l'‚cran.
;----------------------------------------------------------------
;
;
; *Retour: Z mis si tout va bien, sinon erreur.
;----------------------------------------------------------------
Init_scr:	move		ccr,-(sp)
		movem.l		d0-d7/a0-a6,-(sp)

		dc.w		$a00a ; Efface la souris.
		
		movea.l		Scr_pb_addr,a6 ; Adresse du bloc de paramŠtres.
		move.l		Scr_fgs,d7 ; Flags.
		move.l		(scr_pb.fgs.w,a6),d6
		swap		d6
		swap		d7
		move.w		d6,d7 ; Flags imm‚diats.
		swap		d6
		swap		d7

;		Type de moniteur actuellement connect‚.
		VgetMonitor
		tst.w		d0
		bmi		Init_scr_err
		cmpi.w		#3,d0
		bgt		Init_scr_err
		move.w		d0,Monitor
;		moveq		#0,d0 ; Routine perso.
;		move.b		$ff8006,d0
;		lsr.b		#6,d0
;		move.w		d0,Monitor


;		Recherche de la r‚solution de l'‚cran.
; Mode ‚cran correspondant au moniteur.
		move.w		(scr_pb.mono_mode.w,a6,d0.w*2),d5
		move.w		d5,Scr_mode
		beq		Init_scr_end ; Pas d'initialisation.
; Cherche la r‚solution de l'‚cran.
		lea		Internal_mode_pb,a0 ; Buffer mode ‚cran interne.
		move.w		d5,d0
		move.w		Monitor,d1
		bsr		Find_rez ; Cherche la r‚zo.
		bne		Init_scr_err


;		R‚solution totale.
; R‚solution physique systŠme ou pr‚sis‚e dans scr_pb.physic_xrez et scr_pb.physic_yrez.
		btst.l		#scr_pb_phys_fg,d6
		beq.s		Init_scr_ok00
		move.w		(scr_pb.physic_xrez.w,a6),d0 ; Utilisation de la
		move.w		(scr_pb.physic_yrez.w,a6),d1 ; r‚solution physique pr‚cis‚e.
		bra.s		Init_scr_ok01
Init_scr_ok00:	move.w		Scr_mode_Xrez,d0 ; Utilisation de la
		move.w		Scr_mode_Yrez,d1 ; r‚solution physique systŠme.
Init_scr_ok01:	move.w		d0,Physic_Xrez ; Largeur physique.
		move.w		d1,Physic_Yrez ; Hauteur physique.
; scr_pb.xrez et scr_pb.yrez indiquent les r‚solutions totalles si
;scr_pb_rez_fg est mis, ou indiquent les r‚solutions virtuelles sinon.
		move.w		(scr_pb.xrez.w,a6),d2
		move.w		(scr_pb.yrez.w,a6),d3
		btst.l		#scr_pb_rez_fg,d6
		bne.s		Init_scr_ok10
		add.w		d2,d0
		add.w		d3,d1
		bra.s		Init_scr_ok11
Init_scr_ok10:	sub.w		d0,d2 ; Si largeur totalle<largeur physique,
		bmi		Init_scr_err ; alors erreur.
		sub.w		d1,d3 ; Si hauteur totalle<hauteur physique,
		bmi		Init_scr_err ; alors erreur.
		add.w		d2,d0
		add.w		d3,d1
Init_scr_ok11:	move.w		d2,Virtual_Xrez ; Largeur virtuelle.
		move.w		d3,Virtual_Yrez ; Hauteur virtuelle.
		move.w		d0,Xrez ; Largeur totale.
		move.w		d1,Yrez ; Hauteur totale.

; Taille de l'‚cran et d'une ligne.
		move.w		d0,d2
		mulu.w		Scr_mode_bpp,d2 ;Nombre de bits par ligne.
		lsr.l		#3,d2 ; /8: taille d'une ligne en octets.
		move.l		d2,Ln_size
		mulu.w		Yrez,d2 ; Taille de l'‚cran en octets.
		move.l		d2,Scr_size

; Etablit le clipping.
		clr.w		Scr_Xmin_clip ; Clipping X min.
		subq.w		#1,d0
		move.w		d0,Scr_Xmax_clip ; Clipping X max.
		clr.w		Scr_Ymin_clip ; Clipping Y min.
		subq.w		#1,d1
		move.w		d1,Scr_Ymax_clip ; Clipping Y max.

;		R‚servation de la m‚moire.
		move.l		d7,Scr_fgs
		bsr		Reserve_scr ; Reserve la mŠmoire pour l'‚cran.
		bne		Init_scr_err
		move.l		Scr_fgs,d7

;		Efface les ‚crans.
		btst.l		#scr_pb_cls_fg,d6 ; Doit-on effacer les ‚crans ?
		beq.s		Init_scr_ok1
		movea.l		Screens,a0
		move.l		Scr_size,d0
		move.w		(scr_pb.nb.w,a6),d1
		bra.s		Init_scr_lp_ok1
Init_scr_lp1:	bsr		Cls
		adda.l		d0,a0
Init_scr_lp_ok1: dbf		d1,Init_scr_lp1
		bset.l		#scr_pb_cls_fg,d7
Init_scr_ok1:

;		Positionne l'adresse de l'‚cran et change la r‚solution avec les routines systŠmes.
		VsetScreen	d5,#3,Physic_scr,Logic_scr
		move.l		Physic_scr,d0
		bsr		Set_scr_addr ; A cause d'NVDI.

;		Affichage de la palette.
		btst.l		#scr_pb_pal_fg,d6
		beq.s		Init_scr_ok2
		move.l		(scr_pb.pal_addr.w,a6),a0 ; Adresse de la palette.
		moveq		#0,d0 ; Commence … l'entr‚e 0.
		moveq		#0,d1 ; Toutes les entr‚es possibles.
		bsr		Set_pal
		bset.l		#scr_pb_pal_fg,d7
Init_scr_ok2:

;		Initialisation du scrolling.
		btst.l		#scr_pb_set_scroll_fg,d6
		beq.s		Init_scr_ok3
		bsr		Init_scroll
Init_scr_ok3:

		move.l		d7,Scr_fgs

Init_scr_end:	movem.l		(sp)+,d0-d7/a0-a6
		bset		#2,(1.w,sp)
		rtr
Init_scr_err:	movem.l		(sp)+,d0-d7/a0-a6
		bclr		#2,(1.w,sp)
		rtr

;----------------------------------------------------------------
;		Donne des informations sur les modes ‚cran systŠmes.
;
; d0=mode ‚cran(W).
; d1=type d'‚cran (nombre renvoy‚ par VgetMonitor)(W).
; a0=pointe sur une structure mode_pb.
; Tous les registres sont sauvegard‚s.
;----------------------------------------------------------------
; Bits du mode ‚cran.
vertical_fg	equ		256 ; Vertical flag(Line double en VGA/interlace en TV).
st_comp_fg	equ		128 ; ST compatibility flag(ST low, medium & high).
overscan_fg	equ		64 ; Overscan flag(1.2*Xrez & 1.2*Yrez).
pal_fg		equ		32 ; PAL ou si absent, NTSC(60 Hz).
vga_fg		equ		16 ; VGA flag.
col80_fg	equ		8 ; 80 Columns flag.
bpp1		equ		0 ; 1 bit par pixel(monochrome, 2 "couleurs").
bpp2		equ		1 ; 2 bits par pixel(4 couleurs).
bpp4		equ		2 ; 4 bits par pixel(16 couleurs).
bpp8		equ		3 ; 8 bits par pixel(256 couleurs).
bpp16		equ		4 ; 16 bits par pixel(65536 couleurs).
all_fgs		equ		%111111111

find_rez_reg	reg		d0-d7
Find_rez:	move		ccr,-(sp)
		movem.l		find_rez_reg,-(sp)

		moveq		#0,d6 ; Flags … 0.
; Nombre de bits par pixels.
		move.w		d0,d2
		andi.w		#$7,d2 ; Garde juste les 3 bits faibles: BPP.
		moveq		#1,d3
		lsl.w		d2,d3 ; 2^C bits par pixel.
		move.w		d3,(scr_mode_pb.bpp.w,a0) ; Nombre de bits par pixel.
		moveq		#1,d5 ; Pixel_width=1/1.


;		Moniteur VGA?
		cmpi.w		#2,d1 ; Moniteur VGA?
		bne.s		.No_VGA_monitor
		move.w		#st_comp_fg+overscan_fg+vga_fg,d7 ; Masque des bits … comparer.
		and.w		d0,d7
		cmpi.w		#vga_fg,d7 ; Le mode VGA doit etre mis.
		bne		.Find_rez_err

		move.w		#320,d2 ; Rez X=320.
		move.w		#240,d3 ; Rez Y=240.
		bset.l		#scr_double_ln_fg,d6

		btst.l		#8,d0 ; Vertical flag: Line double?
		bne.s		.VGA_double_ln
		add.w		d3,d3 ; Rez Y=480.
		bclr.l		#scr_double_ln_fg,d6
.VGA_double_ln:	btst		#3,d0 ; 80 column flag?
		beq.s		.VGA_40_columns
		cmpi.w		#bpp16,(scr_mode_pb.bpp.w,a0) ; True Color?
		beq		.Find_rez_err ; Oui, alors erreur.
		add.w		d2,d2 ; Rez X=640.
		moveq		#2,d5 ; Pixel_width=1/2.
.VGA_40_columns: bra		.Find_rez_end


;		Mode moniteur monochrome?
.No_VGA_monitor: tst.w		d1 ; Moniteur monochrome?
		bne.s		.No_mono_monitor
		cmpi.w		#bpp1,(scr_mode_pb.bpp.w,a0) ; Si autre chose que 1 plan,
		bne		.Find_rez_err ; alors erreur.
		move.w		#col80_fg+vga_fg+overscan_fg,d7 ; Masque.
		and.w		d0,d7
		cmpi.w		#col80_fg,d7 ; Valeur que l'on doit retrouver.
		bne		.Find_rez_err
		move.w		640,d2 ; Rez X=640.
		move.w		400,d3 ; Rez Y=400.
		moveq		#2,d5 ; Pixel_width=1/2.
		bra		.Find_rez_end


;		Modes TV ou moniteur couleur?
.No_mono_monitor: btst		#4,d0 ; VGA flag?
		bne		.Find_rez_err

		bclr.l		#scr_double_ln_fg,d6
		bclr.l		#scr_interlace_fg,d6

		move.w		#320,d2 ; Rez X=320.
		move.w		#200,d3 ; Rez Y=200.

;		Modes ST compatibles?
		btst		#7,d0 ; ST compatibility flag?
		beq.s		.No_ST_comp
		bset.l		#scr_st_comp_fg,d6
		move.w		#all_fgs-vga_fg-pal_fg,d7 ; Masque.
		and.w		d0,d7
; ST high?
		cmpi.w		#vertical_fg+st_comp_fg+col80_fg+bpp1,d7 ; ST high res?
		bne.s		.No_ST_high_res
		add.w		d2,d2 ; Rez X=640.
		add.w		d3,d3 ; Rez Y=400.
		bset.l		#scr_interlace_fg,d6
		moveq		#2,d5 ; Pixel_width=1/2.
		bra.s		.Find_rez_end
; ST medium?
.No_ST_high_res: cmpi.w		#st_comp_fg+col80_fg+bpp2,d7
		bne.s		.No_ST_low_res
		add.w		d2,d2 ; Rez X=640.
		moveq		#2,d6 ; Pixel_width=1/2.
		bra.s		.Find_rez_end
; ST low?
.No_ST_low_res:	cmpi.w		#st_comp_fg+bpp4,d7
		bne.s		.Find_rez_err ; Il y a erreur si autre chose.
		bra.s		.Find_rez_end


;		Modes FALCON non VGA?
.No_ST_comp:	bclr.l		#scr_st_comp_fg,d6
		btst		#6,d0 ; Overscan flag.
		beq.s		.No_overscan
		add.w		#64,d2 ; Rez X=1.2Rez X.
		add.w		#40,d3 ; Rez Y=1.2Rez Y.
.No_overscan:	btst		#3,d0 ; 80 Columns Flag.
		beq.s		.TV_40columns
		add.w		d2,d2 ; Rez X=2Rez X.
		moveq		#2,d5 ; Pixel_width=1/2.
.TV_40columns:	btst.l		#8,d7 ; Vertical Flag.
		beq.s		.Find_rez_end
		add.w		d3,d3 ; Interlace mode: Rez Y=2RezY.
		bset.l		#scr_interlace_fg,d6

.Find_rez_end:	move.l		d6,(scr_mode_pb.status_fgs.w,a0)
		move.w		d2,(scr_mode_pb.xrez.w,a0)
		move.w		d3,(scr_mode_pb.yrez.w,a0)
		move.w		d5,(scr_mode_pb.pix_w.w,a0)
		movem.l		(sp)+,find_rez_reg
		bset		#2,(1.w,sp) ; Z=1: OK.
		rtr
.Find_rez_err:	movem.l		(sp)+,find_rez_reg
		bclr		#2,(1.w,sp) ; Z=0: erreur.
		rtr

;----------------------------------------------------------------
;		Routine de calcul et de r‚servation de la m‚moire n‚cessaire
;…/aux ‚cran(s).
; -a6: pointe sur une structure scr_pb.
;----------------------------------------------------------------
Reserve_scr:	move		ccr,-(sp)
		movem.l		d0-d7/a0-a6,-(sp)

		move.l		Scr_fgs,d7
		move.l		(scr_pb.fgs.w,a6),d6

;		V‚rifie si des ‚crans ont d‚j… ‚t‚ reserv‚s. Si c'est le cas,
;la m‚moire est lib‚r‚e.
		btst.l		#scr_pb_reserve_fg,d7
		beq.s		Reserve_scr_ok0
		bsr		Free_scr
Reserve_scr_ok0: 


;		Calcul de la taille m‚moire … r‚server.
		moveq		#0,d1 ; Taille … 0.

; Calcul de la taille de la table de lignes.
		btst.l		#scr_pb_ln_tbl_fg,d6 ; Doit-on utiliser une table de lignes.
		beq.s		Reserve_scr_ok1
		move.w		Yrez,d1 ; Nombre de lignes.
		lsl.l		#2,d1 ; *4: taille de la table de lignes.
		bset.l		#scr_pb_ln_tbl_fg,d7 ; Ok pour la table.
Reserve_scr_ok1:

; Calcul de la taille des ‚crans.
		btst.l		#scr_pb_reserve_fg,d6
		beq.s		Reserve_scr_ok2

		move.l		Scr_size,d4 ; Taille de l'‚cran.
		move.w		(scr_pb.nb.w,a6),d3 ; Nombre d'‚crans.
		move.w		d3,Scr_nb
		ext.l		d3
		beq.s		Reserve_scr_ok2 ; Si 0, pas d'‚cran.
		move.l		d4,d5
		mulu.l		d3,d5 ; Taille totale des ‚crans.
		add.l		d5,d1 ; Taille totale avec table de lignes.
Reserve_scr_ok2:

; R‚servation de la m‚moire.
		moveq		#0,d0 ; Pour l'adresse Screens.
		tst.l		d1 ; Il y a-t-il qelque chose … r‚server?
		beq.s		Reserve_scr_ok3
		Malloc		d1 ; R‚servation.
		tst.l		d0
		bmi		Reserve_scr_err
		bset.l		#scr_pb_reserve_fg,d7
Reserve_scr_ok3:


;		Fixe les adresses.
		move.l		d0,Screens ; Adresses des ‚crans.
; Ecran logique.
		move.l		d0,d1
		add.l		d4,d1
		move.l		d1,Logic_scr ; Adresse de l'‚cran logique.
		cmpi.w		#2,d3 ; 2 ou moins de 2 ‚crans?
		bge.s		Reserve_scr_ok40
		move.l		d0,Logic_scr ; Adresse de l'‚cran logique=adresse de l'‚cran physique.
Reserve_scr_ok40:
; Ecran physique.
		move.l		d0,Physic_scr ; Adresse de l'‚cran physique.
		cmpi.w		#1,d3 ; 1 ou pas d'‚cran?
		bge.s		Reserve_scr_ok41
		move.l		Sav_physic_scr,Physic_scr ; Adresse de l'‚cran physique.
		move.l		Sav_logic_scr,Logic_scr
Reserve_scr_ok41:

; Table de lignes.
		btst.l		#scr_pb_ln_tbl_fg,d7
		beq.s		Reserve_scr_ok42
		add.l		d5,d0
		move.l		d0,Ln_tbl ; Adresse de la table de lignes.

;		Calcul des offsets des lignes par rapport au d‚but de l'‚cran.
		movea.l		d0,a0 ; Adresse de la table.
		moveq		#0,d0 ; Offset … 0.
		move.l		Ln_size,d1 ; Taille d'une ligne.
		move.w		Yrez,d2 ; Nombre de lignes.
		bra.s		Reserve_scr_lp_ok
Reserve_scr_lp: move.l		d0,(a0)+
		add.l		d1,d0
Reserve_scr_lp_ok: dbf		d2,Reserve_scr_lp
Reserve_scr_ok42:

Reserve_scr_end: move.l		d7,Scr_fgs
		movem.l		(sp)+,d0-d7/a0-a6
		bset		#2,(1.w,sp) ; Z=1: OK.
		rtr
Reserve_scr_err: move.l		d7,Scr_fgs
		movem.l		(sp)+,d0-d7/a0-a6
		bclr		#2,(1.w,sp) ; Z=0: erreur.
		rtr

;----------------------------------------------------------------
;		Changement de r‚solution.
;----------------------------------------------------------------
scr_vbasehi	equ		$ff8201 ; Video Base Address High(B).
scr_vbasemid	equ		$ff8203 ; Video Base Address Mid(B).
scr_vbaselo	equ		$ff820d ; Video Base Address Low(B).
scr_vcounthi	equ		$ff8205 ; Video Counter Address High(B).
scr_vcountmid	equ		$ff8207 ; Video Counter Address Mid(B).
scr_vcountlo	equ		$ff8209 ; Video Counter Address Low(B).
scr_syncmode	equ		$ff820a ; Video Shifter Sync Mode(B).
scr_linewid	equ		$ff820e ; Video Extra Line Width(W,9 bits): number of extra words per scanline.
scr_scanlinewid	equ		$ff8210 ; Video Line Width(W,10 bits): width of a physic scanline in words.
scr_st_pal	equ		$ff8240 ; ST/E Compatible Palette(16W,12 bits).
scr_shiftmode	equ		$ff8260 ; ST Video Shifter Mode(B,2 bits).
scr_hscroll	equ		$ff8264 ; Horizontal Scroll Register(B,4 bits).
scr_spshift	equ		$ff8266 ; SPSHIFT Control Register(W,11 bits).
scr_hhc		equ		$ff8280 ; Horizontal Hold Counter(W,9 bits).
scr_hht		equ		$ff8282 ; Horizontal Hold Timer(W,9 bits).
scr_hbb		equ		$ff8284 ; Horizontal Border Begin(W,9 bits).
scr_hbe		equ		$ff8286 ; Horizontal Border End(W,9 bits).
scr_hdb		equ		$ff8288 ; Horizontal Display Begin(W,10 bits).
scr_hde		equ		$ff828a ; Horizontal Display End(W,9 bits).
scr_hss		equ		$ff828c ; Horizontal Synchro Start(W,9 bits).
scr_hfs		equ		$ff828e ; Horizontal Frequency Start?(W,9 bits).
scr_hee		equ		$ff8290 ; HEE(W,9 bits).
scr_vfc		equ		$ff82a0 ; Vertical Frequency Counter(W,11 bits).
scr_vft		equ		$ff82a2 ; Vertical Frequency Timer(W,11 bits).
scr_vbb		equ		$ff82a4 ; Vertical Border Begin(W,11 bits).
scr_vbe		equ		$ff82a6 ; Vertical Border End(W,11 bits).
scr_vdb		equ		$ff82a8 ; Vertical Display Begin(W,11 bits).
scr_vde		equ		$ff82aa ; Vertical Display End(W,11 bits).
scr_vss		equ		$ff82ac ; Vertical Synchro Start(W,11 bits).
scr_rco		equ		$ff82c0 ; RCO(W,8 bits).
scr_vco		equ		$ff82c2 ; Video Control(W,4 bits).
scr_f30_pal	equ		$ff9800

;Set_rez:	move		ccr,-(sp)
;		movem.l		d0-d7/a0,-(sp)

; Fixe VC0.
;		move.w		Pixel_width,d0
;		bmi.s		.Set_rez_err
;		cmpi.w		#2,d0
;		bgt.s		.Set_rez_err
;		move.w		d0,d1
;		lsl.w		#2,d1
;		tst.b		Interlace_fg
;		beq.s		.Set_rez_VCO0
;		ori.w		#%10,d1 ; Interlace Mode.
;.Set_rez_VCO0:	tst.b		Ln_double_fg
;		beq.s		.Set_rez_VCO1
;		ori.w		#%1,d1
;		move.w		d1,VCO
;.Set_rez_VCO1:

;		move.w		Physic_Xrez,d1
;		bmi.s		.Set_rez_err
; Fixe HHT.
;		tst.b		VGA_fg
;		beq.s		Set_rez_HHT0
;		lea		Video_datas_VGA,a0 ; Donn‚es video VGA.
;		bra.s		.Set_rez_HHT2
;Set_rez_HHT0:	tst.b		PAL_fg
;		beq.s		Set_rez_HHT1
;		lea		Video_datas_PAL,a0 ; Donn‚es video PAL.
;		bra.s		.Set_rez_HHT2
;Set_rez_HHT1:	lea		Video_datas_NTSC,a0 ; Donn‚es video NTSC.
;.Set_rez_HHT2:	
		

;		movem.l		(sp)+,d0-d7/a0
;		bset		#2,(1.w,sp)
;		rtr
;.Set_rez_err:	movem.l		(sp)+,d0-d7/a0
;		bclr		#2,(1.w,sp)
;		rtr
;****************************************************************


;****************************************************************
;		Sauvegarde et restauration de l'‚cran.
;****************************************************************
;----------------------------------------------------------------
;		Sauvegarde de l'‚cran.
;----------------------------------------------------------------
Save_scr:	movem.l		d0-d7/a0-a6,-(sp)
		Physbase
		move.l		d0,Sav_physic_scr ; Sauve l'adresse de l'‚cran physique.

		Logbase
		move.l		d0,Sav_logic_scr ; Sauve l'adresse de l'‚cran logique.

		VsetMode	#-1
		move.w		d0,Sav_scr_mode ; Sauve le mode ‚cran.

		movem.l		$ff8240,d0-d7 ; Sauve palette ST.
		movem.l		d0-d7,Sav_pal16

		lea		$ff9800,a0 ; Sauve palette FALCON.
		lea		Sav_pal256,a1
		move.w		#256-1,d7
.Sav_pal256_lp:	move.l		(a0)+,(a1)+
		dbf		d7,.Sav_pal256_lp

		st		Scr_saved ; Ecran sauvegard‚.
		movem.l		(sp)+,d0-d7/a0-a6
		rts

;----------------------------------------------------------------
;		Restoration de l'‚cran.
;----------------------------------------------------------------
Restore_scr:	movem.l		d0-d7/a0-a6,-(sp)
		VsetScreen	Sav_scr_mode,#3,Sav_logic_scr,Sav_physic_scr

		bsr		Free_scr

		movem.l		Sav_pal16,d0-d7 ; R‚tablit palette ST.
		movem.l		d0-d7,$ff8240

		lea		$ff9800,a0 ; R‚tablit palette FALCON.
		lea		Sav_pal256,a1
		move.w		#256-1,d7
.Rstr_pal256_lp: move.l		(a1)+,(a0)+
		dbf		d7,.Rstr_pal256_lp

		dc.w		$a009
		movem.l		(sp)+,d0-d7/a0-a6
		rts

;		Lib‚ration de la m‚moire des ‚crans.
Free_scr:	movem.l		d0-d7/a0-a6,-(sp)
		Mfree		Screens
		move.l		Scr_fgs,d0
		bclr.l		#scr_pb_reserve_fg,d0
		bclr.l		#scr_pb_cls_fg,d0
		bclr.l		#scr_pb_ln_tbl_fg,d0
		bclr.l		#scr_pb_reserve_fg,d0
		move.l		d0,Scr_fgs
		movem.l		(sp)+,d0-d7/a0-a6
		rts

;----------------------------------------------------------------
;		Sauvegarde des paramŠtres de l'‚cran.
;----------------------------------------------------------------
Sav_pal16:	ds.w		16
Sav_pal256:	ds.l		256
Sav_physic_scr:	dc.l		0
Sav_logic_scr:	dc.l		0
Sav_scr_mode:	dc.w		0
Scr_saved:	dc.b		0 ; Si $ff, atteste la sauvegarde de l'‚cran.
		even
;****************************************************************


;****************************************************************
;		Routines secondaires.
;****************************************************************
;----------------------------------------------------------------
;		Positionne l'adresse de l'‚cran … l'adresse contenue dans d0.
;----------------------------------------------------------------
Set_scr_addr:	move.l		d1,-(sp)
		move.l		d0,d1
		swap		d1
		move.b		d1,$ff8201
		swap		d1
		lsr.l		#8,d1
		move.b		d1,$ff8203
		move.b		d0,$ff820d
		move.l		(sp)+,d1
		rts

;----------------------------------------------------------------
;		Modification de la palette de couleurs.
; -a0: adresse de la palette … afficher.
; -d0: num‚ro de la premiŠre entr‚e de la palette … changer.
; -d1: nombre d'entr‚es de la palette … changer.
; Le nombre d'entr‚es varie selon la r‚solution: il est ‚gal … 2^n o— n est
;le nombre de plans. Les num‚ros des entr‚es sont compris entre 0 et 2^n-1.
; Si le nombre d'entr‚es est ‚gal ou inf‚rieur … 0, toutes les entr‚es
;possibles dans la r‚solution actuelle seront chang‚es.
;----------------------------------------------------------------
Set_pal:	movem.l		d0-d7/a0-a6,-(sp)

		move.l		Scr_mode_status_fgs,d7
		lea		$ff9800,a1 ; Adresse hardware Falcon.
		move.w		#255,d2 ; Nombre d'entr‚es maximum=256.
		btst.l		#scr_st_comp_fg,d7 ; Mode compatible?
		beq.s		Set_pal_ok0
		lea		$ff8240,a1 ; Adresse hardware ST.
		moveq		#15,d2 ; Nombre d'entr‚es maximum=16.
Set_pal_ok0:

; Si le nombre d'entr‚es est inf‚rieur ou ‚gal … 0, on met le nombre max d'entr‚es
;disponibles dans la r‚solution.
		subq.w		#1,d1
		bmi.s		Set_pal_ok1
		move.w		d2,d1
Set_pal_ok1:

; Clipping du nombre d'entr‚es … afficher.
		cmp.w		d2,d1 ; Plus d'entr‚e … changer
		bgt.s		Set_pal_ok2 ; que possible?
		move.w		d2,d1 ; Alors met le max.
Set_pal_ok2:	sub.w		d0,d2 ; Diff‚rence entre le nbr d'entr‚es
		cmp.w		d2,d1 ; max et la premiŠre entr‚e.
		ble.s		Set_pal_ok3 ; Si >,
		move.w		d2,d1 ; alors met le max.
Set_pal_ok3:

; Affichage de la palette.
		lea		(a1,d0.w*4),a1
Set_pal_lp:	btst.l		#scr_st_comp_fg,d7 ; Conversion de l'entr‚e Falcon
		beq.s		Set_pal_lp_ok0 ; en entr‚e ST?
		move.l		(a0)+,d0
		bsr		Conv_to_ST_pal ; Concersion.
		move.w		d0,(a1)+ ; Change l'entr‚e ST.
		bra.s		Set_pal_lp_ok
Set_pal_lp_ok0:	move.l		(a0)+,(a1)+ ; Change l'entr‚e Falcon.
Set_pal_lp_ok:	dbf		d1,Set_pal_lp

Set_pal_end:	movem.l		(sp)+,d0-d7/a0-a6
		rts

;----------------------------------------------------------------
;		Lecture de la palette de couleurs au format Falcon.
; -a0: adresse du buffer pour recevoir la palette.
; -d0: num‚ro de la premiŠre entr‚e de la palette … changer.
; -d1: nombre d'entr‚es de la palette … lire.
; Si le nombre d'entr‚es est ‚gal ou inf‚rieur … 0, toutes les entr‚es
;possibles dans la r‚solution actuelle seront lues.
;----------------------------------------------------------------
Get_pal:	movem.l		d0-d7/a0-a6,-(sp)

		move.l		Scr_mode_status_fgs,d7
		lea		$ff9800,a1 ; Adresse hardware Falcon.
		move.w		#255,d2 ; Nombre d'entr‚es maximum=256.
		btst.l		#scr_st_comp_fg,d7 ; Mode compatible?
		beq.s		Get_pal_ok0
		lea		$ff8240,a1 ; Adresse hardware ST.
		moveq		#15,d2 ; Nombre d'entr‚es maximum=16.
Get_pal_ok0:

; Si le nombre d'entr‚es est inf‚rieur ou ‚gal … 0, on met le nombre max d'entr‚es
;disponibles dans la r‚solution.
		subq.w		#1,d1
		bmi.s		Get_pal_ok1
		move.w		d2,d1
Get_pal_ok1:

; Clipping du nombre d'entr‚es … lire.
		cmp.w		d2,d1 ; Plus d'entr‚e … lire
		bgt.s		Get_pal_ok2 ; que possible?
		move.w		d2,d1 ; Alors met le max.
Get_pal_ok2:	sub.w		d0,d2 ; Diff‚rence entre le nbr d'entr‚es
		cmp.w		d2,d1 ; max et la premiŠre entr‚e.
		ble.s		Get_pal_ok3 ; Si >,
		move.w		d2,d1 ; alors met le max.
Get_pal_ok3:

; Lecture de la palette.
		lea		(a1,d0.w*4),a1
Get_pal_lp:	btst.l		#scr_st_comp_fg,d7 ; Conversion de l'entr‚e Falcon
		beq.s		Get_pal_lp_ok0 ; en entr‚e ST?
		move.w		(a1)+,d0
		bsr		Conv_to_Flc_pal ; Concersion.
		move.l		d0,(a0)+ ; Change l'entr‚e ST.
		bra.s		Get_pal_lp_ok
Get_pal_lp_ok0:	move.l		(a1)+,(a0)+ ; Change l'entr‚e Falcon.
Get_pal_lp_ok:	dbf		d1,Get_pal_lp

Get_pal_end:	movem.l		(sp)+,d0-d7/a0-a6
		rts


;----------------------------------------------------------------
;		Convertit une entr‚e palette Falcon en entr‚e palette ST.
; Input:
; -d0=entr‚e au format Falcon … convertir(L).
; Output:
; -d0=entr‚e convertit au format ST(W).
;----------------------------------------------------------------
Conv_to_ST_pal:	move.l		d1,-(sp)
		move.l		d0,d1
		lsr.w		#4,d0 ; Composante bleue.
		swap		d1
		lsr.l		#4,d1
		bfins		d1,d0{31-3:4} ; Composante verte.
		lsr.l		#8,d1
		bfins		d1,d0{31-7:4} ; Composante rouge.
		move.l		(sp)+,d1
		rts

;----------------------------------------------------------------
;		Convertit une entr‚e palette ST en entr‚e palette Falcon.
; Input:
; -d0=entr‚e au format ST … convertir(W).
; Output:
; -d0=entr‚e convertit au format Falcon(L).
;----------------------------------------------------------------
Conv_to_Flc_pal: move.l		d1,-(sp)
		move.w		d0,d1
		moveq		#0,d0
		bfins		d1,d0{31-7:4}
		lsr.w		#4,d1
		bfins		d1,d0{31-23:4} ; Composante verte.
		lsr.l		#4,d1
		bfins		d1,d0{31-31:4} ; Composante rouge.
		move.l		(sp)+,d1
		rts

;----------------------------------------------------------------
;		Gestion du scrolling: programmation des adresses hardware.
;----------------------------------------------------------------
Set_scroll:	movem.l		d0-d7/a0-a6,-(sp)
;		move.l		Scr_fgs,d7
;		btst.l		#scr_pb_scroll_fg,d7
;		beq		Set_scroll_end

; Clipping X.
		move.w		Scroll_X,d0
		cmp.w		Scroll_Xmin,d0
		bge.s		Set_scroll_ok00
		move.w		Scroll_Xmin,d0
		move.w		d0,Scroll_X
Set_scroll_ok00: cmp.w		Scroll_Xmax,d0
		ble.s		Set_scroll_ok01
		move.w		Scroll_Xmax,d0
		move.w		d0,Scroll_X
Set_scroll_ok01
; Cipping Y.
		move.w		Scroll_Y,d1
		cmp.w		Scroll_Ymin,d1
		bge.s		Set_scroll_ok10
		move.w		Scroll_Ymin,d1
		move.w		d1,Scroll_Y
Set_scroll_ok10: cmp.w		Scroll_Ymax,d1
		ble.s		Set_scroll_ok11
		move.w		Scroll_Ymax,d1
		move.w		d1,Scroll_Y
Set_scroll_ok11:

;		Programmation des registres.
		move.w		Virtual_Xrez,d3
		move.w		Scr_mode_bpp,d4
		mulu.w		d4,d3
		lsr.l		#4,d3 ; Largeur virtuelle en mots.
		cmp.w		#16,d4
		blt.s		Set_scroll_pln
; True Color.
		clr.w		$ff8264 ; Horizontal Scroll Register.
		bra.s		Set_scroll_ok
; Modes plan.
Set_scroll_pln:	move.w		d0,d2
		andi.w		#$f,d2 ; Modulo 16.
		move.w		d2,$ff8264 ; Horizontal Scroll Register.
		beq.s		Set_scroll_ok
		sub.w		d4,d3
Set_scroll_ok:	move.w		d3,$ff820e ; Line width.

;		Calcul de l'offset sur l'‚cran.
		ext.l		d1
		mulu.l		Ln_size,d1
		mulu.w		d4,d0
		lsr.l		#3,d0 ; /8.
		add.l		d1,d0
		move.l		d0,Scroll_scr ; Offset sur l'‚cran.

Set_scroll_end:	movem.l		(sp)+,d0-d7/a0-a6
		rts

;----------------------------------------------------------------
;		Initialisation du scrolling.
;…/aux ‚cran(s).
; -a6: pointe sur une structure scr_pb.
;----------------------------------------------------------------
Init_scroll:	move		ccr,-(sp)
		movem.l		d0-d7/a0-a5,-(sp)

		move.l		Scr_fgs,d7
		move.l		(scr_pb.fgs.w,a6),d6
		btst.l		#scr_pb_set_scroll_fg,d6
		beq.s		Init_scroll_end

; Clipping du scrolling.
		clr.w		Scroll_Xmin
		move.w		Virtual_Xrez,d0
		subq.w		#1,d0
		bmi.s		Init_scroll_err
		move.w		d0,Scroll_Xmax
		lsr.w		#1,d0
		move.w		d0,Scroll_X

		clr.w		Scroll_Ymin
		move.w		Virtual_Yrez,d1
		subq.w		#1,d1
		bmi.s		Init_scroll_err
		move.w		d1,Scroll_Ymax
		lsr.w		#1,d1
		move.w		d1,Scroll_Y

		bsr		Set_scroll
		bset.l		#scr_pb_set_scroll_fg,d7
Init_scroll_end: move.l		d7,Scr_fgs
		movem.l		(sp)+,d0-d7/a0-a5
		bset		#2,(1.w,sp) ; Z=1: OK.
		rtr
Init_scroll_err: move.l		d7,Scr_fgs
		movem.l		(sp)+,d0-d7/a0-a5
		bclr		#2,(1.w,sp) ; Z=0: erreur.
		rtr
;****************************************************************


;****************************************************************
;		Includes pour l'‚cran.
;****************************************************************
		incdir		"E:\ASSEMBLE\INCLUDE\GRAPHICS\"
;----------------------------------------------------------------
;		Routine de CLS(CLear Screen).
;----------------------------------------------------------------
		include		"CLS.S"

;----------------------------------------------------------------
;		
;----------------------------------------------------------------
;		include		"LINE.S"

;----------------------------------------------------------------
;		
;----------------------------------------------------------------
;		include		"POLY.S"

;----------------------------------------------------------------
;		
;----------------------------------------------------------------
;		include		"QUADRI.S"

;----------------------------------------------------------------
;		
;----------------------------------------------------------------
;		include		"BLITTER.S"

;****************************************************************


;****************************************************************
;		Datas de l'‚cran.
;****************************************************************
red		equ		2048
green		equ		32
blue		equ		1
red_shift	equ		11
green_shift	equ		5
blue_shift	equ		0

;----------------------------------------------------------------
;		Description du bloc de paramŠtres.
;----------------------------------------------------------------
;		Structure du bloc de paramŠtres.
scr_pb:		rsstruct
fgs:		rs.l		1 ; Flags … positionner(L).
mono_mode:	rs.w		1 ; Mode ‚cran systŠme si ‚cran monochrome(W).
color_mode:	rs.w		1 ; Mode ‚cran systŠme si ‚cran couleur(W).
vga_mode:	rs.w		1 ; Mode ‚cran systŠme si ‚cran VGA(W).
tv_mode:	rs.w		1 ; Mode ‚cran systŠme si ‚cran TV(W).
nb:		rs.w		1 ; Nombre d'‚crans … r‚server (0=pas d'‚cran)(W).
physic_xrez:	rs.w		1 ; Largeur physique voulue(voir description des fgs)(W).
physic_yrez:	rs.w		1 ; Hauteur physique voulue(voir description des fgs)(W).
xrez:		rs.w		1 ; Largeur virtuelle ou totalle voulue(voir description des fgs)(W).
yrez:		rs.w		1 ; Hauteur virtuelle ou totalle voulue(voir description des fgs)(W).
pal_addr:	rs.l		1 ; Adresse de la palette … afficher(qui doit faire 256L)(L).
		rsend
;		Description des bits communs … scr_pb.fgs et Scr_fgs.
scr_pb_reserve_fg equ		0 ; R‚servation des ‚crans.
scr_pb_cls_fg:	equ		1 ; Effacement des ‚crans … l'initialisation.
scr_pb_ln_tbl_fg equ		2 ; R‚servation et calcul d'une table de lignes.
scr_pb_phys_fg	equ		3 ; Si mis, la r‚solution physique de l'‚cran devra
;etre pr‚cis‚e dans scr_pb.physic_xrez et scr_pb.physic_yrez(utile lorsqu'on
;programme soi-meme la resolution … partir des registres hardware).
scr_pb_rez_fg	equ		4 ; Si mis, la r‚solution totale de l'‚cran devra
;etre pr‚cis‚e dans scr_pb.xrez et scr_pb.yrez. La r‚solution virtuelle sera
;calcul‚e … partir de la diff‚rence entre la r‚solution totalle et physique.
;Sinon, les valeurs dans scr_pb.xrez et scr_pb.yrez seront consid‚r‚s comme
;des r‚solutions virtuelles: elles seront alors ajout‚es … la aux r‚solutions
;physiques pour donner les r‚solutions totalles.
scr_pb_pal_fg	equ		5 ; Si mis, la palette situ‚e … l'adresse
;scr_pb.pal_addr est affich‚e. Sinon, scr_pb.pal_addr n'est pas pris en compte.
scr_pb_set_scroll_fg equ	6 ; Si mis, le scrolling sera initialis‚.
;		Description des flags effectifs seulement dans Scr_fgs(mot fort).
scr_pb_scroll_fg equ		16 ; Utilisation d'un scrolling.
scr_pb_clip_fg	equ		17 ; Clipping des sorties graphiques.

;----------------------------------------------------------------
;		Structure du bloc de paramŠtres des modes ‚cran systŠmes.
;----------------------------------------------------------------
scr_mode_pb	rsstruct
status_fgs:	rs.l		1 ; Flags ‚cran(L).
bpp:		rs.w		1 ; Nombre de bits par pixel(16=True Color)(W).
xrez:		rs.w		1 ; Largeur physique(W).
yrez:		rs.w		1 ; Hauteur physique(W).
pix_w:		rs.w		1 ; Largeur des pixels: 0=1/1; 1=1/2; 2=1/4(W).
		rsend
;		Description des bits de status_fgs:
scr_st_comp_fg	equ		0 ; Flag de compatibilit‚ ST.
scr_interlace_fg equ		1 ; Flag d'entrelacement.
scr_double_ln_fg equ		2 ; Flag de doublement des lignes.

;----------------------------------------------------------------
;		Donn‚es g‚n‚rales(d‚finies lors de l'initialisation).
;----------------------------------------------------------------
;		Bloc de paramŠtres.
Scr_pb_addr:	dc.l		Internal_scr_pb ; Adresse du bloc de paramŠtres ‚cran actuel.
Internal_scr_pb: ds.b		256 ; Bloc de paramŠtres ‚cran interne.

;		Buffer interne pour la structure d'infos.
Internal_mode_pb:
Scr_mode_status_fgs: dc.l	0
Scr_mode_bpp:	dc.w		0
Scr_mode_Xrez:	dc.w		0
Scr_mode_Yrez:	dc.w		0
Scr_mode_pix_w:	dc.w		0

;		Informations g‚n‚rales.
; .
Scr_fgs:	dc.l		0 ; Copie de scr_pb.fgs(L).
Monitor:	dc.w		0 ; Type de moniteur: 0=mono; 1=couleur; 2=VGA; 3=TV(W).
Scr_mode:	dc.w		0 ; Mode ‚cran correspondant au moniteur(W).
Scr_nb:		dc.w		0 ; Nombre d'‚crans(W).
Physic_Xrez:	dc.w		0 ; Largeur physique de l'‚cran(W).
Physic_Yrez:	dc.w		0 ; Hauteur physique de l'‚cran(W).
Virtual_Xrez:	dc.w		0 ; Largeur virtuelle de l'‚cran(W).
Virtual_Yrez:	dc.w		0 ; Hauteur virtuelle de l'‚cran(W).
Xrez:		dc.w		0 ; Largeur totale(W).
Yrez:		dc.w		0 ; Hauteur totale(W).
Scr_Xmin_clip:	dc.w		0 ; Clipping X minimum(W).
Scr_Xmax_clip:	dc.w		0 ; Clipping X maximum(W).
Scr_Ymin_clip:	dc.w		0 ; Clipping Y minimum(W).
Scr_Ymax_clip:	dc.w		0 ; Clipping Y maximum(W).

; Scrolling.
Scroll_X:	dc.w		0 ; Position X de l'‚cran physique sur l'‚cran virtuel(W).
Scroll_Y:	dC.w		0 ; Position Y(W).
Scroll_Xmin:	dc.w		0 ; Position X minimale(W).
Scroll_Xmax:	dc.w		0 ; Position X maximale(W).
Scroll_Ymin:	dc.w		0 ; Position Y minimale(W).
Scroll_Ymax:	dc.w		0 ; Position Y maximale(W).
Scroll_scr:	dc.l		0 ; Offset de l'‚cran physique sur l'‚cran virtuel(L).

; .
Ln_size:	dc.l		0 ; Taille d'une ligne en octets(L).
Scr_size:	dc.l		0 ; Taille de l'‚cran en octets(L).
Screens:	dc.l		0 ; Adresse de d‚but des ‚crans(L).
Physic_scr:	dc.l		0 ; Adresse de l'‚cran physique (‚cran nø0)(L).
Logic_scr:	dc.l		0 ; Adresse de l'‚cran logique (‚cran nø1 si scr_nb>1)(=physique sinon)(L).
Ln_tbl:		dc.l		0 ; Adresse d'une table d'offsets de lignes(L).

;----------------------------------------------------------------
;		Valeur des registres video hardware.
;----------------------------------------------------------------
Scanlinewid:	dc.w		0
SPSHIFT:	dc.w		0
HHT:		dc.w		0
HBB:		dc.w		0
HBE:		dc.w		0
HDB:		dc.w		0
HDE:		dc.w		0
HSS:		dc.w		0
HFS:		dc.w		0
HEE:		dc.w		0
VFT:		dc.w		0
VBB:		dc.w		0
VBE:		dc.w		0
VDB:		dc.w		0
VDE:		dc.w		0
VSS:		dc.w		0
RCO:		dc.w		0
VCO:		dc.w		0
;****************************************************************
