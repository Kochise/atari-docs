/************************************************************************
 *
 * New version of atan function for PML library.  In general based on
 * original routine by Fred Fish, but modified to use range reduction
 * in a more consistent manner and to perform its task without recursive
 * calls.  It does not complain when arguments are close to 0.0.
 * atan() is smooth enough and its derivative there is 1.
 * It also now returns PI/2 and not 0.0 when arguments are getting too big.
 * Besides original function would not work when matherr() function
 * would be replaced with something which always returns 1.
 *
 * Michal Jaegermann, December 1990
 * ntomczak@ualtavm.bitnet
 *
 ************************************************************************/

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
 *	atan   double precision arc tangent
 *
 *  KEY WORDS
 *
 *	atan
 *	machine independent routines
 *	trigonometric functions
 *	math libraries
 *
 *  DESCRIPTION
 *
 *	Returns double precision arc tangent of double precision
 *	floating point argument.
 *
 *  USAGE
 *
 *	double atan (x)
 *	double x;
 *
 *  REFERENCES
 *
 *	Fortran 77 user's guide, Digital Equipment Corp. pp B-3
 *
 *	Computer Approximations, J.F. Hart et al, John Wiley & Sons,
 *	1968, pp. 120-130.
 *
 *  RESTRICTIONS
 *
 *	The maximum relative error for the approximating polynomial
 *	is 10**(-16.82).  However, this assumes exact arithmetic
 *	in the polynomial evaluation.  Additional rounding and
 *	truncation errors may occur as the argument is reduced
 *	to the range over which the polynomial approximation
 *	is valid, and as the polynomial is evaluated using
 *	finite-precision arithmetic.
 *	
 *  PROGRAMMER
 *
 *	Fred Fish
 *
 *  INTERNALS
 *
 *	Computes arctangent(x) from:
 *
 *		(1)	If x < 0 then negate x, perform steps
 *			2, 3, and 4, and negate the returned
 *			result.  This makes use of the identity
 *			atan(-x) = -atan(x).
 *
 *		(2)	If argument x > 1 at this point then
 *			test to be sure that x can be inverted
 *			without underflowing.  If not, reduce
 *			x to largest possible number that can
 *			be inverted, issue warning, and continue.
 *			Perform steps 3 and 4 with arg = 1/x
 *			and subtract returned result from
 *			pi/2.  This makes use of the identity
 *			atan(x) = pi/2 - atan(1/x) for x>0.
 *
 *              (2a)
 *                      Modification - numbers in range [1, tan((5/12)pi)]
 *                      are not iverted as above but a range is reduced
 *                      to [-tan(pi/12),tan(pi/12)] with result modified
 *                      correspondingly ( -- mj)
 *
 *		(3)	At this point 0 <= x <= 1.  If
 *			x > tan(pi/12) then perform step 4
 *			with arg = (x*sqrt(3)-1)/(sqrt(3)+x)
 *			and add pi/6 to returned result.
 *                      (modification - same formula, different rendition --mj)
 *			This last transformation maps arguments
 *			greater than tan(pi/12) to arguments
 *			in range 0...tan(pi/12).
 *
 *		(4)	At this point the argument has been
 *			transformed so that it lies in the
 *			range -tan(pi/12)...tan(pi/12).
 *                      (The check below eliminated - it really
 *                      doesn't make sense.  Approximation is
 *                      surprisingly robust anyway -- mj)
 *			Since very small arguments may cause
 *			underflow in the polynomial evaluation,
 *			a final check is performed.  If the
 *			argument is less than the underflow
 *			bound, the function returns x, since
 *			atan(x) approaches asin(x) which
 *			approaches x, as x goes to zero.
 *
 *		(5)	atan(x) is now computed by one of the
 *			approximations given in the cited
 *			reference (Hart).  That is:
 *
 *			atan(x) = x * SUM [ C[i] * x**(2*i) ]
 *			over i = {0,1,...8}.
 *
 *			Where:
 *
 *			C[0] =	.9999999999999999849899
 *			C[1] =	-.333333333333299308717
 *			C[2] =	.1999999999872944792
 *			C[3] =	-.142857141028255452
 *			C[4] =	.11111097898051048
 *			C[5] =	-.0909037114191074
 *			C[6] =	.0767936869066
 *			C[7] =	-.06483193510303
 *			C[8] =	.0443895157187
 *			(coefficients from HART table #4945 pg 267)
 *
 */

#include <stdio.h>
#include <math.h>
#include "pml.h"

#if !defined (__M68881__) && !defined (sfp004)	/* mjr++		*/

static char funcname[] = "atan";

static double atan_coeffs[] = {
/*  .9999999999999999849899, */		/* P0 must be first	*/
    .99999999999999998,                 /* watch out - bug in gcc 1.37
                                           at least for ST */
                                        /* longer representations will burn
					   you badly -- mj */
    -.333333333333299308717,
    .1999999999872944792,
    -.142857141028255452,
    .11111097898051048,
    -.0909037114191074,
    .0767936869066,
    -.06483193510303,
    .0443895157187				/* Pn must be last	*/
};

#define LAST_BOUND 0.2679491924311227074725	/*  tan (PI/12)		*/
#define MID_BOUND  1.0				/*  tan (3 * PI/12)	*/
#define HI_BOUND   3.7320508075688772935274	/*  tan (5 * PI/12)	*/

#define INV_ROOT3  0.5773502691896257645
#define THIRDPI    1.0471975511968977461

    struct exception xcpt;

double atan (x)
double x;
{
    short neg_flag = 0;

    xcpt.retval = 0.0;
    if (x < 0.0) {
	x = -x;
	neg_flag |= 1;
    }
    if (x > MID_BOUND) {
	if (x > HI_BOUND) {
	    xcpt.retval = HALFPI;
	    if (x >= MAXDOUBLE) {
		if (!matherr (&xcpt)) {
		    xcpt.type = UNDERFLOW;
		    xcpt.name = funcname;
		    xcpt.arg1 = x;
		    fprintf (stderr, "%s: UNDERFLOW error\n", funcname);
		    errno = EDOM;
		}
		x = 0.0;
	    }
	    else {
		x = -1.0 / x;
	    }
	}
	else {  /* MID_BOUND <= x <= HI_BOUND */
	    xcpt.retval = THIRDPI;
	    x = INV_ROOT3 -  4.0 / (SQRT3 + x + x + x);
	}
    }
    else { /* (x <= MID_BOUND) */
	if (x > LAST_BOUND) {
	    xcpt.retval = SIXTHPI;
	    x = SQRT3 - 4.0 / (SQRT3 + x);
	}
    }
    /* range reduced to [-LAST_BOUND, LAST_BOUND] */
    if (x != 0.0) { /* polynomial approximation */
    		    /* underflow in poly is not of a big concern here */
	x *= poly (((int)sizeof (atan_coeffs) / (int)sizeof(double)) - 1,
			atan_coeffs, x * x);
	xcpt.retval += x;
    }
    if (neg_flag)
	    xcpt.retval = -xcpt.retval;
    return (xcpt.retval);
}
#endif	/* !__M68881__ || !sfp004	*/
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
	.ascii \"atan: %s error\\n\\0\"
.even


| pml compatible atangent
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
	.globl _atan
_atan:
    ");	/* end asm	*/

#endif	/* __M68881__ || sfp004	*/
#ifdef	__M68881__

    __asm("
	fatand	a7@(4), fp0	| atan
	fmoved	fp0,a7@-	| push result
	moveml	a7@+,d0-d1	| return_value
    ");	/* end asm	*/

#endif	__M68881__
#ifdef	sfp004
    __asm("
	lea	0xfffa50,a0
	movew	#0x540a,a0@(comm)	| specify function
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
	swap	d0		| result ok,
	rts			| restore d0
");
#ifndef	__MSHORT__
__asm("
error_nan:
	moveml	a0@(24),d0-d1	| result = +inf
	moveml	d0-d1,a7@-
	movel	#62,_errno	| NAN => errno = EDOM
	pea	_Domain		| for printf
");
#else	__MSHORT__
__asm("
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
    ");
# endif	ERROR_CHECK

__asm("rts");

#endif /* __M68881__ || sfp004	*/
