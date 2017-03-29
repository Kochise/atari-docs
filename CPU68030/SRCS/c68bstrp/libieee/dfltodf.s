#
 ! C68 32 bit integer => 8 byte-floating point conversion routine
 !-----------------------------------------------------------------------------
 ! ported to 68000 by Kai-Uwe Bloem, 12/89
 !  #1  original author: Peter S. Housel 3/28/89
 !  #2  Redid register usage, and then added wrapper routine
 !	to provide C68 IEEE compatibility	Dave & Keith Walker	02/92
 !  #3	Redid entry/exit points for C68 v4.3 compatibility
 !	Removed ACK entry points				-djw-	09/93
 !  #4  Added support for hardware FPU support under QDOS       -djw-   12/95
 !-----------------------------------------------------------------------------

BIAS8	=	0x3FF - 1

	.sect .text

	.define	.Xdfltodf

!----------------------------------------
!	sp	Return address
!	sp+4	address of result
!	sp+8	value to convert
!----------------------------------------
.Xdfltodf:
#ifdef HW_FPU
    jsr     __FPcheck
    bne     5f
!   FMOVE.L 8(sp),FP7
    dc.w    0xf22f,0x4380,0x0008
    move.l  4(sp),a1            ! result address
!   FMOVE.D FP7,(a1)
    dc.w    0xf211,0x7780
    jsr     __FPrelease
    bra     finish
5:
#endif /* HW_FPU */
	move.l	4(sp),a1	! return value address
	lea	8(sp),a0	! source address

	move.l	(a0),d1		! get the 4-byte integer
	move.w	#BIAS8+32-11,d0	! radix point after 32 bits
	move.w	(a0),d2		! check sign of number
	bge	1f		! nonnegative
	neg.l	d1		! take absolute value
1:
	clr.l	4(a1)		! write mantissa onto stack
	move.l	d1,(a1)
	clr.w	d1		! set rounding = 0
	jsr	.Xnorm8
finish:
	move.l	(sp)+,a1	! get return address
	add.l	#8,sp		! remove parameters from stack
	jmp	(a1)		! ... and return

