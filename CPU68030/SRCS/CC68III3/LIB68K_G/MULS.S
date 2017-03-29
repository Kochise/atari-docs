|
| multiplication of signed long quantities
|
| a=2^16*a1+a2
| b=2^16*b1+b2
|
| a*b=2^16*(a1*b2+a2*b1)+a2*b2 (jedenfalls modulo 2^32)
|
|
| Export: .lmul, .aslmul
|
	.text

	.globl .lmul

.lmul:	clrw	d2
	tstl	sp@(4)
	bge	l1
	negl	sp@(4)
	notw	d2
l1:
	tstl	sp@(8)
	bge	l2
	negl	sp@(8)
	notw	d2
l2:				| ab hier wie unsigned
	movw	sp@(4),d1
	mulu	sp@(10),d1
	movw	sp@(6),d0
	mulu	sp@(8),d0
	addl	d0,d1
	swap	d1
	clrw	d1
	movw	sp@(6),d0
	mulu	sp@(10),d0
	addl	d1,d0
| Test, ob noch negiert werden muss
	tstw	d2
	beq	leave
	negl	d0
leave:
	rts


	.globl .aslmul

.aslmul:
	movl	sp@+,a0	| return address
	movl	sp@+,a1	| pointer to first operand
	movl	a1@,sp@-
	jsr	.lmul		| a0/a1 not destroyed
	movl	d0,a1@		| assign result
	jmp	a0@		| return
