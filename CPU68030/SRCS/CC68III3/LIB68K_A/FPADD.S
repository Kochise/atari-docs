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
! D.W.Brooks	Mar 89	Implemented rounding, inlined one-call subroutines,
!			and several other speedups
!
! M.M"uller	Dec 90	avoid use of a2
!
! Rounding in the ambiguous case (tail byte = 0x80) uses round-to-even, as
! Knuth insists (TAOCP3SNA).
!
!	sfsub
!
	.sect	.text
	.sect	.rom
	.sect	.data
	.sect	.bss
	.sect	.text
	.define	__sfsub
	.define	.fpsub
__sfsub:
.fpsub:
	eor.b	#0x80,11(a7)	! negate B, fall through (can produce -0.0)
!
!	sfadd
!
	.define	__sfadd
	.define	.fpadd
__sfadd:
.fpadd:
	move.l	d3,a1		! save d3
	move.l	d4,a0		! and d4
	move.l	4(a7),d0	! First arg
	move.l	8(a7),d1	! Second arg
	move.l	d0,d4		! Keeps the result's sign
	move.l #0x7f,d3

	move.b	d0,d2		! Compare signs only
	eor.b	d1,d2
	bpl	same_sign
! different signs
	and.b	d3,d0		! Force positive
	and.b	d3,d1

	move.l	d0,d2		! note d2 is copy of d0
	cmp.b	d0,d1		! Compare magnitudes
	bne	sk1
	cmp.l	d0,d1
sk1:
	ble	norev1
	move.l	d1,d0		! swap d0/d1...d0 was saved in d2...
	move.l	d2,d1
	move.b	d0,d2		! ...now d2.b is copy of new d0.b
	not.b	d4		! Invert sign
norev1:
! Begin unsigned subtract. Here we have (d0-d1), d0 >= d1, both positive.
! d2.b has result exp.	Subtract 0.0 works without needing a special case.

	move.b	d0,d3
	sub.b	d1,d3		! diff of exps (in low byte)

	clr.b	d0		! Extract mantissas
	clr.b	d1

	cmp.b	#25,d3
	bgt	out		! Nonsignificant addend: d0 is correct mantissa
	lsr.l	d3,d1		! Shift uses d3 mod 64
	sub.l	d1,d0

	beq	out0		! Zero: all done!
	bmi	outsub		! Already normalized
! normalize loop
nloop:
	sub.b	#1,d2
	ble	underfl
	add.l	d0,d0
	bpl	nloop

outsub:
	add.l	#0x80,d0 	! Force a rounding step.  This can't overflow.
				! (rum-ti-rum...can it?)
!
! Common exit point for checking rounding after adding 0x80.  If the tail
! was not 0x80, it's already the correct result.  Otherwise, the tail is now
! 0, and we implement the round-to-even.
!
outround:
	tst.b	d0
	bne	out
	and.w	#0xFE00,d0
!
! Common exit point.  d0 has the mantissa, d2 the exponent and d4 the sign.
!
out:
	move.b	d2,d0
	and.b	#0x80,d4
	or.b	d4,d0		! fix sign
!
! Come here when d0 has the result
!
out0:
	move.l	a1,d3		! restore
	move.l	a0,d4
	rts

! underflow
underfl:
	move.l #0,d0
	bra	out0
!
! same signs: do add.
!
same_sign:
	and.b	d3,d0		! Force both positive
	and.b	d3,d1

	move.l	d0,d2
	cmp.b	d0,d1		! Compare magnitudes
	bne	sk2
	cmp.l	d0,d1
sk2:
	ble	norev2
	move.l	d1,d0		! Swap d0/d1...
	move.l	d2,d1
	move.b	d0,d2		! ...and d2.b is a copy of d0.b
norev2:
! Begin unsigned add: (d0+d1), d0 >= d1
	sub.b	d1,d0
	move.b	d0,d3		! diff of exps

	clr.b	d0		! Extract mantissas
	clr.b	d1

	cmp.b	#25,d3
	bge	out		! Nonsignificant addend: d0 has result mantissa
	lsr.l	d3,d1
	add.l	d1,d0
	bcc	around
	roxr.l	#1,d0		! Mantissa overflowed the word
	add.b	#1,d2
	bmi	oflo		! Exponent too hot to handle

around: 			! Round the fraction.
	add.l	#0x80,d0 	! This rounds unless d0.b was 0x80
	bcc	outround	! No overflow, but do final rounding
	roxr.l	#1,d0		! Actually loads 0x800000nn
	add.b	#1,d2		! Compensate
	bpl	out		! Ok if no exponent overflow

oflo:
	move.l	#0xffffffff,d0	! Handle exponent overflow, maintaining sign
	move.l	#0x7f,d2
	bra	out
!
	.define	.asfpadd
.asfpadd:
	link	a6,#0
	move.l	12(a6),-(a7)
	move.l	8(a6),a0
	move.l	(a0),-(a7)
	jsr	.fpadd
	move.l	8(a6),a0
	move.l	d0,(a0)
	unlk	a6
	rts
!
	.define	.asfpsub
.asfpsub:
	link	a6,#0
	move.l	12(a6),-(a7)
	move.l	8(a6),a0
	move.l	(a0),-(a7)
	jsr	.fpadd
	move.l	8(a6),a0
	move.l	d0,(a0)
	unlk	a6
	rts
