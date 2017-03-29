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

#ifndef NOFLOAT
double
floatexpr()
/* floating point expression */
{
    struct enode   *ep;
    struct typ     *tp;

    tp = exprnc(&ep);
    if (tp == 0) {
	error(ERR_FPCON);
	return (double) 0;
    }

    opt4(&ep);

    if (ep->nodetype == en_icon)
        return (double) ep->v.i;

    if (ep->nodetype == en_fcon)
        return ep->v.f;

    error (ERR_SYNTAX);
    return (double) 0;
}
#endif /* !NOFLOAT */

long
intexpr()
{
    struct enode   *ep;
    struct typ     *tp;

    tp = exprnc(&ep);
    if (tp == 0) {
	error(ERR_INTEXPR);
	return 0;
    }
    opt4(&ep);

    if (ep->nodetype != en_icon) {
	error(ERR_SYNTAX);
	return 0;
    }
    return ep->v.i;
}
