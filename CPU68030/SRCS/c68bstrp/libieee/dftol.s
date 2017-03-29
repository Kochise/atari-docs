 ! C68 8 byte floating point => 32 bit integer conversion routines
 !-----------------------------------------------------------------------------
 ! ported to 68000 by Kai-Uwe Bloem, 12/89
 !  #1  original author: Peter S. Housel 6/12/89,6/14/89
 !  #2  replaced shifts by swap if possible for speed increase -kub-, 01/90
 !  #3  Added wrapper routine to provide C68 IEEE compatibility
 !                                             Dave & Keith Walker     02/92
 !  #4	Changed entry/exit code for C68 v4.3 compatibility
 !	Removed ACK entry points
 !	Changed error handling code				-djw-	09/93
 !-----------------------------------------------------------------------------

       .sect .text

       .define .Xdftol

BIAS8  =       0x3FF - 1

!----------------------------------------
!      sp      Return address
!      sp+4    address of double
!----------------------------------------
.Xdftol:
       move.l  4(sp),a0        ! address of value
       move.w  (a0),d0         ! extract exp
       move.w  d0,a1           ! extract sign
       lsr.w   #4,d0
       and.w   #0x07ff,d0      ! kill sign bit

       cmp.w   #BIAS8,d0       ! check exponent
       blt     zer8            ! strictly factional, no integer part ?
       cmp.w   #BIAS8+32,d0    ! is it too big to fit in a 32-bit integer ?
       bgt     toobig

       movem.l (a0),d1-d2      ! get the value
       and.l   #0x0fffff,d1    ! remove exponent from mantissa
       or.l    #0x100000,d1    ! restore implied leading "1"

       sub.w   #BIAS8+21,d0    ! adjust exponent
       bgt     2f              ! shift up
       beq     3f              ! no shift

       cmp.w   #-8,d0          ! replace far shifts by swap
       bgt     1f
       move.w  d1,d2           ! shift fast, 16 bits
       swap    d2
       clr.w   d1
       swap    d1
       add.w   #16,d0          ! account for swap
       bgt     2f
       beq     3f

1:     lsr.l   #1,d1           ! shift down to align radix point;
       add.w   #1,d0           ! extra bits fall off the end (no rounding)
       blt     1b              ! shifted all the way down yet ?
       bra     3f

2:     add.l   d2,d2           ! shift up to align radix point
       addx.l  d1,d1
       sub.w   #1,d0
       bgt     2b
       bra     3f
zer8:
       clr.l   d1              ! make the whole thing zero

3:     move.l  d1,d0           ! save significant 32 bits
       move.w  a1,d2           ! get sign into d2

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
8:
	move.l	(sp)+,a1	! get return address
	add.l	#4,sp		! remove one parameter from stack
	jmp	(a1)

toobig:
	jsr	.overflow	! Default overflow handling routine
	jsr	.setmaxmin	! If control returned, set LONG_MAX/LONG_MIN
	bra	8b		! .., and exit back to user

