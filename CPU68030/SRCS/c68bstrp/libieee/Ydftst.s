#
 !	C68 8 byte floating point routine to test for zero
 !-----------------------------------------------------------------------------
 !	#1	First version			Keith and Dave Walker		12/92
 !	#2	Changed entry/exit code for C68 v4.3 compatibility	-djw-	09/93
 !	#3	Changed for new parameter format					-djw-	01/96
 !-----------------------------------------------------------------------------

	.sect .text

	.define .Xdftst

.Xdftst:
	move.l	(sp)+,a0		! get return address
	move.l	(sp)+,d0		! first half
	or.l	(sp)+,d0		! 2nd half tested
	jmp 	(a0)			! return
