#
 !  C68 8 byte floating point routine to test for zero
 !-----------------------------------------------------------------------------
 !  #1	First version			Keith and Dave Walker		12/92
 !  #2	Changed entry/exit code for C68 v4.3 compatibility	-djw-	09/93
 !-----------------------------------------------------------------------------

	.sect .text

	.define	.Xdftst

.Xdftst:
	move.l  (sp)+,a0            ! get return address off stack
	move.l  (sp)+,a1            ! pointer to value off stack
	move.l  (a1)+,d0            ! get first half of double
	or.l    (a1),d0             ! and second half of double
	jmp     (a0)                ! return to caller

