!
! quotient and remainder of unsigned long quantities
!
! Amendement History
! ~~~~~~~~~~~~~~~~~~
! #1  11 Dec 92	Changed exit code to tidy up stack.	Dave Walker
!
	.sect	.text
	.sect	.rom
	.sect	.data
	.sect	.bss
!
! Export: .Xulrem, .Xuldiv, .Xasulrem, .Xasuldiv
!
	.sect	.text
	.define .Xulrem
.Xulrem:
	move.l	d6,a0
	move.l	d7,a1
	move.l	#1,d2		! Rest gewuenscht: Flag <> 0
	bra     do_divu
!
	.define .Xuldiv
.Xuldiv:
	move.l	d6,a0
	move.l	d7,a1
	clr.w	d2		! Quotient gewuenscht: Flag =0
!
do_divu:
	clr.l	d0		! Quotient
	move.l	4(a7),d7	! Divident
	move.l	8(a7),d6	! Divisor
	bne	_2		! Divisor <> 0
	divs	#0,d0		! EXCEPTION
	bra	leave
_2:
!
	cmp.l	d7,d6
	bcs	_4		! Divident > Divisor
	beq	_5		! Divident = Divisor
!
!  Divident < Divisor: Quotient=0, Rest=Divisor
!
	bra	finish
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
        tst.l   d6
        bmi     _8
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
	tst.w	d2
	bne	_10
!
! Quotient erwuenscht
!
	bra	leave
!
_10:
!
! Rest erwuenscht
!
	move.l	d7,d0
leave:
	move.l	a0,d6
	move.l	a1,d7
tidyup:
	move.l	(a7)+,a0	! get return address
	lea	8(a7),a7	! remove two long parameters
	jmp	(a0)		! return to calling code

	.define .Xasuldiv
.Xasuldiv:
	link	a6,#0
	move.l	12(a6),-(a7)
	move.l	8(a6),a0
	move.l	(a0),-(a7)
	jsr	.Xuldiv
	move.l	8(a6),a0
	move.l	d0,(a0)
	unlk	a6
	bra	tidyup		! goto tidy stack and exit

	.define .Xasulrem
.Xasulrem:
	link	a6,#0
	move.l	12(a6),-(a7)
	move.l	8(a6),a0
	move.l	(a0),-(a7)
	jsr	.Xulrem
	move.l	8(a6),a0
	move.l	d0,(a0)
	unlk	a6
	bra	tidyup		! goto tidy stack and exit
