!
! multiplication of unsigned long quantities
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
! Export: .ulmul, .asulmul
!
	.sect	.text
	.define .ulmul
.ulmul:
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
	rts
!
	.define	.asulmul
!
.asulmul:
	move.l	(a7)+,a0	! return address
	move.l	(a7)+,a1	! pointer to result
	move.l	(a1),-(a7)
	jsr	.ulmul		! a0/a1 not clobbered
	move.l	d0,(a1)
	jmp	(a0)		! return
!
