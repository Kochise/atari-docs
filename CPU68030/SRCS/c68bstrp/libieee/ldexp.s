#
 ! C68 add exponent to 8 byte floating point number
 !-----------------------------------------------------------------------------
 ! ported to 68000 by Kai-Uwe Bloem, 12/89
 !  #1  original author: Peter S. Housel 9/21/88,01/17/89,03/19/89,5/24/89
 !  #2	added support for denormalized numbers			-kub-, 01/90
 !  #3  Added use of limits.h to allow for both 16 and 32 bit
 !	int implementations
 !	Added check for NaN error case				-djw-	09/93
 !  #4  corrected problem when ints are 32 bit          -djw-, 03/95
 !-----------------------------------------------------------------------------
 !  double ldexp (double x, int n)
 !
 !  The function|ldexp(double x, int n)| returns x*(2**n)
 !
 !  If underflow occurs, then errno is set to ERANGE, and zero returned
 !
 !  If overflow occurs, then errno is set to ERANGE, and +/- HUGE_VAL
 !  is returned
 !
 !  If |x| is a NaN then errno is set to EDOM and Nan returned.
 !----------------------------------------------------------------------------

	.sect .text

	.define _ldexp

	.extern	_errno
	.extern __HUGE_VAL

EDOM	=	33
ERANGE  =	34

#include <limits.h>
#if (INT_MAX == SHRT_MAX)
#define LN w
#else
#define LN l
#endif

_ldexp:
	lea	4(sp),a1
#if (INT_MAX != SHRT_MAX)
	move.l	#0,d0
#endif
	move.w	(a1),d0		! extract value.exp
	move.w	d0,d2		! extract value.sign
	lsr.w	#4,d0
	and.w	#0x7ff,d0	! kill sign bit

	cmp.w	#0x7ff,d0	! NaN ?
	beq	NaNval		! ... YES 

	and.w	#0x0f,(a1)	! remove exponent from value.mantissa
	tst.w	d0		! check for zero exponent - no leading "1"
	beq	0f
	or.w	#0x10,(a1)	! restore implied leading "1"
	bra	1f
0:	add.w	#1,d0
1:
	add.LN	8(a1),d0	! add in exponent
	cmp.LN	#-53,d0		! hmm. works only if 1 in implied position...
	ble	retz		! range error - underflow
	cmp.LN	#0x7ff,d0
	bge	rangerr		! range error - overflow

	clr.w	d1		! zero rounding bits
	jsr	.Xnorm8
retval:
	movem.l	4(sp),d0-d1	! return value
	rts

NaNval:
	move.LN	#EDOM,_errno	! set error code
	bra	retval		! exit returning oringinal value

retz:
	move.l	#0,d0		! set reply to zero
	move.l	#0,d1
	bra	erange		! exit setting errno

rangerr:
	movem.l	__HUGE_VAL,d0/d1
	and.w	#0x8000,d2	! get sign bit of argument
	lsl.l	#8,d2	! get into correct position
	lsl.l	#8,d2
	or.l	d2,d0		! set sign bit if needed
erange:
	move.LN	#ERANGE,_errno
	rts
	
