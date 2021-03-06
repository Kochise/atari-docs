top_srcdir=..

include $(top_srcdir)/Makefile.common
include $(top_srcdir)/Makefile.silent
include optimize.mak

all: $(top_srcdir)/common/config.h bdos.a bdos.o

include $(top_srcdir)/config.mak
-include $(top_srcdir)/common/sections.mak

include SRCFILES

bdos.a: $(top_srcdir)/common/config.h $(BDOS_OBJS) ${MAKEFILE}
	$(AM_V_at)$(RM) $@
	$(AM_V_AR)$(AR) $(ARFLAGS) $@ $(BDOS_$(TOSVERSION)_OBJS1)
	$(AM_V_at)$(AR) $(ARFLAGS) $@ $(BDOS_$(TOSVERSION)_OBJS2)
	$(AM_V_at)$(AR) $(ARFLAGS) $@ $(BDOS_$(TOSVERSION)_OBJS3)

vdidsp.o: vdidsp.S $(top_srcdir)/common/config.h $(top_srcdir)/common/sections.inc
	$(AM_V_AS)${BIN}cp68${EXEEXT} ${CPPFLAGS} -P $*.S $*.i
	$(AM_V_at)${BIN}as68${EXEEXT} ${ASFLAGS} ${$*_ASFLAGS} $*.i
	$(AM_V_at)${RM} $*.i

osinit.o: osinit.S $(top_srcdir)/common/config.h
	$(AM_V_AS)${BIN}cp68${EXEEXT} ${CPPFLAGS} -P $*.S $*.i
	$(AM_V_at)${BIN}as68${EXEEXT} ${ASFLAGS} ${$*_ASFLAGS} $*.i
	$(AM_V_at)${RM} $*.i

lmul.o: lmul.S
	$(AM_V_AS)${BIN}cp68${EXEEXT} ${CPPFLAGS} -P $*.S $*.i
	$(AM_V_at)${BIN}as68${EXEEXT} ${ASFLAGS} ${$*_ASFLAGS} $*.i
	$(AM_V_at)${RM} $*.i

bdos.o: $(top_srcdir)/common/config.h tosvars.o vars.o vdidsp.o $(top_srcdir)/common/sections.mak $(BDOS_OBJS) ${MAKEFILE}
	# sections.mak might have just been generated, make sure it is reread
	$(MAKE) TOSVERSION=$(TOSVERSION) COUNTRY=$(COUNTRY) single

osmem.o: osmem.c
	$(AM_V_CC)${BIN}cp68${EXEEXT} ${CPPFLAGS} $*.c $*.i
	$(AM_V_at)${BIN}c068${EXEEXT} $*.i $*.1 $*.2 $*.3 ${CFLAGS}
	$(AM_V_at)${BIN}c168${EXEEXT} $*.1 $*.2 $*.s
	$(AM_V_at)${RUN_OPTIMIZE_${$*_OPTIMIZE}}
	$(AM_V_at)$(SUBSTLMUL)
	$(AM_V_at)$(SUBSTLDIV)
	$(AM_V_at)${BIN}as68${EXEEXT} ${ASFLAGS} ${$*_ASFLAGS} $*.s
	$(AM_V_at)${RM} $*.s $*.i $*.1 $*.2 $*.3

single:
	$(LD) -s -l -o bdos.o -a $(bdos_tbase) $(bdos_dbase) 0 tosvars.o vars.o vdidsp.o $(BDOS_OBJS)

vars.o: $(top_srcdir)/common/vars.S $(top_srcdir)/common/config.h
	$(AM_V_AS)${BIN}cp68${EXEEXT} ${CPPFLAGS} -P $< $*.i
	$(AM_V_at)${BIN}as68${EXEEXT} ${ASFLAGS} ${$*_ASFLAGS} $*.i $@
	$(AM_V_at)${RM} $*.i

tosvars.o: $(top_srcdir)/common/tosvars.S $(top_srcdir)/common/config.h
	$(AM_V_AS)${BIN}cp68${EXEEXT} ${CPPFLAGS} -P $< $*.i
	$(AM_V_at)${BIN}as68${EXEEXT} ${ASFLAGS} ${$*_ASFLAGS} $*.i $@
	$(AM_V_at)${RM} $*.i

check::

clean:
	$(RM) *.o *.a *.ndx *.i *.i *.1 *.2 *.rel *.mod $(PROGRAMS) $(top_srcdir)/common/config.h

distclean: clean
	$(RM) $(top_srcdir)/common/sections.mak
