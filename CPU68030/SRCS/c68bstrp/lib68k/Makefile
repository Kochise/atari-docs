#	Makefile for general support routines for c68
#
#	(Ensure correct version of alloca used for sizeof(int)
#	that the compiler is built to use).

# OBJ =   Xalloca32.o Xdivs.o Xdivu.o Xmuls.o Xmulu.o
OBJ =   Xalloca32.o Xdiv.o Xmul.o stackcheck.o stmttrace.o \
        Xbfget.o  Xbfput.o  Xbfasop.o

XOBJ = Xalloca16.o

CC = c68 
AS = cc -c
AR = ar
LIB = /usr/lib

all : $(OBJ)

install: $(OBJ)
	ar crv ${LIB}/libc.a $(OBJ)

68ktest : 68ktest.c $(OBJ)
	$(CC) -o 68ktest 68ktest.c $(OBJ)

clean:
	rm -f *.o 68ktest core

