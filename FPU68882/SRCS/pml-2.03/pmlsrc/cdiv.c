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
 *	cdiv   double precision complex division
 *
 *  KEY WORDS
 *
 *	cdiv
 *	complex functions
 *	machine independent routines
 *	math libraries
 *
 *  DESCRIPTION
 *
 *	Computes double precision complex result of division of
 *	first double precision complex argument by second double
 *	precision complex argument.
 *
 *  USAGE
 *
 *	COMPLEX cdiv (numerator, denominator)
 *	COMPLEX numerator;
 *	COMPLEX denominator;
 *
 *  PROGRAMMER
 *
 *	Fred Fish
 *	Tempe, Az 85281
 *	(602) 966-8871
 *
 *  INTERNALS
 *
 *	Computes cdiv(znum,zden) from:
 *
 *		1.	Let znum = a + j b
 *			Let zden = c + j d
 *
 *		2.	denom = c*c + d*d
 *
 *		3.	If denom is zero then log error,
 *			set r_cdiv = maximum floating value,
 *			i_cdiv = 0, and go to step 5.
 *
 *		4.	r_cdiv = (a*c + b*d) / denom
 *			i_cdiv = (c*b - a*d) / denom
 *
 *		5.	Then cdiv(znum,zden) = r_cdiv + j i_cdiv
 *
 */

#if !defined (__M68881__) && !defined (sfp004)

#include <stdio.h>
#include <math.h>
#include "pml.h"

COMPLEX cdiv (znum, zden)
COMPLEX znum;
COMPLEX zden;
{
    COMPLEX result;
    double denom;
    struct exception xcpt;

    result.real = ((znum.real*zden.real)+(znum.imag*zden.imag));
    result.imag = ((zden.real*znum.imag)-(znum.real*zden.imag));
    denom = (zden.real * zden.real) + (zden.imag * zden.imag);

    if (denom == 0.0) {
#ifdef	ERROR_CHECK
	xcpt.type = SING;
	xcpt.name = "cdiv";
	xcpt.arg1 = denom;
	if (!matherr (&xcpt)) {
	    fprintf (stderr, "%s:  ZERO_CMPLX_DENOMINATOR \n", xcpt.name);
	    xcpt.retval = 0.0;	/* useless in this context */
	    errno = ERANGE;	/* should be EDOM if real or imag == 0	*/
	}
	if( result.real >= 0.0)	result.real = HUGE_VAL;	
					/* still wrong, == 0 should yield NAN */
	else			result.real = -HUGE_VAL;	
	if( result.imag >= 0.0) result.imag = HUGE_VAL;
					/* still wrong, == 0 should yield NAN */
	else			result.imag = -HUGE_VAL;	
#else	ERROR_CHECK
	result.real /= denom;
	result.imag /= denom;
#endif	ERROR_CHECK
    } else {
	result.real /= denom;
	result.imag /= denom;
    }
    return (result);
}
#endif !defined (__M68881__) && !defined (sfp004)
#ifdef	__M68881__
__asm("
.text
.even
_funcname:
	.ascii	\"cdiv\\0\"
	.even

.globl	_cdiv
_cdiv:
	fmoved	sp@(4),fp0
	fmoved	sp@(12),fp1
	fmoved	sp@(20),fp2
	fmoved	sp@(28),fp3
	fmovex	fp0,fp4
	movel	a1,d0		| pointer to result

	fmovex	fp2,fp5
	fmulx	fp2,fp5
	fmovex	fp3,fp6
	fmulx	fp3,fp6
	faddx	fp6,fp5

	fmulx	fp2,fp4
	fmulx	fp3,fp0
	fmulx	fp1,fp2	
	fmulx	fp1,fp3
	faddx	fp3,fp4
	fdivx	fp5,fp4
	fsubx	fp0,fp2
	fdivx	fp5,fp2

	fmoved	fp4,a1@
	fmoved	fp2,a1@(8)
");	/* end asm	*/
#endif	__M68881__

#ifdef	sfp004
__asm("

comm =	 -6
resp =	-16
zahl =	  0

.even
.text
.even
_funcname:
	.ascii	\"cdiv\\0\"
	.even
.text
.even
.globl	_cdiv
_cdiv:

	lea	0xfffa50,a0

	movew	#0x5400,a0@(comm)	| z1.real -> fp0
	movel	a1,d0			| pointer to result
	.long	0x0c688900, 0xfff067f8
	movel	a7@(4),a0@		| load arg_hi
	movel	a7@(8),a0@		| load arg_low

	movew	#0x5480,a0@(comm)	| z1.imag -> fp1
	.long	0x0c688900, 0xfff067f8
	movel	a7@(12),a0@		| load arg_hi
	movel	a7@(16),a0@		| load arg_low

	movew	#0x5500,a0@(comm)	| z2.real -> fp2
	.long	0x0c688900, 0xfff067f8
	movel	a7@(20),a0@		| load arg_hi
	movel	a7@(24),a0@		| load arg_low

	movew	#0x5580,a0@(comm)	| z2.imag -> fp3
	.long	0x0c688900, 0xfff067f8
	movel	a7@(28),a0@		| load arg_hi
	movel	a7@(32),a0@		| load arg_low

	movew	#0x0200,a0@(comm)	| copy fp0 to fp4
	.word	0x4a68,0xfff0,0x6bfa	| test


|	fmovex	fp2,fp5
	movew	#0x0a80,a0@(comm)
	.word	0x4a68,0xfff0,0x6bfa	| test
|	fmulx	fp2,fp5
	movew	#0x0aa3,a0@(comm)
	.word	0x4a68,0xfff0,0x6bfa	| test
|	fmovex	fp3,fp6
	movew	#0x0f00,a0@(comm)
	.word	0x4a68,0xfff0,0x6bfa	| test
|	fmulx	fp3,fp6
	movew	#0x0f23,a0@(comm)
	.word	0x4a68,0xfff0,0x6bfa	| test
|	faddx	fp6,fp5
	movew	#0x1aa2,a0@(comm)
	.word	0x4a68,0xfff0,0x6bfa	| test

|	fmulx	fp2,fp4
	movew	#0x0a23,a0@(comm)
	.word	0x4a68,0xfff0,0x6bfa	| test
|	fmulx	fp3,fp0
	movew	#0x0c23,a0@(comm)
	.word	0x4a68,0xfff0,0x6bfa	| test
|	fmulx	fp1,fp2
	movew	#0x0523,a0@(comm)
	.word	0x4a68,0xfff0,0x6bfa	| test
|	fmulx	fp1,fp3
	movew	#0x05a3,a0@(comm)
	.word	0x4a68,0xfff0,0x6bfa	| test

|	faddx	fp3,fp4
	movew	#0x0e22,a0@(comm)
	.word	0x4a68,0xfff0,0x6bfa	| test
|	fdivx	fp5,fp4
	movew	#0x1620,a0@(comm)
	.word	0x4a68,0xfff0,0x6bfa	| test
|	fsubx	fp0,fp2
	movew	#0x0128,a0@(comm)
	.word	0x4a68,0xfff0,0x6bfa	| test
|	fdivx	fp5,fp2
	movew	#0x1520,a0@(comm)
	.word	0x4a68,0xfff0,0x6bfa	| test


|	fmoved	fp4,a1@
	movew	#0x7600,a0@(comm)		| 
	.long	0x0c688900, 0xfff067f8
	movel	a0@,a1@
	movel	a0@,a1@(4)

|	fmoved	fp2,a1@(8)
	movew	#0x7500,a0@(comm)		| 
	.long	0x0c688900, 0xfff067f8
	movel	a0@,a1@(8)
	movel	a0@,a1@(12)
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
