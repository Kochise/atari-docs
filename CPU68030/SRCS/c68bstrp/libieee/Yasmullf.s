#
 ! C68 *= support where right hand side 'long double'
 !				   and left hand side is integral type
 !-----------------------------------------------------------------------------
 !	#1	First version:	  David J. Walker								01/96
 !-----------------------------------------------------------------------------
 !
 !	Name:		.Yasmullf
 !
 !  This is just a wrapper around the shared '.Yasoplf' routine
 !---------------------------------------------------------------------------

	.sect .text

	.define .Yasmullf

.Yasmullf:

    move.l  (sp)+,d0                ! pop current return address
    pea     .Ylfmul                 ! operation wanted
    move.l  d0,-(sp)                ! push back return address
    jmp     .Yasoplf

