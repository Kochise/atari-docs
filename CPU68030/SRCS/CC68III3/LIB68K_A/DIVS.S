!
! quotient and remainder of signed long quantities
!
!
	.sect	.text
	.sect	.rom
	.sect	.data
	.sect	.bss
!
! Export: .ldiv, .lrem, .asldiv, .aslrem
!
	.sect	.text
	.define .lrem
.lrem:
	move.l	d6,a0
	move.l	d7,a1
	move.l	#1,d2		! Rest gewuenscht: Flag <> 0
	bra     do_divs
!
	.define .ldiv
.ldiv:
	move.l	d6,a0
	move.l	d7,a1
	clr.l	d2		! Quotient gewuenscht: Flag =0
!
do_divs:
	swap	d2
	clr.w	d2		! Flag Vorzeichen Ergebnis
	clr.l	d0		! Quotient
	move.l	4(a7),d7	! Divident
	bge	_1
	neg.l	d7
	not.w	d2
_1:
	move.l	8(a7),d6	! Divisor
	bne	_2		! Divisor <> 0
	divs	#0,d0		! EXCEPTION
	bra	leave
_2:
	bge	_3
	neg.l	d6
	not.w	d2
_3:
!
!  beide Operanden sind nun positiv
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
leave:
	move.l	a0,d6
	move.l	a1,d7
	rts
!
_10:
!
! Rest erwuenscht
!
	move.l	d7,d0
	bra	leave
	.define	.asldiv
.asldiv:
	link	a6,#0
	move.l	12(a6),-(a7)
	move.l	8(a6),a0
	move.l	(a0),-(a7)
	jsr	.ldiv
	move.l	8(a6),a0
	move.l	d0,(a0)
	unlk	a6
	rts
	.define	.aslrem
.aslrem:
	link	a6,#0
	move.l	12(a6),-(a7)
	move.l	8(a6),a0
	move.l	(a0),-(a7)
	jsr	.lrem
	move.l	8(a6),a0
	move.l	d0,(a0)
	unlk	a6
	rts
