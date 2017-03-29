#
 !	c68 12 byte floating point negate routine
 !-----------------------------------------------------------------------------
 !	#1	First version - based on Ydfneg_s 8 byte version		-djw-	01/96
 !-----------------------------------------------------------------------------

	.sect .text

	.define .Ylfneg

!----------------------------------------
!	sp		Return address
!	sp+4	long double value to negate
!----------------------------------------

.Ylfneg:
	movem.l 4(sp),d0/d1/d2	! load value into d0/d1/d2
	tst.l	d0				! test first 4 bytes
	bne 	2f				! We must negate if non-zero
	tst.l	d1				! test middle 4 bytes
	bne 2f					! We must negate if non-zero
	tst.l	d2				! Test last 4 bytes
	beq 8f					! skip negate if also zero
2:	bchg	#31,d0			! flip sign bit

8:	move.l	(sp)+,a0		! get return address
	lea 	12(sp),sp		! tidy stack (1 x long double)
	jmp 	(a0)			! return
