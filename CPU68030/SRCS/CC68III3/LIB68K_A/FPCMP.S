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
! These  routines clobber the registers d0-d2/a0-a1. Check if this is
! compatible with your compiler!
! In the MINIX distribution, C68 fulfills this requirement. The CP/M-68K
! version of C68 even considers d0-d2/a0-a2 as scratch registers, so this
! works also.
! You will have difficulties with compilers that use less scratch registers,
! i.e. that expect one of d0-d2/a0-a1 to be unchanged across function
! calls.
!
! MODIFICATIONS:
!
! D.W.Brooks	3/5/89	Fixed sfcmp (when both -ve) and sfneg (when zero)
!
	.sect	.text
	.sect	.rom
	.sect	.data
	.sect	.bss
	.sect	.text

	.define	__sfcmp
	.define	.fpcmp
__sfcmp:
.fpcmp:
	move.l	4(sp),d0
	move.l	8(sp),d1
	move.b	d0,d2		! See if both signs are negative
	and.b	d1,d2
	bpl	L0
!
! Modification by CvW: Why? Doing it in-line is better here!
!
!	move.l	d0,d2		! They are: switch arguments so the rest works
!	move.l	d1,d0
!	move.l	d2,d1
	cmp.b	d0,d1
	bne	L1
	cmp.l	d0,d1
	rts
!
L0:
	cmp.b	d1,d0
	bne	L1
	cmp.l	d1,d0
L1:
	rts


	.define	__sfneg
	.define	.fpneg
__sfneg:
.fpneg:
	move.l	4(sp),d0
	beq	L2
	eor.b	#0x80,d0
L2:
	rts


	.define	__sftst
	.define	.fptst
__sftst:
.fptst:
	tst.b	7(sp)
	rts

