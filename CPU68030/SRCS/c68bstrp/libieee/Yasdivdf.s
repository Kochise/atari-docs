#
 ! C68 /= support where right hand side 'double' type
 !				   and left hand side is integral type
 !-----------------------------------------------------------------------------
 !	#1	First version:	  David J. Walker								01/96
 !-----------------------------------------------------------------------------
 !
 !	Name:		.Yasdivdf
 !
 !  This is just a wrapper around the shared '.Yasopdf' routine
 !---------------------------------------------------------------------------

	.sect .text

	.define .Yasdivdf

.Yasdivdf:

    move.l  (sp)+,d0                ! pop current return address
    pea     .Ydfdiv                 ! operation wanted
    move.l  d0,-(sp)                ! push back return address
    jmp     .Yasopdf

