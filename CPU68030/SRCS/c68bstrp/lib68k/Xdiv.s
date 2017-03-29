!
! c68 Support routine
! ~~~~~~~~~~~~~~~~~~~
! quotient and remainder of long quantities
!
! Amendement History
! ~~~~~~~~~~~~~~~~~~
! #1  10 Dec 92	Changed .lrem so that answer always has the
! 		same sign as dividend (previously was always
! 		giving a positive result)		Dave Walker
! #2  11 Dec 92	Changed exit code to tidy up stack.	Dave Walker
! #3  18 Jul 94 Commoned up code for signed and unsigned
!		variants.  This also fixed a bug on the signed
!		divide for a value of -2^32		Dave Walker
!
	.sect	.text
	.sect	.rom
	.sect	.data
	.sect	.bss
!
! Export: .Xldiv,  .Xlrem,  .Xasldiv,  .Xaslrem
! 	  .Xuldiv, .Xulrem, .Xasuldiv, .Xasulrem
!
	.sect	.text

!	Calculate remainder/result of dividing two longs

	.define .Xlrem
.Xlrem:
	move.l	#1,d2		! Rest gewuenscht: Flag <> 0
	bra     do_divs
!
	.define .Xldiv
.Xldiv:
	move.l	#0,d2		! Quotient gewuenscht: Flag =0

!	Code common to divide/remainder of signed quantities

do_divs:
	move.l	d6,a0		! save data registers that are corrupted
	move.l	d7,a1		! ... in unused address registers
	swap	d2		! swap flag to top of D2
	clr.w	d2		! Flag Vorzeichen Ergebnis
	move.l	#0,d0		! Quotient preset to zero
	move.l	4(a7),d7	! Dividend
	bge	_1		! positive ? - YES, jump
	neg.l	d7		! NO - negate dividend
	not.w	d2		! invert D2 flag
_1:
	move.l	8(a7),d6	! Divisor
	bne	_2		! Divisor <> 0
zerodiv:
	divs	#0,d0		! EXCEPTION
	bra	leave
_2:
	bge	_3		! Divisor positive ? - YES jump
	neg.l	d6		! NO - negate divisor
	not.w	d2		! toggle sign bit
_3:
!
!  both Operands now have positive sign
!
	bsr	shared		! call shared code to do calculation
	swap	d2		! get flag to indicate result type
	tst.w	d2		! remainder wanted?
	bne	_10		! ... yes, go and handle it then
!
! Quotient erwuenscht
!
	swap	d2
	tst.w	d2		! Quotient negieren? (Rest immer positiv)
	beq	leave
	neg.l	d0
	bra	leave		! and then exit
!
_10:
!
! Rest erwuenscht
!	N.B.	Answer must have same sign as dividend as we use
!		a round towards zero strategy for division
!
	move.l	d7,d0
	tst.l	4(a7)		! Check sign of Dividend
	bge	leave		! positive/zero merely exit
	neg.l	d0		! ... else negate answer

!
!	Code copmmon to all exit paths
!
leave:
	move.l	a0,d6		! restore d6
	move.l	a1,d7		! restore d7
tidyup:
	move.l	(a7)+,a0	! get return address
	lea	8(a7),a7	! remove two long parameters
	jmp	(a0)		! return to calling code

!
!	Calculate remainder/result of dividing two unsigned longs
!
	.define .Xulrem
.Xulrem:
	move.l	#1,d2		! Rest gewuenscht: Flag <> 0
	bra     do_divu

	.define .Xuldiv
.Xuldiv:
	move.l	#0,d2		! Quotient gewuenscht: Flag =0
!
!	Code common to unsigned dive/remainder
!
do_divu:
	move.l	d6,a0		! save data registers that are corrupted
	move.l	d7,a1		! ... in unused address registers
	move.l	#0,d0		! Quotient set to 0
	move.l	4(a7),d7	! Dividend
	move.l	8(a7),d6	! Divisor
	beq	zerodiv		! Divisor == 0
	bsr	shared		! call code common to all variants
	tst.w	d2		! Remainder wanted?
	beq	leave		! No, then leave immediately
	move.l	d7,d0		! move Remainder to result register
	bra	leave		! ... and now leave

!
!	Shared code for signed/unsigned modes
!
shared:
	cmp.l	d7,d6
	bcs	_4		! Dividend > Divisor
	beq	_5		! Dividend = Divisor
!
!  Dividend < Divisor: Quotient=0, Rest=Divisor
!
	bra	finish
!
!  Special case of values being equal
!
_5:
	move.l	#1,d0		! Quotient=1
	move.l	#0,d7		! Rest=0
	bra	finish
!
_4:
	cmp.l   #0x10000,d7
	bcc	_6		! Divident>65536
!
! divu muss gelingen
!
	divu	d6,d7
	move.w	d7,d0
	clr.w	d7
	swap	d7
	bra	finish
!
! Jetzt muss es doch brutal gemacht werden
!
_6:
	move.l	#1,d1
_7:
	cmp.l	d6,d7
	bcs	_8
	tst.l	d6           ! value is greateer than 2^31 (only happens in unsigned cases)
	bmi	_8             ! ... YES, we better exit the loop then
!
! kein Check, ob das Bit schon draussen ist (wie bei udiv), da die
! Operanden kleiner als 2^31 sind
!
	asl.l	#1,d6
	asl.l	#1,d1
	bra	_7
!
_8:
	tst.l	d1
	beq	finish
	cmp.l	d6,d7
	bcs	_9
	or.l	d1,d0
	sub.l	d6,d7
_9:
	lsr.l	#1,d1
	lsr.l	#1,d6
	bra	_8
!
finish:
!
! Quotient in d0, Rest in d7
!
	rts

!
!	The following routines are the assign versions of the routines
!
	.define	.Xasldiv
.Xasldiv:
	lea	.Xldiv(pc),a1
	bra	do_asl			! now join shared code

	.define	.Xaslrem
.Xaslrem:
	lea	.Xlrem(pc),a1
	bra	do_asl

	.define	.Xasuldiv
.Xasuldiv:
	lea	.Xuldiv(pc),a1
	bra	do_asl

	.define	.Xasulrem
.Xasulrem:
	lea	.Xulrem(pc),a1

!	Code common to all the assign variants

do_asl:
	move.l	4+4+0(a7),-(a7)		! copy across original second parameter
	move.l	0+4+4(a7),a0		! get original first parameter
	move.l	(a0),-(a7)		! ... and store its target as new param
	jsr	(a1)			! go and execute required routine
	move.l	0+4+0(a7),a0		! get original first param
	move.l	d0,(a0)			! ... and store result at its target
	bra	tidyup			! exit tidying up stack
	
