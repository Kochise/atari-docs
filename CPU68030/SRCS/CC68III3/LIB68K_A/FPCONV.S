! Copyright (c) 1988 by Sozobon, Limited.  Author: Johann Ruegg
!
! Permission is granted to anyone to use this software for any purpose
! on any computer system, and to redistribute it freely, with the
! following restrictions:
! 1) No charge may be made other than reasonable charges for reproduction.
! 2) Modified versions must be clearly marked as such.
! 3) The authors are not responsible for any harmful consequences
!    of using this software, even if they result from defects in it.
!
! Modified for the ACK assembler by Christoph van Wuellen, but I
! did not add functionality.
! These routines handle the Motorola FastFloatingPoint format.
!
! These  routines clobber the registers d0-d2/a0-a1. Check if this is
! compatible with your compiler!
! In the MINIX distribution, C68 fulfills this requirement. The CP/M-68K
! version of C68 even considers d0-d2/a0-a2 as scratch registers, so this
! works also.
! You will have difficulties with compiles that use less scratch registers,
! i.e. that expect one of d0-d2/a0-a1 to be unchanged across function
! calls.
!
!
	.sect	.text
	.sect	.rom
	.sect	.data
	.sect	.bss
	.sect	.text
!
	.define	.fpltof
.fpltof:
	link	a6,#-10
	movem.l	d3/d4,-(a7)
	move.l	8(a6),d3
	bge	_1
	move.w	#128,d4
	move.l	d3,d0
	neg.l	d0
	move.l	d0,d3
	bra	_2
_1:
	move.l	#0,d4
_2:
	move.l	d3,-(a7)
	jsr	.fputof
	add.l	#4,a7
	ext.l	d4
	or.l	d4,d0
_3:
	movem.l	-18(a6),d3/d4
	unlk	a6
	rts
!
	.define	.fputof
.fputof:
	link	a6,#-6
	movem.l	d3/d4,-(a7)
	move.l	8(a6),d4
	bne	_4
	move.l	#0,d0
_6:
	movem.l	(a7)+,d3/d4
	unlk	a6
	rts
_4:
	move.l	#96,d3
_7:
	tst.l	d4
	ble	_8
	asl.l	#1,d4
	sub.w	#1,d3
	bra	_7
_8:
	move.l	d4,d0
	and.l	#-256,d0
	ext.l	d3
	or.l	d3,d0
	bra	_6
!
	.define	.fpftol
.fpftol:
	link	a6,#-8
	movem.l	d3/d4,-(a7)
	move.l	8(a6),d3
	move.l	d3,d0
	and.l	#128,d0
	beq	_9
	eor.l	#128,d3
	move.l	d3,-(a7)
	jsr	.fpftou
	add.l	#4,a7
	move.l	d0,d4
	bge	_11
	move.l	#-2147483648,d0
_13:
_10:
	movem.l	-16(a6),d3/d4
	unlk	a6
	rts
_11:
	move.l	d4,d0
	neg.l	d0
	bra	_13
_9:
	move.l	d3,-(a7)
	jsr	.fpftou
	add.l	#4,a7
	move.l	d0,d4
	bge	_14
	move.l	#2147483647,d0
	bra	_13
_14:
	move.l	d4,d0
	bra	_13
!
	.define	.fpftou
.fpftou:
	link	a6,#-6
	movem.l	d3/d4,-(a7)
	move.l	8(a6),d0
	and.l	#-256,d0
	move.l	d0,d3
	move.l	8(a6),d0
	and.l	#127,d0
	move.w	d0,d4
	cmp.w	#64,d4
	blt	_18
	tst.l	d3
	bne	_16
_18:
	move.l	#0,d0
_19:
	movem.l	(a7)+,d3/d4
	unlk	a6
	rts
_16:
	cmp.w	#96,d4
	ble	_20
	move.l	#-1,d0
	bra	_19
_20:
	sub.w	#64,d4
	move.l	#32,d0
	sub.w	d4,d0
	ext.l	d0
	lsr.l	d0,d3
	move.l	d3,d0
	bra	_19
