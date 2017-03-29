#
 ! C68 *= support where right hand side floating point
 !                 and left hand side is integral type
 !-----------------------------------------------------------------------------
 !  #1  original version: David J. Walker                               10/95
 !-----------------------------------------------------------------------------
 !
 !  Name:       .Xasmul
 !
 !  Parameters:
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
 !  In practise, most of the hard work is done in the 'Xasop' routine
 !  that is shared by the 'Xasmul' and 'Xasdiv' routines
 !
 !---------------------------------------------------------------------------

    .sect .text

    .define .Xasmul

LHSPTR      =   4+0
RHSPTR      =   4+4
UNSIGNED    =   4+8
RHSTYPE     =   4+9
SIZE        =   4+10
OFFSET      =   4+11

.Xasmul:

!   Decide what size RHS is (and therefore
!   which set of routines to use.

        move.b  UNSIGNED(a7),d1         ! get unsigned indicator (for later)
        move.b  RHSTYPE(a7),d0          ! get type (which is also size)
        sub.b   #4,d0                   ! check for 'float'
        bne     notfloat                ! ... NO, jump
        pea     .Xassfmul               ! ... YES, set for 'float' multiply
        jmp     .Xsfasop

notfloat:
#ifdef LONG_DOUBLE
        sub.b   #4,d0                   ! check for 'double'
        bne     notdouble               ! ... NO, jump
#endif /* LONG_DOUBLE */
        pea     .Xasdfmul               ! ... YES, set for 'double' multiply
        jmp     .Xdfasop

#ifdef LONG_DOUBLE 
notdouble:
        pea     .Xaslfmul               ! set for 'long double' multiply
        jmp     .Xlfasop
#endif /* LONG_DOUBLE */

