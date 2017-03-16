/************************************************************************
 *									*
 *   Replacement atan2() function for PML library. Original function    *
 *   from Fred Fish does not conform to Standard C.  It has arguments   *
 *   in a reverse order.  It also does not complain if both arguments   *
 *   are 0.0                                                            *
 *									*
 *   Michal Jaegermann - December 1990
 *									*
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
 *	atan2   double precision arc tangent of two arguments
 *
 *  KEY WORDS
 *
 *	atan2
 *	machine independent routines
 *	trigonometric functions
 *	math libraries
 *
 *  DESCRIPTION
 *
 *	Returns double precision arc tangent of two
 *	double precision floating point arguments ( atan(Y/X) ).
 *
 *  USAGE
 *
 *	double atan2(y, x)
 *	double y;
 *	double x;
 *
 *  (This order of arguments really makes sense if you will notice
 *   that this function is mainly used during a conversion from
 *   rectangular to polar coordinates)
 *
 *  REFERENCES
 *
 *	Fortran 77 user's guide, Digital Equipment Corp. pp B-4.
 *
 *  RESTRICTIONS
 *
 *	For precision information refer to documentation of the
 *	other floating point library routines called.
 *	
 *  PROGRAMMER
 *
 *	Fred Fish
 *	Modified by Michal Jaegermann
 *
 *  INTERNALS
 *
 *	Computes atan2(y, x) from:
 *
 *		1.	If x = 0 and y != 0 then
 *			atan2(y, x) = PI/2 * (sign(y))
 *                      otherwise error signaled and
 *                      atan2(y ,x) is 0.
 *
 *		2.	If x > 0 then
 *			atan2(y, x) = atan(y/x)
 *
 *		3.	If x < 0 then atan2(y, x) =
 *			PI*(sign(y)) + atan(y/x)
 *
 */

#if !defined (__M68881__) && !defined (sfp004)

#include <stdio.h>
#include <math.h>
#include "pml.h"

static char funcname[] = "atan2";

    struct exception xcpt;

double atan2 (y, x)
double y;
double x;
{
    double result;

    if (x == 0.0) {
	if (y == 0.0) {
	    result = HUGE_VAL;	/* mjr: for now, should be NAN	*/
	    xcpt.type = DOMAIN;
	    xcpt.name = funcname;
	    xcpt.arg1 = x;
	    xcpt.retval = result;
	    if (!matherr(&xcpt)) {
		fprintf (stderr, "%s: DOMAIN error\n", funcname);
		errno = EDOM;
	    }
	} else {
	    result = copysign (HALFPI, y);
	}
    } else {
	result = atan (y/x);
	if (x < 0.0) {
	    result += copysign (PI, y);
	}
    }
    return (result);
}

#endif !defined (__M68881__) && !defined (sfp004)
#ifdef	__M68881__
__asm("
.text
.even
_funcname:
	.ascii	\"atan2\\0\"
	.even

.globl	_atan2
_atan2:
| denormalized numbers are treated as 0
	tstl	sp@(12)
	beq	5f		| x == 0!
	blt	1f		| x < 0!
				| x > 0: return atan(y/x)

	fmoved	sp@(4),fp0	| get y
	fdivd	sp@(12),fp0	| y/x	
	fatanx	fp0,fp0		| atan(y/x)
	bra 3f			| return
1:				| x < 0

	fmovecr	#0,fp1		| get pi
	fmoved	sp@(4),fp0	| get y
	fdivd	sp@(12),fp0	| y/x
	fatanx	fp0,fp0		| atan(y/x)
	btst	#31,sp@(4)	| sign(y)
	beq	2f		| positive!

	fnegx	fp1,fp1		| transfer sign
2:	faddx	fp1,fp0		| sign(y)*pi + atan(y/x)
|	bra 3f			| return
3:
	fmoved	fp0,sp@-	| return result
	moveml	sp@+,d0/d1
4:	
	rts			| sigh.
5:				| x == 0
	movel	#1073291771,d0	| pi/2
	movel	#1413754136,d1	|

	tstl	sp@(4)		| 
	beq	6f		| NaN
	bge	4b		| exit
	bset	#31,d0		| x < 0 : return -pi/2
	bra	4b
6:	movel	#-1,d0		| NaN
	movel	#-1,d1		|
	bra	4b
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
	.ascii	\"atan2\\0\"
	.even
.text
.even
.globl	_atan2
_atan2:
| denormalized numbers are treated as 0
	lea	0xfffa50,a0
	moveml	a7@(12),d0-d1	|  x
	tstl	d0
	beq	5f		| x == 0!
	blt	1f		| x < 0!
				| x > 0: return atan(y/x)

|	fmoved	sp@(4),fp0	| get y
	movew	#0x5400,a0@(comm)
	.long	0x0c688900, 0xfff067f8
	movel	sp@(4),a0@
	movel	sp@(8),a0@

|	fdivd	sp@(12),fp0	| y/x
	movew	#0x5420,a0@(comm)
	.long	0x0c688900, 0xfff067f8
	movel	d0,a0@
	movel	d1,a0@

|	fatanx	fp0,fp0		| atan(y/x)
	movew	#0x000a,a0@(comm)
	.word	0x4a68,0xfff0,0x6bfa

	bra 3f			| return
1:				| x < 0

|	fmovecr	#0,fp1		| get pi
	movew	#0x5c80,a0@(comm)
	.long	0x0c688900, 0xfff067f8

|	fmoved	sp@(4),fp0	| get y
	movew	#0x5400,a0@(comm)
	.long	0x0c688900, 0xfff067f8
	movel	sp@(4),a0@
	movel	sp@(8),a0@

|	fdivd	sp@(12),fp0	| y/x
	movew	#0x5420,a0@(comm)
	.long	0x0c688900, 0xfff067f8
	movel	d0,a0@
	movel	d1,a0@

|	fatanx	fp0,fp0		| atan(y/x)
	movew	#0x000a,a0@(comm)
	.word	0x4a68,0xfff0,0x6bfa

	btst	#31,sp@(4)	| sign(y)
	beq	2f		| positive!

|	fnegx	fp1,fp1		| transfer sign
	movew	#0x049a,a0@(comm)
	.word	0x4a68,0xfff0,0x6bfa

2:|	faddx	fp1,fp0		| sign(y)*pi + atan(y/x)
	movew	#0x0422,a0@(comm)
	.word	0x4a68,0xfff0,0x6bfa

|	bra 3f			| return
3:
|	fmoved	fp0,d0-d1	| return result
	movew	#0x7400,a0@(comm)
	.long	0x0c688900, 0xfff067f8
	movel	a0@,d0
	movel	a0@,d1

4:	
	rts			| sigh.
5:				| x == 0
	movel	#1073291771,d0	| pi/2
	movel	#1413754136,d1	|

	tstl	sp@(4)		| 
	beq	6f		| NaN
	bge	4b		| exit
	bset	#31,d0		| x < 0 : return -pi/2
	bra	4b
6:	movel	#-1,d0		| NaN
	movel	#-1,d1		|
	bra	4b
");	/* end asm	*/
#endif	sfp004
