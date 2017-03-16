;****************************************************************
;		Nouvelle routine form_do.
; -(4.w,sp): num‚ro du champ editable sur lequel on doit mettre le curseur.
; -(sp): adresse de l'arbre.
;****************************************************************
Xform_do:	link		#0,a6
		movem.l		d0-d7/a0-a5,-(sp)
		wind_update	BEG_UPDATE ; Bloque les redraws.
		wind_update	BEG_MCTRL ; Bloque la souris.

		move.w		(4.w,a6),d0 ; Champ de d‚part.
		bne.s		Xform_do_ok0 ; Si =0, alors on recherche le premier champ.
		
Xform_do_ok0:

		movem.l		(sp)+,d0-d7/a0-a5
		unlk		a6
		rtd		#6

;----------------------------------------------------------------
;		Routine cherchant le prochain champ ‚ditable ou un champ
;marqu‚ comme un champ de retour par d‚faut.
;Entr‚es:
; -(6.w,sp): objet de d‚part(W).
; -(4.w,sp): type de recherche(W):
;	*0: recherche en arriŠre.
;	*1: recherche en avant.
;	*2: recherche du champ par d‚faut.
; -(sp): adresse de l'arbre(L).
;Sorties:
; -d0: num‚ro de l'objet.
;----------------------------------------------------------------
Find_obj:	link		#0,a6
		movem.l		d1-d7/a0-a5,-(sp)

;		Positionne les paramŠtres.
		moveq		#0,d0 ; obj=objet de d‚part par d‚faut.
		move.w		#EDITABLE,d1 ; flag=flag de l'objet … trouver.
		moveq		#1,d2 ; inc=incr‚ment pour la recherche.

		move.w		(4.w,a6),d7 ; Type de recherche.
		tst.w		d7 ; Recherche en arriŠre?
		bne.s		Find_obj_ok00
		moveq		#-1,d2 ; Alors inc=-1.
		move.w		(6.w,a6),d0 ; start_obj.
		add.w		d2,d0 ; obj=start_obj+inc.
		bra.s		Find_obj_ok02
Find_obj_ok00:	cmpi.w		#1,d7 ; Recherche en avant?
		bne.s		Find_obj_ok01
		move.w		(6.w,a6),d0 ; start_obj.
		add.w		d2,d0 ; obj=start_obj+inc.
		bra.s		Find_obj_ok02
Find_obj_ok01:	move.w		#DEFAULT,d1 ; flag=DEFAULT: recharche du champ par d‚faut.
Find_obj_ok02:

;		Boucle de recherche.
		movea.l		(a6),a0 ; tree(): Adresse de l'arbre.
Find_obj_lp:	move.w		d0,d7 ; obj.
		mulu.w		#24,d7
		move.w		(OBJECT.ob_flags.w,a0,d7.l),d6 ; theflag=tree(obj).ob_flags.
		move.w		d6,d5
		and.w		d2,d5 ; theflag&flag.
		bne.s		Find_obj_ok

		andi.w		#LASTOB,d6 ; theflag&LASTOB.
		bne.s		Find_obj_no
		add.w		d2,d0 ; obj+=inc.
		bra.s		Find_obj_lp

Find_obj_no:	move.w		(6.w,a6),d0 ; Objet non trouv‚ alors: obj=start_obj.

Find_obj_ok:	movem.l		(sp)+,d1-d7/a0-a5 ; Objet trouv‚.
		unlk		a6
		rtd		#8

;----------------------------------------------------------------
;		Chargement d'un fichier RSC.
; Cette routine accepte aussi les RSCs ‚tendus.
; -
;----------------------------------------------------------------
Xrsrc_load:
		rts

;----------------------------------------------------------------
;		Fixe un RSC.
; -a0: adresse du RSC.
;----------------------------------------------------------------
RSRC_fix:	movem.l		d0-d7/a0-a6,-(sp)
;		Fixe les adresses.
; Fixe d'abord les adresses des arbres.
		lea		(a0),a1
		adda.w		(18.w,a0),a1 ; Adresse de la table des pointeurs d'arbres.
		move.w		(22.w,a0),d7 ; Nombre d'arbres.
		bra.s		RSRC_fix_lp0_ok
RSRC_fix_lp0:	add.l		a0,(a1)+ ; Fixe l'adresse de l'arbre.
RSRC_fix_lp0_ok: dbf		d7,RSRC_fix_lp0

; Fixe ensuite les adresses des strings.
		lea		(a0),a1
		adda.w		(12.w,a0),a1 ; Adresse de la table des pointeurs de strings.
		move.w		(30.w,a0),d7 ; Nombre de strings.
		bra.s		RSRC_fix_lp1_ok
RSRC_fix_lp1:	add.l		a0,(a1)+ ; Fixe l'adresse du string.
RSRC_fix_lp1_ok: dbf		d7,RSRC_fix_lp1

; Fixe enfin les adresses des images.
		lea		(a0),a1
		adda.w		(14.w,a0),a1 ; Adresse de la table des pointeurs d'images.
		move.w		(32.w,a0),d7 ; Nombre d'images.
		bra.s		RSRC_fix_lp2_ok
RSRC_fix_lp2:	add.l		a0,(a1)+ ; Fixe l'adresse du string.
RSRC_fix_lp2_ok: dbf		d7,RSRC_fix_lp2

;		Fixe les objets.
; Boucle des arbres.
		lea		(a0),a1
		adda.w		(18.w,a0),a1 ; Adresse des pointeurs d'arbres.
		move.w		(22.w,a0),d7 ; Nombre d'arbres.
		bra.s		RSRC_fix_lp3_ok
RSRC_fix_lp3:	movea.l		(a1)+,a2 ; Adresse de l'arbre.
; Boucle des objets.
		move.w		(4.w,a2),d6 ; Nombre d'objets.
		cmpi.w		#-1,d6
		beq.s		RSRC_fix_lp3_ok
RSRC_fix_lp4:
		dbf		d6,RSRC_fix_lp4

RSRC_fix_lp3_ok: dbf		d7,RSRC_fix_lp3
		movem.l		(sp)+,d0-d7/a0-a6
		rts
;****************************************************************