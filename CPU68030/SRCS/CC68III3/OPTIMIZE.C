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

static          void fold_const();

dooper(node)
/*
 * dooper will execute a constant operation in a node and modify the node to
 * be the result of the operation.
 */
    struct enode  **node;
{
    struct enode   *ep = *node;
    enum e_node     type = ep->nodetype;

#define ep0 ep->v.p[0]
#define ep1 ep->v.p[1]
#define epi ep->v.i
#define epf ep->v.f
#define ulong unsigned long

    ep->nodetype = ep0->nodetype;
    if (ep0->nodetype == en_fcon) {
#ifndef NOFLOAT
        switch (type) {
          case en_uminus:
            epf = - ep0->v.f;
            break;
          case en_not:
            ep->nodetype = en_icon;
            epi = (ep0->v.f) ? 0 : 1;
            break;
          case en_add:
            epf = ep0->v.f + ep1->v.f;
            break;
          case en_sub:
            epf = ep0->v.f - ep1->v.f;
            break;
          case en_mul:
            epf = ep0->v.f * ep1->v.f;
            break;
          case en_div:
	    if (ep1->v.f == 0.0) {
	        fprintf(stderr, "division by zero in constant node\n");
	        ep->nodetype = en_div;
	    } else {
	        epf = ep0->v.f / ep1->v.f;
	    }
            break;
          case en_eq:
            ep->nodetype = en_icon;
            epi = (ep0->v.f == ep1->v.f) ? 1 : 0;
            break;
          case en_ne:
            ep->nodetype = en_icon;
            epi = (ep0->v.f != ep1->v.f) ? 1 : 0;
            break;
          case en_land:
            ep->nodetype = en_icon;
            epi = (ep0->v.f && ep1->v.f) ? 1 : 0;
            break;
          case en_lor:
            ep->nodetype = en_icon;
            epi = (ep0->v.f || ep1->v.f) ? 1 : 0;
            break;
          case en_lt:
            ep->nodetype = en_icon;
            epi = (ep0->v.f < ep1->v.f) ? 1 : 0;
            break;
          case en_le:
            ep->nodetype = en_icon;
            epi = (ep0->v.f <= ep1->v.f) ? 1 : 0;
            break;
          case en_gt:
            ep->nodetype = en_icon;
            epi = (ep0->v.f > ep1->v.f) ? 1 : 0;
            break;
          case en_ge:
            ep->nodetype = en_icon;
            epi = (ep0->v.f >= ep1->v.f) ? 1 : 0;
            break;
          default:
            ep->nodetype = type;
            fprintf(stderr,"Illegal operation in dooper FLOAT\n");
            break;
        }
#endif /* NOFLOAT */
        return;
    }
    /*
     * Thus, ep0->nodetype is en_icon
     * We have to distinguisch unsigned long from the other cases
     *
     * Since we always store in ep->v.i, it is
     * ASSUMED THAT (long) (ulong) ep->v.i == ep->v.i always
     */
    if (ep0->etype == bt_ulong || ep0->etype == bt_pointer) {
        switch (type) {
          case en_uminus:
            epi = - (ulong) ep0->v.i;
            break;
          case en_not:
            epi = ((ulong) ep0->v.i) ? 0 : 1;
            break;
          case en_compl:
            epi = ~ (ulong) ep0->v.i;
            epi = strip_icon(epi, ep->etype);
            break;
          case en_add:
            epi = (ulong) ep0->v.i + (ulong) ep1->v.i;
            break;
          case en_sub:
            epi = (ulong) ep0->v.i - (ulong) ep1->v.i;
            break;
          case en_mul:
            epi = (ulong) ep0->v.i * (ulong) ep1->v.i;
            break;
          case en_div:
	    if ((ulong) ep1->v.i == 0) {
	        fprintf(stderr, "division by zero in constant node\n");
	        ep->nodetype = en_div;
	    } else {
	        epi = (ulong) ep0->v.i / (ulong) ep1->v.i;
	    }
            break;
          case en_mod:
	    if ((ulong) ep1->v.i == 0) {
	        fprintf(stderr, "division by zero in constant node\n");
	        ep->nodetype = en_mod;
	    } else {
	        epi = (ulong) ep0->v.i % (ulong) ep1->v.i;
	    }
            break;
          case en_and:
            epi = (ulong) ep0->v.i & (ulong) ep1->v.i;
            break;
          case en_or:
            epi = (ulong) ep0->v.i | (ulong) ep1->v.i;
            break;
          case en_xor:
            epi = (ulong) ep0->v.i ^ (ulong) ep1->v.i;
            break;
          case en_eq:
            epi = ((ulong) ep0->v.i == (ulong) ep1->v.i) ? 1 : 0;
            break;
          case en_ne:
            epi = ((ulong) ep0->v.i != (ulong) ep1->v.i) ? 1 : 0;
            break;
          case en_land:
            epi = ((ulong) ep0->v.i && (ulong) ep1->v.i) ? 1 : 0;
            break;
          case en_lor:
            epi = ((ulong) ep0->v.i || (ulong) ep1->v.i) ? 1 : 0;
            break;
          case en_lt:
            epi = ((ulong) ep0->v.i < (ulong) ep1->v.i) ? 1 : 0;
            break;
          case en_le:
            epi = ((ulong) ep0->v.i <= (ulong) ep1->v.i) ? 1 : 0;
            break;
          case en_gt:
            epi = ((ulong) ep0->v.i > (ulong) ep1->v.i) ? 1 : 0;
            break;
          case en_ge:
            epi = ((ulong) ep0->v.i >= (ulong) ep1->v.i) ? 1 : 0;
            break;
          case en_lsh:
            epi = (ulong) ep0->v.i << (ulong) ep1->v.i;
            break;
          case en_rsh:
            epi = (ulong) ep0->v.i >> (ulong) ep1->v.i;
            break;
          default:
            ep->nodetype = type;
            fprintf(stderr,"Illegal operation in dooper ULONG\n");
            break;
        }
    } else {
        switch (type) {
          case en_uminus:
            epi = - ep0->v.i;
            break;
          case en_not:
            epi = (ep0->v.i) ? 0 : 1;
            break;
          case en_compl:
            epi = ~ ep0->v.i;
            epi = strip_icon(epi, ep->nodetype);
            break;
          case en_add:
            epi = ep0->v.i + ep1->v.i;
            break;
          case en_sub:
            epi = ep0->v.i - ep1->v.i;
            break;
          case en_mul:
            epi = ep0->v.i * ep1->v.i;
            break;
          case en_div:
	    if (ep1->v.i == 0) {
	        fprintf(stderr, "division by zero in constant node\n");
	        ep->nodetype = en_div;
	    } else {
	        epi = ep0->v.i / ep1->v.i;
	    }
            break;
          case en_mod:
	    if (ep1->v.i == 0) {
	        fprintf(stderr, "division by zero in constant node\n");
	        ep->nodetype = en_mod;
	    } else {
	        epi = ep0->v.i % ep1->v.i;
	    }
            break;
          case en_and:
            epi = ep0->v.i & ep1->v.i;
            break;
          case en_or:
            epi = ep0->v.i | ep1->v.i;
            break;
          case en_xor:
            epi = ep0->v.i ^ ep1->v.i;
            break;
          case en_eq:
            epi = (ep0->v.i == ep1->v.i) ? 1 : 0;
            break;
          case en_ne:
            epi = (ep0->v.i != ep1->v.i) ? 1 : 0;
            break;
          case en_land:
            epi = (ep0->v.i && ep1->v.i) ? 1 : 0;
            break;
          case en_lor:
            epi = (ep0->v.i || ep1->v.i) ? 1 : 0;
            break;
          case en_lt:
            epi = (ep0->v.i < ep1->v.i) ? 1 : 0;
            break;
          case en_le:
            epi = (ep0->v.i <= ep1->v.i) ? 1 : 0;
            break;
          case en_gt:
            epi = (ep0->v.i > ep1->v.i) ? 1 : 0;
            break;
          case en_ge:
            epi = (ep0->v.i >= ep1->v.i) ? 1 : 0;
            break;
          case en_lsh:
            epi = ep0->v.i << ep1->v.i;
            break;
          case en_rsh:
            epi = ep0->v.i >> ep1->v.i;
            break;
          default:
            ep->nodetype = type;
            fprintf(stderr,"Illegal operation in dooper LONG\n");
            break;
        }
    }
#undef ep0
#undef ep1
#undef epi
#undef epf
#undef ulong
}

int
pwrof2(i)
/*
 * return which power of two i is or -1.
 */
    long            i;
{
    int             p;
    long            q;
    q = 2;
    p = 1;
    while (q > 0) {
	if (q == i)
	    return p;
	q <<= 1l;
	++p;
    }
    return -1;
}

long
mod_mask(i)
/*
 * make a mod mask for a power of two.
 */
    long            i;
{
    long            m;
    m = 0;
    while (i--)
	m = (m << 1) | 1;
    return m;
}

opt0(node)
/*
 * opt0 - delete useless expressions and combine constants.
 *
 * opt0 will delete expressions such as x + 0,
 *  x - 0,
 *  x * 0,
 *  x * 1,
 *  0 / x,
 *  x / 1,
 *  x mod 0,
 *  etc from the tree pointed to by node and combine obvious
 * constant operations. It cannot combine name and label constants but will
 * combine icon type nodes.
 */
    struct enode  **node;
{
    struct enode   *ep;

#define ep0 ep->v.p[0]
#define ep1 ep->v.p[1]

    long            val, sc;
    enum e_node     typ;
    ep = *node;
    if (ep == 0)
	return;
    typ = ep->nodetype;
    switch (typ) {
      case en_ref:
      case en_fieldref:
      case en_ainc:
      case en_adec:
      case en_deref:
	opt0(&ep0);
	break;
      case en_uminus:
      case en_not:
      case en_compl:
	opt0(&ep0);
        /*
         * This operation applied twice is a no-op
         */
        if (ep0->nodetype == typ) {
            *node = ep0->v.p[0];
            break;
        }
	if (ep0->nodetype == en_icon || ep0->nodetype == en_fcon)
	    dooper(node);
	break;
      case en_add:
      case en_sub:
	opt0(&ep0);
	opt0(&ep1);
        /*
         *  a + (-b)  =  a - b
         *  a - (-b)  =  a + b
         *  (-a) + b  =  b - a
         */
        if (ep1->nodetype == en_uminus) {
            ep1 = ep1->v.p[0];
            ep->nodetype = typ = (typ == en_add) ? en_sub : en_add;
        }
        if (ep0->nodetype == en_uminus && typ == en_add) {
            ep0 = ep0->v.p[0];
            swap_nodes(ep);
            ep->nodetype = typ = en_sub;
        }
        /*
         * constant expressions
         */
        if ((ep0->nodetype == en_icon && ep1->nodetype == en_icon) ||
            (ep0->nodetype == en_fcon && ep1->nodetype == en_fcon))   {
            dooper(node);
            break;
        }
	if (typ == en_add) {
	    if (ep1->nodetype == en_autocon)
		swap_nodes(ep);
	}
	if (ep0->nodetype == en_icon) {
	    if (ep0->v.i == 0) {
		if (typ == en_sub) {
		    ep0 = ep1;
		    ep->nodetype = typ = en_uminus;
		} else
		    *node = ep1;
		break;
	    }
	} else if (ep1->nodetype == en_icon) {
	    if (ep0->nodetype == en_autocon && typ == en_add) {
		ep0->v.i += ep1->v.i;
		*node = ep0;
		break;
	    }
	    if (ep1->v.i == 0) {
		*node = ep0;
		break;
	    }
	}
	break;
      case en_mul:
	opt0(&ep0);
	opt0(&ep1);
        /*
         * constant expressions
         */
        if ((ep0->nodetype == en_icon && ep1->nodetype == en_icon) ||
            (ep0->nodetype == en_fcon && ep1->nodetype == en_fcon))  {
            dooper(node);
            break;
        }
	if (ep0->nodetype == en_icon) {
	    val = ep0->v.i;
	    if (val == 0) {
		*node = ep0;
		break;
	    }
	    if (val == 1) {
		*node = ep1;
		break;
	    }
	    sc = pwrof2(val);
	    if (sc != -1) {
		swap_nodes(ep);
		ep1->v.i = sc;
		ep->nodetype = en_lsh;
	    }
	} else if (ep1->nodetype == en_icon) {
	    val = ep1->v.i;
	    if (val == 0) {
		*node = ep1;
		break;
	    }
	    if (val == 1) {
		*node = ep0;
		break;
	    }
	    sc = pwrof2(val);
	    if (sc != -1) {
		ep1->v.i = sc;
		ep->nodetype = en_lsh;
	    }
	}
	break;
      case en_div:
	opt0(&ep0);
	opt0(&ep1);
        /*
         * constant expressions
         */
        if ((ep0->nodetype == en_icon && ep1->nodetype == en_icon) ||
            (ep0->nodetype == en_fcon && ep1->nodetype == en_fcon))  {
            dooper(node);
            break;
        }
	if (ep0->nodetype == en_icon) {
	    if (ep0->v.i == 0) {	/* 0/x */
		*node = ep0;
		break;
	    }
	} else if (ep1->nodetype == en_icon) {
	    val = ep1->v.i;
	    if (val == 1) {	/* x/1 */
		*node = ep0;
		break;
	    }
	    sc = pwrof2(val);
	    if (sc != -1) {
		ep1->v.i = sc;
		ep->nodetype = en_rsh;
	    }
	}
	break;
      case en_mod:
	opt0(&ep0);
	opt0(&ep1);
        /*
         * constant expressions
         */
        if ((ep0->nodetype == en_icon && ep1->nodetype == en_icon) ||
            (ep0->nodetype == en_fcon && ep1->nodetype == en_fcon))  {
            dooper(node);
            break;
        }
	if (ep1->nodetype == en_icon) {
	    sc = pwrof2(ep1->v.i);
	    if (sc != -1) {
		ep1->v.i = mod_mask(sc);
		ep->nodetype = en_and;
	    }
	}
	break;
      case en_and:
      case en_or:
      case en_xor:
      case en_eq:
      case en_ne:
      case en_land:
      case en_lor:
      case en_lt:
      case en_le:
      case en_gt:
      case en_ge:
	opt0(&ep0);
	opt0(&ep1);
        /*
         * constant expressions
         */
        if ((ep0->nodetype == en_icon && ep1->nodetype == en_icon) ||
            (ep0->nodetype == en_fcon && ep1->nodetype == en_fcon))
            dooper(node);
	break;
      case en_lsh:
      case en_rsh:
	opt0(&ep0);
	opt0(&ep1);
	if (ep0->nodetype == en_icon && ep1->nodetype == en_icon) {
	    dooper(node);
            break;
        }
        /*
         * optimize a << 0   and a >> 0
         */
	if (ep1->nodetype == en_icon && ep1->v.i == 0)
	    *node = ep0;
	break;
      case en_cond:
	opt0(&ep0);
	opt0(&ep1);
        if (ep0->nodetype == en_icon) {
	    if (ep0->v.i)
		*node=ep1->v.p[0];
	    else
		*node=ep1->v.p[1];
	}
	break;
      case en_asand:
      case en_asor:
      case en_asxor:
      case en_asadd:
      case en_assub:
      case en_asmul:
      case en_asdiv:
      case en_asmod:
      case en_asrsh:
      case en_aslsh:
      case en_fcall:
      case en_void:
      case en_assign:
	opt0(&ep0);
	opt0(&ep1);
	break;
	/* now handled in expr.c */
      case en_cast:
	opt0(&ep0);
	if (ep0->nodetype == en_icon &&
	    ep->etype != bt_float &&
	    ep->etype != bt_double) {
fatal("SHOULD NOT OCCUR");
	    ep->nodetype = en_icon;
	    ep->v.i = ep0->v.i;
	}
	break;
    }

#undef ep0
#undef ep1
}

static long
xfold(node)
/*
 * xfold will remove constant nodes and return the values to the calling
 * routines.
 */
    struct enode   *node;
{
    long            i;
    if (node == 0)
	return 0;
    switch (node->nodetype) {
      case en_icon:
	i = node->v.i;
	node->v.i = 0;
	return i;
      case en_add:
	return xfold(node->v.p[0]) + xfold(node->v.p[1]);
      case en_sub:
	return xfold(node->v.p[0]) - xfold(node->v.p[1]);
      case en_mul:
	if (node->v.p[0]->nodetype == en_icon)
	    return xfold(node->v.p[1]) * node->v.p[0]->v.i;
	else if (node->v.p[1]->nodetype == en_icon)
	    return xfold(node->v.p[0]) * node->v.p[1]->v.i;
	else {
	    fold_const(&node->v.p[0]);
	    fold_const(&node->v.p[1]);
	    return 0;
	}
	/*
	 * CVW: This seems wrong to me... case en_lsh: if(
	 * node->v.p[0]->nodetype == en_icon ) return xfold(node->v.p[1]) <<
	 * node->v.p[0]->v.i; else if( node->v.p[1]->nodetype == en_icon )
	 * return xfold(node->v.p[0]) << node->v.p[1]->v.i; else return 0;
	 */
      case en_uminus:
	return -xfold(node->v.p[0]);
      case en_lsh:
      case en_rsh:
      case en_div:
      case en_mod:
      case en_asadd:
      case en_assub:
      case en_asmul:
      case en_asdiv:
      case en_asmod:
      case en_and:
      case en_land:
      case en_or:
      case en_lor:
      case en_xor:
      case en_asand:
      case en_asor:
      case en_asxor:
      case en_void:
      case en_fcall:
      case en_assign:
      case en_eq:
      case en_ne:
      case en_lt:
      case en_le:
      case en_gt:
      case en_ge:
	fold_const(&node->v.p[0]);
	fold_const(&node->v.p[1]);
	return 0;
      case en_ref:
      case en_fieldref:
      case en_compl:
      case en_not:
      case en_deref:
	fold_const(&node->v.p[0]);
	return 0;
	/*
	 * This is not stricly legal: (long)(x+10) * 4l might not be the same
	 * as (long)(x) * 4l + 40l but it is the same as long as no overflows
	 * occur
	 */
      case en_cast:
#ifdef DONTDEF
	return xfold(node->v.p[0]);
#endif
	/*
	 * Well, sometimes I prefer purity to efficiency
	 * It is a matter of tast how you decide here....
	 */
	fold_const(&node->v.p[0]);
	return 0;
    }
    return 0;
}

static void
fold_const(node)
/*
 * reorganize an expression for optimal constant grouping.
 */
    struct enode  **node;
{
    struct enode   *ep;
    long            i;
    ep = *node;
    if (ep == 0)
	return;
    if (ep->nodetype == en_add) {
	if (ep->v.p[0]->nodetype == en_icon) {
	    ep->v.p[0]->v.i += xfold(ep->v.p[1]);
	    return;
	} else if (ep->v.p[1]->nodetype == en_icon) {
	    ep->v.p[1]->v.i += xfold(ep->v.p[0]);
	    return;
	}
    } else if (ep->nodetype == en_sub) {
	if (ep->v.p[0]->nodetype == en_icon) {
	    ep->v.p[0]->v.i -= xfold(ep->v.p[1]);
	    return;
	} else if (ep->v.p[1]->nodetype == en_icon) {
	    ep->v.p[1]->v.i -= xfold(ep->v.p[0]);
	    return;
	}
    }
    i = xfold(ep);
    if (i != 0) {
/*
 * strip_icon is in fact harmless here since this value is
 * just added to *node
 * consider in 16-bit mode:
 *
 * int day, year;
 * day = 365 * (year - 1970);
 *
 * and look at the code, which is transformed to
 *
 * day = 365*year + 1846;
 *
 * which works if the multiplication returns the lower 16 bits of
 * the result correctly.
 */
	i = strip_icon(i, (*node)->etype);
	ep = mk_icon(i);
	ep->etype = (*node)->etype;
	ep->esize = (*node)->esize;
	ep = mk_node(en_add, *node, ep);
	ep->etype = (*node)->etype;
	ep->esize = (*node)->esize;
	*node = ep;
    }
}

opt4(node)
/*
 * apply all constant optimizations.
 */
    struct enode  **node;
{
    /* opt0(node); */
    fold_const(node);
    opt0(node);
}
