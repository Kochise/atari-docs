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
| MODIFICATIONS:
|
| D.W.Brooks	Mar 89	Implemented rounding, inlined one-call subroutines,
|			and several other speedups
|
| M.M"uller	Dec 90	avoid use of a2
|
| Rounding in the ambiguous case (tail byte = 0x80) uses round-to-even, as
| Knuth insists (TAOCP3SNA).
|
|	sfsub
|
	.text

	.globl	__sfsub
	.globl	.fpsub
__sfsub:
.fpsub:
	eorb	#0x80,sp@(11)	| negate B, fall through (can produce -0.0)
|
|	sfadd
|
	.globl	__sfadd
	.globl	.fpadd
__sfadd:
.fpadd:
	movl	d3,a1		| save d3
	movl	d4,a0		| and d4
	movl	sp@(4),d0	| First arg
	movl	sp@(8),d1	| Second arg
	movl	d0,d4		| Keeps the result's sign
	movl	#0x7f,d3

	movb	d0,d2		| Compare signs only
	eorb	d1,d2
	bpl	same_sign
| different signs
	andb	d3,d0		| Force positive
	andb	d3,d1

	movl	d0,d2		| note d2 is copy of d0
	cmpb	d0,d1		| Compare magnitudes
	bne	sk1
	cmpl	d0,d1
sk1:
	ble	norev1
	movl	d1,d0		| swap d0/d1...d0 was saved in d2...
	movl	d2,d1
	movb	d0,d2		| ...now d2.b is copy of new d0.b
	notb	d4		| Invert sign
norev1:
| Begin unsigned subtract. Here we have (d0-d1), d0 >= d1, both positive.
| d2.b has result exp.	Subtract 0.0 works without needing a special case.

	movb	d0,d3
	subb	d1,d3		| diff of exps (in low byte)

	clrb	d0		| Extract mantissas
	clrb	d1

	cmpb	#25,d3
	bgt	out		| Nonsignificant addend: d0 is correct mantissa
	lsrl	d3,d1		| Shift uses d3 mod 64
	subl	d1,d0

	beq	out0		| Zero: all done|
	bmi	outsub		| Already normalized
| normalize loop
nloop:
	subb	#1,d2
	ble	underfl
	addl	d0,d0
	bpl	nloop

outsub:
	addl	#0x80,d0 	| Force a rounding step.  This can't overflow.
				| (rum-ti-rum...can it?)
|
| Common exit point for checking rounding after adding 0x80.  If the tail
| was not 0x80, it's already the correct result.  Otherwise, the tail is now
| 0, and we implement the round-to-even.
|
outround:
	tstb	d0
	bne	out
	andw	#0xFE00,d0
|
| Common exit point.  d0 has the mantissa, d2 the exponent and d4 the sign.
|
out:
	movb	d2,d0
	andb	#0x80,d4
	orb	d4,d0		| fix sign
|
| Come here when d0 has the result
|
out0:
	movl	a1,d3		| restore
	movl	a0,d4
	rts

| underflow
underfl:
	movq	#0,d0
	bra	out0
|
| same signs: do add.
|
same_sign:
	andb	d3,d0		| Force both positive
	andb	d3,d1

	movl	d0,d2
	cmpb	d0,d1		| Compare magnitudes
	bne	sk2
	cmpl	d0,d1
sk2:
	ble	norev2
	movl	d1,d0		| Swap d0/d1...
	movl	d2,d1
	movb	d0,d2		| ...and d2.b is a copy of d0.b
norev2:
| Begin unsigned add: (d0+d1), d0 >= d1
	subb	d1,d0
	movb	d0,d3		| diff of exps

	clrb	d0		| Extract mantissas
	clrb	d1

	cmpb	#25,d3
	bge	out		| Nonsignificant addend: d0 has result mantissa
	lsrl	d3,d1
	addl	d1,d0
	bcc	around
	roxrl	#1,d0		| Mantissa overflowed the word
	addb	#1,d2
	bmi	oflo		| Exponent too hot to handle

around: 			| Round the fraction.
	addl	#0x80,d0 	| This rounds unless d0.b was 0x80
	bcc	outround	| No overflow, but do final rounding
	roxrl	#1,d0		| Actually loads 0x800000nn
	addb	#1,d2		| Compensate
	bpl	out		| Ok if no exponent overflow

oflo:
	movl	#0xffffffff,d0	| Handle exponent overflow, maintaining sign
	movl	#0x7f,d2
	bra	out
|
	.globl	.asfpadd
.asfpadd:
	link	a6,#0
	movl	a6@(12),sp@-
	movl	a6@(8),a0
	movl	a0@,sp@-
	jsr	.fpadd
	movl	a6@(8),a0
	movl	d0,a0@
	unlk	a6
	rts
|
	.globl	.asfpsub
.asfpsub:
	link	a6,#0
	movl	a6@(12),sp@-
	movl	a6@(8),a0
	movl	a0@,sp@-
	jsr	.fpadd
	movl	a6@(8),a0
	movl	d0,a0@
	unlk	a6
	rts
