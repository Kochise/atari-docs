 ! C68 32 bit unsigned => 8-byte-floating point conversion routine
 !-----------------------------------------------------------------------------
 ! ported to 68000 by Kai-Uwe Bloem, 12/89
 !	#1	original author: Peter S. Housel 3/28/89
 !	#2	Redid register usage, and then added wrapper routine
 !		to provide C68 IEEE compatibility			Dave & Keith Walker 02/92
 !	#3	Changed entry/exit code for C68 v4.3 compatibility
 !		Removed ACK entry points								-djw-	09/93
 !	#4	Changed for new parameter format						-djw-	01/96
 !		(and to return result in d0/d1)
 !-----------------------------------------------------------------------------

BIAS8	=	0x3FF - 1

	.sect	.text
	.define .Ydfutodf

!----------------------------------------
!	sp		Return address
!	sp+4	value to convert
!----------------------------------------
.Ydfutodf:
	move.l	4(sp),d1			! source value
	move.w	#BIAS8+32-11,d0 	! radix point after 32 bits
	clr.w	d2					! sign is always positive
	clr.l	-(sp)				! write mantissa onto stack  (reserving space)
	move.l	d1,-(sp)
	move.l	sp,a1				! set a1 to point to result area
	clr.w	d1					! set rounding = 0
	jsr 	.Xnorm8

	move.l	8(sp),a0			! get return address
	lea	16(sp),sp			! tidy stack (double + return + ulong)
	jmp 	(a0)				! ... and return
