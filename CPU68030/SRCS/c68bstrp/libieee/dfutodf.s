#
 ! C68 32 bit unsigned => 8-byte-floating point conversion routine
 !-----------------------------------------------------------------------------
 ! ported to 68000 by Kai-Uwe Bloem, 12/89
 !	#1	original author: Peter S. Housel 3/28/89
 !	#2	Redid register usage, and then added wrapper routine
 !	to provide C68 IEEE compatibility	Dave & Keith Walker 02/92
 !	#3	Changed entry/exit code for C68 v4.3 compatibility
 !	Removed ACK entry points				-djw-	09/93
 !-----------------------------------------------------------------------------

BIAS8	=	0x3FF - 1

	.sect .text
	.define .Xdfutodf

!----------------------------------------
!	sp	Return address
!	sp+4	address of result
!	sp+8	address of value to convert
!----------------------------------------
.Xdfutodf:
#ifdef HW_FPUX
	jsr 	__FPcheck
	bne 	2f
	move.l	8(sp),a1			! get address for numerator
!	FMOVE.D (a1),FP7			! move to FP register
	dc.l	0xf2115780
	FBGE	1f					! OK if not negative

	FADD.D	CONSTANT,FP7

1:	move.l	4(sp),a0			! get address for result
!	FMOVE.D FP7,(a0)			! store result

	jsr 	__FPrelease
	bra 	addexit
#endif /* HW_FPU */

2:	move.l	4(sp),a1			! return value address
	move.l	8(sp),d1			! source value

	move.w	#BIAS8+32-11,d0 	! radix point after 32 bits
	clr.w	d2					! sign is always positive
	clr.l	4(a1)				! write mantissa onto stack
	move.l	d1,(a1)
	clr.w	d1					! set rounding = 0
	jsr 	.Xnorm8

finish:
	move.l	(sp)+,a0			! get return address
	add.l	#8,sp				! tidy stack ( 2 x address )
	jmp 	(a0)				! ... and return
