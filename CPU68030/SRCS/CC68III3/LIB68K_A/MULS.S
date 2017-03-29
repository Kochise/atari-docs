!
! multiplication of signed long quantities
!
! a=2^16*a1+a2
! b=2^16*b1+b2
!
! a*b=2^16*(a1*b2+a2*b1)+a2*b2 (jedenfalls modulo 2^32)
!
	.sect	.text
	.sect	.rom
	.sect	.data
	.sect	.bss
!
! Export: .lmul, .aslmul
!
	.sect	.text
	.define .lmul
.lmul:
	clr.w	d2
	tst.l	4(a7)
	bge	_1
	neg.l	4(a7)
	not.w	d2
_1:
	tst.l	8(a7)
	bge	_2
	neg.l	8(a7)
	not.w	d2
_2:
!
! ab hier wie unsigned
!
	move.w	 4(a7),d1
	mulu	10(a7),d1
	move.w	 6(a7),d0
	mulu	 8(a7),d0
	add.l	d0,d1
	swap	d1
	clr.w	d1
	move.w	 6(a7),d0
	mulu	10(a7),d0
	add.l	d1,d0
! Test, ob noch negiert werden muss
	tst.w	d2
	beq	leave
	neg.l	d0
leave:
	rts
!
	.define .aslmul
!
.aslmul:
!
	move.l	(a7)+,a0	! return address
	move.l	(a7)+,a1	! pointer to first operand
	move.l	(a1),-(a7)
	jsr	.lmul		! a0/a1 not destroyed
	move.l	d0,(a1)		! assign result
	jmp	(a0)		! return
!
