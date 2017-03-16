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
 *	csinh   complex double precision hyperbolic sine
 *
 *  KEY WORDS
 *
 *	csinh
 *	machine independent routines
 *	complex functions
 *	math libraries
 *
 *  DESCRIPTION
 *
 *	Computes double precision complex hyperbolic sine of
 *	a double precision complex argument.
 *
 *  USAGE
 *
 *	COMPLEX csinh (z)
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
 *	Computes complex hyperbolic sine of z = x + j y from:
 *
 *	    csinh(z) = 0.5 * ( cexp(z) - cexp(-z) )
 *
 */

#if defined (__M68881__) && !defined (_M68881)
/*# define _M68881*/
#endif

#include <stdio.h>
#include <math.h>
#include "pml.h"

COMPLEX csinh (z)
COMPLEX z;
{
    COMPLEX cexpmz;

    cexpmz.real = -z.real;
    cexpmz.imag = -z.imag;
    cexpmz = cexp (cexpmz);
    z = cexp (z);
    z.real -= cexpmz.real;
    z.imag -= cexpmz.imag;
    z.real *= 0.5;
    z.imag *= 0.5;

    return (z);
}
