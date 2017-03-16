; /// MOTOROLA DSP 56001 into the amaing ATARI Falcon030 - KOSS (c) 1999 ///
; THIS IS REVISION 1.04 (19/08/99)
;
;   Once upon a time, ATARI released one of the most incredible computer of the
; World. It was during the late 1992, 1993. PC were growing more and more
; powerful, and a 486DX66 was a standard confuguration, able to display
; TrueColor pictures. The Falcon030, with only NearTrueColor display
; (64Kcolors), 16MHz, 16Bits internal bus (instead of a real 32Bits bus, what
; the MOTOROLA 68030 is able), seems to be slow, what it is. But beyon these
; lacks of power, the Falcon030 bring out something just great, a DSP ! The
; only previous machine carrying a same processor was the Next from Steve Jobs,
; more expensive (and powerful due to a 32Bits bus, 20MHz or 32MHz).
;   ATARI was always meaning music. And the Falcon030 was not the bas son of
; the computer range of the previous ST Family. Able to perform 49170Hz,
; 16Bits, real 4 StereoChannel (8 Channel !), not only in output, but also
; INPUT TOO. Most of the people had met some problem to program the DSP :
;
; - ATARI was only dealing informations to registered developers ($5000 for
;   complete registreration, a bit expensive isn't it ?)
; - MadMac and Asm56000 from MOTOROLA were just slow enough (and bugy) to
;   turn you crazy
; - DevPac DSP wasn't realy MOTOROLA compatible...
;
;   Then I decided not to wait anymore. As always, because nobody else tried to
; write something interesting on the DSP, I done it. Not all, some files came
; from different origin, but I compiled them into one, put there some
; explanation and advices.
;   The DSP, even widly used to carry out sound data, can perform 3D
; calculation, morphing, gouraud shading, Jpeg & Mpeg decoding and other
; stuffs.
;
; *****************************************************************************
; > DSP 56001 Memory Map into the ATARI Falcon030 by Hisoft (c) 1993 & KOSS (c) 1999
;
;   Side to the 68030 and its Main Memory, the DSP provide 3 differents Memory
; called P (Program Memory), X (X Data Memory) & Y (Y Data Memory). Thus you
; have to chose which memory you want to use in you program. Each Memory
; location is called WORD, composed of 3 BYTEs.
;   The DSP 56001 can access 64Kw (Kilo-DSP WORD) of each kinda Memory (P, X
; and Y), that is to say 192Kw, 589824 BYTES !!! (192*1024*3). But there is
; ONLY 32Kw in the Falcon030, shared between the 3 Memories :-| This trick
; allow you to share the datas between the differents Memories (you've to know
; that it's JUST IMPOSSIBLE accessing at the same time a Memory twice, like :
; move X:(R0)+,X:(R4)+), but be awarn not to crash datas by writing on.
;
; We'll call these 32Kw the M Memory (as Main DSP Memory)
; P:$0000 to P:$3FFF == M:$0000 to M:$3FFF : Bank Low
; P:$4000 to P:$7FFF == M:$4000 to M:$7FFF : Bank Hi
;
; X:$0000 to X:$3FFF == M:$4000 to M:$7FFF : Bank Hi
; X:$4000 to X:$7FFF == M:$4000 to M:$7FFF : Bank Hi
;
; Y:$0000 to Y:$3FFF == M:$0000 to M:$3FFF : Bank Low
; Y:$4000 to Y:$7FFF == M:$0000 to M:$3FFF : Bank Low
;
; Have difficults to see the Memory Map ? Well, let me 1 minute to draw it on
; your Screen...
;
;                                                           ,---- X:$FFFF ----,
;                                                           | Peripheral  I/O |
;                                                           | &  Control  Reg.|
;                                                           '---- X:$FFC0 ----'
; ,---- M:$7FFF ----, ,---- P:$7FFF ----, ,---- X:$3FFF ----,---- X:$7FFF ----,
; |                 | | WARNING AREA -> | | SubRoutine  BSS   <- WARNING AREA |
; |                 | |---- P:$7F00 ----| |---- X:$3F00 ----|---- X:$7F00 ----|
; |                 | | SubRoutine Load | |                                   |
; |                 | | | | | | | | | | | |                 |                 |
; |                 | | V V V V V V V V | |                                   |
; |                 | |                 | |                 |                 |
; |                 | |                 | |                                   |
; |                 | |  Off-Chip  RAM  | |  Off-Chip  RAM  |  Off-Chip  RAM  |
; |    Bank  Hi     | |    Bank  Hi     | |    Bank  Hi          Bank  Hi     |
; |                 | |                 | |                 |                 |
; |                 | |                 | |---- X:$0200 ----                  |
; |                 | |                 | |Mu & A-Law  Table|                 |
; |                 | |                 | | >CAN BE DISABLE                   |
; |                 | |                 | |---- X:$0100 ----|                 |
; |                 | |                 | |   On-Chip RAM                     |
; |                 | |                 | |                 |                 |
; + - - M:$4000 - - + + - - P:$4000 - - + '---- X:$0000 ----'---- X:$4000 ----'
; + - - M:$3FFF - - + + - - P:$3FFF - - + ,---- Y:$3FFF ----,---- Y:$7FFF ----,
; |                 | | WARNING AREA -> | | SubRoutine BSS  | <- WARNING AREA |
; |                 | |---- P:$3F00 ----| |---- Y:$3F00 ---- ---- Y:$7F00 ----|
; |                 | |                 | |                 |                 |
; |                 | |                 | |                                   |
; |                 | |  Off-Chip  RAM  | |  Off-Chip  RAM  |  Off-Chip  RAM  |
; |                 | |    Bank  Low    | |    Bank  Low         Bank  Low    |
; |                 | |                 | |                 |                 |
; |                 | | ^ ^ ^ ^ ^ ^ ^ ^ | |                                   |
; |    Bank  Low    | | | | | | | | | | | |                 |                 |
; |                 | |  Program  Load  | |                                   |
; |                 | |---- P:$0200 ----| |---- Y:$0200 ----|                 |
; |                 | | ^ Pretty Fast ^ | |    SIN Table                      |
; |                 | | | On-Chip RAM | | | >CAN BE DISABLE |                 |
; |                 | |  Program  Load  | |---- Y:$0100 ----                  |
; |                 | |---- P:$0040 ----| |   On-Chip RAM   |                 |
; |                 | |  Int.  Vectors  | |                                   |
; '---- M:$0000 ----' '---- P:$0000 ----' '---- Y:$0000 ----'---- Y:$4000 ----'
;
; WARNING AREA are caused by the SAME PHYSICAL LOCATION of the SubRoutine BSS !
; If ROM of X Memory & Y Memory are disable, you'll find Off-Chip RAM !
; On-Chip RAM have priority on Off-Chip RAM, so in Y:$0000-0040, there is not
; the Int.  Vectors of the P Memory...
;
; *****************************************************************************
; > P Memory Interrupts Description
;
;   WARNING : Interrupts ARE NOT ADDRESSES like in the 68030, but REAL INSTRUCTIONS
;             They are Inserted in the Program Flow during its Execution
;             You can ALSO put there JMP Instruction (JMP + P:$ADDR takes 2 WORDs)
;
; P:$0000 HardWare /RESET
; P:$0002 Stack Error
; P:$0004 Trace
; P:$0006 SWI   (SoftWare Interrupt)
; P:$0008 /IRQA (External)
; P:$000A /IRQB (External)
; P:$000C SSI Receive  Data
; P:$000E SSI Receive  Data with Exception Status
; P:$0010 SSI Transmit Data
; P:$0012 SSI Transmit Data with Exception Status
; P:$0014 SCI Receive  Data                       (not in the Falcon030)
; P:$0016 SCI Receive  Data with Exception Status (not in the Falcon030)
; P:$0018 SCI Transmit Data                       (not in the Falcon030)
; P:$001A SCI Idle Line                           (not in the Falcon030)
; P:$001C SCI Timer                               (not in the Falcon030)
; P:$001E NMI
; P:$0020 Host Receive  Data
; P:$0022 Host Transmit Data
; P:$0024 Host Command (Default)
; P:$0026 Available for Host Command              (Free Host Command)
; P:$0028 Available for Host Command              (Free Host Command)
; P:$002A Available for Host Command
; P:$002C Available for Host Command
; P:$002E Available for Host Command
; P:$0030 Available for Host Command
; P:$0032 Available for Host Command
; P:$0034 Available for Host Command
; P:$0036 Available for Host Command
; P:$0038 Available for Host Command
; P:$003A Available for Host Command
; P:$003C Available for Host Command
; P:$003E Illegal Instruction
;
; Short Programs should be loaded into the On-Chip RAM, quite fastest than the
; Off-Chip RAM. You can put in the On-Chip RAM fast Routine, and in the
; Off-Chip RAM (up to P:$0200) 'slow' Routine.
;
; WARNING : NOTHING about the SCI port is implemented in the Falcon030.
;           The DSP 56001 wired in is a Special Version for the Falcon030,
;           without any SCI enchancements.
;
; *****************************************************************************
; > X Memory Details
;
; DSP56001  MCU68030 Size
;
; - On-Chip Peripheral Memory Map -
; DSP56001  MCU68030 Size
; X:$0100                 Mu-Law Table (128 DSP WORDs)
;   to
; X:$017F
;----
; X:$0180                 A-Law  Table (128 DSP WORDs)
;   to
; X:$1FFF
;----
;----
; X:$FFC0                 Reserved
;   to
; X:$FFDF                 Reserved
;----
; DSP Registers are pretty useful, but there are so many things to write on, so
; read the DSP56000/1 User's Manual, all there is well explained.
;
; X:$FFE0                 PORT B - Bus  Control   Register (PBC)
; X:$FFE1                 PORT C -      Control   Register (PCC)
; X:$FFE2                 PORT B - Data Direction Register (PBDDR)
; X:$FFE3                 PORT C - Data Direction Register (PCDDR)
; X:$FFE4                 PORT B - Data           Register (PBD)
; X:$FFE5                 PORT C - Data           Register (PCD)
; X:$FFE6                 Reserved
; X:$FFE7                 Reserved
; X:$FFE8                 Host Control Register            (HCR)
; X:$FFE9                 Host Status  Register            (HSR)
; X:$FFEA                 Unused
; X:$FFEB                 Host Receive/Transmit Register   (HRX/HTX)
; X:$FFEC                 SSI Control Register A           (CRA)
; X:$FFED                 SSI Control Register B           (CRB)
; X:$FFEE                 SSI Status/Time Slot Register    (SSISR/TSR)
; X:$FFEF                 SSI Receive/Transmit Data Reg.   (RX/TX)
; X:$FFF0 not in the F030 SCI Interface Control Register   (SCR)
; X:$FFF1 not in the F030 SCI Interface Status Register    (SSR)
; X:$FFF2 not in the F030 SCI Control Register             (SCCR)
; X:$FFF3 not in the F030 SCI Transmit Data Address Reg.   (STXA)
; X:$FFF4 not in the F030 SCI Low - Rec/XMit Data Register (SRX/STX)
; X:$FFF5 not in the F030 SCI Mid - Rec/XMit Data Register (SRX/STX)
; X:$FFF6 not in the F030 SCI Hi  - Rec/XMit Data Register (SRX/STX)
; X:$FFF7                 Reserved
; X:$FFF8                 Reserved
; X:$FFF9                 Reserved
; X:$FFFA                 Reserved
; X:$FFFB                 Reserved
; X:$FFFC                 Reserved
; X:$FFFD                 Reserved
; X:$FFFE                 PORT A - Bus  Control   Register (BCR)
; X:$FFFF                 Interrupt Priority Register      (IPR)
;
; *****************************************************************************
; > Y Memory Details
;
; DSP56001  MCU68030 Size
; Y:$0100                 Four-Quadrant Sine Table (256 DSP WORDs)
;   to
; Y:$01FF
;
; *****************************************************************************
; > DSP 56001 Registers
;
;     .. are Non-Usable Memory to Prevent DSP from OverFlow
;     00 is a Byte (8 Bits)
;   0000 is a Word (16 Bits)
; 000000 is a Word (DSP WORD - 24 Bits) - Default Size -
;
; WARNING : What is following could be quite uneasy to read, but I think it's
;           the better way I found to describe you how the registers are made.
;
; /---------------- Data ALU Input Registers ----------------\
; Like Dx in the 680x0 family, but NO OPERATION ALLOWED, can ONLY keep a constant
;
; X    [  X1  ][  X0  ]                  Y    [  Y1  ][  Y0  ]
;       000000  000000                         000000  000000
; Bits [23 - 0][23 - 0]                  Bits [23 - 0][23 - 0]
;      [47     -     0]                       [47    -      0]
;
; /----------------------- Accumulator Registers -----------------------\
; Like Dx in the 680X0 family, but OPERATION ALLOWED (like Math, Logical, ...)
; These Accumulators are General Purpose Registers
;
; A          [A2][  A1  ][  A0  ]        B          [B2][  B1  ][  B0  ]
;      ...... 00  000000  000000              ...... 00  000000  000000
; Bits       [70][23 - 0][23 - 0]        Bits       [70][23 - 0][23 - 0]
;            [55       -       0]                   [55       -       0]
; then...
;
; X0  is       X0 - 24 Bits called LSP
; X1  is       X1 - 24 Bits called MSP
; X   is    X1:X0 - 48 Bits
;
; Y0  is       Y0 - 24 Bits called LSP
; Y1  is       Y1 - 24 Bits called MSP
; Y   is    Y1:Y0 - 48 Bits
;
; A0  is       A0 - 24 Bits called LSP
; A1  is       A1 - 24 Bits called MSP
; A2  is       A2 -  8 Bits called EXT
; A   is A2:A1:A0 - 56 Bits
;
; B0  is       B0 - 24 Bits called LSP
; B1  is       B1 - 24 Bits called MSP
; B2  is       B2 -  8 Bits called EXT
; B   is B2:B1:B0 - 56 Bits
;
; AB  is    A1:B1 - 48 Bits
; BA  is    B1:A1 - 48 Bits
; A10 is    A1:A0 - 48 Bits
; B10 is    B1:B0 - 48 Bits
;
; /--------------- Address Generation Unit ---------------\
; Like Ax in the 680X0 family
; Address Registers - OffSet Registers - Modifier Registers
;
; R7       ..0000 <-> N7      ..0000 <-> M7        ..0000
; R6       ..0000 <-> N6      ..0000 <-> M6        ..0000
; R5       ..0000 <-> N5      ..0000 <-> M5        ..0000
; R4       ..0000 <-> N4      ..0000 <-> M4        ..0000 Upper File
; -------------------------------------------------------
; R3       ..0000 <-> N3      ..0000 <-> M3        ..0000 Lower File
; R2       ..0000 <-> N2      ..0000 <-> M2        ..0000
; R1       ..0000 <-> N1      ..0000 <-> M1        ..0000
; R0       ..0000 <-> N0      ..0000 <-> M0        ..0000
;
; You should ever use Rn Registers with their respective Nn and Mn Registers.
; (R0+N2) is impossible, only (R0+N0) or (R2+N2) are...
; Mx (Modifier Registers) are typically used as Modulus Adressing Limitator.
;
;----
; Nx (OffSet Registers) are typically used as OffSet Table Locator.
; In a 680x0 example :
;         move.l         (A0)+,D0
; After the Instruction, the A0 Register is added with the size of the
; Operand, here 4...
; But imagine you want increase the register with 8...
; In a 5600x example :
;         move           X:(R0)+N0,B0
; With 8 in the N0 Register. Operand Size is contextual (here a DSP WORD)
;----
; Nx and Mx registers can also be used as Data Registers,
; like Dx in the 680x0 family
;
; /----------------------- Program Controller -----------------------\
; Loop Address      - Loop Counter     - Program Counter
;
; LA       ..0000     LC      ..0000     PC        ..0000
;
; Status Registers                     - Operating Mode Register
;
; SR  .. 00   00                         OMR ....   00
; |     [MR][CCR]                        |       [Mode]
; |                                      |
; +-> MR                                 |
; |     Bit 15 : LF - Loop Flag          |
; |                                      |
; |     Bit 13 : T - Trace Mode          |
; |                                      |
; |     Bit 11 : S1 \ Scaling Mode       |
; |     Bit 10 : S0 /                    |
; |     Bit  9 : I1 \ Interrupt Mask     |
; |     Bit  8 : I0 /                    |
; |                                      |
; '-> CCR                                '-> Mode
;                                              Bit  7 : EA - External Mem Access
;       Bit  6 : L - Limit                     Bit  6 : SD - Stop Delay
;       Bit  5 : E - Extension
;       Bit  4 : U - UnNormalized
;       Bit  3 : N - Negative
;       Bit  2 : Z - Zero                      Bit  2 : DE - Data ROM Enable
;       Bit  1 : V - oVerflow                  Bit  1 : MB \ Operating Mode
;       Bit  0 : C - Carry                     Bit  0 : MA /
;
; Stack Pointer
;
; SP       ..0000 -> SSH ..0000    SSL ..0000
;                        ..0000        ..0000
;                        ..0000        ..0000
;                        ..0000        ..0000
;                        ..0000        ..0000
;                        ..0000        ..0000
;                        ..0000        ..0000
;                        ..0000        ..0000
;                        ..0000        ..0000
;                        ..0000        ..0000
;                        ..0000        ..0000
;                        ..0000        ..0000
;                        ..0000        ..0000
;                        ..0000        ..0000
;                        ..0000        ..0000
;
; *****************************************************************************
; > Adressing Modes by Motorola (c) 1990
;
; - I
;   NameMove             : Immediate Short Data Move
;   Operation        : (.....),#xx->D
;   Assembler Syntax : (.....)  #xx,D
;   Description      : Move the 8-bit immediate data value (#xx) into the destination operand D.
;
;                      If the destination register D is A0, A1, A2, B0, B1, B2,
;                      Rn, or Nn, the 8-bit immediate short operand is
;                      interpreted as an unsigned integer and is stored in the
;                      specified destination regsiter. That is, the 8-bit data
;                      is stored in the eight LS bit of the destination
;                      operand, and the remaining bits of the destination
;                      operand D are zeroed.
;
;                      If the destination register D is X0, X1, Y0, Y1, A, or
;                      B, the 8-bit immediate short operand is interpreted as a
;                      signed fraction and is stored in the specified
;                      destination register. That is, the 8-bit data is stored
;                      in the eight MS bits of the destination operand, and the
;                      remaining bits of the destination operand D are zeroed.
;
;                      If the arithmetic or logical opcode-operand portion of
;                      the instruction specifies a given destination
;                      accumulator, that same accumulator or portion of that
;                      accumulator may not be specified as a destination D in
;                      the parallel data bus move operation. Thus, if the
;                      opcode-operand portion of the instruction specifies the
;                      56-bit A accumulator as its destination, the parallel
;                      data move portion of the instruction may not specify A0,
;                      A1, A2, or A as its destination D. Similary, if the
;                      opcode-operand portion of the instruction specifies the
;                      56-bit B accumulator as tis destination, the parallel
;                      data bus move portion of the instruction may not specify
;                      B0, B1, B2, or B as its destination D. That is,
;                      duplicate destinations are NOT allowed within the same
;                      instruction.
;
;               NOTE : This parallel data move is considered to be a move-type
;                      instruction. Due to pipelining, if an address register
;                      (R or N) is changed using a move-type instruction, the
;                      new contents of the destination address register will
;                      not be available for use during the following
;                      instruction (i.e., there is a single instruction cycle
;                      pipeline delay.
;
;   Example          : ABS   B  #$18,R1  ;take the absolute value of B, #$18->R1
;
;                      Before Execution:
;                      R1 = $0000
;
;                      After Execution:
;                      R1 = $0018
;
;   Explanation      : Prior to execution, the 16-bit address register R1
;                      contains the value $0000. it immediate short operand
;                      into eight LS bits of the R1 register and zeros the
;                      remaining eight MS bits of that register. The 8-bit
;                      value is intrepeted as an unsigned integer since its
;                      destination is R1 address register.
;
;   Condition Codes  : The condition codes are not affected by this type of
;                      parallel move.
;   Instruction Form : (.....)  #xx,D
;
;                               #xx = 8-bit Immediate Short Data
;                                   D = (X0, X1, Y0, Y1,
;                                        A0, B0, A2, B2, A1, B1, A, B,
;                                        Rn, Nn)
;
;   Timing           : mv oscillator clock cycles
;   Memory           : mv program words
;
; - L
;   Name             : Long Memory Data Move
;   Operation        :                                 Assembler Syntax:
;                      (...); X:ea->D1; Y:ea->D2       (...) L:ea,D
;                      (...); X:aa->D1; Y:aa->D2       (...) L:aa,D
;                      (...); S1->X:ea; S2->Y:ea       (...)   S,L:ea
;                      (...); S1->X:aa; S2->Y:aa       (...)   S,L:aa
;   Description      : Move one 48-bit long-word operand from/to X and Y
;                      memory. Two data ALU rd operand. This allows efficient
;                      moving of both double-precision (high:low) and complex
;                      (real:imaginary) data from/to one effective address in L
;                      (X:Y) memory. The same effective address is used for
;                      both the X and Y memory spaces; thus, only one effective
;                      address is required. Note that the A, B, A10 and B10
;                      operands reference a single 48-bit signed
;                      (double-precision) quantity while the X, Y, AB and BA
;                      operands reference two seperate (i.e., real and
;                      imaginary) 24-bit signed quantities. All memory
;                      alterable addressing modes may be used. Absolute short
;                      addressing may also be used.
;
;                      If the arithmetic or logical opcode-operand portion of
;                      the instruction specifies a given destination
;                      accumulator, that same accumulator or portion of that
;                      accumulator may not be specified as a destination D in
;                      the parallel data bus move operation. Thus, if the
;                      opcode-operand portion of the instruction specifies the
;                      56-bit A accumulator as its destination, the parallel
;                      data bus move portion of the instruction may not specify
;                      A, A10, AB or BA as destination D. Similary, if the
;                      opcode-operand portion of the instruction specifies the
;                      56-bit B accumulator as its destination, the parallel
;                      data bus move portion of the instruction may not specify
;                      B, B10, AB or BA as its destination D. That is,
;                      duplicate destinations are not allowed within the same
;                      instruction.
;
;                      If the opcode-operand portion of the instruction
;                      specifies a given source or destination register, that
;                      same register or portion of that register may be used as
;                      a source S in the parallel data bus move operation. This
;                      allows data to be moved in the same instruction in which
;                      it is being used as a source operand by a data ALU
;                      operation. That is, duplicate sources are allowed within
;                      the same instruction.
;
;               NOTE : The operands A10, B10, X, Y, AB and BA may be used only
;                      for a 48-bit long memory move as previously described.
;                      These operands may not be used in any other type of
;                      instruction or parallel move.
;
;   Example          : CMP   Y0, B A, L:$1234  ;compare Y0 and B, save 48-bit A1:A0 value
;
;                      Before Execution:               After Execution:
;                      A       = $01:234567:89ABCD     A       = $01:234567:89ABCD
;                      X:$1234 =           $000000     X:$1234 =           $7FFFFF
;                      Y:$1234 =           $000000     Y:$1234 =           $FFFFFF
;
;   Explanation      : Prior to execution, the 56-bit A accumulator contains
;                      the value $01:234567:89ABCD, the 24-bit X memory
;                      location X:$1234 contains the value $000000, and the
;                      24-bit Y memory location Y:$1234 contains the value
;                      $000000. The execution of the parallel move portion of
;                      the instruction, A, L:$1234 moves the 48-bit limited
;                      positive saturation constant $7FFFFF:FFFFFF into the
;                      specified long memory location by moving the MS 24 bits
;                      of the 48-bit limited positive saturation constant
;                      ($7FFFFF) into the 24-bit X memory location X:$1234 and
;                      by moving the LS 24 bits of the 48-bit limited positive
;                      saturation constant ($FFFFFF) into the 24-bit Y memory
;                      location Y:$1234 since the signed integer portion of the
;                      A accumulator was in use.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting has occured during parallel move
;
;               NOTE : The MOVE A,L:ea operation will result in a 48-bit
;                      positive or negative saturation constant being stored in
;                      the specified 24-bit X and Y memory locations if the
;                      signed integer portion ofthe A accumulator is in use.
;                      The MOVE AB, L:ea operation will result in either one of
;                      the two 24-bit positive and/or negative saturation
;                      constant(s) being stored in the specified 24-bit X
;                      and/or Y memory location(s) if the signed integer
;                      portion of the A and/or B accumulator(s) is in use.
;
;   Instruction Form : (...) L:ea,D
;                      (...) S,L:ea
;                      (...) L:aa,D
;                      (...) S,L:aa
;
;                              aa = 6-bit Absolute Short Address
;                              ea = (Rn)-Nn,
;                                   (Rn)+Nn,
;                                   (Rn)-,
;                                   (Rn)+,
;                                   (Rn),
;                                   (Rn+Nn),
;                                  -(Rn),
;                                    Absolute address
;                            S = (A10, B10, X, Y, A, B, AB, BA)
;                            D = (A10, B10, X, Y, A, B, AB, BA)
;
;   Timing           : mv oscillator clock cycles
;   Memory           : mv program words
;
; - R
;   Name             : Register to Register Data Move
;   Operation        : (.....);S->D
;   Assembler Syntax : (.....)  S,D
;   Description      : Move the source register S to the destination register D.
;
;                      If the arithmetic or logical opcode_operand portion of
;                      the instruction specifies a given destination
;                      accumulator, that same accumulator or portion of that
;                      accumulator may not be specified as a destination D in
;                      the parallel data bus move operation. Thus, if the
;                      opcode-operand portion of the instruction specifies the
;                      56-bit A accumulator as its destination, the parallel
;                      data bus move portion of the instruction may not specify
;                      A0, A1, A2, or A as its destination D. Similary, if the
;                      opcode-operand portion of the instruction specifies the
;                      56-bit B accumulator as its destination, the parallel
;                      data bus move portion of the instruction may not specify
;                      B0, B1, B2, or B as its destination D. That is,
;                      duplicate destination are NOT allowed within the same
;                      instruction.
;
;                      If the opcode-operand portion of the instruction
;                      specifies a given source or destination register, that
;                      same register or portion of that register may be used as
;                      a source S in the parallel data bus move operation. This
;                      allows data to be moved in the same instruction in which
;                      it is being used as a source operand by a data ALU
;                      operation. That is, duplicate sources are allowed within
;                      the same instruction.
;
;                      When a 24-bit source operand is moved into a 16-bit
;                      destination register, the 16 LS bits of the 24-bit
;                      source operand are stored in 16-bit destination
;                      register. When a 16-bit source operand is moved into a
;                      24-bit destination register, the 16 LS bits of the
;                      destination register are loaded with the contents of the
;                      16-bit source operand, and the eight MS bits of the
;                      24-bit destination register are zeroed.
;
;               NOTE : The MOVE A,B operation will result in a 24-bit positive
;                      or negative saturation constant being stored in the B1
;                      portion of the B accumulator if the signed integer
;                      portion of the A accumulator is in use.
;
;               NOTE : This parallel data move is considered to be a move-type
;                      instruction. Due to pipelining, if an address register
;                      (R or N) is changed using a move-type instruction, the
;                      new contents of the destination address register will
;                      not be available for use during the following
;                      instruction (i.e., there is a single instruction cycle
;                      pipeline delay).
;
;   Example          : MACR  -X0, Y0, A  Y1, N5        ; -X0*Y0+A->A, move Y1->N5
;
;                      Before execution:       After execution:
;                      Y1 = $001234            Y1 = $001234
;                      N5 =   $0000            N5 =   $1234
;
;   Explanation      : Prior to execution, the 24-bit Y1 register contains the
;                      value $001234 and the 16-bit address offset register N5
;                      contains the value $0000. The execution of the parallel
;                      move portion of the instruction, Y1,N5, moves the 16 LS
;                      bits of the 24-bit value in the Y1 register into the
;                      16-bit N5 register.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting has occured during parallel move
;
;   Instruction Form : (.....) S,D
;
;                              S = (X0, X1, Y0, Y1,
;                                   A0, B0, A2, B2, A1, B1, A, B,
;                                   Rn, Nn)
;                                D = (X0, X1, Y0, Y1,
;                                     A0, B0, A2, B2, A1, B1, A, B,
;                                     Rn, Nn)
;
;   Timing           : mv oscillator clock cycles
;   Memory           : mv program words
;
; - U
;   Name             : Address Register Update
;   Operation        : (.....); ea->Rn
;   Assembler Syntax : (.....) ea
;   Description      : Update the specified address register according to the
;                      specified effective addressing mode. All update
;                      addressing modes may be used.
;
;   Example          : RND   B  (R3)+N3        ;round value in N into B1, R3+N3->R3
;
;                      Before Execution:       After Execution:
;                      R3 = $0007              R3 = $000B
;                      N3 = $0004              N3 = $0004
;
;   Explanation      : Prior to execution, the 16-bit address register R3
;                      contains the value $0007, and the 16-bit address offset
;                      register N3 contains the value $0004. The execution of
;                      the paralle move portion of the instruction, (R3)+N3,
;                      updates the R3 address register according to the
;                      specified effective addressing mode by adding the value
;                      in the R3 register to the value in the N3 register and
;                      storing the 16-bit result back in the R3 address
;                      register.
;
;   Condition Codes  : The condition codes are not affected by this type of
;                      parallel move.
;   Instruction Form : (.....) ea
;
;                              ea = (Rn)-Nn,
;                                   (Rn)+Nn,
;                                   (Rn)-,
;                                   (Rn)+
;
;   Timing           : mv oscillator clock cycles
;   Memory           : mv program words
;
; - X:
;   Name             : X Memory Data Move
;   Operation :                                Assembler Syntax:
;               (.....); X:ea->D               (.....)  X:ea,D
;               (.....); X:aa->D               (.....)  X:aa,D
;               (.....); S->X:ea               (.....)  S,X:ea
;               (.....); S->X:aa               (.....)  S,X:aa
;               (.....); #xxxxxx->D            (.....)   #xxxxxx,D
;
;   Description      : Move the specified word operand from/to X memory. All
;                      memory addressing modes, including absolute addressing
;                      and 24-bit immediate data, may be used. Absolute short
;                      addressing may also be used.
;
;                      If the arithmetic or logical opcode-operand portion of
;                      the instruction specifies a given destination
;                      accumulator, that same accumulator or portion of that
;                      accumulator may notbe specified as destination D in the
;                      parallel data bus move operation. Thus, if the
;                      opcode-operand portion of the instruction specifies the
;                      56-bit A accumulator as its destination, the parallel
;                      data bus move portion of the instruction may not specify
;                      A0, A1, A2 or A as its destination D. Similary, if the
;                      opcode-operand portion of the instruction specifies the
;                      56-bit B accumulator as its destination, the parallel
;                      data bus move portion of the instruction may not specify
;                      B0, B1, B2 or B as its destination D. That is, duplicate
;                      destinations are NOT allowed within the same
;                      instruction. If the opcode-operand portion of the
;                      instruction specifies a given source or destination
;                      register, that same register or portion of that register
;                      may be used as a source S in the parallel data bus move
;                      operation. This allows data to be moved in the same
;                      instruction in which it is being used as a source
;                      operand by data ALU operation. That is, duplicate
;                      sources are allowed within the same instruction.
;
;                      When a 24-bit source operand is moved ino a 16-bit
;                      destination register, the 16 LS bits of the 24-bit
;                      source operand are stored in the 16-bit destination
;                      register. When a 16-bit source operand is moved into a
;                      24-bit destination register, the 16LS bits of the
;                      destination register are loaded with the contents of the
;                      16-bit source operand, and the eight MS bits of the
;                      24-bit destination register are zeroed.
;
;               NOTE : This parallel data move is considered to be a move-type
;                      instruction. Due to pipelining, if an address register
;                      (R or N) is changed using a move-type instruction, the
;                      new contents of the destination address register will
;                      not be available for use during the following
;                      instruction (i.e., there is a single instruction cycle
;                      pipeline delay).
;
;   Example          : ASL   A  R2, X:-(R2)    ; A*2->A, save updated R2 in X:(R2)
;
;                      Before Execution:       After Execution:
;                      R2      =   $1001       R2      =   $1000
;                      X:$1000 = $000000       X:$1000 = $001000
;
;   Explanation      : Prior to execution, the 16-bit R2 address register
;                      contains the value $1001, and the 24-bit X memory
;                      location X:$1000 contains the value $000000. The
;                      execution of the parallel move portion of the
;                      instruction, R2, X:-(R2), predecrements the R2 address
;                      register and then uses the R2 address register to move
;                      the updated contents of the R2 address register into the
;                      24-bit X memory location X:$1000.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting has occured during parallel move
;
;               NOTE : The MOVE A, X:ea operation will result in a 24-bit
;                      positive or negative if the signed integer portion of
;                      the A accumulator is in use.
;
;   Instruction Form : (.....)  X:ea,D
;                      (.....)  S,X:ea
;                      (.....)  #xxxxxx,D
;                      (.....)  X:aa,D
;                      (.....)  S,X:aa
;
;                               #xxxxxx = 24-bit Immediate Data
;                                 aa = 6-bit Absolute Short Address
;                                 ea = (Rn)-Nn,
;                                      (Rn)+Nn,
;                                      (Rn)-,
;                                      (Rn)+,
;                                      (Rn)
;                                      (Rn+Nn),
;                                     -(Rn),
;                                      Absolute address
;                               S = (X0, X1, Y0, Y1,
;                                    A0, B0, A2, B2, A1, B1, A, B,
;                                    Rn, Nn)
;                                    D = (X0, X1, Y0, Y1,
;                                         A0, B0, A2, B2, A1, B1, A, B,
;                                         Rn, Nn)
;
;   Timing           : mv oscillator clock cycles
;   Memory           : mv program words
;
; - X:R
;   Name             : X Memory and Register Data Move
;   Operation        :                                 Assembler Syntax:
;              Class I                                 Class I
;                      (...);   X:ea->D1; S2->D2               (...) X:ea, D1 S2,D2
;                      (...);   S1->X:ea; S2->D2               (...) S1, X:ea S2,D2
;                      (...);   #xxxxxx->D1; S2->D2            (...) #xxxxxx,D1  S2,D2
;
;             Class II                                Class II
;                      (...);   A->X:ea; X0->A                 (...) A,X:ea   X0,A
;                      (...);   B->X:ea; X0->B                 (...) B,X:ea   X0,B
;
;   Description      :
;            Class I : Move a one-word operand from/to X memory and move
;                      another word operand from an accumulator (S2) to an
;                      input register (D2). All memory addressing modes,
;                      including absolute addressing and 24-bit immediate data,
;                      may be used. The register to register move (S2, D2)
;                      allows data to be moved to data ALU input register for
;                      use as a data ALU operand in the following instruction.
;
;           Class II : Move one-word operand from a data ALU accumulator to X
;                      memory and one-word operand from data ALU register X0 to
;                      a data ALU accumulator. One effective address is
;                      specified. All memory addressing modes, excluding long
;                      absolute addressing and long immediate data, may be
;                      used.
;
;                      For both Class I and Class II X:R parallel data moves,
;                      if the arithmetic or logical opcode-operand portion of
;                      the instruction specifies a given destination
;                      accumulator, that same accumulator or portion of that
;                      accumulator may not be specified as a destination D1 in
;                      the parallel data bus move operation. Thus, if the
;                      opcode-operand portion of the instruction specifies the
;                      56-bit A accumulator as its destination, the parallel
;                      data bus move portion of the instruction may not specify
;                      A0, A1, A2 or A as its destination D1. Similary, if the
;                      opcode-operand portion of the instruction specifies the
;                      56-bit B accumulator as its destination, the parallel
;                      data bus move portion of the instruction may not specify
;                      B0, B1, B2 or B as its destination D1. That is,
;                      duplicate destination are NOT allowed within the same
;                      instruction.
;
;                      If the opcode-operand portion of the instruction
;                      specifies a given source or detsination register, that
;                      same register or portion of that register may be used as
;                      a source S1 and/or S2 in the parallel data bus move
;                      operation. This allows data to be moved in the parallel
;                      data bus move operation. This allows data to be moved in
;                      the same instruction in which it is being used as a
;                      source operand by data ALU operation. That is,
;                      duplication sources are allowed within the same
;                      instruction. Note that S1 and S2 may specify the same
;                      register.
;
;   Class I Example  : CMPM  Y0, A A, X:$1234   A, Y0  ; compare A,Y0 mag., save A, update Y0
;
;                      Before Execution:               After Execution:
;                      A       = $00:800000:000000     A       = $00:800000:000000
;                      X:$1234 =           $000000     X:$1234 =           $7FFFFF
;                      Y0      =           $000000     Y0      =           $7FFFFF
;
;   Explanation C.I  : Prior to executio, the 56-bit A accumulator contains the
;                      value $00:800000:00000, the 24-bit X memory location
;                      X:$1234 contains the value $000000, and the 24-bit Y0
;                      regsiter contains the value $00000. The execution of the
;                      parallel move portion of the instruction, A,X:$1234 A,
;                      Y0 moves the 24-bit limited positive saturation constant
;                      $7FFFFF into both the X:$1234 memory location and the Y0
;                      register since the signed portion of the A accumulator
;                      was in use.
;
;   Class II Example : MAC   X0, Y0, A   B,X:(R1)+   X0, B     ; multiply X0 and Y0 accumulate in A
;                                                              ; move B to X memory location pointed to
;                                                              ; by R1 and postincrement R1
;                                                              ; move X0 to B
;
;                      Before Execution:               After Execution:
;                      X0      =           $400000     X0      =           $400000
;                      Y0      =           $600000     Y0      =           $600000
;                      A       = $00:000000:000000     A       = $00:300000:000000
;                      B       = $FF:7FFFFF:000000     B       = $00:400000:000000
;                      X:$1234 =           $000000     X:$1234 =           $800000
;                      R1      =             $1234     R1      =             $1235
;
;   Explanation C.II : Prior to execution, the 24-bit registers X0 and Y0
;                      contain $400000 and $600000, respectively. The 56-bit
;                      accumulators A and B contain the values
;                      $00:000000:000000 and $FF:7FFFFF:000000, respectively.
;                      The 24-bit X memory location X:$1234 contains the value
;                      $000000, and the 16-bit R1 regsiter contains the value
;                      $1234. Execution of the parallel move portion of the
;                      instruction (B, X:(R1)+ X0,B) moves the 24-bit limited
;                      value of B ($800000) into the X:$1234 memory location
;                      and the X0 register ($400000) into accumulator B1
;                      ($400000), sign extends B1 into B2 ($00), and zero fills
;                      B0 ($000000). It also increments R1 to $1235.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting has occured during parallel move
;
;   C.I Instru Form  : (.....)  X:ea, D1 S2, D2
;                      (.....)  S1, X:ea S2, D2
;                      (.....)  #xxxxxx, D1 S2, D2
;
;                               #xxxxxx = 24-bit Immediate Data
;                                 ea = (Rn)-Nn,
;                                      (Rn)+Nn,
;                                      (Rn)-,
;                                      (Rn)+,
;                                      (Rn),
;                                      (Rn+Nn),
;                                     -(Rn),
;                                      Absolute address
;                               S1 = (X0, X1, A, B)
;                                     D1 = (X0, X1, A, B)
;                                        S2 = (A, B)
;                                            D2 = (Y0, Y1)
;
;   C.II Instru Form : (.....)  A, X:ea  X0, A
;                      (.....)  B, X:ea  X0, B
;
;                                    ea = (Rn)-Nn,
;                                         (Rn)+Nn,
;                                         (Rn)-,
;                                         (Rn)+,
;                                         (Rn),
;                                         (Rn+Nn),
;                                        -(Rn),
;                                         Absolute address
;
;   Timing           : mv oscillator clock cycles
;   Memory           : mv program words
;
; - X:Y:
;   Name             : X Y Memory Data Move
;   Operation        :                                         Assembler Syntax:
;                      (...); X:<eax>->D1; Y:<eay>->D2         (...) X:<eax>, D1 Y:<eay>, D2
;                      (...); X:<eax>->D1; S2->Y:<eay>         (...) X:<eax>, D1 S2, Y:<eay>
;                      (...); S1->X:<eax>; Y:<eay>->D2         (...) S1, X:<eax> Y:<eay>, D2
;                      (...); S1->X:<eax>; S2->Y:<eay>         (...) S1, X:<eax> S2, Y:<eay>
;
;   Description      : Move one-word operand from/to X memory and move another
;                      word operand from/to Y memory. Note that two independent
;                      effective addresses are specified (<eax> and <eay>)
;                      where one of the effective addresses uses the lower bank
;                      of address registers (R0-R3) while the other effective
;                      address uses the upper bank of address registers
;                      (R4-R7). All parallel addressing modes may be used.
;
;                      If the arithmetic or logical opcode-operand portion of
;                      the instruction specifies a given destination
;                      accumulator, that same accumulator or portion of that
;                      accumulator may not be specified as a destination D1 or
;                      D2 in the parallel data bus move operation. Thus, if the
;                      opcode-operand portion of the instruction specifies the
;                      56-bit A accumulator as its destination, the parallel
;                      data bus move portion of the instruction may not specify
;                      A as its destination D1 or D2. Similary, if the
;                      opcode-operand portion of the instruction specifies the
;                      56-bit B accumulator as its destination, the parallel
;                      data bus move portion of the instruction may not specify
;                      B as its destination D1 or D2. That is, duplicate
;                      destinations are NOT allowed within the same
;                      instruction. D1 and D2 may not specify the same
;                      register.
;
;                      If the opcode-operand portion of the instruction
;                      specifies a given source or destination register, that
;                      same register or portion of that register may be used as
;                      a source S1 and/or S2 in the parallel data bus move
;                      operation. This allows data to be moved in the same
;                      instruction in which it is being used as a source
;                      operand by data ALU operation. That is, duplicate
;                      sources are allowed within the same instruction. Note
;                      that S1 and S2 may specify the same register.
;
;   Example          : MPYR X1, Y0, A X1, X:(R0)+ Y0, Y:(R4)+N4        ;X1*Y0->A, save X1 and Y0
;
;                      Before Execution:       After Execution:
;                      X1      = $123123       X1      = $123123
;                      Y0      = $456456       Y0      = $456456
;                      R0      =   $1000       R0      =   $1001
;                      R4      =   $0100       R4      =   $0123
;                      N4      =   $0023       N4      =   $0023
;                      X:$1000 = $000000       X:$1000 = $123123
;                      Y:$0100 = $000000       Y:$0100 = $456456
;
;   Explanation      : Prior to execution, the 24-bit X1 register contains the
;                      value $123123, the 24-bit Y0 register contains the value
;                      $456456, the 16-bit R0 address register contains the
;                      value $1000, the 16-bit R4 address register contains the
;                      value $0100, the 16-bit N4 address offset register
;                      contains the value $000000, the 24-bit X memory location
;                      X:$1000 contains the value $000000, and the 24-bit Y
;                      memory location Y:$0100 contains the value $000000. The
;                      execution of the parallel move portion of the
;                      instruction, X1, X:(R0)+ Y0, Y:(R4)+N4, moves the 24-bit
;                      value in the X1 register into the 24-bit X memory
;                      location X:$1000 using the 16-bit R0 address register,
;                      moves the 24-bit value in the Y0 register into the
;                      24-bit Y memory location Y:$0100 using the 16-bit R4
;                      address register, updates the 16-bit value in the R0
;                      address register, and updates the 16-bit R4 address
;                      register using the 16-bit value in the R0 address
;                      register, and updates the 16-bit R4 address register
;                      using the 16-bit N4 address offset register. The
;                      contents of the N4 address offset register are not
;                      affected.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting has occured during parallel move
;
;               NOTE : The MOVE A,X:<eax> B,Y:<eay> operation will result in
;                      one or two 24-bit positive and/or negative saturation
;                      constant(s) being stored in the specified 24-bit X
;                      and/or Y memory locations if the signed integer portion
;                      of the A and/or B accumulator(s) is in use.
;
;   Instruction Form : (...) X:<eax>, D1 Y:<eay>, D2
;                      (...) X:<eax>, D1 S2, Y:<eay>
;                      (...) S1, X:<eax> Y:<eay>, D2
;                      (...) S1, X:<eax> S2, Y:<eay>
;
;                               eax = (Rn)+Nn,
;                                     (Rn)-,
;                                     (Rn)+,
;                                     (Rn)
;                                           eay = (Rn)+Nn,
;                                                 (Rn)-,
;                                                 (Rn)+,
;                                                 (Rn)
;                            S1 = (X0, X1, A, B)
;                                     D1 = (X0, X1, A, B)
;                                        S2 = (Y0, Y1, A, B)
;                                                 D2 = (Y0, Y1, A, B)
;
;   Timing           : mv oscillator clock cycles
;   Memory           : mv program words
;
; - Y:
;   Name             : Y Memory Data Move
;   Operation        :                         Assembler Syntax:
;                      (.....); Y:ea->D        (.....) Y:ea,D
;                      (.....); Y:aa->D        (.....) Y:aa,D
;                      (.....); S->Y:ea        (.....) S, Y:ea
;                      (.....); S->Y:aa        (.....)   S, Y:aa
;                      (.....); #xxxxxx->D     (.....)  #xxxxxx,D
;
;   Description      : Move the specified word operand from/to Y memory. All
;                      memory addressing modes, including absolute addressing
;                      and 24-bit immediate data, may be used. Absolute short
;                      addressing may also be used.
;
;                      If the arithmetic or logical opcode-operand portion of
;                      the instruction specifies a given destination
;                      accumulator, that same accumulator or portion of that
;                      accumulator may notbe specified as destination D in the
;                      parallel data bus move operation. Thus, if the
;                      opcode-operand portion of the instruction specifies the
;                      56-bit A accumulator as its destination, the parallel
;                      data bus move portion of the instruction may not specify
;                      A0, A1, A2 or A as its destination D. Similary, if the
;                      opcode-operand portion of the instruction specifies the
;                      56-bit B accumulator as its destination, the parallel
;                      data bus move portion of the instruction may not specify
;                      B0, B1, B2 or B as its destination D. That is, duplicate
;                      destinations are NOT allowed within the same
;                      instruction.
;
;                      If the opcode-operand portion of the instruction
;                      specifies a given source or destination register, that
;                      same register or portion of that register may be used as
;                      a source S in the parallel data bus move operation. This
;                      allows data to be moved in the same instruction in which
;                      it is being used as a source operand by data ALU
;                      operation. That is, duplicate sources are allowed within
;                      the same instruction.
;
;                      When a 24-bit source operand is moved ino a 16-bit
;                      destination register, the 16 LS bits of the 24-bit
;                      source operand are stored in the 16-bit destination
;                      register. When a 16-bit source operand is moved into a
;                      24-bit destination register, the 16LS bits of the
;                      destination register are loaded with the contents of the
;                      16-bit source operand, and the eight MS bits of the
;                      24-bit destination register are zeroed.
;
;               NOTE : This parallel data move is considered to be a move-type
;                      instruction. Due a move-type instruction, the new
;                      contents of the destination address register will not be
;                      available for use during the following instruction
;                      (i.e., there is a single instruction cycle pipeline
;                      delay).
;
;   Example          : EOR   X0,B  #$123456,A  ;exclusive OR X0 and B, update A accumulator
;
;                      Before Execution:       After Execution:
;                      A = $FF:FFFFFF:FFFFFF   A = $00:123456:000000
;
;   Explanation      : Prior to execution, the 56-bit A accumulator contains
;                      the value $FF:FFFFFF:FFFFFF. The execution of the
;                      parallel move portion of the instruction, #$123456, A
;                      moves the 24-bit immediate value $123456 into the 24-bit
;                      A1 register, then sign extends that value into the A2
;                      portion of the accumulator, and zeros the lower 24-bit
;                      A0 portion of the accumulator.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting has occured during parallel move
;
;               NOTE : The MOVE A, Y:ea operation will result in a 24-bit
;                      positive or negative saturation constant being stored in
;                      the specified 24-bit X memory if the signed integer
;                      portion of the A accumulator is in use.
;
;   Instruction Form : (.....)  Y:ea, D
;                      (.....)  S, Y:ea
;                      (.....)  #xxxxxx, D
;                      (.....)  Y:aa, D
;                      (.....)  S, Y:aa
;
;                               #xxxxxx = 24-bit Immediate Data
;                                 aa = 6-bit Absolute Short Address
;                                 ea = (Rn)-Nn,
;                                      (Rn)+Nn,
;                                      (Rn)-,
;                                      (Rn)+,
;                                      (Rn),
;                                      (Rn+Nn),
;                                     -(Rn),
;                                      Absolute address
;                               S = (X0, X1, Y0, Y1,
;                                    A0, B0, A2, B2, A1, B1, A, B,
;                                    Rn, Nn)
;                                     D = (X0, X1, Y0, Y1,
;                                          A0, B0, A2, B2, A1, B1, A, B,
;                                          Rn, Nn)
;
;   Timing           : mv oscillator clock cycles
;   Memory           : mv program words
;
; - R:Y
;   Name             : Register and Y Memory Data Move
;   Operation        :                                 Assembler Syntax:
;              Class I                                 Class I
;                      (...); S1->D1; Y:ea->D2                 (...) S1,D1 Y:ea,D2
;                      (...); S1->D1; S2->Y:ea                 (...) S1,D1 S2,Y:ea
;                      (...); S1->D1; #xxxxxx->D2              (...) S1,D1   #xxxxxx,D2
;
;             Class II                                Class II
;                      (...); Y0->A; A->Y:ea                   (...) Y0,A  A,Y:ea
;                      (...); Y0->B; B->Y:ea                   (...) Y0,B  B,Y:ea
;
;   Description      :
;            Class I : Move a one-word operand from an accumulator (S1) to an
;                      input register (D1) and move another word operand
;                      from/to Y memory. All memory addressing modes, including
;                      absolute addressing and 24-bit immediate data, may be
;                      used. The register to register move (S1, D1) allows a
;                      data ALU accumulator to be moved to a data ALU input
;                      register for use as a data ALU accumulator to be moved
;                      to a data ALU input register for use as a data ALU
;                      operand in the following instruction.
;
;           Class II : Move one-word operand from a data ALU accumulator to Y
;                      memory and one-word operand from data ALU register Y0 to
;                      a data ALU accumulator. One effective address is
;                      specified. All memory addressing modes, excluding long
;                      absolute addressing and long immediate data, may be
;                      used. Class II move operations have been added to the
;                      R:Y parallel move (and a similar feature has been added
;                      to the X:R parallel move) as an added feature available
;                      in the first quarter of 1989.
;
;                      For both Class I and Class II R:Y parallel data moves,
;                      if the arithmetic or logical opcode-operand portion of
;                      teh instruction specifies a given destination
;                      accumulator, that same accumulator or portion of that
;                      accumulator may not be specified as a destiation D2 in
;                      the parallel data bus move operation. Thus, if the
;                      opcode-operand portion of the instruction specifies the
;                      56-bit A accumulator as its destination, the parallel
;                      data bus move portion of the instruction may not specify
;                      A0, A1, A2 or A as its destination D2. Similary, if the
;                      opcode-operand portion of the parallel data bus move
;                      portion of the instruction may not specify B0, B1, B2 or
;                      B as its destination D2. That is, duplicate destinations
;                      are NOT allowed within the same instruction.
;
;                      If the opcode-operand portion of the instruction
;                      specifies a given source or source S1 and/or S2 in the
;                      parallel data bus move operation. This allows data to be
;                      moved in the parallel data bus move operation. This
;                      allows data to be moved in the same instruction in which
;                      it is being used as a source operand by data ALU
;                      operation. That is, duplication sources are allowed
;                      within the same instruction. Note that S1 and S2 may
;                      specify the same register.
;
;   Class I Example  : ADDL  B, A  B, X1 Y:(R6)-N6, B  ;2*A+B->A, update X1, B and R6
;
;                      Before Execution:               After Execution:
;                      B       = $80:123456:789ABC     B       = $00:654321:000000
;                      X1      =           $000000     X1      =           $800000
;                      R6      =             $2020     R6      =             $2000
;                      N6      =             $0020     N6      =             $0020
;                      Y:$2020 =           $654321     Y:$2020 =           $654321
;
;   Explanation C.I  : Prior to execution, the 56-bit B accumulator contains
;                      the value $80:123456:789ABC, the 24-bit X1 register
;                      contains the value $000000, the 16-bit R6 address
;                      register contains the value $2020, the 16-bit N6 address
;                      offset register contains the value $654321. The
;                      execution of the parallel move portion of the
;                      instruction, B, X1 Y:(R6)-N6, B moves the 24-bit limited
;                      negative saturation constant $800000 into the X1
;                      register since the signed integer portion of the B
;                      accumulator was in use, uses the value in the 16-bit R6
;                      address register to move the 24-bit value in the Y
;                      memory location Y:$2020 into the 56-bit B accumulator
;                      (B2) and automatic zeroing of the lower portion of the
;                      accumulator (B0), and finally uses the contents of the
;                      16-bit R6 address register. The contents of the N6
;                      address offset register are not affected.
;
;   Class II Example : MAC   X0, Y0, A   Y0, B    B, Y:(R1)+   ; multiply X0 and Y0 and accumulate in
;                                                              ; A move B to Y memory location pointed
;                                                              ; to by R1 and postincrement R1 move Y0 to B
;
;                      Before Execution:               After Execution:
;                      X0      =           $400000     X0      =           $400000
;                      Y0      =           $600000     Y0      =           $600000
;                      A       = $00:000000:000000     A       = $00:300000:000000
;                      B       = $00:800000:000000     B       = $00:600000:000000
;                      Y:$1234 =           $000000     Y:$1234 =           $7FFFFF
;                      R1      =             $1234     R1      =             $1235
;
;   Explanation C.II : Prior to execution, the 24-bit registers, X0 and Y0,
;                      contain $400000 and $600000, respectively. The 56-bit
;                      accumulators A and B contain the values
;                      $00:000000:000000 and $00:800000:000000 (+1.0),
;                      respectively. The 24-bit Y memory location Y:$1234
;                      contains the value $000000, and the 16-bit R1 register
;                      contains the value $1234. Execution of the parallel move
;                      portion of the instruction (Y0, B B, Y:(R1)+) moves the
;                      Y0 register ($600000) into accumulator B1 ($600000),
;                      sign extends B1 into B2 ($00), and zero fills B0
;                      ($000000). It also moves the 24-bit limited value of B
;                      ($7FFFFF) into the Y:$1234 memory location and
;                      increments R1 to $1235.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting has occured during parallel move
;
;   C.I Instrui Form : (...) S1, D1   Y:ea, D2
;                      (...) S1, D1   S2, Y:ea
;                      (...) S1, D1   #xxxxxx, D2
;
;                                     #xxxxxx = 24-bit Immediate Data
;                                       ea = (Rn)-Nn,
;                                            (Rn)+Nn,
;                                            (Rn)-,
;                                            (Rn)+,
;                                            (Rn),
;                                            (Rn+Nn),
;                                           -(Rn),
;                                             Absolute address
;                            S1 = (A, B)
;                                D1 = (X0, X1)
;                                     S2 = (Y0, Y1, A, B)
;                                           D2 = (Y0, Y1, A, B)
;
;   C.II Instru Form : (...) Y0, A A, Y:ea
;                      (...) Y0, B B, Y:ea
;
;                                       ea = (Rn)-Nn, (Rn)+Nn, (Rn) (Rn)+,
;                                               (Rn), (Rn+Nn), -(Rn), Absolute address
;
;   Timing           : mv oscillator clock cycles
;   Memory           : mv program words
;
; Operand Reference are : P  for Program Memory
;                         X  for X Data  Memory
;                         Y  for Y Data  Memory
;                         L  for Long Move
;                         XY for XY      Memory
;
;   All the Addressing Modes uses the Mx Modifier Register, except to the No
;   Update Addressing Mode...
;
; - No Update (Mx not used)
;   Operand Reference Allowed : P X Y L XY
;   Assembler Syntax          : (Rx)
;   Example                   : move    A1,X:(R0)
;                                                 with A  = 01:234567:89ABCD
;                                                      R0 = $1000
;                                                      N0 = Don't Care
;                                                      M0 = $FFFF (Default)
;
;                               After execution, X:$1000 = $234567
;
; - PostIncrement by 1
;   Operand Reference Allowed : P X Y L XY
;   Assembler Syntax          : (Rx)+
;   Example                   : Same as above, but AFTER execution, R0 = $1001
;
; - PostDecrement by 1
;   Operand Reference Allowed : P X Y L XY
;   Assembler Syntax          : (Rx)-
;   Example                   : Same as above, but AFTER execution, R0 = $0FFF
;
; - PostIncrement by OffSet Nx
;   Operand Reference Allowed : P X Y L XY
;   Assembler Syntax          : (Rx)+Nx
;   Example                   : move    A1,X:(R0)+N0
;                                                 with A  = 01:234567:89ABCD
;                                                      R0 = $1000
;                                                      N0 = 4
;                                                      M0 = $FFFF (Default)
;
;                               AFTER execution, X:$1000 = $234567
;                                                     R0 = $1004
;
; - PostDecrement by OffSet Nx
;   Operand Reference Allowed : P X Y L
;   Assembler Syntax          : (Rx)-Nx
;   Example                   : Same as above, but AFTER execution, R0 = $0FFC
;
; - Indexed       by OffSet Nx
;   Operand Reference Allowed : P X Y L
;   Assembler Syntax          : (Rx+Nx)
;   Example                   : move    A1,X:(R0)+N0
;                                                 with A  = 01:234567:89ABCD
;                                                      R0 = $1000
;                                                      N0 = 4
;                                                      M0 = $FFFF (Default)
;
;                               AFTER execution, X:$1004 = $234567 !!
;                                                     R0 = $1000   !! Unchanged
;
; - PreDecrement  by 1
;   Operand Reference Allowed : P X Y L
;   Assembler Syntax          : -(Rx)
;   Example                   : Same as PostDecrement, but BEFORE execution, R0 = $0FFF
;   WARNING                   : Slower than PostDecrement !
;
; *****************************************************************************
; > Syntax Structure - Motorola (c) 1990
;
;                                     /--- Parallel Moves ---\
; Label       OpCode  <-  Operands || XBD         YDB
; Test        MAC         X0,Y0,A     X:(R0)+,X0  Y:(R4)+N4,Y0
;
; What the DSP do in the e.g. :
;  1- (X0*Y0)+A -> A
;  2- (R0) from X memory -> X0
;  3- R0+1 -> R0
;  4- (R4) from Y memory -> Y0
;  5- R4+N4 -> R4
;
; NOTE : Because of the // Addressing System, the X Memory Bus is already used,
;        then it's just impossible to access twice the X Memory. So // moves
;        are ALWAYS in differents Memories (here X & Y, but P possible).
;
; KOSS : Hum, well, nor really true. Ok on a 192Kw based configuration, but is
;        the ATARI Falcon030, due to the special memory management, you should
;        NOT access the same Physical Bank (Low or High) at the same time. To
;        perform some good work, look at the memory Map on the top of this
;        superb file ;))
;
; *****************************************************************************
; > Arithmetic Instructions - Motorola (c) 1990
;
; - ABS
;   Name             : Absolute Value
;   Operation        : |D|->D   (parallel move)
;   Assembler Syntax : ABS  D   (parallel move)
;   Beschreibung     : Ermittelt den absoluten Wert des Operanden D und legt
;                      das Ergebnis im Accumulator ab.
;                      Take the absolute value of the destination operand D and
;                      store the result in the destination accumulator.
;
;   Beispiel         : ABS A #$123456, X0    A, Y0     ; Berechnet den absoluten Wert
;
;                      Vor der AusfÅhrung  : A = $FF:FFFFFF:FFFFF2
;                      Nach der AusfÅhrung : A = $00:000000:00000E
;
;   Beschreibung     : Vor der AusfÅhrung enthÑlt der 56-Bit-Akku den negativen
;                      Wert $FF:FFFFFF:FFFFF2. Der Befehl ABS berechnet das
;                      Zweierkomplement des Wertes und gibt $00:000000:00000E
;                      zurÅck.
;   Hinweis          : FÅr den Fall, das der Operand D gleich $80:000000:000000
;                      ( -256.0) ist, tritt bei ABS ein öberlauf auf, da das
;                      Ergebnis For the case in which the D operand equals
;                      $80:000000:000000 ( -256.0), the ABS instruction will
;                      cause an overflow to occur since the result cannot be
;                      correctly expressed using the standard 56-bit,
;                      fixed-point, twos-complement data representation. Data
;                      limiting does not occur (i.e., A is not set to the
;                      limiting value of $7F:FFFFFF:FFFFFF).
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if limiting (parallel move) or overflow has occured in result
;                      E  Set if the signed integer portion of A or B result is in use
;                      U  Set if A or B result is unnormalized
;                      N  Set if bit 55 of A or B is set
;                      Z  Set if A or B result equals zero
;                      V  Set if overflow has occured in A or B result
;
;                   NOTE: The definition of the E and U bits varies according
;                         to the scaling mode being used.
;
;   Instruction Form : ABS   D
;
;                            D = (A, B)
;
;   Timing           : 2+mv oscillator clock cycles
;   Memory           :     1+mv programs words
;
; - ADC
;   Name             : Add Long with Carry
;   Operation        : S+C+D -> D      (parallel move)
;   Assembler Syntax : ADC  S, D       (parallel move)
;   Beschreibung     : Add the source operand S and the carry bit C of the
;                      condition code register to the destination operand D and
;                      store the result in the destination accumulator. Long
;                      words (48 bits) may be added to the (56-bit) destination
;                      accumulator.
;
;               NOTE : The carry bit is set correctly for multiple precision
;                      arithmetic using long word operands if the extension
;                      register of the destination accumulator (A2 or B2) is
;                      the sign extension of bit 47 of the destination
;                      accumulator (A or B).
;
;   Beispiel         : MOVE    L:<$0, X                ; get a 48-bit LS long-word operand in X
;                      MOVE    L:<$1, A                ; get other LS long word in A (Sing ext.)
;                      MOVE    L:<$2, Y                ; get a 48-bit MS long-word operand in Y
;                      ADD     X,A    L:<$3, B         ; add LS words; get other MS word in B
;                      ADC     Y,B    A10, L:<$4       ; add MS words with carry, save LS sum
;                      MOVE    B10,   L:<$5            ; save MS sum
;
;                      Before Execution:       After Execution:
;                      A = $FF:800000:000000   A = $FF:000000:000000
;                      X =    $800000:000000   X =    $800000:000000
;                      B = $00:000000:000001   B = $00:000000:000000
;                      Y =    $000000:000001      Y = $000000:000001
;
;   Explanation      : This example illustrates long-word double-precision
;                      (96-bit) addition using the ADC instruction. Prior to
;                      execution of the ADD and ADC instructions, the
;                      double-precision 96-bit value
;                      $000000:000001:800000:000000 is loaded into the Y and X
;                      registers (Y:X), respectively. The other
;                      double-precision 96-bit value
;                      $000000:000001:800000:000000 is loaded into the B and A
;                      accumulators (B:A), respectively. Since the 48-bit value
;                      loaded into the A accumulator is automatically sign
;                      extended to 56 bits and the other 48-bit long-word
;                      operand is internally sign extended to 56 bits during
;                      instruction execution, the carry bit wil be set
;                      correctly after the execution of the ADD X,A
;                      instruction. The ADC Y,B instruction then produces the
;                      correct MS 56-bit result. The actual 96-bit result is
;                      stored in memory using the A10 and B10 operands (instead
;                      of A and B) because shifting and limiting is not
;                      desired.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if limiting (parallel move) or overflow has occured in result
;                      E  Set if the signed integer portion of A or B result is in use
;                      U  Set if A or B result is unnormalized
;                      N  Set if bit 55 of A or B result is set
;                      Z  Set if A or B result equals zero
;                      V  Set if overflow has occured in A or B result
;                      C  Set if a carry (or borrow) occurs from bit 55 of A or B result
;                  NOTE : The definition of the E and U bits varies according to the scaling mode
;                         being used.
;
;   Instruction Form : ADC   S,  D
;
;                            S = (X, Y)
;                                D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; - ADD
;   Name             : Add
;   Operation        : S+D -> D    (parallel move)
;   Assembler Syntax : ADD  S, D   (parallel move)
;   Beschreibung     : Add the source operand S to the destination operand D
;                      and store the result in the destination accumulator.
;                      Words (24 bits), long words (48 bits), and accumulators
;                      (56 bits) may be added to the destination accumulator. ;
;               NOTE : The carry bit is set correctly using word and long-word
;                      source operands if the extension register of the
;                      destination accumulator (A2 or B2) is the sign extension
;                      of bit 47 of the destination accumulator (A or B). Thus,
;                      the carry bit is always set correctly using accumulator
;                      source operands, but can be set incorrectly if A1, B1,
;                      A10, or B10 are used as source operands and A2 and B2
;                      are not replicas of bit 47.
;
;   Beispiel         : ADD   X0, A  A, X1  A, Y:(R1)+       ;24-bit add, set up X1, save prev, result
;
;                      Before Execution:       After Execution:
;                      X0 =           $FFFFFF  X0 =           $FFFFFF
;                      A  = $00:000100:000000  A  = $00:0000FF:000000
;
;   Explanation      : Prior to execution, the 24-bit X0 register contains the
;                      value $FFFFFF and the 56-bit A accumulator contains the
;                      value $00:000100:000000. The ADD instruction
;                      automatically appends the 24-bit value in the X0
;                      register with 24 LS zeros, sign extends the resulting
;                      48-bit long word to 56 bits, and adds the result to the
;                      56-bit A accumulator. Thus, 24-bit operands are are
;                      added to the MSP portion of A or B (A1 or B1) because
;                      all arithmetic instructions assume a fractional, twos
;                      complement data representation. Note that 24-bit
;                      operands can be added to the LSP portion of A or B (A0
;                      or B0) by loading the 24-bit operand into X0 or Y0,
;                      forming a 48-bit word by loading X1 or Y1 with the sign
;                      extension of X0 or Y0 and executing an ADD X,A or ADD
;                      Y,A instruction.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if limiting (parallel move) or overflow has occured in result
;                      E  Set if the signed integer portion of A or B result is in use
;                      U  Set if A or B result is unnormalized
;                      N  Set if bit 55 of A or B result is set
;                      Z  Set if A or B result equals zero
;                      V  Set if overflow has occured in A or B result
;                      C  Set if a carry (or borrow) occurs from bit 55 of A or B result
;                  NOTE : The definition of the E and U bits varies according to the scaling mode
;                         being used.
;
;   Instruction Form : ADD  S, D
;
;                           S = (A, B, X, Y, X0, Y0, X1, Y1)
;                              D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; - ADDL
;   Name             : Shift Left then Add
;   Operation        : S+2*D -> D      (parallel move)
;   Assembler Syntax : ADDL  S, D      (parallel move)
;   Beschreibung     : Add the source operand S to two times the destination
;                      operand D and store the result in the destination
;                      accumulator. The destination operand D is arithmecally
;                      shifted one bit to the left, and a zero is shifted into
;                      the LS bit of D prior to the addition operation. The
;                      carry bit is set correctly if the source operand does
;                      not overflow as a result of the left shifte operation.
;                      The overflow bit may be set as a result of either the
;                      shifting or addition operation (or both). This
;                      instruction is useful for efficient divide and
;                      decimation int time (DIT) FFT algorithms.
;
;   Beispiel         : ADDL  A, B  #$0, R0          ;A + 2 * B -> B, set up addr. reg. R0
;
;                      Before Execution:       After Execution:
;                      A = $00:000000:000123   A = $00:000000:000123
;                      B = $00:005000:000000   B = $00:00A000:000123
;
;   Explanation      : Prior to execution, the 56-bit accumulator contains the
;                      value $00:000000:000123, and the 56-bit B accumulator
;                      contains the value $00:005000:000000. The ADDL A,B
;                      instruction adds two times the value in the B
;                      accumulator to the value in the A accumulator and stores
;                      the 56-bit result in the B accumulator.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if limiting (parallel move) or overflow has occured in result
;                      E  Set if the signed integer portion of A or B result is in use
;                      U  Set if A or B result is unnormalized
;                      N  Set if bit 55 of A or B result is set
;                      Z  Set if A or B result equals zero
;                      V  Set if overflow has occured in A or B result or if
;                         the MS bit of the destination operand is changed as a
;                         result of the instruction's left shift
;                      C  Set if a carry (or borrow) occurs from bit 55 of A or B result
;                  NOTE : The definition of the E and U bits varies according
;                         to the scaling mode being used.
;
;   Instruction Form : ADDL  S, D
;
;                            S = (A, B)
;                               D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; - ADDR
;   Name             : Shift Right then Add
;   Operation        : S + D / 2 -> D      (parallel move)
;   Assembler Syntax : ADDR   S, D         (parallel move)
;   Beschreibung     : Add the source operand S to one-half the destination
;                      operand D and store the result in the destination
;                      accumulator. The destination operand D is arithmetically
;                      shifted one bit to the right while the MS bit of D is
;                      held constant prior to the addition operation. In
;                      contrast to the ADDL instruction, the carry bit is
;                      always set correctly, and the overflow bit can only be
;                      set by the addition operation and not by an overflow due
;                      to the initial shifting operation. This instuction is
;                      useful for efficient divide and decimation in time (DIT)
;                      FFT algorithms.
;
;   Beispiel         : ADDR   B, A   X0, X:(R1)+N1 Y0,  Y:(R4)-      ;B+A/2 -> A, save X0 and Y0
;
;                      Before execution:       After execution:
;                      A = $80:000000:2468AC   A = $C0:013570:123456
;                      B = $00:013570:000000   B = $00:013570:000000
;
;   Explanation      : Prior to execution, the 56-bit A accumulator contains
;                      the value $80:000000:2468AC, and the 56-bit B
;                      accumulator contains the value $00:013570:000000. The
;                      ADDR B, A instruction adds one-half the value in the A
;                      accumulator to the value in the B accumulator and stores
;                      the 56-bit result in the A accumulator.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                   L  Set if limiting (parallel move) or overflow has occured in result
;                   E  Set if the signed integer portion of A or B result is in use
;                   U  Set if A or B result is unnormalized
;                   N  Set if bit 55 of A or B result is set
;                   Z  Set if A or B result equals zero
;                   V  Set if overflow has occured in A or B result
;                   C  Set if a carry (or borrow) occurs from bit 55 of A or B result
;               NOTE : The definition of the E and U bits varies according to
;                      the scaling mode being used.
;
;   Instruction Form : ADDR   S, D
;
;                             S = (A, B)
;                                D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; - ASL
;   Name             : Arithmetic Shift Left
;   Operation        :    55 47     23     0
;                         +--+------+------+
;                      C<-|<-|<-----|<-----|<--0 (parallel move)
;                         +--+------+------+
;   Assembler Syntax : ASL  D        (parallel move)
;   Beschreibung     : Arithmetically shift the destination operand D one bit
;                      to the left and store the result in the destination
;                      accumulator. The MS bit of D prior to instruction
;                      execution is shifted into the carry bit C and a zero is
;                      shifted into the LS bit of the destination accumulator
;                      D. If a zero shift count is specified, the carry bit is
;                      cleared. The difference between ASL and LSL is that ASL
;                      operates on the entires 56 bits of the accumulator and
;                      therefore sets the V bit if the number overflowed.
;
;   Beispiel         : ASL A   (R3)-       ;multiply A by 2,update R3
;
;                      Before Execution:       After Execution:
;                      A  = $A5:012345:012345  A  = $4A:02468A:02468A
;                      SR =             $0300  SR =             $0373
;
;   Explanation      : Prior to execution, the 56-bit A accumulator contains
;                      the value $A5:012345:012345. The execution of the ASL A
;                      instruction shifts the 56-bit value in the A accumulator
;                      one bit to the left and stores the result back in
;                      the A accumulator.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if limiting (parallel move) or overflow has occured in result
;                      E  Set if the signed integer portion of A or B result is in use
;                      U  Set if A or B result is unnormalized
;                      N  Set if bit 55 of A or B result is set
;                      Z  Set if A or B result equals zero
;                      V  Set if bit 55 of A or B result is changed due to left shift
;                      C  Set if bit 55 of A or B was set prior to instruction execution
;                  NOTE : The definition of the E and U bits varies according to the scaling mode
;                         being used.
;
;   Instruction Form : ASL   D
;
;                            D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; - ASR
;   Name             : Arithmetic Shift Right
;   Operation        :    55 47     23     0
;                         +--+------+------+
;                      +->|->|----->|----->|--> C (parallel move)
;                      |  +--+------+------+
;                      +--+
;   Assembler Syntax : ASR   D     (parallel move)
;   Beschreibung     : Arithmetically shift the destination operand D one bit
;                      to the right and store the result in the destination
;                      accumulator. The LS bit of D prior to instruction
;                      execution is shifted into the carry bit C, and the MS
;                      bit of D is held constant.
;
;   Beispiel         : ASR B X:-(R3), R3    ;divide B by 2, update R3,load R3
;
;                      Before Execution:       After Execution:
;                      B  = $AB:A86420:A86421  B  = $D4:543210:543210
;                      SR =             $0300  SR =             $0329
;
;   Explanation      : Prior to execution, the 56-bit B accumulator contains
;                      the value $A8:A86420:A86420. The execution of the ASR B
;                      instruction shifts the 56-bit value in the B accumulator
;                      one bit to the right and restore the result back in the
;                      B accumulator.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting has occured during parallel move
;                      E  Set if the signed integer portion of A or B result is in use
;                      U  Set if A or B result is unnormalized
;                      N  Set if bit 55 of A or B result is set
;                      Z  Set if A or B result equals zero
;                      V  Always cleared
;                      C  Set if bit 0 of A or B was set prior to instruction execution
;                  NOTE : The definition of the E and U bits varies according
;                         to the scaling mode being used.
;
;   Instruction Form : ASR D
;
;                          D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; - CLR
;   Name             : Clear Accumulator
;   Operation        : 0 -> D            (parallel move)
;   Assembler Syntax : CLR  D            (parallel move)
;   Description      : Clear the destination accumulator. This is a 56-bit clear instruction.
;
;   Example          : CLR   A  #$7F, N0    ;clear A, set up N0 addr. reg.
;
;                      Before Execution:
;                      A = $12:345678:9ABCDE
;
;                      After Execution:
;                      A = $00:000000:000000
;
;   Explanation      : Prior to execution, the 56-bit A accumulator contains
;                      the value $12:345678:9ABCDE. The execution of the CLR A
;                      instruction clears the 56-bit A accumulator to zero.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data Limiting has occured during parallel move
;                      E  Always cleared
;                      U  Always set
;                      N  Always cleared
;                      Z  Always set
;                      V  Always cleared
;
;   Instruction Form : CLR   D
;
;                            D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; - CMP
;   Name             : Compare
;   Operation        : S2 - S1           (parallel move)
;   Assembler Syntax : CMP   S1,S2       (parallel move)
;   Description      : Subtract the source one operand, S1, from the source two
;                      accumulator, S2, and update the condition code register.
;                      The result of the substraction operation is not stored.
;
;                NOTE: This instruction substracts 56-bit operands. When a word
;                      is specified as S1, it is sign extended and zero filled
;                      to form a valid 56-bit operand. For the carry to be set
;                      correctly as a result of the substraction, S2 must be
;                      properly sign extended. S2 can be improperly sign
;                      extended by writing A1 or B1 explicity prior to
;                      executing the compare so that A2 or B2, respectively,
;                      may not represent the correct sign extension. This note
;                      particularly applies to the case where it is extended to
;                      compare 24-bit operands such as X0 with A1.
;
;   Example          : CMP   Y0, B X0, X:(R6) + N6   Y1, Y:(R0)-   ;comp. Y0 and B, save X0, Y1
;
;                      Before Execution:       After Execution:
;                      B  = $00:000020:000000  B  = $00:000020:000000
;                      Y0 =           $000024  Y0 =           $000024
;                      SR =             $0300  SR =             $0319
;
;   Explanation      : Prior to execution, the 56-bit B accumulator contains
;                      the value $00:000020:000000 and the 24-bit Y0 register
;                      contains the value $000024. The execution of the CMP
;                      Y0,B instruction automatically appends the 24-bit value
;                      in the Y0 register with 24 LS zeros, sign extends the
;                      resulting 48-bit long word to 56 bits, substracts the
;                      result from the 56-bit B accumulator and updates the
;                      condition code register.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if limiting (parallel move) or overflow has occured in result
;                      E  Set if the signed integer portion of result is in use
;                      U  Set if result is unnormlized
;                      N  Set if bit 55 of result is set
;                      Z  Set if result equals zero
;                      V  Set if overflow has occured in result
;                      C  Set if a carry (or borrow) occurs from bit 55 of result
;                  NOTE : The definition of the E and U bits varies according
;                         to the scaling mode being used.
;
;   Instruction Form : CMP   S1, S2
;
;                            S1 = (A, B, X0, Y0, X1, Y1)
;                                S2 = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; - CMPM
;   Name             : Compare magnitude
;   Operation        : |S2| - |S1|       (parallel move)
;   Assembler Syntax : CMPM  S1,S2       (parallel move)
;   Description      : Subtract the absolute value (magnitude) of the source
;                      oneoperand, S1, from the absolute value of the source
;                      two accumulator, S2, and update the condition code
;                      register. The result of the substraction operation is
;                      not stored.
;
;               NOTE : This instruction substracts 56-bit operands. When a word
;                      is specified as S1, it is sign extended and zero filled
;                      to form a valid 56-bit operand. For of the substraction,
;                      S2 must be properly sign extended. S2 can be improperly
;                      sign extended by writing A1 or B1 explicitly prior to
;                      executing the compare so that A2 or B2, respectively,
;                      may not represent the correct sign extension. This note
;                      particulary applies to the case where it is extended to
;                      compare 24-bit operands such as X0 witch A1.
;
;   Example          : CMPM  X1, A BA,L:-(R4)     ;comp. X1 and A mag., save B1 and A1
;
;                      Before Execution:       After Execution:
;                      A  = $00:000006:000000  A  = $00:000006:000000
;                      X1 =           $FFFFF7  X1 =           $FFFFF7
;                      SR =             $0300  SR =             $0319
;
;   Explanation      : Prior to execution, the 56-bit A accumulator contains
;                      the value $00:000006:000000, and the 24-bit X1 register
;                      contains the $FFFFF7. The execution of the CMPM X1,A
;                      instruction automatically appends the 24-bit value in
;                      the X1 register with 24 LS zeros, sign extends the
;                      resulting 48-bit long word to 56 bits, takes the
;                      absolute value of the resulting 56-bit number,
;                      substracts the result from the absolute value of the
;                      contents of the 56-bit A accumulator, and updates the
;                      condition code register.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if limiting (parallel move) or overflow has occured in result
;                      E  Set if the signed integer portion of result is in use
;                      U  Set if result is unnormlized
;                      N  Set if bit 55 of result is set
;                      Z  Set if result equals zero
;                      V  Set if overflow has occured in result
;                      C  Set if a carry (or borrow) occurs from bit 55 of result
;                  NOTE : The definition of the E and U bits varies according
;                         to the scaling mode being used.
;
;   Instruction Form : CMPM  S1, S2
;
;                            S1 = (A, B, X0, Y0, X1, Y1)
;                                S2 = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; -*DIV
;   Name             : Divide Iteration
;   Operation        : If D[55] ^ S[23] = 1
;
;                       55   47           23         0
;                      +----+------------+------------+
;                then  |<---|<-----------|<-----------| <- C + S -> D
;                      +----+------------+------------+
;                      Destination Accumulator D
;
;                        55   47           23         0
;                      +----+------------+------------+
;               else   |<---|<-----------|<-----------| <- C - S -> D
;                      +----+------------+------------+
;                      Destination Accumulator D
;
;                      where ^ denotes the logical exclusive OR operator
;
;   Assembler Syntax : DIV   S,D
;   Description      : Divide the destination operand D by the source operand S
;                      and store the result in the destination accumulator D.
;                      The 48-bit dividend must be a positive fraction which
;                      has been sign extended to 56-bits and is stored in the
;                      full 56-bit destination accumulator D. The 24-bit
;                      divisor is a signed fraction and is stored in the source
;                      operand S. Each DIV iteration calculates one quotient
;                      bit using a nonrestoring fractional division algorithm
;                      (see description). After the execution of the first DIV
;                      instruction, the destination operand holds both the
;                      partial remainder and the formed quotient. The partial
;                      remainder occupies the high-order portion of the
;                      destination accumulator D and is a signed fraction. The
;                      formed quotient occupies the low-oreder portion of the
;                      destinatioin accumulator D (A0 or B0) and is a positive
;                      fraction. One bit of the formed quotient is shifted into
;                      the LS bit of the destination accumulator at the start
;                      of each  DIV iteration. The formed quotientis the true
;                      quotient if the true quotient is positive. If the true
;                      quotient is negative, the formed quotient must be
;                      negated. Valid result are obtained only when |D| < |S|
;                      and the operands are interpreted as fractions. Note that
;                      this condition ensures that the magnitude of the
;                      quotient is less than one (i.e., is fractional) and
;                      precludes division by zero.
;
;                      The DIV instruction calculates one quotient bit based on
;                      the divisor and the previous partial remainder. To
;                      produce an N-bit quotient, the DIV instruction is
;                      executed N times where N is the number of bits of
;                      precision desired in the quotient, 1 <= N <= 24. Thus,
;                      for a full-precision (24-bit) quotient, 24 DIV
;                      iterations are required. In general, executing the DIV
;                      instruction N times produces an N-bit quotient and a
;                      48-bit remainder which has (48-N) bits of precision and
;                      whose N MS bits are zeros. The partial remainder is not
;                      a true remainder and must be corrected due to the
;                      nonrestoring nature of the division algorithm before it
;                      may be used. Therefore, once the divide is complete, it
;                      is necessary to reverse the last DIV operation and
;                      restore the remainder to obtain the true remainder.
;
;                      The DIV instruction uses a nonrestoring fractional
;                      division algorithm which consists of the following
;                      operations (see the previous Operation diagram):
;
;                   1. Compare the source and destination operand sign bits: An
;                      exclusive OR operation is performed on bit 55 of the
;                      destination operand D and bit 23 of the source operand S
;
;                   2. Shift the partial remainder and the quotient: The 55-bit
;                      destination accumulator D is shifted one bit to the
;                      left. The carry bit C is moved into the LS bit (bit 0)
;                      of the accumulator
;
;                   3. Calculate the next quotient bit and the new partial
;                      remainder: The 24-bit source operand S (signed divisor)
;                      is either added to or subtracted from the MSP portion of
;                      the destination accumulator (A1 or B1), and the result
;                      is stored back into the MSP portion of that destination
;                      accumulator. If the result of the exclusive OR operation
;                      was a '1' (i.e., the sign bits were different), the
;                      source operand S is added to the accumulator. If the
;                      result of the exclusive OR operation was a '0' (i.e.,
;                      the sign bits were the same), the source operand S is
;                      subtracted from the accumulator. Due  to the automatic
;                      sign extension of the 24-bit sign extension of the
;                      24-bit signed divisor, the addition or subtraction
;                      operation correctly sets the carry bit C of the
;                      condition code register with the next quotient bit.
;
;   Example          : (4-Quadrant division, 24-bit signed quotient, 48-bit signed remainder)
;                      ABS   A          A, B           ;make dividend positive, copy A1 to B1
;                      EOR   X0, B      B, X:$0        ;save rem. sign in X:$0, quo. sign in N
;                      AND   #$FE, CCR                 ;clear carry bit C (quotient sign bit)
;                      REP   #$18                      ;form a 24-bit quotient
;                      DIV   X0, A                     ;form quotient in A0, remainder in A1
;                      TFR   A, B                      ;save quotient and remainder in B1,B0
;                      JPL   SAVEQUO                   ;go to SAVEQUO if quotient is positive
;                      NEG   B                         ;complement quotient if N bit set
;          SAVEQUO     TFR   X0, B      B0, X1         ;save quo. in X1, get signed divisor
;                      ABS   B                         ;get absolute value of signed divisor
;                      ADD   A, B                      ;restore remainder in B1
;                      JCLR  #23, X:$0, DONE           ;go to DONE if remainder is positive
;                      MOVE  #$0, B0                   ;clear LS 24 bits of B
;                      NEG   B                         ;complement remainder if negative
;          DONE        ...
;
;                      Before Execution:       After Execution:
;                      A  = $00:0E66D7:F2832C  A  = $FF:EDCCAA:654321
;                      X0 =           $123456  X0 =           $123456
;                      X1 =           $000000  X1 =           $654321
;                      B  = $00:000000:000000  B  = $00:000100:654321
;
;   Explanation      : Prior to execution, 56-bit A accumulator contains the
;                      56-bit, signed-extended fractional dividend D
;                      (D=$00:0E66D7:F2832C = 0.112513535894635 approx.) and
;                      the 24-bit X0 register contains the 24-bit, signed
;                      fractional divisor S (S = $123456 = 0.142222166061401).
;                      Since |D|<|S|, the execution of the previous divide
;                      routine stores the correct 24-bit signed quotient in the
;                      24-bit X1 register (A/X0 = 0.79111111164093 = $654321 =
;                      X1). The partial remainder is restored by reversing the
;                      last DIV operation and adding back the absolute value of
;                      the signed divisor i X0 remained in the 24-bit B1
;                      register. Note that the remainder is really a 48-bit
;                      value which has 24 bits of precision. Thus, the correct
;                      48-bit remainder is $000000:000100 which equals
;                      0.0000000000018190 approximately.
;
;                      Note that the divide routine used in the previous
;                      example assumes that the sign-extended 56-bit signed
;                      fractional dividend is stored in the A accumulator and
;                      that the 24-bit signed fractional dividend is stored in
;                      the X0 register. This routine produces a ful 24-bit
;                      signed quotinet and a 48-bit signed remainder.
;
;                      This routine may be greatly simplified for the case in
;                      which only positive, fractional operands are used to
;                      produce a 24-bit positive quotient and a 48-bit positive
;                      remainder, as shown in the following example:
;
;                      1-Quadrant division, 24-bit unsigned quotient, 48-bit unsigned remainder
;
;                      AND   #$FE, CCR                 ; clear carry bit C (quotient sign bit)
;                      REP   #$18                      ; form a 24-bit quotint and remainder
;                      DIV   X0, A                     ; form quotient in A0, remainder in A1
;                      ADD   X0, A                     ; restore remainder in A1
;
;                      Note that this routine assumes that the 56-bit positive,
;                      fractional, sign-extended dividend is stored in the A
;                      accumulator and that the 24-bit positive, fractional
;                      divisor is stored in the X0 register. After execution,
;                      the 24-bit positive fractional quotient is stored in the
;                      A0 register; the LS 24 bits of the 48-bit positive
;                      fractional remainder are stored in the A1 register.
;
;                      There are many variations possible when choosing a
;                      suitable division routine for a given application. The
;                      selection of a suitable division routine normally
;                      involves specification of the following items:
;                        1) the number of bits precision in the dividend;
;                        2) the number of bits of precision N in quotient;
;                        3) whether the value of N is fixed or is variable;
;                        4) whether the operands are unsigned or signed;
;                        5) whether or not the remainder is to be calculated.
;                      For extended precision division (i.e., for N-bit
;                      quotients where N>24), the DIV instruction is no longer
;                      applicable, and a user-defined N-bit division routine is
;                      required.
;
;   Condition codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      MR CCR
;
;                      L  Set if overflow bit V is set
;                      V  Set if the MS bit of the destination operand is changed as a result of the
;                         instruction's left shift operation
;                      C  Set if bit 55 of the result is cleared
;
;   Instruction Form : DIV   S,D
;
;                            S = (X0, Y0, X1, Y1)
;                              D = (A, B)
;
;   Timing           : 2 oscillator clock cycles
;   Memory           : 1 program word
;
; - MAC
;   Name             : Signed Multiply-Add
;   Operation        : D+-S1*S2 -> D           (parallel move)
;   Assembler Syntax : MAC   (+-) S1, S2, D    (parallel move)
;   Description      : Multiply the two signed 24-bit source operands S1 and S2
;                      and add/subtract the product to/from the specified
;                      56-bit destination accumulator D. The "-" sign option is
;                      used to negate the specified product prior to
;                      accumulation. The default sign option is "+".
;
;   Example          : MAC   X0, X0, A   X:(R2)+N2, Y1  ;square X0 and store in A, update Y1 and R2
;
;                      Before Execution:       After Execution:
;                      X0 =           $123456  X0 =           $123456
;                      A  = $00:100000:000000  A  = $00:1296CD:9619C8
;
;   Explanation      : Prior to execution, the 24-bit X0 register contains the
;                      value of $123456 X0 = $123456 (0.142222166), and the
;                      56-bit A accumulator contains the value X0 = $123456
;                      $00:100000:000000 (0.125). The execution of the MAC
;                      X0,X0,A instruction square the 24-bit signed value in
;                      the X0 regsiter and adds the resulting 48-bit product to
;                      the 56-bit A accumulator (X0*X0+A = 0.145227144519197
;                      approximatively = $00:1296CD:9619C8 = A).
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if limiting (parallel move) or overflow has occured in result
;                      E  Set if the signed integer portion of A or B result is in use
;                      U  Set if A or B result is unnormlized
;                      N  Set if bit 55 of A or B result is set
;                      Z  Set if A or B result equals zero
;                      V  Set if overflow has occured in A or B result
;                  NOTE : The definition of the E and U bits varies according
;                         to the scaling mode being used.
;
;   Instruction Form :  MAC   (+-)S1, S2, D
;
;                                 S1 = (X0, Y0, X1, Y1)
;                                     S2 = (X0, Y0, X1, Y1)
;                                         D  = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; - MACR
;   Name             : Signed Multiply, Accumulate, and Round
;   Operation        : D+-S1*S2+r -> D      (parallel move)
;   Assembler Syntax : MACR  (+-)S1, S2, D  (parallel move)
;   Description      : Multiply the two signed 24-bit source operands S1 and
;                      S2, add/subtract the product to/from the specified
;                      56-bit destination accumulator D, and then round the
;                      result using convergent rounding. The rounded result is
;                      stored in the destination accumulator D. The "-" sign
;                      option is used to negate the specified product prior to
;                      accumulation. The default sign option is "+". The
;                      contribution of the LS bits of the result is rounded
;                      into the upper portion of the destination accumulator
;                      (A1 or B1) by adding a constant to the LS bits of the
;                      lower portion of the accumulator (A0 or B0). The value
;                      of the constant added is determined by the scaling mode
;                      bits S0 and S1 in the RS. Once rounding has been
;                      completed, the LS bits of the destination accumulator D
;                      (A0 or B0) are loaded with zeros to maintain an unbiased
;                      accumulator value which may be refused by next
;                      instruction. The upper portion of the accumulator (A1 or
;                      B1) contains the rounded result which may be read out to
;                      the data buses. Refer to the RND instruction for more
;                      complete information on the convergent rounding process.
;
;   Example          : MACR X0, Y0, B B, X0 Y:(R4)+N4, Y0     ; X0*Y0+B->B, rnd B, update X0,Y0,R4
;
;                      Before Execution:       After Execution:
;                      X0 =           $123456  X0 =           $100000
;                      Y0 =           $123456  Y0 =           $987654
;                      B  = $00:100000:000000  B  = $00:1296CE:000000
;
;   Explanation      : Prior to execution, the 24-bit X0 register contains the
;                      value $123456 (0.142222166), the 24-bit Y0 regsiter
;                      contains the value $123456 (0.142222166), and the 56-bit
;                      accumulator contains the value $00:100000:000000
;                      (0.125). The execution of the MACR X0,Y0,B instruction
;                      multiples the 24-bit signed value in the X0 register by
;                      the 24-bit signed value in the Y0 register, adds the
;                      resulting product to the 56-bit B accumulator, rounds
;                      the result into the B1 portion of the accumulator, and
;                      then zeros the B0 portion of the accumulator (X0*Y0+B =
;                      0.145227144519197 approximately = $00:1296CD:9619C8,
;                      which is rounded to the value $00:1296CE:000000 =
;                      0.145227193832397 = B).
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if limiting (parallel move) or overflow has occured in result
;                      E  Set if the signed integer portion of A or B result is in use
;                      U  Set if A or B result is unnormlized
;                      N  Set if bit 55 of A or B result is set
;                      Z  Set if A or B result equals zero
;                      V  Set if overflow has occured in A or B result
;                  NOTE : The definition of the E and U bits varies according
;                         to the scaling mode being used.
;
;   Instruction Form : MACR  (+-)S1, S2, D
;
;                                S1 = (X0, Y0, X1, Y1)
;                                    S2 = (X0, Y0, X1, Y1)
;                                        D  = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; - MPY
;   Name             : Signed Multiply
;   Operation        : +-S1*S2 -> D            (parallel move)
;   Assembler Syntax : MPY   (+-)S1, S2, D     (parallel move)
;   Description      : Multiply the two signed 24-bit source operands S1 and S2
;                      and store the resulting product in the specified 56-bit
;                      destination accumulator D. The "-" sign option is used
;                      to negate the specified product. The default sign option
;                      is "+".
;
;   Example          : MPY   -X1, Y1, A #$543210, Y0    ;-(X1*Y1)->A, update Y0
;
;                      Before Execution:       After Execution:
;                      X1 =           $800000  X1 =           $800000
;                      Y1 =           $C00000  Y1 =           $C00000
;                      A  = $00:000000:000000  A  = $FF:C00000:000000
;
;   Explanation      : Prior to execution, the 24-bit X1 register contains the
;                      value $800000 (-1,0), the 24-bit Y1 register contains
;                      the value $C00000, (-0.5), and the 56-bit A accumulator
;                      contains the value $00:000000:000000 (0.0). The
;                      execution ofthe MPY -X1,Y1,A instruction multiples the
;                      24-bit signed value in the X1 register by the 24-bit
;                      signed value in the Y1 register, negates the 48-bit
;                      product , and stores the result in the 56-bit A
;                      accumulator (-X1*Y1= -0.5= $FF:C00000:000000 = A).
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting has occured during parallel move
;                      E  Set if the sign ed integer portion of A or B result is in use
;                      U  Set if A or B result is unormalized
;                      N  Set if bit 55 of A or B result is set
;                      Z  Set if A or B result equals zero
;                      V  Always cleared
;                  NOTE : The definition of the E and U bits varies according
;                         to the scaling mode being used.
;
;   Instruction Form : MPY   (+-)S1, S2, D
;
;                                S1 = (X0, Y0, X1, Y1)
;                                    S2 = (X0, Y0, X1, Y1)
;                                        D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; - MPYR
;   Name             : Signed Multiply-Round
;   Operation        : +-S1*S2+r -> D    (parallel move)
;   Assembler Syntax : MPYR  (+-)S1,S2,D (parallel move)
;   Description      : Multiply the two signed 24-bit source operands S1 and
;                      S2, round the result convergent rounding, and store it
;                      in the specified 56-bit destination accumulator D. The
;                      "-" sign option is used to negate the product prior to
;                      rounding. The default sign option is "+". The
;                      contribution of the LS bits of the result is rounded
;                      into the upper portion of the destination accumulator
;                      (A1 or B1) by adding a constant  to the LS bits of the
;                      lower portion of the accumulator (A0 or B0). The value
;                      of the constant added is determined by the scaling mode
;                      bits S0 and S1 in the status register. Once the rouding
;                      has been completed, the LS bits of the destination
;                      accumulator D (A0 or B0) are loaded with zeros to
;                      maintain an unbiased accumulator value which may be
;                      reused by the next instruction. The upper portion of the
;                      accumulator (A1 or B1) contains the rounded result which
;                      may be read out to the data buses. Refer to the RND
;                      instruction for more complete information on the
;                      convergent rounding process.
;
;   Example          : MPYR  -Y0, Y0, B (R3)-N3      ;square and negate Y0, update R3
;
;                      Before Execution:       After Execution:
;                      Y0 =           $654321  Y0 =           $654321
;                      B  = $00:000000:000000  B  = $FF:AFE3ED:000000
;
;   Explanation      : Prior to execution, the 24-bit Y0 register contains the
;                      value $654321 (0.791111112), and the 56-bit B
;                      accumulator contains the value $00:000000:000000 (0.0).
;                      The execution of the MPYR -Y0,Y0,B instruction squares
;                      the 24-bit signed value in the Y0 register, negates the
;                      resulting 48-bit product, rounds the result into B1, and
;                      zeros B0 (-Y0*Y0 = -0.625856790961748 approximately =
;                      $FF:AFE3EC:B76B7E, which is rounded to the value
;                      $FF:AFE3ED:000000 = -0.625856757164002 = B).
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting has occured during parallel move
;                      E  Set if the signed integer portion of A or B result is in use
;                      U  Set if A or B result is unormalized
;                      N  Set if bit 55 of A or B result is set
;                      Z  Set if A or B result equals zero
;                      V  Always cleared
;                  NOTE : The definition of the E and U bits varies according
;                         to the scaling mode being used.
;
;   Instruction Form : MPYR  (+-)S1, S2, D
;
;                                S1 = (X0, Y0, X1, Y1)
;                                    S2 = (X0, Y0, X1, Y1)
;                                        D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; - NEG
;   Name             : Negate Accumulator
;   Operation        : 0-D -> D       (parallel move)
;   Assembler Syntax : NEG D          (parallel move)
;   Description      : Negate the destination operand D and store the result in the destination
;                      accumulator. This is a 56-bit, twos-complement operation.
;
;   Example          : NEG   X1, X:(R3)+ Y:(R6)-, A     ; 0-B -> B, update A, X1, R3, R6
;
;                    Before Execution:
;                    B = $00:123456:789ABC
;
;                    After Execution:
;                    B = $FF:EDCBA9:876544
;
;   Explanation      : Prior to execution, the 56-bit B accumulator contains the value
;                      $00:123456:789ABC. The NEG B instruction takes the twos complement of the
;                      value in the B accumulator.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting has occured during parallel move
;                      E  Set if the signed integer portion of A or B result is in use
;                      U  Set if A or B result is unormalized
;                      N  Set if bit 55 of A or B result is set
;                      Z  Set if A or B result equals zero
;                      V  Set if overflow has occurred in A or B result
;                  NOTE : The definition of the E and U bits varies according to the scaling mode
;                         being used.
;
;   Instruction Form : NEG D
;
;                          D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; -*NORM
;   Name             : Normalize Accumulator Iteration
;   Operation        : If ~ E & U & ~ Z = 1, then ASL D and Rn-1 -> Rn
;                      else if        E = 1, then ASR D and Rn+1 -> Rn
;                      else NOP
;
;                      where ~ denotes the logical complement
;                            & denotes the logical AND operator
;
;   Assembler Syntax : NORM  Rn, D
;   Description      : Perform one normalization iteration on the specified destination operand D,
;                      update the specified address register Rn based upon the result of that
;                      iteration, and store the result back in the destination accumulator. This is a
;                      56-bit operation. If the accumulator extension is not in use, the accumulator
;                      is unnormalized, and the accumulator is not zero, the destination operand is
;                      arithmetically shifted one bit to the left, and the specified address register
;                      is decremented by 1. If the accumulator extension is in use, the destination
;                      operand is arithmetically shifted one bit to the right, and the specified
;                      address register is incremented by 1. If the accumulator is normalized, or
;                      zero, a NOP is executed and the specified address register is not affectred.
;                      Since the operation of the NORM instruction depends on the E, U and Z
;                      condition code register bits, these bits must correctly reflect the current
;                      state of the destination accumulator prior to executing the NORM instruction.
;                      Note that the L and V bits in the condition code register will be cleared
;                      unless they have been improperly set up prior to executing the NORM
;                      instruction.
;
;   Example          : REP   #$2E     ;maximum number of iterations needed
;                      NORM  R3,A     ;perform 1 normalization iteration
;
;                      Before Execution:       After Execution:
;                      A  = $00:000000:000001  A  = $00:400000:000000
;                      R3 =             $0000  R3 =             $FFD2
;
;   Explanation      : Prior to execution, the 56-bit A accumulator contains the value
;                      $00:000000:000001, and the 16-bit R3 address register contains the value
;                      $0000. The repetition of the NORM R3,A instruction normalizes the value in the
;                      56-bit accumulator and stores the resulting number of shifts performed during
;                      that normalization process in the R3 address register. A negative value
;                      reflects the number of left shifts performed; a positive number reflects the
;                      number of right shifts performed during the normalization process.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if overflow has occured in A or B result
;                      E  Set if the signed integer portion of A or B result is in use
;                      U  Set if A or B result is unnormalized
;                      N  Set if bit 55 of A or B result is set
;                      Z  Set if A or B result equals zero
;                      V  Set if bit 55 is changed as a result of a left shift
;
;   Instruction Form : NORM  Rn, D
;   Timing           : 2 oscillator clock cycles
;   Memory           :     1 program words
;
; - RND
;   Name             : Round Accumulator
;   Operation        : D+r -> D (parallel move)
;   Assembler Syntax : RND    D (parallel move)
;   Description      : Round the 56-bit value in the specified destination operand D and store the
;                      result in the MSP portion of the destination accumulator (A1 or B1). This
;                      instruction uses a convergent rounding technique. The contribution of the LS
;                      bits of the result (A0 and B0) is rounded into the upper portion of the result
;                      (A1 or B1) by adding a rounding constant to the LS bits of the result. The MSP
;                      portion of the destination accumulator contains the rounded result wich may be
;                      read out to the data buses.
;
;                      The value of the rounding constant added is determined by the scaling mode bits
;                      S0 and S1 in the system register (SR). A "1" is added in the rounding position
;                      as shown below:
;
;                      Rounding              Rounding      Constant
;                      S1  S0     Scaling Mode    Pos.      55-25   24 23 22   21-0
;                      -------------------------------------------------------------
;                      0     0    No Scaling       23       0...0    0  1  0  0...0
;                      0     1    Scale Down       24       0...0    1  0  0  0...0
;                      1     0    Scale Up         22       0...0    0  0  1  0...0
;
;                      Normal or "standard" rounding consists of adding a rounding constant to a given
;                      number of LS bits of a value to produce a rounded result. The rounding
;                      constant depends on the scaling mode being used as previously shown.
;                      Unfortunately, when using a twos-complement data representation, this process
;                      introduces a positive bias in the statistical distribution of the roundoff
;                      .error.
;
;                      Convergent rounding differs from "standard" rounding in that convergent
;                      rounding attempts to remove the aforementioned positive bias by equally
;                      distributing the round-off error. The convergent rounding technique initially
;                      performs "standard" rounding as previously described. Again, the rounding
;                      constant depends on the scaling mode being used. Once "standard" rounding has
;                      been done, the convergent rounding method tests the result to determine if ALL
;                      bits INCLUDING AND TO THE RIGHT of the rounding position are ZERO. IF, AND
;                      ONLY IF, this SPECIAL CONDITION is true, the convergent rounding method will
;                      clear the bit immediately to the LEFT of the rounding position. When this
;                      special condition is true, numbers wich have a "1" in the bit immediately to
;                      the left of the rounding position are rounded UP; numbers with a "0" in the
;                      bit immediately to the left of the rounding position are rounded DOWN. Thus,
;                      these numbers are rounded UP HALF the time and rounded DOWN the rest of the
;                      time. Therefore, THE ROUNDOFF ERROR AVERAGES OUT TO ZERO. The LS bits of the
;                      convergently rounded result are cleared so that the rounded result may be
;                      immediately used by the next instruction.
;
;   Example          : RND   A  #$123456,X1 B,Y1  ;round A accumulator into A1, zero A0
;
;                      Before execution:       After execution:
;              Case 1: A = $00:123456:789ABC   A = $00:123456:000000
;              Case 2: A = $00:123456:800000   A = $00:123456:000000
;              Case 3: A = $00:123455:800000   A = $00:123456:000000
;
;   Explanation      : Prior to execution, the 56-bit A accumulator countains the value
;                      after execution of the RND A instruction rounds the value in the A accumulator into the MSP
;                      portion of the A accumulator (A1), using wonvergent rounding, and then zeros
;                      the LSP portion of the A accumulator (A0). Note that case 2 is the special
;                      case that distinguishes convergent rounding from standard or biased rounding.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting or overflow has occured during parallel move
;                      E  Set if the signed integer portion of A or B result is in use
;                      U  Set if A or B result is unnormalized
;                      N  Set if bit 55 of A or B result is set
;                      Z  Set if A or B result are zero
;                      V  Set if overflow has occured in A or B result
;                  NOTE : The definition of the E and U bits varies according to the scaling mode
;                         being used.
;
;   Instruction Form : RND D
;
;                          D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; - SBC
;   Name             : Subtract Long with Carry
;   Operation        : D - S - C -> D    (parallel move)
;   Assembler Syntax : SBC   S, D        (parallel move)
;   Description      : Subtract the source operand S and the carry bit C of the condition code
;                      register from the destination operand D and store the result in the
;                      destination accumulator. Long words (48 bits) may be subtracted to the
;                      (56-bit) destination accumulator.
;
;               NOTE : The carry bit is set correctly for multiple precision arithmetic using
;                      long word operands if the extension register of the destination accumulator
;                      (A2 or B2) is the sign extension of bit 47 of the destination accumulator (A
;                      or B).
;
;   Example          :  MOVE  L:<$0, X                 ;get a 48-bit LS long-word operand in X
;                       MOVE  L:<$1, A                 ;get other LS long word in A (Sing ext.)
;                       MOVE  L:<$2, Y                 ;get a 48-bit MS long-word operand in Y
;                       SUB   X, A  L:<$3, B           ;sub LS words; get other MS word in B
;                       SBC   Y, B  A10,L:<$4          ;sub MS words with carry, save LS sum
;                       MOVE  B10, L:<$5               ;save MS difference
;
;                       Before Execution:      After Execution:
;                       A = $00:000000:000000  A = $00:800000:000000
;                       X =    $800000:000000  X =    $800000:000000
;                       B = $00:000000:000003  B = $00:000000:000001
;                       Y =    $000000:000001  Y =    $000000:000001
;
;   Explanation      : This example illustrate long-word double-precision (96-bit) subtraction using
;                      the SBC instruction. Prior to execution of the SUB and SBC instructions, the
;                      double-precision 96-bit value $000000:000001:800000:000000 is loaded into the
;                      Y and X registers (Y:X), respectively. The other double-precision 96-bit value
;                      $000000:000003:000000:000000 is loaded into the B and A accumulators (B:A),
;                      respectively. Since the 48-bit value loaded into the A accumulator is
;                      automatically sign extended to 56 bits and the other 48-bit long-word operand
;                      is internally sign extended to 56 bits during instruction execution, the carry
;                      bit wil be set correctly after the execution of the SUB X, A instruction. The
;                      SBC Y,B instruction then produces the correct MS 56-bit result. The actual
;                      96-bit result is stored in memory using the A10 and B10 operands (instead of A
;                      and B) because shifting and limiting is not desired.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if limiting (parallel move) or overflow has occured in result
;                      E  Set if the signed integer portion of A or B result is in use
;                      U  Set if A or B result is unnormalized
;                      N  Set if bit 55 of A or B result is set
;                      Z  Set if A or B result equals zero
;                      V  Set if overflow has occured in A or B result
;                      C  Set if a carry (or borrow) occurs from bit 55 of A or B result
;                  NOTE : The definition of the E and U bits varies according to the scaling mode
;                         being used.
;
;   Instruction Form : SBC   S,D
;
;                            S = (X, Y)
;                              D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; - SUB
;   Name             : Subtract
;   Operation        : D - S -> D        (parallel move)
;   Assembler Syntax : SUB   S,D         (parallel move)
;   Description      : Subtract the source operand S from the destination operand D and store the
;                      result in the destination operand D. Words (24 bits), long words (48 bits),
;                      and accumulators (56 bits) may be added to the destination accumulator.
;
;               NOTE : The carry bit is set correctly using word and long-word source operands
;                      if the extension register of the destination accumulator (A2 or B2) is the
;                      sign extension of bit 47 of the destination accumulator (A or B). The carry
;                      bit is always set correctly using accumulator source operands.
;
;   Example          : SUB   X1, A X:(R2)+  N2,R0 ;24-bit subtract, load R0, update R2
;
;                      Before Execution:       After Execution:
;                      X1 =           $000003  X1 =           $000003
;                      A  = $00:000058:242424  A  = $00:000055:242424
;
;   Explanation      : Prior to execution, the 24-bit X1 register contains the value $000003 and the
;                      56-bit A accumulator contains the value $00:000058:242424. The SUB instruction
;                      automatically appends the 24-bit value in the X1 register with 24 LS zeros,
;                      sign extends the resulting 48-bit long word to 56 bits, and subtracts the
;                      result to the 56-bit A accumulator. Thus, 24-bit operands are subtracted from
;                      the MSP portion of A or B (A1 or B1) because all arithmetic instructions
;                      assume a fractional, twos complement data representation. Note that 24-bit
;                      operands can be subtracted from the LSP portion of A or B (A0 or B0) by
;                      loading the 24-bit operand into X0 or Y0, forming a 48-bit word by loading X1
;                      or Y1 with the sign extension of X0 or Y0 and executing an SUB X,A or SUB Y,A
;                      instruction.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if limiting (parallel move) or overflow has occured in result
;                      E  Set if the signed integer portion of A or B result is in use
;                      U  Set if A or B result is unnormalized
;                      N  Set if bit 55 of A or B result is set
;                      Z  Set if A or B result equals zero
;                      V  Set if overflow has occured in A or B result
;                      C  Set if a carry (or borrow) occurs from bit 55 of A or B result
;                  NOTE : The definition of the E and U bits varies according to the scaling mode
;                         being used.
;
;   Instruction Form : SUB   S, D
;
;                            S = (A, B, X, Y, X0, Y0, X1, Y1)
;                               D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; - SUBL
;   Name             : Shift Left then Subtract
;   Operation        : 2*D - S -> D      (parallel move)
;   Assembler Syntax : SUBL  S, D        (parallel move)
;   Description      : Subtract the source operand S from two times the destination operand D and
;                      the left, and a zero is shifted into the LS bit of D prior to the subtraction
;                      operation. The carry bit is set correctly if the source operand does not
;                      overflow as a result of the left shift operation. The overflow bit may be set
;                      as a result of either the shifting or addition operation (or both). This
;                      instruction is useful for efficient divide and decimation in time (DIT) FFT
;                      algorithms.
;
;   Example          : SUBL  A, B    Y:(R5+N5), R7      ;2*B-A -> B, load R7, no R5 update
;
;                      Before Execution:       After Execution:
;                      A = $00:004000:000000   A = $00:004000:000000
;                      B = $00:005000:000000   B = $00:006000:000000
;
;   Explanation      : Prior to execution, the 56-bit accumulator contains the value
;                      $00:004000:000000, and the 56-bit B accumulator contains the value
;                      $00:005000:000000. The SUBL A,B instruction subtracts the value in the A
;                      accumulator from two times the value in the A accumulator and stores the
;                      56-bit result in the B accumulator.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if limiting (parallel move) or overflow has occured in result
;                      E  Set if the signed integer portion of A or B result is in use
;                      U  Set if A or B result is unnormalized
;                      N  Set if bit 55 of A or B result is set
;                      Z  Set if A or B result equals zero
;                      V  Set if overflow has occured in A or B result or if the MS bit of the
;                         destination operand is changed as a result of the instruction's left
;                         shift
;                      C  Set if a carry (or borrow) occurs from bit 55 of A or B result
;                  NOTE : The definition of the E and U bits varies according to the scaling mode
;                         being used.
;
;   Instruction Form : SUBL  S, D
;
;                            S = (A, B)
;                               D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; - SUBR
;   Name             : Shift Right then Subtract
;   Operation        : D / 2 - S -> D    (parallel move)
;   Assembler Syntax : SUBR  S,D         (parallel move)
;   Description      : Subtract the source operand S from one-half the destination operand D and store
;                      the result in the destination accumulator. The destination operand D is
;                      arithmetically shifted one bit to the right while the MS bit of D is held
;                      constant prior to the subtract operation. In contrast to the SUBL instruction,
;                      the carry bit is always set correctly, and the overflow bit can only be set by
;                      the addition operation and not by an overflow due to the initial shifting
;                      operation. This instuction is useful for efficient divide and decimation in
;                      time (DIT) FFT algorithms.
;
;   Example          : SUBR  B, A     N5, Y:-(R5)    ;A/2 - B -> A, update R5, save N5
;
;                      Before execution:       After execution:
;                      A = $80:000000:2468AC   A = $C0:000000:000000
;                      B = $00:000000:123456   B = $00:000000:123456
;
;   Explanation      : Prior to execution, the 56-bit A accumulator contains the value
;                      $80:000000:2468AC, and the 56-bit accumulator contains the value
;                      $00:000000:123456. The SUBR B,A instruction subtract the value in the B
;                      accumulator from one-half the value in the A accumulator and stores the 56-bit
;                      result in the A accumulator.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if limiting (parallel move) or overflow has occured in result
;                      E  Set if the signed integer portion of A or B result is in use
;                      U  Set if A or B result is unnormalized
;                      N  Set if bit 55 of A or B result is set
;                      Z  Set if A or B result equals zero
;                      V  Set if overflow has occured in A or B result
;                      C  Set if a carry (or borrow) occurs from bit 55 of A or B result
;                  NOTE : The definition of the E and U bits varies according to the scaling mode
;                         being used.
;
;   Instruction Form : SUBR  S, D
;
;                            S = (A, B)
;                               D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; -*Tcc
;   Name             : Transfer Conditionally
;   Operation        : If cc, then S1 -> D1
;                      If cc, then S1 -> D1 and S2 -> D2
;   Assembler Syntax : Tcc S1,D1
;                      Tcc S1,D1 S2,D2
;   Description      : Transfer data from the specified source register S1 to the specified
;                      destination accumulator D1 if the specified condition is true. If a second
;                      source register S2 and a second destination register D2 are also specified,
;                      transfer data from address register S2 to address register D2 if the specified
;                      condition is true. If the specified condition is false, a NOP is executed. The
;                      term "cc" may specify the following conditions:
;
;   Conditions       : "cc"  Mnemonic Condition
;                       CC (HS) carry clear (higher or same)   C = 0
;                       CS (LO) carry set (lower)              C = 1
;                       EC      extension clear                E = 0
;                       EQ      equal                          Z = 1
;                       ES      extension set                  E = 1
;                       GE      greater than or equal        N^V = 0
;                       GT      greater than             Z+(N^V) = 0
;                       LC      limit clear                    L = 0
;                       LE      less than or equal       Z+(N^V) = 1
;                       LS      limit set                      L = 1
;                       LT      less than                    N^V = 1
;                       MI      minus                          N = 1
;                       NE      not equal                      Z = 0
;                       NR      normalized             Z+(U & E) = 1
;                       PL      plus                           N = 0
;                       NN      not normalized       Z+(~U & ~E) = 0
;
;                       where ~ denote the logical complement,
;                             + denotes the logical OR operator,
;                             & denotes the logical AND operator, and
;                             ^ denotes the logical Exclusive OR operator.
;
;                      When used after the CMP or CMPM instructions, the Tcc instruction can perform
;                      many useful functions such as a "maximum value", "minimum value" "maximum
;                      absolute value" or "minimum absolute value" function. The desired value is
;                      stored in the destination accumulator D1. If address register S2 is used as an
;                      address pointer into an array of data, the address of the desired value is
;                      stored in the address register D2. The Tcc instruction may be used after any
;                      instruction and allows efficient searching and sorting algorithms. The Tcc
;                      instruction uses the internal data ALU paths and internal address ALU paths.
;                      The Tcc instruction does not affect the condition code bits.
;
;               NOTE : This instruction is considered to be a move-type instruction. Due to
;                      pipelining, if an address register (R0-R7) is changed using a move-type
;                      instruction, the new contents of the destination address register will not be
;                      available for use during the following instruction (i.e., there is a single
;                      instruction cycle pipeline delay).
;
;   Example          : CMP   X0, A          ;compare X0 and A (sort for minimum)
;                      TGT   X0, A R0, R1   ;transfer X0 -> A and R0 -> R1 if X0 < A
;
;   Explanation      : In this example, the contents of the 24-bit X0 register are transferred to the
;                      56-bit A accumulator, and the contents of the 16-bit R0 address register are
;                      transferred to the 16-bit R1 address register if the specified condition is
;                      true. If the specified condition is not true, a NOP is executed.
;   Condition Codes  : The condition codes are not affected by this instruction.
;   Instruction Form : Tcc   S1, D1
;                      Tcc   S1, D1   S2, D2
;
;                            S1 = (A, B, X0, Y0, X1, Y1)
;                                D1 = (A, B)
;                                     S2 = (Rn)
;                                         D2 = (Rn)
;
;   Timing           : 2 oscillator clock cycles
;   Memory           : 1 program word
;
; - TFR
;   Name             : Transfer Data ALU Register
;   Operation        : S -> D            (parallel move)
;   Assembler Syntax : TFR S,D           (parallel move)
;   Description      : Transfer data from the specified source data ALU register S to the specified
;                      destination data ALU accumulator D. TFR uses the internal data ALU data paths;
;                      thus, data DO NOT pass through the data shifter/limiters. This allows the full
;                      56-bit contents of one of the accumulatorsto be transferred into the other
;                      accumulator WITHOUT data shifting and/or limiting. Moreover, since TFR uses
;                      the internal data ALU data paths, parallel moves are possible. The TFR
;                      instruction only affects the L condition code bit, wich can be set by data
;                      limiting associated with the instruction's parallel move operations.
;
;   Example          : TFR   A, B  A, X1 Y:(R4+N4),Y 0 ; move A to B and X1, update Y0
;
;                      Before Execution : A  = $01:234567:89ABCD
;                                         B  = $FF:FFFFFF:FFFFFF
;
;                      After  Execution : A  = $01:234567:89ABCD
;                                         B  = $01:234567:89ABCD
;
;   Explanation      : Prior to execution, the 56-bit A accumulator contains the value
;                      $01:234567:89ABCD, and the 56-bit B accumulator contains the value
;                      $FF:FFFFFF:FFFFFF. The execution of the TFR A,B instruction moves the 56-bit
;                      value in the A accumulator into the 56-bit B accumulator using the internal
;                      data ALU data paths without any data shifting and/or limiting. The value in
;                      the B accumulator WOULD have been limited if a MOVE A,B instruction had been
;                      used. Note, however, that the parallel move portion of the TFR instruction
;                      DOES use the data shifter/limiter. Thus, the value stored in the 24-bit X1
;                      register (not shown) WOULD have been limited in this example. This instruction
;                      illustrate a TRIPLE move instruction.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L- Set if data limiting has occured during parallel move
;
;   Instruction Form : TFR   S,D
;
;                            S = (A, B, X0, Y0, X1, Y1)
;                              D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           :     1 + mv program words
;
; - TST
;   Name             : Test Accumulator
;   Operation        : S - 0          (parallel move)
;   Assembler Syntax : TST S          (parallel move)
;   Description      : Compare the specified source accumulator S with zero and set the condition
;                      codes accordingly. No result is stored although the condition codes are
;                      updated.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting has occured during parallel move
;                      E  Set if the signed integer portion of A or B result is in use
;                      U  Set if A or B result is unnormalized
;                      N  Set if bit 55 of A or B result is set
;                      Z  Set if A or B result equals zero
;                      V  Always cleared
;               NOTE : The definition of the E and U bits varies according to the scaling mode
;                      being used.
;
;   Instruction Form : TST   S
;
;                            S = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; *****************************************************************************
; > Logical Instructions - Motorola (c) 1990
;
; - AND
;   Name             : Logical AND
;   Operation        : S & D[47:24] -> D[47:24] (parallel move)
;                      where & denotes the logical AND operator
;   Assembler Syntax : AND   S, D               (parallel move)
;   Beschreibung     : Logically AND the source operand S with bits 47-24 of the destination operand D
;                      and store the result in bits 47-24 of the destination accumulator. This
;                      instruction is a 24-bit operation. The remaining bits of the destination
;                      operand D are not affected.
;
;   Beispiel         : AND  X0, A   (R5)-N5          ;AND X0 with A1, update R5 using N5
;
;                      Before Execution:       After Execution:
;                      X0 =           $FF0000  X0 =           $FF0000
;                      A  = $00:123456:789ABC  A  = $00:120000:789ABC
;
;   Explanation      : Prior to execution, the 24-bit X0 register contains the value $FF0000, and the
;                      value in the X0 register with bits 47-24 of the A accumulator (A1) and stores
;                      the result in the the A accumulator with bits 55-48 and 23-0 unchanged.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting has occured during parallel move
;                      N  Set if bit 47 of A or B result is set
;                      Z  Set if bits 47-24 A or B result are zero
;                      V  Always cleared
;
;   Instruction Form : AND   S, D
;
;                            S = (X0, X1, Y0, Y1)
;                               D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; -*ANDI
;   Name             : AND Immediate with Control Register
;   Operation        : AND #xx & D -> D
;                      where & denotes the logical AND operator
;   Assembler Syntax : AND (I)  #xx, D
;   Beschreibung     : Logically AND the 8-bit immediate operand (#xx) with the contents of the
;                      destination control register D and store the result in the destination control
;                      register. The condition code are affected only when the condition code
;                      register (CCR) is specified as the destination operand.
;   Restrictions     : The ANDI #xx, MR instruction cannot be used immediately before an ENDDO or RTI
;                      instruction and cannot be one of the last three instructions in a DO loop (at
;                      LA-2, LA-1, or LA).
;                      The ANDI #xx, CCR instruction cannot be used immediately before an RTI
;                      instruction.
;
;   Beispiel         : ANDI  #$FE, CCR        ;clear carry bit C in cond. code register
;
;                      Before Execution:       After Execution:
;                      CCR = $31               CCR = $30
;
;   Explanation      : Prior to execution, the 8-bit condition code register (CCR) contains the value
;                      $31. The ANDI #$FE,CCR instruction logically ANDs the immediate 8-bit value
;                      $FE with the contents of the condition code register and stores the result in
;                      the condition code register.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;              For CCR Operand :
;                      L  Cleared if bit 6 of the immediate operand is cleared
;                      E  Cleared if bit 5 of the immediate operand is cleared
;                      U  Cleared if bit 4 of the immediate operand is cleared
;                      N  Cleared if bit 3 of the immediate operand is cleared
;                      Z  Cleared if bit 2 of the immediate operand is cleared
;                      V  Cleared if bit 1 of the immediate operand is cleared
;                      C  Cleared if bit 0 of the immediate operand is cleared
;       For MR and OMR Operands:
;                      The condition codes are not affected using these operands.
;
;   Instruction Form : ANDI  #xx, D
;
;                            #xx = 8-bit Immediate Short Data
;                                 D = (MR, CCR, OMR)
;
;   Timing           : 2 oscillator clock cycles
;   Memory           : 1 program word
;
; - EOR
;   Name             : Logical Exclusive OR
;   Operation        : S ^ D [47:24] -> D [47:24] (parallel move)
;                      where ^ denotes the logical exclusive OR operator
;   Assembler Syntax : EOR   S,D                  (parallel move)
;   Description      : Logically exclusive OR the source operand S with bits 47-24 of the destination
;                      operand D and store the result in bits 47-24 of the destination accumulator.
;                      This instruction is 24-bit operation. The remaining bits of the destination
;                      operand D are not affected.
;
;   Example          : EOR   Y1, B (R2)+    ;Exclusive OR Y1 with B1, update R2
;
;                      Before Execution:       After Execution:
;                      Y1 =           $000003  Y1 =           $000003
;                      B  = $00:000005:000000  B  = $00:000006:000000
;
;   Explanation      : Prior to execution, the 24-bit Y1 register contains the value $000003, and the
;                      56-bit B accumulator contains the value $00:000005:000000. The EOR Y1,B
;                      instruction logically exclusive ORs the 24-bit value in the Y1 register with
;                      bits 47-24 of the B accumulator (B1) and stores the result in the B
;                      accumulator with bits 55-48 and 23-0 unchanged.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting has occured during parallel move
;                      N  Set if bit 47 of A or B result is set
;                      Z  Set if bits 47-24 of A or B result are zero
;                      V  Always cleared
;
;   Instruction Form : EOR   S,D
;
;                            S = (X0, X1, Y0, Y1)
;                              D = (A, B)
;
;   Timing           : 2 + mv oscillator
;   Memory           : 1 + mv program words
;
; - LSL
;   Name             : Logical Shift Accumulator Left
;   Operation        :      47        24
;                          +------------+
;                      C <-|<-----------|<- 0 (parallel move)
;                          +------------+
;   Assembler Syntax : LSL   D                (parallel move)
;   Description      : Logical shifts bits 47-24 of the destination operand D one bit to the left and
;                      store the result in the destination accumulator. Prior to instruction
;                      execution, bit 47 of D is shifted into the carry bit C, and zero is shifted
;                      into bit 24 of the destination accumulator D. This instruction is a 24-bit
;                      operation. The remainig bits of the destination operand E are not affected. If
;                      zero shift count is specified, the carry bit is cleared. The difference
;                      between LSL and ASL is that LSL operates on only A1 or B1 and always clears
;                      the V bit.
;
;   Example          : LSL   B  #$7F, R0    ;shift B1 one bit to the left, set up R0
;
;                      Before execution:       After execution:
;                      B  = $00:F01234:13579B  B  = $00:E02468:13579B
;                      SR =             $0300  SR =             $0309
;
;   Explanation      : Prior to execution, the 56-bit B accumulator contains the value
;                      $00:F01234:13579B. The execution of the LSL B instruction shifts the 24-bit
;                      value in the B1 register one bit to the left and stores the result back in the
;                      B1 register.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting has occured during parallel move
;                      N  Set if bit 47 of A or B result is set
;                      Z  Set if bits 47-24 of A or B result are zero
;                      V  Always cleared
;                      C  Set if bit 47 of A or B was set prior to instruction execution
;
;   Instruction Form : LSL   D
;
;                            D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; - LSR
;   Name             : Logical Shift Accumulator Right
;   Operation        :      47        24
;                          +------------+
;                      0 ->|----------->|-> C (parallel move)
;                          +------------+
;   Assembler Syntax : LSR   D                (parallel move)
;   Description      : Logically shifts bits 47-24 of the destination operand D one bit to the right
;                      and store the result in the destination accumulator. Prior to instruction
;                      execution, bit 24 of D is shifted into the carry bit C, and zero is shifted
;                      into bit 47 of the destination accumulator D. This instruction is a 24-bit
;                      operation. The remaining bits of the destination operand D are not affected.
;
;   Example          : LSR   A   A1, N4      ; shift A1 one bit to the right, set up N4
;
;                      Before execution:       After execution:
;                      A  = $37:444445:828180  A  = $37:222222:828180
;                      SR =             $0300  SR =             $0301
;
;   Explanation      : Prior to execution, the 56-bit A accumulator countains the value
;                      $37:444445:828180. The execution of the LSR A instruction shifts the 24-bit
;                      value in the A1 register one bit tothe right and stores the result back in the
;                      A1 register.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting has occured during parallel move
;                      N  Always cleared
;                      Z  Set if bits 47-24 of A or B result are zero
;                      V  Always cleared
;                      C  Set if bit 24 of A or B was set prior to instruction execution
;
;   Instruction Form : LSR D
;
;                          D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; - NOT
;   Name             : Logical Complement on Accumulator
;   Operation        :  ~ D [47:24] -> D [47:24]   (parallel move)
;                      where ~ denotes the logical NOT operator
;   Assembler Syntax : NOT   D                     (parallel move)
;   Description      : Take ones complement of bits 47-24 off the destination operand D and store the
;                      result in bits 47-24 of the destination accumulator. This instruction is a
;                      24-bit operation. The remaining bits of the destination operand D are not
;                      affected.
;
;   Example          : NOT   A AB, L:(R2)+     ;save A1, B1, take the ones complement of A1
;
;                      Before Execution:
;                      A  = $00:123456:789ABC
;
;                      After Execution:
;                      A  = $00:EDCBA9:789ABC
;
;   Explanation      : Prior to execution, the 56-bit A accumulator contains the value
;                      $00:123456:789ABC. The NOT A instruction takes the ones complement of bits
;                      47-24 of the A accumulator (A1) and stores the result back in the A1 register.
;                      The remainings bits of the A accumulator are not affected.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting has occured during parallel move
;                      N  Set if bit 47 of A or B result is set
;                      Z  Set if bits 47-24 A or B result are zero
;                      V  Always cleared
;
;   Instruction Form : NOT   D
;
;                            D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; - OR
;   Name             : Logical Inclusive OR
;   Operation        : S + D[47:24] -> D[47:24] (parallel move)
;                      where + denotes the logical inclusive OR operator
;   Assembler Syntax : OR S, D                  (parallel move)
;   Description      : Logically inclusive OR the source operand S with bits 47-24 of the destination
;                      operand D and store the result in bits 47-24 of the destination accumulator.
;                      This instruction is a 24-bit operation. The remaining bits of the destination
;                      operand D are not affected.
;
;   Example          : OR Y1, B BA, L:$1234 ; save A1, B1, OR Y1 with B
;
;                      Before Execution:       After Execution:
;                      Y1 =           $FF0000  Y1 =           $FF0000
;                      B  = $00:123456:789ABC  B  = $00:FF3256:789ABC
;
;   Explanation      : Prior to execution, the 24-bit Y1 register contains the value $FF0000, and the
;                      56-bit B accumulator contains the value $00:123456:789ABC. The OR Y1,B
;                      instruction logically ORs the 24-bit value in the Y1 register with bits 47-24
;                      of the B accumulator (B1) and stores the result in the B accumulator.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting has occured during parallel move
;                      N  Set if bit 47 of A or B result is set
;                      Z  Set if bits 47-24 A or B result are zero
;                      V  Always cleared
;
;   Instruction Form : OR S,D
;
;                         S = (X0, X0, X1, Y1)
;                           D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; -*ORI
;   Name             : OR Immediate with Control Register
;   Operation        : #xx + D -> D   where + denotes the logical inclusive OR operator
;   Assembler Syntax : OR (I)   #xx, D
;   Description      : Logically OR the 8-bit immediate operand (#xx) with the contents of the
;                      destination control register D and store the result in the destination control
;                      register. The condition code are affected only when the condition code
;                      register (CCR) is specified as the destination operand.
;   Restrictions     : The ORI #xx, MR instruction cannot be used immediately before an ENDDO or RTI
;                      instruction and cannot be one of the last three instructions in a DO loop (at
;                      LA-2, LA-1, or LA).
;
;   Example          : ORI   #$8, MR     ;set scaling mode bit S1 to scale up
;
;                      Before Execution:
;                      MR = $03
;
;                      After Execution:
;                      MR = $0B
;
;   Explanation      : Prior to execution, the 8-bit mode register (MR) contains the value $03. The
;                      ORI #$8, MR instruction logically ORs the immediate 8-bit value $8 with the
;                      contents of the mode register and stores the result in the mode register.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;              For CCR Operand:
;                      L  Set if bit 6 of the immediate operand is cleared
;                      E  Set if bit 5 of the immediate operand is cleared
;                      U  Set if bit 4 of the immediate operand is cleared
;                      N  Set if bit 3 of the immediate operand is cleared
;                      Z  Set if bit 2 of the immediate operand is cleared
;                      V  Set if bit 1 of the immediate operand is cleared
;                      C  Set if bit 0 of the immediate operand is cleared
;
;       For MR and OMR Operands:
;                      The condition codes are not affected using these operands.
;
;   Instruction Form : ORI   #xx, D
;
;                                 D = (MR, CCR, OMR)
;
;   Timing           : 2 oscillator clock cycles
;   Memory           : 1 program word
;
; - ROL
;   Name             : Rotate Accumulator Left
;   Operation        :      47        24
;                          +------------+
;                      <-C-|<-----------|<-+  (parallel move)
;                      |   +------------+  |
;                      +-------------------+
;   Assembler Syntax : ROL   D                (parallel move)
;   Description      : Rotate bits 47-24 of the destination operand D one bit to the left and store
;                      the result in the destination accumulator. Prior to instruction execution, bit
;                      47 of D is shifted into the carry bit C, and prior to instruction execution,
;                      the value in the carry bit C is shifted into bit 24 of the destination
;                      accumulator D. This instruction is a 24-bit operation. The remaining bits of
;                      the destination operand D are not affected.
;
;   Example          : ROL   A  #$314,N2 ;rotate A1 left one bit, update N2
;
;                      Before execution:       After execution:
;                      A  = $00:000000:000000  A  = $00:000001:000000
;                      SR =             $0301  SR =             $0300
;
;   Explanation      : Prior to execution, the 56-bit A accumulator countains the value
;                      $00:000000:00000. The execution of the ROL A instruction shifts the 24-bit
;                      value in the A1 register one bit to the left, shifting bit 47 into the carry
;                      bit C,rotating the carry bit C into bit 24, and storing the result back in the
;                      A1 register.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting has occured during parallel move
;                      N  Set if bit 47 of A or B result is set
;                      Z  Set if bits 47-24 of A or B result are zero
;                      V  Always cleared
;                      C  Set if bit 47 of A or B was set prior to instruction execution
;
;   Instruction Form : ROR D
;
;                          D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
; - ROR
;   Name             : Rotate Accumulator Right
;   Operation        :      47        24
;                          +------------+
;                      +C->|----------->|->-+  (parallel move)
;                      |   +------------+   |
;                      +--------------------+
;   Assembler Syntax : ROR   D           (parallel move)
;   Description      : Rotate bits 47-24 of the destination operand D one bit to the right and store
;                      the result in the destination accumulator. Prior to instruction execution, bit
;                      24 of D is shifted into the carry bit C, and prior to instruction execution,
;                      the value in the carry bit C is shifted into bit 47 of the destination
;                      accumulator D. This instruction is a 24-bit operation. The remaining bits of
;                      the destination operand D are not affected.
;
;   Example          : ROR   B  #$1234,R2   ; rotate B1 right one bit, update R2
;
;                      Before execution:       After execution:
;                      B  = $00:000001:222222  B  = $00:000000:222222
;                      SR =             $0300  SR =             $0305
;
;   Explanation      : Prior to execution, the 56-bit B accumulator countains the value
;                      $00:000001:222222. The execution of the ROR B instruction shifts the 24-bit
;                      value in the B1 register one bit to the right, shifting bit 24 into the carry
;                      bit C, rotating the carry bit C into bit 47, and storing the result back in
;                      the B1 register.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting has occured during parallel move
;                      N  Set if bit 47 of A or B result is set
;                      Z  Set if bits 47-24 of A or B result are zero
;                      V  Always cleared
;                      C  Set if bit 47 of A or B was set prior to instruction execution
;
;   Instruction Form : ROR D
;
;                          D = (A, B)
;
;   Timing           : 2 + mv oscillator clock cycles
;   Memory           : 1 + mv program words
;
;
; *****************************************************************************
; > Bit Manipulation Instructions - Motorola (c) 1990
;
; -*BCLR
;   Name             : Bit Test and Clear
;   Operation        : D[n] -> C
;                      0 -> D[n]
;   Assembler Syntax :    BCLR  #n, X:ea
;                         BCLR  #n, X:aa
;                         BCLR  #n, X:pp
;                         BCLR  #n, Y:ea
;                         BCLR  #n, Y:aa
;                         BCLR  #n, Y:pp
;                         BCLR  #n, D
;   Description      : Test the nth bit of the destination operand D, clear it and store the result in
;                      the destination location. The state of the nth bit is stored in the carry bit
;                      C of the condition code register. After the test, the nth bit of the
;                      struction performs a read-modify-write operation on the destination location
;                      using two destination accesses before releasing the bus. This instruction
;                      provides a test-and-clear capability which is useful for synchronizing
;                      multiple processors using a shared memory. This instruction can use all memory
;                      alterable addressing modes.
;
;   Example          : BCLR  #$E, X<<$FFE4     ;test and clear bit 14 in I/O Port B Data Reg.
;
;                      Before Execution:       After Execution:
;                      X:$FFE4 = $FFFFFF       X:$FFE4 = $FFBFFF
;                      SR      =   $0300       SR      =   $0301
;
;   Explanation      : Prior to execution, the 24-bit X memory location X:$FFE4 (I/O port B data
;                      register) contains the value $FFFFFF. The execution of the BCLR #$E, X:<<$FFE4
;                      instruction tests the state of the 14th bit in X:$FFE4, sets the carry bit C
;                      accordingly, and then clears the 14th bit in X:$FFE4.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;     > CCR Condition Codes :
;         For destination operand SR :
;                      C  Changed if bit 0 is specified. Not affected otherwise.
;                      V  Changed if bit 1 is specified. Not affected otherwise.
;                      Z  Changed if bit 2 is specified. Not affected otherwise.
;                      N  Changed if bit 3 is specified. Not affected otherwise.
;                      U  Changed if bit 4 is specified. Not affected otherwise.
;                      E  Changed if bit 5 is specified. Not affected otherwise.
;                      L  Changed if bit 6 is specified. Not affected otherwise.
;
;         For other destination operands :
;                      C  Set if bit tested is set. Cleared otherwise.
;                      V  Not Affected.
;                      Z  Not Affected.
;                      N  Not Affected.
;                      U  Not Affected.
;                      E  Not Affected.
;                      L  Not Affected.
;
;     > MR Status Bits :
;         For destination operand SR :
;                      I0 Changed if bit 8 specified. Not affected otherwise.
;                      I1 Changed if bit 9 specified. Not affected otherwise.
;                      S0 Changed if bit 10 specified. Not affected otherwise.
;                      S1 Changed if bit 11 specified. Not affected otherwise.
;                      T  Changed if bit 13 specified. Not affected otherwise.
;                      LF Changed if bit 15 specified. Not affected otherwise.
;
;         For other destination operands :
;                      I0 Not affected
;                      I1 Not affected
;                      S0 Not affected
;                      S1 Not affected
;                      T  Not affected
;                      LF Not affected
;
;   Instruction Form : BCLR  #n, X:ea
;                      BCLR  #n, Y:ea
;                      BCLR  #n, X:aa
;                      BCLR  #n, Y:aa
;                      BCLR  #n, X:pp
;                      BCLR  #n, Y:pp
;                      BCLR  #n, D
;
;                            #n = bit number
;                                  ea = (Rn)-Nn,
;                                       (Rn)+Nn,
;                                       (Rn)-,
;                                       (Rn)+,
;                                       (Rn),
;                                       (Rn+Nn),
;                                      -(Rn),
;                                        Absolute address
;                                  aa = 6-bit Absolute Short Address
;                                  pp = 6-bit I/O Short Address
;                                D  = (X0, X1, Y0, Y1,
;                                      A0, B0, A2, B2, A1, B1, A, B,
;                                      Rn, Nn, Mn,
;                                      SR, OMR, SP, SSH, SSL, LA, LC)
;
;   Timing           : 4 + mvb oscillator clock cycles
;   Memory           : 1 + ea program words
;
; -*BSET
;   Name             : Bit Test and Set
;   Operation        : D[n] -> C
;                      1 -> D[n]
;   Assembler Syntax : BSET  #n, X:ea
;                      BSET  #n, X:aa
;                      BSET  #n, X:pp
;                      BSET  #n, Y:ea
;                      BSET  #n, Y:aa
;                      BSET  #n, Y:pp
;                      BSET  #n, D
;   Description      : Test the nth bit of the destination operand D, set it, and store the result in
;                      the destination location. The state of the nth bit is stored in the carry bit
;                      C of the condition code register. After the test, the nth bit of the
;                      destination location is set. The bit to be tested is selected by an immediate
;                      bit number from 0-23. This instruction performs a read-modify-write operation
;                      on the destination location using two destination accesses before releasing
;                      the bus. This instruction provides a test-and-set capability which is useful
;                      for synchronizing multiple processorsusing a shared memory. This instruction
;                      can use all memory alterable addressing modes.
;
;   Example          : BSET  #$0, X:<<$FFE5    ;test and set bit 10 in I/O Port C Data Reg.
;
;                      Before Execution:       After Execution:
;                      X:$FFE5 = $000000       X:$FFE5 = $000001
;                      SR      =   $0300       SR      =   $0300
;
;   Explanation      : Prior to execution, the 24-bit X memory location X:$FFE5 (I/O port C data
;                      register) contains the value $000000. The execution of the BSET #$0, X:<<$FFE5
;                      instruction test the state of the 0th bit in X:$FFE5, sets the carry bit C
;                      accordingly, and then sets the 0th bit in X:$FFE5.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;     > CCR Condition Codes :
;         For destination operand SR :
;                      C  Changed if bit 0 is specified. Not affected otherwise.
;                      V  Changed if bit 1 is specified. Not affected otherwise.
;                      Z  Changed if bit 2 is specified. Not affected otherwise.
;                      N  Changed if bit 3 is specified. Not affected otherwise.
;                      U  Changed if bit 4 is specified. Not affected otherwise.
;                      E  Changed if bit 5 is specified. Not affected otherwise.
;                      L  Changed if bit 6 is specified. Not affected otherwise.
;
;         For other destination operands:
;                      C  Set if bit tested is set. Cleared otherwise.
;                      V  Not Affected.
;                      Z  Not Affected.
;                      N  Not Affected.
;                      U  Not Affected.
;                      E  Not Affected.
;                      L  Not Affected.
;
;     > MR Status Bits:
;         For destination operand SR:
;                      I0 Changed if bit 8 specified. Not affected otherwise.
;                      I1 Changed if bit 9 specified. Not affected otherwise.
;                      S0 Changed if bit 10 specified. Not affected otherwise.
;                      S1 Changed if bit 11 specified. Not affected otherwise.
;                      T  Changed if bit 13 specified. Not affected otherwise.
;                      LF Changed if bit 15 specified. Not affected otherwise.
;
;         For other destination operands:
;                      I0 Not affected
;                      I1 Not affected
;                      S0 Not affected
;                      S1 Not affected
;                      T  Not affected
;                      LF Not affected
;
;   Instruction Form : BSET  #n, X:ea
;                      BSET  #n, Y:ea
;                      BSET  #n, X:aa
;                      BSET  #n, Y:aa
;                      BSET  #n, X:pp
;                      BSET  #n, Y:pp
;                      BSET  #n, D
;
;                            #n = bit number
;                                  ea = (Rn)-Nn,
;                                       (Rn)+Nn,
;                                       (Rn)-,
;                                       (Rn)+,
;                                       (Rn),
;                                       (Rn+Nn),
;                                      -(Rn),
;                                        Absolute address
;                                  aa = 6-bit Absolute Short Address
;                                  pp = 6-bit I/O Short Address
;                                D  = (X0, X1, Y0, Y1,
;                                      A0, B0, A2, B2, A1, B1, A, B,
;                                      Rn, Nn, Mn,
;                                      SR, OMR, SP, SSH, SSL, LA, LC)
;
;   Timing           : 4 + mvb oscillator clock cycles
;   Memory           : 1 + ea program words
;
; -*BCHG
;   Name             : Bit Test and Change
;   Operation        : D[n] -> C
;                      D[n] -> D[n]
;   Assembler Syntax : BCHG #n, X:ea
;                      BCHG #n, X:aa
;                      BCHG #n, X:pp
;                      BCHG #n, Y:ea
;                      BCHG #n, Y:aa
;                      BCHG #n, Y:pp
;                      BCHG #n, D
;   Description      : Test the nth bit of the destination operand D, complement it, and store the
;                      result in the destination location. The state of the nth bit is stored in the
;                      carry bit C of the condition code register. After the test, the nth bit of the
;                      destination location is complemented. The bit to be tested is selected by an
;                      immediate bit number from 0-23. This instruction performs a read-modify-write
;                      operation on the destination locatiob using two destination accesses before
;                      releasing the bus. This instruction providesa test-and-change capability which
;                      is useful for synchronizing multiple processors using a shared memory. This
;                      instruction can use all memory alterable addressing modes.
;
;   Example          : BCHG #$7,X:<<$FFE2            ;test and change bit 7 in I/O Port B DDR
;
;                      Before Execution:       After Execution:
;                      X:$FFE2 = $000000       X:$FFE2 = $000080
;                      SR      =   $0300       SR      =   $0300
;
;   Explanation      : Prior to execution, the 24-bit X memory location X:$FFE2 (I/O port B data
;                      direction register) contains the value $000000. The execution of the BCHG #$7,
;                      X:<<$FFE2 instructiontests the state of the 7th bit in X:$FFE2, sets the carry
;                      bit C accordingly, and then complements the 7th bit in X:$FFE2.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;     > CCR Condition Codes :
;         For destination operand SR :
;                      C  Changed if bit 0 is specified. Not affected otherwise.
;                      V  Changed if bit 1 is specified. Not affected otherwise.
;                      Z  Changed if bit 2 is specified. Not affected otherwise.
;                      N  Changed if bit 3 is specified. Not affected otherwise.
;                      U  Changed if bit 4 is specified. Not affected otherwise.
;                      E  Changed if bit 5 is specified. Not affected otherwise.
;                      L  Changed if bit 6 is specified. Not affected otherwise.
;
;         For other destination operands:
;                      C  Set if bit tested is set. Cleared otherwise.
;                      V  Not Affected.
;                      Z  Not Affected.
;                      N  Not Affected.
;                      U  Not Affected.
;                      E  Not Affected.
;                      L  Not Affected.
;
;     > MR Status Bits:
;         For destination operand SR:
;                      I0 Changed if bit 8 specified. Not affected otherwise.
;                      I1 Changed if bit 9 specified. Not affected otherwise.
;                      S0 Changed if bit 10 specified. Not affected otherwise.
;                      S1 Changed if bit 11 specified. Not affected otherwise.
;                      T  Changed if bit 13 specified. Not affected otherwise.
;                      LF Changed if bit 15 specified. Not affected otherwise.
;
;         For other destination operands:
;                      I0 Not affected
;                      I1 Not affected
;                      S0 Not affected
;                      S1 Not affected
;                      T  Not affected
;                      LF Not affected
;
;   Instruction Form : BCHG  #n,X:ea
;                      BCHG  #n,Y:ea
;                      BCHG  #n,X:aa
;                      BCHG  #n,Y:aa
;                      BCHG  #n,X:pp
;                      BCHG  #n,Y:pp
;                      BCHG  #n,D
;
;                            #n = bit number
;                                 ea = (Rn)-Nn,
;                                      (Rn)+Nn,
;                                      (Rn)-,
;                                      (Rn)+,
;                                      (Rn),
;                                      (Rn+Nn),
;                                     -(Rn),
;                                       Absolute address
;                                 aa = 6-bit Absolute Short Address
;                                 pp = 6-bit I/O Short Address
;                               D  = (X0, X1, Y0, Y1,
;                                     A0, B0, A2, B2, A1, B1, A, B,
;                                     Rn, Nn, Mn,
;                                     SR, OMR, SP, SSH, SSL, LA, LC)
;
;   Timing           : 4 + mvb oscillator clock cycles
;   Memory           : 1 + ea program words
;
; -*BTST
;   Name             : Bit Test on Memory
;   Operation        : D[n] -> C
;   Assembler Syntax : BTST #n, X:ea
;                      BTST #n, X:aa
;                      BTST #n, X:pp
;                      BTST #n, Y:ea
;                      BTST #n, Y:aa
;                      BTST #n, Y:pp
;                      BTST #n, D
;   Description      : Test the nth bit of the destination operand D. The state of the nth bit is
;                      stored in the carry bit C of the condition code register. The bit to be tested
;                      is selected by an immediate bit number from 0-23. This instruction is useful
;                      for performing serial to parallel conversion when used with the apropriate
;                      rotate instructions. This instruction can use all memory alterable addressing
;                      modes.
;
;   Example          : BTST  #$1, X:<<$FFEE    ; read SSI serial input flag IF1 into C bit
;                      ROL      A              ; rotate carry bit C into LSB of A1
;
;                      Before Execution:       After Execution:
;                      X:$FFEE = $000002       X:$FFEE = $000002
;                      SR      =   $0300       SR      =   $0301
;
;   Explanation      : Prior to execution, the 24-bit X memory location X:$FFEE (I/O SSI status
;                      register) contains the value $000002. The execution of the BTST #$1, X:<<$FFEE
;                      instruction tests the state of the 1stbit (serial input flag IF1) in X:$FFEE
;                      and sets the carry bit C accordingly. This instruction sequence illustrates
;                      serial to parallel conversion using the carry bit C and the 24-bit A1 register.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;     > CCR Condition Codes :
;                      C  Set if bit tested is set. Cleared otherwise
;                      V  Not Affected
;                      Z  Not Affected
;                      N  Not Affected
;                      U  Not Affected
;                      E  Not Affected
;                      L  Not Affected
;
;     > MR Status bits are not affeted.
;
;     > SP Stack Pointer :
;         For destination operand SSH    : SP - Decrement by 1.
;         For other destination operands : SP - Not affected.
;
;   Instruction form : BTST #n, X:ea
;                      BTST #n, Y:ea
;                      BTST #n, X:aa
;                      BTST #n, Y:aa
;                      BTST #n, X:pp
;                      BTST #n, Y:pp
;                      BTST #n, D
;
;                           #n = bit number
;                                 ea = (Rn)-Nn,
;                                      (Rn)+Nn,
;                                      (Rn)-,
;                                      (Rn)+,
;                                      (Rn),
;                                      (Rn+Nn),
;                                     -(Rn),
;                                       Absolute address
;                                 aa = 6-bit Absolute Short Address
;                                 pp = 6-bit I/O Short Address
;                               D  = (X0, X1, Y0, Y1,
;                                     A0, B0, A2, B2, A1, B1, A, B,
;                                     Rn, Nn, Mn,
;                                     SR, OMR, SP, SSH, SSL, LA, LC)
;
;   Timing           : 4 + mvb oscillator clock cycles
;   Memory           : 1 + ea program words
;
; *****************************************************************************
; > Loop Instructions - Motorola (c) 1990
;
; -*DO
;   Name             : Start Hardware Loop
;   Operation        : SP+1->SP, LA->SSH, LC->SSL, X:ea->LC
;   |                  SP+1->SP, PC->SSH, SR->SSL, expr-1->LA
;   |                  1->LF
;   Assembler Syntax : DO X:ea,expr
;
;   Operation        : SP+1->SP, LA->SSH, LC->SSL, X:aa->LC
;   |                  SP+1->SP, PC->SSH, SR->SSL, expr-1->LA
;   |                  1->LF
;   Assembler Syntax : DO X:aa,expr
;
;   Operation        : SP+1->SP, LA->SSH, LC->SSL, Y:ea->LC
;   |                  SP+1->SP, PC->SSH, SR->SSL, expr-1->LA
;   |                  1->LF
;   Assembler Syntax : DO Y:ea,expr
;
;   Operatiion       : SP+1->SP, LA->SSH, LC->SSL, Y:aa->LC
;   |                  SP+1->SP, PC->SSH, SR->SSL, expr-1->LA
;   |                  1->LF
;   Assembler Syntax : DO Y:aa,expr
;
;   Operation        : SP+1->SP, LA->SSH, LC->SSL, #xxx->LC
;   |                  SP+1->SP, PC->SSH, SR->SSL, expr-1->LA
;   |                  1->LF
;   Assembler Syntax : DO #xxx,expr
;
;   Operation        : SP+1->SP, LA->SSH, LC->SSL, S->LC
;   |                  SP+1->SP, PC->SSH, SR->SSL, expr-1->LA
;   |                  1->LF
;   Assembler Syntax : DO S,expr
;
; > End of Loop      : SSL(LF)->SR, SP-1->SP
;                      SSH->LA, SSL->LC, SP-1->SP
;
;   Description      : Begin a hardware Do loop that is to be repeated the number of times specified
;                      in the instruction's source operand and whose range of execution is terminated
;                      by the destination operand (previously shown as "expr"). No overhead other
;                      than the execution of this DO instruction is required to set up this loop. DO
;                      loops can be nested and the loop count can be passed as a parameter.
;
;                      During the first instruction cycle, the current contents of the loop address
;                      (LA) and the loop counter (LC) registers are pushed onto the system stack. The
;                      DO instruction's source operand is then loaded into the loop counter (LC)
;                      register. The LC register countains the remaining number of times the DO loop
;                      will be executed and can be accessed from inside the DO loop subject to
;                      certain restrictions. If LC equals zero, the DO loop is executed 65536 times.
;                      All address register indirect addressing modes may be used to generate the
;                      effective address of the source operand. If immediate short data is specified,
;                      the 12 LS bits of LC are loaded with the 12-bit immediate value, and the four
;                      MS bits of LC are cleared.
;
;                      During the second instruction cycle, the current contents of the program
;                      counter (PC) register and the status register (SR) are pushed onto the system
;                      stack. The stacking of the LA, LC, PC, and SR registers is the mechanisme
;                      which permits the nesting of DO loops. The DO instruction's destination
;                      operand (shown as "expr") is then loaded into the loop address (LA) register.
;                      The value in the program counter (PC) register pushed onto the system stack is
;                      the address of the first instruction following the DO instruction (i.e., the
;                      first actual instruction in the DO loop). This value is read (i.e., copied but
;                      not pulled) fromthe top of the system stackto return to the top of the loop
;                      for another pass through the loop.
;
;                      During the third instruction cycle, the loop flag (LF) is set. This results in
;                      the PC being reapeatedly compared with LA to determine if the last instruction
;                      in the loop has been fetched and the loop counter (LC) is tested. If LC not
;                      equal to one, it is decremented by one and SSH is loaded into the PC to fetch
;                      the first instruction in the loop again. If LC equals one, the "end-of-loop"
;                      processing begins.
;
;                      When executing a DO loop, the instructions are actually fetched each time
;                      through the loop. Therefore, a DO loop can be interrupted. DO loops can also
;                      be nested. When DO loops ar nested, the end-of-loop addresses must also be
;                      nested and are not allowed to be equal. The assembler generates an error
;                      message when DO loops are improperly nested. Nested DO loops are illustratedin
;                      the example.
;
;               NOTE : The assembler calculates the end-of-loop address to be loaded into LA
;                      (the absolute address extension word) by evaluating the end-of-loop expression
;                      "expr" and subtracting one. This is done to accommodate the case where the
;                      last word in the DO loop is a two word instruction. Thus, the end-of-loop
;                      expression "expr" in the source code must represent the address of the
;                      instruction AFTER the last instruction in the loop as shown in example.
;
;                      During the "end-of-loop" processing, the loop flag (LF) from the lower position
;                      of the contents of the loop address (LA) are restored from the upper portion (SSH)
;                      of (SP-1), the contents of the loop counter (LC) register are restored from
;                      the lower portion (SSL) of (SP-1) and the stack pointer (SP) is decremented by
;                      two. Instruction fetches now continue at the address of the instruction
;                      following the last instruction in the DO loop. Note that LF is the only bit in
;                      the SR that is restored after a hardware DO loop has been exited.
;
;               NOTE : The LF is cleared by a hardware reset.
;
;   Restrictions     : The "end-of-loop" comparison previously described actually occurs at
;                      instruction fetch time. That is, LA is being compared with PC when the
;                      instruction at LA-2 is being executed. Therefore, instructions which acceses
;                      the program controller register and/or change program flow canot be used in
;                      locations LA-2, LA-1 or LA.
;
;                      Proper DO loop operation is not guaranteed if an instruction starting at
;                      address LA-2, LA-1 or LA specifies one of the program controller registers SR,
;                      SP, SSL, LA, LC, or (implicitly) PC as a destination register. Similary, the
;                      SSH program controller register may not be specified as a source or
;                      destination register in an instruction starting at address LA-2, LA-1, or LA.
;                      Additionally, the SSH register cannot be specified as a source register in the
;                      DO instruction itself and LA cannot be used as a target for jumps to
;                      subroutine (i.e., JSR, JScc, JSSET, or JSCLR to LA). A DO instruction cannot
;                      be repeated using the REP instruction.
;
;                      The following instructions cannot begin at the indicated position(s) near the
;                      end of a DO loop:
;
;              At LA-2, LA-1, and LA
;                      DO
;                      MOVEC from SSH
;                      MOVEM from SSH
;                      MOVEP from SSH
;                      MOVEC to LA, LC, SR, SP, SSH, or SSL
;                      MOVEM to LA, LC, SR, SP, SSH, or SSL
;                      MOVEP to LA, LC, SR, SP, SSH, or SSL
;                      ANDI MR
;                      ORI MR
;                      Two word instructions which read LC, SP or SSL
;
;              At LA-1
;                      Single-word instructions (except REP) which read LC, SP, or SSL, JCLR, JSET,
;                      two-word JMP, two word Jcc.
;
;              At LA
;                      any two-word instruction
;                      Jcc                     REP
;                      JCLR                    RESET
;                      JSET                    RTI
;                      JMP                     RTS
;                      JScc                    STOP
;                      JSR                     WAIT
;
;              Other Restrictions :
;                      DO SSH,xxxx
;                      JSR to (LA) whenever the loop flag (LF) is set
;                      JScc to (LA) whenever the loop flag (LF) is set
;                      JSCLR to (LA) whenever the loop flag (LF) is set
;                      JSSET to (LA) whenever the loop flag (LF) is set
;
;                      A DO instruction cannot be repeated using the REP instruction.
;
;               NOTE : Due to pipelining, if an address register (Rn, Nn or Mn) is changed using
;                      a move-type instruction (LUA, Tcc, MOVE, MOVEC, MOVEM, MOVEP or parallel
;                      move), the new contents of the destination address register will not be
;                      available for use during the folowing instruction (i.e., there is a single
;                      instruction cycle pipeline delay). This restriction also applies tothe
;                      situation in which the lat instruction in a DO loop changes an address
;                      register and the first instruction at the top of the DO loop uses that same
;                      address register. The top instruction becomes the following instruction
;                      because of the loop construct.
;                      Similary, since the DO instruction accesses the program controller registers,
;                      the DO instrcuction must not be immediately preceded byany of the following
;                      instructions :
;
;               Immediately before DO :
;                      MOVEC to LA, LC, SSH, SSL, or SP
;                      MOVEM to LA, LC, SSH, SSL, or SP
;                      MOVEP to LA, LC, SSH, SSL, or SP
;                      MOVEC from SSH
;                      MOVEM from SSH
;                      MOVEP from SSH
;
;   Example          : DO #cnt1,END1           ;begin outer DO loop
;                       :
;                      DO #cnt2,END2           ;begin inner DO loop
;                       :
;                       :
;                      MOVE  A,X:(R0)+         ;last instruction in inner loop
;                       :                              ;(in outer loop)
;          END2                                ;last instruction in outer loop
;                      ADD   A, B  X:(R1)+, X0 ;first instruction after outer loop
;          END1        ...
;
;   Explanation      : This example illustrates a nested DO loop. The outer DO loop will be executed
;                      "cnt1" times while the inner DO loop wile be executed ("cnt1" * "cnt2") times.
;                      Note that the labels END1 and END2 are located at the first instruction past
;                      the end of the DO loop, as mentioned above, and are nested properly.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      LF  Set when a DO loop is in progress
;                      L   Set if data limiting occurred
;
;   Instruction Form : DO X:ea, expr
;                      DO Y:ea, expr
;                      DO X:aa, expr
;                      DO Y:aa, expr
;                      DO #xxx, expr
;                      DO    S, expr
;
;                               expr = 16-bit Absolute Adress
;                           ea = (Rn)-Nn,
;                                (Rn)+Nn,
;                                (Rn)-,
;                                (Rn)+,
;                                (Rn),
;                                (Rn+Nn),
;                               -(Rn)
;                           aa = 6-bit Absolute Short Address
;                         #xxx = 12-bit Immediate Short Data
;                            S = (X0, X1, Y0, Y1,
;                                 A0, B0, A2, B2, A1, B1, A, B,
;                                 SR, OMR, SP, SSL, LA, LC,
;                                 Rn, Nn, Mn)
;
;             NOTE 1 : Implementation Notes:
;
;                      For DO SP,expr The actual value that will be load into the loop counter (LC) is
;                      the value of the stack pointer (SP) before the execution of the DO
;                      instruction, incremented by 1.
;                      Thus, if SP=3, the execution of the DO SP,expr instruction will load the loop
;                      counter (LC) with the value LC = 4.
;                      For DO SSL,expr   The LC will be loaded with the previous value wich was saved on
;                      the stack by the DO instruction itself.
;
;             NOTE 2 : If A or B is specified as a source operand, the accumulator value is optionally
;                      shifted according to the scaling mode bits in the status register. If the data
;                      out of the shifter indicates that the accumulator extension is in use, the
;                      24-bit data is limited to a maximum positive or negative saturation constant.
;                      The shifted and limited value is loaded into LC, although A or B remain
;                      unchanged.
;
;   Timing           : 6 + mv oscillator clock cycles
;   Memory           : 2 program words
;
; -*ENDDO
;   Name             : Exit from Hardware Loop
;   Operation        : SSL (LF) -> SR, SP-1 -> SP
;                      SSH -> LA, SSL -> LC, SP-1 -> SP
;   Assembler Syntax : ENDDO
;   Description      : Terminate the current hardware loop before the current loop counter (LC) equals
;                      one. If the value of the current DO loop counter (LC) is needed, it must be
;                      read before the execution of the ENDDO instruction. Initially, the loop flag
;                      (LF) is restored from the system stack and the remaining portion of the status
;                      register (SR) and the Program counter are purged from the system stack. The LA
;                      and the LC registers are then restored from the system stack.
;   Restrictions     : Due to pipelining and the fact that the ENDDO instruction accesses the program
;                      controller registers, the ENDDO instruction must not be immediately preceded
;                      by any of the following instructions :
;
;              Immediately before ENDDO
;                      MOVEC to LA, LC, SR, SSH, SSL, or SP
;                      MOVEM to LA, LC, SR, SSH, SSL, or SP
;                      MOVEP to LA, LC, SR, SSH, SSL, or SP
;                      MOVEC from SSH
;                      MOVEM from SSH
;                      MOVEP from SSH
;                      ORI MR
;                      ANDI MR
;
;                      Also, the ENDDO instruction cannot be the next to last (LA-1) or last (LA)
;                      instruction in a DO loop.
;
;   Example          : DO Y0, NEXT             ;exec. loop ending at NEXT (Y0) time
;                       :
;                      MOVEC LC,A              ;get current value of loop counter
;                      CMP Y1, A               ;compare LC with value in Y1
;                      JNE ONWARD              ;go to ONWARD ifLC not equal to Y1
;                      ENDDO                   ;LC equals to Y1, restore all DO registers
;                      JMP NEXT                ;go to NEXT
;          ONWARD                              ;LC not equal to Y1, continue DO loop
;                       :                      ;(last instruction in DO loop)
;          NEXT        MOVE #$123456,X1        ;(first instruction AFTER DO loop)
;
;   Explanation      : This example illustrate the use of the ENDDO instruction to terminate the
;                      current DO loop. The value of the loop counter is compared with the value in
;                      the Y1 register to determine if execution of the DO loop should continue. Note
;                      that the ENDDO instruction updates certain program controller registers but
;                      does not automatically jump past the end of the DO loop. Thus, if this action
;                      is desired, a JMP instruction (i.e., JMP NEXT as previously shown) must be
;                      included after the ENDDO instruction to transfer program control to the first
;                      instruction past the end of the DO loop.
;   Condition Codes  : The condition codes are not affected by this instruction.
;   Instruction Form : ENDDO
;   Timing           : 2 oscillator clock cycles
;   Memory           : 1 program word
;
; *****************************************************************************
; > Move Instructions - Motorola (c) 1990
;
; -*LUA
;   Name             : Load Update Address
;   Operation        : ea -> D
;   Assembler Syntax : LUA   ea, D
;   Description      : Load the updated address into the destination address register D. The source
;                      address register and the update mode used to compute the updated address are
;                      specified by the effective address (ea). Note that the source address register
;                      specified in the effective address is not updated. All update addressing modes
;                      may be used.
;
;               NOTE : This instruction is considered to be a move-type instruction. Due to
;                      pipelining, the new contents of the destination address register (Rn or Nn)
;                      will not be available for use during the following instruction (i.e., there is
;                      a single instruction cycle pipeline delay).
;
;   Example          : LUA   (R0)+N0, R1       ; update R1 using (R0)+N0
;
;                      Before Execution:       After Execution:
;                      R0 = $0003              R0 = $0003
;                      N0 = $0005              N0 = $0005
;                      R1 = $0004              R1 = $0008
;
;   Explanation      : Prior to execution, the 16-bit address register R0 contains the value $0003,
;                      the 16-bit address register N0 contains the value $0005, and the 16-bit
;                      address register R1 contains the value $0004. The execution of the LUA
;                      (R0)+N0,R1 instruction adds the contents of the R0 register to the contents of
;                      the N0 register and stores the resulting updated address in R1. The contents
;                      of both the R0 and N0 address registers are not affected.
;   Condition Codes  : The condition codes are not affected by this instruction.
;   Instruction Form : LUA   ea, D
;
;                            ea = (Rn)-Nn,
;                                 (Rn)+Nn,
;                                 (Rn)-,
;                                 (Rn)+
;                                D  = (Rn, Nn)
;
;   Timing           : 4 oscillator clock cycles
;   Memory           : 1 program word
;
; - MOVE
;   Name             : Move Data
;   Operation        : S->D
;   Assembler Syntax : MOVE  S, D
;   Description      : Move the contents of the specified data source S to the specified destination
;                      D. This instruction is equivalent to a data ALU NOP with a parallel data move.
;
;                      When a 56-bit accumulator (A or B) is specified as a source operand S, the
;                      accumulator value is optionally shifted according to the scaling mode bits S0
;                      and S1 in the SR. If the data out of the shifter indicates that the
;                      accumulator extension register is in use and the data is to be moved into a 24
;                      or 48-bit destination, the value stored in the destination D is limited to a
;                      maximum positive or negative saturation constant to minimize truncation error.
;                      Limiting does not occurif an individual 24-bit accumulator register (A1,A0,B1,
;                      or B0) is specified as a source operand instead of the full 56-bit accumulator
;                      (A or B). This limiting features allows block floating-point operations to be
;                      performed with error detection since the L bit in the condition code register
;                      is latched.
;
;                      When a 56-bit accumulator (A orB) is specified as a destination operand D, any
;                      24-bit source data to be moved into that accumulator is automatically extended
;                      to 56-bits by sign extending the MS bit o the source operand (bit23) and
;                      appending the source operand with 24 LS zeros. Similary, any 48-bit source
;                      data to be load into a 56-bit accumulator isautomatically sign extended to 56
;                      bits. Note that for 24-bit source operands both the automatic sign-extension
;                      and zeroing features may be disabled by specifying the destination register to
;                      be one of the individual 24-bit accumulator registers (A1 orB1). Similary, for
;                      48-bit source operands, the automatic sign-extension feature may be disabled
;                      by using the long memory move addressing mode specifying A10 or B10 as the
;                      destination operand.
;
;   Example          : MOVE  X0, A1   ;move X0 to A1 without sign ext. or zeroing
;
;                      Before Execution:       After Execution:
;                      X0 =           $234567  X0 =           $234567
;                      A  = $FF:FFFFFF:FFFFFF  A  = $FF:234567:FFFFFF
;
;   Explanation      : Prior to execution, the 56-bit A accumulator contains the value
;                      $FF:FFFFFF:FFFFFF, and the 24-bit X0 register contains the value $234567. The
;                      execution of the MOVE X0,A1 instruction moves the 24-bit value in the X0
;                      register into the  24-bit A1 register without automatic sign extension and
;                      without automatic zeroing.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L- Set if data limiting has occured during parallel move
;
;   // Move Descript : Thirty of the sixty-two instructions provide the capability to specify an
;                      optional parallel data bus movement over the X and/or Y data bus. This allows
;                      a data ALU operation to be executed in parallel with up to two data bus moves
;                      during the instruction cycle. Ten types of parallel moves are permitted,
;                      including register to register moves, register to memory moves, and memory to
;                      register moves. However, not all addressing modes are allowed for each type of
;                      memory reference. Addressing mode restrictions which apply to specific types
;                      of moves are noted in the individual move operation descriptions. The
;                      following section contains detailed descriptions about each type of parallel
;                      move operation.
;
;                      When a 56-bit accumulator (A or B) is specified as a source operand S, the
;                      according to the scaling mode bits S0 and S1 in the system status register
;                      (SR). If the data out of the shifter indicates that the accumulator extension
;                      register is in use and the data is to be moved into a 24- or 48-bit
;                      destination, the value stored in the destination D is limited to a maximum
;                      positive or negative saturation constant to minimize truncation error.
;                      Limiting does not occur if an individual 24-bit accumulator register (A1, A0,
;                      B1, or B0) isspecified as a source operand instead of a full 56-bit
;                      accumulator (A or B). This limiting feature allows block floting-point
;                      operations to be performed with error detection since the L bit in the
;                      condition code register is latched.
;
;                      When a 56-bit accumulator (A or B) is specified as a destination operand D, any
;                      24-bit source data to be moved into that accumulator is automatically extended
;                      to 56 bits by sign extending the MS bit of the source operand (bit 23) and
;                      appending the source operand with 24 LS zeros. Similary, any 48-bit source
;                      data to be loaded into a 56-bit accumulator is automatically sign extended to
;                      56 bits. Note that for 24-bit source operands both the automatic
;                      sign-extension and zeroing features may be disabled by specifying the
;                      destination register to be one of the individual 24-bit accumulator registers
;                      (A1 or B1). Similary, for 48-bit source operands, the automatic sign-extension
;                      feature may be disabled by using the long memory move addressing mode and
;                      specifying A10 or B10 as the destination operand.
;
;                      Note that the symbols used in decoding the various opcode fields of an
;                      instruction or parallel move are completely arbitrary. Furthermore, the opcode
;                      symbols used in one instruction or parallel move are completely independent of
;                      the opcode symbols used in a different instruction or parallel move.
;
;   Timing           : 2 + mv oscillator cycles
;   Memory           : 1 + mv program words
;
; -*MOVEC
;   Name             : Move Control Register
;   Operation        :                         Assembler Syntax :
;                      X:ea->D1                MOVEC X:ea,D1
;                      X:aa->D1                MOVEC X:aa,D1
;                      S1->X:ea                MOVEC S1,X:ea
;                      S1->X:aa                MOVEC S1,X:aa
;                      Y:ea->D1                MOVEC Y:ea,D1
;                      Y:aa->D1                MOVEC Y:aa,D1
;                      S1->Y:ea                MOVEC S1,Y:ea
;                      S1->Y:aa                MOVEC S1,Y:aa
;                      S1->D2                  MOVEC   S1,D2
;                      S2->D1                  MOVEC   S2,D1
;                      #xxxx->D1               MOVEC #xxxx,D1
;                      #xx->D1                 MOVEC #xx,D1
;
;   Description      : Move the contents of the specified source control register S1 or S2 to the
;                      specified destination or move the specified source to the specified
;                      destination control register D1 or D2. The control registers S1 and D1 are
;                      subset of the S2 and D2 register set and consist of the address ALU modifier
;                      registers and the program controller registers. These registers. These
;                      registers may be moved to or from any other register or memory space. All
;                      memory addressing modes, as well as an immediate short addressing mode, may be
;                      used.
;
;                      If the system stack register SSH is specified as a source operand, the system
;                      stack pointer (SP) is postdecremented by 1 after SSH has been read. If the
;                      system stack register SSH is specified as a destination operand, the system
;                      stack pointer (SP) is preincremented by 1 before SSH is written. This allows
;                      the system stack to be efficiently extended using software stack pointer
;                      operations.
;
;                      When a 56-bit accumulator (A or B) is specified as a source operand, the
;                      accumulator value is optionnaly shifted according to the scaling mode bits S0
;                      and S1 in the system status register (SR). If the data out of the shifter
;                      indicates that the accumulator extension register is in use and the data is to
;                      be moved into a 24-bit destination, the value stored in the destination is
;                      limited to a maximum positive or negative saturation constant to minimize
;                      truncation error. If the data is to be moved into 16-bit destination and the
;                      accumulator extension register is in use, the value is limited to a maximum
;                      positive or negative saturation constant whose LS 16 bits are then stored in
;                      the 16-bit destination register. Limiting does not occur if an individual
;                      24-bit accumulator register (A1, A0, B1 or B0) is specified as a source
;                      operand instead of the full 56-bit accumulator (A or B). This limiting
;                      features allows block floating-point operations to be performed with error
;                      detection since the L bit in the condition code register is latched.
;
;                      When a 56-bit accumulator (A or B) is specified as a destination operand, any
;                      24-bit source data to be moved into that accumulator is automatically extended
;                      to 56 bits by sign extending the MS bits ofthe source operand (bit 23) and
;                      appending the source operand with 24 LS zeros. Whenever a 16-bit source
;                      operands is to be moved into a 24-bit destination, the 16-bit value is stored
;                      in the 16 LS 16 bits of the 24-bit destination, and the MS 8 bits of that
;                      destination are zeroed. Similary, whenever a 16-bit source operand is to be
;                      moved into a 56-bit accumulator, the 16-bit value is moved into the LS 16 bits
;                      of the MSP portion of the accumulator (A1 or B1), the MS 8 bits of the MSP
;                      portion of that accumulator are zeroed, and the resulting 24-bit value is
;                      extended to 56 bits by sign extending the MS bit and appending the result with
;                      24 LS zeros. Note that for 24-bit source operands both the automatic
;                      sign-extension and zeroing features may be disabled by specifying the
;                      destination register to be one of the individual 24-bit accumulator registers
;                      (A1 or B1).
;
;               NOTE : Due to pipelining, if an address register (R,N or M) is changed using a
;                      move-type instruction, the new contents of the destination address register
;                      will not beavailable for use during the following instruction (i.e., there is
;                      a single instruction cycle pipeline delay).
;   Restrictions     :
;               NOTE : The following restrictions represent very unusual operations, which
;                      probably would never be used but are listed only for completeness.
;
;                    - A MOVEC instruction used within a DO loop which specifies SSH as the source
;                      operand or LA, LC, SR, SP, SSH  or SSL as the destination operand cannot begin
;                      at the address LA-2, LA-1, or LA within that DO loop.
;                    - A MOVEC instruction which specifies SSH as the source operand or LA, LC, SSH,
;                      SSL or SP as the destination   operand cannot be used immediately before a DO
;                      instruction.
;                    - A MOVEC instruction which specifies SSH as the source operand or LA, LC, SR,
;                      SSH, SSL or SP as the destina   tion operand cannot be used immediately before
;                      an ENDDO instruction.
;                    - A MOVEC instruction which specifies SSH as the source operand or SR, SSH, SSL,
;                      or SP as the destination ope   rand cannot be used immediately before an RTI
;                      instruction.
;                    - A MOVEC instruction which specifies SSH as the source operand or SSH, SSL, or
;                      SP as the destination operand   cannot be used immediately before an RTS
;                      instruction.
;                    - A MOVEC instruction which specifies SP as the destination operand cannot be
;                      used immediately before a        MOVEC, MOVEM, or MOVEP instruction which
;                      specifies SSH or SSL as the source operand.
;                    - A MOVEC SSH,SSH instruction is illegal and cannot be used.
;
;   Example          : MOVEC LC, X0   ;move LC into X0
;
;                      Before Execution:       After Execution:
;                      LC =   $0100            LC =   $0100
;                      X0 = $123456            X0 = $000100
;
;   Explanation      : Prior to execution, the 16-bit loop couter (LC) register contains the value
;                      $0100, and the 24-bit X0 register contains the value $123456. The execution of
;                      the MOVEC LC,X0 instruction moves the contents of the 16-bit LC register into
;                      the 16 LS bits of the 24-bit X0 register and zeros the 8 MS bits of the X0
;                      register.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;              For D1 or D2 = SR operand:
;                      L  Set according to bit 6 of the source operand
;                      E  Set according to bit 5 of the source operand
;                      U  Set according to bit 4 of the source operand
;                      N  Set according to bit 3 of the source operand
;                      Z  Set according to bit 2 of the source operand
;                      V  Set according to bit 1 of the source operand
;                      C  Set according to bit 0 of the source operand
;
;              For D1 and D2 != SR operand:
;                      L  Set if data limiting has occured during move
;
;   Instruction Form : MOVEC X:ea, D1
;                      MOVEC X:aa, D1
;                      MOVEC   S1, X:ea
;                      MOVEC   S1, X:aa
;                      MOVEC Y:ea, D1
;                      MOVEC Y:aa, D1
;                      MOVEC   S1, Y:ea
;                      MOVEC   S1, Y:aa
;                      MOVEC   S1, D2
;                      MOVEC   S2, D1
;                      MOVEC #xxxx, D1
;                      MOVEC #xx , D1
;
;                            #xxxx = Immediate Data
;                            #xx = 8-bit Immediate Short Data
;                              aa = 6-bit Absolute Short Address
;                              ea = (Rn)-Nn,
;                                   (Rn)+Nn,
;                                   (Rn)-,
;                                   (Rn)+,
;                                   (Rn),
;                                   (Rn+Nn),
;                                  -(Rn),
;                                    Absolute address
;                              S1 = (Mn, SR, OMR, SP, SSH, SSL, LA, LC)
;                                  D1 = (Mn, SR, OMR, SP, SSH, SSL, LA, LC)
;                              S2 = (X0, X1, Y0, Y1,
;                                    A0, B0, A2, B2, A1, B1, A, B,
;                                    Rn, Nn, Mn,
;                                    SR, OMR, SP, SSH, SSL, LA, LC)
;                                  D2 = (X0, X1, Y0, Y1,
;                                        A0, B0, A2, B2, A1, B1, A, B,
;                                        Rn, Nn, Mn,
;                                        SR,OMR, SP, SSH, SSL, LA, LC)
;
;   Timing           : 2 + mvc oscillator clock cycles
;   Memory           : 1 + ea program words
;
; -*MOVEM
;   Name             : Move Program Memory
;   Operation        :                         Assembler Syntax:
;                      S->P:ea                 MOVEM S,P:ea
;                      S->P:aa                 MOVEM S,P:aa
;                      P:ea->D                 MOVEM P:ea,D
;                      P:aa->D                 MOVEM P:aa,D
;   Description      : Move the specified operand from/to the specified operand from/to the specified
;                      program (P) memory location. This is a powerful move instruction in that the
;                      source and destination registers S and D may be any register. All memory
;                      alterable addressing modes may be used as well as the absolute short
;                      addressing mode.
;
;                      If the system stack register SSH is specified as a source operand, the system
;                      stack pointer (SP) is postdecremented by 1 after SSH has been read. If the
;                      system stack register SSH is specified as a destination operand, the system
;                      stack pointer (SP) is preincremented by 1 before SSH is written. This allows
;                      the system stack to be efficiently extended using software stack pointer
;                      operations.
;
;                      When a 56-bit accumulator (A or B) is specified as a source operand S, the
;                      is the scaling mode bits S0 and S1 in the system status register (SR). If data out
;                      of the shifter indicates that the accumulator extension register is in use and
;                      the data is to be moved into a 24-bit destination, the value stored in the
;                      destination is limited to a maximum positive or negative saturation constant
;                      to minimize truncation error. If a 24-bit source operand is to be moved into a
;                      16-bit destination register D, the 8 MS bits of the 24-bit source operand are
;                      discarded, and the 16 LS bits are stored in the 16-bit destination register.
;                      Limiting does not occur if an individual 24-bit accumulator register (A1, A0,
;                      B1 or B0) is specified as a source operand instead of the full 56-bit
;                      accumulator (A or B). This limiting feature allows block floating-point
;                      operations to be performed with error detection since the L bit in the
;                      condition code register is latched.
;
;                      When a 56-bit accumulator (A or B) is specified as a destination operand D, any
;                      24-bit source data to be moved into that accumulator is automatically extended
;                      to 56 bits by sign extending the MS bits of the source operand (bit 23) and
;                      appending the source operand with 24 LS zeros. Whenever a 16-bit source
;                      operand S is to be moved into 24-bit destination, the 16-bit source is loaded
;                      into the LS 16 bits of the destination operand, and the remaining 8 MS bits of
;                      the destination are zeroed. Note that for 24-bit source operands, both the
;                      automatic sign-extension and zeroing features may be disabled by specifying
;                      the destination register to be one of the individual 24-bit accumulator
;                      register (A1 or B1).
;
;               NOTE : Due to pipelining, if an address register (R,N, or M) is changed using a
;                      move-type instruction, the new contents of the destination address register
;                      will not beavailable for use during the following instruction (i.e., there is
;                      a single instruction cycle pipeline delay).
;
;    Restrictions    :
;                    - A MOVEM instruction used within a DO loop which specifies SSH as the source
;                      operand or LA, LC, SR, SP, SSH or SSL as the destination operand cannot
;                      begin at the address LA-2, LA-1, or LA within that DO loop.
;                    - A MOVEM instruction which specifies SSH as the source operand or LA, LC, SSH,
;                      SSL, or SP as the destination  operand cannot be used immediately before a DO
;                      instruction.
;                    - A MOVEM instruction which specifies SSH as the source operand or LA, LC, SR,
;                      SSH, SSL, or SP as the destination operand cannot be used immediately
;                      before an ENDDO instruction.
;                    - A MOVEM instruction which specifies SSH as the source operand or SR, SSH, SSL,
;                      or SP as the destination operand cannot be used immediately before an
;                      RTI instruction.
;                    - A MOVEM instruction which specifies SSH as the source operand or SSH, SSL, or
;                      SP as the destination operand  cannot be used immediately before an RTS
;                      instruction.
;                    - A MOVEM instruction which specifies SP as the destination operand cannot be
;                      used immediately before a MOVEC, MOVEM, or MOVEP instruction which
;                      specifies SSH or SSL as the source operand.
;
;   Example          : MOVEM P:(R5+N5), LC     ; move P:(R5+N5) into the loop counter (LC)
;
;                      Before Execution:       After Execution:
;                      P:(R5+N5) = $000116     P:(R5+N5) = $000116
;                      LC        =   $0000     LC        =   $0116
;
;   Explanation      : Prior to execution, the 16-bit loop couter (LC) register contains the value
;                      $0000, and the 24-bit program (P) memory locations P:(R5+N5) contains the
;                      value $0000, and the 24-bit program (P) memory location P:(R5+N5) into the
;                      16-bit LC register.
;
;   Conditions Codes : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      MR CCR
;
;              For D = SR operand :
;                      L  Set according to bit 6 of the source operand
;                      E  Set according to bit 5 of the source operand
;                      U  Set according to bit 4 of the source operand
;                      N  Set according to bit 3 of the source operand
;                      Z  Set according to bit 2 of the source operand
;                      V  Set according to bit 1 of the source operand
;                      C  Set according to bit 0 of the source operand
;
;              For D != SR operand :
;                      L  Set if data limiting has occured during move
;
;   Instruction Form : MOVEM    S, P:ea
;                      MOVEM    S, P:aa
;                      MOVEM P:ea,    D
;                      MOVEM P:aa,    D
;
;                              aa = 6-bit Absolute Short Data
;                              ea = (Rn)-Nn,
;                                   (Rn)+Nn,
;                                   (Rn)-,
;                                   (Rn)+,
;                                   (Rn),
;                                   (Rn+Nn),
;                                  -(Rn),
;                                    Absolute address
;                               S = (X0, X1, Y0, Y1,
;                                    A0, B0, A2, B2, A1, B1, A, B,
;                                    Rn, Nn, Mn,
;                                    SR, OMR, SP, SSH, SSL, LA, LC)
;                                     D = (X0, X1, Y0, Y1,
;                                          A0, B0, A2, B2, A1, B1, A, B,
;                                          Rn, Nn, Mn,
;                                          SR, OMR, SP, SSH, SSL, LA, LC)
;
;   Timing           : 2 + mvm oscillator clock cycles
;   Memory           : 1 + ea program words
;
; -*MOVEP
;   Name             : Move Peripheral Data
;   Operation        :                         Assembler Syntax:
;                      X:pp->D                 MOVEP X:pp,    D
;                      X:pp->X:ea              MOVEP X:pp, X:ea
;                      X:pp->Y:ea              MOVEP X:pp, Y:ea
;                      X:pp->P:ea              MOVEP X:pp, P:ea
;                      S->X:pp                 MOVEP    S, X:pp
;                      #xxxxxx->X:pp           MOVEP #xxxxxx, X:pp
;                      X:ea->X:pp              MOVEP X:ea, X:pp
;                      Y:ea->X:pp              MOVEP Y:ea, X:pp
;                      P:ea->X:pp              MOVEP P:ea, X:pp
;                      Y:pp->D                 MOVEP Y:pp,    D
;                      Y:pp->X:ea              MOVEP Y:pp, X:ea
;                      Y:pp->Y:ea              MOVEP Y:pp, Y:ea
;                      Y:pp->P:ea              MOVEP Y:pp, P:ea
;                      S->Y:pp                 MOVEP    S, Y:pp
;                      #xxxxxx->Y:pp           MOVEP #xxxxxx, Y:pp
;                      X:ea->Y:pp              MOVEP X:ea, Y:pp
;                      Y:ea->Y:pp              MOVEP Y:ea, Y:pp
;                      P:ea->Y:pp              MOVEP P:ea, Y:pp
;
;   Description      : Move the specified operand from/to the specified X or Y I/O peripheral. The I/O
;                      short addressing mode is used for the I/O peripheral address. All memory
;                      addressing modes may be used for the X or Y memory effective address.
;
;                      If the system stack register SSH is specified as a source operand, the system
;                      stack pointer (SP) is postdecremented by 1 after SSH has been read. If the
;                      system stack register SSH is specified as a destination operand, the system
;                      stack pointer (SP) is preincremented by 1 before SSH is written. This allows
;                      the system stack to be efficiently extended using software stack pointer
;                      operations.
;
;                      When a 56-bit accumulator (A or B) is specified as a source operand S, the
;                      accumulator value is optionally shifted according to the scaling mode bits S0
;                      and S1 in the system status register (SR). If the data out of the shifter
;                      indicates that the accumulator extension register is in use and the data is to
;                      be moved into a 24-bit destination, the value stored in the destination is
;                      limited to a maximum positive or negative saturation constant to minimize
;                      truncation error. If a 24-bit source operand is to be moved into a 16-bit
;                      destination register D, the 8 MS bits of the 24-bit source operand are
;                      discarded, and the 16 LS bits are stored in the 16-bit destination register.
;                      Limiting does not occur if an individual 24-bit accumulator register (A1, A0,
;                      B1 or B0) is specified as a source operand instead of the full 56-bit
;                      accumulator (A or B). This limiting feature allows block floating-point
;                      operations to be performed with error detection since the L bit in the
;                      condition code register is latched.
;
;                      When a 56-bit accumulator (A or B) is specified as a destination operand D, any
;                      24-bit source data to be moved into that accumulator is automatically extended
;                      to 56 bits by sign extending the MS bit of the source operand (bit 23) and
;                      appending the source operand with 24 LS zeros. Whenever a 16-bit source
;                      operand S is to be moved into a 24-bit destination, the 16-bit source is
;                      loaded into the LS 16 bits of the destination operand, and the remaining 8 MS
;                      bits of the destination are zeroed. Note that for 24-bit source operands both
;                      the automatic sign-extension and zeroing features may be disabled by
;                      specifying the destination register to be one of the individual 24-bit
;                      accumulator register (A1 or B1).
;
;               NOTE : Due to pipelining, if an address register (R, N or M) is changed using a
;                      move-type instruction, the new contents of the destination address register
;                      will not be available for use during the following instruction (i.e., there is
;                      a single instruction cycle pipeline delay).
;
;    Restrictions    :
;                NOTE: The following restrictions represent very unusual operations, which
;                      probably would never be used but are listed only for completeness.
;
;                    - A MOVEP instruction used within a DO loop which specifies SSH as the source
;                      operand or LA, LC, SR, SP, SSH  or SSL as the destination operand cannot begin
;                      at the address LA-2, LA-1 or LA within that DO loop.
;                    - A MOVEP instruction which specifies SSH as the source operand or LA, LC, SSH,
;                      SSL or SP as the destination   operand cannot be used immediately before a DO
;                      instruction.
;                    - A MOVEP instruction which specifies SSH as the source operand or LA, LC, SR,
;                      SSH, SSL or SP as the destina-   tion operand cannot be used immediately
;                      before an ENDDO instruction.
;                    - A MOVEP instruction which specifies SSH as the source operand or SR, SSH, SSL
;                      or SP as the destination ope-   rand cannot be used immediately before an RTI
;                      instruction.
;                    - A MOVEP instruction which specifies SSH as the source operand or SSH, SSL, or
;                      SP as the destination operand   cannot be used immediately before an RTS
;                      instruction.
;                    - A MOVEP instruction which specifies SP as the destination operand cannot be
;                      used immediately before a        MOVEC, MOVEM or MOVEP instruction which
;                      specifies SSH or SSL as the source operand.
;
;   Example          : MOVEP #$1113, X:<<$FFFE ;initialize Bus Control Register wait states
;
;                      Before Execution:       After Execution:
;                      X:$FFFE (BCR) = $FFFF   X:$FFFE (BCR) = $1113
;
;   Explanation      : Prior to execution, the 16-bit, X memory-mapped, I/O bus control register (BCR)
;                      contains the value $FFFF. The execution of the MOVEP #$1113,X:<<$FFFE
;                      instruction moves the value $1113 into the 16-bit bus control register
;                      X:$FFFE, resulting in one wait state for all external X, external Y and
;                      external program memory accesses and three wait states for al external I/O
;                      accesses.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;              For D = SR operand:
;                      L  Set according to bit 6 of the source operand
;                      E  Set according to bit 5 of the source operand
;                      U  Set according to bit 4 of the source operand
;                      N  Set according to bit 3 of the source operand
;                      Z  Set according to bit 2 of the source operand
;                      V  Set according to bit 1 of the source operand
;                      C  Set according to bit 0 of the source operand
;
;             For D != SR operand:
;                      L  Set if data limiting has occured during move
;
;   Instruction Form : MOVEP X:pp, D
;                      MOVEP X:pp, X:ea
;                      MOVEP X:pp, Y:ea
;                      MOVEP X:pp, P:ea
;                      MOVEP    S, X:pp
;                      MOVEP #xxxxxx, X:pp
;                      MOVEP X:ea, X:pp
;                      MOVEP Y:ea, X:pp
;                      MOVEP P:ea, X:pp
;                      MOVEP Y:pp,    D
;                      MOVEP Y:pp, X:ea
;                      MOVEP Y:pp, Y:ea
;                      MOVEP Y:pp, P:ea
;                      MOVEP    S, Y:pp
;                      MOVEP #xxxxxx, Y:pp
;                      MOVEP X:ea, Y:pp
;                      MOVEP Y:ea, Y:pp
;                      MOVEP P:ea, Y:pp
;
;                            #xxxxxx = Immediate Data
;                              pp = 6-bit I/O Short Address
;                              ea = (Rn)-Nn,
;                                   (Rn)+Nn,
;                                   (Rn)-,
;                                   (Rn)+,
;                                   (Rn),
;                                   (Rn+Nn),
;                                  -(Rn),
;                                    Absolute address
;                               S = (X0, X1, Y0, Y1,
;                                    A0, B0, A2, B2, A1, B1, A, B,
;                                    Rn, Nn, Mn,
;                                    SR, OMR, SP, SSH, SSL, LA, LC)
;                                     D = (X0, X1, Y0, Y1,
;                                          A0, B0, A2, B2, A1, B1, A, B,
;                                          Rn, Nn, Mn,
;                                          SR, OMR, SP, SSH, SSL, LA, LC)
;
;   Timing           : 4 + mvp oscillator clock cycles
;   Memory           : 1 + ea program words
;
; *****************************************************************************
; > Program Control Instructions - Motorola (c) 1990
;
; - ILLEGAL
;   Name             : Illegal Instruction
;   Operation        : Begin Illegal Instruction exception processing
;   Assembler Syntax : ILLEGAL
;   Description      : The ILLEGAL instruction is executed as if it were a NOP instruction. Normal
;                      instruction execution is suspend and illegal instruction exception processing
;                      is initiated. The interrupt vector address is located at address P:$3E. The
;                      interrupt priority level (I1,I0) is set to 3 in the status register if a long
;                      interrupt service routine is used. The pupose of the ILLEGAL instruction is to
;                      force the DSP into an illegal instruction exception for test purposes. If a
;                      fast interrupt is used with the ILLEGAL instruction, an infinite loop will be
;                      formed (an illegal instruction interupt normally returns to the illegal
;                      instruction) which can only be broke by a hardware reset. Therefore, only long
;                      interrupts should be used. Exiting an illegal instruction is a fatal error.
;                      The long exception routine should indicate this condition and cause the system
;                      to be restarted.
;
;                      If the ILLEGAL instruction is in a DO loop at LA and the instruction at LA-1 is
;                      being interrupted, then LC will be decremented twice due to the same mechanism
;                      that causes LC to be decremented twice if JSR, REP, etc. at LA are restricted.
;                      Clearly restriction cannot beimposed on illegal instructions.
;
;                      Since REP is uninterruptable, repeating an ILLEGAL instruction results in
;                      interrupt not being initiated until after completion of the REP. After
;                      servicing the interrupt, program control will return to the address of the
;                      second word following the ILLEGAL instruction. Of course, the ILLEGAL
;                      interrupt service routine should obort further processing, and the processor
;                      should be reinitialized.
;
;   Example          : ILLEGAL        ;begin ILLEGAL exception processing
;   Explanation      : The ILLEGAL instruction suspends normal instruction execution and initiates
;                      ILLEGAL exception processing.
;   Condition Codes  : The condition codes are not affected by this instruction.
;   Timing           : 8 oscillator clock cycles
;   Memory           : 1 program word
;
; -*Jcc
;   Name             : Jump Conditionally
;   Operation        :                         Assembler Syntax:
;                      If cc, then 0xxx -> PC  Jcc   xxx
;                      else PC+1 -> PC
;
;                      If cc, then ea -> PC    Jcc ea
;                      else PC+1 -> PC
;
;   Description      : Jump to the location in program memory given by the instruction's effective
;                      address if the specified if the specified condition is true. If the specified
;                      condition is false, the program counter (PC) is incremented and the effective
;                      address is ignored. However, the address register specified in the effective
;                      address field is always updated independently of the specified condition. All
;                      memory alterable addressing modes may be used for effective address. A fast
;                      Short Jump addressing mode may also be used. The 12-bit data is zero extended
;                      to form the effective address. The term "cc" may specify the following
;   Conditions       : "cc" Mnemonic Condition
;                       CC (HS) carry clear (higher or same)   C = 0
;                       CS (LO) carry set (lower)              C = 1
;                       EC      extension clear                E = 0
;                       EQ      equal                          Z = 1
;                       ES      extension set                  E = 1
;                       GE      greater than or equal        N^V = 0
;                       GT      greater than             Z+(N^V) = 0
;                       LC      limit clear                    L = 0
;                       LE      less than or equal       Z+(N^V) = 1
;                       LS      limit set                      L = 1
;                       LT      less than                    N^V = 1
;                       MI      minus                          N = 1
;                       NE      not equal                      Z = 0
;                       NR      normalized           Z+(~U & ~E) = 1
;                       PL      plus                           N = 0
;                       NN      not normalized       Z+(~U & ~E) = 0
;
;                       where ~ denote the logical complement,
;                             + denotes the logical OR operator,
;                             & denotes the logical AND operator, and
;                             ^ denotes the logical Exclusive OR operator.
;
;   Restrictions     :
;                    - A Jcc instruction used within a DO loop cannot begin at the address LA within
;                      that DO loop.
;                    - A Jcc instruction cannot be repeated using the REP instruction.
;
;   Example          : JNN   -(R4)             ;jump to P:(R4)-1 if not normalized
;   Explanation      : In this example, program execution is transferred to the address P:(R4)-1 if
;                      the result is not normalized. Note that the contents of address register R4
;                      are predecremented by 1, and the resulting address is then loaded into the
;                      program counter if the specified condition is true. If the specified condition
;                      is not true, no jump is taken, and the program counter is incremented by one.
;   Condition Codes  : The condition codes are not affected by this instruction.
;   Instruction Form : Jcc   xxx
;                      Jcc   ea
;
;                            xxx = 12-bit Short Jump Adress
;                            ea = (Rn)-Nn,
;                                 (Rn)+Nn,
;                                 (Rn)-,
;                                 (Rn)+,
;                                 (Rn),
;                                 (Rn+Nn),
;                                -(Rn),
;                                  Absolute address
;
;   Timing           : 4 + jx oscillator clock cycles
;   Memory           : 1 + ea program words
;
; -*JMP
;   Name             : Jump
;   Operation        :                         Assembler Syntax:
;                      0xxx -> PC              JMP xxx
;                        ea -> PC              JMP ea
;
;   Description      : Jump to the location in program memory given by the instruction's effective
;                      address. All memory alterable addressing modes may be used for effective
;                      address. A Fast Short Jump addressing modes may also be used. The 12-bit data
;                      is zero extended to form the efective address.
;   Restriction      :
;                    - A JMP instruction used within a DO loop cannot begin at the Address LA within
;                      that DO loop.
;                    - A JMP instruction cannot be repeated using the REP instruction.
;   Example          : JMP   (R1 + N1)         ;jump to program address P:(R1 + N1)
;   Explanation      : In this example, program execution is transferred to theprogram address P:(R1
;                      + N1).
;   Condition Codes  : The condition codes are not affected by this instruction.
;   Instruction Form : JMP   xxx
;                      JMP   ea
;
;                            xxx = 12-bit Short Jump Address
;                            ea = (Rn)-Nn,
;                                 (Rn)+Nn,
;                                 (Rn)-,
;                                 (Rn)+,
;                                 (Rn),
;                                 (Rn+Nn),
;                                -(Rn),
;                                  Absolute address
;
;   Timing           : 4 + jx oscillator clock cycles
;   Memory           : 1 + ea program words
;
; -*JCLR
;   Name             : Jump if Bit Clear
;   Operation        : If S[n] = 0, then xxxx -> PC
;                      else PC+1 -> PC
;   Assembler Syntax : JCLR  #n, X:ea, xxxx
;                      JCLR  #n, X:aa, xxxx
;                      JCLR  #n, X:pp, xxxx
;                      JCLR  #n, Y:ea, xxxx
;                      JCLR  #n, Y:aa, xxxx
;                      JCLR  #n, Y:pp, xxxx
;                      JCLR  #n, S, xxxx
;   Description      : Jump to the 16-bit absolute address in program memory specified in the
;                      instruction's 24-bit extension word if the nth bit of the source operand S is
;                      clear. The bit tested is selected by an immediate bit number from 0-23. If the
;                      specified memory bit is not clear, the program counter is incremented and the
;                      absolute address in the extension word is ignored. However, the address
;                      register specified in the effective address field is always updated
;                      independently ofthe state of the nth bit. All address register indirect
;                      addressing modes may be used to reference the source operand S. Absolute Short
;                      and I/O Short addressing modes may also be used.
;   Restrictions     :
;                    - A JCLR instruction cannot be repeated using the REP instruction.
;                    - A JCLR located at LA, LA-1, or LA-2 of the DO loop cannot specify the program
;                      controller registers SR, SP, SSH, SSL, LA, or LC as its target.
;                    - JCLR SSH or JCLR SSL cannot follow an instruction that changes the SP.
;   Example          : JCLR  #$5, X:<<$FFF1, $1234     ;go to P:$1234 if bit 5 in SCI SSR is clear
;   Explanation      : In this example, program execution is transferred to the address P:$1234 if bit
;                      5 (PE) of the 8-bit read-only X memory location X:$FFF1 (I/O SCI interface
;                      status register) is a zero. If the specified bit is not clear, no jump is
;                      taken, and the PC is incremented by one.
;   Condition Codes  : The condition codes are not affected by this instruction.
;   Instruction Form : JCLR  #n, X:ea, xxxx
;                      JCLR  #n, Y:ea, xxxx
;                      JCLR  #n, X:aa, xxxx
;                      JCLR  #n, Y:aa, xxxx
;                      JCLR  #n, X:pp, xxxx
;                      JCLR  #n, Y:pp, xxxx
;                      JCLR  #n,    S, xxxx
;
;                            #n = bit number
;                                  ea = (Rn)-Nn,
;                                       (Rn)+Nn,
;                                       (Rn)-,
;                                       (Rn)+,
;                                       (Rn),
;                                       (Rn+Nn),
;                                      -(Rn)
;                                  aa = 6-bit Absolute Short Address
;                                  pp = 6-bit I/O Short Address
;                                   S  = (X0, X1, Y0, Y1,
;                                         A0, B0, A2, B2, A1, B1, A, B,
;                                         Rn, Nn, Mn,
;                                         SR, OMR, SP, SSH, SSL, LA, LC)
;
;   Timing           : 6 + jx oscillator
;   Memory           : 2 program words
;
; -*JSET
;   Name             : Jump if Bit Set
;   Operation        : If S[n] = 1, then xxxx -> PC
;                      else PC+1 -> PC
;   Assembler Syntax : JSET  #n, X:ea, xxxx
;                      JSET  #n, X:aa, xxxx
;                      JSET  #n, X:pp, xxxx
;                      JSET  #n, Y:ea, xxxx
;                      JSET  #n, Y:aa, xxxx
;                      JSET  #n, Y:pp, xxxx
;                      JSET  #n, S, xxxx
;   Description      : Jump to the 16-bit absolute address in program memory specified in the
;                      instruction's 24-bit extension word if the nth bit of the source operand S is
;                      set. The bitto be tested is selected by an immediate bit number from 0-23. If
;                      the specified memory bitis not set, the PC is incremented, and the absolute
;                      address in the extension word is ignored. However, the address register
;                      specified in the effective address field is always updated independently of
;                      the state of the nth bit. All address register indirect addressing modes may
;                      be used to reference the source operand S. Absolute short I/O addressing modes
;                      may also be used.
;   Restrictions     :
;                    - A JSET instruction used within a DO loop cannot specify the loop address (LA)
;                      as its target.
;                    - A JSET located at LA, LA-1, or LA-2 of a DO loop cannot specify the program
;                      controller registers SR, SP, SSH,   SSL, LA, or LC as its target.
;                    - JSET SSH or JSET SSL cannot follow an instruction that changes the SP.
;                    - A JSET instruction cannot be repeated using the REP instruction.
;   Example          : JSET  #12, X:<<$FFF2, $4321     ;$4321 -> (PC) if bit 12 (SCI COD) is set
;   Explanation      : In this example, pogram execution is transfered to the address P:$4321 if bit
;                      12 (SCI COD) of the 16-bit read/write I/O register X:$FFF2 is a one. If the
;                      specified bit is not set, no jump is taken and the program counter (PC) is
;                      incremented by 1.
;   Condition Codes  : The condition codes are not affected by this instruction.
;   Instruction Form : JSET  #n, X:ea, xxxx
;                      JSET  #n, X:aa, xxxx
;                      JSET  #n, X:pp, xxxx
;                      JSET  #n, Y:ea, xxxx
;                      JSET  #n, Y:aa, xxxx
;                      JSET  #n, Y:pp, xxxx
;                      JSET  #n,    S, xxxx
;
;                                      xxxx = 16-bit Absolute Address
;                            #n = bit number
;                                  ea = (Rn)-Nn,
;                                       (Rn)+Nn,
;                                       (Rn)-,
;                                       (Rn)+,
;                                       (Rn),
;                                       (Rn+Nn),
;                                       -(Rn)
;                                  aa = 6-bit Absolute Short Address
;                                  pp = 6-bit I/O Short Address
;                                   S  = (X0, X1, Y0, Y1,
;                                         A0, B0, A2, B2, A1, B1, A, B,
;                                         Rn, Nn, Mn,
;                                         SR, OMR, SP, SSH, SSL, LA, LC)
;
;   Timing           : 6 + jx oscillator clock cycles
;   Memory           : 2 program words
;
; -*JScc
;   Name             : Jump to Subroutine Conditionally
;   Operation        :                         Assembler Syntax:
;                      If cc, then SP+1 -> SP  JScc xxx
;                                    PC -> SSH
;                                    SR -> SSL
;                                  0xxx -> PC
;                      else...     PC+1 -> PC
;
;                      If cc, then SP+1 -> SP  JScc   ea
;                                    PC -> SSH
;                                    SR -> SSL
;                                    ea -> PC
;                      else...      PC+1 ->PC
;   Description      : Jump to subroutine whose location in program memory is given by the
;                      instruction's effective address if the specified condition is true. If the
;                      specified condition is true, the address of the instruction immediately
;                      following the JScc instruction (PC) and SR are pushed onto the system stack.
;                      Program execution then continues at the specified effective address in program
;                      memory. If the specified condition is false, the PC is incremented, and any
;                      extension word is ignored. However, the address register specified in the
;                      effective address field is always updated independently of the specified
;                      condition. All memory alterable addressing mods may be used for the effective
;                      address. A fast short jump addressing mode may also be used? The 12-bit data
;                      is zero extended to form the effective address. The term "cc" may specify the
;                      following condition :
;   Conditions       : "cc" Mnemonic Condition
;                       CC (HS) carry clear (higher or same)   C = 0
;                       CS (LO) carry set (lower)              C = 1
;                       EC      extension clear                E = 0
;                       EQ      equal                          Z = 1
;                       ES      extension set                  E = 1
;                       GE      greater than or equal        N^V = 0
;                       GT      greater than             Z+(N^V) = 0
;                       LC      limit clear                    L = 0
;                       LE      less than or equal       Z+(N^V) = 1
;                       LS      limit set                      L = 1
;                       LT      less than                    N^V = 1
;                       MI      minus                          N = 1
;                       NE      not equal                      Z = 0
;                       NR      normalized           Z+(~U & ~E) = 1
;                       PL      plus                           N = 0
;                       NN      not normalized       Z+(~U & ~E) = 0
;
;                       where ~ denote the logical complement,
;                             + denotes the logical OR operator,
;                             & denotes the logical AND operator, and
;                             ^ denotes the logical Exclusive OR operator.
;
;   Restrictions     :
;                    - A JScc instruction used within a DO loop cannot specify the loop address (LA)
;                      as its target.
;                    - A JScc instruction used within in a DO loop cannot begin at the address LA
;                      within that DO loop.
;                    - A JScc instruction cannot be repeated using  the REP instruction.
;   Example          : JSLS  (R3+N3)           ;jump to subroutine at P:(R3+N3) if limit set (L=1)
;   Explanation      : In this example, program execution is transfered tothe subroutine at address
;                      (R3+N3) and SR are pushed onto the system stack prior to transferring program control
;                      to the subroutine if the specified condition is not true, no jump is taken and
;                      the PC is incremented by 1.
;   Condition Codes  : The condition codes are not affected by this instruction.
;   Instruction Form : JScc  xxx
;                      JScc   ea
;
;                            xxx = 12-bit Short Jump Address
;                             ea = (Rn)-Nn,
;                                  (Rn)+Nn,
;                                  (Rn)-,
;                                  (Rn)+,
;                                  (Rn),
;                                  (Rn+Nn),
;                                 -(Rn),
;                                   Absolute address
;
;   Timing           : 4 + jx oscillator clock cycles
;   Memory           : 1 + ea program words
;
; -*JSR
;   Name             : Jump to Subroutine
;   Operation        :                         Assembler Syntax:
;                      SP+1 -> SP              JSR   xxx
;                        PC -> SSH
;                        SR -> SSL
;                      0xxx -> PC
;
;                      SP+1 -> SP              JSR   ea
;                        PC -> SSH
;                        SR -> SSL
;                        ea -> PC
;   Description      : Jump to the subroutine whose location in program memory is given by the
;                      instruction's effective address. The address of the instruction immediately
;                      following the JSR instruction (PC) and the SR is pushed onto the system stack.
;                      Program execution then continues at the specified effective address in program
;                      memory. All memory alterable addressing modes may be used for the effective
;                      address. A fast short jump addressing mode may also be used. the 12-bit data
;                      is zero extended to form the effective address.
;   Restrictions     :
;                    - A JSR instruction used within a DO loop cannot specify the loop address (LA)
;                      as its target.
;                    - A JSR instruction used within a DO loop cannot begin at the address LA within
;                      that DO loop.
;                    - A JSR instruction cannot be repeated using the REP instruction.
;   Example          : JSR   (R5)+             ;jump to subroutine at (R5), update R5
;   Explanation      : In this example, program execution is transferred to the subroutine at address
;                      P:(R5) in program memory, and the contents of the R5 address register are then
;                      updated.
;   Condition Codes  : The condition codes are not affected by this instruction.
;   Instruction Form : JSR  xxx
;                      JSR   ea
;
;                           xxx = 12-bit Short Jump Address
;                            ea = (Rn)-Nn,
;                                 (Rn)+Nn,
;                                 (Rn)-,
;                                 (Rn)+,
;                                 (Rn),
;                                 (Rn+Nn),
;                                -(Rn),
;                                  Absolute address
;
;   Timing           : 4 + jx oscillator clock cycles
;   Memory           : 1 + ea program words
;
; -*JSCLR
;   Name             : Jump to Subroutine if Bit Clear
;   Operation        : If S[n]=0 then SP+1 -> SP
;                                       PC -> SSH
;                                       SR -> SSL
;                                     xxxx -> PC
;                      else...        PC+1 -> PC
;   Assembler Syntax : JSCLR #n, X:ea, xxxx
;                      JSCLR #n, X:aa, xxxx
;                      JSCLR #n, X:pp, xxxx
;                      JSCLR #n, Y:ea, xxxx
;                      JSCLR #n, Y:aa, xxxx
;                      JSCLR #n, Y:pp, xxxx
;                      JSCLR #n, S, xxxx
;   Description      : Jump to subroutine at the 16-bit absolute address in program memory specified
;                      in the instruction's 24-bit extension word if the nth bit of the source
;                      operand S is clear. The bit to be tested is selected by an immediate bit
;                      number from 0-23. if the nth bit of the source operand S is clear, the address
;                      of the instruction immediately following the JSCLR instruction (PC) and the SR
;                      are pushed onto the system stack. Program  execution then contintinues at the
;                      specified absolute address in the instruction's 24-bit extension word. If the
;                      specified memory bit is not clear, the PC is incremented and the extension
;                      word is ignored. However, the adress register specified in the effective
;                      address field is always updated independently of the state of the nth bit. All
;                      address register indirect addressing modes may be used to reference the source
;                      operand S. Absolute short and I/O short adressing modes may also be used.
;   Restrictions     :
;                    - A JSCLR instruction used within a DO lopp cannot specify the loop address (LA)
;                      as its target.
;                    - A JSCLR located at LA, LA-1, or LA-2 of a DO loop, cannot specify the program
;                      controller registers SR, SP,      SSH, SSL, LA, or LC as its target.
;                    - JSCLR SSH or JSCLR SSL  cannot follow an instruction that changes the SP.
;                    - A JSCLR instrcuction cannot be repeated using the REP instruction.
;   Example          : JSCLR #$1, Y:<<$FFE3, $1357     ; go sub. at P:$1357 if bit 1 in
;                                                      ; Y:$FFE3 is clear
;   Explanation      : In this example, program execution is transferred to the subroutine at absolute
;                      address P:$1357 in program memory if bit 1 of the external I/O location
;                      Y:<<$FFE3 is a zero. If the specified bit is not clear, no jump is taken and
;                      the PC is incremented by 1.
;   Condition Codes  : The condition codes are not affected by this instruction.
;   Instruction Form : JSCLR #n, X:ea, xxxx
;                      JSCLR #n, X:aa, xxxx
;                      JSCLR #n, X:pp, xxxx
;                      JSCLR #n, Y:ea, xxxx
;                      JSCLR #n, Y:aa, xxxx
;                      JSCLR #n, Y:pp, xxxx
;                      JSCLR #n,    S, xxxx
;
;                                      xxxx = 16-bit Absolute Address
;                            #n = bit number
;                                  ea = (Rn)-Nn,
;                                       (Rn)+Nn,
;                                       (Rn)-,
;                                       (Rn)+,
;                                       (Rn),
;                                       (Rn+Nn),
;                                      -(Rn)
;                                  aa = 6-bit Absolute Short Address
;                                  pp = 6-bit I/O Short Address
;                                   S  = (X0, X1, Y0, Y1,
;                                         A0, B0, A2, B2, A1, B1, A, B,
;                                         Rn, Nn, Mn,
;                                         SR, OMR, SP, SSH, SSL, LA, LC)
;
;   Timing           : 6 + jx oscillator clock cycles
;   Memory           : 2 program words
;
; -*JSSET
;   Name             : Jump to Subroutine if Bit Set
;   Operation        : If S[n] = 1 then SP+1 -> SP
;                                         PC -> SSH
;                                         SR -> SSL
;                                       xxxx -> PC
;                      else...          PC+1 -> PC
;   Assembler Syntax : JSSET #n, X:ea, xxxx
;                      JSSET #n, X:aa, xxxx
;                      JSSET #n, X:pp, xxxx
;                      JSSET #n, Y:ea, xxxx
;                      JSSET #n, Y:aa, xxxx
;                      JSSET #n, Y:pp, xxxx
;                      JSSET #n, S, xxxx
;   Description      : Jump to the subroutine at the 16-bit absolute address in program memory
;                      specified in the instruction's 24-bit extension word if the nth bit of the
;                      source operand S is set. The bit to be tested is selected by an immediate bit
;                      number from 0-23. If the nth bit of the source operand S is set, the address
;                      of the instruction immediately following the JSSET instruction (PC) and the SR
;                      program execution then continues at the specified absolute absolute address in
;                      the instruction's 24-bit extension word. If the specified memory bit is not
;                      set, the PC is incremented, and the extension word is ignored. However, the
;                      address register specified in the effective address field is always updated
;                      independently of the state of the nth bit. All address register indirect
;                      addressing modes may be used to reference the source operand S. Absolute short
;                      and I/O short addressing modes may also be used.
;   Restrictions     :
;                    - A JSSET instruction used within a DO loop cannot specify the loop address (LA)
;                      as its target.
;                    - A JSSET located at LA, LA-1, or LA-2 ofa DO loop, cannot specify the program
;                      controller registers SR, SP, SSH,  SSL, LA, or LC as its target.
;                    - JSSET SSH or JSSET SSL cannot follow an instruction that changes the SP.
;                    - A JSSET instruction cannot be repeated using the REP instruction.
;   Example          : JSSET #$17, Y:<$3F, $100        ;go to sub. at P:$0100 if bit 23 in Y:$3F is set
;   Explanation      : In this example, program execution is transferred to the subroutine at absolute
;                      address P:$0100 in program memory if bit 23 of Y memory location Y:$003F is a
;                      one. If the specified bit is not set, no jump is taken and the PC is
;                      incremented by 1.
;   Condition Codes  : The condition codes are notaffected by this instruction.
;   Instruction Form : JSSET #n, X:ea, xxxx
;                      JSSET #n, X:aa, xxxx
;                      JSSET #n, X:pp, xxxx
;                      JSSET #n, Y:ea, xxxx
;                      JSSET #n, Y:aa, xxxx
;                      JSSET #n, Y:pp, xxxx
;                      JSSET #n,    S, xxxx
;
;                                      xxxx = 16-bit Absolute Address
;                            #n = bit number
;                                  ea = (Rn)-Nn,
;                                       (Rn)+Nn,
;                                       (Rn)-,
;                                       (Rn)+,
;                                       (Rn),
;                                       (Rn+Nn),
;                                      -(Rn)
;                                  aa = 6-bit Absolute Short Address
;                                  pp = 6-bit I/O Short Address
;                                   S  = (X0, X1, Y0, Y1,
;                                         A0, B0, A2, B2, A1, B1, A, B,
;                                         Rn, Nn, Mn,
;                                         SR, OMR, SP, SSH, SSL, LA, LC)
;
;   Timing           : 6 + jx oscillator clock cycles
;   Memory           : 2 program words
;
; -*NOP
;   Name             : No Operation
;   Operation        : PC = PC +1
;   Assembler Syntax : NOP
;   Description      : Increment the programm counter (PC),. Pending pipeline actions, if any, are
;                      completed. Execution continues with the instruction following the NOP.
;   Condition Codes  : The condition codes are not affected by this instruction
;   Instruction Form : NOP
;   Timing           : 2 oscillator clock cycles
;   Memory           : 1 program words
;
; -*REP
;   Name             : Repeat Next Instruction
;   Operation        : LC -> TEMP; X:<ea> -> LC or
;                      LC -> TEMP; X:<aa> -> LC or
;                      LC -> TEMP; Y:<ea> -> LC or
;                      LC -> TEMP; Y:<aa> -> LC or
;                      LC -> TEMP; S -> LC      or
;                      LC -> TEMP; #xxx -> LC
;
;                      Repeat next instruction until LC=1
;                      TEMP -> LC
;
;   Assembler syntax : REP   X:<ea>
;                      REP   X:<aa>
;                      REP   Y:<ea>
;                      REP   Y:<aa>
;                      REP   S
;                      REP   #xxx
;   Description      : Repeat the SINGLE-WORD INSTRUCTION immediately following the REP instruction
;                      the specified number of times. The value specifying the number of times the
;                      given instruction is to be repeated is loaded into the 16-bit loop counter
;                      (LC) register. The single-word instruction is then executed the specified
;                      number of times, decrementing the loop counter (LC) after each execution until
;                      LC=1. When the REP instruction is in effect, the repeated instruction is
;                      fetched only one time, and it remains in the instruction register for the
;                      duration of the loop count. Thus, THE REP INSTRUCTION IS NOT INTERRUPTIBLE
;                      (sequential repeats are also not interruptible). The current loop counter (LC)
;                      value is stored in an internal temporary register. If LC is set equal to zero,
;                      the instruction is repeated 65,536 times. The instruction's effective address
;                      specifies the address of the value wich is to be loaded into the loop counter
;                      (LC). All address register indirect adressing modes may be used. The absolute
;                      short and the immediate short addressing modes may also be used. The four MS
;                      bits of the 12-bit immediate value are zeroed to form the 16-bit value that is
;                      to be loaded into the loop counter (LC).
;
;                      If the A or B accumulator is specified as a SOURCE operand, the accumulator
;                      value is optionally shifted according to the scaling mode bits S0 and S1 in
;                      the system status register (SR). If the data out the shifter indicates that
;                      the accumulator extension is in use, the value to be loaded into the loop
;                      counter (LC) register will be limited to a 24-bit maximum positive or negative
;                      saturation constant to minimize the error due to truncation. The LS 16 bits of
;                      the resulting 24-bit value are then stored in the 16-bit loop counter (LC)
;                      register.
;
;                      If the system stack register SSH is specified as a source operand, the system
;                      stack pointer (SP) is postdecremented by 1 after SSH has been read.
;
;   Restrictions     : The REP instruction ca repeat any single-word instruction except the REP
;                      instruction itself and any instruction that changes program flow. The
;                      following instructions are not allowed to follow an REP instruction:
;
;        IMMEDIATELY AFTER REP
;
;                      DO
;                      JSSET
;                      Jcc
;                      REP
;                      JCLR
;                      RTI
;                      JMP
;                      RTS
;                      JSET
;                      STOP
;                      JScc
;                      SWI
;                      JSCLR
;                      WAIT
;                      JSR
;
;                      Also a REP instruction cannot be the LAST instruction in a DO loop (at LA). The
;                      assembler will generate an error if any of the previous instructions are found
;                      immediately following an REP instruction.
;
;   Example          : REP   X0                                    ; repeat (X0) times
;                      MAC   X1, Y1, A  X:(R1)+, X1 Y:(R4)+, Y1    ; X1*Y1+A -> A, update X1,Y1
;
;                      Before execution:       After execution:
;                      X0 = $000100            X0 = $000100
;                      LC =   $0000            LC =   $0100
;
;   Explanation      : Prior to execution, the 24-bit X0 register contains the value $000100, and the
;                      16-bit loop counter (LC) register contains the value $0000. The execution of
;                      the REP X0 instruction takes the 24-bit value in the X0 register, truncates
;                      the MS 8 bits, and stores the 16 LS bits in the 16-bit loop counter (LC)
;                      register. Thus, the single-word MAC instruction immediately following the REP
;                      instruction is repeated $100 times.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set if data limiting occured using A or B as source operands
;
;   Instruction form : REP   X:<ea>
;                      REP   X:<aa>
;                      REP   Y:<ea>
;                      REP   Y:<aa>
;                      REP   S
;                      REP   #xxx
;
;                               ea = (Rn)-Nn,
;                                    (Rn)+Nn,
;                                    (Rn)-,
;                                    (Rn)+,
;                                    (Rn),
;                                    (Rn+Nn),
;                                   -(Rn)
;                               aa = 6-bit Absolute Short Address
;                            #xxx = 12-bit Immediate Short Data
;                            S = (X0, Y0, X1, Y1,
;                                 A2, A1, A0, B2, B1, B0, A, B,
;                                 Rn, Nn, Mn,
;                                 SR, OMR, SP, SSH, SSL, LA, LC)
;
;   Timing           : 4 oscillator clock cycles
;   Memory           : 1 program word
;
; -*RESET
;   Name             : Reset On-Chip Peripheral Devices
;   Operation        : Reset the interrupt priority register and all on-chip peripherals
;   Assembler Syntax : RESET
;   Description      : Reset the interrupt priority register and all on-chip peripherals. This is a
;                      SOFTWARE RESET wich is NOT equivalent to a hardware reset since only on-chip
;                      peripherals and the interrupt structure are affected. the processor state is
;                      not affected, and execution continues with the next instruction. All interrupt
;                      sources are disabled except for the trace, stack error, NMI, illegal
;                      instruction, and hardware reset interrupts.
;   Restrictions     : A RESET instruction cannot be the last instruction in a DO loop (at LA).
;   Condition Codes  : The condition codes are not affected by this instruction.
;   Instruction Form : RESET
;   Timing           : 4 oscillator clock cycles
;   Memory           : 1 program word
;
; - RTI
;   Name             : Return from Interrupt
;   Operation        :    SSH -> PC
;                         SSL -> SR
;                      SP - 1 -> SP
;   Assembler Syntax : RTI
;   Description      : Pull the program counter (PC) and the status register (SR) from the stack. The
;                      previous program counter and status register are lost.
;   Restrictions     : Due to pipelining in the program controller and the fact that the RTI
;                      instruction accesses certain controller registers, the RTI instruction must be
;                      immediately preceded by any of the following instructions:
;
;         Immediately before RTI:
;                      MOVEC to LA, LC, SSH, SSL, or SP
;                      MOVEM to LA, LC, SSH, SSL, or SP
;                      MOVEP to LA, LC, SSH, SSL, or SP
;                      MOVEC from SSH
;                      MOVEM from SSH
;                      MOVEP from SSH
;                      ANDI MR or ANDI CCR
;                      ORI MR or ORI CCR
;
;                      An RTI instruction cannot be the LAST instruction in a DO loop (at LA).
;                      An RTI instruction cannot be repeated using the REP instruction.
;
;   Condition Codes  : 15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;                      LF ** T  ** S1 S0 I1 I0 ** L  E  U  N  Z  V  C
;                      |<         MR         >|<         CCR       >|
;
;                      L  Set according to the value pulled from the stack
;                      E  Set according to the value pulled from the stack
;                      U  Set according to the value pulled from the stack
;                      N  Set according to the value pulled from the stack
;                      Z  Set according to the value pulled from the stack
;                      V  Set according to the value pulled from the stack
;                      C  Set according to the value pulled from the stack
;
;   Instruction Form : RTI
;   Timing           : 4 + rx oscillator clock cycles
;   Memory           : 1 program word
;
; - RTS
;   Name             : Return from Subroutine
;   Operation        :    SSH -> PC
;                      SP - 1 -> SP
;   Assembler Syntax : RTS
;   Description      : Pull the program counter (PC) from the stack. The previous program counter is
;                      lost. The status register (SR) is not affected.
;   Restrictions     : Due to pipelining in the program controller and the fact that the RTS
;                      instruction accesses certain controller registers, the RTS instruction must be
;                      immediately preceded by any of the following instructions:
;
;         Immediately before RTS :
;                      MOVEC to LA, LC, SSH, SSL, or SP
;                      MOVEM to LA, LC, SSH, SSL, or SP
;                      MOVEP to LA, LC, SSH, SSL, or SP
;                      MOVEC from SSH
;                      MOVEM from SSH
;                      MOVEP from SSH
;
;                      An RTS instruction cannot be the LAST instruction in a DO loop (at LA).
;                      An RTS instruction cannot be repeated using the REP instruction.
;
;   Condition Codes  : The condition codes are not affected by this instruction.
;   Instruction Form : RTS
;   Timing           : 4 + rx oscillator clock cycles
;   Memory           : 1 program word
;
; -*STOP
;   Name             : Stop Instruction Processing
;   Operation        : Enter the STOP processing state and stop the clock oscillator
;   Assembler Syntax : STOP
;   Description      : Enter the STOP processing state. All activity in the processor is suspended
;                      until the RESET or IRQA pin is asserted. The clock escillator is gated off
;                      internally. The STOP processing state is a low-power standby state.
;
;                      During the STOP state, port A is in an idle state with the control signals held
;                      inactive (I.E., RD=WR=VCC etc.), the data pins (D0-D23) are high impedance,
;                      and the address pins (A1-A15) are unchanged from the previous instruction. If
;                      the bus grant was asserted when the STOP instruction was executed, port A will
;                      remain three-stated until the DSP exits the STOP state.
;
;                      If the exit from the STOP state was caused by a low level on the RESET pin,
;                      then the processor will enter the reset processing state. The time to recover
;                      from the STOP state using RESET will depend on the oscillator used.
;
;                      If the exit from the STOP state was caused by a low level on the IRQA pin, then
;                      ice the IRQA interrupt unless it is highest priority. The interrupt will be
;                      serviced after an internal delay counter counts 65,536 clock cycles (or a
;                      three clock cycle delay if the stop delay bit in the OMR is set to one) plus
;                      17T. During this clock stabilization count delay, all peripherals and external
;                      interrupts are cleared and re-enabled/arbitrated at the start of the 17T
;                      period following the count interval. The processor will resume program
;                      execution at the instruction following the STOP instruction that caused the
;                      entry into the STOP state after the delay count plus 17T. If the IRQA pin is
;                      asserted when the STOP instruction is executed, the clock will not be gated
;                      off, and the internal delay counter will be started.
;   Restrictions     :
;                    - A STOP instruction cannot be used in a fast interrupt routine.
;                    - A STOP instruction cannot be the last instruction in a DO loop (at LA).
;                    - A STOP instruction cannot be repeated using REP instruction.
;   Condition Codes  : The condition codes are not affected by this instruction.
;   Instruction Form : STOP
;   Timing           : The STOP instruction disable the internal clock oscillator and
;                      internal distribution of the external clock.
;   Memory           : 1 program word
;
; -*SWI
;   Name             : Software Interrupt
;   Operation        : Begin SWI exception processing
;   Assembler Syntax : SWI
;   Description      : Suspend normal instruction execution and begin SWI exception processing. The
;                      priority level (I1,I0) is set to 3 in the status register (SR) if a long interrupt
;                      service routine is used.
;   Restrictions     :
;                    - An SWI instruction cannot be used in a fast interrupt routine.
;                    - An SWI instruction cannot be repeated using REP instruction.
;   Condition Codes  : The condition codes are not affected by this instruction.
;   Instruction Form : SWI
;   Timing           : 8 oscillator clock cycles
;   Memory           : 1 program word
;
; -*WAIT
;   Name             : Wait for Interrupt
;   Operation        : Disable clocks to the processor core and enter the WAIT processing state.
;   Assembler Syntax : WAIT
;   Description      : Enter the WAIT processing state. The internal clocks to the processor core and
;                      memories are gated off, and all activity in the processor is suspended until
;                      an unmasked interrupt occurs. The clock oscillator and the internal I/O
;                      peripheral clocks remain active. If WAIT is executed when an interrupt is
;                      pending, the interrupt will be processed; the effect will be the same as if
;                      the processor never entered the WAIT state and three NOPs followed the WAIT
;                      instruction. When an unmasked interrupt or external (hardware) processor RESET
;                      occurs, the processor leave the WAIT state and begins exception processing of
;                      the unmasked interrupt or RESET condition. The BR/BG circuits remain active
;                      during the WAIT state. The WAIT state is a low-power standby state. The
;                      processor always leave the WAIT state in the T2 clock phase. Therefore,
;                      multiple processors may be synchronized by having them all enter the WAIT
;                      state and then interrupting them with a common interrupt.
;   Restrictions     : A WAIT instruction cannot be used in a fast interrupt routine.
;                      A WAIT instruction cannot be the last instruction in a DO loop (at LA).
;                      A WAIT instruction cannot be repeated using REP instruction.
;   Condition Codes  : The condition codes are not affected by this instruction.
;   Instruction Form : WAIT
;   Timing           : The WAIT instruction takes a minimum of 16 cycles to execute when an
;                      internal interrupt is pending during the execution of the WAIT
;                      instruction.
;   Memory           :     1 program word
;
; *****************************************************************************
; > Floating Point Routines for the DSP 56001 - Motorola Corporation (c) 1990
;
;including "FPDEF.HLP"...
;
;SOF>>>
; FPLIB - MOTOROLA DSP56000/1 FLOATING POINT SOFTWARE SUBROUTINE LIBRARY
;
;                 FORMAT DEFINITION - VERSION 2.0
;
; Revision 1.0    August 29, 1986
; Revision 1.1    March  25, 1987
; Revision 2.0    October 5, 1987
;
; INTRODUCTION
;
; FPLIB is a useful set of floating point arithmetic subroutines for the
; Motorola DSP56000/1 digital signal processor.  This HELP file defines
; the storage format and arithmetic representation used by the DSP56000/1
; floating point software subroutine library (FPLIB).  The handling of
; exception cases is also discussed.  Subroutine calling conventions are
; not discussed here but are given in the FPCALLS.HLP file.
;
; FPLIB "SINGLE EXTENDED" PRECISION FLOATING POINT FORMAT
;
; Floating point number - (m,e) including mantissa sign
;         Decimal value = m * ( 2 ** ( e - ebias ))
;
;         23_____________________0    23_______________________0
;         | s .      m           |    |    0            e .    |
;         |______________________|    |________________________|
;
; m = 24 bit mantissa (two's complement, normalized fraction)
;         23 bit mantissa precision plus 1 bit mantissa sign gives
;         precision of approximately 7 decimal digits.  The 24 bit
;         mantissa was chosen to maximize precision with efficient
;         use of the DSP56000 MPY and MAC instructions.
;         A hidden leading 1 is not implemented in this format.
;
;         Binary encoding:  s.xxxxxxx xxxxxxxx xxxxxxxx
;         Bit weight:       0  -1                      -23
;                           -2  2                       2
;
;         Largest positive mantissa    $7FFFFF = +0.99999988079071044921875
;         Smallest positive mantissa   $400000 = +0.5
;         Floating point zero mantissa $000000 = 0
;         Smallest negative mantissa   $BFFFFF = -0.50000011920928955078125
;         Largest negative mantissa    $800000 = -1.0
;         Reserved mantissas           $000001 through $3FFFFF
;                                      $C00000 through $FFFFFF
;
;         Note that all reserved mantissas are illegal since they
;         represent denormalized mantissas.
;
; e = 14 bit exponent (unsigned integer, biased by ebias = +8191)
;         Stored as a 24 bit unsigned integer with 10 leading zeros.
;         Exponent arithmetic is generally done with 16 bit precision.
;         The 14 bit exponent format was chosen to maximize dynamic
;         range with efficient detection of exponent overflow and
;         exponent underflow.
;
;         Binary encoding:  00000000 00xxxxxx xxxxxxxx.
;         Bit weight:                   13            0
;                                     2             2
;
;         Largest exponent             $003FFF = 2 ** +8192
;         Assumed fixed point exponent $001FFF = 2 ** +0 = +1.0
;         Smallest exponent            $000000 = 2 ** -8191
;         Reserved exponents           $004000 through $FFFFFF
;
;                         14
;         If bit weight  2   is set, exponent overflow has occured.
;                         15
;         If bit weight  2   is set, exponent underflow has occured.
;
;         Note that no distinct exponents are reserved for plus infinity,
;         minus infinity, Not a Number (IEEE NaN), minus zero or
;         denormalized numbers.
;
;
; FPLIB "SINGLE EXTENDED" PRECISION FLOATING POINT NUMBER RANGE
;
; Largest positive floating point number -  m = $7FFFFF, e = $003FFF
;         Decimal value = +0.1090748 E+2467
;
; Smallest positive floating point number - m = $400000, e = $000000
;         Decimal value = +0.9168017 E-2466
;
; Smallest negative floating point number - m = $BFFFFF, e = $000000
;         Decimal value = -0.9168019 E-2466
;
; Largest positive floating point number -  m = $800000, e = $003FFF
;         Decimal value = -0.1090748 E+2467
;
; Floating point zero -                     m = $000000, e = $000000
;         Decimal value = +0.0
;
; Note that the two's complement mantissa does not have equal
; positive and negative ranges.  Only sign-magnitude formats
; possess this property.  These ranges should be checked after
; most arithmetic operations.
;
;
; FPLIB "SINGLE EXTENDED" PRECISION FLOATING POINT DSP56000/1 REGISTER USAGE
;
; Sign Only       Mantissa        Exponent        Usage
;                 x1              x0              Input only
;                 y1              y0              Input only
; a2              a1              b1              Input and output
;                                 r0,n0,m0        Reserved for FPLIB
;
; The library subroutines do not preserve the contents of these registers
; unless specifically noted in the function.  Accumulator a usually
; contains the mantissa upon return from the subroutine.  Accumulator b
; usually contains the exponent upon return from the subroutine.
; The subroutines assume that the input variables are present in the
; appropriate registers when the subroutine is called.
;
;
; FPLIB "SINGLE EXTENDED" PRECISION FLOATING POINT DSP56000/1 MEMORY USAGE
;
; The floating point mantissa and exponent may be stored in any
; locations in any memory space.  The input and output register
; values are organized so that the long (L:) addressing mode may
; be used to load/store both the mantissa and exponent with one
; instruction.  If the long addressing mode is used, the mantissa
; is in X memory and the exponent is in Y memory at the same address.
;
;
; COMPARISON TO ANSI/IEEE STD 754-1985 STANDARD FOR BINARY FLOATING
; POINT ARITHMETIC
;
; Since the IEEE Floating Point Arithmetic Standard is well
; publicized, it is useful to compare these two floating point
; formats.  This floating point format (FPLIB) differs from the
; IEEE standard primarily in its handling of floating point exceptions.
; Other differences are noted in the table below.  Conversion between
; the IEEE standard format and this format is straight-forward.
;
; CHARACTERISTIC          FPLIB FORMAT            IEEE FORMAT
; --------------          ------------            -----------
;
; Mantissa Precision      23 bits                 24 bits
;
; Hidden Leading One      No                      Yes
;
; Mantissa Format         24 bit Two's            23 bit Unsigned
;                         Complement Fraction     Magnitude Fraction
;
; Exponent Width          16 bits (14 bits        8 bits (single)
;                         used)                   11 bits (double)
;
; Maximum Exponent        +8192                   +127 (single)
;                                                 +1023 (double)
;
; Minimum Exponent        -8191                   -127 (single)
;                                                 -1022 (double)
;
; Exponent Bias           +8191                   +127 (single)
;                                                 +1023 (double)
;
; Format Width            48 bits                 32 bits (single)
;                                                 64 bits (double)
;
; Rounding                Round to Nearest        Round to Nearest
;                                                 Round to +Infinity
;                                                 Round to -Infinity
;                                                 Round to Zero
;
; Infinity Arithmetic     Saturation Limiting     Affine Operations
;
; Denormalized Numbers    No (Forced to Zero)     Yes (With Minimum Exponent)
;
; Exceptions              Divide by Zero          Invalid Operations
;                         Overflow                Divide by Zero
;                         Negative Square Root    Overflow
;                                                 Underflow
;                                                 Inexact Arithmetic
;
;
; IEEE SINGLE PRECISION FORMAT
;
;  _31_30______________23_22______________________0
; | s |  8 bit exponent  |     23 bit mantissa    |
; |___|__________________|________________________|
;
;
; IEEE DOUBLE PRECISION FORMAT
;
;  _63_62______________________52_51_______________________________0
; | s |      11 bit exponent     |         52 bit mantissa         |
; |___|__________________________|_________________________________|
;
;
; As shown in the table, the FPLIB mantissa precision is one bit less
; than the IEEE single precision format.  This is a result of using
; two's complement arithmetic in the DSP56000/1.  The FPLIB exponent
; width is three bits more than the IEEE double precision format.
; This provides an extremely large (approx. 100,000 dB) dynamic
; range which eliminates exponent overflow for most applications.
; If exponent overflow occurs, the result is limited to the maximum
; representable floating point number of the correct sign.  If
; exponent underflow occurs, the result is limited to the minimum
; representable floating point number, which is zero.  Although
; the FPLIB format does not provide the arithmetic safety offered
; by the IEEE standard, it avoids extensive error checking and
; exceptions in favor of real-time execution speed and efficient
; implementation on the DSP56000/1.  All exception conditions are
; handled "in-line" according to predefined rules.  This accepts
; the fact that real-time systems have no choice but to provide an
; output with some amount of error if an exception occurs.  It is
; not possible to stop execution until the application program
; determines a solution to the problem and fixes it.
;
; One major difference is the use of affine arithmetic in the IEEE
; standard versus the use of saturation arithmetic in the FPLIB format.
; Affine arithmetic gives separate identity to plus infinity, minus
; infinity, plus zero and minus zero.  In operations involving these
; values, finite quantities remain finite and infinite quantities
; remain infinite.  In contrast, this format gives special identity
; only to unsigned zero.  This format performs saturation arithmetic
; such that any result out of the representable floating point range
; is replaced with the closest floating point representation.  Since
; the dynamic range of this format is quite large, it is adequate for
; most applications.  In the analog world, overflow is analogous to an
; analog op amp output clamping at the power supply rails.
;
; The IEEE floating point standard provides extensive error handling
; required by affine arithmetic, denormalized numbers, signaling Not
; a Number (NaNs) and quiet NaNs.  It postpones introducing computation
; errors by using internal signaling and user traps to process each
; exception condition.  Computational errors will be introduced by
; the application program if the calculation is completed instead of
; aborting the program.  The FPLIB format introduces computation errors
; when an exception occurs in order to maintain real-time execution.
; An error flag (L bit in CCR) is set to inform the application program
; that an exception has occured.  This bit will remain set until reset
; by the application program.  The user can then eliminate the exception
; by algorithm modifications.
;<<<EOF
;
;including "FPCALLS.HLP"
;
;SOF>>>
;2 FPCALLS
;
;
; FPLIB - MOTOROLA DSP56000/1 FLOATING POINT SOFTWARE SUBROUTINE LIBRARY
;
;             CALLING CONVENTIONS - VERSION 2.0
;
; Revision 1.0      August 29, 1986
; Revision 1.1      March  25, 1987
; Revision 2.0      October 5, 1987
;
; MOTOROLA, INC.
; COPYRIGHT 1986, 1987
; ALL RIGHTS RESERVED
;
; INTRODUCTION
;
; FPLIB is a useful set of floating point arithmetic subroutines for the
; Motorola DSP56000/1 digital signal processor.  This HELP file defines
; the subroutine calling conventions and condition codes used by the
; DSP56000/1 floating point software subroutine library (FPLIB).
; Register usage and error conditions are described.  The storage format
; and arithmetic representation are not discussed here but are given in
; the FPDEF.HLP file.
;
; FPLIB INITIALIZATION AND ASSUMPTIONS
;
; FPLIB must be initialized by calling the subroutine "FPINIT" before
; any other FPLIB subroutines are used.  FPLIB assumes that R0, N0 and
; M0 are RESERVED pointers for FPLIB and should not be used by the
; calling program. FPLIB also assumes that the scaling modes are
; DISABLED (NO SCALING) and that the CCR limit (L) bit is cleared so
; that FPLIB subroutines can set it to indicate error conditions.  These
; assumptions are initialized by the FPINIT subroutine.  FPINIT need
; only be called once per application program unless the above
; assumptions are violated.  However, FPINIT may be called at any time
; if the user needs to restore the FPLIB assumptions. No FPLIB state
; information (except the L bit error flag) is carried from one FPLIB
; subroutine to another.  A final caution is that FPINIT clears the CCR
; L bit so any previous error indication will be lost.
;
; FPLIB MEMORY USAGE
;
; FPLIB uses approximately 32 words of data memory for storage of certain
; constants and tables.  The user may specify any address in X or Y data
; memory for this storage area.  This is done by specifying the memory
; space label "fp_space" with an assembler DEFINE directive and the memory
; base address label "fp_temp" with an assembler EQU directive as shown
; below.
;
;       define      fp_space      'x'      ;FPLIB storage in X Data RAM
; fp_temp      equ      0                  ;beginning at address $0000
;
; For code efficiency, fp_temp should be located in the bottom 64 locations
; of X or Y data memory to take advantage of the absolute short addressing
; mode.
;
; The current version of FPLIB requires approximately 200 program memory
; locations if all subroutines are included.  Most subroutines require
; other subroutines to be included since many share common code.
;
; FPLIB REGISTER USAGE
;
; FPLIB uses all of the DSP56000/1 data ALU registers for input variables,
; output variables and temporary storage.  FPLIB does not preserve any
; data ALU registers so users should save/restore data ALU registers as
; required.  Input and output variables are described using a floating
; point register notation (shown in capital letters below) similar to the
; DSP56000/1 register names.  The floating point and fixed point register
; usage is indicated in lower case letters.  The floating point mantissa
; word is indicated with "m" and the floating point exponent word is
; indicated with "e".
;
; Input variables:
;
;    X      x1 = mx  (normalized)
;           x0 = ex
;
;    Y      y1 = my  (normalized)
;           y0 = ey
;
;    A      a2 = sign extension of ma
;           a1 = ma  (normalized)
;           a0 = zero
;
;           b2 = sign extension of ea (always zero)
;           b1 = ea
;           b0 = zero
;
;    D       a = fixed point data
;
; Output variables:
;
;    R      a2 = sign extension of mr
;           a1 = mr  (normalized)
;           a0 = zero
;
;           b2 = sign extension of er (always zero)
;           b1 = er
;           b0 = zero
;
;    D       a = fixed point data
;
; FPLIB SUBROUTINE CALLS
;
; FPLIB subroutines are called with a JScc, JSCLR, JSR or JSSET instruction.
; Input variables are loaded before calling the FPLIB subroutine and output
; variables are available after the FPLIB subroutine returns to the calling
; program.  Input variables may be destroyed by the subroutine.  In general,
; the condition codes are only valid after the floating point compare "fcmp"
; subroutine.
;
; Entry Point      Operation
; -----------      ---------
; fpinit            Initialize FPLIB
; fadd_xa           R = A + X
; fadd_xy           R = Y + X
; fsub_xa           R = A - X
; fsub_xy           R = Y - X
; fcmp_xa           A - X, set condition codes
; fcmp_xy           Y - X, set condition codes
; fmpy_xa           R = A * X
; fmpy_xy           R = X * Y
; fmac_xya          R = A + X * Y
; fmac_mxya         R = A - X * Y
; fdiv_xa           R = A / X
; fdiv_xy           R = Y / X
; fscal_xa          R = A * 2**ex, assumes mx=1
; fscal_xy          R = Y * 2**ex, assumes mx=1
; fsqrt_a           R = square root (A)
; fsqrt_x           R = square root (X)
; fneg_a            R = - A
; fneg_x            R = - X
; fabs_a            R = absolute value (A)
; fabs_x            R = absolute value (X)
; fix_a             D = fixed point conversion (A)
; fix_x             D = fixed point conversion (X)
; float_a           R = floating point conversion (A)
; float_x           R = floating point conversion (X)
; floor_a           R = floor(A), largest integer less than or equal to A
; floor_x           R = floor(X)
; fceil_a           R = ceil(A), smallest integer greater than or equal to A
; fceil_x           R = ceil(X)
; frac_a            R = frac(A), fractional part of A
; frac_x            R = frac(X)
;
;
; FPLIB ERROR CONDITIONS
;
; The FPLIB subroutines detect various error conditions and set the CCR
; limit (L) bit as an error flag.  The user may test the CCR L bit upon
; return from the subroutine.  Note that the CCR L bit remains set until
; cleared by the user.  To promote real-time application, each
; subroutine also substitutes a floating point (or fixed point) value
; for the result.  This allows the real-time system to run continuously
; in the presence of errors which would typically abort a FORTRAN or C
; program.  These error conditions and result values are given for each
; subroutine below.
;
; Entry Point    Error Conditions            Result Value
; -----------    ----------------            ------------
; fpinit         none
; fcmp_xa
; fcmp_xy
; float_a
; float_x
; floor_a
; floor_x
; fceil_a
; fceil_x
; frac_a
; frac_x
;
; fadd_xa        floating point overflow     maximum value, correct sign.
; fadd_xy        floating point underflow    zero.
; fsub_xa
; fsub_xy
; fmpy_xa
; fmpy_xy
; fmac_xya
; fmac_mxya
; fscal_xa
; fscal_xy
; fneg_a
; fneg_x
; fabs_a
; fabs_x
;
; fdiv_xa        floating point overflow       maximum value, correct sign.
; fdiv_xy        floating point underflow      zero.
;                divide by zero                if dividend non-zero, maximum
;                                              value, correct sign.
;                                              if dividend zero, zero.
;
; fsqrt_a        negative input value          zero.
; fsqrt_x
;
; fix_a          fixed point overflow          maximum fixed point value,
; fix_x                                        correct sign.
;
; FPLIB CONDITION CODES
;
; In general, conditional jumps based on condition codes may be used
; only after calling the floating point compare subroutines (fcmp_xa and
; fcmp_xy).  The following branch conditions can be used after calling
; fcmp_xa or fcmp_xy. Other branch conditions should not be used.
;
;       "cc" Mnemonic                  Condition
;       -------------                  ---------
;       EQ - equal                      Z = 1
;       GE - greater than or equal      N eor V = 0
;       GT - greater than               Z + (N eor V) = 0
;       LE - less than or equal         Z + (N eor V) = 1
;       LT - less than                  N eor V = 1
;       NE - not equal                  Z = 0
;
; FPLIB BUGS AND EXTENSIONS
;
; FLPIB has been tested for a short time and is thought to be bug free.
; However, if bugs are found they should be reported to Motorola so they
; can be fixed.  Other subroutines may be added to extend FPLIB as time
; allows.  User-written FPLIB extensions should be submitted to Motorola
; for possible inclusion in FPLIB.
;
; FPLIB EXECUTION TIMES
;
; The FPLIB subroutines are generic floating point routines which
; include rounding, error detection (such as floating point overflow and
; underflow) and error correction (result substitution).  As such, their
; execution time is data dependent.  Of course, users who do not want
; these safety features may remove them (with some editing) to gain a
; modest speed improvement. The best case and worst case execution times
; are given below.  The average is somewhere in between and is data and
; algorithm dependent.  The cycle count is in DSP56000/1 INSTRUCTION
; CYCLES and the execution time assumes a 20.5 MHz clock with no wait
; states or external bus contention.  The calling program subroutine
; call is not included in these times since it can take various forms
; but the FPLIB return from subroutine (RTS) execution time is included.
;
; Entry Point      Best Case Execution Time      Worst Case Execution Time
; -----------      ------------------------      -------------------------
; fpinit            6 cycles, 0.59 usec           6 cycles,  0.59 usec
; fadd_xa          12 cycles, 1.17 usec          75 cycles,  7.32 usec
; fadd_xy          13 cycles, 1.27 usec          76 cycles,  7.41 usec
; fsub_xa          11 cycles, 1.07 usec          71 cycles,  6.93 usec
; fsub_xy          12 cycles, 1.17 usec          72 cycles,  7.02 usec
; fcmp_xa           7 cycles, 0.68 usec          14 cycles,  1.37 usec
; fcmp_xy           8 cycles, 0.78 usec          15 cycles,  1.46 usec
; fmpy_xa          18 cycles, 1.76 usec          63 cycles,  6.15 usec
; fmpy_xy          19 cycles, 1.85 usec          64 cycles,  6.24 usec
; fmac_xya         39 cycles, 3.80 usec         147 cycles, 14.34 usec
; fmac_mxya        40 cycles, 3.90 usec         145 cycles, 14.15 usec
; fdiv_xa          12 cycles, 1.17 usec         109 cycles, 10.63 usec
; fdiv_xy          13 cycles, 1.27 usec         110 cycles, 10.73 usec
; fscal_xa         12 cycles, 1.17 usec          15 cycles,  1.46 usec
; fscal_xy         13 cycles, 1.27 uses          16 cycles,  1.56 usec
; fsqrt_a           7 cycles, 0.68 usec         158 cycles, 15.41 usec
; fsqrt_x           8 cycles, 0.78 usec         159 cycles, 15.51 usec
; fneg_a           16 cycles, 1.56 usec          61 cycles,  5.95 usec
; fneg_x           17 cycles, 1.66 usec          62 cycles,  6.05 usec
; fabs_a            5 cycles, 0.49 usec          64 cycles,  6.24 usec
; fabs_x            6 cycles, 0.59 usec          65 cycles,  6.34 usec
; fix_a             5 cycles, 0.49 usec          27 cycles,  2.63 usec
; fix_x             6 cycles, 0.59 usec          28 cycles,  2.73 usec
; float_a          11 cycles, 1.07 usec          83 cycles,  8.10 usec
; float_x          12 cycles, 1.17 usec          84 cycles,  8.20 usec
; floor_a           5 cycles, 0.49 usec          18 cycles,  1.76 usec
; floor_x           6 cycles, 0.59 usec          19 cycles,  1.85 usec
; fceil_a           9 cycles, 0.88 usec          22 cycles,  2.15 usec
; fceil_x          10 cycles, 0.98 usec          23 cycles,  2.24 usec
; frac_a           25 cycles, 2.44 usec          98 cycles,  9.56 usec
; frac_x           26 cycles, 2.54 usec          99 cycles,  9.66 usec
;
; CONCLUSION
;
; FPLIB is a compact, software floating library which can be used in
; real-time applications.  It can be used selectively to extend the
; dynamic range of the DSP56000/1 fixed point fractional arithmetic or
; as a basic data type to support high level languages.  The worst case
; performance is roughly equivalent to a 12.5 MHz MC68881 floating point
; coprocessor.  The average performance is believed to be about twice as
; fast as the worst case performance.
;<<<EOF
;
;including "FPREVS.HLP"...
;
;SOF>>>
;2 FPREVS
;
;
; FPLIB - MOTOROLA DSP56000/1 FLOATING POINT SOFTWARE SUBROUTINE LIBRARY
;
;                 LATEST REVISIONS - VERSION 2.0
;
; Revision 1.0      August 29, 1986
; Revision 1.1      March  25, 1987
; Revision 2.0      October 5, 1987
;
; MOTOROLA, INC.
; COPYRIGHT 1986, 1987
; ALL RIGHTS RESERVED
;
; INTRODUCTION
;
; FPLIB is a useful set of floating point arithmetic subroutines for the
; Motorola DSP56000/1 digital signal processor.  This HELP file defines
; the filenames, latest version numbers and latest revision date of all
; FPLIB subroutines.  Users should update their FPLIB copies if they do
; not have the latest versions since previous versions may have program
; bugs.  As new FPLIB routines are added, their entry date will be noted
; here.
;
;  FPLIB       Latest         Latest           First
; Filename     Version     Revision Date     Entry Date
; --------     -------     -------------     ----------
; fpinit         2.0          5-Oct-87        5-Oct-87
; fpadd          2.0          7-Oct-87        5-Oct-87
; fpsub          2.1         15-Oct-87        5-Oct-87
; fpcmp          2.1          3-Nov-87        5-Oct-87
; fpmpy          2.0          5-Oct-87        5-Oct-87
; fpmac          2.1         30-Oct-87        5-Oct-87
; fpdiv          2.0          5-Oct-87        5-Oct-87
; fpscale        2.0          5-Oct-87        5-Oct-87
; fpsqrt         2.0          5-Oct-87        5-Oct-87
; fpneg          2.0          5-Oct-87        5-Oct-87
; fpabs          2.0          5-Oct-87        5-Oct-87
; fpfix          2.0          5-Oct-87        5-Oct-87
; fpfloat        2.0          6-Oct-87        5-Oct-87
; fpfloor        2.0          1-Mar-88        1-Mar-88
; fpceil         2.0          1-Mar-88        1-Mar-88
; fpfrac         2.0          1-Mar-88        1-Mar-88
;
; and now, the routines...
;<<<EOF
;
;including "FPABS.ASM"
;
;SOF>>>
;;
;; This program originally available on the Motorola DSP bulletin board.
;; It is provided under a DISCLAIMER OF WARRANTY available from
;; Motorola DSP Operation, 6501 Wm. Cannon Drive W., Austin, Tx., 78735.
;;
;; Last Update 5 Oct 87   Version 2.0
;;
;; Entry points: fabs_a  R = absolute value(A)
;;               fabs_x  R = absolute value(X)
;;
;;       m = 24 bit mantissa (two's complement, normalized fraction)
;;
;;       e = 14 bit exponent (unsigned integer, biased by +8191)
;;
;; Input variables:
;;
;;   X   x1 = mx  (normalized)
;;       x0 = ex
;;
;;   A   a2 = sign extension of ma
;;       a1 = ma  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of ea (always zero)
;;       b1 = ea
;;       b0 = zero
;;
;; Output variables:
;;
;;   R   a2 = sign extension of mr
;;       a1 = mr  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of er (always zero)
;;       b1 = er
;;       b0 = zero
;;
;; Error conditions:     Set CCR L=1 if floating point overflow.  Result
;;                       is set to the maximum floating point value of the
;;                       correct sign.  The CCR L bit remains set until
;;                       cleared by the user.
;;
;;                       Set CCR L=1 if floating point underflow.  Result
;;                       is set to floating point zero.  The CCR L bit
;;                       remains set until cleared by the user.
;;
;; Assumes n0, m0, shift constant table and scaling modes
;; initialized by previous call to the subroutine "fpinit".
;;
;; Alters Data ALU Registers
;;       a2      a1      a0      a
;;       b2      b1      b0      b
;;       x1      x0      y1      y0
;;
;; Alters Address Registers
;;       r0
;;
;; Alters Program Control Registers
;;       pc      sr
;;
;; Uses 0 locations on System Stack
;;
;;
;fabs_x  tfr     x0,b    x1,a            ;get ex, mx
;fabs_a  tst     a                       ;check for negative ma
;        jmi     fneg_a                  ;negate if negative
;        rts
;<<<EOF
;
;including "FPADD.ASM"
;
;SOF>>>
;;
;; This program originally available on the Motorola DSP bulletin board.
;; It is provided under a DISCLAIMER OF WARRANTY available from
;; Motorola DSP Operation, 6501 Wm. Cannon Drive W., Austin, Tx., 78735.
;;
;; Last Update 7 Oct 87   Version 2.0
;;
;fpadd   ident   2,0
;;
;; MOTOROLA DSP56000/1 FPLIB - VERSION 2
;;
;; FPADD - FLOATING POINT ADDITION SUBROUTINE
;;
;; Entry points: fadd_xa R = A + X
;;               fadd_xy R = Y + X
;;
;;       m = 24 bit mantissa (two's complement, normalized fraction)
;;
;;       e = 14 bit exponent (unsigned integer, biased by +8191)
;;
;; Input variables:
;;
;;   X   x1 = mx  (normalized)
;;       x0 = ex
;;
;;   Y   y1 = my  (normalized)
;;       y0 = ey
;;
;;   A   a2 = sign extension of ma
;;       a1 = ma  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of ea (always zero)
;;       b1 = ea
;;       b0 = zero
;;
;; Output variables:
;;
;;   R   a2 = sign extension of mr
;;       a1 = mr  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of er (always zero)
;;       b1 = er
;;       b0 = zero
;;
;; Error conditions:     Set CCR L=1 if floating point overflow.  Result
;;                       is set to the maximum floating point value of the
;;                       correct sign.  The CCR L bit remains set until
;;                       cleared by the user.
;;
;;                       Set CCR L=1 if floating point underflow.  Result
;;                       is set to floating point zero.  The CCR L bit
;;                       remains set until cleared by the user.
;;
;; Assumes n0, m0, shift constant table and scaling modes
;; initialized by previous call to the subroutine "fpinit".
;;
;; Alters Data ALU Registers
;;       a2      a1      a0      a
;;       b2      b1      b0      b
;;       x1      x0      y1      y0
;;
;; Alters Address Registers
;;       r0
;;
;; Alters Program Control Registers
;;       pc      sr
;;
;; Uses 0 locations on System Stack
;;
;;
;fadd_xy tfr     y0,b    y1,a            ;get ey, my
;fadd_xa cmp     x0,b    fp_space:fp_23,y0       ;compare delta = er - ea,
;                                                ; get delta limit
;        jge     _dpos                   ;jump if er >= ea
;
; er < ea
;
;_dneg   tfr     x1,a    a1,x1           ;swap ma with mr
;        tfr     x0,b    b1,x0           ;swap ea with er
;;
;; er >= ea
;;
;_dpos   sub     x0,b    b1,y1           ;calculate delta, save er'
;        cmp     y0,b    b1,r0           ;check delta limit, save delta
;        jgt     done1                   ;jump if delta > 23
;addm    move    fp_space:(r0+n0),x0     ;lookup shift constant s
;        mac     -x1,x0,a        y1,r0   ;denormalize by s, add mantissa, get er'
;        jmp     norm1                   ;try for quick normalization
;;
;; normalize and round result - assumes a=mr', r0=er' and CCR reflects mr' value.
;;
;norm    rep     #8                      ;normalize up to 8 bits left or right
;norm1   norm    r0,a                    ;shift 1 bit and update exponent by 1
;        jnn     norm                    ;jump if not normalized
;round   rnd     a                       ;round to 24 bit mr
;        norm    r0,a                    ;correct mr overflow due to round
;;
;; detect and correct exceptions - assumes a=mr and r0=er
;;
;check   move    r0,fp_space:fp_temp     ;check er
;        jset    #15,fp_space:fp_temp,under      ;jump if exponent underflow
;        jset    #14,fp_space:fp_temp,limit      ;jump if exponent overflow
;check1  tst     a       r0,b            ;check mr, get er
;        teq     a,b                     ;if mr=0, correct to fp zero
;        rts
;under   or      #$40,ccr                ;set L=1 for exponent underflow
;zero    clr     a       #0,b            ;correct to fp zero
;        rts
;limit   asl     a       fp_space:fp_emax,y1     ;correct to maximum fp value
;done1   tfr     y1,b    a,a             ;get mr and er, set L bit if mr limited
;done    rts
;<<<EOF
;
;including "FPCEIL.ASM"
;
;SOF>>>
;fpceil  ident   2,0
;;
;; MOTOROLA DSP56000/1 FPLIB - VERSION 2
;;
;; This program, originally available on the Motorola DSP bulletin board,
;; is provided under a DISCLAIMER OF WARRANTY available from Motorola DSP
;; Operation, 6501 William Cannon Drive, West, Austin, Texas  78735-8598.
;;
;; FPCEIL - FLOATING POINT CEIL SUBROUTINE
;;
;; Entry points: fceil_a    R = ceil(A)
;;               fceil_x    R = ceil(X)
;;
;;       m = 24 bit mantissa (two's complement, normalized fraction)
;;
;;       e = 14 bit exponent (unsigned integer, biased by +8191)
;;
;; Input variables:
;;
;;   X   x1 = mx  (normalized)
;;       x0 = ex
;;
;;   A   a2 = sign extension of ma
;;       a1 = ma  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of ea (always zero)
;;       b1 = ea
;;       b0 = zero
;;
;; Output variables:
;;
;;   R   a2 = sign extension of mr
;;       a1 = mr  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of er (always zero)
;;       b1 = er
;;       b0 = zero
;;
;; Error conditions:     No error conditions are signaled.
;;
;; Assumes n0, m0, shift constant table and scaling modes
;; initialized by previous call to the subroutine "fpinit".
;;
;; Alters Data ALU Registers
;;       a2      a1      a0      a
;;       b2      b1      b0      b
;;       x1      x0
;;
;; Alters Address Registers
;;       r0
;;
;; Alters Program Control Registers
;;       pc      sr
;;       ssh     ssl     sp
;;
;; Uses 1 location on System Stack
;;
;; Version - 2.0
;; Latest Revision - February 22, 1988
;;
;fceil_x tfr     x0,b    x1,a            ;get mx,ex
;fceil_a
;        neg     a                       ;reverse number line
;        jsr     floor_a                 ;do floor operation
;        neg     a                       ;reverse number line
;        rts
;<<<EOF
;
;including "FPCMP.ASM"
;
;SOF>>>
;;
;; This program originally available on the Motorola DSP bulletin board.
;; It is provided under a DISCLAIMER OF WARRANTY available from
;; Motorola DSP Operation, 6501 Wm. Cannon Drive W., Austin, Tx., 78735.
;;
;; Last Update 3 Nov 87   Version 2.1
;;
;fpcmp   ident   2,1
;;
;; MOTOROLA DSP56000/1 FPLIB - VERSION 2
;;
;; FPCMP - FLOATING POINT COMPARISON (SETS CONDITION CODES) SUBROUTINE
;;
;;
;; Entry points: fcmp_xa A - X   SET CONDITION CODES
;;               fcmp_xy Y - X   SET CONDITION CODES
;;
;;       m = 24 bit mantissa (two's complement, normalized fraction)
;;
;;       e = 14 bit exponent (unsigned integer, biased by +8191)
;;
;; Input variables:
;;
;;   X   x1 = mx  (normalized)
;;       x0 = ex
;;
;;   Y   y1 = my  (normalized)
;;       y0 = ey
;;
;;   A   a2 = sign extension of ma
;;       a1 = ma  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of ea (always zero)
;;       b1 = ea
;;       b0 = zero
;;
;; Output variables:
;;
;;       The following Jcc branch conditions can be used after calling
;;       fcmp_xa or fcmp_xy.  The other branch conditions should not be used.
;;
;;       "cc" Mnemonic                   Condition
;;       -------------                   ---------
;;       EQ - equal                      Z = 1
;;       GE - greater than or equal      N eor V = 0
;;       GT - greater than               Z + (N eor V) = 0
;;       LE - less than or equal         Z + (N eor V) = 1
;;       LT - less than                  N eor V = 1
;;       NE - not equal                  Z = 0
;;
;; Error conditions:     none
;;
;; Assumes n0, m0, shift constant table and scaling modes
;; initialized by previous call to the subroutine "fpinit".
;;
;; Alters Data ALU Registers
;;       a2      a1      a0      a
;;       b2      b1      b0      b
;;               x0              y0
;;
;; Alters Address Registers
;;
;;
;; Alters Program Control Registers
;;       pc      sr
;;
;; Uses 0 locations on System Stack
;;
;;
;fcmp_xy tfr     y0,b    y1,a            ;get ey, my
;fcmp_xa eor     x1,a    a,y0            ;compare signs, save ma
;        jmi     _mant                   ;jump if different signs
;
; Same signs
;
;_sign   eor     x1,a                    ;check sign of ma
;        jpl     _sign1                  ;jump if ma and mx positive
;        tfr     x0,b    b,x0            ;if minus, exchange ea and ex
;_sign1  cmp     x0,b                    ;compare exponents
;        jne     done                    ;jump if different exponents
;;
;; Same signs, same exponents or different signs
;;
;_mant   tfr     y0,a                    ;restore ma
;        cmp     x1,a                    ;compare mantissa
;        rts
;<<<EOF
;
;including "FPDIV.ASM"
;
;SOF>>>
;;
;; This program originally available on the Motorola DSP bulletin board.
;; It is provided under a DISCLAIMER OF WARRANTY available from
;; Motorola DSP Operation, 6501 Wm. Cannon Drive W., Austin, Tx., 78735.
;;
;; Last Update 5 Oct 87   Version 2.0
;;
;fpdiv   ident   2,0
;;
;; MOTOROLA DSP56000/1 FPLIB VERSION 2
;;
;; FPDIV - FLOATING POINT DIVIDE SUBROUTINE
;;
;; Entry points: fdiv_xa R = A / X
;;               fdiv_xy R = Y / X
;;
;;       m = 24 bit mantissa (two's complement, normalized fraction)
;;
;;       e = 14 bit exponent (unsigned integer, biased by +8191)
;;
;; Input variables:
;;
;;   X   x1 = ma  (normalized)
;;       x0 = ea
;;
;;   Y   y1 = my  (normalized)
;;       y0 = ey
;;
;;   A   a2 = sign extension of ma
;;       a1 = ma  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of ea (always zero)
;;       b1 = ea
;;       b0 = zero
;;
;; Output variables:
;;
;;   R   a2 = sign extension of mr
;;       a1 = mr  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of er (always zero)
;;       b1 = er
;;       b0 = zero
;;
;; Error conditions:     Set CCR L=1 if divide by zero error.  Result is
;;                       set to the maximum floating point value having
;;                       the same sign as the dividend if the dividend
;;                       is non-zero.  Result is set to floating point
;;                       zero if the dividend is zero.  The CCR L bit
;;                       remains set until cleared by the user.
;;
;;                       Set CCR L=1 if floating point overflow.  Result
;;                       is set to the maximum floating point value of the
;;                       correct sign.  The CCR L bit remains set until
;;                       cleared by the user.
;;
;;                       Set CCR L=1 if floating point underflow.  Result
;;                       is set to floating point zero.  The CCR L bit
;;                       remains set until cleared by the user.
;;
;; Assumes n0, m0, shift constant table and scaling modes
;; initialized by previous call to the subroutine "fpinit".
;;
;; Alters Data ALU Registers
;;       a2      a1      a0      a
;;       b2      b1      b0      b
;;       y1                      x0
;;
;; Alters Address Registers
;;       r0
;;
;; Alters Program Control Registers
;;       pc      sr
;;
;; Uses 0 locations on System Stack
;;
;;
;fdiv_xy tfr     y0,b    y1,a            ;get ey, my
;fdiv_xa sub     x0,b    fp_space:fp_ebias,x0 ;calculate er' = ea - ex,get ebias
;        add     x0,b                    ;add ebias to er'
;        tfr     x1,b    b,r0            ;get mx, save er'
;        tst     b                       ;check for divisor mx = 0
;        jne     _div1                   ;jump if divisor not zero
;        tst     a                       ;check for dividend ma = 0
;        jne     limit                   ;jump if dividend not zero
;        or      #$40,ccr                ;set L=1 for divide by zero error
;_div1   asr     a       a,b             ;force fractional quotient, copy ma
;        jeq     done                    ;jump if dividend ma = 0 (underflow)
;        abs     a       (r0)+           ;make dividend positive, adjust er'
;        eor     x1,b                    ;calculate quotient sign
;        and     #$fe,ccr                ;clear carry (quotient sign bit)
;        rep     #24                     ;repeat for 24 bit quotient
;        div     x1,a                    ;generate one quotient bit
;        jpl     _qpos                   ;jump if positive quotient
;        neg     a                       ;negate mr' for negative quotient
;_qpos   move    a0,a                    ;get quotient mr'
;        tst     a                       ;normalize mr' 1 extra bit
;        norm    r0,a                    ;shift 1 bit and update exponent by 1
;        jmp     norm1                   ;normalize and check for errors
;<<<EOF
;
;including "FPFIX.ASM"
;
;SOF>>>
;;
;; This program originally available on the Motorola DSP bulletin board.
;; It is provided under a DISCLAIMER OF WARRANTY available from
;; Motorola DSP Operation, 6501 Wm. Cannon Drive W., Austin, Tx., 78735.
;;
;; Last Update 5 Oct 87   Version 2.0
;;
;fpfix   ident   2,0
;;
;; MOTOROLA DSP56000/1 FPLIB - VERSION 2
;;
;; FPFIX - FLOATING POINT TO FIXED POINT CONVERSION SUBROUTINE
;;
;; Entry points: fix_a   D = fix(A)
;;               fix_x   D = fix(X)
;;
;;       m = 24 bit mantissa (two's complement, normalized fraction)
;;
;;       e = 14 bit exponent (unsigned integer, biased by +8191)
;;
;;       data = 56 bit fixed point data in standard integer/fractional
;;              accumulator data representation.
;;
;; Input variables:
;;
;;   X   x1 = mx  (normalized)
;;       x0 = ex
;;
;;   A   a2 = sign extension of ma
;;       a1 = ma  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of ea (always zero)
;;       b1 = ea
;;       b0 = zero
;;
;; Output variables:
;;
;;   D    a = data
;;
;; Error conditions:     Set CCR L=1 if conversion overflow error.  That is,
;;                       the input value was larger than +/- 256 and could
;;                       not be represented in the standard 56 bit accumulator
;;                       format.  Result is the maximum 56 bit fixed point
;;                       value having the same sign as the floating point
;;                       mantissa.  The CCR L bit remains set until cleared
;;                       by the user.
;;
;; Assumes n0, m0, shift constant table and scaling modes
;; initialized by previous call to the subroutine "fpinit".
;;
;; Alters Data ALU Registers
;;       a2      a1      a0      a
;;       b2      b1      b0      b
;;               x0      y1
;;
;; Alters Address Registers
;;       r0
;;
;; Alters Program Control Registers
;;       pc      sr
;;
;; Uses 0 locations on System Stack
;;
;;
;fix_x   tfr     x0,b    x1,a            ;get mx,ex
;fix_a   tst     a       fp_space:fp_ebias,x0    ;check ma, get bias
;        jeq     done                    ;jump if ma = 0
;        sub     x0,b    #>8,x0          ;remove ea bias, get shift limit
;        jlt     _eneg                   ;jump if exponent < 0
;        jeq     done                    ;jump if exponent = 0
;;
;; exponent > 0
;;
;        cmp     x0,b                    ;check left shift limit
;        jgt     _ehigh                  ;jump if exponent > 8
;        rep     b                       ;shift left b bits
;        asl     a                       ;shift data left
;        rts
;_ehigh  or      #$40,ccr                ;set L=1 for conversion overflow
;        tst     a                       ;check sign of ma
;        jpl     _fix1                   ;jump if ma positive
;        clr     a                       ;limit to maximum negative 56 bit value
;        move    #$80,a2                 ;set extension word
;        rts
;_fix1   clr     a                       ;limit to maximum positive 56 bit value
;        not     a                       ;set most significant word
;        move    a1,a0                   ;set least significant word
;        move    #$7f,a2                 ;set extension word
;        rts
;;
;; exponent < 0
;;
;_eneg   abs     b       #>24,x0         ;fix exponent, get right shift limit
;        sub     x0,b    b1,r0           ;check for underflow, save exponent
;        jge     _elow                   ;jump if fixed point underflow
;        move    fp_space:(r0+n0),x0     a,y1    ;lookup shift factor, get ma
;        mpy     -y1,x0,a                ;denormalize ma
;        rts
;_elow   jeq     _shift                  ;jump if exponent = -24
;        cmp     x0,b    b1,r0           ;check for underflow, save exponent
;        jge     zero                    ;jump if data underflow
;        move    fp_space:(r0+n0),x0     a,y1    ;lookup shift factor, get ma
;        mpy     -y1,x0,a                ;denormalize ma
;_shift  tfr     a,b     a2,a            ;shift down 24 bits more
;        move    b1,a0
;        rts
;<<<EOF
;
;including "FPFLOAT.ASM"
;
;SOF>>>
;;
;; This program originally available on the Motorola DSP bulletin board.
;; It is provided under a DISCLAIMER OF WARRANTY available from
;; Motorola DSP Operation, 6501 Wm. Cannon Drive W., Austin, Tx., 78735.
;;
;; Last Update 6 Oct 87   Version 2.0
;;
;fpfloat ident   2,0
;;
;; MOTOROLA DSP56000/1 FPLIB - VERSION 2
;;
;; FPFLOAT - FIXED POINT TO FLOATING POINT CONVERSION SUBROUTINE
;;
;; Entry points: float_a R = float(A)
;;               float_x R = float(X)
;;
;;       data = 56 bit two's complement fixed point number
;;              consisting of a 48 bit fraction with an 8 bit
;;              integer extension in standard accumulator data
;;              representation.
;;
;;       m = 24 bit mantissa (two's complement, normalized fraction)
;;
;;       e = 14 bit exponent (unsigned integer, biased by +8191)
;;
;; Input variables:
;;
;;   X   x1 = data
;;
;;   A    a = data
;;
;; Output variables:
;;
;;   R   a2 = sign extension of mr
;;       a1 = mr  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of er (always zero)
;;       b1 = er
;;       b0 = zero
;;
;; Error conditions:     none
;;
;; Assumes n0, m0, shift constant table and scaling modes
;; initialized by previous call to the subroutine "fpinit".
;;
;; Alters Data ALU Registers
;;       a2      a1      a0      a
;;       b2      b1      b0      b
;;       y1
;;
;; Alters Address Registers
;;       r0
;;
;; Alters Program Control Registers
;;       pc      sr
;;
;; Uses 0 locations on System Stack
;;
;;
;float_x tfr     x1,a                    ;get data
;float_a tst     a       fp_space:fp_ebias,r0    ;check data, initialize er
;        jnr     float1                  ;jump if data normalized
;norm8   rep     #8                      ;normalize up to 8 bits left or right
;        norm    r0,a                    ;normalize one bit, update er
;        jnn     norm8                   ;jump if not normalized
;float1  rnd     a                       ;round mr to 24 bits
;        norm    r0,a                    ;correct overflow due to rounding
;        jmp     check1                  ;go check exponent range
;<<<EOF
;
;including "FPFRAC.ASM"
;
;SOF>>>
;fpfrac  ident   2,0
;;
;; MOTOROLA DSP56000/1 FPLIB - VERSION 2
;;
;; This program, originally available on the Motorola DSP bulletin board,
;; is provided under a DISCLAIMER OF WARRANTY available from Motorola DSP
;; Operation, 6501 William Cannon Drive, West, Austin, Texas  78735-8598.
;;
;; FPFRAC - FLOATING POINT FRACTION SUBROUTINE
;;
;; Entry points: frac_a     R = frac(A)
;;               frac_x     R = frac(X)
;;
;;       m = 24 bit mantissa (two's complement, normalized fraction)
;;
;;       e = 14 bit exponent (unsigned integer, biased by +8191)
;;
;; Input variables:
;;
;;   X   x1 = mx  (normalized)
;;       x0 = ex
;;
;;   A   a2 = sign extension of ma
;;       a1 = ma  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of ea (always zero)
;;       b1 = ea
;;       b0 = zero
;;
;; Output variables:
;;
;;   R   a2 = sign extension of mr
;;       a1 = mr  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of er (always zero)
;;       b1 = er
;;       b0 = zero
;;
;; Error conditions:     No error conditions are signaled.
;;
;; Assumes n0, m0, shift constant table and scaling modes
;; initialized by previous call to the subroutine "fpinit".
;;
;; Alters Data ALU Registers
;;       a2      a1      a0      a
;;       b2      b1      b0      b
;;       x1      x0      y1      y0
;;
;; Alters Address Registers
;;       r0
;;
;; Alters Program Control Registers
;;       pc      sr
;;       ssh     ssl     sp
;;
;; Uses 1 location on System Stack
;;
;; Version - 2.0
;; Latest Revision - February 22, 1988
;;
;frac_x
;        tfr     x0,b    x1,a            ;get mx,ex
;frac_a
;        move    b1,y0                   ;copy input
;        move    a1,y1
;        jsr     floor_a                 ;get floor of input
;        move    b1,x0                   ;put floor in X
;        move    a1,x1
;        jmp     fsub_xy                 ;R=x-floor(x)
;<<<EOF
;
;including "FPINIT.ASM"
;
;SOF>>>
;;
;; This program originally available on the Motorola DSP bulletin board.
;; It is provided under a DISCLAIMER OF WARRANTY available from
;; Motorola DSP Operation, 6501 Wm. Cannon Drive W., Austin, Tx., 78735.
;;
;; Last Update 5 Oct 87   Version 2.0
;;
;fpinit  ident   2,0
;;
;; MOTOROLA DSP56000/1 FPLIB - VERSION 2
;;
;; FPINIT - FLOATING POINT LIBRARY INITIALIZATION SUBROUTINE
;;
;; Entry point:  fpinit  Initialize address pointers and shift constant
;;                       table for DSP56000/1 floating point subroutine
;;                       library.
;;
;; Input variables:      none
;;
;; Output variables:
;;
;;       n0 = base address of shift constant table
;;       m0 = $ffff  (linear address modifier)
;;
;;       shift constant table - stores multiplication constants for
;;                              denormalization operations.
;;
;;       The X or Y data memory space (without the colon) used for the
;;       shift constant table must be specified in single quotes by a
;;       DEFINE directive for the global symbol "fp_space" and the base
;;       address of the shift constant table must be specified for the
;;       global symbol "fp_temp" via an EQU or similar directive.  An
;;       example is given below.
;;
;;               define  fp_space        'x'
;;       fp_temp equ     $0000
;;
;; Error conditions:     none
;;
;; Memory requirements:  28 locations in "fp_space" memory space
;;
;; Alters Address Registers
;;               n0      m0
;;
;; Alters Program Control Registers
;;       pc      sr
;;
;; Uses 0 locations on System Stack
;;
;;
;        org     fp_space:fp_temp
;        ds      4       ;temporary storage locations
;fp_23   dc      23      ;exponent delta limit
;fp_ebias dc     $001fff ;fixed point exponent bias
;fp_emax dc      $003fff ;maximum exponent
;fp_shift dc     $800000,$c00000,$e00000,$f00000,$f80000,$fc0000,$fe0000,$ff0000
;        dc      $ff8000,$ffc000,$ffe000,$fff000,$fff800,$fffc00,$fffe00,$ffff00
;        dc      $ffff80,$ffffc0,$ffffe0,$fffff0,$fffff8,$fffffc,$fffffe
;fp_m1   dc      $ffffff
;;
;        org p:
;fpinit  move    fp_space:fp_m1,m0       ;initialize linear address modifier
;        move    #fp_shift,n0    ;initialize base address of shift constant table
;        and     #$f3,mr         ;reset scaling modes (S1,S0)
;        and     #$bf,ccr        ;reset overflow flag (L bit)
;        rts
;<<<EOF
;
;including "FPLIST.ASM"
;
;SOF>>>
;;
;; This program originally available on the Motorola DSP bulletin board.
;; It is provided under a DISCLAIMER OF WARRANTY available from
;; Motorola DSP Operation, 6501 Wm. Cannon Drive W., Austin, Tx., 78735.
;;
;; Last Update 5 Oct 87   Version 2.0
;;
;;
;; Call FPLIB subroutines for listing purposes
;;
;        page    132,60,5,5
;        opt     nomd,mex,mu,cre
;        define  fp_space 'x'
;fp_temp equ     0
;        org     p:0
;        jmp     start
;        org     p:$100
;        page
;        include 'fpinit'
;        page
;        include 'fpadd'
;        page
;        include 'fpsub'
;        page
;        include 'fpcmp'
;        page
;        include 'fpmpy'
;        page
;        include 'fpmac'
;        page
;        include 'fpdiv'
;        page
;        include 'fpsqrt'
;        page
;        include 'fpneg'
;        page
;        include 'fpabs'
;        page
;        include 'fpscale'
;        page
;        include 'fpfix'
;        page
;        include 'fpfloat'
;        page
;start   jsr     fpinit
;loop    jsr     fadd_xa
;        jsr     fadd_xy
;        jsr     fsub_xa
;        jsr     fsub_xy
;        jsr     fcmp_xa
;        jsr     fcmp_xy
;        jsr     fmpy_xa
;        jsr     fmpy_xy
;        jsr     fmac_xya
;        jsr     fmac_mxya
;        jsr     fdiv_xa
;        jsr     fdiv_xy
;        jsr     fsqrt_a
;        jsr     fsqrt_x
;        jsr     fneg_a
;        jsr     fneg_x
;        jsr     fabs_a
;        jsr     fabs_x
;        jsr     fscal_xa
;        jsr     fscal_xy
;        jsr     fix_a
;        jsr     fix_x
;        jsr     float_a
;        jsr     float_x
;        jmp     loop
;        end
;<<<EOF
;
;including "FPMAC.ASM"
;
;SOF>>>
;;
;; This program originally available on the Motorola DSP bulletin board.
;; It is provided under a DISCLAIMER OF WARRANTY available from
;; Motorola DSP Operation, 6501 Wm. Cannon Drive W., Austin, Tx., 78735.
;;
;; Last Update 30 Oct 87   Version 2.1
;;
;fpmac   ident   2,1
;;
;; MOTOROLA DSP56000/1 FPLIB - VERSION 2
;;
;; FPMAC - FLOATING POINT MULTIPLY/ACCUMULATION SUBROUTINE
;;
;; Entry points: fmac_xya        R = A + X * Y
;;               fmac_mxya       R = A - X * Y
;;
;;       m = 24 bit mantissa (two's complement, normalized fraction)
;;
;;       e = 14 bit exponent (unsigned integer, biased by +8191)
;;
;; Input variables:
;;
;;   X   x1 = mx  (normalized)
;;       x0 = ex
;;
;;   Y   y1 = my  (normalized)
;;       y0 = ey
;;
;;   A   a2 = sign extension of ma
;;       a1 = ma  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of ea (always zero)
;;       b1 = ea
;;       b0 = zero
;;
;; Output variables:
;;
;;   R   a2 = sign extension of mr
;;       a1 = mr  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of er (always zero)
;;       b1 = er
;;       b0 = zero
;;
;; Error conditions:     Set CCR L=1 if floating point overflow.  Result
;;                       is set to the maximum floating point value of the
;;                       correct sign.  The CCR L bit remains set until
;;                       cleared by the user.
;;
;;                       Set CCR L=1 if floating point underflow.  Result
;;                       is set to floating point zero.  The CCR L bit
;;                       remains set until cleared by the user.
;;
;; Assumes n0, m0, shift constant table and scaling modes
;; initialized by previous call to the subroutine "fpinit".
;;
;; Alters Data ALU Registers
;;       a2      a1      a0      a
;;       b2      b1      b0      b
;;       x1      x0      y1      y0
;;
;; Alters Address Registers
;;       r0
;;
;; Alters Program Control Registers
;;       pc      sr
;;
;; Uses 1 location on System Stack
;;
;fmac_xya move   a,fp_space:fp_temp+1    ;save ma
;        move    b,fp_space:fp_temp+2    ;save ea
;        jsr     fmpy_xy                 ;multiply x*y first
;        move    fp_space:fp_temp+1,x1   ;restore ma
;        move    fp_space:fp_temp+2,x0   ;restore ea
;        jmp     fadd_xa                 ;add product to a
;;
;fmac_mxya move  a,fp_space:fp_temp+1    ;save ma
;        move    b,fp_space:fp_temp+2    ;save ea
;        jsr     fmpy_xy                 ;multiply x*y first
;        move    a,x1                    ;save product mantissa
;        move    b,x0                    ;save product exponent
;        move    fp_space:fp_temp+1,a    ;restore ma
;        move    fp_space:fp_temp+2,b    ;restore ea
;        jmp     fsub_xa                 ;subtract product from a
;<<<EOF
;
;including "FPMPY.ASM"
;
;SOF>>>
;;
;; This program originally available on the Motorola DSP bulletin board.
;; It is provided under a DISCLAIMER OF WARRANTY available from
;; Motorola DSP Operation, 6501 Wm. Cannon Drive W., Austin, Tx., 78735.
;;
;; Last Update 5 Oct 87   Version 2.0
;;
;fpmpy   ident   2,0
;;
;; MOTOROLA DSP56000/1 FPLIB - VERSION 2
;;
;; FPMPY - FLOATING POINT MULTIPLICATION SUBROUTINE
;;
;; Entry points: fmpy_xy R = X * Y
;;               fmpy_xa R = X * A
;;
;;       m = 24 bit mantissa (two's complement, normalized fraction)
;;
;;       e = 14 bit exponent (unsigned integer, biased by +8191)
;;
;; Input variables:
;;
;;   X   x1 = mx  (normalized)
;;       x0 = ex
;;
;;   Y   y1 = my  (normalized)
;;       y0 = ey
;;
;;   A   a2 = sign extension of ma
;;       a1 = ma  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of ea (always zero)
;;       b1 = ea
;;       b0 = zero
;;
;; Output variables:
;;
;;   R   a2 = sign extension of mr
;;       a1 = mr  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of er (always zero)
;;       b1 = er
;;       b0 = zero
;;
;; Error conditions:     Set CCR L=1 if floating point overflow.  Result
;;                       is set to the maximum floating point value of the
;;                       correct sign.  The CCR L bit remains set until
;;                       cleared by the user.
;;
;;                       Set CCR L=1 if floating point underflow.  Result
;;                       is set to floating point zero.  The CCR L bit
;;                       remains set until cleared by the user.
;;
;; Assumes n0, m0, shift constant table and scaling modes
;; initialized by previous call to the subroutine "fpinit".
;;
;; Alters Data ALU Registers
;;       a2      a1      a0      a
;;       b2      b1      b0      b
;;       y1
;;
;; Alters Address Registers
;;       r0
;;
;; Alters Program Control Registers
;;       pc      sr
;;
;; Uses 0 locations on System Stack
;;
;;
;fmpy_xy tfr     y0,b    y1,a            ;get ey, my
;fmpy_xa add     x0,b    fp_space:fp_ebias,x0    ;er' = ex + ea,get ebias
;        sub     x0,b    a,y1            ;subtract ebias from er',get ma
;        mpy     x1,y1,a         b,r0    ;mr = mx * ma, get er'
;        jmp     norm1                   ;normalize and check result
;<<<EOF
;
;including "FPNEG.ASM"
;
;SOF>>>
;;
;; This program originally available on the Motorola DSP bulletin board.
;; It is provided under a DISCLAIMER OF WARRANTY available from
;; Motorola DSP Operation, 6501 Wm. Cannon Drive W., Austin, Tx., 78735.
;;
;; Last Update 5 Oct 87   Version 2.0
;;
;fpneg   ident   2,0
;;
;; MOTOROLA DSP56000/1 FPLIB - VERSION 2
;;
;; FPNEG - FLOATING POINT NEGATION SUBROUTINE
;;
;; Entry points: fneg_a  R = -A
;;               fneg_x  R = -X
;;
;;       m = 24 bit mantissa (two's complement, normalized fraction)
;;
;;       e = 14 bit exponent (unsigned integer, biased by +8191)
;;
;; Input variables:
;;
;;   X   x1 = mx  (normalized)
;;       x0 = ex
;;
;;   A   a2 = sign extension of ma
;;       a1 = ma  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of ea (always zero)
;;       b1 = ea
;;       b0 = zero
;;
;; Output variables:
;;
;;   R   a2 = sign extension of mr
;;       a1 = mr  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of er (always zero)
;;       b1 = er
;;       b0 = zero
;;
;; Error conditions:     Set CCR L=1 if floating point overflow.  Result
;;                       is set to the maximum floating point value of the
;;                       correct sign.  The CCR L bit remains set until
;;                       cleared by the user.
;;
;;                       Set CCR L=1 if floating point underflow.  Result
;;                       is set to floating point zero.  The CCR L bit
;;                       remains set until cleared by the user.
;;
;; Assumes n0, m0, shift constant table and scaling modes
;; initialized by previous call to the subroutine "fpinit".
;;
;; Alters Data ALU Registers
;;       a2      a1      a0      a
;;       b2      b1      b0      b
;;       x1      x0      y1      y0
;;
;; Alters Address Registers
;;       r0
;;
;; Alters Program Control Registers
;;       pc      sr
;;
;; Uses 0 locations on System Stack
;;
;;
;fneg_x  tfr     x0,b    x1,a            ;get ex, mx
;fneg_a  neg     a       b,r0            ;negate ma, save ea
;        jmp     norm1                   ;normalize ma and check ea
;<<<EOF
;
;including "FPSCALE.ASM"
;
;SOF>>>
;;
;; This program originally available on the Motorola DSP bulletin board.
;; It is provided under a DISCLAIMER OF WARRANTY available from
;; Motorola DSP Operation, 6501 Wm. Cannon Drive W., Austin, Tx., 78735.
;;
;; Last Update 5 Oct 87   Version 2.0
;;
;fpscale ident   2,0
;;
;; MOTOROLA DSP56000/1 FPLIB - VERSION 2
;;
;; FPSCALE - FLOATING POINT SCALING SUBROUTINE
;;
;; Entry points: fscal_xa        R = A * 2**X
;;               fscal_xy        R = Y * 2**X
;;
;;       m = 24 bit mantissa (two's complement, normalized fraction)
;;
;;       e = 14 bit exponent (unsigned integer, biased by +8191)
;;
;; Input variables:
;;
;;   X   x0 = ex
;;
;;   Y   y1 = my  (normalized)
;;       y0 = ey
;;
;;   A   a2 = sign extension of ma
;;       a1 = ma  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of ea (always zero)
;;       b1 = ea
;;       b0 = zero
;;
;; Output variables:
;;
;;   R   a2 = sign extension of mr
;;       a1 = mr  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of er (always zero)
;;       b1 = er
;;       b0 = zero
;;
;; Error conditions:     Set CCR L=1 if floating point overflow.  Result
;;                       is set to the maximum floating point value of the
;;                       correct sign.  The CCR L bit remains set until
;;                       cleared by the user.
;;
;;                       Set CCR L=1 if floating point underflow.  Result
;;                       is set to floating point zero.  The CCR L bit
;;                       remains set until cleared by the user.
;;
;; Assumes n0, m0, shift constant table and scaling modes
;; initialized by previous call to the subroutine "fpinit".
;;
;; Alters Data ALU Registers
;;       a2      a1      a0      a
;;       b2      b1      b0      b
;;       x1      x0      y1      y0
;;
;; Alters Address Registers
;;       r0
;;
;; Alters Program Control Registers
;;       pc      sr
;;
;; Uses 0 locations on System Stack
;;
;;
;fscal_xy        tfr     y0,b    y1,a    ;get ey, my
;fscal_xa        add     x0,b            ;add scale factor to ea
;        move    b,r0                    ;save er'
;        jmp     check                   ;check for exponent errors
;<<<EOF
;
;including "FPSQRT.ASM"
;
;SOF>>>
;;
;; This program originally available on the Motorola DSP bulletin board.
;; It is provided under a DISCLAIMER OF WARRANTY available from
;; Motorola DSP Operation, 6501 Wm. Cannon Drive W., Austin, Tx., 78735.
;;
;; Last Update 5 Oct 87   Version 2.0
;;
;fpsqrt  ident   2,0
;;
;; MOTOROLA DSP56000/1 FPLIB - VERSION 2
;;
;; FPSQRT - FLOATING POINT SQUARE ROOT SUBROUTINE
;;
;; Entry points: fsqrt_a R = square root(A)
;;               fsqrt_x R = square root(X)
;;
;;       m = 24 bit mantissa (two's complement, normalized fraction)
;;
;;       e = 14 bit exponent (unsigned integer, biased by +8191)
;;
;; Input variables:
;;
;;   X   x1 = mx  (normalized)
;;       x0 = ex
;;
;;   A   a2 = sign extension of ma
;;       a1 = ma  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of ea (always zero)
;;       b1 = ea
;;       b0 = zero
;;
;; Output variables:
;;
;;   R   a2 = sign extension of mr
;;       a1 = mr  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of er (always zero)
;;       b1 = er
;;       b0 = zero
;;
;; Error conditions:     Set CCR L=1 if input value is negative.  Result
;;                       is set to floating point zero.  The CCR L bit
;;                       remains set until cleared by the user.
;;
;; Assumes n0, m0, shift constant table and scaling modes
;; initialized by previous call to the subroutine "fpinit".
;;
;; Alters Data ALU Registers
;;       a2      a1      a0      a
;;       b2      b1      b0      b
;;       x1      x0      y1      y0
;;
;; Alters Address Registers
;;       r0
;;
;; Alters Program Control Registers
;;       pc      sr
;;       la      lc
;;       ssh     ssl     sp
;;
;; Uses 2 locations on System Stack
;;
;;
;fsqrt_x tfr     x0,b    x1,a            ;get mx,ex
;fsqrt_a tst     a       fp_space:fp_ebias,x0    ;check for negative input
;        jmi     under                   ;jump if negative, set L bit
;        jeq     done                    ;jump if zero
;        sub     x0,b                    ;remove ebias from ea
;        lsr     b       #<$40,y0        ;er' = ea / 2, get first guess
;        jcc     _sqrt1                  ;jump if er' even
;        asr     a       fp_space:fp_m1,x1       ;divide ma by 2, get -1
;        sub     x1,b                    ;increment er' by 1
;_sqrt1  add     x0,b    y0,x0           ;add ebias to er', save first temp
;        clr     b       b,r0            ;clear root, save er'
;        do      #23,_sqrt2              ;square all 23 bits
;        mac     -x0,x0,a        a,x1    ;square temp, save ma
;        tge     x0,b                    ;update root if correct guess
;        move    y0,a                    ;get guess bit
;        asr     a                       ;try next bit
;        add     b,a     a,y0            ;form root guess, save guess bit
;        tfr     x1,a    a,x0            ;get ma, save temp
;_sqrt2
;        tfr     b,a     r0,b            ;get root mr, er
;        rts
;<<<EOF
;
;including "FPSUB.ASM"
;
;SOF>>>
;;
;; This program originally available on the Motorola DSP bulletin board.
;; It is provided under a DISCLAIMER OF WARRANTY available from
;; Motorola DSP Operation, 6501 Wm. Cannon Drive W., Austin, Tx., 78735.
;;
;; Last Update 15 Oct 87   Version 2.1
;;
;fpsub   ident   2,1
;;
;; MOTOROLA DSP56000/1 FPLIB - VERSION 2
;;
;; FPSUB - FLOATING POINT SUBTRACTION SUBROUTINE
;;
;; Entry points: fsub_xa R = A - X
;;               fsub_xy R = Y - X
;;
;;       m = 24 bit mantissa (two's complement, normalized fraction)
;;
;;       e = 14 bit exponent (unsigned integer, biased by +8191)
;;
;; Input variables:
;;
;;   X   x1 = mx  (normalized)
;;       x0 = ex
;;
;;   Y   y1 = my  (normalized)
;;       y0 = ey
;;
;;   A   a2 = sign extension of ma
;;       a1 = ma  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of ea (always zero)
;;       b1 = ea
;;       b0 = zero
;;
;; Output variables:
;;
;;   R   a2 = sign extension of mr
;;       a1 = mr  (normalized)
;;       a0 = zero
;;
;;       b2 = sign extension of er (always zero)
;;       b1 = er
;;       b0 = zero
;;
;; Error conditions:     Set CCR L=1 if floating point overflow.  Result
;;                       is set to the maximum floating point value of the
;;                       correct sign.  The CCR L bit remains set until
;;                       cleared by the user.
;;
;;                       Set CCR L=1 if floating point underflow.  Result
;;                       is set to floating point zero.  The CCR L bit
;;                       remains set until cleared by the user.
;;
;; Assumes n0, m0, shift constant table and scaling modes
;; initialized by previous call to the subroutine "fpinit".
;;
;; Alters Data ALU Registers
;;       a2      a1      a0      a
;;       b2      b1      b0      b
;;       x1      x0      y1      y0
;;
;; Alters Address Registers
;;       r0
;;
;; Alters Program Control Registers
;;       pc      sr
;;
;; Uses 0 locations on System Stack
;;
;;
;fsub_xy tfr     y0,b    y1,a            ;get ey, my
;fsub_xa sub     x0,b    b1,y1           ;compare delta = ea - ex, save ea
;        jge     _dpos                   ;jump if ea >= ex
;;
;; ea < ex
;;
;_dneg   tfr     x1,a    a1,x1           ;swap ma with mx
;        neg     a       x0,y1           ;negate mx, save ex
;        abs     b       fp_space:fp_23,y0       ;negate er', get delta limit
;        cmp     y0,b    b1,r0           ;check delta limit, save delta
;        jle     addm                    ;jump if delta =< 23
;        tst     a       x0,r0           ;get er', setup CCR for norm
;        jmp     norm1                   ;normalize result
;;
;; ea >= ex
;;
;_dpos   move            fp_space:fp_23,y0       ;get delta limit
;        cmp     y0,b    b1,r0           ;check delta limit, save delta
;        jgt     done1                   ;jump if delta > 23
;        move    fp_space:(r0+n0),x0     ;lookup shift constant s
;        mac     x1,x0,a y1,r0           ;denormalize by s,
;                                        ;  subtract mantissa, get er'
;        jmp     norm                    ;normalize result
;<<<EOF
;
; *****************************************************************************
; > XBIOS DSP Functions - ATARI Corporation (c) 1992 & KOSS (c) 1999
;
; - XBIOS $60/ 96 DSP_DOBLOCK -
; DSP_DoBlock will handle block transfers of data between the Host Process and
; the Process inside the DSP. Data pointed to by DataIn will be passed to the
; DSP until SizeIn number of DSP Words are transferred over (the number of
; bytes in a DSP Word is returned by the DSP_GetWordSize call). It is important
; to note that no HandShaking will occur while the routine is feeding the data
; to the DSP. It will be assumed that for the purpose of this call, the DSP will
; be able to accept the data as fast as we can provide it. The call will wait for
; the first DSP Word to be accepted by the DSP before beginning transfer of the
; rest of the Buffer. After all of the data has been transferred to the DSP,
; DSP_DoBlock will wait until the DSPhas finished processing the data and is
; ready to send it back to the Host (when the RXDF Bit is set in the ISR register).
; At this time, SizeOut number of DSP Words will be read from the DSP and stored
; into the Buffer pointed to by DataOut. Again, no polling of dataready bits will
; occur before data transfer. Also, we will read SizeOut number of Words into
; the DataOut Buffer whether or not that much data actually exists for the
; transfer from the DSP. If no data is expected out of the DSP, a zero should be
; placed in SizeOut. Similarly if no input is to be received by the DSP, SizeIn
; should be set to zero.
;
; Parameters : LONG : SizeOut
;              LONG : Address of a Buffer -> DataOut (RAW array)
;              LONG : SizeIn
;              LONG : Address of a Buffer -> DataIn  (RAW array)
; Return     : None
; Stack      : 18
;
; - XBIOS $61/ 97 DSP_BLKHANDSHAKE -
; This call is identical to DSP_DoBlock except that HandShaking takes place during
; the transfer of the entire Buffer. This call will be slower than DSP_DoBlock and
; should ONLY be used when the routine is expected to send/receive data faster than
; the DSP Process can accept or send it.
;
; Parameters : LONG : SizeOut
;              LONG : Address of a Buffer -> DataOut (RAW array)
;              LONG : SizeIn
;              LONG : Address of a Buffer -> DataIn  (RAW array)
; Return     : None
; Stack      : 18
;
; - XBIOS $62/ 98 DSP_BLKUNPACKED -
; DSP_BlkUnpacked is another block transfer routine which works in a similar manner
; to DSP_DoBlock. This routine will work ONLY for TOS Versions which will return a
; value of 4 or smaller for DSP_GetWordSize. DataIn and DataOut are arrays of 32 Bits
; long Words. SizeIn and SizeOut are the number of longwords in the array and the
; number of DSP Words to transfer. Data is fetched from the least significant bytes
; of the longword and sent to the DSP. Similarly, data obtained from the DSP is
; placed into the least significant bytes of the SizeOut Buffer.
; For example if DSP_GetWordSize returned 3 (24 Bits of DSP Data). The least
; significant 24 Bits of each longword would contain DSP Data while the most
; significant 8 Bits would contain something meaningless. (Note: These 8 Bits are
; not guaranteed to contain zero. If the calling routine expects this byte to be
; cleared, it must mask it off itself).
;
; Parameters : LONG : SizeOut
;              LONG : Address of a Buffer -> DataOut (32 Bits array)
;              LONG : SizeIn
;              LONG : Address of a Buffer -> DataIn  (32 Bits array)
; Return     : None
; Stack      : 18
;
; - XBIOS $63/ 99 DSP_INSTREAM -
; DS_InStream will pass data to the DSP from the given Buffer via a DSP Interrupt
; Handler. Each time an Interrupt occurs telling the routine that the DSP is ready
; for more data, BlockSize DSP Words will be transmitted to the DSP. As with the
; block move function, no HandShaking will occur during this process. This routine
; will continue servicing interrupts until it has transferres over "NumBlocks"
; number of blocks to the DSP. At that time the interrupt routine will tell the
; DSP to stop sending ready to receive interrupts.
; DSP_InStream will update the long value pointed to by BlocksDone to let the caller
; know how many blocks have been transferred over. The calling routine can
; periodically check this value to see if transmission has been completed. This
; routine allows the calling application to begin processing another batch of data
; as the current batch is being transferred to the DSP. As the routine's name implies
; this call should be used instead of DSP_DoBlock when a continuous stream of data
; is to be transmitted into the DSP. If on the other hand, a single large chunk of
; data needs to be transferred, it may be more efficient to use DSP_DoBlock instead.
;
; Parameters : LONG : Address of a LONG : BlocksDone
;              LONG : NumBlocks
;              LONG : BlocksSize
;              LONG : Address of a Buffer -> DataIn  (RAW array)
; Return     : None
; Stack      : 18
;
; - XBIOS $64/100 DSP_OUTSTREAM -
; DSP_OutStream will fill the Buffer pointed to by DataOut via a DSP interrupt Handler.
; The call is similar to DSP_InStream above except that datais transferred from the
; DSP to the Buffer at each Interrupt. Again, BlockSize number of DSP Words are
; transferred at each interrupt until NumBlocks number of blocks has been
; transferred over. At that time, BlocksDone will be equal to NumBlocks informing
; the calling process that transmission has stopped.
;
; Parameters : LONG : Address of a LONG : BlocksDone
;              LONG : NumBlocks
;              LONG : BlocksSize
;              LONG : Address of a Buffer -> DataIn  (RAW array)
; Return     : None
; Stack      : 18
;
; - XBIOS $65/101 DSP_IOSTREAM -
; DSP_IOStream is a specialized form of the previously documented stream handlers.
; This routine makes the important assumption that every time a block of data is
; ready to be transferred from the DSP to the Host, the DSP will at the same time
; be ready to accept as input another block of data (IT'S a bug, because if you
; fast the CPU, it could be faster than the DSP, and the DSP could be unready).
; By handling both the input to and output fromthe DSP in one interrupt handler,
; the application can save the overhead of servicing a second interrupt. When
; DSP_IOStream is first called, it "primes the pump" by sending the first block
; of data to the DSP. It then installs an interrupt handler to service "output
; is ready" interrupt from the DSP. From that point on, each time an interrupt
; occurs, the handler will fetch the block of data from the DSP and also send a
; new block of data to the DSP. The variables which are passed into the function
; are used in a manner similar to the other stream processing functions. DataIn
; and DataOut represent the input and output Buffers. BlockInSize and BlockOutSize
; represent the size of blocks in DSP Words to pass into and receive from the DSP.
; NumBlocks is the number of blocks to transfer and BlocksDone points to the value
; which keeps track of the number of blocks which have been transferred.
;
; Parameters : LONG : Address of a LONG : BlocksDone
;              LONG : NumBlocks
;              LONG : BlocksOutSize
;              LONG : BlocksInSize
;              LONG : Address of a Buffer -> DataOut (RAW array)
;              LONG : Address of a Buffer -> DataIn  (RAW array)
; Return     : None
; Stack      : 26
;
; - XBIOS $66/102 DSP_REMOVEINTERRUPTS -
; DSP_RemoveInterrupts will stop the DSP from generating ready to receive or ready
; to send interrupts to the Host. Mask is an 8 Bit mask which represent the interrupt
; to turn off.
; 1 = No more interrupts when the DSP has dataready for the Host.
; 2 = Don't generate interrupts when the DSP is ready to receive data from the Host.
; 3 = Remove both types of interrupts.
; This call should be made if one of the previously described stream calls are
; made and a less than expected amount of data is passed to or from the DSP thereby
; not allowing the interrupt routine to terminate.
;
; Parameters : WORD : Mask
; Return     : None
; Stack      : 4
;
; - XBIOS $67/103 DSP_GETWORDSIZE -
; DSP_GetWordSize returns the number of bytes which represents a DSP Word in the current
; system. It is important for the application to use this routine to determine values
; such as Buffer size and Block size. Buffer sizes for all of the data transfer routines
; should be modulo the size returned by this function. The value returned by this
; routine may change in future versions of hardware.
;
; Parameters : None
; Return     : D0.w = Size in byte of a DSP Word
; Stack      : 2
;
; - XBIOS $68/104 DSP_LOCK -
; DSP_Lock should be called before making any other calls to the DSP Library. The call
; is intented to provide a way for Host Apllications to tell whether or not the DSP
; is currently in use. A value of -1 returned by this function informs the calling
; application that a call to DSP_Lock has already been made by another process.
; A returned value of 0 means that the DSP is available and that you are free to
; make other DSP calls. The DSP will stay locked until a call to DSP_Unlock is made.
;
; Parameters : None
; Return     : D0.w = DSP State
;                      0 : OK, DSP free
;                     -1 : Already locked by Another Application
; Stack      : 2
;
; - XBIOS $69/105 DSP_UNLOCK -
; DSP_UnLock should be used in conjunction with the DSP_Lock call described above.
; A call to this routine tells the system that you are through with the DSP and
; that it is safe to allow someone else to begin using it.
;
; Parameters : None
; Return     : None
; Stack      : 2
;
; - XBIOS $6A/106 DSP_AVAILABLE -
; DSP_Available returns to the calling process the amount of memory which is
; available to use in the DSP (see previous discussion on DSP Memory Map).
; Upon return from this call, the longword pointed to by XAvailable will contain
; the amount of free X Memory space left in the DSP and YAvailable will contain
; the same for Y Memory space. Free memory for both X and Y will always begin
; at physical location 0. Remember that since Program space overlays both X and
; Y space, the low 64 words of Y memory are used for interrupt vectors.
;
; Parameters : LONG : Address of a LONG YAvailable
;              LONG : Address of a LONG XAvailable
; Return     : In the LONGs previously used, the amount of free X Memory
;              and Y Memory free, from $0000 (in DSP WORD).
; Stack      : 10
;
; - XBIOS $6B/107 DSP_RESERVE -
; DSP_Reserve sets aside DSP Memory for a DSP Program. The amount of requested
; memory should not exceed the amount given by the DSP_Available call. This
; function must be called to insure that your DSP Process is not overwritten
; by a DSP Subroutine which may be installed in the same area. The memory area
; which is set aside will be preserved until another DSP_Reserve call is made.
; This will allow other processes to use the DSP Program residing in this
; reserved space. XReserve is the amount of X Memory space that is requested
; and YReserve represents the same thing in Y Memory space. A 0 return value
; indicates that the memory was succefully reserved. A -1 indicates an error in
; reserving the requested memory.
;
; Parameters : LONG : YReserve in DSP WORD
;              LONG : XReserve in DSP WORD
; Return     : D0.w = Status
;                      0 : OK, well done, DSP Program is running
;                     -1 : An error occured
; Stack      : 10
;
; - XBIOS $6C/108 DSP_LOADPROG -
; DSP_LoadProg will load from disk a program to be executed in the DSP. The
; program must be in Ascii ".LOD" Format and cannot exceed the amount of space
; reserved by the DSP_Reserve command. File should point to the name of the
; program file to be loaded into the DSP. Ability represents the 16 Bits code
; which describes the functionality of the given program. The DSP program
; cannot contain initialized X and Y Internal RAM Space. The loader will
; handle initialized P Space as well as initialized external X and Y.
; A 0 return value indicates a succeful launch. A return value of -1
; indicates an error occurred before the file could be executed.
;
; Parameters : LONG : Address of a Buffer where will be put the P56 Program
;                     Must be large enough !! (see XBIOS 111 - DSP_LODTOBINARY)
;              WORD : DSP Ability
;              LONG : Address of the LOD Path & Name
; Return     : D0.w = Status
;                      0 : OK, well done, DSP Program is running
;                     -1 : An error occured
; Stack      : 12
;
; - XBIOS $6D/109 DSP_EXECPROG -
; DSP_ExecProg executes a DSP Program which resides in Binary ".P56" Format
; in the CPU memory. This function is much faster than DSP_LoadProg since it
; doesn't need to read the file into memory and convert it from Ascii ".LOD"
; to Binary ".P56" Format. CodePtr should point to a block of binary DSP Code.
; CodeSize number of DSP Words will be transferred from this location and
; downloaded into the DSP. The Ability parameters specifies the programs
; functional ability. CodeSize should not exceed the amount of memory reserved
; by the DSP_Reserve call.
;
; Parameters : WORD : DSP Ability
;              LONG : Number of DSP Word to load into the DSP Memory
;                     Usualy : #(DSPCodeEnd-DSPCodeStart)/WordSize
;                              WordSize is 3 in the case of the 56K
;              LONG : Address of the start of the DSP Program
;                     Usualy : DSPCodeStart
; Return     : None
; Stack      : 12
;
; - XBIOS $6E/110 DSP_EXECBOOT -
; DSP_ExecBoot will download into the 512 words of internal DSP Memory a BootStrap
; Program. A Reset will be performed on the DSP before the program is loaded.
; This program can either run as a program or be used to load a larger DSP Program.
; Note that this call currently exists for developmental test purposes only. Only
; debuggers or similar programs wanting to take over the entire DSP System
; should use this call. Applications should use DSP_LoadProg and DSP_ExecProg
; instead. CodePtr should point to a block of binary DSP Code. CodeSize number of
; DSP words will be transferred from this location and downloaded into the DSP
; (See function DSP_GetWordSize for a description of a DSP word). Only the first
; 512 DSP Words of Code will be downloaded.
;
; Parameters : WORD : DSP Ability
;              LONG : Number of DSP Word to load into the DSP Memory
;                     Usualy : (DSPBootEnd-DSPBootStart)/3
;                     WARNING : Should be less than 512
;              LONG : Address of the start of the DSP Program
; Return     : None
; Stack      : 12
;
; - XBIOS $6F/111 DSP_LODTOBINARY -
; DSP_LodToBinary reads in the ".LOD" file whose name is given in the variable
; file. The function will then convert the file into binary form ready to sent
; to the DSP_ExecBoot or the DSP_ExecProg function. CodePtr should point to a
; block of memory which is large enough (!!!) for the routine to place the
; binary code data. The function will return the size of the program in DSP
; words. A negative size means that an error occured during the conversion
; process.
;
; Parameters : LONG : Address of a Buffer where will be put the P56 Program
;                     Must be large enough !!
;              LONG : Address of the LOD Path & Name
; Return     : D0.w = Size in DSP WORD of the P56 Program
;                     -1 : An error occured...
; Stack      : 10
;
; - XBIOS $70/112 DSP_TRIGGERHC -
; DSP_TriggerHC will cause a host command which is set aside for DSP programs to
; be executed. Only two HC vectors are available to use by DSP programs.
; Vector $13 ans $14. All other Host vectors are used by the system and by DSP
; subroutines. Note that when a program is loaded for execution, the vector table
; is overlayed with the system's vector table. All other vectors except $13 and $14
; will be overwritten by the system.
;
; Parameters : WORD : Host Vector (only Vector 19 & 20 are available)
; Return     : None
; Stack      : 4
;
; - XBIOS $71/113 DSP_REQUESTUNIQUEABILITY -
; DSP_RequestUniqueAbility provides a way for host processes to uniquely identify
; their own DSP process which does not fall under a known ability definition.
; Upon return, the system will pass back an ability identifier which is unique
; to the current system session. Using this value in calls such as DSP_InqSubrAbility
; will allow the host process to check to see if your code is still resident in
; the DSP making it unnecessary to load it back again.
;
; Parameters : None
; Return     : D0.w = Ability
; Stack      : 2
;
; - XBIOS $72/114 DSP_GETPROGABILITY -
; DSP_GetProgAbility will return to the callin process the ability of the program
; currently residing in the DSP. This ability value can then be used to determine
; if another DSP program needs to be downloaded into the DSP or if the current
; DSP program will do the requied job.
;
; Parameters : None
; Return     : D0.w = Ability
; Stack      : 2
;
; - XBIOS $73/115 DSP_FLUSHSUBROUTINES -
; DSP_FlushSubroutines can be called if the host process needs more DSP memory
; than what is returned by DSP_Available. When this call is made, all DSP
; subroutines currently residing in the DSP will be removed and the memory will
; be returned back to the pool of usable program memory. DSP_Available may then
; be called again to find out how much memory was returned to the system.
; Programs should make an effort to get by with the memory left in the system
; without making this call whenever possible. Overall system performance can be
; greatly enhanced if frequently called DSP code can be left in the DSP instead
; of having to repeatedly download them.
;
; Parameters : None
; Return     : None
; Stack      : 2
;
; - XBIOS $74/116 DSP_LOADSUBROUTINE -
; DSP_LoadSubroutine will install a DSP subroutine into the system to be executed
; at a later time. Ptr must point to a block of DSP subroutine code. This code
; must meet the "DSP subroutine" requirements as explained in a earlier section
; of this document. The size of a subroutine as well as its ability are reported
; in the remaining 2 variables. DSP_LoadSubroutine will return a positive handle
; if the subroutine was installed without problems. A zero handle will be returned
; if the system was not able to install the subroutine. The subroutine will remain
; resident in the DSP until all of the subroutine slots have been filled and it is
; replaced by another subroutine. It may also be removed if a process makes a
; DSP_FlsuhSubroutine call.
;
; Parameters : WORD : DSP Ability
;              LONG : Number of DSP Word to load into the DSP Memory
;              LONG : Address of the start of the DSP Program
; Return     : D0.w = 0 if an error occured, else OK if positive
; Stack      : 12
;
; - XBIOS $75/117 DSP_INQSUBRABILITY -
; DSP_InqSubrAbility will return the handle of an installed subroutine if the
; subroutine's ability matches the ability passed into the routine. By finding
; a subroutine which already exists on the DSP (whether or not the process is
; the one that installed it) the calling process will save the time taken to
; download it to the DSP. If the system does not find a DSP subroutine whose
; ability matches the requested one, a zero handle will be returned. In that
; case it would be necessary for tyhe calling process to use the
; DSP_LoadSubroutine call to install their own subroutine.
;
; Parameters : WORD : DSP Ability
; Return     : D0.w = Ability requested
; Stack      : 4
;
; - XBIOS $76/118 DSP_RUNSUBROUTINE -
; DSP_RunSubroutine will execute a DSP resident subroutine identified by the given
; handle. Before this call can be made the subroutine must be identified through
; either a DSP_InqSubrAbility call or a DSP_LoadSubroutine call. Tha status which
; is returned from the cal lets the calling process know if the DSP subroutine was
; properly launched. A negative status report that an error occured and that the
; process was not launched. A zero return value represent a successful launch.
;
; Parameters : WORD : DSP Ability
; Return     : D0.w = 0 if all is OK, else an error occured
; Stack      : 4
;
; - XBIOS $77/119 DSP_HF0 -
; DSP_HF0 will read from or write to bit #3 of the HSR. If flag is either a zero
; or a one, the value of flag will be written into the HSR bit. If flag contains
; a $FFFF, the routine will return into HF0_Ret the value of bit #3 int he HSR
; (either 0 if cleared, 1 is set) without changing its value.
;
; Parameters : WORD : Flag
; Return     : D0.w = HF0_Ret
; Stack      : 4
;
; - XBIOS $78/120 DSP_HF1 -
; Identical to DSP_HF0 except sets/check bits for bit #4 of the HSR.
;
; Parameters : WORD : Flag
; Return     : D0.w = HF1_Ret
; Stack      : 4
;
; - XBIOS $79/121 DSP_HF2 -
; Returns the value of bit #3 in the HCR. Note that this bit can only be read by
; the host and cannot be set.
;
; Parameters : None
; Return     : D0.w = HF2_Ret
; Stack      : 2
;
; - XBIOS $7A/122 DSP_HF3 -
; Similar to DSP_HF2 except returns value of bit #4 of the HCR.
;
; Parameters : None
; Return     : D0.w = HF3_Ret
; Stack      : 2
;
; - XBIOS $7B/123 DSP_BLKWORDS -
;
;
; Parameters :
; Return     :
; Stack      :
;
; - XBIOS $7C/124 DSP_BLKBYTES -
;
;
; Parameters :
; Return     :
; Stack      :
;
; - XBIOS $7D/125 DSP_HSTAT -
;
;
; Parameters :
; Return     :
; Stack      :
;
; - XBIOS $7E/126 DSP_SETVECTORS -
;
;
; Parameters :
; Return     :
; Stack      :
;
; - XBIOS $7F/127 DSP_MULTBLOCKS -
;
;
; Parameters :
; Return     :
; Stack      :
;
;
; *****************************************************************************
; > DSP Philosophy - KOSS (c) 1999
;
; What you've to know first, is that the DSP is NOT the main processor in
; computers. It's ever used with another one, like 68HC11 or 68030 in the
; case of the ATARI Falcon030 or NexT. That is to say the DSP cannot decide itself
; for its own future. It has NO Operating System, just a BootStrap ROM.
; When you switch ON the Falcon030, the CPU boot on the Operating System
; while the DSP do nothing.
;
; - BOOT -
; CPU : Busy
; DSP : Free
;
; Then you launch a Program that will use the DSP. First, be sure that no
; other program use it already.
; If not, lock it for you to prevent other Program for DSP use (MultiTasking).
; Then load your Program into the DSP Memory.
;
; - DSP USE -
; CPU : Send program to DSP
; DSP : Receive the program and boot on it
;
; The DSP, once the program in the Memory, jump to P:$0000, where an Instruction
; is. Use there a BRA to jump at P:$0040.
; DSP code cannot use any Operating System function because there is no.
;
; Start to call the DSP by sending him orders, and waiting for the replies.
; HOST Port is the more common way to use the DSP, but it's a little bit
; slow dialing trough this little hole of 24 Bits (1Mb/s Max @32MHz). So some
; people use the DMA system. But it's quite more difficult because the DSP have to
; do some kinda D2D into the memory (you should use many more registers to
; perform this).
;
; - Calling the DSP -
; CPU : Put something on the HOST Port
; DSP : Look for something on the HOST Port
;
; - Waiting for the DSP -
; CPU : Wait a HOST Interrupt
; DSP : Put the data on the HOST Port
;
; Well, now your program have to finish. Don't try to free the DSP, it's
; impossible. The DSP program still run, waiting for you.
; Just Unlock the DSP for allowing other Program to use it
;
; - Finishing your program -
; CPU : Unlock DSP
; DSP : Look for something on the HOST Port (silly, isn't it ?)
;
; The DSP cannot access to the Main Memory (except trough the DMA system),
; so it's not able to crash your datas. Now you return to the DeskTop, but
; your DSP Program still runs. When another Program will use the DSP, it
; will just write in the DSP Memory it's own DSP Program, and then the DSP
; will boot on it, and start again to dial with the another Program
;
; You've see that it's quite easy using the DSP. Don't fear anything about it,
; it don't bite, even if it's very powerful.
;
; *****************************************************************************
; > How To Use the DSP - KOSS (c) 1999
;
;
; *****************************************************************************
; > Programming Example by AXEL F. and KOSS
;
; - The CPU Program : Exclusive, contain the whole DSP initialisation -
;
; /// DSP Initialisation, the whole method - AGOPIAN Mathias & KOSS ///
;
;  comment  HEAD=7
;
;  SECTION  TEXT
;
;  movea.l  (4,SP),A6   ; Adresse de la BASEPAGE
;  move.l   ($C,A6),D0  ; Taille du SEGMENT TEXT
;  add.l ($14,A6),D0 ; Additionne la taille du SEGMENT DATA Ö D0
;  add.l ($1C,A6),D0 ; Additionne la taille du SEGMENT BSS Ö D0
;  addi.l   #$100,D0 ; Additionne la taille de la BASEPAGE Ö D0
;  addi.l   #$400,D0 ; Additionne la taille de la future PILE (Ici, 256 positions longues (1024 OCTETS))
;  move.l   D0,D1 ; Copie D0 dans D1 (Taille Ö rÇserver)
;  move.l   D0,D7
;  add.l A6,D1 ; Additionne l'adresse du dÇbut du programme avec D1 (La taille Ö rÇserver)
;  andi.l   #-2,D1   ; Rend D1 pair (Au cas oó il ne l'Çtait pas)
;  subq.l   #8,D1 ; Garde de la place pour l'adresse de la BASEPAGE
;  move.l   (4,SP),D2   ; Sauvegarde l'adresse de la BASEPAGE
;  movea.l  D1,SP ; Installe l'adresse de fin du programme+place nouvelle PILE dans la PILE
;  move.l   D2,(4,SP)   ; RÇinstalle l'adresse de la BASEPAGE
;  move.l   D0,-(SP) ; EmPILE la taille Ö rÇserver
;  move.l   A6,-(SP) ; EmPILE l'adresse du programme
;  clr.w -(SP) ; RÇservÇ
;  move.w   #$4A,-(SP)  ; - M_SHRINK -
;  trap  #1 ; *** GEMDOS ***
;  lea   (12,SP),SP
;
;  ; Let reserve enough RAM to convert DSP program
;  ; from LOD Format to P56 Format
;
;DSP_Start  move.w   #3,-(SP) ; Alt RAM if possible
;  move.l   #4096,-(SP) ; Binary DSP Prog Size
;  move.w   #$44,-(SP)  ; - M_XALLOC -
;  trap  #1 ; *** GEMDOS ***
;  addq.l   #8,SP
;
;  tst.l D0
;  BEQ   DSP_Error
;
;  move.l   D0,DSP_ProgAddr
;
;  ; Now ask the DSP for an UniqueAbility
;
;  move.w   #113,-(SP)  ; - DSP_RequestUniqueAbility -
;  trap  #14   ; *** XBIOS ***
;  addq.l   #2,SP
;
;  move.w   D0,DSP_Ability
;
;  ; Is the DSP free ?
;
;  move.w   #104,-(SP)  ; - DSP_Lock -
;  trap  #14   ; *** GEMDOS ***
;  addq.l   #2,SP
;
;  tst.w D0
;  BMI   DSP_Error   ; -1 : Already used
;
;  ; Test if our DSP Prog is still in the DSP Memory
;
;  move.w   #114,-(SP)  ; - DSP_GetProgAbility -
;  trap  #14   ; *** XBIOS ***
;  addq.l   #2,SP
;
;  move.w   DSP_Ability,D1
;  cmp.w D1,D0
;  BEQ   DSP_AlReady
;
;  ; Well, the Prog in the DSP is not our one.
;  ; Let load it into the DSP Memory
;
;  ; Let's see if there is enough DSP Memory left for our
;  ; DSP Prog
;
;  pea   DSP_YMem
;  pea   DSP_XMem
;  move.w   #106,-(SP)  ; - DSP_Available -
;  trap  #14   ; *** XBIOS ***
;  lea   (10,SP),SP
;
;  move.l   DSP_YMem,D0
;  move.l   DSP_WannaYMem,D1
;  cmp.l D1,D0
;  BMI   DSP_FlushSubRoutines
;
;  move.l   DSP_XMem,D0
;  move.l   DSP_WannaXMem,D1
;  cmp.l D1,D0
;  BMI   DSP_FlushSubRoutines
;
;  BRA   DSP_EnoughMemory
;
;DSP_FlushSubRoutines   move.w   #115,-(SP)  ; - DSP_FlushSubRoutines -
;  trap  #14   ; *** XBIOS ***
;  addq.l   #2,SP
;
;DSP_EnoughMemory ; OK, now load our DSP Prog into the DSP
;  ; Two ways : - From LOD
;  ;            - From P56
;
;  move.w   #103,-(SP)  ; - DSP_GetWordSize -
;  trap  #14   ; *** XBIOS ***
;  addq.l   #2,SP
;
;  move.w   D0,DSP_WordSize
;
;DSP_FromLOD   move.l   DSP_ProgAddr,-(SP)   ; Buffer
;  move.w   DSP_Ability,-(SP)
;  pea   DSP_ProgPath
;  move.w   #108,-(SP)  ; - DSP_LoadProg -
;  trap  #14   ; *** XBIOS ***
;  lea   (12,SP),SP
;
;  tst.w D0
;  BMI   DSP_Error
;
;  BRA   DSP_Loaded
;
;DSP_FromP56   move.w   DSP_Ability,-(SP)
;  move.l   #DSP_BinaryEnd,D0
;  move.l   #DSP_BinaryStart,D1
;  sub.l D1,D0
;  clr.l D1
;  clr.l D2
;  move.w   DSP_WordSize,D2
;  add.l D2,D0 ; Avoid Side Error
;  divu.l   D1:D0,D2
;  move.l   D0,-(SP) ; CodeSize
;  pea   DSP_BinaryStart
;  move.w   #109,-(SP)  ; - DSP_ExecProg -
;  trap  #14   ; *** XBIOS ***
;  lea   (12,SP),SP
;
;DSP_Loaded move.l   DSP_WannaYMem,-(SP)
;  move.l   DSP_WannaXMem,-(SP)
;  move.w   #107,-(SP)  ; - DSP_Reserve -
;  trap  #14   ; *** GEMDOS ***
;  lea   (10,SP),SP
;
;  tst.w D0
;  BMI   DSP_Error
;
;DSP_AlReady   pea   DSP_SendWait   ; Dial Routine
;  move.w   #$26,-(SP)  ; - SUPEXEC -
;  trap  #14   ; *** XBIOS ***
;  addq.l   #6,SP
;
;  ; Now free the DSP for another application
;
;
;  move.w   #105,-(SP)  ; - DSP_UnLock -
;  trap  #14   ; *** GEMDOS ***
;  addq.l   #2,SP
;
;  BRA   DSP_End
;
;DSP_Error  pea   DSP_UsedText
;  move.w   #9,-(SP) ; - C_CONWS -
;  trap  #1 ; *** GEMDOS ***
;  addq.l   #6,SP
;
;  move.w   #7,-(SP) ; - C_RAWCIN -
;  trap  #1 ; *** GEMDOS ***
;  addq.l   #2,SP
;
;DSP_End move.l   DSP_ProgAddr,-(SP)
;  move.w   #$49,-(SP)  ; - M_FREE -
;  trap  #1 ; *** GEMDOS ***
;  addq.l   #6,SP
;
;  move.w   D0,-(SP)
;  move.w   #$4C,-(SP)  ; - P_TERM -
;  trap  #1 ; *** GEMDOS ***
;
;  ; - The Dial Routine, Supervisor ONLY -
;
;  ; Wait for the DSP
;DSP_SendWait  btst.b   #1,$FFFFA202.w
;  BEQ   DSP_SendWait
;
;  ; Send the Data to the DSP
;
;  move.l   #87654321,$FFFFA204.w
;
;  ; Wait for the answer of the DSP
;DSP_ReceiveWait  btst.b   #0,$FFFFA202.w
;  BEQ   DSP_ReceiveData
;
;  ; Receive the Data from the DSP
;
;  move.l   $FFFFA204.w,D0
;  cmp.l #12345678,D0
;  BEQ   DSP_Ok
;
;  move.w   #7,-(SP) ; Bell
;  move.w   #2,-(SP) ; - C_CONOUT -
;  trap  #1 ; *** GEMDOS ***
;  addq.l   #4,SP
;
;DSP_Ok  RTS
;
;  SECTION  DATA
;
;DSP_ProgPath  dc.b  "\MYPROG.LOD",0
;DSP_WannaXMem dc.l  32
;DSP_WannaYMem dc.l  32
;
;  SECTION  BSS
;
;DSP_Ability   ds.w  1
;DSP_WordSize  ds.w  1
;DSP_ProgAddr  ds.l  1
;DSP_ProgSize  ds.l  1
;DSP_XMem   ds.l  1
;DSP_YMem   ds.l  1
;
; - The DSP Program -
;
;  ORG   P:0   ; RESET Vector
;
;  ; DSP Start HERE, at P:$0000
;  JMP   Get_From_68030
;
;  ORG   P:$40 ; Start of On-Chip RAM
;
;  ; Wait for Peripheral Stuff coming from the CPU
;  ; Instead of using a Label for looping, just write
;  ; a Start (*) to loop on the same address
;  ; > JCLR #<0,X:<<$FFE9,*
;Get_From_68030   JCLR  #<0,X:<<$FFE9,Get_From_68030
;
;  ; Read Peripheral Stuff and store it in X0 (1 DSP WORD)
;  movep X:<<$FFEB,X0
;
;  ; Wait for the CPU
;  ; Same system like Get_From_68030
;  ; > JCLR #<1,X:<<$FFE9,*
;Send_to_68030 JCLR  #<1,X:<<$FFE9,Send_to_68030
;
;  ; Write Peripheral Stuff (1 DSP WORD MAX = 24 Bits MAX !!!)
;  movep #12345678,X:<<$FFEB
;
;  ; Wait till the End of Time
;  ; > JMP  *
;EndLoop JMP   EndLoop  ; Loop
;
; *****************************************************************************
; > Tips & Tricks - BrainStorm (c) 1993
;
; One of the most outstanding features of the Falcon030 is its  DSP  56001
; installed as standard. Well used, this processor offers some  impressive
; speed  gains  in  various  tasks  like  compression/  decompression,  3D
; calculations, video or audio  effects.  Taking  full  advantage  of  the
; 68030/56001 on the Falcon030 is often faster than a  486DX2/66.  However
; two rules have to be followed:
;
; 1) Attempt to use both processors in parallel, dividing parts of the
;    task between the 68030 and the 56001.
; 2) Write "true" DSP code in the 56001's native tongue.
;
; It is stupid to take a 68030 routine and convert it line  by  line  into
; 56001 assembly because in this case you will not take advantage  of  the
; highly parallel architecture  of  the  DSP.  We  will  not  explain  DSP
; programming theory. For that just purchase the "DSP 56001 User's  Guide"
; from Motorola. What we want to show with practical  examples,  are  some
; subtleties of the Motorola DSP 56001.  And  to  illustrate  the  correct
; method to utilitize/program the DSP to its greatest potential.
;
; Example 1: Copy a memory block
; ==============================
;
; The following assembly source copies a block of 32 bytes into memory.
;
;      move    #INBuffer,R0                                    ; source pointer
;      move    #OUTBuffer,R1                                   ; destination pointer
;
;      DO      #32,EndLoop                                     ; loop 32 times
;      move    X:(R0)+,A                                       ; read a word
;      move    A,X:(R1)+                                       ; write a word
; EndLoop
;
; This program is fast but does not take advantage of the DSP. Now, we
; will try to change the destination register R1 to R4, as well as the
; type of RAM used (remember the DSP uses two RAMs: X and Y).
;
; [ Editor's Note:
;
;   A basic block diagram of the Motorola 56001 DSP ---|
;                                                      |
;   |------------|                                     |
;   | [A][B][C]  |  <----------------------------------|
;   |------------|
;
; ========================================================================
; ;
;   |--------------------------|
;   | program memory           |
;   | program controller       |  <------ contents of [A]
;   | Address Generation Unit  |
;   |--------------------------|
;
;   |--------------------------|
;   | X memory                 |
;   | Y memory                 |  <------ contents of [B]
;   | MAC (Multiply/Accumulate)|
;   |--------------------------|
;
;   |--------------------------|
;   |                          |
;   | input/output             |  <------ contents of [C]
;   |                          |
;   |--------------------------|
;
; ======================================================================= ]
;
; The previous routine can be rewritten like this:
;
;      move    #INBuffer,R0                                    ; source
;      move    #OUTBuffer,R4                                   ; destination
;      move    X:(R0)+,A                                       ; read 1 word
;      REP     #31                                             ; repeat 31 times
;      move    X:(R0)+,A       A,Y:(R4)+                       ; write a word and read next one
;      move    A,Y:(R4)+                                       ; write last word
;
; With this little optimization the speed has been increased by a factor
; of three! This optimization uses instructions in parallel that allows
; one to read AND write at the same time!
;
; NOTE:
;
; To be executed in parallel, two memory moves have to be done in
; different memories and use registers from two different banks. The
; DSP56001 uses two banks of registers:
;
; Bank number 1 includes: R0, R1, R2, R3
; Bank number 2 includes: R4, R5, R6, R7
;
; [ Editor's Note: These registers are located in Address Generation
;                  Unit ]
;
; For example: In one instruction, it is possible to read from RAM X and
; write to RAM Y. But you cannot read from RAM Y and write into RAM Y.
; In the same way, you can associate the same instruction registers R2
; and R7, but not R1 and R3.
;
; Example 2: Invert a memory bloc
; ===============================
;
; In this sample we will try to invert 32 DSP words, using the NEG
; operation. The easiest way to do that is in the example below:
;
;      move    #INBuffer,R0                                    ; ptr source
;      move    #OUTBuffer,R1                                   ; ptr destination
;
;      DO      #$20,EndLoop                                    ; 32 loops
;      move    X:(R0)+,A                                       ; read a word
;      neg     A                                               ; invert it
;      move    A,Y:(R1)+                                       ; write the inverted word
; EndLoop
;
; Here again, the algorithm choice is not the best one for the  DSP.  Each
; loop includes 1 read from memory, 1 arithmetic operation, and 1 write of
; the data. ON THE DSP, ALL THIS CAN BE DONE IN ONE INSTRUCTION!!  Here is
; how to achieve this goal:
;
;      move    #INBuffer,R0                                    ; ptr source
;      move    #OUTBuffer,R4                                   ; ptr destination
;      move    X:(R0)+,A                                       ; read a word
;      neg     A               X:(R0)+,B                       ; invert it, and read the next one.
;
;      DO      #16,EndLoop                                     ; repeat 16 times
;      neg     B               X:(R0)+,A       A,Y:(R4)+       ; invert current word(b), read next one(a),  write previous one
;      neg     A               X:(R0)+,B       B,Y:(R4)+       ; invert current word (a), read next one (b), write previous one
; EndLoop
;
; This new routine does the job  in  one  instruction  instead  of  three.
; Because we are dealing with two words at the same  time.  While  one  is
; inverted, the previous one is written down and the next one is read from
; memory.
;
; As you can see, even with simple operations,  the  DSP  can  provide  an
; incredible increase in speed.
;
; For the next step we will try to  avoid  the  "MOVE"  instruction  as  a
; memory move can  (most  of  the  time)  be  done  in  parallel  with  an
; arithmetic instruction.
;
; Example 3: Memory shift
; =======================
;
; On the DSP, instructions ASL and ASR shift  the  specified  register  of
; only one bit (68030 can shift multiple bits).  However  one  can  easily
; avoid this problem. One has to remember what a shift [left] is... it  is
; just a multiplication by a power of 2.
;
; The following routine will shift a register 4 times:
;
;      move    #INBuffer,R0                                    ; ptr source
;      move    #OUTBuffer,R1                                   ; ptr destination
;
;      DO      #32,EndLoop                                     ; loop 32 times
;      move    X:(R0)+,A                                       ; read 1 word
;      rep     #4                                              ; shift 4 times to the right
;      asr     A
;      move    A,Y:(R1)+                                       ; write the shifted word
; EndLoop
;
; It takes 7 instructions, which is definitely quite a bit for a small
; DSP job. We can do much better using multiply instructions as detailed
; below.
;
;      move    #INBuffer,R0                                    ; ptr source
;      move    #OUTBuffer,R1                                   ; ptr destination
;      move    #$80000,Y0                                      ; multiplier
;
;      DO      #32,EndLoop                                     ; loop 32 times
;      move    X:(R0)+,X0                                      ; read 1 word
;      mpy     X0,Y0,A                                         ; right shift of 4 bits
;      move    A,Y:(R1)+                                       ; write shifted word
; EndLoop
;
; This routine only uses 3 instructions. This is much better!  But one
; can do exactly the same job in ONE instruction in the same manner as
; example 2.
;
;      move    #INBuffer,R0                                    ; source
;      move    #OUTBuffer,R4                                   ; destination
;      move    #$80000,Y0                                      ; multiplier
;      move    X:(R0)+,X0                                      ; read 1 word
;      mpy     X0,Y0,B         X:(R0)+,X0                      ; shift it and read the next one
;      REP     #31                                             ; repeat 31 times the next instruction
;      mpy     X0,Y0,B         X:(R0)+,X0      B,Y:(R4)+       ; shift the current word, read the next one, write the previous one
;      move    B,Y:(R4)+                                       ; write last word
;
; Isn't this easy?
;
; The art of DSP  programming  is  based  on  the  clever  choice  of  the
; registers  and  the  combination  of  memory  accesses  with  arithmetic
; operations. The DSP can replace the 68030 for many calculations  with  a
; speed gain of over 10 times. And do not forget that on the  Falcon,  the
; DSP clock is twice the clock of the 68030! That is 32Mhz for  the  56001
; DSP versus 16mhz for the 68030 cpu.
;