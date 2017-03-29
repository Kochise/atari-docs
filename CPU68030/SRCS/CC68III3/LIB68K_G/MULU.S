|
| multiplication of unsigned long quantities
|
| a=2^16*a1+a2
| b=2^16*b1+b2
|
| a*b=2^16*(a1*b2+a2*b1)+a2*b2 (jedenfalls modulo 2^32)
|
|
| Export: .ulmul, .asulmul
|
	.text

	.globl .ulmul

.ulmul:
	movw	sp@(4), d1
	mulu	sp@(10), d1
	movw	sp@(6), d0
	mulu	sp@(8), d0
	addl	d0, d1
	swap	d1
	clrw	d1
	movw	sp@(6), d0
	mulu	sp@(10), d0
	addl	d1, d0
	rts
|
.globl	.asulmul
|
.asulmul:
	movl	sp@+, a0	| return address
	movl	sp@+, a1	| pointer to result
	movl	a1@, sp@-
	jsr	.ulmul		| a0/a1 not clobbered
	movl	d0, a1@
	jmp	a0@		| return
|
