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

/* function compilation routines */

funcbody(sp, names, nparms)
/*
 * funcbody starts with the current symbol being the begin for the local
 * block or the first symbol of the parameter declaration
 */
    struct sym     *sp;
    char           *names[];
int             nparms;
{
    long            poffset;
    int             i, j;
    struct sym     *sp1, *mk_int();
    int             old_global;
    long            old_spvalue;

#ifdef VERBOSE
    time_t          ltime;
#endif				/* VERBOSE */

#ifdef VERBOSE
    times(&tms_buf);
    ltime = tms_buf.tms_utime;
#endif				/* VERBOSE */
    uses_structassign=0;
    lc_auto = 0;
    max_scratch = 0;
    is_leaf_function = 1;
    regptr = 0;
    autoptr = 0;
    init_node = 0;
    old_global = global_flag;
    global_flag = 0;
    poffset = 8;		/* size of return block */
    if (sp->tp->btp->type == bt_struct || sp->tp->btp->type == bt_union)
	poffset = 12;
    if (lastst != begin)
	dodecl(sc_parms);	/* declare parameters */
    /* undeclared parameters are int's */
    for (i = 0; i < nparms; ++i) {
	if ((sp1 = search(names[i], lsyms.tail)) == 0) {
	    sp1 = mk_int(names[i]);
	    if (warning())
	        fprintf(stderr, "Argument %s implicitly declared 'int'\n",
		    names[i]);
	}
	old_spvalue = sp1->value.i;
	sp1->value.i = poffset;
	sp1->storage_class = sc_auto;
	/*
	 * char, unsigned char, short, unsigned short, enum have been widened
	 * to int by the caller. This has to be un-done The same is true for
	 * float/double but float==double actually convert x[] to *x by
	 * clearing val_flag
	 * 
	 * It is shown here how to do this correctly, but if we know something
	 * about the data representation, it can be done much more
	 * effectively. Therefore, we define MC680X0 and do the cast
	 * by hand. This means that we can retrieve a char, widened to short
	 * and put at machine address n, at machine address n+1. This should
	 * work on most machines. BIGendian machines can do it like it is
	 * shown here, LOWendian machines must not adjust sp1->value.i The
	 * function castback is still needed if someone decides to have a
	 * double data type which is not equivalent to float.
	 * This approach is, of course, ugly since some
	 * assumptions on the target machine enter the front end here, but
	 * they do anyway through the initial value of poffset which is the
	 * number of bytes that separate the local block from the argument
	 * block. On an 68000 this are eight bytes since we do a link a6,...
	 * always.
	 */
	switch (sp1->tp->type) {
	  case bt_char:
	  case bt_uchar:
#ifdef MC680X0
	    if (short_option) {
		sp1->value.i += 1;
		poffset += 2;
	    } else {
		sp1->value.i += 3;
		poffset += 4;
	    }
#endif
#ifdef INTEL_386
            /* note that we only support 32-bit integers */
	    poffset += 4; /* byte already right there */
#endif
	    break;
	  case bt_short:
	  case bt_ushort:
#ifdef MC680X0
	    if (short_option) {
		poffset += 2;
	    } else {
		sp1->value.i += 2;
		poffset += 4;
	    }
#endif
#ifdef INTEL_386
	    poffset += 4; /* word already right there */
#endif
	    break;
          case bt_float:
#ifdef MC68000
            /* float is the same as double in the 68000 implementation */
            poffset += 4;
#endif
#ifdef INTEL_386
            castback(poffset, &tp_double, &tp_float);
            poffset += 8;
#endif
            break;
	  case bt_pointer:
	  case bt_func:
	    poffset += 4;
	    /*
	     * arrays and functions are never passed. They are really
	     * Pointers
	     */
	    if (sp1->tp->val_flag != 0) {
		TYP            *tp1 = (TYP *) xalloc((int) sizeof(TYP));
		*tp1 = *(sp1->tp);
		tp1->st_flag = 0;
		sp1->tp = tp1;
		sp1->tp->val_flag = 0;
		sp1->tp->size = 4;
	    }
	    break;
	  default:
	    poffset += sp1->tp->size;
	    break;
	}
	/*
	 * The following code updates the reglst and autolst arrays
	 * old_spvalue is zero for undeclared parameters (see mk_int), so it
	 * works. We do a linear search through the reglst and autolst array,
	 * so this is inefficient. Howewer, these arrays are usually short
	 * since they only contain the function arguments at moment. In
	 * short, function argument processing need not be efficient.
	 */
	for (j = 0; j < regptr; j++) {
	    if (reglst[j] == old_spvalue) {
		reglst[j] = sp1->value.i;
		break;
	    }
	}
	for (j = 0; j < autoptr; j++) {
	    if (autolst[j] == old_spvalue) {
		autolst[j] = sp1->value.i;
		break;
	    }
	}
    }
    /*
     * Check if there are declared parameters missing in the argument list.
     */
    sp1 = lsyms.tail;
    while (sp1 != 0) {
	/*
	 * assume that value.i is negative for normal auto variables
         * and positive for parameters
	 */
	if (sp1->value.i <= 0)
	    error(ERR_ARG);
	sp1 = sp1->prev;
    }
    if (lastst != begin)
	error(ERR_BLOCK);
    else {
	block(sp);
	funcbottom();
    }
    global_flag = old_global;
#ifdef VERBOSE
    times(&tms_buf);
    parse_time += tms_buf.tms_utime - ltime;
#endif				/* VERBOSE */
}

struct sym     *
mk_int(name)
    char           *name;
{
    struct sym     *sp;
    TYP            *tp;
    sp = (struct sym *) xalloc((int) sizeof(struct sym));
    tp = (TYP *) xalloc((int) sizeof(TYP));
    tp->st_flag = 0;
    if (short_option) {
	tp->type = bt_short;
	tp->size = 2;
    } else {
	tp->type = bt_long;
	tp->size = 4;
    }
    tp->btp = 0;
    tp->lst.head = 0;
    tp->sname = 0;
    sp->name = name;
    sp->storage_class = sc_auto;
    sp->value.i = 0;		/* dummy */
    sp->tp = tp;
    append(&sp, &lsyms);
    return sp;
}

check_table(head)
    struct sym     *head;
{
    while (head != 0) {
	if (head->storage_class == sc_ulabel) {
	    fprintf(stderr, "*** UNDEFINED LABEL - %s\n", head->name);
	    if (list_option)
		fprintf(list, "*** UNDEFINED LABEL - %s\n", head->name);
	}
	head = head->next;
    }
}

funcbottom()
{
    nl();
    check_table(labsyms.head);
    if (list_option && lsyms.head != 0) {
	fprintf(list, "\n\n*** argument symbol table ***\n\n");
	list_table(&lsyms, 0);
	fprintf(list, "\n\n\n");
    }
    if (list_option && labsyms.head != 0) {
	fprintf(list, "\n\n*** label symbol table ***\n\n");
	list_table(&labsyms, 0);
	fprintf(list, "\n\n\n");
    }
    rel_local();		/* release local symbols */
    lsyms.head = lsyms.tail = 0;
    ltags.head = ltags.tail = 0;
    labsyms.head = labsyms.tail = 0;
}

block(sp)
    struct sym     *sp;
{
    struct snode   *stmt;
    int local_total_errors = total_errors;
#ifdef VERBOSE
    time_t          ltime;
#endif				/* VERBOSE */

#ifdef VERBOSE
    fprintf(stderr, "%s\n", sp->name);
#endif				/* VERBOSE */

#ifdef ICODE
    if (icode_option)
	if (sp->storage_class == sc_external || sp->storage_class == sc_global)
	    fprintf(icode, "%s:\n", sp->name);
	else
	    fprintf(icode, "L%ld:\n", sp->value.i);
#endif
    needpunc(begin);
    stmt = compound(0);
#ifdef VERBOSE
    times(&tms_buf);
    ltime = tms_buf.tms_utime;
#endif				/* VERBOSE */
/*
 * If errors so far, do not try to generate code
 */
    if (total_errors > local_total_errors) {
        cseg();
        dumplits();
        return;
    }
    genfunc(stmt);
#ifdef VERBOSE
    times(&tms_buf);
    gen_time += tms_buf.tms_utime - ltime;
    ltime = tms_buf.tms_utime;
#endif				/* VERBOSE */
    cseg();
    dumplits();
    put_align(AL_FUNC);
    if (sp->storage_class == sc_external || sp->storage_class == sc_global)
	g_strlab(sp->name);
    else
	put_label((unsigned int) sp->value.i);
    flush_peep();
#ifdef VERBOSE
    times(&tms_buf);
    flush_time += tms_buf.tms_utime - ltime;
#endif				/* VERBOSE */
}

castback(offset, tp1, tp2)
    long            offset;
    TYP            *tp1, *tp2;

/*
 * cast an argument back which has been widened on the caller's side.
 * append the resulting assignment expression to init_node
 */
{
    struct enode   *ep1, *ep2;

    ep2 = mk_node(en_autocon, NIL_ENODE, NIL_ENODE);
    ep2->v.i = offset;
    ep2->etype = bt_pointer;
    ep2->esize = 4;

    ep1 = copynode(ep2);

    ep2 = mk_node(en_ref, ep2, NIL_ENODE);
    ep2->etype = tp1->type;
    ep2->esize = tp1->size;

    ep2 = mk_node(en_cast, ep2, NIL_ENODE);
    ep2->etype = tp2->type;
    ep2->esize = tp2->size;

    ep1 = mk_node(en_ref, ep1, NIL_ENODE);
    ep1->etype = tp2->type;
    ep1->esize = tp2->size;

    ep1 = mk_node(en_assign, ep1, ep2);
    ep1->etype = tp2->type;
    ep1->esize = tp2->size;

    if (init_node == 0)
	init_node = ep1;
    else
	init_node = mk_node(en_void, init_node, ep1);
}
