#
 ! C68 8 byte floating point => 12 byte floating point conversion routine
 !-----------------------------------------------------------------------------
 !	#1	First version.	based on Ydftosf_s		Dave Walker 			01/96
 !-----------------------------------------------------------------------------

SAVEREG = 3*4			! size of saved registers on stack

BIAS4	=	0x7F - 1
BIAS8	=	0x3FF - 1
BIAS12	=	0x3FFF - 1

	.sect .text
	.define .Ydftolf

!----------------------------------------
!	sp		Return address
!	sp+4	value of argument
!----------------------------------------
.Ydftolf:
#ifdef HW_FPU
	jsr 	__FPcheck
	bne 	5f
!	FMOVE.D 4(sp),FP7			! argument value into FP register
	dc.w	0xf22f,0x5780,0x0004
!	FMOVE.X FP7,-(sp)			! get out of FP register onto stack
	dc.w	0xf227,0x6b80
	jsr 	__FPrelease 		! release FPU
	movem.l (sp)+,d0/d1/d2		! finally move result to return registers
	bra 	finish
5:
#endif /* HW_FPU */
	lea 	4(sp),a0			! value address
	lea 	-12(sp),sp			! work area for result
	move.l	sp,a1
	move.l	(a0),(a1)			! move across current value
	move.l	4(a0),4(a1) 		!
	clr.l	8(a1)				! clear unset bits

	move.w	(a1),d0 			! extract exponent
	move.w	d0,d2				! extract sign
	lsr.w	#4,d0
	and.w	#0x7ff,d0			! kill sign bit

	move.w	d2,d1
	and.w	#0x0f,d1			! remove exponent from mantissa
	tst.w	d0					! check for zero exponent - no leading "1"
	beq 0f						! for denormalized numbers
	or.w	#0x10,d1			! restore implied leading "1"
	bra 1f
0:	add.w	#1,d0				! "normalize" exponent
1:	move.w	d1,(a1) 			! store corrected matissa

	add.w	#BIAS12-BIAS8,d0	! adjust bias
	clr.w	d1					! clear rounding bits
	jsr 	.Xnorm12			! go to normalise result
	lea 	12(sp),sp			! remove work area from stack

finish:
	move.l	(sp)+,a1			! get return address
	add.l	#8,sp		! remove parameters from stack ( 1 x double)
	jmp (a1)			! ... and return
