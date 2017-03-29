#
 !  c68 8 byte floating point negate routine
 !-----------------------------------------------------------------------------
 ! ported to 68000 by Kai-Uwe Bloem, 12/89
 !  #1  original author: Peter S. Housel
 !  #2  Added routine to provide C68 IEEE compatibility
 !						Dave & Keith Walker	02/92
 !  #3	Changed entry/exit code for C68 v4.3 compatibility
 !	Removed ACK entry points				-djw-	09/93
 !-----------------------------------------------------------------------------

	.sect .text

	.define .Xdfneg

!----------------------------------------
!	sp	Return address
!	sp+4	address of result
!	sp+8	address of value
!----------------------------------------

.Xdfneg:
	move.l	4(sp),a1	! Pointer to result
	move.l	8(sp),a0	! Pointer to value
	move.l	0(a0),0(a1)	! First half
	move.l	4(a0),4(a1)	! Second half
	bne	2f		! We must negate if non-zero
	tst.l	0(a0)		! Test for 0 in first part
	beq	8f		! skip negate if also zero
2:	eor.b	#0x80,0(a1)	! flip sign bit

8:	move.l	(sp)+,a0	! get return address
	add.l	#8,sp		! remove parameters
	jmp	(a0)		! return

