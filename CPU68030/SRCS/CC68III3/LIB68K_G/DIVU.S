|
| quotient and remainder of unsigned long quantities
|
|
| Export: .ulrem, .uldiv, .asulrem, .asuldiv
|
	.text

	.globl .ulrem

.ulrem:
	movl	d6,a0
	movl	d7,a1
	movq	#1,d2		| Rest gewuenscht: Flag <> 0
	bra     do_divu


	.globl .uldiv

.uldiv:
	movl	d6,a0
	movl	d7,a1
	clrw	d2		| Quotient gewuenscht: Flag =0
|
do_divu:
	movq	#0, d0		| Quotient
	movl	sp@(4),d7	| Divident
	movl	sp@(8),d6	| Divisor
	bne	L2		| Divisor <> 0
	divs	#0,d0		| EXCEPTION
	bra	leave
L2:
|
	cmpl	d7,d6
	bcs	L4		| Divident > Divisor
	beq	L5		| Divident = Divisor
|
|  Divident < Divisor: Quotient=0, Rest=Divisor
|
	bra	finish
L5:
	movq	#1,d0		| Quotient=1
	movq	#0, d7		| Rest=0
	bra	finish
|
L4:
	cmpl	#0x10000,d7
	bcc	L6		| Divident>65536
|
| divu muss gelingen
|
	divu	d6,d7
	movw	d7,d0
	clrw	d7
	swap	d7
	bra	finish
|
| Jetzt muss es doch brutal gemacht werden
|
L6:
	movq	#1,d1
L7:
	cmpl	d6,d7
	bcs	L8
        tstl	d6
        bmi     L8
|
	asll	#1,d6
	asll	#1,d1
	bra	L7
|
L8:
	tstl	d1
	beq	finish
	cmpl	d6,d7
	bcs	L9
	orl	d1,d0
	subl	d6,d7
L9:
	lsrl	#1,d1
	lsrl	#1,d6
	bra	L8
|
finish:
|
| Quotient in d0, Rest in d7
|
	tstw	d2
	bne	L10
|
| Quotient erwuenscht
|
leave:
	movl	a0,d6
	movl	a1,d7
	rts
|
L10:
|
| Rest erwuenscht
|
	movl	d7,d0
	bra	leave


	.globl .asuldiv

.asuldiv:
	link	a6,#0
	movl	a6@(12),sp@-
	movl	a6@(8),a0
	movl	a0@,sp@-
	jsr	.uldiv
	movl	a6@(8),a0
	movl	d0,a0@
	unlk	a6
	rts


	.globl .asulrem

.asulrem:
	link	a6,#0
	movl	a6@(12),sp@-
	movl	a6@(8),a0
	movl	a0@,sp@-
	jsr	.ulrem
	movl	a6@(8),a0
	movl	d0,a0@
	unlk	a6
	rts
