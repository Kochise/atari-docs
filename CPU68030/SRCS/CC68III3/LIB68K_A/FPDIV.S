! FPDIV.S -- floating point divide
! Copyright = David Brooks, 1989 All Rights Reserved
!
! This version works by a normal bitwise shift/subtract loop, with separate
! handling of the exponent and a final normalization.  26 bits are computed,
! to allow one normalization and one rounding step.  A certain amount of
! black magic and handwaving are involved, but please note that at no time
! do any bits leave the confines of the computer.
!
! Round-to-even is used for the ambiguous rounding case.
!
! These  routines clobber the registers d0-d2/a0-a1. Check if this is
! compatible with your compiler!
! In the MINIX distribution, C68 fulfills this requirement. The CP/M-68K
! version of C68 even considers d0-d2/a0-a2 as scratch registers, so this
! works also.
! You will have difficulties with compiles that use less scratch registers,
! i.e. that expect one of d0-d2/a0-a1 to be unchanged across function
! calls.
! float _sfdiv(num, denom)
	.sect	.text
	.sect	.rom
	.sect	.data
	.sect	.bss
	.sect	.text
!
        .define __sfdiv
	.define	.fpdiv
__sfdiv:
.fpdiv:
        move.l  d3,a1                   ! We don't need no wimpy stack frame
        move.l	#0,d0
        move.l  4(a7),d1
        beq     exit                    ! Numerator 0 - all done
        move.l  8(a7),d2
        beq     div0                    ! Divide by 0 - overflow
        clr.b   d1                      ! Work with mantissas
        clr.b   d2
        move.l  #0x2000000,d3            ! Position of msb of 26-bit field
cmpbit:
        cmp.l   d2,d1                   ! Compare against new divisor
        bcs     nobit
        add.l   d3,d0                   ! Add in this bit
        sub.l   d2,d1                   ! and adjust
nobit:
        lsr.l   #1,d2
        lsr.l   #1,d3
        bne     cmpbit                  ! Done 26 bits?

        lsl.l   #6,d0                   ! Reposition
        tst.l   d1                      ! If there was a remainder...
        beq     doexp
        add.l   #2,d0                   ! record a memory of it.  The 2 bit
                                        ! .won't be lost by either of the
                                        ! ..subsequent normalizations
doexp:
        move.l	#0x7F,d1                 ! Calculate new exponent
        move.l  d1,d2
        and.b   7(a7),d1
        and.b   11(a7),d2
        sub.w   d2,d1
        add.w   #0x41,d1                 ! Adjust
        tst.l   d0                      ! Check for already normalized or zero
        bmi     normok
normloop:
        sub.w   #1,d1                   ! Do one normalize step (there can't
        add.l   d0,d0                   ! .be more)
normok:
        add.l   #0x80,d0                 ! Round up in most cases
        bcc     round1
        roxr.l  #1,d0                   ! The rounding caused overflow, sigh
        add.w   #1,d1
round1:
        tst.b   d0                      ! See if trailer was exactly 0x80
        bne     ckexp
        and.w   #0xFE00,d0               ! It was: round to even

ckexp:                                  ! Check exponent for sanity
        tst.w   d1
        ble     underflow
        cmp.w   #0x7F,d1
        bgt     overflow
setexp:
        move.b  d1,d0                   ! Set exponent

        move.b  7(a7),d1                ! Get signs
        move.b  11(a7),d2
        eor.b   d2,d1                   ! Form new sign
        and.b   #0x80,d1                 ! Extract it
        or.b    d1,d0
exit:
        move.l  a1,d3
        rts
div0:
overflow:
        move.l  #0xFFFFFFFF,d0
        move.l  #0x7F,d1
        bra     setexp

underflow:
        move.l  #0,d0
        bra     exit
!
	.define	.asfpdiv
.asfpdiv:
	link	a6,#0
	move.l	12(a6),-(a7)
	move.l	8(a6),a0
	move.l	(a0),-(a7)
	jsr	.fpdiv
	move.l	8(a6),a0
	move.l	d0,(a0)
	unlk	a6
	rts
