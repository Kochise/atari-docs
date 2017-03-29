#	Makefile for the IEEE support modules for c68

.SUFFIXES : _x .x _o .o _h

SRC=dfadd.s dfcmp.s dfdiv.s dfltodf.s dfmul.s \
    dfneg.s dftol.s dftosf.s dftoul.s dftst.s dfutodf.s \
    sfadd.s sfcmp.s sfdiv.s sfltosf.s sfmul.s \
    sfneg.s sftodf.s sftol.s sftoul.s sftst.s sfutosf.s \
    asmul.s asdiv.s asop.s Xerror.s Xnorm4.s Xnorm8.s \
    Ysfadd.s Ysfdiv.s Ysfltosf.s Ysfmul.s Ysfinc.s \
    Ysfneg.s Ysftodf.s Ysfutosf.s \
    Yasdivsf.s Yasmulsf.s Yasopsf.s \
    Ydfadd.s Ydfdiv.s Ydfltodf.s Ydfmul.s Ydfinc.s \
    Ydfneg.s Ydftosf.s Ydfutodf.s \
    Yasdivdf.s Yasmuldf.s Yasopdf.s\
    Ylfadd.s Ylfdiv.s Ylfltodf.s Ylfmul.s Ylfinc.s \
    Ylfneg.s Ylftol.s Ylftosf.s Ylfutolf.s Ylfutolf.s \
    Yasdivlf.s Yasmullf.s Yasoplf.s\
    frexp.s ldexp.s modf.s modff.s fpcheck.s


OBJ=dfadd.o dfcmp.o dfdiv.o dfltodf.o dfmul.o \
    dfneg.o dftol.o dftosf.o dftoul.o dftst.o dfutodf.o \
    sfadd.o sfcmp.o sfdiv.o sfltosf.o sfmul.o \
    sfneg.o sftodf.o sftol.o sftoul.o sftst.o sfutosf.o \
    asmul.o asdiv.o asop.o Xerror.o Xnorm4.o Xnorm8.o \
    Ysfadd.o Ysfdiv.o Ysfmul.o Ysfneg.o Ysfinc.o \
    Yasdivsf.o Yasmulsf.o Yasopsf.o \
    Ysfltosf.o Ysfutosf.o Ysftoul.o Ysftol.o Ysftodf.o \
    Ydfadd.o Ydfdiv.o Ydfmul.o Ydfneg.o Ydfinc.o \
    Yasdivdf.o Yasmuldf.o Yasopdf.o \
    Ydfltodf.o Ydfutodf.o Ydftoul.o Ydftol.o Ydftosf.o \
    frexp.o ldexp.o modf.o modff.o fpcheck.o

#    Ysftolf.o  Ydftolf.o 
#    Ylfadd.o Ylfdiv.o Ylfmul.o Ylfneg.o Ylfinc.o \
#    Yasdivlf.o Yasmullf.o Yasoplf.o \
#    Ylfltolf.o Ylfutolf.o Ylftoul.o Ylftol.o Ylftosf.o Ylftodf.o \


AS = cc -c
CC = c68
AR = ar
LIB = /usr/lib
#LDFLAGS = -ms
#LIBS = -lm


all : ${OBJ} ieeetest #fputest

#
#   Default rules
#
.x.o:
	$(CC) $(CFLAGS) $(CPPFLAGS) $(ASFLAGS) $*_x

# .s.o :
# 	${AS} $<

install:	${OBJ}
	ar crv ${LIB}/libc.a ${OBJ}

#	The following command line MUST include the library you use
#	for printing floating point numbers.  

ieeetest :	ieeetest.c ${OBJ}
	$(CC) ${LDFLAGS} -o ieeetest ieeetest.c ${OBJ} ${LIBS}

fputest : fputest.c ${OBJ}
	$(CC) -V ${LDFLAGS} -Qmaxerr=5 -fpu=yes -o fputest fputest.c ${OBJ} ${LIBS}
#	$(CC) ${LDFLAGS} -Qmaxerr=5 -o fputest fputest.c ${OBJ} ${LIBS}

clean:
	rm -f *.o ieeetest fputest core

