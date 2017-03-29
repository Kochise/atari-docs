#
 ! C68 support routine to get a value in a bit field to a 32 bit value
 !-----------------------------------------------------------------------------
 !	#1	original version: David J. Walker								10/95
 !-----------------------------------------------------------------------------
 !
 !	Name:		.Xbfget
 !
 !	Parameters:
 !				LONG: Address of bit field
 !				WORD: value encoded with size/type information as follows
 !
 !					Byte	Description
 !					~~~~	~~~~~~~~~~~
 !					0	   Offset of bit field in bits (0-31)
 !						   Top bit set if field unsigned
 !					1	   Size of bit field in bits   (1-32)
 !
 !	The following assumptions are made:
 !	   1. The combination of offset and size cannot be larger than 32.
 !		  (i.e the value always fits into a long).
 !	   2. If the address passed is odd, the combination is limited to 24.
 !
 !---------------------------------------------------------------------------

	.sect .text

	.globl .Xbfget

VALPTR		= 	4+0
UNSIGNED	= 	4+4
SIZE		= 	4+4
OFFSET		= 	4+5

.Xbfget:

!	Load up registers as follows:
!		a0		Address of bit field
!		d1		Offset of bit field
!		d2		32 - Size of bit field
!	Check address supplied was even.  If not
!	we can assume that the size of the bit field
!	is less than 32 bits, so make adjustments

		move.b	OFFSET(a7),d1		! get offset to start
		move.l #32,d2
		sub.b	SIZE(sp),d2 		! 32 - size
		move.l	VALPTR(sp),d0		! load address of field
		bclr	#0,d0				! ensure even address ?
		beq 	waseven 			! ... it already was so jump
		add.b	#8,d1				! ... and adjust offset
waseven:
		move.l	d0,a0				! move to address register

!	Now extract the value into a long

		move.l	(a0),d0 			! get long that contains value
		lsl.l	d1,d0				! left align field
		btst	#7,d2				! is value unsigned?
		bne 	unsigned			! ... YES - jump
		asr.l	d2,d0				! move up signed value
		bra 	finish
unsigned:
		lsr.l	d2,d0				! move up unsigned value
finish:
		move.l	(sp)+,a1			! get return address
		add.l	#6,sp				! tidy stack (long + short)
		jmp 	(a1)				! return to caller
