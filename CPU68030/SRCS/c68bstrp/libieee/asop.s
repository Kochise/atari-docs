#
 ! C68 op= support where right hand side floating point
 !                 and left hand side is integral type
 !-----------------------------------------------------------------------------
 !  #1  original version: David J. Walker                               10/95
 !-----------------------------------------------------------------------------
 !
 !  Name:       .Xasop
 !
 !  Parameters:
 !              Pointer to 'op' routine needed
 !              Pointer to 'to fp' conversion routine
 !              Pointer to 'from fp' conversion routine
 !              Pointer to LHS value
 !              Pointer to RHS value
 !              Long value encoded with size/type information as follows
 !
 !                  Byte    Description
 !                  ~~~     ~~~~~~~~~~~
 !                  0    Offset of LHS in bits (0 if not bitfield)
 !                  1    Size of LHS in bits
 !                  2    Size of RHS:  4 = float
 !                                     8 = double
 !                                     10 = long double (not yet supported)
 !                  3    Set if unsigned type, 0 if signed
 !
 !  The following assumptions are made:
 !     1. The combination of offset and size cannot be larger than 32.
 !        (i.e the value always fits into a long).
 !     2. If the address passed is odd, the combination is limited to 24.
 !---------------------------------------------------------------------------

    .sect .text

    .globl .Xsfasop
    .globl .Xdfasop
#ifdef LONG_DOUBLE
    .globl .Xlfasop
#endif /* LONG_DOUBLE */

FROMPTR     =   0+0                 ! FP to int conversion required
TOPTR       =   0+4                 ! int to FP conversion required
OPPTR       =   0+8                 ! FP routine for main operation
RTSADDR     =   0+12                ! return address back to caller
LHSPTR      =   RTSADDR+4+0
RHSPTR      =   RTSADDR+4+4
UNSIGNED    =   RTSADDR+4+8
RHSTYPE     =   RTSADDR+4+9
SIZE        =   RTSADDR+4+10
OFFSET      =   RTSADDR+4+11
PARAMSIZE   =   RTSADDR+4+12

SFSIZE      =   4                   ! size of a float
DFSIZE      =   8                   ! size of a double
LFSIZE      =   10                  ! size of a long double

SAVEREG     =   4*4                 ! size of registers saved

.Xsfasop:
        tst.b   d1                  ! signed ?
        bne     sfunsigned          ! ... NO, then jump
        pea     .Xsfltosf
        pea     .Xsftol
        bra     shared
sfunsigned:
        pea     .Xsfutosf
        pea     .Xsftoul
        bra     shared

.Xdfasop:
        tst.b   d1                  ! signed ?
        bne     dfunsigned          ! ... NO, then jump
        pea     .Xdfltodf
        pea     .Xdftol
        bra     shared
dfunsigned:
        pea     .Xdfutodf
        pea     .Xdftoul
        bra     shared

#ifdef LONG_DOUBLE
.Xlfasop:
        tst.b   d1                  ! signed ?
        bne     lfunsigned          ! ... NO, then jump
        pea     .Xlfltolf
        pea     .Xlftol
        bra     shared
lfunsigned:
        pea     .Xlfutolf
        pea     .Xlftoul
        bra     shared
#endif /* LONG_DOUBLE */

!----------------------------------------------------------------------

!   The code from this point on is common
!   regardless of the size of the RHS

shared:

!   Check address is on an even address
!   (and adjust if not)

        bclr    #0,LHSPTR+3(a7)     ! odd address ?
        beq     waseven             ! ... NO, jump
        add.b   #8,OFFSET(a7)       ! ... YES, adjust offset
waseven:

!   Get LHS value into a long

        move.l  LHSPTR(a7),a0       ! get LHS pointer value off stack
        lea     UNSIGNED(a7),a1     ! get address of unsigned.signed byte
        move.b  OFFSET(a7),d1       ! get offset to start
        move.b  SIZE(a7),d2         ! get size
        movem.l d1/d2/a0/a1,-(a7)   ! save registers we have just set up

        move.l  (a0),d0             ! get long that contains value
        lsl.l   d1,d0               ! left align field
        neg.b   d2
        add.b   #32,d2              ! 32 - size
        tst.b   (a1)                ! is value unsigned?
        bne     unsigned            ! ... YES - jump
        asr.l   d2,d0               ! move up signed value
        bra     lhsgot
unsigned:
        lsr.l   d2,d0               ! move up unsigned value
lhsgot:

!   Reserve space to store FP value
!   (assume the worst case o a long double)

        sub.w   #LFSIZE,a7          ! reserve work space to store longest result

!   Convert value to floating point

        move.l  TOPTR+SAVEREG+LFSIZE(a7),a0 ! get routine that converts to FP
        move.l  d0,-(a7)            ! push value to convert
        pea     4(a7)               ! push result area address
        jsr     (a0)                ! ... and call it

!   Do the op= FP operation

        move.l  OPPTR+LFSIZE+SAVEREG(a7),a0 ! get routine that does FP op=
        move.l  RHSPTR+LFSIZE+SAVEREG(a7),-(a7)  ! address of multiplier
        pea     4(a7)               ! address of converted value
        jsr     (a0)                ! assign/multiply

!   Convert FP back to long

        move.l  FROMPTR+LFSIZE+SAVEREG(a7),a0 ! get routine that converts from FP
        pea     (a7)                ! push address of result area
        jsr     (a0)                ! ... and call it

!   The result is now in d0.

        movem.l LFSIZE(a7),d1/d2/a0/a1   ! restore saved registers
        move.l  d0,-(a7)            ! save value on stack

        move.l  (a0),d0             ! get Long containing value
        rol.l   d1,d0               ! use offset to left align field
        lsl.l   d2,d0               ! clear bits that belong to value
        lsr.l   d2,d0               ! ... and then back again
        ror.l   d1,d0               ! back into position
        move.l  d0,(a0)             ! and store value with zero in bit field

!   Now get the bits that are to be stored in the
!   bit field into position ensuring all other
!   bits are set to zero

        move.l  (a7),d0             ! get value to be stored back off stack
        neg.b   d2                  ! negate size
        add.b   #32,d2              ! work out 32 - size
        lsl.l   d2,d0               ! move to top clearing other bits
        lsr.l   d1,d0               ! use offset to move into position

!   Finally store the new bit field value

        or.l    d0,(a0)

!   Now tidy up stack before returning to calling point
!   Remember that the RTS address is in the middle of
!   the various bits of stack contents.


        move.l  (a7)+,d0             ! get value to be stored back off stack
        move.l  LFSIZE+SAVEREG+RTSADDR(a7),a0   ! get return address
        lea     LFSIZE+SAVEREG+PARAMSIZE(a7),a7 ! remove parameters from stack
        jmp     (a0)                    ! return to caller


