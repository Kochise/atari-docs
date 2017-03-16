VERSION = 2.4a.dl1bke
KERNEL  = `cat /proc/version | cut -d" " -f3`
CCOPT   = -O2 -m486 -Wall -Wstrict-prototypes -DCONFIG_SCC_STANDALONE
MODOPT  = -c -pipe -D__KERNEL__ -DMODULE -DMODVERSIONS -fomit-frame-pointer\
	  -DCONFIG_SCC_DEV -DCONFIG_SCC_TTY -I/usr/src/linux/include
# MODVER  = -DMODVERSIONS -include /usr/src/linux/include/linux/modversions.h
DEVNAME = scc
MAJOR   = 34

all: utils install

for_kernel: install_source all

module: scc.o all install_module

utils: sccparam sccstat sccinit gencfg

scc.o: scc.c
	gcc ${CCOPT} ${MODOPT} ${MODVER} scc.c -o $@

sccparam: sccparam.c
	gcc ${CCOPT} sccparam.c -o $@

sccstat: sccstat.c
	gcc ${CCOPT} sccstat.c -o $@

sccinit: sccinit.c
	gcc ${CCOPT} sccinit.c -o $@

gencfg: gencfg.c
	gcc ${CCOPT} gencfg.c -o $@

install:
	install -g root -o root -m 0755 -s sccstat /sbin/sccstat
	install -g root -o root -m 0700 -s sccinit /sbin/sccinit
	install -g root -o root -m 0700 -s sccparam /sbin/sccparam
	install -g root -o root -m 0644 z8530drv.conf /etc/z8530drv.conf.ex
	for d in 0 1 2 3 4 5 6 7 ; do \
		rm -f /dev/${DEVNAME}$$d		;\
		mknod /dev/${DEVNAME}$$d c ${MAJOR} $$d	;\
	done

install_module:
	install -g root -o root -m 0644 scc.o /lib/modules/${KERNEL}/misc/scc.o

install_source:
	cp -f scc.c /usr/src/linux/drivers/char/
	cp -f scc.h /usr/src/linux/include/linux/

clean:
	rm -f *.o *~ doc/*~

distrib:
	( cd .. && tar zcvvf z8530drv-${VERSION}.tar.gz \
	z8530drv-2.4/README z8530drv-2.4/FAQ z8530drv-2.4/Makefile z8530drv-2.4/doc \
	z8530drv-2.4/*.c z8530drv-2.4/scc.h z8530drv-2.4/sccinit z8530drv-2.4/sccparam \
	z8530drv-2.4/sccstat z8530drv-2.4/gencfg z8530drv-2.4/z8530drv.conf \
	z8530drv-2.4/*.lsm z8530drv-2.4/*patch z8530drv-2.4/kernel-2.1.x)

lharc:
	( cd .. && lharc a z8530drv-${VERSION}.lzh \
	z8530drv-2.4/README z8530drv-2.4/FAQ z8530drv-2.4/Makefile z8530drv-2.4/doc \
	z8530drv-2.4/*.c z8530drv-2.4/scc.h z8530drv-2.4/sccinit z8530drv-2.4/sccparam \
	z8530drv-2.4/sccstat z8530drv-2.4/gencfg z8530drv-2.4/z8530drv.conf \
	z8530drv-2.4/*.lsm z8530drv-2.4/*patch z8530drv-2.4/kernel-2.1.x)

dep:
	gcc ${CCOPT} -M sccstat.c sccinit.c sccparam.c >.depend
	gcc ${CCOPT} ${MODOPT} -M scc.c >>.depend

ifeq (.depend,$(wildcard .depend))
include .depend
endif
