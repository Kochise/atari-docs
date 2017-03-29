#
 ! C68 8 byte floating point auto increment/decrement routine
 !-----------------------------------------------------------------------------
 !	#1	First version.									Dave Walker   01/96
 !-----------------------------------------------------------------------------

	.sect	.text
	.define .Ydfinc
	.define .Ydfdec
	.define __DFone

__DFone:
	.data4	0x3ff00000,0x0

!-------------------------------------------
!	   sp	   Return address
!	   sp+4    pointer to value to increment
!-------------------------------------------
.Ydfinc:
	move.l	#0,d0					! set for sign bit clear
	bra 	shared

.Ydfdec:
	move.l	#1,d0					! set for sign bit set

shared:
	move.l	4(sp),a1				! get address for value/result
	movem.l (a1),d1/d2				! load value
	movem.l d1/d2,-(sp) 			! push original value
	ror.l	#1,d0					! set sign bit if needed
	or.l	__DFone(pc),d0				! add in double constant
	move.l	__DFone+4(pc),d1
	movem.l d0/d1,-(sp) 			! Push increment/decrement value
	move.l	a1,-(sp)				! result pointer
	jsr 	.Yasdfadd				!
	movem.l (sp)+,d0/d1 			! pop original value as return value

	move.l	(sp)+,a1				! get return address
	add.l	#4,sp					! tidy stack ( 1 x pointer)
	jmp 	(a1)					! ... and return to caller

