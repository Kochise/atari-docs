#
 ! C68 support routine to do assign/op where LHS is bit field
 !-----------------------------------------------------------------------------
 !  #1  original version: David J. Walker                               01/96
 !-----------------------------------------------------------------------------
 !
 !  Name:       .Xbfget
 !
 !  Parameters:
 !              Address of bit field (LHS)
 !              short value encoded with size/type information as follows
 !
 !                  Byte    Description
 !                  ~~~~    ~~~~~~~~~~~
 !                  0      Offset of bit field in bits (0-31)
 !                  1      Size of bit field in bits   (1-32)
 !                         Top bit set if field unsigned
 !
 !              pointer to operation routine
 !              long value for RHS
 !
 !  The following assumptions are made:
 !     1. The combination of offset and size cannot be larger than 32.
 !        (i.e the value always fits into a long).
 !     2. If the address passed is odd, the combination is limited to 24.
 !
 !---------------------------------------------------------------------------

    .sect .text

    .globl .Xbfasop

VALPTR      =     4+0
CODEWORD    =     4+4
OPPTR       =     4+6
RHSVAL      =     4+10

.Xbfasop:
        move.w  CODEWORD(sp),-(sp)
        move.l  2+VALPTR(sp),-(sp)
        jsr     .Xbfget             ! get bit field into D0

        move.l  OPPTR(sp),a0        ! get operation address
        move.l  RHSVAL(sp),-(sp)    ! move across parameter
        move.l  d0,-(sp)            ! and other parameter
        jmp     (a0)                ! do op (also tidies stack) - result in d0

        move.l  d0,-(sp)
        move.w  4+CODEWORD(sp),-(sp)
        move.l  6+VALPTR(sp),-(sp)
        jsr     .Xbfput             ! store bit field

        move.l  (sp)+,a1            ! get return address
        lea     14(sp),sp           ! tidy stack (pointer+short+pointer+long)
        jmp     (a1)                ! return to caller

