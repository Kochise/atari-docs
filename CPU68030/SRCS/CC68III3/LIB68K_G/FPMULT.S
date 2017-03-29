| Copyright (c) 1988 by Sozobon, Limited.  Author: Johann Ruegg
|
| Permission is granted to anyone to use this software for any purpose
| on any computer system, and to redistribute it freely, with the
| following restrictions:
| 1) No charge may be made other than reasonable charges for reproduction.
| 2) Modified versions must be clearly marked as such.
| 3) The authors are not responsible for any harmful consequences
|    of using this software, even if they result from defects in it.
|
| These  routines clobber the registers d0-d2/a0-a1. Check if this is
| compatible with your compiler|
| In the MINIX distribution, C68 fulfills this requirement. The CP/M-68K
| version of C68 even considers d0-d2/a0-a2 as scratch registers, so this
| works also.
| You will have difficulties with compilers that use less scratch registers,
| i.e. that expect one of d0-d2/a0-a1 to be unchanged across function
| calls.
|
| MODIFICATION:
|
| D.W.Brooks	Apr 89	Tightened up some coding, and looked after some
|			trailing bits for the sake of textbook rounding.
|
| M.M"uller	Dec 90	avoid use of a2
|
|	sfmul
|
	.text

	.globl	__sfmul
	.globl	.fpmult
__sfmul:
.fpmult:
	link	a6,#-4
	movl	d3,a0		| save scratch registers
	movl	d4,a1
	movl	d5,a6@(-4)
	movl	a6@(8),d0
	movl	a6@(12),d1

	movl	#0x7F,d2 	| Calculate the presumed exponent
	movl	d2,d3
	andw	d0,d2
	beq	ret		| Mult by 0: d0 is correct
	andw	d1,d3
	beq	ret0		| Mult by 0: set d0
	addw	d3,d2
	subw	#0x40,d2 	| Remove the extra bias

	clrb	d0		| Calculate the absolute mantissa product
	clrb	d1
	movw	d0,d3		| Get least significant bits of result
	mulu	d1,d3
	swap	d3		| d3 range now 0...fe01

	movw	d0,d4
	movw	d1,d5
	swap	d0
	swap	d1
	mulu	d0,d5		| calculate inner portion
	mulu	d1,d4
	addl	d3,d4		| no carry since d3 <= fe01 && d4 <= fffe0001
	addl	d4,d5
	bcc	nocar1
	movw	d5,d3		| Save trailing bits
	movw	#1,d5
	bra	t1
nocar1:
	movw	d5,d3
	clrw	d5
t1:
	swap	d5

	mulu	d1,d0		| calculate most significant part
	addl	d5,d0
	bcc	nocar2
	roxrl	#1,d0
	addw	#1,d2		| Normalize down
nocar2:
	bmi	norm
	addl	d0,d0		| only need at most 1 shift: started norm AB
	subw	#1,d2
norm:
	addl	#0x80,d0 	| Round uppppp....
	bcc	nocar3
	roxrl	#1,d0
	addw	#1,d2
nocar3:
	tstb	d0		| Check if trailer was exactly 0x80 (now 0x00)
	bne	rebuild
	tstw	d3		| Check back with spare bits
	bne	rebuild
	andw	#0xFE00,d0	| Round to even
rebuild:
	tstw	d2		| Reconstruct the number.  First test overflow
	ble	underflow	| Could be mult by 0
	cmpw	#0x7F,d2
	bgt	overflow
expsign:
	movb	d2,d0		| Stuff exponent in
	movb	a6@(11),d1	 | Calculate sign
	movb	a6@(15),d2
	eorb	d1,d2
	andb	#0x80,d2
	orb	d2,d0
ret:
	movl	a1,d4
	movl	a0,d3
	movl	a6@(-4),d5
	unlk	a6
	rts

ret0:
underflow:
	clrl	d0		| Underflow, return 0
	bra	ret

overflow:
	movl	#0x7F,d2 	| Overflow, return +/- huge
	movl	#0xFFFFFFFF,d0
	bra	expsign
|
	.globl	.asfpmult
.asfpmult:
	link	a6,#0
	movl	a6@(12),sp@-
	movl	a6@(8),a0
	movl	a0@,sp@-
	jsr	.fpmult
	movl	a6@(8),a0
	movl	d0,a0@
	unlk	a6
	rts
