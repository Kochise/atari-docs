.tp
.(1C
P M L    U S E R S   G U I D E
.sp 2
P o r t a b l e   M a t h   L i b r a r y
.sp 2
Version 2.0
.sp 2
\*(td
.sp 4
by
.sp
Fred Fish
.)1
.bp
.sh 1
INTRODUCTION
.(x
document topics
.)x
.sh 2
Document structure
.pp
This document describes the PML library, a
mathematical function library for C programs.
It contains the following major sections:
.(1
Introduction to the document (this section).
A module description section.
An index.
.)1
.sh 2 
Design Considerations

.pp
In writing this library many tradeoffs had to be considered.  The
primary design goal was transportability.  It was desired that
the final library be easily transportable among a wide class
of machines.  As of this release, the library has been used
with only minor modifications on
a DECSYSTEM-20 (a 36 bit machine), a VAX-11/780 under compatibility
mode, and various PDP-11's.

.pp
This portability was achieved by careful isolation of machine
dependencies and parameterization of the environment (see references).
The only assumption made is that the C compiler can generate proper code for
the four basic operations (+,-,/,*).

.pp
Even though efficiency
was considered to be of only secondary importance, the final routines
compared favorably with an informal test "race" against the
DECSYSTEM-20 FORTRAN, which has optimized assembly language
library routines.  The PML library routines seldom took
more than twice as long as the FORTRAN library, and many were
close enough to call a draw.

.pp
There are currently only four highly machine dependent routines in
the Portable Math Library.  When transporting the library to a new machine,
these should be the only ones in which recoding is necessary.
These routines, written in machine targeted C, are:

.pp
dscale --- scale a double precision floating point number by a specified
power of two.  Equivalent to multiplication or division
by a power of two, depending upon sign of the scale value.

.pp
dxexp --- extract exponent of double precision floating point number and
return it as an integer.

.pp
dxmant --- extract mantissa of double precision floating point number and
return it as a double precision floating point number.

.pp
dint --- discard fractional part of double precision number, returning
integer part as a double precision floating point
number.

.pp
The entire Portable Math Library is built upon six "primitives"
which compute their values from polynomial approximations.  All
others can be defined in terms of the primitives using various
identities.  The primitives are (1) datan, (2) dexp, (3) dln, 
(4) dsin, (5) dcos, and (6) dsqrt.  Strictly speaking, only
one of dsin and dcos could be chosen as a primitive and the
other defined with an appropriate identity.  In this implementation
however, dsin and dcos call themselves recursively, and each other,
to perform range reduction.

.sh 2
Error Handling

.pp
No assumptions are made about whether the four basic operations are done by
hardware or software.  Any overflows or underflows in the basic operations
are assumed to be handled by the environment, if at all.  Pathological
cases in the library routines are trapped internally and control
is passed to an error handler routine "pmlerr"
(which may be replaced with
one of the user's choosing) for error recovery.

.pp
The default error handler is conceptually similar to the one used by DEC for
the FORTRAN compilers.  It contains an internal table which
allows various actions to be taken for each error recognized.
Currently each error has a corresponding flag word with three
bits, each bit assigned as follows:

.pp
CONTINUE --- If the bit is set control is returned to the calling
routine after completion of error processing.  Otherwise
the task exits with an error status.

.pp
LOG --- If the log bit is set then an error warning message is
written to the standard error output channel prior to exiting
or continuing.  If reset, no message is given.

.pp
COUNT --- If the count bit is set then the task's PML
error count (internal to the error handler) is incremented.
If the total error count exceeds the maximum allowed 
then the task exits with
error status.  If the count bit is reset then the error
is ignored with respect to the error count and exit on limit.

.pp
The default conditions in the error handler for all errors
is that the CONTINUE, LOG, and COUNT bits are all set.  The
error limit is set at 10.  These values can be changed by
suitably editing the header file "pml.h"
and <pmluser.h>.

.pp
The error handler responses can also be changed dynamically
via the following routines:

.pp
PMLSFS --- Sets the specified bits in the specified error's
flag word.
For example, "pmlsfs(NEG__DSQRT,CONTINUE | LOG)" sets
the CONTINUE and LOG bits for the "double precision square root
of a negative number" error.  The COUNT bit is not affected.
The manifest constant values are defined in <pmluser.h>.

.pp
PMLCFS --- Clears the specified bits in the specified error's
flag word.
For example, "pmlcfs(NEG__DSQRT,CONTINUE | LOG)" clears
the CONTINUE and LOG bits for the "double precision square root
of a negative number" error.  The COUNT bit is not affected.
The manifest constant values are defined in <pmluser.h>.

.pp
PMLLIM --- Changes the task's PML error limit to
the specified value and returns the previous value.

.pp
PMLCNT --- Returns the current value of the PML error
count and resets it back to zero.

.sh 2
Function Names

.pp
In general, FORTRAN naming conventions were followed since no
other more obvious convention was apparent.  There is one
strong exception however, and that is the natural
logarithm functions use the generic name "ln" while the
logarithm to the base 10 functions use the name "log".
This is consistent with the normal usage in virtually all
modern mathematical and engineering texts.  How FORTRAN came
to use "log" and "log10" respectively is beyond me.
This usage has bitten many a starting FORTRAN programmer.

.sh 2
Installation

.pp
As part of the installation kit, some simple minded testing programs
are provided.  They are by no means exhaustive tests or ones that
carefully check possible trouble areas.  They are intended to
provide a quick and dirty way of verifying that no gross errors
are inadvertently incorporated in the library as a result of
improvements or bug fixes, and that the installation is successful.
Future releases may incorporate more extensive test routines
and suggestions are solicited.

.sh 2
Bugs

.pp
On the subject of bugs, all exterminators are encouraged
to notify the author of any problems or fixes so that
they can be incorporated into the next release and renegade
versions of the library can be minimized.  
Contact:
.sp 2
.nf
		Fred Fish
		1346 W 10th Place
		Tempe, Arizona 85281
.sp 1
		(602) 894-6881   (home)
		(602) 932-7000   (work @ GACA)
.fi
.sp 2
.pp
Those users with strong numerical analysis backgrounds or experience
may be able to suggest better methods for some of the library routines.
Many of the higher level routines are simple minded implementations
of identities, and may not be nearly as stable as some more obscure
methods.

.sh 2
Transporting To Other Machines

.pp
To transport the Portable Math Library to a processor other than
the PDP11 or DECSYSTEM-20, do the following:
.(1
Define the machine dependent parameters in "pml.h".
Implement the four machine dependent modules listed previously.
Compile the rest of the library modules and the testing routines.
Link and run the testing routines to verify successful installation.
Repeat as required.
.)1

.bp
.sh 1 
RUNTIME MODULES

.pp
The PML modules are documented on the following pages.
All the rest of this section was produced by the DEX (documentation
extractor) utility directly from the source files.  Thus
the information reflects the current state of the runtime
modules.
