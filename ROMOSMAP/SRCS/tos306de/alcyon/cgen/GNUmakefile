top_srcdir=..
subdir=cgen

# 
# cross compiling
#
include ../GNUmakefile.common
include ../Makefile.silent

PROGRAMS = c168$(EXEEXT)

LIBS =

CPPFLAGS = -I../common -I$(INC)
CFLAGS = $(OPTS) $(WARN)

all: $(PROGRAMS)

include SRCFILES

c168$(EXEEXT): $(C168_OBJS)
	$(AM_V_LD)$(CC) ${CFLAGS} $(C168_OBJS) ${LIBS} $(LDFLAGS) -o $@

install: all
	$(CP) $(PROGRAMS) $(BIN)

check::

dist::
	$(CP) -a $(SRCS) $(EXTRA_DIST) $(top_srcdir)/$(DISTDIR)/$(subdir)

clean:
	$(RM) *.o *.a $(PROGRAMS)
