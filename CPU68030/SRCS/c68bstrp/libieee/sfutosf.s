#
 ! C68 32 bit unsigned => 4-byte-floating point conversion routine
 !-----------------------------------------------------------------------------
 ! ported to 68000 by Kai-Uwe Bloem, 12/89
 !  #1  original author: Peter S. Housel 3/28/89
 !  #2  Redid register usage, and then added wrapper routine
 !	to provide C68 IEEE compatibility	Dave & Keith Walker	02/92
 !  #3  Changed entry/exit code for C68 v4.3 compatibility
 !	Removed ACK entry point						09/93
 !-----------------------------------------------------------------------------

BIAS4	=	0x7F - 1

	.sect .text

	.define	.Xsfutosf

!----------------------------------------
!	sp	Return address
!	sp+4	address of result
!	sp+8	Value to convert
!----------------------------------------
.Xsfutosf:
	move.l	4(sp),a1	! address for result
	move.l	8(sp),d1	! value to convert

	move.w	#BIAS4+32-8,d0	! radix point after 32 bits
	clr.w	d2		! sign is always positive 
	move.l	d1,(a1)		! write mantissa onto stack
	clr.w	d1		! set rounding = 0
	jsr	.Xnorm4

	move.l	(sp)+,a0	! get return address
	add.l	#8,sp		! remove parameters from stack
	jmp	(a0)		! ... and return
