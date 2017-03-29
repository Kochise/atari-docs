#
 ! C68 4 byte floating point => 8 byte floating point conversion routine
 !-----------------------------------------------------------------------------
 ! ported to 68000 by Kai-Uwe Bloem, 12/89
 !  #1  original author: Peter S. Housel 06/03/89
 !  #2	added support for denormalized numbers			-kub-, 01/90
 !  #3  Redid register usage, and then added wrapper routine
 !	to provide C68 IEEE compatibility	Dave & Keith Walker	02/92
 !  #4  Changed entry/exit code for C68 compatibility
 !	Removed ACK entry points				-djw-	09/93
 !  #5  Added support for hardware FPU support under QDOS       -djw-   12/95
 !-----------------------------------------------------------------------------

	.sect .text

	.define	.Xsftodf

BIAS4	=	0x7F - 1
BIAS8	=	0x3FF - 1

!----------------------------------------
!	sp	Return address
!	sp+4	address of result
!	sp+8	address of value
!----------------------------------------
.Xsftodf:
#ifdef HW_FPU
    jsr     __FPcheck
    bne     5f
    move.l  8(sp),a1            ! argument address
!   FMOVE.S (a1),FP7
    dc.l    0xf2114780
    move.l  4(sp),a1            ! result address
!   FMOVE.D FP7,(a1)
    dc.l    0xf2117780
    jsr     __FPrelease
    bra     finish
5:
#endif /* HW_FPU */
	move.l	4(sp),a1	! result address
	move.l	8(sp),a0	! value address
	move.l	(a0),(a1)	! move across value
	move.l  #0,4(a1)

	move.w	(a1),d0		! extract exponent
	move.w	d0,d2		! extract sign
	lsr.w	#7,d0
	and.w	#0xff,d0	! kill sign bit (exponent is 8 bits)

	move.w	d2,d1
	and.w	#0x7f,d1	! remove exponent from mantissa
	tst.w	d0		! check for zero exponent - no leading "1"
	beq	0f		! for denormalized numbers
	or.w	#0x80,d1	! restore implied leading "1"
	bra	1f
0:	add.w	#1,d0		! "normalize" exponent
1:	move.w	d1,(a1)

	add.w	#BIAS8-BIAS4-3,d0	! adjust bias, account for shift
	clr.w	d1		! dummy rounding info
	jsr	.Xnorm8
finish:
	move.l	(sp)+,a0	! get return address
	add.l	#8,sp		! remove parameters from stack
	jmp	(a0)		! ... and return

