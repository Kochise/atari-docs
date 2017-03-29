#
 !  C68 4 byte floating point negate routine
 !-----------------------------------------------------------------------------
 ! ported to 68000 by Kai-Uwe Bloem, 12/89
 !  #1  original author: Peter S. Housel
 !  #2  Added routine to provide C68 IEEE compatibility
 !						Dave & Keith Walker	02/92
 !  #3  Changed entry/exit code for C68 v4.3 compatibility
 !	Removed ACK entry points				-djw-	09/93
 !-----------------------------------------------------------------------------

	.sect .text
	.define .Xsfneg

!----------------------------------------
!	sp	Return address
!	sp+4	address of result
!	sp+8	address of value
!----------------------------------------

.Xsfneg:			! floating point negate
	move.l	4(sp),a1	! Pointer to result
	move.l	8(sp),a0	! Pointer to value
	move.l	0(a0),0(a1)	! Move across value
	beq	8f		! skip negate if also zero
	eor.b	#0x80,0(a1)	! flip sign bit

8:	move.l	(sp)+,a0	! get return address
	add.l	#8,sp		! remove parameters from stack
	jmp	(a0)		! return

