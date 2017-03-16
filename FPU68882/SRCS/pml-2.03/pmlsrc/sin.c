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
 *	sin	double precision sine
 *
 *  KEY WORDS
 *
 *	sin
 *	machine independent routines
 *	trigonometric functions
 *	math libraries
 *
 *  DESCRIPTION
 *
 *	Returns double precision sine of double precision
 *	floating point argument.
 *
 *  USAGE
 *
 *	double sin (x)
 *	double x;
 *
 *  REFERENCES
 *
 *	Computer Approximations, J.F. Hart et al, John Wiley & Sons,
 *	1968, pp. 112-120.
 *
 *  RESTRICTIONS
 *
 *	The sin and cos routines are interactive in the sense that
 *	in the process of reducing the argument to the range -PI/4
 *	to PI/4, each may call the other.  Ultimately one or the
 *	other uses a polynomial approximation on the reduced
 *	argument.  The sin approximation has a maximum relative error
 *	of 10**(-17.59) and the cos approximation has a maximum
 *	relative error of 10**(-16.18).
 *
 *	These error bounds assume exact arithmetic
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
 *	Computes sin(x) from:
 *
 *	  (1)	Reduce argument x to range -PI to PI.
 *
 *	  (2)	If x > PI/2 then call sin recursively
 *		using relation sin(x) = -sin(x - PI).
 *
 *	  (3)	If x < -PI/2 then call sin recursively
 *		using relation sin(x) = -sin(x + PI).
 *
 *	  (4)	If x > PI/4 then call cos using
 *		relation sin(x) = cos(PI/2 - x).
 *
 *	  (5)	If x < -PI/4 then call cos using
 *		relation sin(x) = -cos(PI/2 + x).
 *
 *	  (6)	If x is small enough that polynomial
 *		evaluation would cause underflow
 *		then return x, since sin(x)
 *		approaches x as x approaches zero.
 *
 *	  (7)	By now x has been reduced to range
 *		-PI/4 to PI/4 and the approximation
 *		from HART pg. 118 can be used:
 *
 *		sin(x) = y * ( p(y) / q(y) )
 *		Where:
 *
 *		y    =  x * (4/PI)
 *
 *		p(y) =  SUM [ Pj * (y**(2*j)) ]
 *		over j = {0,1,2,3}
 *
 *		q(y) =  SUM [ Qj * (y**(2*j)) ]
 *		over j = {0,1,2,3}
 *
 *		P0   =  0.206643433369958582409167054e+7
 *		P1   =  -0.18160398797407332550219213e+6
 *		P2   =  0.359993069496361883172836e+4
 *		P3   =  -0.2010748329458861571949e+2
 *		Q0   =  0.263106591026476989637710307e+7
 *		Q1   =  0.3927024277464900030883986e+5
 *		Q2   =  0.27811919481083844087953e+3
 *		Q3   =  1.0000...
 *		(coefficients from HART table #3063 pg 234)
 *
 *
 *	**** NOTE ****	  The range reduction relations used in
 *	this routine depend on the final approximation being valid
 *	over the negative argument range in addition to the positive
 *	argument range.  The particular approximation chosen from
 *	HART satisfies this requirement, although not explicitly
 *	stated in the text.  This may not be true of other
 *	approximations given in the reference.
 *			
 */

#if !defined (__M68881__) && !defined (sfp004)	/* mjr++	*/

#include <stdio.h>
#include <math.h>
#include "pml.h"

static char funcname[] = "sin";

static double sin_pcoeffs[] = {
    0.20664343336995858240e7,
   -0.18160398797407332550e6,
    0.35999306949636188317e4,
   -0.20107483294588615719e2
};

static double sin_qcoeffs[] = {
    0.26310659102647698963e7,
    0.39270242774649000308e5,
    0.27811919481083844087e3,
    1.0
};

    struct exception xcpt;

double sin (x)
double x;
{
    double y;
    double yt2;

    if (x < -PI || x > PI) {
	x = fmod (x, TWOPI);
	if (x > PI) {
	    x = x - TWOPI;
	} else if (x < -PI) {
	    x = x + TWOPI;
	}
    }
    if (x > HALFPI) {
	xcpt.retval = -(sin (x - PI));
    } else if (x < -HALFPI) {
	xcpt.retval = -(sin (x + PI));
    } else if (x > FOURTHPI) {
	xcpt.retval = cos (HALFPI - x);
    } else if (x < -FOURTHPI) {
	xcpt.retval = -(cos (HALFPI + x));
    } else if (x < X6_UNDERFLOWS && x > -X6_UNDERFLOWS) {
	xcpt.retval = x;
    } else {
	y = x / FOURTHPI;
	yt2 = y * y;
	xcpt.retval = y * (poly (3, sin_pcoeffs, yt2) / poly(3, sin_qcoeffs, yt2));
    }
    return (xcpt.retval);
}
#endif	/* __M68881__, sfp004	*/
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
	.ascii \"sin: %s error\\n\\0\"
.even
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
    ");	/* end asm	*/
# endif	ERROR_CHECK

    __asm(".even
.globl _sin
_sin:
    ");	/* end asm	*/

#endif	/* __M68881__ || sfp004	*/
#ifdef	__M68881__

    __asm("
	fsind	a7@(4), fp0	| sin
	fmoved	fp0,a7@-	| push result
	moveml	a7@+,d0-d1	| return_value
    ");	/* end asm	*/

#endif	__M68881__
#ifdef	sfp004
    __asm("
	lea	0xfffa50,a0
	movew	#0x540e,a0@(comm)	| specify function
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
	rts
    ");
# else	ERROR_CHECK

__asm("rts");

# endif	ERROR_CHECK
#endif /* __M68881__ || sfp004	*/
