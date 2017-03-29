#	Makefile for missing library routines used by c68
#
#	Laurent Vogel

OBJ =  raise.o vfprintf.o

CC = c68 
AS = cc -c
AR = ar
LIB = /usr/lib

all : $(OBJ)

install: $(OBJ)
	ar crv $(LIB)/libc.a $(OBJ)

clean:
	rm -f $(OBJ) core

