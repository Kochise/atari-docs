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
| Modified for the ACK assembler by Christoph van Wuellen, but I
| did not add functionality.
| These routines handle the Motorola FastFloatingPoint format.
|
| These  routines clobber the registers d0-d2/a0-a1. Check if this is
| compatible with your compiler|
| In the MINIX distribution, C68 fulfills this requirement. The CP/M-68K
| version of C68 even considers d0-d2/a0-a2 as scratch registers, so this
| works also.
| You will have difficulties with compiles that use less scratch registers,
| i.e. that expect one of d0-d2/a0-a1 to be unchanged across function
| calls.
|
| c68-generated assembler file
|
	.text
|
	.globl	.fpltof
.fpltof:
	link	a6,#-10
	moveml	d3/d4,sp@-
	movl	a6@(8),d3
	bge	_1
	movw	#128,d4
	movl	d3,d0
	negl	d0
	movl	d0,d3
	bra	_2
_1:
	movq	#0,d4
_2:
	movl	d3,sp@-
	jsr	.fputof
	addl	#4,sp
	extl	d4
	orl	d4,d0
_3:
	moveml	a6@(-18),d3/d4
	unlk	a6
	rts
|
	.globl	.fputof
.fputof:
	link	a6,#-6
	moveml	d3/d4,sp@-
	movl	a6@(8),d4
	bne	_4
	movq	#0,d0
_6:
	moveml	sp@+,d3/d4
	unlk	a6
	rts
_4:
	movl	#96,d3
_7:
	tstl	d4
	ble	_8
	asll	#1,d4
	subw	#1,d3
	bra	_7
_8:
	movl	d4,d0
	andl	#-256,d0
	extl	d3
	orl	d3,d0
	bra	_6
|
	.globl	.fpftol
.fpftol:
	link	a6,#-8
	moveml	d3/d4,sp@-
	movl	a6@(8),d3
	movl	d3,d0
	andl	#128,d0
	beq	_9
	eorl	#128,d3
	movl	d3,sp@-
	jsr	.fpftou
	addl	#4,sp
	movl	d0,d4
	bge	_11
	movl	#-2147483648,d0
_13:
_10:
	moveml	a6@(-16),d3/d4
	unlk	a6
	rts
_11:
	movl	d4,d0
	negl	d0
	bra	_13
_9:
	movl	d3,sp@-
	jsr	.fpftou
	addl	#4,sp
	movl	d0,d4
	bge	_14
	movl	#2147483647,d0
	bra	_13
_14:
	movl	d4,d0
	bra	_13
|
	.globl	.fpftou
.fpftou:
	link	a6,#-6
	moveml	d3/d4,sp@-
	movl	a6@(8),d0
	andl	#-256,d0
	movl	d0,d3
	movl	a6@(8),d0
	andl	#127,d0
	movw	d0,d4
	cmpw	#64,d4
	blt	_18
	tstl	d3
	bne	_16
_18:
	movq	#0,d0
_19:
	moveml	sp@+,d3/d4
	unlk	a6
	rts
_16:
	cmpw	#96,d4
	ble	_20
	movl	#-1,d0
	bra	_19
_20:
	subw	#64,d4
	movl	#32,d0
	subw	d4,d0
	extl	d0
	lsrl	d0,d3
	movl	d3,d0
	bra	_19
