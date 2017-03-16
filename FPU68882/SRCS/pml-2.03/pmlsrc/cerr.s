#APP

| mjr: complex error checking code
|    inputs:
|	a1:	pointer to double
|	a7@(4):	pointer to funcname

.text
.even

.globl c_err_check
.even

c_err_check:
	movew	a1@,d1		| get z.real
	cmpiw	#0x7fff,d1	| == NaN ?
	beq	error_nan	|
	cmpiw	#0x7ff0,d1	| == + Infinity ?
	beq	error_plus	|
	cmpiw	#0xfff0,d1	| == - Infinity ?
	beq	error_minus	|
continue:
	movew	a1@(8),d1	| get z.imag
	cmpiw	#0x7fff,d1	| == NaN ?
	beq	error_nan_i	|
	cmpiw	#0x7ff0,d1	| == + Infinity ?
	beq	error_plus_i	|
	cmpiw	#0xfff0,d1	| == - Infinity ?
	beq	error_minus_i	|

	addqw	#4,a7		| drop _funcname
	rts

error_minus:
	moveml	d0/a1,a7@-
	movel	#63,_errno	| errno = ERANGE
	pea	Overflow	| for printf
	bra	error_exit	|
error_plus:
	moveml	d0/a1,a7@-
	movel	#63,_errno	| NAN => errno = EDOM
	pea	Overflow	| for printf
	bra	error_exit	|
error_nan:
	moveml	d0/a1,a7@-
	lea	__infinitydf,a0
	movel	a0@,a1@		| result = + Infinity (for now)
	movel	a0@(4),a1@(4)	| result = + Infinity (for now)
	movel	#62,_errno	| NAN => errno = EDOM
	pea	Domain		| for printf
error_exit:
	pea	__iob+52	|
	jbsr	_fprintf	|
	addqw	#8,a7		| leave _funcname on stack
	moveml	a7@+,d0/a1
	bra	continue

error_minus_i:
	moveml	d0/a1,a7@-
	movel	#63,_errno	| errno = ERANGE
	pea	Overflow	| for printf
	bra	error_exit_i	|
error_plus_i:
	moveml	d0/a1,a7@-
	movel	#63,_errno	| NAN => errno = EDOM
	pea	Overflow	| for printf
	bra	error_exit_i	|
error_nan_i:
	moveml	d0/a1,a7@-
	lea	__infinitydf,a0
	movel	a0@,a1@(8)	| result = + Infinity (for now)
	movel	a0@(4),a1@(12)	| result = + Infinity (for now)
	movel	#62,_errno	| NAN => errno = EDOM
	pea	Domain		| for printf
error_exit_i:
	pea	__iob+52	|
	jbsr	_fprintf	|
	addw	#12,a7		|
	moveml	a7@+,d0/a1

	rts
.data
.even
|double_max:
|	.long	0x7fee42d1
|	.long	0x30273b76
|double_min:
|	.long	0xffee42d1
|	.long	0x30273b76
|NaN:
|	.long	0x7fffffff
|	.long	0xffffffff
|p_Inf:
|	.long	0x7ff00000
|	.long	0x00000000
|m_Inf:
|	.long	0xfff00000
|	.long	0x00000000
Overflow:
	.ascii	": Overflow\n\0"
	.even
Domain:
	.ascii	": Domain error\n\0"
	.even
