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
 *	fmod   double precision modulo
 *
 *  KEY WORDS
 *
 *	mod
 *	machine independent routines
 *	math libraries
 *
 *  DESCRIPTION
 *
 *	Returns double precision modulo of two double
 *	precision arguments.
 *
 *  USAGE
 *
 *	double fmod (value, base)
 *	double value;
 *	double base;
 *
 *  PROGRAMMER
 *
 *	Fred Fish
 *
 *	68881 support included by Michael Ritzert
 *
 */


#include <stdio.h>
#include <math.h>
#include "pml.h"

#if !defined (__M68881__) && !defined (sfp004)	/* mjr++	*/

double fmod (value, base)
double value;
double base;
{
    double intpart;

    (void) modf (value/base, &intpart);
    return(value - base * intpart);
}
#endif	/* __M68881, sfp004	*/
#ifdef	sfp004

__asm("

| base =	0xfffa50
|      the fpu addresses are taken relativ to 'base':
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
	.ascii \"fmod: %s error\\n\\0\"

| pml compatible tangent
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
	.globl _fmod
_fmod:
    ");	/* end asm	*/

#endif	/* __M68881__ || sfp004	*/
#ifdef	__M68881__

    __asm("
	fmovex	fp0,sp@-	| 12 Bytes
	fmoved	a7@(16), fp0	| value
	fmodd	a7@(24),fp0	| base
	fmoved	fp0,a7@-	| push result
	moveml	a7@+,d0-d1	| return_value
	fmovex	sp@+,fp0
    ");	/* end asm	*/

#endif	__M68881__
#ifdef	sfp004
    __asm("
	lea	0xfffa50,a0
	movew	#0x5400,a0@(comm)	| specify function (fmove)
	cmpiw	#0x8900,a0@(resp)	| check
	movel	a7@(4),a0@		| load arg_hi
	movel	a7@(8),a0@		| load arg_low
	movew	#0x5421,a0@(comm)	| specify function (fmod)
	.long	0x0c688900, 0xfff067f8	| wait
	movel	a7@(12),a0@		| load arg_hi
	movel	a7@(16),a0@		| load arg_low
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
	rts
    ");
# else	ERROR_CHECK

__asm("rts");

# endif	ERROR_CHECK
#endif /* __M68881__ || sfp004	*/

#ifdef m68881
/* mjr: intermediate version, remove after debugging	*/

    struct exception xcpt;

double fmod (double value, double base)
{
    if( base == 0.0 )	{
	xcpt.retval = HUGE_VAL;
	if( value < 0.0 ) xcpt.retval = -HUGE_VAL;
	xcpt.arg1 = base;
	xcpt.type = DOMAIN;
	if (!matherr (&xcpt)) {
	    fprintf (stderr, "%s: ZERO DIVIDE error\n", "fmod");
	    errno = EDOM;
	}
    } else {
	__asm ("fmod%.x %2,%0"
	 : "=f" (xcpt.retval)
	 : "0" (value),
	   "f" (base));
    }
    return xcpt.retval;
}
#endif m68881
