/************************************************************************
 *									*
 * mjr: provided assembler version for all system configurations	*
 * 15.12.92									*
 ************************************************************************
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
 *	copysign   transfer of sign
 *
 *  KEY WORDS
 *
 *	sign
 *	machine independent routines
 *	math libraries
 *
 *  DESCRIPTION
 *
 *	Returns first argument with same sign as second argument.
 *
 *  USAGE
 *
 *	double copysign (x, y)
 *	double x;
 *	double y;
 *
 *  PROGRAMMER
 *
 *	Fred Fish
 *	Tempe, Az 85281
 *	(602) 966-8871
 *
 */

#include <stdio.h>
#include <math.h>
#include "pml.h"


#if OLD

double copysign (x, y)
double x;
double y;
{
    double rtnval;
    
    ENTER ("copysign");
    DEBUG4 ("copysignin", "args %le %le", x, y);
    if (x >= 0.0) {
	if (y >= 0.0) {
	    rtnval = x;
	} else {
	    rtnval = -x;
	}
    } else {
	if (y < 0.0) {
	    rtnval = x;
	} else {
	    rtnval = -x;
	}
    }
    DEBUG3 ("copysignout", "result %le", rtnval);
    LEAVE ();
    return (rtnval);
}

#else	OLD 	/* mjr: assembler version for  all machines */
__asm("
.text
.even
.globl _copysign

_copysign:
	moveml	a7@(4),d0-d1
	btst	#31,a7@(12)
	beq	clear
	bset	#31,d0
	rts
clear:
	bclr	#31,d0
	rts
");	/* end asm	*/

#endif	OLD
