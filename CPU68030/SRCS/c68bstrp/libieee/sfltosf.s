#
 ! C68 32 bit integer => 4-byte-floating point conversion routine
 !-----------------------------------------------------------------------------
 ! ported to 68000 by Kai-Uwe Bloem, 12/89
 !  #1  original author: Peter S. Housel 3/28/89
 !  #2  Redid register usage, and then added wrapper routine
 !	to provide C68 IEEE compatibility	Dave & Keith Walker	02/92
 !  #3  Changed entry/exit code for C68 v4.3 compatibility
 !	Removed ACk entry points				-djw-	09/93
 !  #4  Added support for hardware FPU support under QDOS       -djw-   12/95
 !-----------------------------------------------------------------------------

BIAS4	=	0x7F - 1

	.sect .text
	.define	.Xsfltosf

!----------------------------------------
!	sp	Return address
!	sp+4	value to convert
!	sp+8	address of float/double
!----------------------------------------
.Xsfltosf:
#ifdef HW_FPU
    jsr     __FPcheck
    bne     5f
!   FMOVE.L 8(sp),FP7
    dc.w    0xf22f,0x4380,0x0008
    move.l  4(sp),a1            ! result address
!   FMOVE.S FP7,(a1)
    dc.w    0xf211,0x6780
    jsr     __FPrelease
    bra     finish
5:
#endif /* HW_FPU */
	move.l	4(sp),a1	! address for result
	lea	8(sp),a0	! address for source

	move.l	(a0),d1		! get the 4-byte integer
	move.w	#BIAS4+32-8,d0	! radix point after 32 bits
	move.w	(a0),d2		! check sign of number
	bge	1f		! nonnegative
	neg.l	d1		! take absolute value
1:
	move.l	d1,(a1)		! write mantissa onto stack
	clr.w	d1		! set rounding = 0
	jsr	.Xnorm4
finish:
	move.l	(sp)+,a0	! get return address
	add.l	#8,sp		! remove parameters from stack
	jmp	(a0)		! ... and return

