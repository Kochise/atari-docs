/************************************************************************
 *                                                                      *
 * A replacement exp() routine for PML library.  An original algorithm  *
 * is not changed but a table of fractionals power of 2 was recalcul-   *
 * ated (believe it or not - this has an influence on a final result).  *
 * Also divisions by power of 2 were replaced by applications of ldexp  *
 * routine which is faster and better preserves precision               *
 *                                                                      *
 * Michal Jaegermann, December 1990                                     *
 *                                                                      *
 ************************************************************************
 *                                                                      *
 * 68881 support added by Michael Ritzert				*
 *                                                                      *
 ************************************************************************
 */
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
 *	exp   double precision exponential
 *
 *  KEY WORDS
 *
 *	exp
 *	machine independent routines
 *	math libraries
 *
 *  DESCRIPTION
 *
 *	Returns double precision exponential of double precision
 *	floating point number.
 *
 *  USAGE
 *
 *	double exp (x)
 *	double x;
 *
 *  REFERENCES
 *
 *	Fortran IV plus user's guide, Digital Equipment Corp. pp B-3
 *
 *	Computer Approximations, J.F. Hart et al, John Wiley & Sons,
 *	1968, pp. 96-104.
 *
 *  RESTRICTIONS
 *
 *	Inputs greater than log(MAXDOUBLE) result in overflow.
 *	Inputs less than log(MINDOUBLE) result in underflow.
 *
 *	The maximum relative error for the approximating polynomial
 *	is 10**(-16.4).  However, this assumes exact arithmetic
 *	in the polynomial evaluation.  Additional rounding and
 *	truncation errors may occur as the argument is reduced
 *	to the range over which the polynomial approximation
 *	is valid, and as the polynomial is evaluated using
 *	finite precision arithmetic.
 *	
 *  PROGRAMMER
 *
 *	Fred Fish
 *
 *  INTERNALS
 *
 *	Computes exponential from:
 *
 *		exp(x)	=	2**y  *  2**z  *  2**w
 *
 *	Where:
 *
 *		y	=	int ( x * log2(e) )
 *
 *		v	=	16 * frac ( x * log2(e))
 *
 *		z	=	(1/16) * int (v)
 *
 *		w	=	(1/16) * frac (v)
 *
 *	Note that:
 *
 *		0 =< v < 16
 *
 *		z = {0, 1/16, 2/16, ...15/16}
 *
 *		0 =< w < 1/16
 *
 *	Then:
 *
 *		2**z is looked up in a table of 2**0, 2**1/16, ...
 *
 *		2**w is computed from an approximation:
 *
 *			2**w	=  (A + B) / (A - B)
 *
 *			A	=  C + (D * w * w)
 *
 *			B	=  w * (E + (F * w * w))
 *
 *			C	=  20.8137711965230361973
 *
 *			D	=  1.0
 *
 *			E	=  7.2135034108448192083
 *
 *			F	=  0.057761135831801928
 *
 *		Coefficients are from HART, table #1121, pg 206.
 *
 *		Effective multiplication by 2**y is done by a
 *		floating point scale with y as scale argument.
 *
 */

#if !defined (__M68881__) && !defined (sfp004)	/* mjr++		*/

#include <stdio.h>
#include <math.h>
#include "pml.h"

static char funcname[] = "exp";

# define C  20.8137711965230361973	/* Polynomial approx coeff.	*/
/* # define D  1.0	*/              /* Polynomial approx coeff.	*/
# define E  7.2135034108448192083	/* Polynomial approx coeff.	*/
# define F  0.057761135831801928	/* Polynomial approx coeff.	*/


/************************************************************************
 *									*
 *	This table is fixed in size and reasonably hardware		*
 *	independent.  The given constants were computed on Atari ST     *
 *      using integer arithmetic and decimal values for 2**(1/2),       *
 *      2**(1/4) and 2**(1/8) taken from Appendix C of HART et al.      *
 *									*
 ************************************************************************
 */

static double fpof2tbl[] = {
    1.0/*0000000000000000000*/,		/*	2 ** 0/16	*/
    1.04427378242741384032,		/*	2 ** 1/16	*/
    1.09050773266525765920,		/*	2 ** 2/16	*/
    1.13878863475669165369,		/*	2 ** 3/16	*/
    1.18920711500272106671,		/*	2 ** 4/16	*/
    1.24185781207348404858,		/*	2 ** 5/16	*/
    1.29683955465100966592,		/*	2 ** 6/16	*/
    1.35425554693689272828,		/*	2 ** 7/16	*/
    1.41421356237309504880,		/*	2 ** 8/16	*/
    1.47682614593949931138,		/*	2 ** 9/16	*/
    1.54221082540794082360,		/*	2 ** 10/16	*/
    1.61049033194925430816,		/*	2 ** 11/16	*/
    1.68179283050742908605,		/*	2 ** 12/16	*/
    1.75625216037329948310,		/*	2 ** 13/16	*/
    1.83400808640934246346,		/*	2 ** 14/16	*/
    1.91520656139714729384		/*	2 ** 15/16	*/
};

    char * xcptstr;
    struct exception xcpt;

double exp (x)
double x;
{
    register int index;
    int y;
    double w;
    double a;
    double b;
    double temp;

    if (x > LOGE_MAXDOUBLE) {
	xcpt.type = OVERFLOW;
	xcpt.retval = MAXDOUBLE;
	xcptstr = "OVER";
	goto eset;
    }
    if (x <= LOGE_MINDOUBLE) {
	xcpt.type = UNDERFLOW;
	xcpt.retval = 0.0;
	xcptstr = "UNDER";
eset:
	xcpt.name = funcname;
	xcpt.arg1 = x;
	if (!matherr (&xcpt)) {
            errno = ERANGE;
	    fprintf (stderr, "%s: %sFLOW error\n", funcname, xcptstr);
	}
    } else {
	x *= LOG2E;
	w = ldexp(modf(x,&a), 4);
	y = a;
	w = ldexp(modf(w, &temp), -4);
	index = temp;
	
	b = w * w;
	a = C + b;
	b = w * (E + (F * b));
	xcpt.retval = ldexp (((a + b) / (a - b)) *
	    (index < 0 ? ldexp(fpof2tbl[16 + index], -1) : fpof2tbl[index]), y);
    }
    return (xcpt.retval);
}
#endif	/* !__M68881__ && !sfp004	*/
#ifdef	sfp004

__asm("

comm =	 -6
resp =	-16
zahl =	  0

");	/* end asm	*/

#endif	sfp004
#if defined (__M68881__) || defined (sfp004)
    __asm(".text; .even");

# ifdef	ERROR_CHECK

    __asm("


_Overflow:
	.ascii \"OVERFLOW\\0\"
_Domain:
	.ascii \"DOMAIN\\0\"
_Error_String:
	.ascii \"exp: %s error\\n\\0\"
.even

| pml compatible expgent
| m.ritzert 7.12.1991
| ritzert@dfg.dbp.de
|
|    /* NAN  = {7fffffff,ffffffff}		*/
|    /* +Inf = {7ff00000,00000000}		*/
|    /* -Inf = {fff00000,00000000}		*/
|    /* MAX_D= {7fee42d1,30773b76}		*/
|    /* MIN_D= {ffee42d1,30773b76}		*/

.even
double_max:
	.long	0x7fee42d1
	.long	0x30273b76
double_min:
	.long	0xffee42d1
	.long	0x30273b76
NaN:
	.long	0x7fffffff
	.long	0xffffffff
p_Inf:
	.long	0x7ff00000
	.long	0x00000000
m_Inf:
	.long	0xfff00000
	.long	0x00000000
");
#endif	ERROR_CHECK

__asm("
.even
	.globl _exp
_exp:
");	/* end asm	*/

#endif	/* __M68881__ || sfp004	*/
#ifdef	__M68881__

    __asm("
	fetoxd	a7@(4), fp0	| exp
	fmoved	fp0,a7@-	| push result
	moveml	a7@+,d0-d1	| return_value
    ");	/* end asm	*/

#endif	__M68881__
#ifdef	sfp004
    __asm("
	lea	0xfffa50,a0
	movew	#0x5410,a0@(comm)	| specify function
	cmpiw	#0x8900,a0@(resp)	| check
	movel	a7@(4),a0@		| load arg_hi
	movel	a7@(8),a0@		| load arg_low
	movew	#0x7400,a0@(comm)	| result to d0
	.long	0x0c688900, 0xfff067f8	| wait
	movel	a0@,d0
	movel	a0@,d1
    ");	/* end asm	*/

#endif	sfp004
#if defined (__M68881__) || defined (sfp004)
# ifdef	ERROR_CHECK
    __asm("
	lea	double_max,a0	|
	swap	d0		| exponent into lower word
	cmpw	a0@(16),d0	| == NaN ?
	beq	error_nan	|
	cmpw	a0@(24),d0	| == + Infinity ?
	beq	error_plus	|
	swap	d0		| result ok,
	rts			| restore d0
");
#ifndef	__MSHORT__
__asm("
error_plus:
	swap	d0
	moveml	d0-d1,a7@-
	movel	#63,_errno	| NAN => errno = EDOM
	pea	_Overflow	| for printf
	bra	error_exit	|
error_nan:
	moveml	a0@(24),d0-d1	| result = +inf
	moveml	d0-d1,a7@-
	movel	#62,_errno	| NAN => errno = EDOM
	pea	_Domain		| for printf
");
#else	__MSHORT__
__asm("
error_plus:
	swap	d0
	moveml	d0-d1,a7@-
	movew	#63,_errno	| NAN => errno = EDOM
	pea	_Overflow	| for printf
	bra	error_exit	|
error_nan:
	moveml	a0@(24),d0-d1	| result = +inf
	moveml	d0-d1,a7@-
	movew	#62,_errno	| NAN => errno = EDOM
	pea	_Domain		| for printf
");
#endif	__MSHORT__
__asm("
error_exit:
	pea	_Error_String	|
	pea	__iob+52	|
	jbsr	_fprintf	|
	addl	#12,a7		|
	moveml	a7@+,d0-d1
	rts
    ");
# else	ERROR_CHECK

__asm("rts");

# endif	ERROR_CHECK
#endif /* __M68881__ || sfp004	*/
