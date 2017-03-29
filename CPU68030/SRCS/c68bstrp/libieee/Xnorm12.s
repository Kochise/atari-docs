#
 ! C68 12-byte-floating point normalization routine
 !-----------------------------------------------------------------------------
 !	#1	First version.	Based on Xnorm8_s						-djw-  01/96
 !-----------------------------------------------------------------------------

	.sect .text

	.define .Xnorm12

!-----------------------------------------------
! on entry to norm8:
!	D0.W	exponent value of result
!	D2.w	sign byte in left most bit position
!			sticky bit in least significant byte
!	D1		rounding bits
!	A1		mantissa pointer (96 bits)
!-----------------------------------------------

.Xnorm12:
	clr.l	d1
	movem.l d3-d6,-(sp) 		! save some registers

	movem.l (a1),d4/d5/d6		! load current mantissa
	move.l	d4,d3				! rounding and u.mant == 0 ?
	or.l	d5,d3
	or.l	d6,d3
	bne 	1f
	tst.b	d1
	beq 	retz

!	We first see if we can do a fast left shift of 16 bits

1:
	move.l	d4,d3
	and.l	#0xffff0000,d3		! fast shift, 16 bits ?
	bne 	2f
	cmp.w	#9,d0				! shift is going to far; do normal shift
	ble 	2f					!  (minimize shifts here : 10l = 16l + 6r)
	swap	d4					! yes, swap register halfs
	swap	d5
	swap	d6
	move.w	d5,d4
	move.w	d6,d5
	move.b	d1,d6				! some doubt about this one !
	lsl.w	#8,d6
	clr.w	d1
	sub.w	#16,d0				! account for swap
	bra 	1b

!	We now get ready to move in smaller bits
2:
	clr.b	d2					! "sticky byte"
3:	tst.w	d0					! divide (shift)
	ble 	0f					!  denormalized number
4:	tst.l	d4					! top bit set?
	bmi 	8f					! Yes, go to complete processing

!	Now do smaller left shifts to finally get into position

	and.b	#1,d2
	or.b	d2,d1				! make least sig bit "sticky"

!	Shift left 1 bit at a time left to try and normalise

5:	tst.l	d4					! multiply (shift) until
	bmi 	6f					! one in top bit
	sub.w	#1,d0				! decrement exponent
	beq 	6f					!  too small. store as denormalized number
	add.b	d1,d1				! some doubt about this one *
	addx.l	d6,d6
	addx.l	d5,d5
	addx.l	d4,d4
	bra 	5b

!	Shift mantissa right 1 bit (denormalised numbers)

0:	add.w	#1,d0				! increment exponent
	lsr.l	#1,d4
	roxr.l	#1,d5
	roxr.l	#1,d6
	or.b	d1,d2				! set "sticky"
	roxr.b	#1,d1				! shift into rounding bits
	bra 	4b

!	Exponent reached zero - so set up denomalised number

6:
	tst.b	d1					! check rounding bits
	bge 	8f					! round down - no action neccessary
	neg.b	d1
	bvc 	7f					! round up
	btst	#0,d5				! tie case - use state of last bit
	beq 	8f					! .. no rounding needed

!	Round up - this may mean we need to retry normalisation

7:
	clr.l	d1					! zero rounding bits
	add.l	#1,d6
	addx.l	d1,d5
	addx.l	d1,d4
	tst.w	d0
	bne 	0f					! renormalize if number was denormalized
	add.w	#1,d0				! correct exponent for denormalized numbers
	bra 	2b

!	Exponent zero - but has rounding overlflow happened ?

0:	tst.l	d4					! check for rounding overflow
	bmi 	2b					! go back and renormalize

!	Finished normalisation loops
!	finally check for overflow/underlow conditions
8:
	move.l	d4,d3				! check if normalization caused an underflow
	or.l	d5,d3
	beq 	retz
	cmp.w	#0,d0				! check for exponent overflow or underflow
	blt 	retz
	cmp.w	#32767,d0
	bge 	oflow

!	Now set up the final value

	and.w	#0x8000,d2			! sign bit isolated
	or.w	d2,d0				! add to exponent
	swap	d0					! map to upper word
	clr.w	d0					! clear bottom 16 bits (reserved)
	movem.l d0/d4-d5,(a1)
finish:
	movem.l (sp)+,d3-d6 		! restore saved registers
	movem.l (a1),d0/d1/d2		! store result in d0/d1/d2
	rts

retz:
	clr.l	(a1)+
	clr.l	(a1)+
	clr.l	(a1)
	bra 	finish

oflow:
	jsr 	.overflow			! call overflow exception routine
	movem.l d0-d1,(a1)			! set reurn value
	bra 	finish				! ... and exit
