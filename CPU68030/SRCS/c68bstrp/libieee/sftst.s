#
 ! C68 4 byte floating point routine to test zero
 !-----------------------------------------------------------------------------
 !  #1	First version			Dave and Keith Walker		08/92
 !  #2  Changed entry/exit code for C68 v4.3 compatibility	-djw-	09/93
 !-----------------------------------------------------------------------------

	.sect .text
	.define	.Xsftst

.Xsftst:
    move.l  (sp)+,a0        ! get return address off stack
    move.l  (sp)+,a1        ! pointer to value off stack
    tst.l   (a1)            ! test it
    jmp     (a0)            ! return

