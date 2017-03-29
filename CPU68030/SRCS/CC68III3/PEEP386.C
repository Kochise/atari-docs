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

#ifdef INTEL_386

static struct ocode *peep_head = 0;
static struct ocode *next_ip;

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
/*
 * perform peephole optimizations
 */
    opt3();
/*
 * generate assembler output
 */
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
    if (ap1->mode == am_reg && ap1->preg == ap2->preg)
        return 1;
    if (ap1->mode == am_fpstack)
        return 1;
    if (ap1->mode == am_indx && ap1->preg == EBP &&
        ap2->preg == EBP && ap1->offset->nodetype == en_icon && 
        ap2->offset->nodetype == en_icon &&
        ap1->offset->v.i == ap2->offset->v.i)
             return 1;
    return 0;
}

static
peep_mov(ip)
/*
 * delete mov src,src
 *
 * change mov src,dest
 *        mov dest,src
 *                            to mov src,dest
 *
 * change mov $0, reg to xor reg,reg
 */
    struct ocode *ip;
{
    struct ocode *prev;

    if (equal_address(ip->oper1, ip->oper2)) {

        peep_delete(ip);
        return;
    }
    if (ip->oper1->mode == am_immed
        && ip->oper2->mode == am_reg
        && ip->oper1->offset->nodetype == en_icon
        && ip->oper1->offset->v.i == 0) {
        ip->oper1 = ip->oper2;
        ip->opcode = op_xor;
        return;
    }
    if ((prev = ip->back) == 0) return;
/*
 * think about
 *
 * movl (%eax),eax         I will make equal_address very restrictive!
 * movl eax,(%eax)
 *
 */
    if (prev->opcode == op_mov && prev->length == ip->length &&
        equal_address(prev->oper1,ip->oper2) &&
        equal_address(prev->oper2,ip->oper1)){
            peep_delete(ip);
            return;
    }
}

static
peep_cmp(ip)
/*
 * changes cmp $0,reg to test reg,reg if followed by je, jne, jg, jge, jl, jle
 */
    struct ocode *ip;
{
    struct ocode *next;

    if (ip->oper1->mode == am_immed &&
        ip->oper1->offset->nodetype == en_icon &&
        ip->oper1->offset->v.i == 0 &&
        ip->oper2->mode == am_reg &&
        (next=ip->fwd) != 0)
        switch (next->opcode) {
          case op_je:
          case op_jne:
          case op_jg:
          case op_jge:
          case op_jl:
          case op_jle:
            ip->opcode = op_test;
            ip->oper1 = ip->oper2;
        }
}

static
peep_xtend(ip)
/*
 * changes things like
 *
 * movw src,%ax
 * movzwl %ax,%eax
 *
 * to
 *
 * movzwl src,%eax
 *
 * DO NOT DESTRUCT
 * movw %di,%ax
 * movzbl %al,%eax
 * since %di,%si have no byte-components.
 */
    struct ocode   *ip;
{
    struct ocode   *prev = ip->back;
    int size;

    if (prev != 0 && prev->opcode == op_mov &&
        equal_address(prev->oper2, ip->oper1) &&
        equal_address(ip->oper1, ip->oper2)) {
            if (prev->oper1->mode == am_reg &&
               (prev->oper1->preg == ESI || prev->oper1->preg == EDI))
                   return;
            ip->oper1 = prev->oper1;
            peep_delete(prev);
    }
/*
 * the code generator, or this procedure, may generate code like
 *
 * movsbl $const, %reg
 *
 * this is not a legal instruction.
 * we will change it to a mov instruction here
 */
    if (ip->oper1->mode != am_immed)
        return;
    if (ip->opcode == op_movsbw || ip->opcode == op_movzbw)
        size = 2;
    else
        size = 4;
    ip->length=size;
    ip->opcode = op_mov;
}

static
peep_addsub(ip,flag)
struct ocode *ip;
long flag;
/*
 * changes add $1 to inc, add $-1 to dec, sub $1 to dec, sub $-1 to inc
 */
{
if (ip->oper1->mode != am_immed || ip->oper1->offset->nodetype != en_icon)
   return;
flag *= ip->oper1->offset->v.i;
if (flag == 1l) {
    ip->opcode = op_inc;
    ip->oper1 = ip->oper2;
    ip->oper2 = 0;
} else if (flag == -1l) {
    ip->opcode = op_dec;
    ip->oper1 = ip->oper2;
    ip->oper2 = 0;
}
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
    static enum e_op revcond[] = { op_jne, op_je,
                                   op_jge, op_jg, op_jle, op_jl,
                                   op_jbe, op_jb, op_jae, op_ja };
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
	    ip->fwd->opcode = revcond[(int)ip->opcode - (int)op_je];
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
	    || prev->opcode == op_ret)
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
    while (next_ip != 0) {
	ip = next_ip;
	next_ip = ip->fwd;
	switch (ip->opcode) {
          case op_movzbw:
          case op_movsbw:
          case op_movzbl:
          case op_movsbl:
          case op_movzwl:
          case op_movswl:
            peep_xtend(ip);
            break;
          case op_mov:
            peep_mov(ip);
            break;
          case op_add:
            peep_addsub(ip,1l);
            break;
          case op_sub:
            peep_addsub(ip,-1l);
            break;
          case op_cmp:
            peep_cmp(ip);
            break;
	  case op_je:
	  case op_jne:
	  case op_jg:
	  case op_jge:
          case op_jle:
	  case op_jl:
	  case op_ja:
          case op_jae:
          case op_jbe:
          case op_jb:
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
                        ip=0;
			break;
		    }
		    p = p->fwd;
		}
	    }
            if (ip == 0)
               break;
	    /* FALLTHROUGH */
	  case op_jmp:
	  case op_ret:
	    peep_uctran(ip);
	    break;
	  case op_label:
	    peep_label(ip);
	    break;
	}
    }
}
#endif /* INTEL_386 */
