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
 *	dabs,fabs   double precision absolute value
 *
 *  KEY WORDS
 *
 *	dabs
 *	fabs
 *	machine independent routines
 *	math libraries
 *
 *  DESCRIPTION
 *
 *	Returns absolute value of double precision number.
 *
 *	The fabs routine is supplied for compatibility with unix
 *	libraries where for some bizarre reason, the double precision
 *	absolute value routine is called fabs.
 *
 *  USAGE
 *
 *	double dabs (x)
 *	double x;
 *
 *	double fabs (x)
 *	double x;
 * 
 *  PROGRAMMER
 *
 *	Fred Fish
 *
 */
#if !defined (OLD)	/* mjr++	*/

__asm("
.text
.even
.globl _dabs
.globl _fabs

_dabs:
_fabs:
	moveml	a7@(4),d0-d1
	bclr	#31,d0
	rts
");

#else OLD

#include <stdio.h>
#include <math.h>
#include "pml.h"

#ifdef IEEE
struct bitdouble {
    unsigned long sign : 1;
    unsigned long exp  : 11;
    unsigned long mant1: 20;
    unsigned long mant2: 32;
};
#endif


#if defined(m68k) && defined(__GNUC__)
asm(".stabs \"_fabs\",5,0,0,_dabs"); /* dept of clean tricks */
#endif

double dabs (x)
double x;
{
#ifndef IEEE
    if (x < 0.0) {
	x = -x;
    }
    return (x);
#else
    struct bitdouble *bd = (struct bitdouble *)&x;
    bd->sign = 0;

    return x;
#endif
}

#if !(defined(m68k) && defined(__GNUC__))
double fabs (x)
double x;
{
#ifndef IEEE
    return (dabs(x));
#else
    struct bitdouble *bd = (struct bitdouble *)&x;
    bd->sign = 0;

    return x;
#endif
}
#endif

#endif OLD
