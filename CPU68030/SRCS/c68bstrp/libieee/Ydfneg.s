#
 !	c68 8 byte floating point negate routine
 !-----------------------------------------------------------------------------
 ! ported to 68000 by Kai-Uwe Bloem, 12/89
 !	#1	original author: Peter S. Housel
 !	#2	Added routine to provide C68 IEEE compatibility
 !													Dave & Keith Walker 02/92
 !	#3	Changed entry/exit code for C68 v4.3 compatibility
 !		Removed ACK entry points								-djw-	09/93
 !	#4	Changed for new C68 parameter formats					-djw-	01/96
 !		(and to return result in d0/d1)
 !-----------------------------------------------------------------------------

	.sect .text

	.define .Ydfneg

!----------------------------------------
!	sp		Return address
!	sp+4	value to negate
!----------------------------------------

.Ydfneg:
	movem.l 4(sp),d0/d1 ! load value into d0/d1
	tst.l	d1			! test second half
	bne 2f				! We must negate if non-zero
	tst.l	d0			! Test for 0 in first part
	beq 8f				! skip negate if also zero
2:	bchg	#31,d0		! flip sign bit

8:	move.l	(sp)+,a0	! get return address
	add.l	#8,sp		! tidy stack (1 x double)
	jmp 	(a0)		! return
