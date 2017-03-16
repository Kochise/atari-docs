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
 *	crcp   complex double precision reciprocal
 *
 *  KEY WORDS
 *
 *	crcp
 *	complex functions
 *	math libraries
 *
 *  DESCRIPTION
 *
 *	Computes double precision complex reciprocal of
 *	a double precision complex argument.
 *
 *  USAGE
 *
 *	COMPLEX crcp (z)
 *	COMPLEX z;
 *
 *  PROGRAMMER
 *
 *	Fred Fish
 *	Tempe, Az 85281
 *	(602) 966-8871
 *
 *  INTERNALS
 *
 *	Computes complex reciprocal of z = x + j y from:
 *
 *		1.	Compute denom = x*x + y*y
 *
 *		2.	If denom = 0.0 then flag error
 *			and return MAX_POS_DBLF + j 0.0
 *
 *		3.	Else crcp(z) = (x/denom) + j (-y/denom)
 *
 */

#if defined (__M68881__) && !defined (_M68881)
/*# define _M68881*/
#endif

#include <stdio.h>
#include <math.h>
#include "pml.h"


    double denom;
    struct exception xcpt;

COMPLEX crcp (z)
COMPLEX z;
{
    denom = (z.real * z.real) + (z.imag * z.imag);
    if (denom == 0.0) {
	xcpt.type = SING;
	xcpt.name = "crcp";
	xcpt.arg1 = denom;
	if (!matherr (&xcpt)) {
	    fprintf (stderr, "%s: ZERO_CMPLX_DENOMINATOR \n", xcpt.name);
	    errno = ERANGE;
	    xcpt.retval = 0.0;	/* useless in this context */
	}
	if( z.real >= 0.0 )	z.real =  HUGE_VAL;
	else			z.real = -HUGE_VAL;
	if( z.imag  < 0.0 )	z.imag =  HUGE_VAL;
	else			z.imag = -HUGE_VAL;
    } else {
	z.real /= denom;
	z.imag /= -denom;
    }
    return (z);
}
