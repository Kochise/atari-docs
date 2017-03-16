;File name:	POOLFIX4.S		Revision date:	1992.03.03
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
	beq.s	L40
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
	bsr	find_os_gemdos
	tst.l	d0
	bmi	error_exit
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
	addq.l	#8,(a5)
	move.l	(a5),-(sp)
	move.l	24(a6),d0
	add.l	28(a6),d0
	move.l	d0,-(sp)
	clr.l	-(sp)
	move.l	#'_OOL',-(sp)
	bsr	place_cookie
	adda	#$10,sp
	moveq	#0,d7
	tst	d0
	bmi.s	LB6
	beq.s	LB6
	move.l	(a5),d7
	asl.l	#3,d7
LB6:
	bsr.s	find_os_gemdos
	move.l	a2,a1
	move.l	-1794(a1),a2
	move.l	a2,L69C
	move.l	a2,L694
	addq.l	#4,a2
	move.l	a2,L698
	move.l	-1100(a1),L6A0
	move.l	(ev_gemdos).w,8+nugemdos
	move.l	#12+nu_gemdos,(ev_gemdos).w
	lea	installed_s(pc),a0
	bsr.s	Cconws_a0
	move.l	24(a6),d0
	add.l	28(a6),d0
	add.l	d7,d0
	sub.l	a6,d0
	gemdos	Ptermres,d0,!
;
;
error_exit:
	bsr.s	Cconws_a0
	lea	crlf_s(pc),a0
	bsr.s	Cconws_a0
	pea	$4C0001.l
	trap	#1
	dc.b	'J',$FC	;	dc.w	$4AFC
;
;
Cconws_a0:
	gemdos	Cconws,(a0)
	rts
;
;
find_os_gemdos:
	movem.l	d1-d1/a1-a1,-(sp)
	moveq	#0,d0
	move.l	(ev_gemdos).w,a2
L130:
	cmpi.l	#'XBRA',-12(a2)
	bne.s	L140
	move.l	-4(a2),a2
	bra.s	L130
;
L140:
	move.l	a2,d1
	and.l	#$FFFFFF,d1
	move.l	(_sysbase).w,a1
	move.l	8(a1),a1
	sub.l	a1,d1
	bmi.s	L15C
	cmp.l	#$20000,d1
	bmi.s	L15E
L15C:
	moveq	#-1,d0
L15E:
	movem.l	(sp)+,d1-d1/a1-a1
	rts
;
;
installed_s:
	dc.b	'POOL PATCH OF 19-JAN-90 INSTALLED.',CR,LF
	dc.b	'Improved 27-MAR-90 by Claus Brod
crlf_s:
	dc.b	CR,LF,NUL
already_in_s:
	dc.b	'Pool patch already installed.',NUL
not_needed_s:
	dc.b	'Pool patch not needed in this TOS',NUL
bad_linkage_s:
	dc.b	'Something linked into the GEMDOS trap',CR,LF
	dc.b	'without following XBRA rules.',CR,LF,NUL
strange_TOS_s:
	dc.b	'POOLFIX4 doesn't recognize this TOS.',NUL
	even
;
;
	XB_define	nu_gemdos,'_OOL'
	tst.b	poolfix_flag
	beq.s	L26E
	bsr.s	compact_all_sub
L26E:
	move	USP,a0
	btst	#5,(sp)
	beq.s	L282
	lea	6(sp),a0
	tst	(_longframe).w
	beq.s	L282
	addq	#2,a0
L282:
	move	(a0),d0	;Pterm0 ?
	beq.s	L294
	sub	#$31,d0	;Ptermres ?
	beq.s	L294
	sub	#$18,d0	;Mfree ?
	beq.s	L294
	subq	#3,d0	;Pterm
NB: Error of POOLFIX3: Mshrink is ignored !!!
NB: Yet, it too can free RAM for compaction
L294:
	seq	poolfix_flag
	move.l	8+nugemdos(pc),a0
	jmp	(a0)
;
;
compact_all_sub:
	link	a6,#0
	movem.l	d2-d7/a3-a5,-(sp)
	suba.l	a5,a5
	move.l	L6A0(pc),a0
	move.l	(a0),a4
	clr	d3
	bra.s	L2FA
;
L2B4:
	tst.b	4(a4)
	ble.s	L2F8
	clr	d4
	clr	d5
	lea	6(a4),a3
	bra.s	L2DE
;
L2C4:
	cmpi.l	#1,12(a3)
	bne.s	L2D8
	addq	#1,d4
	move.l	a5,d0
	bne.s	L2D8
	move.l	a4,a5
	move	d5,d6
L2D8:
	addq	#1,d5
	adda	#$10,a3
L2DE:
	cmp	#4,d5
	blt.s	L2C4
	cmp	#4,d4
	bne.s	L2F6
	clr.b	4(a4)
	cmp.l	a4,a5
	bne.s	L2F4
	suba.l	a5,a5
L2F4:
	bra.s	L2F8
;
L2F6:
	add	d4,d3
L2F8:
	move.l	(a4),a4
L2FA:
	move.l	a4,d0
	bne.s	L2B4
	cmp	#4,d3
	blt	L4B4
	move.l	a5,a4
	move	d6,d7
L30A:
	addq	#1,d7
	cmp	#4,d7
	beq.s	L318
	tst.b	4(a4)
	bgt.s	L31C
L318:
	clr	d7
	move.l	(a4),a4
L31C:
	move.l	a4,d0
	beq.s	L33A
	tst.b	4(a4)
	ble.s	L30A
	move	d7,d0
	ext.l	d0
	asl.l	#4,d0
	add.l	a4,d0
	move.l	d0,a0
	cmpi.l	#1,18(a0)
	beq.s	L30A
L33A:
	bra	L4AA
;
L33E:
	bra.s	L3A8
;
L340:
	lea	6(a5),a3
	cmpi.l	#1,12(a3)
	bne.s	L3AC
	cmpi.l	#1,28(a3)
	bne.s	L3AC
	cmpi.l	#1,44(a3)
	bne.s	L3AC
	cmpi.l	#1,60(a3)
	bne.s	L3AC
	clr.b	4(a5)
	moveq	#3,d6
L372:
	addq	#1,d6
	cmp	#4,d6
	beq.s	L380
	tst.b	4(a5)
	bgt.s	L384
L380:
	clr	d6
	move.l	(a5),a5
L384:
	move.l	a5,d0
	beq.s	L3A2
	tst.b	4(a5)
	ble.s	L372
	move	d6,d0
	ext.l	d0
	asl.l	#4,d0
	add.l	a5,d0
	move.l	d0,a0
	cmpi.l	#1,18(a0)
	bne.s	L372
L3A2:
	move.l	a5,d0
	beq	L4B4
L3A8:
	tst	d6
	beq.s	L340
L3AC:
	bra.s	L412
;
L3AE:
	lea	6(a4),a3
	cmpi.l	#1,12(a3)
	beq.s	L416
	cmpi.l	#1,28(a3)
	beq.s	L416
	cmpi.l	#1,44(a3)
	beq.s	L416
	cmpi.l	#1,60(a3)
	beq.s	L416
	moveq	#3,d7
L3DC:
	addq	#1,d7
	cmp	#4,d7
	beq.s	L3EA
	tst.b	4(a4)
	bgt.s	L3EE
L3EA:
	clr	d7
	move.l	(a4),a4
L3EE:
	move.l	a4,d0
	beq.s	L40C
	tst.b	4(a4)
	ble.s	L3DC
	move	d7,d0
	ext.l	d0
	asl.l	#4,d0
	add.l	a4,d0
	move.l	d0,a0
	cmpi.l	#1,18(a0)
	beq.s	L3DC
L40C:
	move.l	a4,d0
	beq	L4B4
L412:
	tst	d7
	beq.s	L3AE
L416:
	cmp.l	a5,a4
	beq.s	L47A
	move	d6,d0
	ext.l	d0
	asl.l	#4,d0
	add.l	a5,d0
	move.l	d0,(sp)
	addq.l	#6,(sp)
	move	d7,d0
	ext.l	d0
	asl.l	#4,d0
	add.l	a4,d0
	move.l	d0,-(sp)
	addq.l	#6,(sp)
	bsr	compact_block_sub
	addq.l	#4,sp
	move	d7,d0
	ext.l	d0
	asl.l	#4,d0
	add.l	a4,d0
	move.l	d0,a0
	move.l	#1,18(a0)
L44A:
	addq	#1,d6
	cmp	#4,d6
	beq.s	L458
	tst.b	4(a5)
	bgt.s	L45C
L458:
	clr	d6
	move.l	(a5),a5
L45C:
	move.l	a5,d0
	beq.s	L47A
	tst.b	4(a5)
	ble.s	L44A
	move	d6,d0
	ext.l	d0
	asl.l	#4,d0
	add.l	a5,d0
	move.l	d0,a0
	cmpi.l	#1,18(a0)
	bne.s	L44A
L47A:
	addq	#1,d7
	cmp	#4,d7
	beq.s	L488
	tst.b	4(a4)
	bgt.s	L48C
L488:
	clr	d7
	move.l	(a4),a4
L48C:
	move.l	a4,d0
	beq.s	L4AA
	tst.b	4(a4)
	ble.s	L47A
	move	d7,d0
	ext.l	d0
	asl.l	#4,d0
	add.l	a4,d0
	move.l	d0,a0
	cmpi.l	#1,18(a0)
	beq.s	L47A
L4AA:
	move.l	a5,d0
	beq.s	L4B4
	move.l	a4,d0
	bne	L33E
L4B4:
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
	bra.s	L4F4
;
L4CE:
	move	d7,a0
	adda.l	a0,a0
	adda.l	a0,a0
	adda.l	#L694,a0
	move.l	(a0),-4(a6)
	move.l	-4(a6),a3
	move.l	(a3),a4
	bra.s	L4EE
;
;
L4E6:
	cmp.l	a5,a4
	beq.s	L500
	move.l	a4,a3
	move.l	(a3),a4
L4EE:
	move.l	a4,d0
	bne.s	L4E6
	addq	#1,d7
L4F4:
	cmp	#2,d7
	blt.s	L4CE
	move	#1,d0
	bra.s	L52A
L500:
	move.l	L69C(pc),a0
	cmp.l	8(a0),a5
	bne.s	L514
	move.l	L69C(pc),a0
	move.l	12(a6),8(a0)
L514:
	move.l	12(a6),a0
	move.l	a5,a1
	move	#7,d1		;NB: ERROR d1 unprotected
L51E:
	move	(a1)+,(a0)+
	dbf	d1,L51E		;NB: ERROR d1 unprotected
	move.l	12(a6),(a3)
	clr	d0
L52A:
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
	moveq	#0,d7
	move.l	#1,-(sp)
	move	#Super&$ff,-(sp)
	trap	#1
	tst.l	d0
	bne.s	L55E
	clr.l	2(sp)
	move	#Super&$ff,(sp)
	trap	#1
	move.l	d0,d7
L55E:
	addq.l	#6,sp
	move.l	(_cookies).w,a0
	move.l	a0,d0
	beq.s	L580
L568:
	move.l	(a0),d0
	cmp.l	d0,d6
	beq.s	L576
	tst.l	d0
	beq.s	L580
	addq.l	#8,a0
	bra.s	L568
;
L576:
	move.l	a6,d0
	beq.s	L57E
	move.l	4(a0),(a6)
L57E:
	moveq	#1,d0
L580:
	move.l	d0,d6
	tst.l	d7
	beq.s	L590
	gemdos	Super!_ind,d7
L590:
	move.l	d6,d0
	movem.l	(sp)+,d6-d7/a6-a6
	rts
;
;
place_cookie:
	link	a6,#0
	move.l	d7,-(sp)
	moveq	#1,d7
	move.l	d7,-(sp)
	moveq	#0,d7
	move	#$20,-(sp)
	trap	#1
	tst.l	d0
	bne.s	L5BA
	clr.l	2(sp)
	move	#$20,(sp)
	trap	#1
	move.l	d0,d7
L5BA:
	addq.l	#6,sp
	move.l	(_cookies).w,a0
	move.l	a0,d0
	beq.s	L5F0
	moveq	#0,d0
L5C6:
	addq.l	#1,d0
	tst.l	(a0)
	beq.s	L5D0
	addq.l	#8,a0
	bra.s	L5C6
;
L5D0:
	cmp.l	4(a0),d0
	beq.s	L642
	move.l	4(a0),12(a0)
	clr.l	8(a0)
	move.l	8(a6),(a0)
	move.l	12(a6),4(a0)
	moveq	#0,d0
	bra	L674
;
L5F0:
	cmpi.l	#2,20(a6)
	blt.s	L672
	lea	L6A6(pc),a0
	move.l	(memctrl).w,(a0)+	;NB:was 'move.l  (resvector)...' in POOLFIX3
;NB: Fatal POOLFIX4 error:  'memctrl' has been mixed up with 'resvector'
;NB: This error may be a lost bit during unpacked file transfer
;NB: This error is hidden if no resetroutine has been loaded
	move.l	(resvalid).w,(a0)
	move.l	#L630,(resvector).w
	move.l	#$31415926,(resvalid).w
	move.l	16(a6),a0
	move.l	a0,(_cookies).w
	move.l	8(a6),(a0)+
	move.l	12(a6),(a0)+
	clr.l	(a0)+
	move.l	20(a6),(a0)
	moveq	#1,d0
	bra.s	L674
;
;NB: This resetvector is linked by POOLFIX4 without XBRA !!!
L630:
	clr.l	(_cookies).w
	move.l	L6AA(pc),(resvalid).w
	move.l	L6A6(pc),(resvector).w	;NB: unfortunately 'memctrl' was saved, not 'resvector'
	jmp	(a6)
;
L642:
	cmp.l	20(a6),d0
	ble.s	L672
	move.l	d0,d1
	subq.l	#2,d1
	move.l	(_cookies).w,a0
	move.l	16(a6),a1
	move.l	a1,(_cookies).w
L658:
	move.l	(a0)+,(a1)+
	move.l	(a0)+,(a1)+
	dbf	d1,L658
	move.l	8(a6),(a1)+
	move.l	12(a6),(a1)+
	clr.l	(a1)+
	move.l	20(a6),(a1)
	moveq	#1,d0
	bra.s	L674
;
L672:
	moveq	#-1,d0
L674:
	tst.l	d7
	beq.s	L68A
	move.l	d0,8(a6)
	gemdos	Super!_ind,d7
	move.l	8(a6),d0
L68A:
	move.l	(sp)+,d7
	unlk	a6
	rts
;
;
	bss	;$690:
;
basepage_p:	ds.b	4	;unref
L694:		ds.b	4
L698:		ds.b	4
L69C:		ds.b	4
L6A0:		ds.b	4
poolfix_flag:	ds.b	2
L6A6:		ds.b	4
L6AA:		ds.b	4
;
;
	end	;of file:	POOLFIX4.S
