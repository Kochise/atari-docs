#
 ! C68 4 byte floating point routine to test zero
 !-----------------------------------------------------------------------------
 !	#1	First version			Dave and Keith Walker		08/92
 !	#2	Changed entry/exit code for C68 v4.3 compatibility	-djw-	09/93
 !	#3	Changed for new parameter formats					-djw-	01/96
 !-----------------------------------------------------------------------------

	.sect .text
	.define .Ysftst

.Ysftst:

	move.l	(sp)+,a0		! get return address
	tst.l	(sp)+			! test it
	jmp (a0)				! return
