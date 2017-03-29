#
#ifdef HW_FPU
!       F P c h e c k . x
!
!   Routines that check for availability of FPU,
!   reserve it for use, and release it after use.
!
!

	.sect	.text

	.globl  __FPcheck
	.globl  __FPrelease

SYS_PTYP  = 0xa1
SYS_FPHW  = 0xd0
SYS_FPLK  = 0xd1
SYS_FPID  = 0xd4
SYS_FPJB  = 0xd8
SYS_FPSV  = 0xdc

!---------------------------------------------------------------------
!   _ F P c h e c k
!
!   This routine is used to check for availability of
!   the hardware FPU, and if present reserve it for use.
!
!               Input       Output
!               ~~~~~       ~~~~~~
!       D0      ?           Smashed
!       A0      ?           Smashed
!       A1      ?           Smashed
!
!   All other registers preserved
!
!   On exit condition codes (and D0) set to minus if there
!   is no hardware FPU present (or it cannot be reserved).
!---------------------------------------------------------------------

__FPcheck:
        move.l  __sys_var,a0        ! get address of system variables
        move.l  (sp)+,a1            ! get return address
        move.b  SYS_FPHW(a0),d0     ! get flag
        bmi     nofp                ! ... negative, so known to be no FPU
        beq     unsurefp            ! ... zero, so check FP
surefp:
!        trap    #0                  ! Enter supervisor mode
        bset    #7,SYS_FPLK(a0)     ! can we grab FP unit to use FP7 ?
        beq     finish              ! ... YES, exit back to caller
!        and.w   #$dfff,sr           ! ... NO, clear supervisor flag
nofp:
        move    #-1,d0              ! set condition code for no FPU
finish:
        jmp     (a1)

!   If we get here we are not sure if there is
!   hardware FP.  At the moment we simply
!   assume that there is not.

unsurefp:
        move.b  SYS_PTYP(a0),d0
        and.b   #0x0c,d0            ! are FPU bits sets?
        bne     gotfpu              ! ... YES, we have a FPU
        bset    #7,SYS_FPHW(a0)     ! ... NO, set for no FPU
        bra     nofp

gotfpu:
        lsr.b   #2,d0               ! get in least significant bits
        move.b  d0,SYS_FPHW(a0)     ! store as known FPU type
        bra     surefp              ! rejoin hardware path

!---------------------------------------------------------------------
!   _ F P r e l e a s e
!
!   This routine is used after we have finished
!   a FP operation to tidy up again.
!
!               Input       Output
!               ~~~~~       ~~~~~~
!       A0      ?           Smashed
!
!   All other registers preserved
!---------------------------------------------------------------------

__FPrelease:
        move.l  __sys_var,a0        ! get system variables address
        bclr    #7,SYS_FPLK(a0)     ! clear lock on FP7

        move.l  (sp)+,a0            ! get return address
!        and.w   #$dfff,sr          ! return to user mode
        jmp     (a0)                ! exit back to caller
#endif  /* HW_FPU */
