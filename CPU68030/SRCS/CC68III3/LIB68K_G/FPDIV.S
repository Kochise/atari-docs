| FPDIV.S -- floating point divide
| Copyright = David Brooks, 1989 All Rights Reserved
|
| This version works by a normal bitwise shift/subtract loop, with separate
| handling of the exponent and a final normalization.  26 bits are computed,
| to allow one normalization and one rounding step.  A certain amount of
| black magic and handwaving are involved, but please note that at no time
| do any bits leave the confines of the computer.
|
| Round-to-even is used for the ambiguous rounding case.
|
| These  routines clobber the registers d0-d2/a0-a1. Check if this is
| compatible with your compiler|
| In the MINIX distribution, C68 fulfills this requirement. The CP/M-68K
| version of C68 even considers d0-d2/a0-a2 as scratch registers, so this
| works also.
| You will have difficulties with compiles that use less scratch registers,
| i.e. that expect one of d0-d2/a0-a1 to be unchanged across function
| calls.
| float _sfdiv(num, denom)

	.text
|
	.globl	__sfdiv
	.globl	.fpdiv
__sfdiv:
.fpdiv:
	movl	d3,a1			| We don't need no wimpy stack frame
	movl	#0,d0
	movl	sp@(4),d1
	beq	exit			| Numerator 0 - all done
	movl	sp@(8),d2
	beq	div0			| Divide by 0 - overflow
	clrb	d1			| Work with mantissas
	clrb	d2
	movl	#0x2000000,d3		| Position of msb of 26-bit field
cmpbit:
	cmpl	d2,d1			| Compare against new divisor
	bcs	nobit
	addl	d3,d0			| Add in this bit
	subl	d2,d1			| and adjust
nobit:
	lsrl	#1,d2
	lsrl	#1,d3
	bne	cmpbit			| Done 26 bits?

	lsll	#6,d0			| Reposition
	tstl	d1			| If there was a remainder...
	beq	doexp
	addl	#2,d0			| record a memory of it.  The 2 bit
					| .won't be lost by either of the
					| ..subsequent normalizations
doexp:
	movl	#0x7F,d1		| Calculate new exponent
	movl	d1,d2
	andb	sp@(7),d1
	andb	sp@(11),d2
	subw	d2,d1
	addw	#0x41,d1		| Adjust
	tstl	d0			| Check for already normalized or zero
	bmi	normok
normloop:
	subw	#1,d1			| Do one normalize step (there can't
	addl	d0,d0			| .be more)
normok:
	addl	#0x80,d0		| Round up in most cases
	bcc	round1
	roxrl	#1,d0			| The rounding caused overflow, sigh
	addw	#1,d1
round1:
	tstb	d0			| See if trailer was exactly 0x80
	bne	ckexp
	andw	#0xFE00,d0		| It was: round to even

ckexp:					| Check exponent for sanity
	tstw	d1
	ble	underflow
	cmpw	#0x7F,d1
	bgt	overflow
setexp:
	movb	d1,d0			| Set exponent

	movb	sp@(7),d1		| Get signs
	movb	sp@(11),d2
	eorb	d2,d1			| Form new sign
	andb	#0x80,d1		| Extract it
	orb	d1,d0
exit:
	movl	a1,d3
	rts
div0:
overflow:
	movl	#0xFFFFFFFF,d0
	movl	#0x7F,d1
	bra	setexp

underflow:
	movl	#0,d0
	bra	exit
|
	.globl	.asfpdiv
.asfpdiv:
	link	a6,#0
	movl	a6@(12),sp@-
	movl	a6@(8),a0
	movl	a0@,sp@-
	jsr	.fpdiv
	movl	a6@(8),a0
	movl	d0,a0@
	unlk	a6
	rts
