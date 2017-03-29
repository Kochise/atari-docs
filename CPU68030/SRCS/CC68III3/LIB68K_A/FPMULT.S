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
! MODIFICATION:
!
! D.W.Brooks	Apr 89	Tightened up some coding, and looked after some
!			trailing bits for the sake of textbook rounding.
!
! M.M"uller	Dec 90	avoid use of a2
!
!	sfmul
!
	.sect	.text
	.sect	.rom
	.sect	.data
	.sect	.bss
	.sect	.text
	.define	__sfmul
	.define	.fpmult
__sfmul:
.fpmult:
	link	a6,#-4
	move.l	d3,a0		! save scratch registers
	move.l	d4,a1
	move.l	d5,-4(a6)
	move.l	8(a6),d0
	move.l	12(a6),d1

	move.l	#0x7F,d2 	! Calculate the presumed exponent
	move.l	d2,d3
	and.w	d0,d2
	beq	ret		! Mult by 0: d0 is correct
	and.w	d1,d3
	beq	ret0		! Mult by 0: set d0
	add.w	d3,d2
	sub.w	#0x40,d2 	! Remove the extra bias

	clr.b	d0		! Calculate the absolute mantissa product
	clr.b	d1
	move.w	d0,d3		! Get least significant bits of result
	mulu	d1,d3
	swap	d3		! d3 range now 0...fe01

	move.w	d0,d4
	move.w	d1,d5
	swap	d0
	swap	d1
	mulu	d0,d5		! calculate inner portion
	mulu	d1,d4
	add.l	d3,d4		! no carry since d3 <= fe01 && d4 <= fffe0001
	add.l	d4,d5
	bcc	nocar1
	move.w	d5,d3		! Save trailing bits
	move.w	#1,d5
	bra	t1
nocar1:
	move.w	d5,d3
	clr.w	d5
t1:
	swap	d5

	mulu	d1,d0		! calculate most significant part
	add.l	d5,d0
	bcc	nocar2
	roxr.l	#1,d0
	add.w	#1,d2		! Normalize down
nocar2:
	bmi	norm
	add.l	d0,d0		! only need at most 1 shift: started norm AB
	sub.w	#1,d2
norm:
	add.l	#0x80,d0 	! Round uppppp....
	bcc	nocar3
	roxr.l	#1,d0
	add.w	#1,d2
nocar3:
	tst.b	d0		! Check if trailer was exactly 0x80 (now 0x00)
	bne	rebuild
	tst.w	d3		! Check back with spare bits
	bne	rebuild
	and.w	#0xFE00,d0	! Round to even
rebuild:
	tst.w	d2		! Reconstruct the number.  First test overflow
	ble	underflow	! Could be mult by 0
	cmp.w	#0x7F,d2
	bgt	overflow
expsign:
	move.b	d2,d0		! Stuff exponent in
	move.b	11(a6),d1	 ! Calculate sign
	move.b	15(a6),d2
	eor.b	d1,d2
	and.b	#0x80,d2
	or.b	d2,d0
ret:
	move.l	a1,d4
	move.l	a0,d3
	move.l	-4(a6),d5
	unlk	a6
	rts

ret0:
underflow:
	clr.l	d0		! Underflow, return 0
	bra	ret

overflow:
	move.l	#0x7F,d2 	! Overflow, return +/- huge
	move.l	#0xFFFFFFFF,d0
	bra	expsign
!
	.define	.asfpmult
.asfpmult:
	link	a6,#0
	move.l	12(a6),-(a7)
	move.l	8(a6),a0
	move.l	(a0),-(a7)
	jsr	.fpmult
	move.l	8(a6),a0
	move.l	d0,(a0)
	unlk	a6
	rts
