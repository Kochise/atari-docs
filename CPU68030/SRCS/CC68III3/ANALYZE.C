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
 * this module will step through the parse tree and find all optimizable
 * expressions. at present these expressions are limited to expressions that
 * are valid throughout the scope of the function. the list of optimizable
 * expressions is:
 *
 * constants
 * global and static addresses
 * auto addresses
 * contents of auto addresses.
 *
 * contents of auto addresses are valid only if the address is never referred to
 * without dereferencing.
 *
 * scan will build a list of optimizable expressions which opt1 will replace
 * during the second optimization pass.
 */

static struct cse *olist;	/* list of optimizable expressions */

int
equalnode(node1, node2)
/*
 * equalnode will return 1 if the expressions pointed to by node1 and node2
 * are equivalent.
 */
    register struct enode *node1, *node2;
{
    if (node1 == 0 || node2 == 0)
	return 0;
    if (node1->nodetype != node2->nodetype)
	return 0;
    switch (node1->nodetype) {
      case en_icon:
      case en_labcon:
      case en_autocon:
	return (node1->v.i == node2->v.i);
      case en_nacon:
	return (!strcmp(node1->v.sp, node2->v.sp));
      case en_ref:
      case en_fieldref:
	return equalnode(node1->v.p[0], node2->v.p[0]);
      default:
	return 0;
    }
}


static struct cse *
searchnode(node)
/*
 * searchnode will search the common expression table for an entry that
 * matches the node passed and return a pointer to it.
 * the top level of equalnode is code inline here for speed
 */
    register struct enode *node;
{
    register struct cse *csp;
    register struct enode *ep;
    if (node == 0)
	return 0;
    csp = olist;
    while (csp != 0) {
	ep = csp->exp;
	if (ep != 0 && node->nodetype == ep->nodetype) {
	    switch (node->nodetype) {
	      case en_icon:
	      case en_labcon:
	      case en_autocon:
		if (node->v.i == ep->v.i)
		    return csp;
		break;
	      case en_nacon:
		if (!strcmp(node->v.sp, ep->v.sp))
		    return csp;
		break;
	      case en_ref:
		if (equalnode(node->v.p[0], ep->v.p[0]))
		    return csp;
		break;
	    }
	}
	csp = csp->next;
    }
    return 0;
}

struct enode   *
copynode(node)
/*
 * copy the node passed into a new enode so it wont get corrupted during
 * substitution.
 */
    struct enode   *node;
{
    struct enode   *temp;
    if (node == 0)
	return 0;
    temp = (struct enode *) xalloc((int) sizeof(struct enode));
    *temp = *node;
    return temp;
}



static struct cse *
enternode(node, duse)
/*
 * enternode will enter a reference to an expression node into the common
 * expression table. duse is a flag indicating whether or not this reference
 * will be dereferenced.
 */
    struct enode   *node;
    int             duse;
{
    struct cse     *csp;
    if ((csp = searchnode(node)) == 0) {	/* add to tree */
	csp = (struct cse *) xalloc((int) sizeof(struct cse));
	csp->next = olist;
	csp->uses = 0;
	csp->duses = 0;
	csp->exp = copynode(node);
	csp->voidf = 0;
	olist = csp;
	return csp;
    } else {
	/*
	 * Integer constants may be in the table with different sizes -- keep
	 * the maximum size
	 */
	if (node->nodetype == en_icon && node->esize > csp->exp->esize)
	    csp->exp->esize = node->esize;
    }
    ++(csp->uses);
    if (duse)
	++(csp->duses);
    return csp;
}

static struct cse *
voidauto(node)
/*
 * voidauto will void an auto dereference node which points to the same auto
 * constant as node.
 */
    struct enode   *node;
{
    struct cse     *csp;
    csp = olist;
    while (csp != 0) {
	if (lvalue(csp->exp) && equalnode(node, csp->exp->v.p[0])) {
	    if (csp->voidf)
		return 0;
	    csp->voidf = 1;
	    return csp;
	}
	csp = csp->next;
    }
    return 0;
}

scanexpr(node, duse)
/*
 * scanexpr will scan the expression pointed to by node for optimizable
 * subexpressions. when an optimizable expression is found it is entered into
 * the tree. if a reference to an autocon node is scanned the corresponding
 * auto dereferenced node will be voided. duse should be set if the
 * expression will be dereferenced.
 */
    struct enode   *node;
    int             duse;
{
    struct cse     *csp, *csp1;
    if (node == 0)
	return;
    switch (node->nodetype) {
      case en_icon:
#ifdef INTEL_386
/*
 * I decided to test if it is more efficient not to hold
 * integer constants in registers since they are rare.
 * On the 68000, integer constants in register make sense only
 * in a limited number of cases
 */
        break;
#endif
      case en_labcon:
      case en_nacon:
	(void) enternode(node, duse);
	break;
      case en_autocon:
	/*
	 * look if the dereferenced use of the node is in the list, remove it
	 * in this case
	 */
	if ((csp = voidauto(node)) != 0) {
	    csp1 = enternode(node, duse);
	    csp1->duses += csp->uses;
	} else
	    (void) enternode(node, duse);
	break;

      case en_ref:
      case en_fieldref:
	if (node->v.p[0]->nodetype != en_autocon) {
	    scanexpr(node->v.p[0], 1);
	    break;
	} else {
	    int             first = (searchnode(node) == 0);
	    csp = enternode(node, duse);
	    /*
	     * take care: the non-derereferenced use of the autocon node may
	     * already be in the list. In this case, set voidf to 1
	     */
	    if (searchnode(node->v.p[0]) != 0) {
		csp->voidf = 1;
		scanexpr(node->v.p[0], 1);
	    } else if (first) {
		/* look for register nodes */
		int             i = 0;
		long            j = node->v.p[0]->v.i;
		while (i < regptr) {
		    if (reglst[i] == j) {
			csp->voidf--;	/* this is not in auto_lst */
			csp->uses += 90 * (100 - i);
			csp->duses += 30 * (100 - i);
			break;
		    }
		    ++i;
		}
		/* set voidf if the node is not in autolst */
		csp->voidf++;
		i = 0;
		while (i < autoptr) {
		    if (autolst[i] == j) {
			csp->voidf--;
			break;
		    }
		    ++i;
		}
		/*
		 * even if that item must not be put in a register,
                 * it is legal to put its address therein
                 */
                if (csp->voidf)
                    scanexpr(node->v.p[0], 1);
	    }
	}
	break;
      case en_uminus:
      case en_compl:
      case en_ainc:
      case en_adec:
      case en_not:
      case en_cast:
      case en_deref:
	scanexpr(node->v.p[0], duse);
	break;
      case en_asadd:
      case en_assub:
      case en_add:
      case en_sub:
	scanexpr(node->v.p[0], duse);
	scanexpr(node->v.p[1], duse);
	break;
      case en_mul:
      case en_div:
      case en_lsh:
      case en_rsh:
      case en_mod:
      case en_and:
      case en_or:
      case en_xor:
      case en_lor:
      case en_land:
      case en_eq:
      case en_ne:
      case en_gt:
      case en_ge:
      case en_lt:
      case en_le:
      case en_asmul:
      case en_asdiv:
      case en_asmod:
      case en_aslsh:
      case en_asrsh:
      case en_asand:
      case en_asor:
      case en_asxor:
      case en_cond:
      case en_void:
      case en_assign:
	scanexpr(node->v.p[0], 0);
	scanexpr(node->v.p[1], 0);
	break;
      case en_fcall:
	scanexpr(node->v.p[0], 1);
	scanexpr(node->v.p[1], 0);
	break;
    }
}

scan(block)
/*
 * scan will gather all optimizable expressions into the expression list for
 * a block of statements.
 */
    struct snode   *block;
{
    while (block != 0) {
	switch (block->stype) {
	  case st_return:
	  case st_expr:
	    opt4(&block->exp);
	    scanexpr(block->exp, 0);
	    break;
	  case st_while:
	  case st_do:
	    opt4(&block->exp);
	    scanexpr(block->exp, 0);
	    scan(block->s1);
	    break;
	  case st_for:
	    opt4(&block->exp);
	    scanexpr(block->exp, 0);
	    opt4(&block->v1.e);
	    scanexpr(block->v1.e, 0);
	    scan(block->s1);
	    opt4(&block->v2.e);
	    scanexpr(block->v2.e, 0);
	    break;
	  case st_if:
	    opt4(&block->exp);
	    scanexpr(block->exp, 0);
	    scan(block->s1);
	    scan(block->v1.s);
	    break;
	  case st_switch:
	    opt4(&block->exp);
	    scanexpr(block->exp, 0);
	    scan(block->v1.s);
	    break;
	  case st_case:
	  case st_default:
	    scan(block->v1.s);
	    break;
	  case st_compound:
	  case st_label:
	    scan(block->s1);
	    break;
	}
	block = block->next;
    }
}

int
desire(csp)
/*
 * returns the desirability of optimization for a subexpression.
 */
    struct cse     *csp;
{
    if (csp->voidf || (csp->exp->nodetype == en_icon &&
		       csp->exp->v.i < 16 && csp->exp->v.i >= 0))
	return 0;
    if (lvalue(csp->exp))
	return 2 * csp->uses;
    return csp->uses;
}

int
bsort(list)
/*
 * bsort implements a bubble sort on the expression list.
 */
    struct cse    **list;
{
    struct cse     *csp1, *csp2;
    csp1 = *list;
    if (csp1 == 0 || csp1->next == 0)
	return;
    bsort(&(csp1->next));
    while (csp1 != 0 && (csp2 = csp1->next) != 0 && desire(csp1) < desire(csp2)) {
	*list = csp2;
	csp1->next = csp2->next;
	csp2->next = csp1;
	list = &(csp2->next);
    }
}

#ifdef MC680X0
allocate()
/*
 * allocate will allocate registers for the expressions that have a high
 * enough desirability.
 */
{
    struct cse     *csp;
    struct enode   *exptr;
    char            datareg, addreg;
    unsigned int    mask, rmask;
    struct amode   *ap, *ap2;
    regs_used = 0;
    datareg = MAX_DATA + 1;
    addreg = MAX_ADDR + 9;
    mask = 0;
    rmask = 0;
    bsort(&olist);		/* sort the expression list */
    csp = olist;
    while (csp != 0) {
/*
 * If reg_option is not true, the 'desire' value must be at least
 * 5000, which I hope can only be achieved by the 'register' attribute
 */
	if (desire(csp) < 3 || (!reg_option && desire(csp) < 5000))
	    csp->reg = -1;
	else if (csp->duses > (csp->uses / 3) && addreg < 14
	    /*
	     * integer constans may have different types
	     */
		 && csp->exp->nodetype != en_icon
	    /*
	     * the types which are fine in address registers
	     */
		 && (csp->exp->etype == bt_short ||
		     csp->exp->etype == bt_long ||
		     csp->exp->etype == bt_ulong ||
		     csp->exp->etype == bt_pointer))
	    csp->reg = addreg++;
	else if (datareg < 8)
	    csp->reg = datareg++;
	else
	    csp->reg = -1;
	if (csp->reg != -1) {
            regs_used++;
	    rmask = rmask | (1 << (15 - csp->reg));
	    mask = mask | (1 << csp->reg);
	}
	csp = csp->next;
    }
    if (mask != 0) {
	g_code(op_movem, 4, mk_rmask(rmask), &push);
#ifdef ICODE
	if (icode_option)
	    fprintf(icode, "\t$regpush %04x\n", rmask);
#endif
    }
    save_mask = mask;
    csp = olist;
    while (csp != 0) {
	if (csp->reg != -1) {	/* see if preload needed */
	    exptr = csp->exp;
	    if ((!lvalue(exptr)) || (exptr->v.p[0]->v.i > 0)) {
		initstack();
		ap = g_expr(exptr, F_ALL);
		ap2 = mk_reg(csp->reg);
		g_code(op_move, (int) exptr->esize, ap, ap2);
		freeop(ap);
#ifdef ICODE
		if (icode_option) {
		    fprintf(icode, "$reg ");
		    if (csp->reg < 8)
			fprintf(icode, "D%d\n", csp->reg);
		    else
			fprintf(icode, "A%d\n", csp->reg - 8);
		    g_icode(exptr);
		}
#endif
	    }
	}
	csp = csp->next;
    }
}
#endif
#ifdef INTEL_386
allocate()
/*
 * allocate will allocate registers for the expressions that have a high
 * enough desirability.
 */
{
    struct cse     *csp;
    struct enode   *exptr;
    struct amode   *ap, *ap2;
    int number_of_regs;
    int regs_to_use[3];
    int reg_use_ptr;
/*
 * On Sun386i, ebx gets clobbered calling Sun library functions --
 * cannot be used
 */
    if (uses_structassign) {
        number_of_regs = 1;
        regs_to_use[0] = EBX;
        ebx_used=0;
        esi_used=1;
        edi_used=1;
        regs_used=2;
    } else {
        number_of_regs = 3;
        regs_to_use[0] = EBX;
        regs_to_use[1] = EDI;
        regs_to_use[2] = ESI;
        regs_used = 0;
        ebx_used=esi_used=edi_used=0;
    }
    reg_use_ptr = 0;
    bsort(&olist);		/* sort the expression list */
    csp = olist;
    while (csp != 0) {
/*
 * If reg_option is not true, the 'desire' value must be at least
 * 5000, which I hope can only be achieved by the 'register' attribute
 */
	if (desire(csp) < 3 || (!reg_option && desire(csp) < 5000))
	    csp->reg = -1;
	else if (reg_use_ptr < number_of_regs
	    /*
	     * integer constans may have different types
	     */
		 && csp->exp->nodetype != en_icon
	    /*
	     * the types which are fine: one-byte quantities are illegal
             * in some of the registers, e.g. %edi and %esi
	     */
		 && (csp->exp->etype == bt_pointer ||
                     csp->exp->etype == bt_long    ||
                     csp->exp->etype == bt_ulong   ||
                     csp->exp->etype == bt_short   ||
                     csp->exp->etype == bt_ushort)) {
      
	    csp->reg = regs_to_use[reg_use_ptr++];
            regs_used++;
            switch (csp->reg) {
              case EBX:
                ebx_used = 1;
                break;
              case EDI:
                edi_used = 1;
                break;
              case ESI:
                esi_used = 1;
                break;
            }
        } else
	    csp->reg = -1;
	csp = csp->next;
    }
    if (ebx_used)
        g_code(op_push, 4, mk_reg(EBX), NIL_AMODE);
    if (edi_used)
        g_code(op_push, 4, mk_reg(EDI), NIL_AMODE);
    if (esi_used)
        g_code(op_push, 4, mk_reg(ESI), NIL_AMODE);
    csp = olist;
    while (csp != 0) {
	if (csp->reg != -1) {	/* see if preload needed */
	    exptr = csp->exp;
	    if ((!lvalue(exptr)) || (exptr->v.p[0]->v.i > 0)) {
		initstack();
		ap = g_expr(exptr, F_ALL);
		ap2 = mk_reg(csp->reg);
		g_code(op_mov, (int) exptr->esize, ap, ap2);
		freeop(ap);
	    }
	}
	csp = csp->next;
    }
}
#endif

repexpr(node)
/*
 * repexpr will replace all allocated references within an expression with
 * tempref nodes.
 */
    struct enode   *node;
{
    struct cse     *csp;
    if (node == 0)
	return;
    switch (node->nodetype) {
      case en_icon:
      case en_nacon:
      case en_labcon:
      case en_autocon:
	if ((csp = searchnode(node)) != 0) {
	    if (csp->reg > 0) {
		node->nodetype = en_tempref;
		node->v.i = csp->reg;
	    }
	}
	break;
      case en_ref:
      case en_fieldref:
	if ((csp = searchnode(node)) != 0) {
	    if (csp->reg > 0) {
		node->nodetype = en_tempref;
		node->v.i = csp->reg;
	    } else
		repexpr(node->v.p[0]);
	} else
	    repexpr(node->v.p[0]);
	break;
      case en_uminus:
      case en_not:
      case en_compl:
      case en_ainc:
      case en_adec:
      case en_cast:
      case en_deref:
	repexpr(node->v.p[0]);
	break;
      case en_add:
      case en_sub:
      case en_mul:
      case en_div:
      case en_mod:
      case en_lsh:
      case en_rsh:
      case en_and:
      case en_or:
      case en_xor:
      case en_land:
      case en_lor:
      case en_eq:
      case en_ne:
      case en_lt:
      case en_le:
      case en_gt:
      case en_ge:
      case en_cond:
      case en_void:
      case en_asadd:
      case en_assub:
      case en_asmul:
      case en_asdiv:
      case en_asor:
      case en_asxor:
      case en_asand:
      case en_asmod:
      case en_aslsh:
      case en_asrsh:
      case en_fcall:
      case en_assign:
	repexpr(node->v.p[0]);
	repexpr(node->v.p[1]);
	break;
    }
}

repcse(block)
/*
 * repcse will scan through a block of statements replacing the optimized
 * expressions with their temporary references.
 */
    struct snode   *block;
{
    while (block != 0) {
	switch (block->stype) {
	  case st_return:
	  case st_expr:
	    repexpr(block->exp);
	    break;
	  case st_while:
	  case st_do:
	    repexpr(block->exp);
	    repcse(block->s1);
	    break;
	  case st_for:
	    repexpr(block->exp);
	    repexpr(block->v1.e);
	    repcse(block->s1);
	    repexpr(block->v2.e);
	    break;
	  case st_if:
	    repexpr(block->exp);
	    repcse(block->s1);
	    repcse(block->v1.s);
	    break;
	  case st_switch:
	    repexpr(block->exp);
	    repcse(block->v1.s);
	    break;
	  case st_case:
	  case st_default:
	    repcse(block->v1.s);
	    break;
	  case st_compound:
	  case st_label:
	    repcse(block->s1);
	    break;
	}
	block = block->next;
    }
}

opt1(block)
/*
 * opt1 is the externally callable optimization routine. it will collect and
 * allocate common subexpressions and substitute the tempref for all
 * occurrances of the expression within the block.
 *
 */
    struct snode   *block;
{
    if (! opt_option)
        return;
    olist = 0;
    scan(block);		/* collect expressions */
    allocate();			/* allocate registers */
    repcse(block);		/* replace allocated expressions */
}
