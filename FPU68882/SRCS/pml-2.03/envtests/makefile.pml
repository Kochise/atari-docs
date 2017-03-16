#  USAGE
#	make m=value s=true 
#		where m=value is either
#		    m=m68020 (implies 68881 support)
#			to support systems with an 68020/68030+68881/68882
#		or
#		    m=sfp004
#			to support 68000 based systems with a memory mapped
#			68881
#
#		default (m omitted)
#		    for systems without coprocessor, 32 bit
#
#		s=true
#		    sets -mshort (16 bit int)
#
.SUFFIXES:
.SUFFIXES: .c .o

#CC = c:\gcc.140\exec\cc.ttp
#LD = c:\gcc.140\exec\ld.ttp -M c:\gcc.140\lib\crt0.o 

CFLAGS  := -c -O
#OUTLIB := -lpml.olb -lgnu.olb -nostdlib
OUTLIB := -lgnu.olb #-nostdlib

ifneq (,$(findstring true,$(s)))
 CFLAGS	:= $(CFLAGS) $(addprefix  ,-mshort)
 OUTLIB	:= $(subst .olb,16.olb, $(OUTLIB))
endif

ifneq (,$(findstring 881,$(m)))
 CFLAGS	:= $(CFLAGS) $(addprefix  ,-m68020 -m68881)
 OUTLIB	:= $(subst .olb,020.olb, $(OUTLIB))
endif

ifneq (,$(findstring sfp004,$(m)))
 CFLAGS	:= $(CFLAGS) $(addprefix  ,-Dsfp004)
 OUTLIB	:= $(subst .olb,sfp.olb, $(OUTLIB))
endif

all : testfrexp.ttp testldexp.ttp  testmodf.ttp

%.ttp : %.o
	$(LD) $< $(OUTLIB) -o $@
#	toglclr  $@
