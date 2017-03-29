!
! quotient and remainder of signed long quantities
!
! Amendement History
! ~~~~~~~~~~~~~~~~~~
! #1  10 Dec 92	Changed .lrem so that answer always has the
! 		same sign as dividend (previously was always
! 		giving a positive result)	Dave Walker
! #2  11 Dec 92	Changed exit code to tidy up stack.	Dave Walker
!
	.sect	.text
	.sect	.rom
	.sect	.data
	.sect	.bss
!
! Export: .Xldiv, .Xlrem, .Xasldiv, .Xaslrem
!
	.sect	.text
	.define .Xlrem

!	Calculate remainder of dividing two longs

.Xlrem:
	move.l	d6,a0		! save d6
	move.l	d7,a1		! save d7
	move.l	#1,d2		! Rest gewuenscht: Flag <> 0
	bra     do_divs
!
	.define .Xldiv

!	Caclualate result of dividing two longs

.Xldiv:
	move.l	d6,a0		! save d6
	move.l	d7,a1		! save d7
	clr.l	d2		! Quotient gewuenscht: Flag =0

!	Code common to divide/remainder

do_divs:
	swap	d2		! swap falg to top of D2
	clr.w	d2		! Flag Vorzeichen Ergebnis
	clr.l	d0		! Quotient
	move.l	4(a7),d7	! Dividend
	bge	_1		! negative ? - YES, jump
	neg.l	d7		! NO - negate answer
	not.w	d2		! set D2
_1:
	move.l	8(a7),d6	! Divisor
	bne	_2		! Divisor <> 0
	divs	#0,d0		! EXCEPTION
	bra	leave
_2:
	bge	_3		! Divisor negative ? - YES jump
	neg.l	d6		! NO - negate divisor
	not.w	d2		! toggle sign bit
_3:
!
!  both Operandsn now have positive sign
!
	cmp.l	d7,d6
	bcs	_4		! Dividenr > Divisor
	beq	_5		! Dividenr = Divisor
!
!  Divident < Divisor: Quotient=0, Rest=Divisor
!
	bra	finish
!
!  Special case of values being equal
!
_5:
	move.l	#1,d0		! Quotient=1
	clr.l	d7		! Rest=0
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
	swap	d2
	tst.w	d2
	bne	_10
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
	tst.l	4(a7)		! Check sign of Dividenda
	bge	leave		! positive/zero merely exit
	neg.l	d0		! ... else negate answer
leave:
	move.l	a0,d6		! restore d6
	move.l	a1,d7		! restore d7
tidyup:
	move.l	(a7)+,a0	! get return address
	lea	8(a7),a7	! remove two long parameters
	jmp	(a0)		! return to calling code

	.define	.Xasldiv
.Xasldiv:
	link	a6,#0
	move.l	12(a6),-(a7)
	move.l	8(a6),a0
	move.l	(a0),-(a7)
	jsr	.Xldiv
	move.l	8(a6),a0
	move.l	d0,(a0)
	unlk	a6
	bra	tidyup			! exit tidying up stack

	.define	.Xaslrem
.Xaslrem:
	link	a6,#0
	move.l	12(a6),-(a7)
	move.l	8(a6),a0
	move.l	(a0),-(a7)
	jsr	.Xlrem
	move.l	8(a6),a0
	move.l	d0,(a0)
	unlk	a6
	bra	tidyup			! exit tidying up stack
	
