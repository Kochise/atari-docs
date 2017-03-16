/************************************************************************
 *                                                                      *
 * A replacement log() routine for PML library.  It really computes     *
 * base 2 logarithm which can be multiplied by a proper constant        *
 * to provide final answer.  A rational approximation of an original    *
 * is replaced by a polynomial one.  In practice, with a software       *
 * floating point, this gives a better precision.                       *
 *                                                                      *
 * Michal Jaegermann, December 1990                                     *
 *                                                                      *
 * If __GCC_HACK__ is defined then we are folding log and log10 routines*
 * by making in assembler an extra entry point.  Do not define that     *
 * for portable routine!!                                               *
 * Do not define that with gcc -O2 !!					*
 *                                                                      *
 * 68881 support added by Michael Ritzert, November 1991		*
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
 *	log   double precision natural log
 *
 *  KEY WORDS
 *
 *	log
 *	machine independent routines
 *	math libraries
 *
 *  DESCRIPTION
 *
 *	Returns double precision natural log of double precision
 *	floating point argument.
 *
 *  USAGE
 *
 *	double log (x)
 *	double x;
 *
 *  REFERENCES
 *
 *	Computer Approximations, J.F. Hart et al, John Wiley & Sons,
 *	1968, pp. 105-111.
 *
 *  RESTRICTIONS
 *
 *	The absolute error in the approximating rational function is
 *	10**(-19.38).  Note that contrary to DEC's assertion
 *	in the F4P user's guide, the error is absolute and not
 *	relative.
 *      ** modified ** theoretical precision is only 10**(-16.5);
 *      it works better in practice.
 *
 *	This error bound assumes exact arithmetic
 *	in the polynomial evaluation.  Additional rounding and
 *	truncation errors may occur as the argument is reduced
 *	to the range over which the polynomial approximation
 *	is valid, and as the polynomial is evaluated using
 *	finite-precision arithmetic.
 *	
 *  PROGRAMMER
 *
 *	Fred Fish
 *      Modifications - Michal Jaegermann
 *
 *  INTERNALS
 *
 *	Computes log(X) from:
 *
 *	  (1)	If argument is zero then flag an error
 *		and return minus infinity (or rather its
 *		machine representation).
 *
 *	  (2)	If argument is negative then flag an
 *		error and return minus infinity.
 *
 *	  (3)	Given that x = m * 2**k then extract
 *		mantissa m and exponent k.
 *        (3a)  If m = 0.5 then we know what is the final
 *              result and calculations can be shortened.
 *
 *	  (4)	Transform m which is in range [0.5,1.0]
 *		to range [1/sqrt(2), sqrt(2)] by:
 *
 *			s = m * sqrt(2)
 *
 *	  (5)	Compute z = (s - 1) / (s + 1)
 *        (5a)  Modified - combine steps (4) and (5) computing
 *              z = (m - 1/sqrt(2)) / (m + 1/sqrt(2))
 *
 *	  (6)	Now use the approximation from HART
 *		page 111 to find log(s):
 *
 *		log(s) = z * ( P(z**2) / Q(z**2) )
 *
 *		Where:
 *
 *		P(z**2) =  SUM [ Pj * (z**(2*j)) ]
 *		over j = {0,1,2,3}
 *
 *		Q(z**2) =  SUM [ Qj * (z**(2*j)) ]
 *		over j = {0,1,2,3}
 *
 *		P0 =  -0.240139179559210509868484e2
 *		P1 =  0.30957292821537650062264e2
 *		P2 =  -0.96376909336868659324e1
 *		P3 =  0.4210873712179797145
 *		Q0 =  -0.120069589779605254717525e2
 *		Q1 =  0.19480966070088973051623e2
 *		Q2 =  -0.89111090279378312337e1
 *		Q3 =  1.0000
 *
 *		(coefficients from HART table #2705 pg 229)
 *	  (6a)	Modified - compute, as a polynomial of z, an
 *              approximation of log2(m * sqrt(2)). Coefficients
 *              for this polynomial are not given explicitely in HART
 *              but can be computed from table #2665, for example.
 *
 *	  (7)	Finally, compute log(x) from:
 *
 *		log(x) = (k * log(2)) - log(sqrt(2)) + log(s)
 *
 *        (7a)  log2(x) = k - 1/2 + log(m * sqrt(2)).  Multiply
 *              by a constant to adjust a logarithm base.
 *
 */

#if !defined (__M68881__) && !defined (sfp004)

#include <stdio.h>
#include <math.h>
#include "pml.h"

			/* mjr++				*/
			/* use a different routine instead	*/
			/* see end of listing			*/

# define HALFSQRT2		0.70710678118654752440

static double log_coeffs[] = {
	2.88539008177793058026,
	0.9617966939212138784,
	0.577078018095541030,
	0.4121983030496934,
	0.32062199711811,
	0.2612917312170,
	0.24451102108
};

#ifdef __GCC_HACK__
static double log_of2[] = {
	LN2, 0.30102999566398119521 /* log10(2) */
};
#endif

static char funcname[] = "log";

#ifdef __GCC_HACK__
/*
 * This fake function header may change even from version to a version
 * of gcc compiler.  Ensure that first four assembler instructions in
 * log and log10 are the same!
 */
__asm__("
	.text
	.even
	.globl _log10
_log10:");
#ifdef __MSHORT__
__asm__("
	link a6,#-32
	moveml #0x3e30,sp@-");
#else
__asm__("
	link a6,#-36
	moveml #0x3f30,sp@-");
#endif  /* __MSHORT__ */
__asm__("
	movel a6@(8),d4
	movel a6@(12),d5
	moveq #1,d6
	jra   lgentry");
#endif  /* __GCC_HACK__ */

double log (x)
double x;
{
    int k;
    double s;
    struct exception xcpt;
    char * xcptstr;
#ifdef __GCC_HACK__
    int index;

    index = 0;
__asm__("
lgentry:");
#endif

    if (x <= 0.0) {
	xcpt.name = funcname;
	xcpt.arg1 = x;
    	if (x == 0.0) {
	    xcpt.retval = -MAXDOUBLE;
	    xcpt.type = SING;
	    xcptstr = "SINGULARITY";
	}
	else {
	    xcpt.retval = MAXDOUBLE;
	    xcpt.type = DOMAIN;
	    xcptstr = "DOMAIN";
	}
	if (!matherr (&xcpt)) {
	    fprintf (stderr, "%s: %s error\n", xcptstr, funcname);
	    errno = EDOM;
	}
    }
    else {
	s = frexp (x, &k);
	if (0.5 == s ) {
		s = -1.0;
	}
	else {
	    /* range reduction with s multiplied by SQRT2 */
	    s = (s - HALFSQRT2) / (s + HALFSQRT2);
	    /* polynomial approximation */
	    s *= poly ((sizeof(log_coeffs)/sizeof(double)) - 1,
	               log_coeffs, s * s);
	    /* and subtract log2 of SQRT2 */
	    s -= 0.5;
	}
	/* add the original binary exponent */
	s += k;
	/* multiply to get a requested logarithm */
#ifdef __GCC_HACK__
	xcpt.retval = s * log_of2[index];
#else
	xcpt.retval = s * LN2;
#endif
    }
    return (xcpt.retval);
}
#endif /* !__M68881__ && ! sfp004	*/

/*****************************************************************/

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
	.ascii \"log: %s error\\n\\0\"
.even

| pml compatible log
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
# endif	ERROR_CHECK

    __asm("
.even
	.globl _log
_log:
    ");	/* end asm	*/

#endif	/* __M68881__ || sfp004	*/
#ifdef	__M68881__

    __asm("
	flognd	a7@(4), fp0	| log
	fmoved	fp0,a7@-	| push result
	moveml	a7@+,d0-d1	| return_value
    ");	/* end asm	*/

#endif	__M68881__
#ifdef	sfp004
    __asm("
	lea	0xfffa50,a0
	movew	#0x5414,a0@(comm)	| specify function
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
	cmpw	a0@(32),d0	| == - Infinity ?
	beq	error_minus	|
	swap	d0		| result ok,
	rts			| restore d0
");
#ifndef	__MSHORT__
__asm("
error_minus:
	swap	d0
	moveml	d0-d1,a7@-
	movel	#63,_errno	| errno = ERANGE
	pea	_Overflow	| for printf
	bra	error_exit	|
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
error_minus:
	swap	d0
	moveml	d0-d1,a7@-
	movew	#63,_errno	| errno = ERANGE
	pea	_Overflow	| for printf
	bra	error_exit	|
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
