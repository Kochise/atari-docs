/*
 * C compiler
 * ==========
 *
 * Copyright 1989, 1990, 1991 Christoph van Wuellen.
 * Credits to Matthew Brandt.
 * All commercial rights reserved.
 *
 * This compiler may be redistributed as long there is no
 * commercial interest. The compiler must not be redistributed
 * without its full sources. This notice must stay intact.
 *
 * History:
 *
 * 1989   starting an 68000 C compiler, starting with material
 *        originally by M. Brandt
 * 1990   68000 C compiler further bug fixes
 *        started i386 port (December)
 * 1991   i386 port finished (January)
 *        further corrections in the front end and in the 68000
 *        code generator.
 *        The next port will be a SPARC port
 */

#include	"c.h"
#include	"expr.h"
#include	"gen.h"
#include	"cglbdec.h"

/*
 * Memory is allocated in Blocks of 1024 longs, which form a linked list
 */

struct blk {
    char            m[1024 * sizeof(long)];	/* memory area */
    struct blk     *next;
};

#define BLKLEN (1024 * (int) sizeof(long))
#define NIL_BLK ( (struct blk *) 0)

static int      glbsize = 0,	/* size left in current global block */
                locsize = 0,	/* size left in current local block */
                glbindx = 0,	/* global index */
                locindx = 0;	/* local index */

static int      max_mem = 0,	/* statistics... */
                glo_mem = 0;

static struct blk *locblk = NIL_BLK,	/* pointer to local block list */
               *glbblk = NIL_BLK;	/* pointer to global block list */

int            *
xalloc(siz)
    int             siz;
{
    struct blk     *bp;
    char           *rv;
    char           *calloc();
    /*
     * DO NOT use AL_DEFAULT here: host and target machine may differ. Align
     * on 32-bit boundaries, necessary for the SparcStation. This should be
     * suitable for most 32-bit processors. The i860 might need a change
     * here...
     */
    if (siz & 3)
	siz += 4 - (siz & 3);

    if (global_flag) {
	if (glbsize >= siz) {
	    rv = &(glbblk->m[glbindx]);
	    glbsize -= siz;
	    glbindx += siz;
	    return (int *) rv;
	} else {
	    bp = (struct blk *) calloc(1, (int) sizeof(struct blk));
	    if (bp == NULL) {
		fprintf(stderr, " not enough memory.\n");
		exit(1);
	    }
	    glo_mem++;
	    bp->next = glbblk;
	    glbblk = bp;
	    glbsize = BLKLEN - siz;
	    glbindx = siz;
	    return (int *) glbblk->m;
	}
    } else {			/* not global */
	if (locsize >= siz) {
	    rv = &(locblk->m[locindx]);
	    locsize -= siz;
	    locindx += siz;
	    return (int *) rv;
	} else {
	    bp = (struct blk *) calloc(1, (int) sizeof(struct blk));
	    if (bp == NULL) {
		fprintf(stderr, " not enough local memory.\n");
		exit(1);
	    }
	    bp->next = locblk;
	    locblk = bp;
	    locsize = BLKLEN - siz;
	    locindx = siz;
	    return (int *) locblk->m;
	}
    }
}

rel_local()
{
    struct blk     *bp1, *bp2;
    int             blkcnt;
    blkcnt = 0;
    bp1 = locblk;
    while (bp1 != 0) {
	bp2 = bp1->next;
	(void) free((char *) bp1);
	++blkcnt;
	bp1 = bp2;
    }
    if (blkcnt + glo_mem > max_mem)
	max_mem = blkcnt + glo_mem;
    locblk = 0;
    locsize = 0;
#ifdef VERBOSE
    if (list_option)
	fprintf(stderr, " releasing %2d Kbytes  local tables.\n",
		blkcnt * (int) sizeof(long));
#endif
}

rel_global()
{
    struct blk     *bp1, *bp2;
    int             blkcnt;
    bp1 = glbblk;
    blkcnt = 0;
    while (bp1 != 0) {
	bp2 = bp1->next;
	(void) free((char *) bp1);
	++blkcnt;
	bp1 = bp2;
    }
    if (blkcnt > max_mem)
	max_mem = blkcnt;
    glo_mem = 0;
    glbblk = 0;
    glbsize = 0;
#ifdef VERBOSE
    if (list_option)
	fprintf(stderr, " releasing %2d Kbytes global tables.\n",
		blkcnt * (int) sizeof(long));
#endif
#ifdef VERBOSE
    fprintf(stderr, "Maximum memory request was %d KBytes.\n",
	    max_mem * (int) sizeof(long));
#endif
    max_mem = 0;
}
