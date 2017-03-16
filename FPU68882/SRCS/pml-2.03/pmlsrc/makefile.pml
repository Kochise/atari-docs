#
#  FILE
#
#	Makefile    build and install the pml library (tos-gcc)
#	
#  USAGE
#	make m=value e=true s=true 
#		where m=value is either
#		    m=m68881
#			to support systems with an 68020/68030+68881/68882
#			(the 'TT-version' of the lib)
#
#			lib name: pml020.olb
#		or
#		    m=sfp004
#			to support 68000 based systems with a memory mapped
#			68881
#			such as the MEGA ST with Atari's sfp004 board
#			or compatibles like Weide's board
#			or (hopefully) the coprocessor of the MEGA STE
#
#			lib name: pmlsfp.olb
#
#		default (m omitted)
#		    make the pml for systems without coprocessor
#
#			lib name: pml.olb
#
#		e=true
#		    compiles with error checking code
#		    meaningful only in combination with m68020/m68881/sfp004
#
#		    lib name: not affected
#
#		s=true
#		    sets -D__MSHORT__
#
#		    lib name: pml16.olb, pml02016.olb, pmlsfp16.olb
#
#	make checks the following environment variables for the executables
#	if they are defined, the make variables CC,.. need not be defined any more
#
#		CC=c:\gcc.140\exec\cc.ttp
#		LD=c:\gcc.140\exec\cc.ttp
#		AR=c:\gcc.140\exec\ar.ttp
#		AS=c:\gcc.140\exec\as.ttp
#		CC1=c:\gcc.140\exec\cc1.ttp
#		CPP=c:\gcc.140\exec\cpp.ttp
#		PATH=c:\bin,c:\gcc.140\exec,c:\gcc.140\util,d:\,e:\tex,k:\konvekt
#
#	M.Ritzert, ritzert@dfg.dbp.de
#	4.Januar 1992
#	
#  SYNOPSIS
#
#	make funcs	make version of library in local directory
#	make install	install the library (must be root)
#
#  WARNING
#
#	The order of the modules listed in the "LEVEL<n>" macros
#	is significant since these are the orders in which
#	they will be loaded into the library archive.  Although
#	some machines support randomly ordered libraries, ordering
#	them correctly doesn't hurt...

.SUFFIXES:
.SUFFIXES: .c .s .o .h .cpp


DEFINE	:= -DIEEE -Datarist 
OPT	:= -O2
OFLAGS	:= -fomit-frame-pointer -fstrength-reduce 
OUTLIB	:= pml.olb

CFLAGS	:= $(OPT) $(OFLAGS) $(XFLAGS) $(DEFINE) -I.
PFLAGS	:= $(DEFINE)

# check the command line arguments
#
# the check for 16 bit ints must be performed first to ensure correct 
# library names to be built

define run-ar
 $(AR) rs $(OUTLIB) $(OBJ)
endef

define	compile_and_touch
	$(CC) $(CFLAGS) -c  $<
endef

ifneq (,$(findstring true,$(asm)))
CFLAGS	:= $(CFLAGS) $(addprefix  ,-S)
define	compile_and_touch
	$(CC) $(CFLAGS) -c  $<
	touch $@
endef
define run-ar
endef
endif

ifneq (,$(findstring true,$(s)))
 CFLAGS	:= $(CFLAGS) $(addprefix  , -mshort)
 PFLAGS	:= $(PFLAGS) $(addprefix  ,-D__MSHORT__)
 OUTLIB	:= $(subst .olb,16.olb, $(OUTLIB))
endif

ifneq (,$(findstring 881,$(m)))
 CFLAGS	:= $(CFLAGS) $(addprefix  ,-m68020 -m68881 -DNO_INLINE_MATH)
 OUTLIB	:= $(subst .olb,020.olb, $(OUTLIB))
endif

ifneq (,$(findstring sfp004,$(m)))
 CFLAGS	:= $(CFLAGS) $(addprefix  ,-Dsfp004)
 OUTLIB	:= $(subst .olb,sfp.olb, $(OUTLIB))
endif

LEVEL0	:=	cerr.o

LEVEL0a	:=	matherr.o ident.o

LEVEL1	:=	sign.o mod.o poly.o dabs.o sqrt.o rint.o

LEVEL2	:=	acos.o acosh.o asin.o asinh.o atan2.o atan.o \
		log10.o tan.o \
		tanh.o sinh.o cosh.o atanh.o \
		log.o sin.o cos.o exp.o floor.o pow.o max.o min.o

LEVEL3	:=	casin.o cacos.o cmult.o catan.o ccosh.o clog.o \
		crcp.o csinh.o csqrt.o ctan.o ctanh.o cexp.o \
		ccos.o csin.o cdiv.o csubt.o cabs.o

LEVEL4	:=	cadd.o


OBJ	:=	$(LEVEL4) $(LEVEL3) $(LEVEL2) $(LEVEL1) $(LEVEL0a)

ifneq (,$(findstring true,$(e)))
CFLAGS	:= $(CFLAGS) $(addprefix  ,-DERROR_CHECK)
OBJ	:= $(OBJ) $(addprefix  , $(LEVEL0))
endif


#
#	The default thing to make.
#

default:	$(OUTLIB)
		$(run-ar)

$(OUTLIB) :	$(OBJ)

$(LEVEL0) :	pml.h
$(LEVEL0a) :	pml.h
$(LEVEL1) :	pml.h
$(LEVEL2) :	pml.h
$(LEVEL3) :	pml.h
$(LEVEL4) :	pml.h

#
#	Clean up the directory.
#

clean:
	rm -f *.o *.BAK *.tmp *.bak nohup.out

realclean: clean
	rm -f *.olb report core

%.s :: %.cpp
	$(CPP) $(PFLAGS) -P  $< $@

# mjr: needed to make .s files from .c files if asm=true
%.o :: %.c
	$(compile_and_touch)
