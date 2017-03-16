;****************************************************************
;		Gestion de l'IKBD controller.
;****************************************************************
;----------------------------------------------------------------
;		Routine principale.
;----------------------------------------------------------------
;		Routine d'interruption g‚n‚rale.
IKBD:		movem.l		d0-d1/a0-a2,-(sp)

IKBD_new_data:	lea		IKBD_param,a0
		lea		$fffc04,a1
		lea		IKBD_midi,a2
		bsr		IKBD_receive

		lea		$fffc00,a1
		lea		IKBD_kbd,a2
		bsr		IKBD_receive

		btst.b		#4,$fffa01 ; GPIP: G‚neral Purpose I/O Interrupt Port.
		beq.s		IKBD_new_data

IKBD_end:	bclr		#6,$fffa11 ; Interrupt in service off.
		movem.l		(sp)+,d0-d1/a0-a2
		rte

;		V‚rifie s'il y a eu overrun.
IKBD_receive:	move.b		(a1),d1
		btst		#7,d1 ; Interrupt Request?
		beq.s		IKBD_receive_ok
		btst		#0,d1 ; Receiver Full?
		beq.s		IKBD_receive_ok0
		jsr             (a2)
IKBD_receive_ok0: andi.b	#$20,d1 ; Overrun?
		beq.s           IKBD_receive_ok
		move.b		(2.w,a1),d0 ; Overrun: prend donn‚e effac‚e.
IKBD_receive_ok: rts

;		ACIA keyboard.
IKBD_kbd:	move.b		(2.w,a1),d0
		tst.b		(ikbd.header.w,a0) ; Il y a-t-il un header?
		bne.s		IKBD_header_ok ; Si oui c'est une donn‚e sp‚ciale.

		cmpi.b		#$f6,d0 ; La donn‚e est-t-elle un header?
		bcs.s		IKBD_key ; Si non c'est un code clavier.
		move.b		d0,(ikbd.header.w,a0) ; On signale le header et on quitte.
		rts
               
IKBD_header_ok:	moveq		#0,d1
		move.b		(ikbd.header.w,a0),d1
		subi.b		#$f6,d1
		movea.l		(IKBD_table.b,pc,d1.w*4),a1
		jmp		(a1)
IKBD_table:	dc.l		IKBD_stat_pack,IKBD_abs_mouse,IKBD_rel_mouse,IKBD_rel_mouse
		dc.l		IKBD_rel_mouse,IKBD_rel_mouse,IKBD_time,IKBD_joys
		dc.l		IKBD_joy0_event,IKBD_joy1_event

;----------------------------------------------------------------
;		Gestion du clavier.
;----------------------------------------------------------------
IKBD_key:	move.b		d0,d1
		andi.b		#$7f,d1

		cmpi.b		#$2a,d1 ; SHIFT gauche.
		bne.s		IKBD_no_Lshift
		tst.b		d0
		spl		(ikbd.lshift_fg.w,a0)
		rts
IKBD_no_Lshift:	cmpi.b		#$36,d1 ; SHIFT droit.
		bne.s		IKBD_no_Rshift
		tst.b		d0
		spl		(ikbd.rshift_fg.w,a0)
		rts
IKBD_no_Rshift:	cmpi.b		#$1d,d1 ; CONTROL.
		bne.s		IKBD_no_control
		tst.b		d0
		spl		(ikbd.ctrl_fg.w,a0)
		rts
IKBD_no_control: cmpi.b		#$38,d1 ; ALTERNATE.
		bne.s		IKBD_no_alternate
		tst.b		d0
		spl		(ikbd.alt_fg.w,a0)
		rts
IKBD_no_alternate: cmpi.b	#$3a,d0 ; CAPSLOCK.
		bne.s		IKBD_no_capslock
		not.b		(ikbd.caps_fg.w,a0)
		rts
IKBD_no_capslock: move.b	d0,(ikbd.key_code.w,a0) ; Code clavier
		rts

;----------------------------------------------------------------
;		Gestion des packets de donn‚es de status.
;----------------------------------------------------------------
IKBD_stat_pack:	subq.b		#1,(ikbd.nb_dat.w,a0) ; Nbr de donn‚es de status-1.
		bpl.s		IKBD_get_stat
		move.b		#6,(ikbd.nb_dat.w,a0) ; Encore 6 octets.
IKBD_get_stat:	bne.s		IKBD_get_stat2
		clr.b		(ikbd.header.w,a0)
IKBD_get_stat2:	lea		(ikbd.stat_buf.w,a0),a1
		move.b		d0,(a1)
		rts

;----------------------------------------------------------------
;		Gestion de la souris en mode absolu: 1 octet pour
;les boutons de la souris et 2 mots pour ses coordonn‚es absolues.
;----------------------------------------------------------------
IKBD_abs_mouse:	subq.b		#1,(ikbd.nb_dat.w,a0) ; Si Nb_data=-1, c'est le 1er octet
		bpl.s		IKBD_abs_mouse_ok0 ; du paquet(boutons de la souris).
		move.b		#4,(ikbd.nb_dat.w,a0) ; Encore 4 octets(2 mots coordonn‚es).
		rts

IKBD_abs_mouse_ok0: move.b	(ikbd.nb_dat.w,a0),d1
		bne.s		IKBD_abs_mouse_ok1
		clr.b		(ikbd.header.w,a0) ; Transfer est fini.
IKBD_abs_mouse_ok1: ext.w	d1
		neg.w		d1 ; -d1.
		lea		(ikbd.mousex.w,a0),a1
		move.b		d0,(3.b,a1,d1.w) ; a0+(3-d1).
		rts

;----------------------------------------------------------------
;		Gestion de la souris en mode relatif.
;----------------------------------------------------------------
IKBD_rel_mouse:	btst		#0,(ikbd.header.w,a0) ; Bouton gauche press‚?
		sne		(ikbd.r_mbut.w,a0)
		btst		#1,(ikbd.header.w,a0) ; Bouton droit press‚?
		sne		(ikbd.l_mbut.w,a0)

		ext.w		d0 ; Signe la coordonn‚e relative sur 1 mot.
		subq.b		#1,(ikbd.nb_dat.w,a0) ; Si Nb_data=-1, la donn‚e est la 
		beq.s		IKBD_rel_mouse_ok ; position relative X.
		move.b		#1,(ikbd.nb_dat.w,a0) ; Le prochain octet est la position

		tst.b		(ikbd.mclip_fg.w,a0)
		beq.s		IKBD_no_mclip0
		add.w		(ikbd.mousex.w,a0),d0
		cmp.w		(ikbd.mclipxmin.w,a0),d0
		bge.s		IKBD_clipxmin
		move.w		(ikbd.mclipxmin.w,a0),(ikbd.mousex.w,a0)
		rts
IKBD_clipxmin:	cmp.w		(ikbd.mclipxmax.w,a0),d0
		ble.s		IKBD_clipxmax
		move.w		(ikbd.mclipxmax.w,a0),d0
IKBD_clipxmax:	move.w		d0,(ikbd.mousex.w,a0)
		rts
IKBD_no_mclip0:	add.w		d0,(ikbd.mousex.w,a0) ; Coordonn‚e X de la souris.
		rts

IKBD_rel_mouse_ok: clr.b	(ikbd.header.w,a0) ; Fin des datas.

		tst.b		(ikbd.mclip_fg.w,a0)
		beq.s		IKBD_no_mclip1
		add.w		(ikbd.mousey.w,a0),d0
		cmp.w		(ikbd.mclipymin.w,a0),d0
		bge.s		IKBD_clipymin
		move.w		(ikbd.mclipymin.w,a0),(ikbd.mousey.w,a0)
		rts
IKBD_clipymin:	cmp.w		(ikbd.mclipymax.w,a0),d0
		ble.s		IKBD_clipymax
		move.w		(ikbd.mclipymax.w,a0),d0
IKBD_clipymax:	move.w		d0,(ikbd.mousey.w,a0)
		rts
IKBD_no_mclip1:	add.w		d0,(ikbd.mousey.w,a0) ; Coordonn‚e Y de la souris.
		rts

;----------------------------------------------------------------
;		Gestion de l'horloge de l'IKBD.
;----------------------------------------------------------------
IKBD_time:	subq.b		#1,(ikbd.nb_dat.w,a0); Si Nb_data=-1, c'est le premier
		bpl.s		IKBD_time_ok0 ; octet.
		move.b		#5,(ikbd.nb_dat.w,a0) ; Encore 5 octets

IKBD_time_ok0:	move.b		(ikbd.nb_dat.w,a0),d1
		bne.s		IKBD_time_ok1
		clr.b		(ikbd.header.w,a0) ; Dernier octet.
IKBD_time_ok1:	neg.w		d1 ; -d1.
		lea		(ikbd.time.w,a0),a1
		move.b		d0,(5.b,a1,d1.w) ; a0+(5-d1).
		rts

;----------------------------------------------------------------
;		Gestion des joysticks
;----------------------------------------------------------------
IKBD_joys:	subq.b		#1,(ikbd.nb_dat.w,a0) ; Si Nb_data=-1, c'est la position
		beq.s		IKBD_joy0 ; du joystick 0.
		move.b		d0,(ikbd.joystick0.w,a0)
		move.b		#1,(ikbd.nb_dat.w,a0) ; Prochain octet: joystick 1.
		rts
IKBD_joy0:	move.b		d0,(ikbd.joystick1.w,a0)
		clr.b		(ikbd.header.w,a0)
		rts

IKBD_joy0_event: move.b		d0,(ikbd.joystick0.w,a0)
		clr.b		(ikbd.header.w,a0)
		rts
IKBD_joy1_event: move.b		d0,(ikbd.joystick1.w,a0)
		clr.b		(ikbd.header.w,a0)
		rts

;----------------------------------------------------------------
;		Gestion du MIDI.
;----------------------------------------------------------------
IKBD_midi:	tst.l		(ikbd.midi_hdlr.w,a0)
		beq.s		IKBD_midi_ok
		jsr		(ikbd.midi_hdlr.w,a0)
IKBD_midi_ok:	rts

;****************************************************************


;****************************************************************
;		DATAS.
;****************************************************************
;		D‚finition de la structure des donn‚es.
ikbd:		rsstruct
header:		rs.b		1 ; B.
nb_dat:		rs.b		1 ; B.

key_code:	rs.b		1 ; B.
lshift_fg:	rs.b		1 ; B.
rshift_fg:	rs.b		1 ; B.
ctrl_fg:	rs.b		1 ; B.
alt_fg:		rs.b		1 ; B.
caps_fg:	rs.b		1 ; B.

l_mbut:		rs.b		1 ; B.
r_mbut:		rs.b		1 ; B.
mousex:		rs.w		1 ; W.
mousey:		rs.w		1 ; W.
mclip_fg:	rs.b		2 ; B(+B pour alignement).
mclipxmin:	rs.w		1 ; W.
mclipxmax:	rs.w		1 ; W.
mclipymin:	rs.w		1 ; W.
mclipymax:	rs.w		1 ; W.
joystick0:	rs.b		1 ; B.
joystick1:	rs.b		1 ; B.
time:		rs.b		6 ; 6B.
stat_buf:	rs.b		256 ; 256B.

midi_hdlr:	rs.l		1 ; L(handler MIDI: rien si 0).
		rsend

;		Buffer.
IKBD_param	ds.b		300 ; Buffer pour l'IKBD.
;****************************************************************