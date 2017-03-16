#!sh

BIN="..\bin\"
LIB="..\lib\"
INC="..\include\"
EXEEXT=.ttp
CFLAGS="-f"
C1FLAGS=""
ASFLAGS="-u -L -s ${LIB}"
CPPFLAGS=""
keepasm=no
optimize=yes

f=
while test "$1" != ""; do
	case $1 in
	# flags for cp68
	-D*) CPPFLAGS="$CPPFLAGS $1" ;;
	# flags for c068
	# -w: suppress warnings
	# -t: put strings into text segment
	# -e: ieee floating point
	# -f: fast floating point
	-w|-t|-e|-f) CFLAGS="$CFLAGS $1" ;;
	# flags for c168
	# -T: generate code for 68010+
	-T) C1FLAGS="$C1FLAGS $1" ;;
	# flags for as68
	# -u: treat undefined symbols global
	# -L: address constants 32 bit
	# -a: address constants 16 bit
	# -N: no branch optimization
	# -p: produce listing
	-N|-n|-a|-l|-L|-p) ASFLAGS="$ASFLAGS $1" ;;
	# flags handled in this script only
	-S) keepasm=yes ;;
	-O0) optimize=no ;;
	-*) echo "unknown option $1" >&2; exit 1;;
	*) f=$1
	esac
	shift
done
CPPFLAGS="$CPPFLAGS -I ${INC}"

if test "$f" = ""; then
	echo "missing filename"
	exit 1
fi
f=`basename $f .c`
if test ! -f $f.c; then
	echo "$f.c: no such file"
	exit 1
fi
${BIN}cp68${EXEEXT} $CPPFLAGS $f.c $f.i
${BIN}c068${EXEEXT} $f.i $f.1 $f.2 $f.3 ${CFLAGS}
${BIN}c168${EXEEXT} $f.1 $f.2 $f.s ${C1FLAGS}
if test $optimize = yes; then
	${BIN}optimize${EXEEXT} $f.s > NUL:
	sed -e 's/move.l #$0,-(sp)/clr.l -(sp)/' $f.s > $f.1
	mv $f.1 $f.s
fi
${BIN}as68${EXEEXT} ${ASFLAGS} $f.s
rm -f $f.i $f.1 $f.2 $f.3
if test $keepasm = no; then
	rm -f $f.s
fi
