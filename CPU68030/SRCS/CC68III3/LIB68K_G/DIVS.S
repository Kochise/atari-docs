|
| quotient and remainder of signed long quantities
|
|
| Export: .ldiv, .lrem, .asldiv, .aslrem
|
	.text

	.globl .lrem

.lrem:	movl	d6, a0
	movl	d7, a1
	movq	#1, d2		| Rest gewuenscht: Flag <> 0
	bra	do_divs


	.globl .ldiv

.ldiv:	movl	d6, a0
	movl	d7, a1
	movq	#0, d2		| Quotient gewuenscht: Flag =0


do_divs:
	swap	d2
	clrw	d2		| Flag Vorzeichen Ergebnis
	movq	#0, d0		| Quotient
	movl	sp@(4), d7	| Divident
	bge	l1
	negl	d7
	notw	d2
l1:	movl	sp@(8), d6	| Divisor
	bne	l2		| Divisor <> 0
	divs	#0, d0		| EXCEPTION
	bra	leave

l2:	bge	l3
	negl	d6
	notw	d2
l3:
|
|  beide Operanden sind nun positiv
|
	cmpl	d7, d6
	bcs	l4		| Divident > Divisor
	beq	l5		| Divident = Divisor
|
|  Divident < Divisor: Quotient=0, Rest=Divisor
|
	bra	finish
l5:
	movq	#1, d0		| Quotient=1
	movq	#0, d7		| Rest=0
	bra	finish
|
l4:
	cmpl   #0x10000, d7
	bcc	l6		| Divident>65536
|
| divu muss gelingen
|
	divu	d6, d7
	movw	d7, d0
	clrw	d7
	swap	d7
	bra	finish
|
| Jetzt muss es doch brutal gemacht werden
|
l6:
	movl	#1, d1
l7:
	cmpl	d6, d7
	bcs	l8
|
| kein Check, ob das Bit schon draussen ist (wie bei udiv), da die
| Operanden kleiner als 2^31 sind
|
	asll	#1, d6
	asll	#1, d1
	bra	l7
|
l8:
	tstl	d1
	beq	finish
	cmpl	d6, d7
	bcs	l9
	orl	d1, d0
	subl	d6, d7
l9:	lsrl	#1, d1
	lsrl	#1, d6
	bra	l8
|
finish:
|
| Quotient in d0, Rest in d7
|
	swap	d2
	tstw	d2
	bne	l10
|
| Quotient erwuenscht
|
	swap	d2
	tstw	d2		| Quotient negieren? (Rest immer positiv)
	beq	leave
	negl	d0
leave:	movl	a0, d6
	movl	a1, d7
	rts
|
l10:
|
| Rest erwuenscht
|
	movl	d7, d0
	bra	leave


	.globl	.asldiv

.asldiv:
	link	a6, #0
	movl	a6@(12), sp@-
	movl	a6@(8), a0
	movl	a0@, sp@-
	jsr	.ldiv
	movl	a6@(8), a0
	movl	d0, a0@
	unlk	a6
	rts


	.globl	.aslrem

.aslrem:
	link	a6, #0
	movl	a6@(12), sp@-
	movl	a6@(8), a0
	movl	a0@, sp@-
	jsr	.lrem
	movl	a6@(8), a0
	movl	d0, a0@
	unlk	a6
	rts
