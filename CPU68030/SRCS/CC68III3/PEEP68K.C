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

#ifdef MC680X0

static struct ocode *peep_head = 0;
static struct ocode *next_ip;

static enum e_op revcond[] = { op_bne, op_beq, op_bge, op_bgt, op_ble, op_blt,
			       op_bls, op_blo, op_bhs, op_bhi };

g_code(op, len, ap1, ap2)
/*
 * generate a code sequence into the peep list.
 */
    int             len;
    enum e_op       op;
    struct amode   *ap1, *ap2;
{
    struct ocode   *new;
    new = (struct ocode *) xalloc((int) sizeof(struct ocode));
    new->opcode = op;
    new->length = len;
    new->oper1 = ap1;
    new->oper2 = ap2;
    add_peep(new);
}

g_coder(op, len, ap1, ap2)
/*
 * generate a code sequence and put it in front of the list
 */
    int             len;
    enum e_op       op;
    struct amode   *ap1, *ap2;
{
    struct ocode   *new;
    new = (struct ocode *) xalloc((int) sizeof(struct ocode));
    new->opcode = op;
    new->length = len;
    new->oper1 = ap1;
    new->oper2 = ap2;
    if (peep_head == 0) {
	/* must use add_peep to take care of peep_tail */
	add_peep(new);
    } else {
        new->back  = 0;
        new->fwd   = peep_head;
	peep_head->back = new;
	peep_head  = new;
	/* peep_tail does not change */
    }
}

add_peep(new)
/*
 * add the ocoderuction pointed to by new to the peep list.
 */
    struct ocode   *new;
{
    static struct ocode *peep_tail;
    if (peep_head == 0) {
	peep_head = peep_tail = new;
	new->fwd = 0;
	new->back = 0;
    } else {
	new->fwd = 0;
	new->back = peep_tail;
	peep_tail->fwd = new;
	peep_tail = new;
    }
}

g_label(labno)
/*
 * add a compiler generated label to the peep list.
 */
    unsigned int    labno;
{
    struct ocode   *new;
    new = (struct ocode *) xalloc((int) sizeof(struct ocode));
    new->opcode = op_label;
    new->oper1 = mk_immed((long) labno);
    add_peep(new);
}

flush_peep()
/*
 * output all code and labels in the peep list.
 */
{
    register struct ocode *ip;
    opt3();			/* do the peephole optimizations */
    ip = peep_head;
    while (ip != 0) {
	if (ip->opcode == op_label)
	    put_label((unsigned int) ip->oper1->offset->v.i);
	else
	    put_code(ip->opcode, ip->length, ip->oper1, ip->oper2);
	ip = ip->fwd;
    }
    peep_head = 0;
}

static
peep_delete(ip)
/*
 * delete an instruction referenced by ip
 */
    struct ocode   *ip;
{
    if (ip == 0 || ip->back == 0)
	fatal("PEEP_DELETE");

    if ((ip->back->fwd = ip->fwd) != 0)
	ip->fwd->back = ip->back;

    next_ip = ip->back;
}

static
peep_pea(ip)
/*
 * changes lea <ea>,An + pea (An) to pea <ea>
 *  The value of An is not needed (An is scratch register)
 * CAVEAT code generator modifier!
 */
    struct ocode   *ip;
{
    struct ocode   *prev;
    if (ip->oper1->mode != am_ind)
	return;
    if ((prev = ip->back) == 0)
	return;
    if (prev->opcode == op_lea && prev->oper2->preg == ip->oper1->preg
	&& ip->oper1->preg <= MAX_ADDR) {
	prev->opcode = op_pea;
	prev->oper2 = 0;
	peep_delete(ip);
    }
}

static
peep_lea(ip)
/*
 * changes lea <ea>,An + move.l An,Am to lea <ea>,Am
 * The value of An is not needed (An scratch, Am typically tempref)
 * CAVEAT code generator modifier!
 */
    struct ocode   *ip;
{
    struct ocode   *next;
    if ((next = ip->fwd) == 0)
	return;
    if (next->opcode == op_move && ip->oper2->preg <= MAX_ADDR &&
	next->oper1->mode == am_areg && next->oper1->preg == ip->oper2->preg
	&& next->oper2->mode == am_areg && next->oper2->preg > MAX_ADDR) {
	ip->oper2 = next->oper2;
	peep_delete(ip->fwd);
    }
}

static
peep_move(ip)
/*
 * peephole optimization for move instructions.
 * makes quick immediates when possible (redundant for most assemblers).
 * changes move #0 to clr except on address registers
 * changes move #0 to address registers to sub An,An
 * changes long moves to address registers to short when possible.
 * changes move immediate to stack to pea.
 * changes move immediate to An	to lea.
 * deletes move <ea>,<ea> (The code generator does not know that this sets
 *			   the flags, and it is necessary for peep_and
 *			   to work correctly if ea is am_dreg)
 */
    struct ocode   *ip;
{
    struct enode   *ep;

    if (equal_address(ip->oper1, ip->oper2) &&
/*
 * move.w An,An changes the contents of An through sign extension
 */
       (ip->oper1->mode != am_areg || ip->length != 2)) {
	peep_delete(ip);
	return;
    }
    if (ip->oper1->mode != am_immed)
	return;

    ep = ip->oper1->offset;
    if (ip->oper2->mode == am_areg && ep->nodetype == en_icon) {
	if (ep->v.i == 0) {
	    ip->length = 4;
	    ip->opcode = op_sub;
	    ip->oper1 = ip->oper2;
	} else if (-32768 <= ep->v.i && ep->v.i <= 32767)
	    ip->length = 2;
	return;
    }
    if (ip->oper2->mode == am_dreg && ep->nodetype == en_icon
	&& -128 <= ep->v.i && ep->v.i <= 127) {
	ip->opcode = op_moveq;
	ip->length = 0;
	return;
    }
    if (ep->nodetype == en_icon && ep->v.i == 0) {
#ifdef MC68000
        /*
         * The M68000 reads the operand to be cleared.
         * This is unsafe e.g. when manipulating interface
         * registers, and clr is not too fast for this reason
         * clr.x Dn is still attractive (and safe)
         *
         * I heard rumours that M68010, M68020 etc. do not have
         * this bug
         */
        if (ip->oper2->mode != am_dreg)
            return;
#endif /* MC68000 */
	ip->opcode = op_clr;
	ip->oper1 = ip->oper2;
	ip->oper2 = 0;
	return;
    }
    if (ip->oper2->mode == am_adec && ip->oper2->preg == 7
	&& ip->length == 4) {
	ip->opcode = op_pea;
	ip->length = 0;
	ip->oper1 = copy_addr(ip->oper1);
	ip->oper1->mode = am_direct;
	ip->oper2 = 0;
	return;
    }
    if (ip->oper2->mode == am_areg && ip->length == 4) {
	ip->opcode = op_lea;
	ip->length = 0;
	ip->oper1 = copy_addr(ip->oper1);
	ip->oper1->mode = am_direct;
	return;
    }
}

int
equal_address(ap1, ap2)
/*
 * compare two address nodes and return true if they are equivalent.
 */
    struct amode   *ap1, *ap2;
{
    if (ap1 == 0 || ap2 == 0)
	return 0;
    if (ap1->mode != ap2->mode)
	return 0;
    switch (ap1->mode) {
      case am_areg:
      case am_dreg:
      case am_ind:
	return ap1->preg == ap2->preg;
      case am_indx:
	return ap1->preg == ap2->preg &&
               ap1->offset->nodetype == en_icon &&
               ap2->offset->nodetype == en_icon &&
	       ap1->offset->v.i == ap2->offset->v.i;
      case am_indx2:
      case am_indx3:
	return
	    ap1->preg == ap2->preg &&
	    ap1->sreg == ap2->sreg &&
            ap1->offset->nodetype == en_icon &&
            ap2->offset->nodetype == en_icon &&
	    ap1->offset->v.i == ap2->offset->v.i;
    }
    return 0;
}

static
peep_movem(ip)
/*
 * peephole optimization for movem instructions. movem instructions are used
 * to save registers on the stack. if only one register is being saved we
 * can convert the movem to a move instruction.
 *
 */
    struct ocode   *ip;
{
    register int i,mask;

    if (ip->oper1->mode == am_mask1)
	mask = ip->oper1->offset->v.i;
    else mask = ip->oper2->offset->v.i;

    for (i = 15; i >= 0; i--)
	if (mask == (1 << i)) {
	    if (ip->oper1->mode == am_mask1) {
		if ((ip->oper1->preg = 15 - i) >= 8) {
		    ip->oper1->mode = am_areg;
		    ip->oper1->preg -= 8;
		} else ip->oper1->mode = am_dreg;
	    } else {
		if ((ip->oper2->preg = i) >= 8) {
		    ip->oper2->mode = am_areg;
		    ip->oper2->preg -= 8;
		} else ip->oper2->mode = am_dreg;
	    }
	    ip->opcode = op_move;
	    break;
	}
}

static
peep_add(ip)
/*
 * peephole optimization for add instructions.
 * makes quick immediates out of small constants (redundant for most as's).
 * change add immediate to address registers to lea where possible
 */
    struct ocode   *ip;
{
    struct enode   *ep;
    if (ip->oper1->mode != am_immed)
	return;
    ep = ip->oper1->offset;
    if (ip->oper2->mode != am_areg)
	ip->opcode = op_addi;
    if (ep->nodetype != en_icon)
	return;
    if (1 <= ep->v.i && ep->v.i <= 8) {
	ip->opcode = op_addq;
	return;
    }
    if (-8 <= ep->v.i && ep->v.i <= -1) {
	ip->opcode = op_subq;
	ep->v.i = -ep->v.i;
	return;
    }
    if (ip->oper2->mode == am_areg && isshort(ep)) {
	ip->oper1 = copy_addr(ip->oper1);
	ip->oper1->mode = am_indx;
	ip->oper1->preg = ip->oper2->preg;
	ip->length = 0;
	ip->opcode = op_lea;
	return;
    }
}

static
peep_and(ip)
/*
 * conversion of unsigned data types often yields statements like
 * move.b source,d0 +  andi.l #255,d0
 * which should be converted to
 * clr.l d0 + move.b source,d0
 * deletes and #-1
 */
    struct ocode   *ip;
{
    struct ocode   *prev;
    int             size;
    long            arg;
    if (ip->oper1->mode != am_immed ||
	ip->oper1->offset->nodetype != en_icon)
	return;
    arg = ip->oper1->offset->v.i;
    /*
     * and #-1 does only set flags, which the code generator does not know
     */
    if (arg == -1) {
	peep_delete(ip);
	return;
    }
    if (ip->oper1->mode != am_immed ||
	(arg != 255 && arg != 65535))
	return;

    size = (arg == 255) ? 1 : 2;

    if ((prev = ip->back) == 0 || prev->length != size
	|| prev->opcode != op_move
	|| ip->oper2->mode != am_dreg || prev->oper2->mode != am_dreg
	|| ip->oper2->preg != prev->oper2->preg
        ||      (prev->oper1->mode == am_indx2 &&
                 prev->oper1->sreg == prev->oper2->preg)
        )
	return;

    prev->length = ip->length;
    ip->length = size;
    prev->opcode = op_clr;
    ip->opcode = op_move;
    ip->oper1 = prev->oper1;
    prev->oper1 = prev->oper2;
    prev->oper2 = 0;

    next_ip = prev;
}

static
peep_clr(ip)
/*
 * removes consecutive clr-statements
 *
 */
    struct ocode   *ip;
{
    struct ocode   *prev;

    if ((prev = ip->back) == 0 || prev->opcode != op_clr ||
	!equal_address(ip->oper1, prev->oper1))
	return;

    if (prev->length < ip->length)
	prev->length = ip->length;

    peep_delete(ip);
}

static
peep_sub(ip)
/*
 * peephole optimization for subtract instructions.
 * makes quick immediates out of small constants (redundant for most as's).
 */
    struct ocode   *ip;
{
    struct enode   *ep;
    if (ip->oper1->mode != am_immed)
	return;
    ep = ip->oper1->offset;
    if (ip->oper2->mode != am_areg)
	ip->opcode = op_subi;
    else {
	if (isshort(ep))
	    ip->length = 2;
    }
    if (ep->nodetype != en_icon)
	return;
    if (1 <= ep->v.i && ep->v.i <= 8)
	ip->opcode = op_subq;
    else if (-8 <= ep->v.i && ep->v.i <= -1) {
	ip->opcode = op_addq;
	ep->v.i = -ep->v.i;
    }
}

static
peep_cmp(ip)
/*
 * peephole optimization for compare instructions.
 * changes compare #0 to tst
 *
 */
    struct ocode   *ip;
{
    struct enode   *ep;
    if (ip->oper1->mode != am_immed)
	return;
    ep = ip->oper1->offset;
    if (ip->oper2->mode == am_areg)
	/* cmpa.w extents the first argument automatically */
    {
	if (isshort(ep))
	    ip->length = 2;
	return;
    }
    ip->opcode = op_cmpi;
    if (ep->nodetype != en_icon || ep->v.i != 0)
	return;
    ip->oper1 = ip->oper2;
    ip->oper2 = 0;
    ip->opcode = op_tst;
    next_ip = ip;
}

static
peep_tst(ip)
/*
 * deletes a tst instruction if the flags are already set.
 */
    struct ocode   *ip;
{
    struct ocode   *prev;
    prev = ip->back;
    if (prev == 0)
	return;
/*
 * All the following cases used to be checked with an obscure
 * if-statement. There was an error in it that caused prev->oper2->mode
 * to be referenced even if prev->opcode is op_clr. (This yields a NIL-
 * pointer reference.
 * I threw all this stuff away and replaced it by this case-statement.
 * This is much more readable.
 */
    switch (prev->opcode) {
        case op_label:
/*
 * List all pseudo-instructions here. Of course, they do not do
 * anything.
 */
            return;

        case op_move:
/*
 * A move TO an address register does not set the flags
 */
            if (prev->oper2->mode == am_areg)
                return;
        case op_moveq:
        case op_clr:
/*
 * All other move an clr instructions set the flags according to
 * the moved operand, which is prev->oper1
 */
            if (equal_address(prev->oper1, ip->oper1))
                break;
        default:
/*
 * All instructions that have a target set the flags according to the
 * target (prev->oper2)
 * Note that equal_address may be called with a NIL pointer
 */
            if (equal_address(prev->oper2, ip->oper1))
                break;
            return;
    }
/*
 * We come here if the flags are already set, thus the tst
 * instruction can be deleted.
 */
    peep_delete(ip);
}

static
peep_uctran(ip)
/*
 * peephole optimization for unconditional transfers. deletes instructions
 * which have no path. applies to bra, jmp, and rts instructions.
 */
    struct ocode   *ip;
{
    while (ip->fwd != 0 && ip->fwd->opcode != op_label)
	peep_delete(ip->fwd);
}

static
peep_bxx(ip)
/*
 * optimizes conditional branch over a bra.
 */
    struct ocode   *ip;
{
    struct ocode   *next = ip->fwd;
    if (next == 0)
	return;
    if (next->opcode == op_bra) {
       /* peep_uctran increases the 'hit' probability */
        peep_uctran(next);
	next = next->fwd;
	if (next == 0)
	    return;
	if (next->opcode == op_label &&
	    ip->oper1->offset->v.i == next->oper1->offset->v.i) {
	    ip->fwd->opcode = revcond[(int)ip->opcode - (int)op_beq];
	    peep_delete(ip);
	}
    }
}

static
peep_label(ip)
/*
 * if a label is followed by a branch to another label, the
 * branch statement can be deleted when the label is moved
 */
    struct ocode   *ip;
{
    struct ocode   *prev, *next, *target;
    long            label;
    prev = ip->back;
    if ((next = ip->fwd) == 0 || next->opcode != op_bra)
	return;
    /*
     * To make this fast, assume that the label number is really
     * next->oper1->offset->v.i
     */
    label = next->oper1->offset->v.i;
    if (label == ip->oper1->offset->v.i)
	return;
    target = peep_head;
    /*
     * look for the label
     */
    while (target != 0) {
	if (target->opcode == op_label
	    && target->oper1->offset->v.i == label)
	    break;
	target = target->fwd;
    }
    /* we should have found it */
    if (target == 0) {
       fprintf(stderr,"INCONSISTENCY: PEEP_LABEL (FATAL?)\n");
       return;
    }
    /* move label */
    peep_delete(ip);
    ip->fwd = target->fwd;
    ip->back = target;
    target->fwd = ip;
    if (ip->fwd != 0)
	ip->fwd->back = ip;
    /* possibly remove branches */
    /* in fact, prev is always != 0 if peep_delete has succeeded */
    if (prev != 0) {
	if (prev->opcode == op_bra || prev->opcode == op_jmp
	    || prev->opcode == op_rts)
	    peep_uctran(prev);
    }
}



opt3()
/*
 * peephole optimizer. This routine calls the instruction specific
 * optimization routines above for each instruction in the peep list.
 */
{
    struct ocode   *ip;
    next_ip = peep_head;
    if (! opt_option)
        return;
    while (next_ip != 0) {
	ip = next_ip;
	next_ip = ip->fwd;
	switch (ip->opcode) {
	  case op_move:
	    peep_move(ip);
	    break;
          case op_movem:
	    peep_movem(ip);
            break;
	  case op_pea:
	    peep_pea(ip);
	    break;
	  case op_lea:
	    peep_lea(ip);
	    break;
	  case op_add:
	    peep_add(ip);
	    break;
	  case op_and:
	    peep_and(ip);
	    break;
	  case op_clr:
	    peep_clr(ip);
	    break;
	  case op_sub:
	    peep_sub(ip);
	    break;
	  case op_cmp:
	    peep_cmp(ip);
	    break;
	  case op_tst:
	    peep_tst(ip);
	    break;
	  case op_beq:
	  case op_bne:
	  case op_bgt:
	  case op_bge:
	  case op_blt:
	  case op_bls:
	  case op_blo:
	  case op_bhi:
	  case op_bhs:
	    peep_bxx(ip);
	    break;
	  case op_bra:
	    /* delete branches to the following statement */
	    {
		struct ocode   *p = ip->fwd;
		long            label = ip->oper1->offset->v.i;
		while (p != 0 && p->opcode == op_label) {
		    if (p->oper1->offset->v.i == label) {
			peep_delete(ip);
                        ip = 0;
			break;
		    }
		    p = p->fwd;
		}
	    }
            if (ip == 0)
                break;
	    /* FALLTHROUGH */
	  case op_jmp:
	  case op_rts:
	    peep_uctran(ip);
	    break;
	  case op_label:
	    peep_label(ip);
	    break;
	}
    }
}
#endif /* MC680X0 */
