#
 ! C68 4 byte floating point => 32 bit integer conversion routines
 !-----------------------------------------------------------------------------
 ! ported to 68000 by Kai-Uwe Bloem, 12/89
 !  #1  original author: Peter S. Housel 6/12/89,6/14/89
 !  #2  replaced shifts by swap if possible for speed increase -kub-, 01/90
 !  #3  Added wrapper routine to provide C68 IEEE compatibility
 !                                             Dave & Keith Walker     02/92
 !  #4	Changed entry/exit code for C68 v4.3 compatibility
 !	Removed ACK entry points					09/93
 !-----------------------------------------------------------------------------

       .sect .text

       .define .Xsftol

	.extern	.overflow

BIAS4  =       0x7F - 1

!----------------------------------------
!      sp      Return address
!      sp+4    address of float/double
!----------------------------------------
.Xsftol:
       move.l  4(sp),a0        ! address of value
       move.w  (a0),d0         ! extract exp
       move.w  d0,d2           ! extract sign
       lsr.w   #7,d0           ! shift down 7
       and.w   #0x0ff,d0       ! kill sign bit

       cmp.w   #BIAS4,d0       ! check exponent
       blt     zer4            ! strictly fractional, no integer part ?
       cmp.w   #BIAS4+32,d0    ! is it too big to fit in a 32-bit integer ?
       bgt     toobig

       move.l  (a0),d1
       and.l   #0x7fffff,d1    ! remove exponent from mantissa
       or.l    #0x800000,d1    ! restore implied leading "1"

       sub.w   #BIAS4+24,d0    ! adjust exponent
       bgt     2f              ! shift up
       beq     3f              ! no shift

       cmp.w   #-8,d0          ! replace far shifts by swap
       bgt     1f
       clr.w   d1              ! shift fast, 16 bits
       swap    d1
       add.w   #16,d0          ! account for swap
       bgt     2f
       beq     3f

1:     lsr.l   #1,d1           ! shift down to align radix point;
       add.w   #1,d0           ! extra bits fall off the end (no rounding)
       blt     1b              ! shifted all the way down yet ?
       bra     3f

2:     add.l   d1,d1           ! shift up to align radix point
       sub.w   #1,d0
       bgt     2b
       bra     3f
zer4:
       clr.l   d1              ! make the whole thing zero

3:     move.l  d1,d0           ! put integer into register
       cmp.l   #0x80000000,d0  ! -2147483648 is a nasty evil special case
       bne     6f
       tst.w   d2              ! this had better be -2^31 and not 2^31
       bpl     toobig
       bra     8f
6:     tst.l   d0              ! sign bit set ? (i.e. too big)
       bmi     toobig
       tst.w   d2              ! is it negative ?
       bpl     8f
       neg.l   d0              ! negate

8:	move.l	(sp)+,a1
	add.l	#4,sp		! remove parameters from stack
	jmp	(a1)		! return to caller

toobig:
	jsr	.overflow	! Default overflow handling routine
	jsr	.setmaxmin	! If control returned, set LONG_MAX/LONG_MIN
	bra	8b		! .., and exit backa to user

