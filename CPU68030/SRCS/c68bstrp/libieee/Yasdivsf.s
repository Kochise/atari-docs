#
 ! C68 /= support where right hand side floating point
 !				   and left hand side is integral type
 !-----------------------------------------------------------------------------
 !	#1	First version:	  David J. Walker								01/96
 !-----------------------------------------------------------------------------
 !
 !	Name:		.Yasdivsf
 !
 !  This is just a wrapper around the shared '.Yasopsf' routine
 !---------------------------------------------------------------------------

	.sect .text

	.define .Yasdivsf

.Yasdivsf:

    move.l  (sp)+,d0                ! pop current return address
    pea     .Ysfdiv                 ! operation wanted
    move.l  d0,-(sp)                ! push back return address
    jmp     .Yasopsf

