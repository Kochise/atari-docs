#
 !	C68 4 byte floating point negate routine
 !-----------------------------------------------------------------------------
 ! ported to 68000 by Kai-Uwe Bloem, 12/89
 !	#1	original author: Peter S. Housel
 !	#2	Added routine to provide C68 IEEE compatibility
 !													Dave & Keith Walker 02/92
 !	#3	Changed entry/exit code for C68 v4.3 compatibility
 !		Removed ACK entry points								-djw-	09/93
 !	#4	Changed for new parameter format						-djw-	01/96
 !		and to return result in d0
 !-----------------------------------------------------------------------------

	.sect .text
	.define .Ysfneg

!----------------------------------------
!	sp	Return address
!	sp+4	value to negate
!----------------------------------------

.Ysfneg:				! floating point negate
	move.l	4(sp),d0	! Move to register
	beq 	8f			! skip negate if zero
	bchg	#31,d0		! flip sign bit

8:	move.l	(sp)+,a0	! get return address
	add.l	#4,sp		! tidy stack ( 1 x float)
	jmp 	(a0)		! return
