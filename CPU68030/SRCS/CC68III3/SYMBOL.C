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
 * The inline expansion of strcmp() in search (and in searchkw) reduced
 * the overall execution time by an amount over 25 percent since the
 * compiler very frequently searching something in the symbol tables...
 */

struct sym     *
search(na, ttail)
/*
 * If your machine is low on registers, delete the register attribute in the
 * next two lines since it is more important to keep s1 and s2 in registers
 */

    register struct sym *ttail;
#ifdef i386
    char           *na;
#else
    register char  *na;
#endif

{
    register char  *s1;
    register char  *s2;
    while (ttail != 0) {
	s1 = ttail->name;
	s2 = na;
	for (;;) {
	    if (*s1++ != *s2)
		break;
	    if (*s2++ == '\0')
		return ttail;
	}
	ttail = ttail->prev;
    }
    return 0;
}

struct sym     *
gsearch(na)
    char           *na;
{
    struct sym     *sp;
    if ((sp = search(na, lsyms.tail)) == 0)
	sp = search(na, gsyms.tail);
    return sp;
}

void
append(ptr_sp, table)
    struct sym    **ptr_sp;
    TABLE          *table;
{
    struct sym     *sp1, *sp = *ptr_sp;

    if (table == &gsyms && (sp1 = search(sp->name, table->tail)) != 0) {
	/*
	 * The global symbol table has only one level, this means that we
	 * only check if the new declaration is compatible with the old one
	 */

	if (!eq_type(sp->tp, sp1->tp))
	    error(ERR_REDECL);
	/*
	 * The new storage class depends on the old and on the new one.
	 */
	if (sp->storage_class == sp1->storage_class) {
	    if (sp->storage_class == sc_global) {
		/*
		 * This hack sets sp->used -1 so that decl.c knows to to
		 * suppress storage allocation
		 */
		do_warning();
		fprintf(stderr, "global redeclaration of %s\n", sp->name);
		sp1->used = -1;
	    }
	    *ptr_sp = sp1;	/* caller uses old entry */
	    return;
	}
	/*
	 * since we use compiler generated label for static data, we must
	 * retain sc_static
	 */
	if (sp1->storage_class == sc_static) {
	    *ptr_sp = sp1;	/* caller uses old entry */
	    return;
	}
	/*
	 * if the new storage class is global, we must update sp1 to generate
	 * the .globl directive at the very end and perhaps the size (e.g.
	 * for arrays)
	 */
	if (sp->storage_class == sc_global) {
	    sp1->storage_class = sc_global;
	    sp1->tp = sp->tp;
	    *ptr_sp = sp1;	/* caller uses old entry */
	    return;
	}
	/*
	 * if the new storage class is static, set it to global (since we may
	 * have used the ,real' name and cannot use compiler generated names
	 * for this symbol from now on) and set sp->value.i to -1 to prevent
	 * it from being exported via .globl directives
	 */
	if (sp->storage_class == sc_static) {
	    sp1->storage_class = sc_global;
	    sp1->value.i = -1;
	    *ptr_sp = sp1;	/* caller uses old entry */
	    return;
	}
	/*
	 * last case: global declaration followed by external decl.: just do
	 * nothing
	 */
	*ptr_sp = sp1;		/* caller uses old entry */
	return;
    }
    if (table->head == 0) {
	/* The table is empty so far... */
	table->head = table->tail = sp;
	sp->next = sp->prev = 0;
	sp->used = 0;
    } else {
	table->tail->next = sp;
	sp->prev = table->tail;
	table->tail = sp;
	sp->next = 0;
	sp->used = 0;
    }
}
