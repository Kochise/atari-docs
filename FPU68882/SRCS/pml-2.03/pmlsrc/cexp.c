/************************************************************************
 *									*
 *				N O T I C E				*
 *									*
 *			Copyright Abandoned, 1987, Fred Fish		*
 *									*
 *	This previously copyrighted work has been placed into the	*
 *	public domain by the author (Fred Fish) and may be freely used	*
 *	for any purpose, private or commercial.  I would appreciate	*
 *	it, as a courtesy, if this notice is left in all copies and	*
 *	derivative works.  Thank you, and enjoy...			*
 *									*
 *	The author makes no warranty of any kind with respect to this	*
 *	product and explicitly disclaims any implied warranties of	*
 *	merchantability or fitness for any particular purpose.		*
 *									*
 ************************************************************************
 */


/*
 *  FUNCTION
 *
 *	cexp   complex double precision exponential
 *
 *  KEY WORDS
 *
 *	cexp
 *	complex functions
 *	machine independent routines
 *	math libraries
 *
 *  DESCRIPTION
 *
 *	Computes double precision complex exponential of
 *	a double precision complex argument.
 *
 *  USAGE
 *
 *	COMPLEX cexp (z)
 *	COMPLEX z;
 *
 *  REFERENCES
 *
 *	Fortran 77 user's guide, Digital Equipment Corp. pp B-13
 *
 *  PROGRAMMER
 *
 *	Fred Fish
 *	Tempe, Az 85281
 *	(602) 966-8871
 *
 *  INTERNALS
 *
 *	Computes complex exponential of z = x + j y from:
 *
 *		1.	r_cexp = exp(x) * cos(y)
 *
 *		2.	i_cexp = exp(x) * sin(y)
 *
 *		3.	cexp(z) = r_cexp + j i_cexp
 *
 */

#if !defined (__M68881__) && !defined (sfp004)

#include <stdio.h>
#include <math.h>
#include "pml.h"


COMPLEX cexp (z)
COMPLEX z;
{
    COMPLEX result;
    double expx;

    expx = exp (z.real);
    result.real = expx * cos (z.imag);
    result.imag = expx * sin (z.imag);
    return (result);
}

#else	!defined (__M68881__) && !defined (sfp004)
#ifdef	ERROR_CHECK
__asm("
.text
.even
_funcname:
	.ascii \"cexp\\0\"
	.even
");
#endif	ERROR_CHECK
#endif	!defined (__M68881__) && !defined (sfp004)

#ifdef	__M68881__

__asm("
	.text 
	.even
	.globl _cexp
_cexp:
	fmovex	fp2,sp@-	| 12 Bytes
	movel	a1,d0		| save a1 as return value
	fetoxd	a7@(16),fp0	| exp( z.real )
	fmoved	a7@(24),fp2
	fcosx	fp2,fp1
	fsinx	fp2,fp2
	fmulx	fp0,fp1		|
	fmulx	fp0,fp2		|
	fmoved	fp1,a1@		| fetch result.real
	fmoved	fp2,a1@(8)	| fetch result.imag
	fmovex	sp@+,fp2
");	/* end asm	*/
#endif	__M68881__

#ifdef	sfp004
__asm("
| double precision floating point stuff for Atari-gcc using the SFP004
| developed with gas
|
| double precision complex exponential function
|
| M. Ritzert (mjr at dmzrzu71)
|
| 12.10.1990
|
| addresses of the 68881 data port. This choice is fastest when much data is
| transferred between the two processors.

comm =	 -6
resp =	-16
zahl =	  0

| waiting loop ...
|
| wait:
| ww:	cmpiw	#0x8900,a1@(resp)
| 	beq	ww
| is coded directly by
|	.long	0x0c688900, 0xfff067f8
| and
| www:	tst.b	a1@(resp)
|	bmi.b	www
| is coded by
|	.word	0x4a68,0xfff0,0x6bfa		| test

	.text; .even
	.globl _cexp
_cexp:
	movel	a1,d0				| save a1 as return value
	lea	0xfffa50,a0			| fpu address
	movew	#0x5410,a0@(comm)		| exp()
	cmpiw	#0x8900,a0@(resp)		| check
	movel	a7@(4),a0@			| load arg_hi
	movel	a7@(8),a0@			| load arg_low

|	movew	#%0101 0101 0011 0001,a0@(comm)	| sincos: sin -> fp2
	movew	#0x5531,a0@(comm)		| sincos: sin -> fp2
	.long	0x0c688900, 0xfff067f8
	movel	a7@(12),a0@			| load arg_hi
	movel	a7@(16),a0@			| load arg_low

|	movew	#%0000 0000 1010 0011,a0@(comm)	| mul fp0 -> fp1
	movew	#0x00a3,a0@(comm)		| mul fp0 -> fp1
	.word	0x4a68,0xfff0,0x6bfa		| test

|	movew	#%0000 0001 0010 0011,a0@(comm)	| mul fp0 -> fp2
	movew	#0x0123,a0@(comm)		| mul fp0 -> fp2
	.word	0x4a68,0xfff0,0x6bfa		| test

|	movew	#%0111 0100 1000 0000,a0@(comm)	| fetch fp1
	movew	#0x7480,a0@(comm)		|
	.long	0x0c688900, 0xfff067f8
	movel	a0@(zahl),a1@
	movel	a0@(zahl),a1@(4)

|	movew	#%0111 0101 0000 0000,a0@(comm)	| fetch fp2
	movew	#0x7500,a0@(comm)		| 
	.long	0x0c688900, 0xfff067f8
	movel	a0@(zahl),a1@(8)
	movel	a0@(zahl),a1@(12)
");	/* end asm	*/
#endif	sfp004


#if defined (__M68881__) || defined (sfp004)
# ifdef ERROR_CHECK	/* no error checking for now	*/
__asm("
	pea	_funcname
	jmp	c_err_check
");	/* end asm	*/
# else  ERROR_CHECK

__asm("rts");

# endif ERROR_CHECK
#endif defined (__M68881__) || defined (sfp004)
