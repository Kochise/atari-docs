top_srcdir=..
subdir=parser

# 
# cross compiling
#
include ../GNUmakefile.common
include ../Makefile.silent

PROGRAMS = c068$(EXEEXT)

LIBS =

CPPFLAGS = -I../common -I$(INC)
CFLAGS = $(OPTS) $(WARN)

all: $(PROGRAMS)

include SRCFILES

c068$(EXEEXT): $(C068_OBJS)
	$(AM_V_LD)$(CC) ${CFLAGS} $(C068_OBJS) ${LIBS} $(LDFLAGS) -o $@

install: all
	$(CP) $(PROGRAMS) $(BIN)

check::
	$(AM_V_at)for i in $(PROGRAMS); do cmp $$i.ttp ../bin/$$i.ttp; done

dist::
	$(CP) -a $(SRCS) $(EXTRA_DIST) $(top_srcdir)/$(DISTDIR)/$(subdir)

clean:
	$(RM) *.o *.a $(PROGRAMS)
