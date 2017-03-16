#  USAGE
#	make m=value s=true 
#		where m=value is either
#		    m=m68881 or 881 
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
#		s=true
#		    sets -D__MSHORT__
#
#		    lib name: pml16.olb, pml02016.olb, pmlsfp16.olb
#
#		gdb=true
#		    compiles for gdb, also runs sym_ld
#
.SUFFIXES:
.SUFFIXES: .c .o

# please define SLD to prepare for gdb and ld for verbose linking
#
#LD  = c:\gcc.140\exec\ld.ttp -M c:\gcc.140\lib\crt0.o
SLD = c:\gcc.140\exec\sym_ld.ttp

CFLAGS :=	-DNO_DBUG -O -I../pmlsrc -DMJR

PML    := -lpml.olb
GNU    := -lgnu.olb

ifneq (,$(findstring true,$(s)))
 CFLAGS := $(CFLAGS) $(addprefix  ,-D__MSHORT__ -mshort)
 PML := $(subst .olb,16.olb, $(PML))
 GNU := $(subst .olb,16.olb, $(GNU))
endif

ifneq (,$(findstring 881,$(m)))
 CFLAGS := $(CFLAGS) $(addprefix  ,-m68020 -m68881 -D__M68881__)
 PML := $(subst .olb,020.olb, $(PML))
 GNU := $(subst .olb,020.olb, $(GNU))
endif

ifneq (,$(findstring sfp004,$(m)))
 CFLAGS := $(CFLAGS) $(addprefix  ,-Dsfp004)
 PML := $(subst .olb,sfp.olb, $(PML))
 GNU := $(subst .olb,sfp.olb, $(GNU))
endif

LOADLIBES := $(PML) $(GNU)
LDFLAGS = -s

ifneq (,$(findstring true,$(gdb)))

CFLAGS := $(CFLAGS) $(addprefix  ,-g)
define link
 $(LD) $< $(LDFLAGS) -o $@ $(LOADLIBES) 
 $(SLD) $*.sym $(GNULIB)/crt0.o $(LOADLIBES) -o $@
endef

else

define link
 $(LD) $< $(LDFLAGS) -o $@ $(LOADLIBES) 
endef
endif

all :		d2d.ttp dd2d.ttp c2d.ttp c2c.ttp cc2c.ttp


%.ttp : %.o
	$(link)
#	toglclr  $@

#$(SLD) $*.sym c:\gcc.140\lib\crt0.o $(LOADLIBES) -o $@
#
#	Clean up the directory.
#

clean:
	rm -f *.ttp *.BAK *.bak *.tmp nohup.out *.o
