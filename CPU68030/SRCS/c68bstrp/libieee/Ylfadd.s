#
 !	C68 12 byte floating point add/subtract routines.
 !-----------------------------------------------------------------------------
 !	#1	First version.	Based on Ydfadd_s		Dave Walker 			01/96
 !-----------------------------------------------------------------------------

	.define .Ylfadd
	.define .Ylfsub
	.define .Yaslfadd
	.define .Yaslfsub

SAVEREG = 6*4		! Size of saved registers on stack

	.sect .text
!----------------------------------------
!	sp	Return address
!	sp+4	value of v
!	sp+16	value of u
!	result returnded in d0/d1/d2
!----------------------------------------

.Ylfadd:
	move.l	#0,d1				! set for add
	bra 1f
.Ylfsub:
	move.l	#1,d1				! sign bit
	ror.l	#1,d1				! set for subtract
1:
#ifdef HW_FPU
	eor.l	d1,16(sp)			! invert if needed sign of second operand
	jsr 	__FPcheck
	bne 	2f
!	FMOVE.X 4(sp),FP7			! move value to FP register
	dc.w	0xf22f,0x4b80,0x0004
!	FADD.X	16(sp),FP7			  ! ... YES do add
	dc.w	0xf22f,0x4ba2,0x0010
!	FMOVE.X FP7,-(sp)			! get result out of FP register
	dc.w	0xf227,0x6b80
	jsr 	__FPrelease
	movem.l (sp)+,d0/d1 		! move result into d0/d1
	bra 	addexit
2:
#endif /* HW_FPU */

	movem.l d2-d7,-(sp) 		! save registers
	movem.l SAVEREG+12(sp),d4-d5 ! load v
	lea 	SAVEREG+4(sp),a1	! re-use parameter space for result area
	movem.l (a1),d6-d7			! load u
	bsr 	shared				! go to do operation
	movem.l (sp)+,d2-d7 		! restore saved registers
addexit:
	move.l	(sp)+,a0			! get return address
	lea 	16(sp),sp			! remove parameters from stack (2 doubles)
	jmp 	(a0)				! ... and return


!----------------------------------------
!	sp	Return address
!	sp+4	address of result/v
!	sp+8	value of u
!	Result returned in d0/d1
!----------------------------------------

.Yasdfadd:
	move.l	#0,d1				! set for add
	bra 1f

.Yasdfsub:
	move.l	#1,d1				! sign bit
	ror.l	#1,d1				! set for subtract

1:
#ifdef HW_FPU
	eor.l	d1,8(sp)			! invert if needed sign of second operand
	jsr 	__FPcheck
	bne 	2f
	move.l	4(sp),a1			! get address for result/ numerator
!	FMOVE.X (a1),FP7
	dc.w	0xf211,0x4b80
!	FADD.X	8(sp),FP7
	dc.w	0xf22f,0x4ba2,0x0008
!	FMOVE.X FP7,(a1)			! store result
	dc.w	0xf211,0x6b80
	jsr 	__FPrelease
	movem.l (a1),d0/d1/d2		! put result into d0/d1
	bra 	asexit
2:
#endif /* HW_FPU */

	movem.l d2-d7,-(sp) 		! save registers
	movem.l SAVEREG+8(sp),d4-d5 ! load u
	move.l	SAVEREG+4(sp),a1	! address of v / result address
	movem.l (a1),d6-d7			! ... load v
	bsr 	shared				! go to do operation
	movem.l (sp)+,d2-d7 		! restore saved registers
asexit:
	move.l	(sp)+,a1			! get return address
	lea 	16(sp),sp			! remove parameters from stack (1 pointer, 1 long double)
	jmp 	(a1)				! ... and return


 !-------------------------------------------------------------------------
 ! This is the routine that actually carries out the operation.
 !
 ! Register usage:
 !
 !			Entry					Exit
 !
 !	d0		add/subtract mask		undefined
 !	d1		?						undefined
 !	d2		?						undefined
 !	d3		?						undefined
 !	d2-d4	v						undefined
 !	d5-d7	u						undefined
 !
 !	A1	Address for result		preserved
 !
 !-----------------------------------------------------------------------------

shared:
	eor.l	d1,d4		! reverse sign of v if needed (frees d1 for use)
	move.l	d6,d0		! d0 = u.exp
	swap	d0
	move.l	d6,d2		! d2.h = u.sign
	move.w	d0,d2
	lsr.w	#4,d0
	and.w	#0x07ff,d0	! kill sign bit

	move.l	d4,d1		! d1 = v.exp
	swap	d1
	eor.w	d1,d2		! d2.l = u.sign ^ v.sign
	lsr.w	#4,d1
	and.w	#0x07ff,d1	! kill sign bit

	and.l	#0x0fffff,d6	! remove exponent from u.mantissa
	tst.w	d0		! check for zero exponent - no leading "1"
	beq 0f
	or.l	#0x100000,d6	! restore implied leading "1"
	bra 1f
0:	add.w	#1,d0		! "normalize" exponent
1:
	and.l	#0x0fffff,d4	! remove exponent from v.mantissa
	tst.w	d1		! check for zero exponent - no leading "1"
	beq 0f
	or.l	#0x100000,d4	! restore implied leading "1"
	bra 1f
0:	add.w	#1,d1		! "normalize" exponent
1:
	clr.w	d3		! (put initial zero rounding bits in d3)
	neg.w	d1		! d1 = u.exp - v.exp
	add.w	d0,d1
	beq 5f		! exponents are equal - no shifting neccessary
	bgt 1f		! not equal but no exchange neccessary
	exg d4,d6		! exchange u and v
	exg d5,d7
	sub.w	d1,d0		! d0 = u.exp - (u.exp - v.exp) = v.exp
	neg.w	d1
	tst.w	d2		! d2.h = u.sign ^ (u.sign ^ v.sign) = v.sign
	bpl 1f
	bchg	#31,d2
1:
	cmp.w	#53,d1		! is u so much bigger that v is not
	bge 7f		! significant ?

	move.w	#10-1,d3	! shift u left up to 10 bits to minimize loss
2:
	add.l	d7,d7
	addx.l	d6,d6
	sub.w	#1,d0		! decrement exponent
	sub.w	#1,d1		! done shifting altogether ?
	dbeq	d3,2b		! loop if still can shift u.mant more
	clr.w	d3
3:
	cmp.w	#16,d1		! see if fast rotate possible
	blt 4f
	or.b	d5,d3		! set rounding bits
	or.b	d2,d3
	sne d2		! "sticky byte"
	move.w	d5,d3
	lsr.w	#8,d3
	move.w	d4,d5		! rotate by swapping register halfs
	swap	d5
	clr.w	d4
	swap	d4
	sub.w	#16,d1
	bra 3b
0:
	lsr.l	#1,d4		! shift v.mant right the rest of the way
	roxr.l	#1,d5		! to line it up with u.mant
	or.b	d3,d2		! set "sticky byte" if necessary
	roxr.w	#1,d3		! shift into rounding bits
4:	dbra	d1,0b		! loop
	and.b	#1,d2		! see if "sticky bit" should be set
	or.b	d2,d3
5:
	tst.w	d2		! are the signs equal ?
	bpl 6f		! yes, no negate necessary

	neg.b	d3		! negate rounding bits and v.mant
	neg.l	d5
	negx.l	d4
6:
	add.l	d5,d7		! u.mant = u.mant + v.mant
	addx.l	d4,d6
	bcs 7f		! need not negate
	tst.w	d2		! opposite signs ?
	bpl 7f		! do not need to negate result

	neg.b	d3		! negate rounding bits and u.mant
	neg.l	d7
	negx.l	d6
	not.l	d2		! switch sign
7:
	movem.l d6-d7,(a1)			! move result on stack
	move.b	d3,d1				! put rounding bits in d1 for .norm8
	swap	d2					! put sign into d2
	jmp 	.Xnorm12			! exit via normalising routine
