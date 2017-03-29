#
 ! C68 4 byte floating point multiply routine
 !-----------------------------------------------------------------------------
 !      Based on _dfmul.s
 !
 !      #1      Redid register usage, and then added wrapper routine
 !      to provide C68 IEEE compatibility       Dave & Keith Walker 02/92
 !      #2      Corrected problem with corrupting D7.  Redid register
 !              useage to slightly increase effeciency.  Dave Walker            09/92
 !      #3      Changed exit code to put pointer to result in D0   Dave Walker  12/92
 !      #4      Changed entry/exit code for C68 v4.3 compatibility.
 !              Removed ACK entry points                                                                -djw-   09/93
 !      #5      Added support for hardware FPU support under QDOS               -djw-   09/95
 !-----------------------------------------------------------------------------

SAVEREG =       5*4     ! size of saved registers ons tack
BIAS4   =       0x7F - 1

        .sect .text

        .define .Xsfmul
        .define .Xassfmul

!----------------------------------------
!       sp      Return address
!       sp+4    address of result
!       sp+8    address of multiplicand
!       sp+12   address of multiplier
!----------------------------------------
.Xsfmul:
#ifdef HW_FPU
        jsr     __FPcheck               ! see if FPU present and reservable
        bne     1f                      ! ... NO, use SW version
        move.l  8(sp),a1                ! get address of multiplicand
!       FMOVE.S (a1),FP7                ! move to FP register
        dc.l    0xf2114780
        move.l  12(sp),a1               ! get address of multiplier
!       FMUL.S  (a1),FP7                ! do multiply
        dc.l    0xf21147a3
        move.l  4(sp),a0                ! get address for result
!       FMOVE.S FP7,(a0)                ! store result
        dc.l    0xf2106780
        jsr     __FPrelease             ! release FPU
        bra     mulexit
1:
#endif  /* HW_FPU */

        movem.l d2-d6,-(sp)             ! save registers
        move.l  SAVEREG+12(sp),a1       ! address of u
        move.l  (a1),d4                 ! load v
        move.l  SAVEREG+8(sp),a1        ! address of v
        move.l  (a1),d6                 ! load u
        move.l  SAVEREG+4(sp),a1        ! result address
        bsr     sfmultiply              ! do operation
        movem.l (sp)+,d2-d6             ! restore saved registers
mulexit:
        move.l  (sp)+,a0                ! get return address
        lea 12(sp),sp           ! remove 3 parameters from stack
        jmp (a0)                        ! ... and return

!----------------------------------------
!       sp      Return address
!       sp+4    address of result/multiplicand
!       sp+8    address of multiplier
!----------------------------------------
.Xassfmul:
#ifdef HW_FPU
        jsr     __FPcheck
        bne     1f
        move.l  4(sp),a0                ! get address for result/multiplicand
        move.l  8(sp),a1                ! get address of muliplier
!       FMOVE.S (a0),FP7                ! load multiplicand into FP register
        dc.l    0xf2104780
!       FMUL.S  (a1),FP7                ! do multiply
        dc.l    0xf21147a3
!       FMOVE.S FP7,(a0)                ! store result
        dc.l    0xf2106780
        jsr     __FPrelease             ! release FPU
        bra     asexit
1:
#endif /* HW_FPU */

        movem.l d2-d6,-(sp)             ! save registers
        move.l  SAVEREG+8(sp),a1        ! address of u
        move.l  (a1),d4                 ! load v
        move.l  SAVEREG+4(sp),a1        ! address of v
        move.l  (a1),d6                 ! load u
        bsr sfmultiply
        movem.l (sp)+,d2-d6             ! restore saved registers
asexit:
        move.l  (sp)+,a1                ! get return address
        move.l  (sp),d0                 ! address of v returned as result
        add.l   #8,sp                   ! remove 2 parameters from stack
        jmp (a1)                        ! ... and return

 !-------------------------------------------------------------------------
 ! This is the routine that actually carries out the operation.
 !
 ! Register usage:
 !
 !              Entry                           Exit
 !
 !      d0      ?                               undefined
 !      d1      ?                               undefined
 !      d2      ?                               undefined
 !      d3      ?                               undefined
 !      d4      v (multiplicand)                undefined
 !      d5      ?                               undefined
 !      d6      u (multiplier)                  undefined
 !
 !      A1      Address for result              preserved
 !
 !-----------------------------------------------------------------------------

sfmultiply:
        move.l  d6,d0           ! d0 = u.exp
        swap    d0
        move.w  d0,d2           ! d2 = u.sign

        move.l  d4,d1           ! d1 = v.exp
        swap    d1
        eor.w   d1,d2           ! d2 = u.sign ^ v.sign (in bit 31)

        and.l   #0x07fffff,d6   ! remove exponent from u.mantissa
        lsr.w   #7,d0
        and.w   #0x0ff,d0       ! kill sign bit
        beq 0f          ! check for zero exponent - no leading "1"
        or.l    #0x800000,d6    ! restore implied leading "1"
        bra 1f
0:      add.w   #1,d0           ! "normalize" exponent
1:      tst.l   d6              ! multiplying by zero ?
        beq retz                ! ... yes - special case - take fast route

        and.l   #0x07fffff,d4   ! remove exponent from v.mantissa
        lsr.w   #7,d1
        and.w   #0x0ff,d1       ! kill sign bit
        beq 0f          ! check for zero exponent - no leading "1"
        or.l    #0x800000,d4    ! restore implied leading "1"
        bra 1f
0:      add.w   #1,d1           ! "normalize" exponent
1:      tst.l   d4              ! multiplying by zero ?
        beq retz                ! ... yes - special case - take fast route

        add.w   d1,d0           ! add exponents,
        sub.w   #BIAS4+8,d0 ! remove excess bias, acnt for repositioning

!       Now do a 32bit x 32bit multiply to get a 64 bit result
!       see Knuth, Seminumerical Algorithms, section 4.3. algorithm M

        sub.l   #8,sp           ! reserve space on stack
        clr.l   (sp)            ! initialize 64-bit product to zero
        clr.l   4(sp)
        lea 4(sp),a0    ! address of 2nd half
        move.w  #2-1,d5
1:
        move.w  d4,d3
        mulu    d6,d3           ! multiply with digit from multiplier
        move.l  (a0),d1         ! add to result
        addx.l  d3,d1
        move.l  d1,(a0)
#ifdef QDOS
        move.w  -(a0),d3
        roxl.w  #1,d3           ! QDOS assembler does not do other form of ROXL
        move.w  d3,(a0)
#else
        roxl.w  #1,-(a0)        ! rotate carry in
#endif

        move.l  d4,d3
        swap    d3
        mulu    d6,d3
        move.l  (a0),d1         ! add to result
        addx.l  d3,d1
        move.l  d1,(a0)

        swap    d6              ! get next 16 bits of multiplier
        dbra    d5,1b

!       The next bit of code does a coarse normalisation to ensure that
!       we have enough bits to complete it in the .norm4 routine.

        movem.l 2(sp),d4/d5 ! get the 64 valid bits
2:
        cmp.l   #0x007fffff,d4  ! multiply (shift) until
        bhi 3f          !  1 in upper result bits
        cmp.w   #9,d0           ! give up for denormalized numbers
        ble 3f
        lsl.l   #8,d4           ! else rotate up by 8 bits
        rol.l   #8,d5           ! get 8 bits from d6
        move.b  d5,d4           ! ... and insert into space
        clr.b   d5              ! ... and then remove bits from running result
        sub.w   #8,d0           ! reduce exponent
        bra 2b          ! try again
3:
        move.l  d5,d1
        rol.l   #8,d1
        move.l  d1,d3           ! see if sticky bit should be set
        and.l   #0xffffff00,d3
        beq 5f
        or.b    #1,d1           ! set "sticky bit" if any low-order set
5:
        add.l   #8,sp           ! remove stack workspace
        move.l  d4,(a1)         ! save result
        jmp .Xnorm4     ! exit via normalisation routine

retz:   clr.l   (a1)            ! save zero as result
        rts                     ! no normalization needed
