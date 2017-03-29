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

static long     inittype(), initstruct(), initarray(), initunion();
static int      initchar(), initshort(), initlong(), initfloat(), initpointer();
static int	initdouble();
static struct enode *constexpr();

doinit(sp, align)
    struct sym     *sp;
    int             align;
{
    nl();
    if (lastst != assign)
	genstorage(sp, align);
    else {
	dseg();			/* select data segment */
	put_align(align);
	if (sp->storage_class == sc_static)
	    put_label((unsigned int) sp->value.i);
	else
	    g_strlab(sp->name);
	getsym();
	(void) inittype(sp->tp);
    }
}

static long
inittype(tp)
    TYP            *tp;
{
    int             brace_seen = 0;
    long            nbytes;
    if (lastst == begin) {
	brace_seen = 1;
	getsym();
    }
    switch (tp->type) {
      case bt_char:
      case bt_uchar:
	nbytes = initchar();
	break;
      case bt_short:
      case bt_ushort:
        nbytes = initshort();
        break;
      case bt_pointer:
	if (tp->val_flag)
	    nbytes = initarray(tp);
	else {
	    nbytes = initpointer();
	}
	break;
      case bt_ulong:
      case bt_long:
	nbytes = initlong();
	break;
      case bt_float:
	nbytes = initfloat();
	break;
      case bt_double:
        nbytes = initdouble();
        break;
      case bt_struct:
	nbytes = initstruct(tp);
	break;
      case bt_union:
	nbytes = initunion(tp);
	break;
      default:
	error(ERR_NOINIT);
	nbytes = 0;
    }
    if (brace_seen)
	needpunc(end);
    return nbytes;
}

static long
initarray(tp)
    TYP            *tp;
{
    long            nbytes;
    char           *p;
    int             len;
    nbytes = 0;
    if (lastst == sconst && (tp->btp->type == bt_char ||
			     tp->btp->type == bt_uchar)) {
	len = lstrlen;
	nbytes = len + 1;
	p = laststr;
	while (len--)
	    genbyte(*p++);
	genbyte(0);
	while (nbytes < tp->size) {
	    genbyte(0);
	    nbytes++;
	}
	getsym();		/* skip sconst */
    } else
	for (;;) {
	    nbytes += inittype(tp->btp);
	    if (lastst == comma)
		getsym();
	    if (lastst == end || lastst == semicolon) {
		while (nbytes < tp->size) {
		    genbyte(0);
		    nbytes++;
		}
		break;
	    }
	    if (tp->size > 0 && nbytes >= tp->size)
		break;
	}
    if (tp->size == 0)
	tp->size = nbytes;
    if (nbytes > tp->size)
	error(ERR_INITSIZE);
    return nbytes;
}

static long
initunion(tp)
    TYP		   *tp;
{
    struct sym     *sp;
    long            nbytes;
    long	    size;
    
    size = tp->size;
    sp = tp->lst.head;
/*
 * Initialize the first branch
 */
    if (sp == 0)
        return 0;
    tp = sp->tp;
    nbytes = inittype(tp);
    while (nbytes < size) {
	genbyte(0);
	nbytes++;
    }
}

static long
initstruct(tp)
    TYP            *tp;
{
    struct sym     *sp;
    long            nbytes;
    nbytes = 0;
    sp = tp->lst.head;		/* start at top of symbol table */
    while (sp != 0) {
	while (nbytes < sp->value.i) {	/* align properly */
	    nbytes++;
	    genbyte(0);
	}
	nbytes += inittype(sp->tp);
	if (lastst == comma)
	    getsym();
	if (lastst == end || lastst == semicolon)
	    break;
	sp = sp->next;
    }
    while (nbytes < tp->size) {
	genbyte(0);
	nbytes++;
    }
    return tp->size;
}

static int
initchar()
{
    genbyte((int) intexpr());
    return 1;
}

static int
initshort()
{
    genword((int) intexpr());
    return 2;
}

static int
initlong()
{
/*
 * We allow longs to be initialized with pointers now.
 * Thus, we call constexpr() instead of intexpr.
 */
#if 0
/*
 * This is more strict
 */
    genlong(intexp());
    return 4;
#endif
    genptr(constexpr());
    return 4;
}

static int
initfloat()
{
#ifndef NOFLOAT
    double          floatexpr();
    genfloat(floatexpr());
#endif
#ifdef NOFLOAT
    genlong(0l);
#endif
    return 4;
}

static int
initdouble()
{
#ifdef NOFLOAT
    int i;
    for (i=0; i< tp_double.size; i++)
	genbyte(0);
#endif
#ifndef NOFLOAT
    double floatexpr();
    gendouble(floatexpr());
#endif
    return tp_double.size;
}

static int
initpointer()
{
    genptr(constexpr());
    return 4;
}

static struct enode *
constexpr()
{
    struct enode *ep;
    struct typ   *tp;
    tp=exprnc(&ep);
    if (tp == 0) {
        error(ERR_SYNTAX);
        return 0;
    }
    opt4(&ep);
    if (!tst_const(ep)) {
	error(ERR_SYNTAX);
	return 0;
    }
    return ep;
}
