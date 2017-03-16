;File name:	POOLFIX3.S		Revision date:	1992.03.03
;Revised by:	Ulf Ronald Andersson	Disassembled:	1992.03.03
;
;
	include	TOS\URAn_SYS.S
	include	TOS\URAn_DOS.S
	include	TOS\URAn_XB.S
;
;
	text
;
;
L0:
	move.l	4(sp),a6
	move.l	a6,basepage_p
	clr.l	-(sp)
	move	#$20,-(sp)
	trap	#1
;NB: ERROR of POOLFIX3, returned SSP is ignored here
;NB: This may not work in all TOS versions
	gemdos	Sversion
	lea	not_needed_s(pc),a0
	cmp	#$1500,d0
	bne	error_exit
	lea	strange_TOS_s(pc),a0
	move.l	(_sysbase).w,a1
	move	2(a1),d0
	cmp	#$104,d0		;TOS 1.04 ?
	beq.b	L40
	cmp	#$106,d0		;TOS 1.06 ?
	bne	error_exit
L40:
	clr.l	-(sp)
	move.l	#'_OOL',-(sp)
	bsr	find_cookie		;test for own 'cookie'
	addq.l	#4,sp
	lea	already_in_s(pc),a0
	tst	d0
	bne	error_exit
	lea	bad_linkage_s(pc),a0
	move.l	(_sysbase).w,a1
	move.l	8(a1),a1
	move.l	(ev_gemdos).w,a2
	move.l	a2,d0
	sub.l	a1,d0
	cmp.l	#$20000,d0
	bhi	error_exit
	lea	strange_TOS_s(pc),a0
	cmpi	#$2EBC,-1796(a2)
	bne	error_exit
	cmpi	#$2A79,-1102(a2)
	bne	error_exit
	clr.l	-(sp)
	move.l	sp,a5
	move.l	a5,-(sp)
	clr.l	-(sp)
	bsr	find_cookie		;test for free 'cookie'
	addq.l	#4,sp
	addi.l	#$8,(a5)
	move.l	(a5),-(sp)
	move.l	24(a6),d0
	add.l	28(a6),d0
	move.l	d0,-(sp)
	move.l	#$0,-(sp)
	move.l	#'_OOL',-(sp)
	bsr	place_cookie
	adda	#$10,sp
	moveq	#0,d7
	tst	d0
	bmi.b	LCE
	beq.b	LCE
	move.l	(a5),d7
	asl.l	#3,d7
LCE:
	move.l	(ev_gemdos).w,a1
	move.l	-1794(a1),a2
	move.l	a2,L78E
	move.l	a2,L786
	addq.l	#4,a2
	move.l	a2,L78A
	move.l	-1100(a1),a2
	move.l	a2,L792
	move.l	(ev_gemdos).w,8+nu_gemdos
	move.l	#12+nu_gemdos,$84.w
	gemdos	Cconws,installed_s
	move.l	24(a6),d0
	add.l	28(a6),d0
	add.l	d7,d0
	sub.l	a6,d0
	gemdos	Ptermres,d0,#0
;
;
error_exit:
	move.l	a0,-(sp)
	move	#$9,-(sp)
	trap	#1
	addq	#6,sp
	move.l	#L172,-(sp)
	move	#$9,-(sp)
	trap	#1
	addq	#6,sp
	move	#$1,-(sp)
	move	#$4C,-(sp)
	trap	#1
	dc.b	'J',$FC	;	dc.w	$4AFC
;
;
installed_s:
	dc.b	'POOL PATCH OF 19-JAN-90 INSTALLED.',CR,LF,NUL
already_in_s:
	dc.b	'The pool patch is already installed.',NUL
not_needed_s:
	dc.b	'The pool patch is not needed in this TOS',NUL
bad_linkage_s:
	dc.b	'The pool patch must run first in the',CR,LF
	dc.b	'\AUTO\ folder (before any program',CR,LF
	dc.b	'links into the GEMDOS (trap 1) vector).',NUL
strange_TOS_s:
	dc.b	'This GEMDOS needs the pool patch, but',CR,LF
	dc.b	"this program doesn't recognize this TOS.",NUL
;
;
basepage_p:	dc.l	0	;unref
;
;
	XB_define	nu_gemdos,'_OOL'
	tst.b	poolfix_flag
	beq	L2A2
	bsr	compact_all_sub
L2A2:
	move	USP,a0
	btst	#5,(sp)
	beq.b	L2B6
	lea	6(sp),a0
	tst	(_longframe).w
	beq.b	L2B6
	addq.l	#2,a0
L2B6:
	move	(a0),d0	;Pterm0 ?
	beq.b	L2CA
	cmp	#$49,d0	;Mfree ?
	beq.b	L2CA
	cmp	#$31,d0	;Ptermres ?
	beq.b	L2CA
	cmp	#$4C,d0	;Pterm ?
NB: Error of POOLFIX3: Mshrink is ignored !!!
NB: Yet, it too can free RAM for compaction
L2CA:
	seq	poolfix_flag
	move.l	8+nu_gemdos,a0
	jmp	(a0)
;
;
compact_all_sub:
	link	a6,#0
	movem.l	d2-d7/a3-a5,-(sp)
	suba.l	a5,a5
	move.l	L792,a0
	move.l	(a0),a4
	clr	d3
	bra	L34A
;
L2F0:
	tst.b	4(a4)
	ble	L348
	clr	d4
	clr	d5
	lea	6(a4),a3
	bra	L328
;
L304:
	cmpi.l	#$1,12(a3)
	bne	L31E
	add	#$1,d4
	move.l	a5,d0
	bne	L31E
	move.l	a4,a5
	move	d5,d6
L31E:
	add	#$1,d5
	adda.l	#$10,a3
L328:
	cmp	#$4,d5
	blt.b	L304
	cmp	#$4,d4
	bne	L346
	clr.b	4(a4)
	cmp.l	a4,a5
	bne	L342
	suba.l	a5,a5
L342:
	bra	L348
;
L346:
	add	d4,d3
L348:
	move.l	(a4),a4
L34A:
	move.l	a4,d0
	bne.b	L2F0
	cmp	#$4,d3
	blt	L566
	move.l	a5,a4
	move	d6,d7
L35A:
	add	#$1,d7
	cmp	#$4,d7
	beq	L36E
	tst.b	4(a4)
	bgt	L372
L36E:
	clr	d7
	move.l	(a4),a4
L372:
	move.l	a4,d0
	beq	L392
	tst.b	4(a4)
	ble.b	L35A
	move	d7,d0
	ext.l	d0
	asl.l	#4,d0
	add.l	a4,d0
	move.l	d0,a0
	cmpi.l	#$1,18(a0)
	beq.b	L35A
L392:
	bra	L55A
;
L396:
	bra	L41C
;
L39A:
	lea	6(a5),a3
	cmpi.l	#$1,12(a3)
	bne	L418
	cmpi.l	#$1,28(a3)
	bne	L418
	cmpi.l	#$1,44(a3)
	bne	L418
	cmpi.l	#$1,60(a3)
	bne	L418
	clr.b	4(a5)
	move	#$3,d6
L3D6:
	add	#$1,d6
	cmp	#$4,d6
	beq	L3EA
	tst.b	4(a5)
	bgt	L3EE
L3EA:
	clr	d6
	move.l	(a5),a5
L3EE:
	move.l	a5,d0
	beq	L40E
	tst.b	4(a5)
	ble.b	L3D6
	move	d6,d0
	ext.l	d0
	asl.l	#4,d0
	add.l	a5,d0
	move.l	d0,a0
	cmpi.l	#$1,18(a0)
	bne.b	L3D6
L40E:
	move.l	a5,d0
	beq	L566
	bra	L41C
;
L418:
	bra	L422
;
L41C:
	tst	d6
	beq	L39A
L422:
	bra	L4A4
;
L426:
	lea	6(a4),a3
	cmpi.l	#$1,12(a3)
	beq	L4A0
	cmpi.l	#$1,28(a3)
	beq	L4A0
	cmpi.l	#$1,44(a3)
	beq	L4A0
	cmpi.l	#$1,60(a3)
	beq	L4A0
	move	#$3,d7
L45E:
	add	#$1,d7
	cmp	#$4,d7
	beq	L472
	tst.b	4(a4)
	bgt	L476
L472:
	clr	d7
	move.l	(a4),a4
L476:
	move.l	a4,d0
	beq	L496
	tst.b	4(a4)
	ble.b	L45E
	move	d7,d0
	ext.l	d0
	asl.l	#4,d0
	add.l	a4,d0
	move.l	d0,a0
	cmpi.l	#$1,18(a0)
	beq.b	L45E
L496:
	move.l	a4,d0
	beq	L566
	bra	L4A4
;
L4A0:
	bra	L4AA
;
L4A4:
	tst	d7
	beq	L426
L4AA:
	cmp.l	a5,a4
	beq	L522
	move	d6,d0
	ext.l	d0
	asl.l	#4,d0
	add.l	a5,d0
	move.l	d0,(sp)
	addi.l	#$6,(sp)
	move	d7,d0
	ext.l	d0
	asl.l	#4,d0
	add.l	a4,d0
	move.l	d0,-(sp)
	addi.l	#$6,(sp)
	jsr	compact_block_sub
	addq.l	#4,sp
	move	d7,d0
	ext.l	d0
	asl.l	#4,d0
	add.l	a4,d0
	move.l	d0,a0
	move.l	#$1,18(a0)
L4EA:
	add	#$1,d6
	cmp	#$4,d6
	beq	L4FE
	tst.b	4(a5)
	bgt	L502
L4FE:
	clr	d6
	move.l	(a5),a5
L502:
	move.l	a5,d0
	beq	L522
	tst.b	4(a5)
	ble.b	L4EA
	move	d6,d0
	ext.l	d0
	asl.l	#4,d0
	add.l	a5,d0
	move.l	d0,a0
	cmpi.l	#$1,18(a0)
	bne.b	L4EA
L522:
	add	#$1,d7
	cmp	#$4,d7
	beq	L536
	tst.b	4(a4)
	bgt	L53A
L536:
	clr	d7
	move.l	(a4),a4
L53A:
	move.l	a4,d0
	beq	L55A
	tst.b	4(a4)
	ble.b	L522
	move	d7,d0
	ext.l	d0
	asl.l	#4,d0
	add.l	a4,d0
	move.l	d0,a0
	cmpi.l	#$1,18(a0)
	beq.b	L522
L55A:
	move.l	a5,d0
	beq	L566
	move.l	a4,d0
	bne	L396
L566:
	tst.l	(sp)+
	movem.l	(sp)+,d3-d7/a3-a5
	unlk	a6
	rts
;
;
;NB: fatal POOLFIX3 error in this subroutine  !!!
;NB: It may be called for ANY gemdos function following a RAM release
;NB: so at final gemdos exit all regs except d0/a0 must be restored
;NB: but d1 is used here, without protection either here or above
;NB: ONLY the 'Super' function has permission to do this !!!
;NB: This may BOMB any program expecting unchanged d1    !!!
compact_block_sub:
	link	a6,#-4
	movem.l	d6-d7/a3-a5,-(sp)
	move.l	8(a6),a5
	clr	d7
	bra	L5AE
;
L582:
	move	d7,a0
	adda.l	a0,a0
	adda.l	a0,a0
	adda.l	#L786,a0
	move.l	(a0),-4(a6)
	move.l	-4(a6),a3
	move.l	(a3),a4
	bra	L5A6
;
L59C:
	cmp.l	a5,a4
	beq	L5BC
	move.l	a4,a3
	move.l	(a3),a4
L5A6:
	move.l	a4,d0
	bne.b	L59C
	add	#$1,d7
L5AE:
	cmp	#$2,d7
	blt.b	L582
	move	#$1,d0
	bra	L5F0
;
L5BC:
	move.l	L78E,a0
	cmp.l	8(a0),a5
	bne	L5D6
	move.l	L78E,a0
	move.l	12(a6),8(a0)
L5D6:
	move.l	12(a6),a0
	move.l	a5,a1
	move	#$7,d1		;NB: ERROR d1 unprotected
L5E0:
	move	(a1)+,(a0)+
	dbf	d1,L5E0		;NB: ERROR d1 unprotected
	move.l	12(a6),(a3)
	clr	d0
	bra	L5F0
;
L5F0:
	tst.l	(sp)+
	movem.l	(sp)+,d7-d7/a3-a5
	unlk	a6
	rts
;
;
;int	find_cookie(long id, void **ptr)
find_cookie:
	movem.l	d6-d7/a6-a6,-(sp)
	move.l	16(sp),d6
	move.l	20(sp),a6
	clr.l	d7
	move.l	#$1,-(sp)
	move	#$20,-(sp)
	trap	#1
	tst.l	d0
	bne	L62A
	move.l	#$0,2(sp)
	move	#$20,(sp)
	trap	#1
	move.l	d0,d7
L62A:
	addq.l	#6,sp
	move.l	(_cookies).w,a0
	move.l	a0,d0
	beq	L654
L636:
	move.l	(a0),d0
	cmp.l	d0,d6
	beq	L648
	tst.l	d0
	beq	L654
	addq.l	#8,a0
	bra.b	L636
;
L648:
	move.l	a6,d0
	beq	L652
	move.l	4(a0),(a6)
L652:
	moveq	#1,d0
L654:
	move.l	d0,d6
	tst.l	d7
	beq	L666
	move.l	d7,-(sp)
	move	#$20,-(sp)
	trap	#1
	addq.l	#6,sp
L666:
	move.l	d6,d0
	movem.l	(sp)+,d6-d7/a6-a6
	rts
;
;
place_cookie:
	link	a6,#0
	move.l	d7,-(sp)
	moveq	#0,d7
	move.l	#$1,-(sp)
	move	#$20,-(sp)
	trap	#1
	tst.l	d0
	bne	L698
	move.l	#$0,2(sp)
	move	#$20,(sp)
	trap	#1
	move.l	d0,d7
L698:
	addq.l	#6,sp
	move.l	(_cookies).w,a0
	move.l	a0,d0
	beq	L6D4
	moveq	#0,d0
L6A6:
	addq.l	#1,d0
	tst.l	(a0)
	beq	L6B2
	addq.l	#8,a0
	bra.b	L6A6
;
L6B2:
	cmp.l	4(a0),d0
	beq	L732
	move.l	4(a0),12(a0)
	clr.l	8(a0)
	move.l	8(a6),(a0)
	move.l	12(a6),4(a0)
	moveq	#0,d0
	bra	L768
;
L6D4:
	cmpi.l	#$2,20(a6)
	blt	L766
	move.l	(resvector).w,L798
	move.l	(resvalid).w,L79C
	move.l	#L71C,(resvector).w
	move.l	#$31415926,(resvalid).w
	move.l	16(a6),a0
	move.l	a0,(_cookies).w
	move.l	8(a6),(a0)+
	move.l	12(a6),(a0)+
	clr.l	(a0)+
	move.l	20(a6),(a0)
	moveq	#1,d0
	bra	L768
;
L71C:
	clr.l	(_cookies).w
	move.l	L79C,(resvalid).w
	move.l	L798,(resvector).w
	jmp	(a6)
L732:
	cmp.l	20(a6),d0
	ble	L766
	move.l	d0,d1
	subq.l	#2,d1
	move.l	(_cookies).w,a0
	move.l	16(a6),a1
	move.l	a1,(_cookies).w
L74A:
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	dbf	d1,L74A
	move.l	8(a6),(a1)+
	move.l	12(a6),(a1)+
	clr.l	(a1)+
	move.l	20(a6),(a1)
	moveq	#1,d0
	bra	L768
L766:
	moveq	#-1,d0
L768:
	tst.l	d7
	beq	L780
	move.l	d0,8(a6)
	move.l	d7,-(sp)
	move	#$20,-(sp)
	trap	#1
	addq.l	#6,sp
	move.l	8(a6),d0
L780:
	move.l	(sp)+,d7
	unlk	a6
	rts
;
;
	bss	;$786:
;
L786:		ds.b	4
L78A:		ds.b	4
L78E:		ds.b	4
L792:		ds.b	4
poolfix_flag:	ds.b	2
L798:		ds.b	4
L79C:		ds.b	4
;
;
	end	;of file:	POOLFIX3.S
