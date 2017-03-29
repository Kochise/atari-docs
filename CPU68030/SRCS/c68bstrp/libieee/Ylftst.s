#
 !	C68 12 byte floating point routine to test for zero
 !-----------------------------------------------------------------------------
 !	#1	First version based on 8 byte Ydftst_s		Dave Walker 	  12/92
 !----------------------------------------------------------------------------- 																			   

	.sect .text

	.define .Xlftst

.Xlftst:
	move.l	(sp)+,a0		! get return address
	move.l	(sp)+,d0		! first 4 bytes
	or.l	(sp)+,d0		! 2nd 4 bytes
	or.l	(sp)+,d0		! 3rd 4 bytes
	jmp 	(a0)			! return
