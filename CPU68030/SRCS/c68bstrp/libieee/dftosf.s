#
 ! C68 8 byte floating point => 4 byte floating point conversion routine
 !-----------------------------------------------------------------------------
 ! ported to 68000 by Kai-Uwe Bloem, 12/89
 !  #1  original author: Peter S. Housel 06/03/89
 !  #2	added support for denormalized numbers			-kub-, 01/90
 !  #3  Redid register usage, and then added wrapper routine
 !	to provide C68 IEEE compatibility	Dave & Keith Walker	02/92
 !  #4	Changed entry/exit code for C68 v4.3 compatibility
 !	Removed ACK entry points				-djw-	09/93
 !  #5  Added support for hardware FPU support under QDOS       -djw-   12/95
 !-----------------------------------------------------------------------------

SAVEREG = 3*4			! size of saved registers on stack

BIAS4	=	0x7F - 1
BIAS8	=	0x3FF - 1

	.sect .text
	.define .Xdftosf

!----------------------------------------
!	sp	Return address
!	sp+4	address of result
!	sp+8	address of argument
!----------------------------------------
.Xdftosf:
#ifdef HW_FPU
    jsr     __FPcheck
    bne     5f
    move.l  8(sp),a1            ! argument address
!   FMOVE.D (a1),FP7
    dc.l    0xf2115780
    move.l  4(sp),a1            ! result address
!   FMOVE.S FP7,(a1)
    dc.l    0xf2116780
    jsr     __FPrelease
    bra     exit
5:
#endif /* HW_FPU */
	movem.l	d2-d4,-(sp)		! save registers that will be corrupted
	move.l	SAVEREG+8(sp),a0	! argument address
	move.l	SAVEREG+4(sp),a1	! result address

	move.w	(a0),d0		! extract exponent
	move.w	d0,d2		! extract sign
	lsr.w	#4,d0
	and.w	#0x7ff,d0	! kill sign bit

	move.w	d2,d1
	and.w	#0x0f,d1	! remove exponent from mantissa
	tst.w	d0		! check for zero exponent - no leading "1"
	beq	0f		! for denormalized numbers
	or.w	#0x10,d1	! restore implied leading "1"
	bra	1f
0:	add.w	#1,d0		! "normalize" exponent
1:	move.w	d1,d3		! store exponent
	swap	d3		! ... in correct part of register
	move.w	2(a0),d3	! get next 2 bytes of original value
	move.l	4(a0),d4	! .. and the last 4 bytes

	add.w	#BIAS4-BIAS8,d0	! adjust bias

	add.l	d4,d4		! shift up to realign mantissa for floats
	addx.l	d3,d3
	add.l	d4,d4
	addx.l	d3,d3
	add.l	d4,d4
	addx.l	d3,d3
	move.l	d3,(a1)		! write result.mantissa

	move.l	d4,d1		! set rounding bits
	rol.l	#8,d1
	and.l	#0x00ffffff,d4	! check to see if sticky bit should be set
	beq	2f
	or.b	#1,d1		! set sticky bit
2:	jsr	.Xnorm4		! go to normalise result

	movem.l	(sp)+,d2-d4	! restore saved registers
exit:
	move.l	(sp)+,a1	! get return address
	add.l	#8,sp		! remove parameters from stack
	jmp	(a1)		! ... and return

