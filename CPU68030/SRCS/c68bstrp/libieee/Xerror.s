#
 !	C68 Floating Point error routines
 !
 !	If return made from the raise() system call, then an
 !	appropriate value is passed back in d0 and d1.
 !
 !	The values involved are such that 'float' routines 
 !	can simply take the d0 value
 !
 !-----------------------------------------------------------------------------
 !	#1	First version (based on ideas from Michael Mueller) djw-  Sep/93
 !	#2	Corrected problem with missing # on .setmaxmin			  11/93
 !	#3	Corrected another problem with missing # on .setmaxmin	  12/93 
 !	#4	Corrected signal number send when using QDOS		djw - 07/95
 !	#5	made Infinity and HUGE_VAL into same constant		djw - 11/95
 !-----------------------------------------------------------------------------

	.sect .text

	.define __HUGE_VAL
	.define __Infinity
	.define __NaN
	.define __SNaN

	.globl .overflow
	.globl .underflow
	.globl .divzero
	.globl .setmaxmin

!	This next bit handles the sizeof(int) problem

#include <limits.h>
#if (INT_MAX == SHRT_MAX)
#define LN w
#define LEN 2
#else
#define LN l
#define LEN 4
#endif

SIGFPE	=	8

EDOM	=	33
ERANGE	=	34

	.extern _errno
	.extern _raise


 ! This is the representation of key floating point values.
 !
 ! It is done this way, because it is quite likely that  rounding errors
 ! in the compiler might mean the bit pattern is not exactly represented
 ! if simply done via a #define statement.



! Infinity/HUGE_VAL  (can be signed)
__HUGE_VAL:
__Infinity:
	.data4	0x7ff00000,0x00000000

! Not-a-Number
__NaN:
	.data4	0x7fffffff,0xffffffff

! Signalling Not-a-Number
__SNaN:
	.data4	0xffffffff,0xffffffff


! Overflow has occurred
! We need to raise a floating point exception, with errno
! set to ERANGE.  If a return is made from the exception
! routine, then return HUGE_VAL

.overflow:
	move.LN #ERANGE,_errno		! errno = ERANGE for overflow
	bsr 	sendsigfp
	movem.l __HUGE_VAL(pc),d0/d1	! result = HUGE_VAL in case of return
	rts

! Underflow has occurred
! We need to raise a floating point exception, with errno
! set to ERANGE.  If a return is made from the floating
! routine, then return 0.
!
.underflow:
	move.LN #ERANGE,_errno		! errno = ERANGE for underflow
	bsr 	sendsigfp
	move.l	#0,d0			! result = 0 in case of return
	move.l	#0,d1
	rts

! Divide by Zero
! We need to raise a floating point exception with errno set to EDOM.
! If a return is made from the exception routine, then return infinity.

.divzero:
	move.LN #EDOM,_errno		! errno = EDOM for	divide by zero
	bsr 	sendsigfp
	movem.l __Infinity(pc),d0/d1	! result = infinity in case of return
	rts

! Send a signal.
! We also preserve A1 across this call as many of the FP support routines
! use this to hold a pointer to where the result is meant to be put.
! Most of the time we will not return from such a call, but ithe calling
! routines better be prepared to handle this just in case.

sendsigfp:
	move.l	a1,-(sp)		! save a1
	move.LN #SIGFPE,-(sp)		! set for signal required
	jsr 	_raise			! raise (SIGFPE)
	add.l	#LEN,sp 		! tidy up stack
	move.l	(sp)+,a1		! restore a1
	rts

! Set LONG_MAX or LONG_MIN
! This is used to set LONG_MAX or LONG_MIN according to the sign of the
! floating point number pointed to by 8(A0)
! (called by sftol() and dftol() routines)

.setmaxmin:
	move.l	8(sp),a0		! address of value
	move.b	(a0),d1 		! get value
	and.b	#0x80,d1		! isolate sign
	bne 	setmin		! ... jump if negative
	move.l	#0x7fffffff,d0	! set to LONG_MAX
	rts
setmin:
	move.l	#0x80000000,d0	! set to LONG_MIN
	rts
