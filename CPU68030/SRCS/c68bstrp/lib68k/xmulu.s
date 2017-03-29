!
! multiplication of unsigned long quantities
!
! a=2^16*a1+a2
! b=2^16*b1+b2
!
! a*b=2^16*(a1*b2+a2*b1)+a2*b2 (jedenfalls modulo 2^32)
!
! Amendement History
! ~~~~~~~~~~~~~~~~~~
! #1  11 Dec 92	Changed exit code to tidy up stack.	Dave Walker
!
	.sect	.text
	.sect	.rom
	.sect	.data
	.sect	.bss
!
! Export: .Xulmul, .Xasulmul
!
	.sect	.text
	.define .Xulmul
.Xulmul:
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
tidyup:
	move.l	(a7)+,a0	! get return address
	lea	8(a7),a7	! remove two long parameters
	jmp	(a0)		! return to calling code
!
	.define	.Xasulmul
!
.Xasulmul:
	move.l	8(a7),a0	! second operand
	move.l	4(a7),a1	! pointer to first operand
	move.l	a0, -(a7)	! store copy of second operand
	move.l	(a1),-(a7)	! store value for first operand
	jsr	.Xlmul		! a1 not destroyed (but stack tidied)
	move.l	d0,(a1)		! assign result
	move.l	(a7)+,a0	! get return address
	lea	8(a7),a7	! remove two parameters from stack
	jmp	(a0)		! return
!
