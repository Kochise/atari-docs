

                    ####   #####  ###  ## #####   ######
                   ##     ##   ##  ##  ##  ## ###  ## ###
                  ##      ##   ##  ## ##   ##  ##  ##  ##
                  ######   #####   ####    ##  ##  ##### 
                  ##   ## ##   ##  ####    ##  ##  ##  ##
                  ##   ## ##   ##  ## ##   ## ###  ## ###
                   #####   #####  ###  ## #####   ###### 

                              [ 68kdb Readme ]
                             Bart Trzynadlowski


This is the documentation for 68kdb Version 0.6, please read it. 68kdb is
public domain software. The disassembler was originally written by Aaron
Giles.

68kdb is a debugger package for use with the Turbo68K 680X0 emulation library.
It should be fairly portable, and has been tested successfully on DOS and UNIX
systems. It can be used both as a standalone 68000/68010 cross-debugger or it
can be included in your own software.

Contact Bart Trzynadlowski:
    Email: trzy@mailandnews.com
    WWW:   http://trzy.overclocked.org
           http://trzy.overclocked.org/turbo68k


------------------------
  0. Table of Contents
------------------------

    0. Table of Contents
    1. Compiling and Configuring
    2. The 68kdb Standalone Debugger
    3. Debug680X0()
    4. Using the Debugger
        4.1 Commands
        4.2 The Watch Facility
    5. Change History
    6. Special Thanks


--------------------------------
  1. Compiling and Configuring
--------------------------------

68kdb comes in the form of 3 source files: 68KDB.C, DEBUG.C, and DEBUG.H. It
assumes that TURBO68K.H is present in the same directory (if this is not the
case, edit DEBUG.H.)

To compile it, any 32-bit C compiler should do. For the standalone 68kdb
debugger, compile 68KDB.C and DEBUG.C -- make sure to link in Turbo68K (this
should have been built with the -defmap, -addr 24, and -multiaddr options.)

If you intend to use the debugger as part of another program, just compile
DEBUG.C and link it in with your program. As with the standalone debugger,
Turbo68K must be linked in (you don't have to use -defmap, -addr 24, or
-multiaddr here -- any configuration will work!)

Make sure that the Turbo68K header file (usually turbo68k.h) is being included
properly in DEBUG.H. Change the appropriate line to comply with your set up.

By default, the debugger assumes you are linking in a 68000-configured
Turbo68K. You can change this with the DEBUG_TYPE definition in DEBUG.H.
Regardless of whether 68000 or 68010 mode is selected, the disassembler still
recognizes 68010 instructions. The DEBUG_TYPE definition is needed for 68kdb
to reference the proper context (turbo68kcontext_68000 or
turbo68kcontext_68010.)

For DOS kbhit() support (in order to be able to terminate the "b" command with
a key stroke), #define DEBUG_CONIO in DEBUG.H.


------------------------------------
  2. The 68kdb Standalone Debugger
------------------------------------

The standalone debugger can be used to debug simple 680X0 binaries in flat
binary form. The vector table must be located at the beginning of these files.
In essence, they should be flat binary images of a 680X0 memory map.

By default, 68kdb will allocate enough memory to hold just the file. The rest
of the address space will be unusable. To allocate more memory, use the -a
command line option. The argument to this must be the amount of bytes to
allocate in hexadecimal. For example, to set up a 16MB address space, do:

    68kdb prog.bin -a 1000000

Once 68kdb loads up the program, it will call the debugger, Debug680X0().


-------------------
  3. Debug680X0()
-------------------

The Debug680X0() function is the debugger itself. It is defined as such:

TURBO68K_INT32 Debug680X0(void (*dbg_printf)(const char *, ...),
                          void (*dbg_fgets)(char *, int, FILE *),
                          void (*dbg_switch)(TURBO68K_INT32));

The function pointer arguments are purely optional. They determine how the
debugger manages I/O. If you specify NULL for dbg_printf, printf() will be
used. If you specify NULL for dbg_fgets, fgets will be used. You can specify
your own functions to handle input/output if stdio and stdin are not usable.

The dbg_switch function, if not set to NULL, is called on the "p" command. If
the argument to it is 0, switch to the next 680X0 processor. If it is not 0,
switch to that processor number. This is a flexible way for the program using
Debug680X0() to manage multiple processors.

Simply compile DEBUG.C into your program, include DEBUG.H, and you can then
invoke Debug680X0(). Make sure the 680X0 processors have been fully set up.


-------------------------
  4. Using the Debugger
-------------------------

This section describes how to use the debugger encapsulated in Debug680X0().


4.1 Commands

The debugger is line-oriented. Each command is separated by whitespace and
must be typed in lowercase. Numerical data should not have any identifiers
such as 0x, h, d, b, %, $, etc. This sort of information is defined by the
command you are using.

    Command:            Command Description:
    --------            --------------------
    ?                   Show help.
    b <addr>            Run the 680X0 until the specified breakpoint or until
                        a watch expression evaluates true. If DEBUG_CONIO has
                        been defined, a keystroke will terminate execution.
    d [addr] [num]      Dump [num] (base 10) lines of data (16 items each) at
                        [addr] (base 16.) The default number of lines is 16.
                        If no address is specified, the dump will be from the
                        last set address.
    e <cycles>          Execute <cycles> number of cycles (base 10.) Watch
                        expressions are ignored.
    i <level> [vector]  Generate an interrupt at level <level> with the vector
                        <vector>, if no vector is specified, auto-vector is
                        assumed.
    j <addr>            Jumps to the specified address (base 16.)
    l <file> [addr]     Loads the specified file at the path <file> to the
                        address [addr] (base 16.) If no address is specified,
                        0 is assumed. Useful for loading up code to execute.
    m <addr> [b/w/l]    Accesses the address space. Use b for byte, w for 
      [data]            word, or l for long word. If [data] (base 16) is
                        present, it will be written to the specified address.
                        Otherwise, the contents of the address are only shown.
    q                   Quit the debugger.
    r [reg] [data]      Shows the 68K registers and state as well as the next
                        instruction to be executed. If a register is specified
                        ([reg]) then only it will be shown. Data ([data]) can
                        also be written to a specified register (base 16.)
    reset               Resets the 680X0.
    s                   Skips over the next instruction.
    t                   Trace: executes one instruction. Watch expressions are
                        processed.
    u [addr] [num]      Unassemble: Disassembles [num] (base 10) instructions
                        from [addr] (base 16.) The default number of instruct-
                        ions is 16 and the default address is what was last
                        set.
    w [+/-] [expr/num]  Manage watch expressions. Using w alone will display
                        all active watches. Using the + option will add a
                        watch expression (up to 16 are allowed) and - will
                        subtract the specified watch number. You can use w - *
                        to remove all watches. This is by far the most complex
                        feature of the debugger and it is described in detail
                        further into this section of the documentation.


4.2 The Watch Facility

Watches are special conditions which the user is notified of if they become
true. Certain execution functions (breakpoint, trace) will process watches to
see if they evaluate true as code is being executed by the 680X0.

Watches are managed with the "w" command. The syntax for the command is as
follows:

        w [+/-] [expr/num]

The "+/-" specifies whether you are adding or removing a watch. If you are
adding a watch, specify the expression as the next argument. If you are
removing a watch, specify its number (or "*" to remove all.) Without any
arguments at all, the "w" command prints a list of active watches.

The watch expression language is a very simple one where an expression must
consist of 3 parts:

    primary:condition:secondary

No whitespace is allowed, the colons (":") are the separators between the
parts (thus, no colons must ever be present in any of the 3 parts.)

The secondary is what is being compared against the primary. It may be a
register, memory location, or immediate hexadecimal number. The primary can be
any of those things as well. The condition is the condition to test for.

Below are tables of elements you can use:

    Primary/Secondary:
    ------------------
    rld0-rld7   D0-D7 (long word)
    rla0-rla7   A0-A7 (long word)
    rlpc        PC (long word)
    rlvbr       VBR (long word, 68010 only)
    rwsr        SR (word)
    rbccr       CCR (byte)
    rbsfc       SFC (byte, lowest 3 bits, 68010 only)
    rbdfc       DFC (byte, lowest 3 bits, 68010 only)
    rwd0-rwd7   D0-D7 (word)
    rwa0-rwa7   A0-A7 (word)
    rwpc        PC (word)
    rbsr        SR (byte)
    rbd0-rbd7   D0-D7 (byte)
    rba0-rba7   A0-A7 (byte)
    rbpc        PC (byte)
    @la0-@la7   Long word at address in A0-A7
    @lpc        Long word at address in PC
    @lvbr       Long word at address in VBR (68010 only)
    @wa0-@wa7   Word at address in A0-A7
    @wpc        Word at address in PC
    @wvbr       Word at address in VBR (68010 only)
    @ba0-@ba7   Byte at address in A0-A7
    @bpc        Byte at address in PC
    @bvbr       Byte at address in VBR (68010 only)
    @#<addr>    Byte at immediate address
    #<data>     Immediate base 16 data

    Condition:
    ----------
    =   Equal
    >   Greater than
    <   Less than
    >=  Greater than or equal
    <=  Less than or equal
    !=  Not equal
    1   Always true
    0   Always false

When data of different sizes is compared, the smaller data is zero-extended to
the size of the larger data item. All data is unsigned.


---------------------
  5. Change History
---------------------

January 19, 2002: Version 0.6
    - Updated to work with Turbo68K Version 0.6

June 29, 2001: Version 0.5
    - Updated to work with Turbo68K Version 0.5
    - Corrected the usage message
    - Debugger no longer recognizes registers D8-D15 and A8-A5 -- they don't
      exist!
    - Disassembler now prints operand to RTD instruction
    - When USP is read or written, debugger no longer prints "SSP="
    - If no file is specified for the "l" command, an error is printed
    - SSP is listed above USP in the register display now
    - USP and SSP can be safely modified, and the changes will be reflected
      appropriately
    - Minor touch-ups to the source code

April 29, 2001: Version 0.3
    - Updated to work with Genital68K Version 0.3
    - Added new 68010 features
    - Fixed a watch processing bug
    - Added 68010 BKPT instruction to the disassembler
    - Added 68010 RTD instruction to the disassembler
    - Disassembler now always prints 4 hex digits for the STOP operand

December 3, 2000: Version 0.1
    - Updated 68kdb.c to work with Genital68K Version 0.1

November 23, 2000: Version 0.0
    - Initial release


---------------------
  6. Special Thanks
---------------------

A big thanks goes out to Aaron Giles for letting me use his 680X0 disassembler
in 68kdb. Also, major thanks go out to Dragorn of DALnet's #programmers for
finding a really nasty bug which interfered with the write() FreeBSD syscall.

See you next time!
