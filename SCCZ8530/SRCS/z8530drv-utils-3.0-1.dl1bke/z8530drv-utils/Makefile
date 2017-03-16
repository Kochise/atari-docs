VERSION = 3.0-1
DIRECTORY = z8530drv-utils
KERNEL  = `cat /proc/version | cut -d" " -f3`
CCOPT   = -O2 -m486 -Wall -Wstrict-prototypes # -DCONFIG_SCC_STANDALONE

all: utils install

utils: sccparam sccstat sccinit gencfg kissbridge

sccparam: sccparam.c
	gcc ${CCOPT} sccparam.c -o $@

sccstat: sccstat.c
	gcc ${CCOPT} sccstat.c -o $@

sccinit: sccinit.c
	gcc ${CCOPT} sccinit.c -o $@

gencfg: gencfg.c
	gcc ${CCOPT} gencfg.c -o $@

kissbridge: kissbridge.c
	gcc ${CCOPT} kissbridge.c -o $@

install:
	install -g root -o root -m 0755 -s sccstat /sbin/sccstat
	install -g root -o root -m 0700 -s sccinit /sbin/sccinit
	install -g root -o root -m 0700 -s sccparam /sbin/sccparam
	install -g root -o root -m 0700 -s kissbridge /usr/sbin/kissbridge
	install -g root -o root -m 0644 z8530drv.conf /etc/z8530drv.conf.ex

clean:
	rm -f *.o *~ doc/*~

distrib:
	( cd .. && tar zcvvf z8530drv-utils-${VERSION}.tar.gz \
	z8530drv-utils/README z8530drv-utils/Makefile \
	z8530drv-utils/doc z8530drv-utils/*.c z8530drv-utils/*.h \
	z8530drv-utils/sccinit z8530drv-utils/sccparam z8530drv-utils/sccstat \
	z8530drv-utils/gencfg z8530drv-utils/kissbridge \
	z8530drv-utils/z8530drv.conf z8530drv-utils/*.lsm)

lharc:
	( cd .. && lharc a z8530drv-utils-${VERSION}.lzh \
	z8530drv-utils/README z8530drv-utils/Makefile \
	z8530drv-utils/doc z8530drv-utils/*.c z8530drv-utils/*.h \
	z8530drv-utils/sccinit z8530drv-utils/sccparam z8530drv-utils/sccstat \
	z8530drv-utils/gencfg z8530drv-utils/kissbridge \
	z8530drv-utils/z8530drv.conf z8530drv-utils/*.lsm)

dep:
	gcc ${CCOPT} -M sccstat.c sccinit.c sccparam.c kissbridge.c gencfg.c >.depend

ifeq (.depend,$(wildcard .depend))
include .depend
endif
