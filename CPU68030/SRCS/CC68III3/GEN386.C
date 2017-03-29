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
 * this module contains all of the code generation routines for evaluating
 * expressions and conditions.
 */

#ifdef INTEL_386

struct amode fp_stack = {am_fpstack, 0,   0, 0,0};
struct amode ecx_reg =  {am_reg,     0, ECX, 0,0};
struct amode edi_reg =  {am_reg,     0, EDI, 0,0};
struct amode esi_reg =  {am_reg,     0, ESI, 0,0};
struct amode cl_reg  =  {am_reg,     0,  CL, 0,0};
struct amode esp_reg =  {am_reg,     0, ESP, 0,0};
struct amode eax_reg =  {am_reg,     0, EAX, 0,0};
struct amode  ax_reg =  {am_reg,     0,  AX, 0,0};
struct amode edx_reg =  {am_reg,     0, EDX, 0,0};

extern int reg_in_use[];

struct amode   *
mk_scratch(size)
/*
 * returns addressing mode of form offset(FRAMEPTR)
 * size is rounded up to AL_DEFAULT
 */
    long            size;
{
    struct amode   *ap;
    if (size % AL_DEFAULT)
        size += AL_DEFAULT - (size % AL_DEFAULT);
    act_scratch += size;
    if (act_scratch > max_scratch)
        max_scratch = act_scratch;
    ap = (struct amode *) xalloc((int) sizeof(struct amode));
    ap->mode = am_indx;
    ap->preg = FRAMEPTR;
    ap->offset = mk_icon(-(lc_auto+act_scratch));
    return ap;
}

struct amode   *
mk_label(lab)
/*
 * construct a reference node for an internal label number.
 */
    unsigned int    lab;
{
    struct enode   *lnode;
    struct amode   *ap;
    lnode = mk_node(en_labcon, NIL_ENODE, NIL_ENODE);
    lnode->v.i = lab;
    ap = (struct amode *) xalloc((int) sizeof(struct amode));
    ap->mode = am_direct;
    ap->offset = lnode;
    return ap;
}

struct amode   *
mk_immed(i)
/*
 * make a node to reference an immediate value i.
 */
    long            i;
{
    struct amode   *ap;
    struct enode   *ep;
    ep = mk_icon(0l);
    ep->v.i = i;
    ap = (struct amode *) xalloc((int) sizeof(struct amode));
    ap->mode = am_immed;
    ap->offset = ep;
    return ap;
}

struct amode   *
mk_offset(node)
/*
 * make a direct reference to a node.
 */
    struct enode   *node;
{
    struct amode   *ap;
    ap = (struct amode *) xalloc((int) sizeof(struct amode));
    ap->mode = am_direct;
    ap->offset = node;
    return ap;
}

struct amode   *
mk_legal(ap, flags, size)
/*
 * mk_legal will coerce the addressing mode in ap1 into a mode that is
 * satisfactory for the flag word.
 */
    struct amode   *ap;
    int             flags;
    long	    size;
{
    struct amode   *ap2;

    if (flags & F_NOVALUE) {
        /* ap == 0 is allowed in these cases */
        freeop(ap);
        maybe_fppop(ap);
	return 0;
    }
    if (ap == 0)
        fatal("MK_LEGAL: AP == 0");

	switch (ap->mode) {
	  case am_immed:
	    if (flags & F_IMMED)
		return ap;	/* mode ok */
            break;
	  case am_reg:
            if (flags & F_REG) {
                if ((flags & F_NOEDI) && (ap->preg == EDI || ap->preg == ESI))
                    break;
                if ((flags & F_VOL) && ap->preg > MAX_REG)
                    break;
		return ap;
            }
            break;
          case am_indx:
          case am_indx2:
          case am_direct:
	    if (flags & F_MEM)
		return ap;
            if (flags & F_FPSTACK) {
                if (fpu_option)
                    g_code(op_fld, 1+ (int) size, ap, NIL_AMODE);
                else {
                    g_code(op_lea, 4, ap, &ecx_reg, NIL_AMODE);
                    call_library(size == 4 ? ".fplds" : ".fpldl");
/*
 * LIBRARY fplds, fpldl
 *
 * loads single or double precision FP value on stack
 * a pointer to the FP value is in %ecx
 * except %ecx, no registers may be clobbered
 */
                }
                freeop(ap);
                return &fp_stack;
            }
            break;
          case am_fpstack:
            if (flags & F_FPSTACK)
                return ap;
            /* else fall through */
          default:
            fatal("MK_LEGAL: MODE");
	}
    if (! (flags & F_REG))
	fatal ("MK_LEGAL: NOT A REGISTER");
    freeop (ap); /* maybe we can use it */
    ap2 = get_register();
/*
 * byte transfers from %edi/%esi to a scratch register come up here
 */
    if (ap->mode == am_reg && (ap->preg == ESI || ap->preg == EDI)
                           && size == 1)
        size = 2;
    g_code (op_mov, (int) size, ap, ap2);
    return ap2;
}


struct amode   *
copy_addr(ap)
/*
 * copy an address mode structure.
 */
    struct amode   *ap;
{
    struct amode   *newap;
    if (ap == 0)
	return 0;
    newap = (struct amode *) xalloc((int) sizeof(struct amode));
    *newap = *ap;
    return newap;
}


struct enode *
mk_add(ep1,ep2)
/*
 * generates added offsets.
 * ep1, or ep2, or both may be NULL, representing zero offsets
 */
    struct enode *ep1,*ep2;
{
    if (ep1 == 0)
        return ep2;
    if (ep2 == 0)
        return ep1;
    if (ep1->nodetype == en_icon && ep2->nodetype == en_icon) {
        ep1->v.i += ep2->v.i;
        return ep1;
    }
    return mk_node(en_add,ep1,ep2);
}

struct amode   *
g_deref(node, type)
/*
 * return the addressing mode of a dereferenced node.
 */
    struct enode   *node;
    enum e_bt	    type;
{
    struct amode   *ap1, *ap2, *ap3;
    switch (type) {
      case bt_uchar:
      case bt_char:
      case bt_ushort:
      case bt_short:
      case bt_ulong:
      case bt_long:
      case bt_pointer:
      case bt_float:
      case bt_double:
        if (tst_const(node)) {
           ap1 = (struct amode *) xalloc((int) sizeof(struct amode));
           ap1->mode = am_direct;
           ap1->offset = node;
           return ap1;
        }
        if (node->nodetype == en_add) {
/*
 * this is the g_index stuff...
 */
            ap2=g_deref(node->v.p[0], type);
            if (ap2->mode == am_direct) {
                ap1=ap2;
                ap2=g_deref(node->v.p[1], type);
            } else {
                ap1=g_deref(node->v.p[1], type);
                validate(ap2);
            }
/*
 * possible combinations:
 *
 * ap1->mode     ap2->mode  reduction
 * direct        direct     direct
 * direct        indx       indx
 * direct        indx2      indx2
 * indx          indx       indx2, or g_code+indx
 * indx2         indx       g_code + indx
 * indx          indx2      g_code + indx
 * indx2         indx2      g_code + g_code + indx2
 */
            if (ap1->mode == am_direct && ap2->mode == am_direct) {
                ap2->offset = mk_add(ap1->offset, ap2->offset);
                return ap2;
            }
            if (ap1->mode == am_direct &&
                (ap2->mode == am_indx || ap2->mode == am_indx2)) {
                if (ap2->offset == 0)
                    ap2->offset = ap1->offset;
                else
                    ap2->offset = mk_add(ap1->offset,ap2->offset);
                return ap2;
            }
            if (ap1->mode == am_indx && ap2->mode == am_indx) {
                if (uses_temp(ap2) && uses_temp(ap1)) {
                    g_code(op_add, 4, mk_reg(ap1->preg), mk_reg(ap2->preg));
                    ap2->offset=mk_add(ap1->offset,ap2->offset);
                    freeop(ap1);
                    return ap2;
                }
                if (uses_temp(ap2)) {
                    ap2 = copy_addr(ap2);
                    ap2->sreg = ap2->preg;
                    ap2->mode = am_indx2;
                    ap2->preg = ap1->preg;
                    ap2->offset=mk_add(ap1->offset,ap2->offset);
                    return ap2;
                }
                if (uses_temp(ap1)) {
                    ap1 = copy_addr(ap1);
                    ap1->sreg = ap1->preg;
                    ap1->mode = am_indx2;
                    ap1->preg = ap2->preg;
                    ap1->offset=mk_add(ap1->offset,ap2->offset);
                    return ap1;
                }
                /* do not create (%esi,%edi etc) */
                ap3 = get_register();
                g_code(op_mov, 4, mk_reg(ap1->preg), ap3);
                g_code(op_add, 4, mk_reg(ap2->preg), ap3);
                ap3 = copy_addr(ap3);
                ap3->mode = am_indx;
                ap3->offset=mk_add(ap1->offset,ap2->offset);
                return ap3;
            }
            if (ap1->mode == am_indx2 && ap2->mode == am_indx) {
                if (uses_temp(ap2)) {
                    ap2=copy_addr(ap2);
                    freeop(ap1);
                    g_code(op_add, 4, mk_reg(ap1->sreg), mk_reg(ap2->preg));
                    ap2->sreg = ap2->preg;
                    ap2->preg = ap1->preg;
                    ap2->mode = am_indx2;
                    ap2->offset=mk_add(ap1->offset,ap2->offset);
                    return ap2;
                }
                g_code(op_mov, 4, mk_reg(ap2->preg), mk_reg(ap1->sreg));
                ap1->offset=mk_add(ap1->offset,ap2->offset);
                return ap1;
            }
            if (ap1->mode == am_indx && ap2->mode == am_indx2) {
                freeop(ap1);
                g_code(op_add, 4, mk_reg(ap1->preg), mk_reg(ap2->sreg));
                ap1->offset=mk_add(ap1->offset,ap2->offset);
                return ap2;
            }
            if (ap1->mode == am_indx2 && ap2->mode == am_indx2) {
                freeop(ap1);
                ap3 = mk_reg(ap2->sreg);
                g_code(op_add, 4, mk_reg(ap1->preg), ap3);
                g_code(op_add, 4, mk_reg(ap1->sreg), ap3);
                ap2->offset=mk_add(ap1->offset,ap2->offset);
                return ap2;
            }
            fatal ("G_DEREF COMBINE");                
        } /* end of g_index stuff */

        if (node->nodetype == en_autocon) {
          ap1 = (struct amode *) xalloc((int) sizeof(struct amode));
          ap1->mode = am_indx;
          ap1->preg = FRAMEPTR;
	  ap1->offset = mk_icon((long) node->v.i);
	  return ap1;
        }
        ap1 = g_expr(node, F_REG | F_IMMED);
        ap1 = copy_addr(ap1);
        if (ap1->mode == am_immed) {
	    ap1->mode = am_direct;
	    return ap1;
        }
        ap1->mode = am_indx;
        ap1->offset = 0;
        return ap1;
      case bt_struct:
      case bt_union:
        /* return a pointer to the struct rather than the struct itself */
        return g_expr(node, F_ALL);
    }
    fatal ("g_deref: illegal type");
    /*NOTREACHED*/
}

struct amode *
g_fderef(node, flags)
    struct enode   *node;
    int             flags;
/*
 * get a bitfield value
 */
{
    struct amode   *ap;
    long            mask;
    int             width = node->bit_width + 1;

    ap = g_deref(node->v.p[0], node->etype);
    ap = mk_legal(ap, F_REG | F_VOL, node->esize);
    if (node->bit_offset > 0)
	g_code(op_shr, (int) node->esize,
		   mk_immed((long) node->bit_offset), ap);
    mask = 0;
    while (--width)
	mask = mask + mask + 1;
    g_code(op_and, (int) node->esize, mk_immed(mask), ap);

    return mk_legal(ap, flags, node->esize);
}

struct amode   *
g_unary(node, flags, op)
/*
 * generate code to evaluate a unary minus or complement.
 */
    struct enode   *node;
    int             flags;
    enum e_op       op;
{
    struct amode   *ap;
    switch (node->etype) {
      case bt_uchar:
      case bt_char:
      case bt_short:
      case bt_ushort:
      case bt_long:
      case bt_ulong:
      case bt_pointer:
	ap = g_expr(node->v.p[0], F_REG | F_VOL);
	g_code(op, (int) node->esize, ap, NIL_AMODE);
	return mk_legal(ap, flags, node->esize);
      case bt_float:
      case bt_double:
        if (op != op_neg)
            fatal("g_unary illegal operation");
        (void) g_expr(node->v.p[0], F_FPSTACK);
        if (fpu_option)
	    g_code(op_fchs, 0, NIL_AMODE, NIL_AMODE);
        else
            call_library(".fpneg");
/*
 * LIBRARY fpneg
 * negates the number on top of the FP stack
 * only %ecx may be clobbered
 */
        return mk_legal(&fp_stack, flags, 8l);
    }
    fatal("g_unary: illegal type or operation");
    /* NOTREACHED */
}

struct amode   *
g_bin(node, flags, op)
/*
 * generate code to evaluate a binary node and return the addressing mode of
 * the result.
 */
    struct enode   *node;
    int             flags;
    enum e_op       op;
{
    struct amode   *ap1, *ap2;
    int f=F_ALL;
    switch (node->etype) {
      case bt_uchar:
      case bt_char:
        f |= F_NOEDI;
      case bt_short:
      case bt_ushort:
      case bt_long:
      case bt_ulong:
      case bt_pointer:
	ap1 = g_expr(node->v.p[0], F_REG | F_VOL);
	ap2 = g_expr(node->v.p[1], f);
	validate(ap1);
	g_code(op, (int) node->esize, ap2, ap1);
	freeop(ap2);
	return mk_legal(ap1, flags, node->esize);
      case bt_float:
      case bt_double:
        if (fpu_option) {
            ap1 = g_expr(node->v.p[0], F_MEM | F_FPSTACK);
            if (ap1->mode == am_fpstack) {
		ap1 = mk_scratch(8l);
		g_code(op_fstp, 9, ap1, NIL_AMODE);
	    }
            (void) g_expr(node->v.p[1], F_FPSTACK);
	    validate(ap1);
	    freeop(ap1);
            switch (op) {
              case op_add:
                g_code(op_fadd, 9, ap1, NIL_AMODE);
                break;
              case op_sub:
                g_code(op_fsubr,9, ap1, NIL_AMODE);
                break;
              case op_imul:
                g_code(op_fmul, 9, ap1, NIL_AMODE);
                break;
              case op_idiv:
                g_code(op_fdivr,9, ap1, NIL_AMODE);
                break;
              default:
                fatal("G_BIN ILLEGAL OP");
            }
	} else {
            (void) g_expr(node->v.p[0], F_FPSTACK);
            (void) g_expr(node->v.p[1], F_FPSTACK);
            switch (op) {
/*
 * LIBRARY fpadd fpsub fpmult fpdiv
 * if the top elements of the FP stack are a b .....
 * the stack is c ..... after this call, where
 * c = b+a, b-a, b/a, or b*a
 *
 * only %ecx may be clobbered
 */
              case op_add:
                call_library(".fpadd");
                break;
              case op_sub:
                call_library(".fpsubr");
                break;
              case op_imul:
                call_library(".fpmult");
                break;
              case op_idiv:
                call_library(".fpdivr");
                break;
              default:
                fatal("G_BIN ILLEGAL OP");
           }
	}
        return 	mk_legal(&fp_stack, flags, 8l);
    }

    fatal("g_bin illegal type");
    /* NOTREACHED */
}

struct amode   *
g_aincdec(node, flags, op)
/*
 * generate code to evaluate a autoincrement/autodecrement node
 */
    struct enode   *node;
    int             flags;
    enum e_op       op;
{
    struct amode   *ap1, *ap2;
    switch (node->etype) {
      case bt_uchar:
      case bt_char:
      case bt_short:
      case bt_ushort:
      case bt_long:
      case bt_ulong:
      case bt_pointer:
        if (!(flags & F_NOVALUE))
            ap1 = get_register();
        else
            ap1 = 0;
	ap2 = g_expr(node->v.p[0], F_MEM | F_REG);
        if (ap1) {
	    validate(ap1);
            g_code(op_mov, (int) node->esize, ap2, ap1);
        }
        g_code(op, (int) node->esize, mk_immed(node->v.p[1]->v.i), ap2);
	freeop(ap2);
        if (ap1)
            ap1 = mk_legal(ap1, flags, node->esize);
        return ap1;
    }

    fatal("g_aincdec illegal type");
    /* NOTREACHED */
}

struct amode *
g_asbin (node, flags, op)
/*
 * generate code to evaluate a binary as-node
 * the result.
 */
    struct enode   *node;
    int             flags;
    enum e_op       op;
{
    struct amode   *ap1, *ap2, *ap3;
    int f1=F_MEM | F_REG;
    int f2=F_ALL;
    int f,g;
    switch (node->etype) {
      case bt_uchar:
      case bt_char:
        f1 |= F_NOEDI;
        f2 |= F_NOEDI;
      case bt_short:
      case bt_ushort:
      case bt_long:
      case bt_ulong:
      case bt_pointer:
	ap1 = g_expr(node->v.p[0], f1);
        ap2 = g_expr(node->v.p[1], f2);
        ap3 = &ecx_reg;
	validate(ap1);
        g_code(op_mov, (int) node->esize, ap1, ap3);
	g_code(op, (int) node->esize, ap2, ap3);
        g_code(op_mov, (int) node->esize, ap3, ap1);
	freeop(ap2);
        freeop(ap1);
        if (!(flags & F_NOVALUE)) {
            /* need result */
            ap1 = get_register();
            g_code(op_mov, 4, ap3, ap1);
            return mk_legal(ap1, flags, node->esize);
        } else
            /* void result */
	    return 0;
      case bt_float:
      case bt_double:
        f = node->etype == bt_float;
        ap1 = g_expr(node->v.p[0], F_MEM);
        (void) g_expr(node->v.p[1], F_FPSTACK);
	validate(ap1);
        if (fpu_option) {
	    g = f ? 5 : 9;
            switch (op) {
              case op_add:
                g_code(op_fadd, g, ap1, NIL_AMODE);
                break;
              case op_sub:
                g_code(op_fsubr, g, ap1, NIL_AMODE);
                break;
              case op_imul:
                g_code(op_fmul, g, ap1, NIL_AMODE);
                break;
              case op_idiv:
                g_code(op_fdivr, g, ap1, NIL_AMODE);
                break;
              default:
                fatal("G_ASBIN ILLEGAL OP");
            }
            if (flags & F_NOVALUE) {
                g_code(op_fstp, g, ap1, NIL_AMODE);
                ap2 = 0;
            } else {
                g_code(op_fst,  g, ap1, NIL_AMODE);
                ap2 = &fp_stack;
            }
	 } else {
            g_code (op_lea, 4, ap1, &ecx_reg);
            call_library(f ? ".fplds" : ".fpldl");
            switch (op) {
              case op_add:
                call_library(".fpadd");
                break;
              case op_sub:
                call_library(".fpsub");
                break;
              case op_imul:
                call_library(".fpmult");
                break;
              case op_idiv:
                call_library(".fpdiv");
                break;
              default:
                fatal("G_ASBIN ILLEGAL OP");
           }
           g_code(op_lea, 4, ap1, &ecx_reg);
           if (flags & F_NOVALUE) {
               ap2 = 0;
               call_library (f ? ".fpstps" : ".fpstpl");
/*
 * LIBRARY fpstps, fpstpl
 * Store the top of the floating point stack into the location addressed
 * by %ecx. Only %ecx may be clobbered.
 * pop the top of the stack thereafter.
 */
           } else {
               ap2 = &fp_stack;
               call_library(f ? ".fpsts" : ".fpstl");
/*
 * LIBRARY fpsts, fpstl
 * same as fpstps, fpstpl, but do not touch the FP stack
 */
           }
	}
        freeop(ap1);
        return mk_legal(ap2, flags, node->esize);
    }
    fatal("g_asbin illegal type");
    /* NOTREACHED */
}

struct amode *
g_mul (node, flags)
/*
 * generate code to evaluate a multiply node 
 */
    struct enode   *node;
    int             flags;
{
    struct amode   *ap1, *ap2;
    switch (node->etype) {
      case bt_long:
      case bt_ulong:
      case bt_pointer:
	ap1 = g_expr(node->v.p[1], F_REG | F_VOL);
	ap2 = g_expr(node->v.p[0], F_ALL);
	validate(ap1);		/* in case push occurred */
	g_code(op_imul, (int) node->esize, ap2, ap1);
	freeop(ap2);
	return mk_legal(ap1, flags, node->esize);
      default:
        return g_bin(node, flags, op_imul);
    }
}

struct amode *
g_asmul(node, flags)
/*
 * generate code for *= node
 */
    struct enode    *node;
    int              flags;
{
    enum e_op op;
    int size=0;
    int f = F_MEM | F_REG;
    struct amode *ap1, *ap2, *ap3;
    switch (node->etype) {
      case bt_uchar:
        op=op_movzbl;
        f |= F_NOEDI;
        goto common;
      case bt_char:
        op=op_movsbl;
        f |= F_NOEDI;
        goto common;
      case bt_ushort:
        op=op_movzwl;
        goto common;
      case bt_short:
        op=op_movswl;
        goto common;
      case bt_ulong:
      case bt_long:
      case bt_pointer:
        op=op_mov;
        size=4;
      common:
        ap1 = g_expr(node->v.p[1], F_REG | F_VOL);
        if (size == 0)
            g_code(op, size, ap1, ap1);
        ap2 = g_expr(node->v.p[0], f);
        ap3 = &ecx_reg;
        validate(ap1);
        g_code(op, size, ap2, ap3);
        g_code(op_imul, 4, ap3, ap1);
        g_code(op_mov, (int) node->esize, ap1, ap2);
        freeop(ap2);
        return mk_legal(ap1, flags, node->esize);
      default:
        return g_asbin(node, flags, op_imul);
    }
}
        
struct amode *
g_div (node, flags, mod)
/*
 * generate code to evaluate a divide node (mod==0) or mod node (mod==1)
 */
    struct enode   *node;
    int             flags;
    int             mod;
{
    struct amode   *ap1, *ap2;
    switch (node->etype) {
      case bt_long:
      case bt_pointer:
      case bt_ulong:
        temp_inv();
        ap1 = g_expr(node->v.p[0], F_ALL);
        ap2 = g_expr(node->v.p[1], F_ALL);
        if (uses_temp(ap2) || ap2->mode == am_immed) {
            g_code(op_mov, 4, ap2, &ecx_reg);
            freeop(ap2);
            ap2 = &ecx_reg;
        }
        validate(ap1);
        g_code(op_mov, 4, ap1, &eax_reg);
        freeop(ap1);
        if (node->etype == bt_long)
            g_code(op_cltd, 0, NIL_AMODE, NIL_AMODE);
        else
            g_code(op_xor, 4, &edx_reg, &edx_reg);
        g_code(op_idiv, 4, ap2, NIL_AMODE);
        ap1 = get_register();
        if (mod)
            g_code(op_mov, 4, &edx_reg, ap1);
        else
            g_code(op_mov, 4, &eax_reg, ap1);
        return mk_legal(ap1, flags, 4l);
      default:
        return g_bin(node, flags, op_idiv);
    }
}

struct amode *
g_asdiv(node, flags, mod)
/*
 * generate code for /= node
 */
    struct enode    *node;
    int              flags;
    int              mod;
{
    enum e_op op;
    int size=0,sign=1;
    struct amode *ap1, *ap2;
    switch (node->etype) {
      case bt_uchar:
        op=op_movzbl;
        sign=0;
        goto common;
      case bt_char:
        op=op_movsbl;
        goto common;
      case bt_ushort:
        op=op_movzwl;
        sign=0;
        goto common;
      case bt_short:
        op=op_movswl;
        goto common;
      case bt_ulong:
        sign=0;
      case bt_long:
      case bt_pointer:
        op=op_mov;
        size=4;
      common:
        temp_inv();
        ap1 = g_expr(node->v.p[0], F_MEM | F_REG);
        ap2 = g_expr(node->v.p[1], F_ALL);
        if (size == 0 || uses_temp(ap2) || ap2->mode == am_immed) {
            g_code(op,size,ap2,&ecx_reg);
            freeop(ap2);
            ap2=&ecx_reg;
        }
        validate(ap1);
        temp_inv();
        g_code(op, size, ap1, &eax_reg);
        if (sign)
            g_code(op_cltd, 0, NIL_AMODE, NIL_AMODE);
        else
            g_code(op_xor, 4, &edx_reg, &edx_reg);
        g_code(op_idiv, 4, ap2, NIL_AMODE);
        ap2 = mod ? &edx_reg : &eax_reg;
        if (uses_temp(ap1)) {
            g_code(op_mov, 4, ap2, &ecx_reg);
            ap2 = &ecx_reg;
        } 
        validate(ap1);
        g_code(op_mov, (int) node->esize, ap2, ap1);
        return mk_legal(ap1, flags, node->esize);
      default:
        return g_asbin(node, flags, op_idiv);
    }
}

struct amode *
g_lsh (node, flags)
/*
 * generate code to evaluate a left-shift node
 */
    struct enode   *node;
    int             flags;
{
    struct amode   *ap1, *ap2;
    switch (node->etype) {
      case bt_long:
      case bt_pointer:
      case bt_ulong:
      case bt_char:
      case bt_uchar:
      case bt_short:
      case bt_ushort:
        ap1 = g_expr(node->v.p[0], F_REG | F_VOL);
        ap2 = g_expr(node->v.p[1], F_ALL);
        validate(ap1);
        if (ap2->mode == am_immed)
            g_code(op_shl, (int) node->esize, ap2, ap1);
        else {
            g_code(op_mov, (int) node->esize, ap2, &ecx_reg);
            g_code(op_shl, (int) node->esize, &cl_reg, ap1);
        }
        freeop(ap2);
        return mk_legal(ap1, flags, node->esize);
    }
    fatal("g_lsh illegal type");
    /* NOTREACHED */
}

struct amode *
g_aslsh (node, flags)
/*
 * generate code to evaluate a left-shift node
 */
    struct enode   *node;
    int             flags;
{
    struct amode   *ap1, *ap2;
    switch (node->etype) {
      case bt_long:
      case bt_pointer:
      case bt_ulong:
      case bt_char:
      case bt_uchar:
      case bt_short:
      case bt_ushort:
        ap1 = g_expr(node->v.p[0], F_MEM | F_REG);
        ap2 = g_expr(node->v.p[1], F_ALL);
        validate(ap1);
        if (ap2->mode == am_immed)
            g_code(op_shl, (int) node->esize, ap2, ap1);
        else {
            g_code(op_mov, (int) node->esize, ap2, &ecx_reg);
            g_code(op_shl, (int) node->esize, &cl_reg, ap1);
        }
        freeop(ap2);
        return mk_legal(ap1, flags, node->esize);
    }
    fatal("g_aslsh illegal type");
    /* NOTREACHED */
}

struct amode *
g_rsh (node, flags)
/*
 * generate code to evaluate a right-shift node
 */
    struct enode   *node;
    int             flags;
{
    struct amode   *ap1, *ap2;
    enum e_op op;
    op = op_shr;
    switch (node->etype) {
      case bt_long:
      case bt_pointer:
      case bt_char:
      case bt_short:
        op = op_asr;
      case bt_ulong:
      case bt_uchar:
      case bt_ushort:
        ap1 = g_expr(node->v.p[0], F_REG | F_VOL);
        ap2 = g_expr(node->v.p[1], F_ALL);
        validate(ap1);
        if (ap2->mode == am_immed)
            g_code(op,     (int) node->esize, ap2, ap1);
        else {
            g_code(op_mov, (int) node->esize, ap2, &ecx_reg);
            g_code(op,     (int) node->esize, &cl_reg, ap1);
        }
        freeop(ap2);
        return mk_legal(ap1, flags, node->esize);
    }
    fatal("g_rsh illegal type");
    /* NOTREACHED */
}

struct amode *
g_asrsh (node, flags)
/*
 * generate code to evaluate a right-shift node
 */
    struct enode   *node;
    int             flags;
{
    struct amode   *ap1, *ap2;
    enum e_op op;
    op = op_shr;
    switch (node->etype) {
      case bt_long:
      case bt_pointer:
      case bt_char:
      case bt_short:
        op = op_asr;
      case bt_ulong:
      case bt_uchar:
      case bt_ushort:
        ap1 = g_expr(node->v.p[0], F_MEM | F_REG);
        ap2 = g_expr(node->v.p[1], F_ALL);
        validate(ap1);
        if (ap2->mode == am_immed)
            g_code(op,     (int) node->esize, ap2, ap1);
        else {
            g_code(op_mov, (int) node->esize, ap2, &ecx_reg);
            g_code(op,     (int) node->esize, &cl_reg, ap1);
        }
        freeop(ap2);
        return mk_legal(ap1, flags, node->esize);
    }
    fatal("g_asrsh illegal type");
    /* NOTREACHED */
}

struct amode   *
g_hook(node, flags)
/*
 * generate code to evaluate a condition operator node (?:)
 */
    struct enode   *node;
    int             flags;
{
    struct amode   *ap1, *ap2;
    unsigned int    false_label, end_label;
    long size=node->esize;
    int flagx;
    int result_is_void;

    switch (node->etype) {
        case bt_float:
        case bt_double:
          flagx = F_FPSTACK;
          result_is_void =0;
          break;
        case bt_void:
          flagx = F_ALL | F_NOVALUE;
          result_is_void = 1;
          break;
        case bt_struct:
        case bt_union:
          size = 4;
          /*FALLTHROUGH*/
        default:
          flagx = F_REG | F_VOL;
    }
          
    false_label = nextlabel++;
    end_label = nextlabel++;

    temp_inv(); /* I do not think I can avoid that */

    /* all registers are void */

    falsejp(node->v.p[0], false_label);
    node = node->v.p[1];

    /* all registers are void */

    ap1 = g_expr(node->v.p[0], flagx);
    freeop(ap1);

    /* all registers are void */

    g_code(op_bra, 0, mk_label(end_label), NIL_AMODE);

    g_label(false_label);

    ap2 = g_expr(node->v.p[1], flagx);

    if (!result_is_void && !equal_address(ap1,ap2))
       fatal("G_HOOK: INCONSISTENCY");

    g_label(end_label);

    return mk_legal(ap2, flags, size);
}

swap_nodes(node)
/*
 * exchange the two operands in a node.
 */
    struct enode   *node;
{
    struct enode   *temp;
    temp = node->v.p[0];
    node->v.p[0] = node->v.p[1];
    node->v.p[1] = temp;
}

structassign (ap1, ap2, size)
/*
 * assign structures: ap1=dest, ap2=source
 */
   struct amode *ap1,*ap2;
   long size;
{
   if (size % 4 != 0)
       fatal("STRUCTASSIGN: SIZE");
   if (! uses_structassign)
       fatal("STRUCTASSIGN: USES");
   if (size == 4) {
      if (ap1->mode == am_reg) {
         ap1 = copy_addr(ap1);
         ap1->mode = am_indx;
         ap1->offset=0;
      } else {
         g_code(op_mov, 4, ap1, &edi_reg);
         ap1 = copy_addr(&edi_reg);
         ap1->mode = am_indx;
         ap1->offset=0;
      }
      if (ap2->mode == am_reg) {
         ap2 = copy_addr(ap2);
         ap2->mode = am_indx;
         ap2->offset = 0;
      } else {
         g_code(op_mov, 4, ap2, &esi_reg);
         ap2 = copy_addr(&esi_reg);
         ap2->mode = am_indx;
         ap2->offset =0;
      }
      g_code(op_mov, 4, ap2, &ecx_reg);
      g_code(op_mov, 4, &ecx_reg, ap1);
   } else {
      g_code (op_mov, 4, ap1, &edi_reg);
      g_code (op_mov, 4, ap2, &esi_reg);
      g_code (op_mov, 4, mk_immed(size/4), &ecx_reg);
      g_code (op_rep, 0, NIL_AMODE, NIL_AMODE);
      g_code (op_smov, 4, NIL_AMODE, NIL_AMODE);
   }
}

struct amode   *
g_assign(node, flags)
/*
 * generate code for an assignment node.
 */
    struct enode   *node;
    int             flags;
{
    int             f;
    struct amode   *ap1, *ap2, *ap3;
    long            size = node->esize;

    if (node->etype == bt_struct || node->etype == bt_union) {
        ap2 = g_expr(node->v.p[1], F_ALL);
        ap1 = g_expr(node->v.p[0], F_ALL);
        validate(ap2);
        structassign (ap1, ap2, size);
        freeop(ap1);
        return mk_legal(ap2, flags, 4l);
    }
    if (node->v.p[0]->nodetype == en_fieldref) {
	long            mask;
	int             i;
	/*
	 * Field assignment
	 */
	/* get the value */
	ap1 = g_expr(node->v.p[1], F_REG | F_VOL);
	i = node->v.p[0]->bit_width;
	mask = 0;
	while (i--)
	    mask = mask + mask + 1;
	g_code(op_and, (int) size, mk_immed(mask), ap1);
	mask <<= node->v.p[0]->bit_offset;
	if (!(flags & F_NOVALUE)) {
	    /*
	     * result value needed
	     */
	    ap3 = get_register();
	    g_code(op_mov, 4, ap1, ap3);
	} else
	    ap3 = ap1;
	if (node->v.p[0]->bit_offset > 0)
		g_code(op_shl, (int) size,
		       mk_immed((long) node->v.p[0]->bit_offset), ap3);
	ap2 = g_deref(node->v.p[0]->v.p[0], node->v.p[0]->etype);
        validate(ap3);
        g_code(op_mov, (int) size, ap2, &ecx_reg);
	g_code(op_and, (int) size, mk_immed(~mask), &ecx_reg);
	g_code(op_or, (int) size, ap3, &ecx_reg);
        g_code(op_mov, (int) size, &ecx_reg, ap2);
	freeop(ap2);
        if (!(flags & F_NOVALUE)) {
            freeop(ap3);
	    validate(ap1);
        }
	return mk_legal(ap1, flags, size);
    }
    if (node->etype == bt_double || node->etype == bt_float) {
      int f = node->etype == bt_float;
      ap1 = g_expr(node->v.p[0], F_MEM);
      (void) g_expr(node->v.p[1], F_FPSTACK);
      validate(ap1);
      freeop(ap1);
      if (fpu_option) {
        if (flags & F_NOVALUE) {
            g_code(op_fstp, f ? 5 : 9, ap1, NIL_AMODE);
            ap1 = 0;
        } else {
            g_code(op_fst, f ? 5 : 9, ap1, NIL_AMODE);
            ap1 = &fp_stack;
        }
      } else {
        g_code(op_lea, 4, ap1, &ecx_reg);
        if (flags & F_NOVALUE) {
            ap1 = 0;
            call_library(f ? ".fpstps" : ".fpstpl");
        } else {
            ap1 = &fp_stack;
            call_library(f ? ".fpsts" : ".fpstl");
        }
      }
      return mk_legal(ap1, flags, 8l);
    }
    /*
     * (uns.) char, (uns.) short, (uns.) long, float
     * 
     * we want to pass the right hand side as the expression value. This can''t
     * be done if the left side is a register variable on which the right
     * hand side addressing mode depends. But if the left side IS a register
     * variable, it is desirable to pass the left side, so no problem.
     */
    if (node->v.p[0]->nodetype == en_tempref) {
	/* pass the left side as expr. value */
	ap1 = g_expr(node->v.p[0], F_ALL);
	ap2 = g_expr(node->v.p[1], F_ALL);
	validate(ap1);
	g_code(op_mov, (int) size, ap2, ap1);
	freeop(ap2);
	return mk_legal(ap1, flags, size);
    } else {
	/* pass the right side as expr. value */
	/* normally, this is more efficient */
	ap1 = g_expr(node->v.p[1], F_ALL);
	ap2 = g_expr(node->v.p[0], F_ALL);
	validate(ap1);
        if (ap1->mode == am_reg || ap2->mode == am_reg
		|| ap1->mode == am_immed) {
	    g_code(op_mov, (int) size, ap1, ap2);
            freeop(ap2);
        } else {
           g_code (op_mov, (int) size, ap1, &ecx_reg);
           g_code (op_mov, (int) size, &ecx_reg, ap2);
           freeop(ap2);
           freeop(ap1);
           if (!(flags & F_NOVALUE)) {
               ap1=get_register();
               g_code(op_mov, (int) size, &ecx_reg, ap1);
           } else
               ap1 = 0;
        }
        return mk_legal(ap1,flags,size);
    }
}

long
push_param(ep)
/*
 * push the operand expression onto the stack. return the number of bytes
 * pushed
 */
    struct enode   *ep;
{
    struct amode   *ap;
    long            size = ep->esize;

    /* pushing of structures and unions */
    if (ep->etype == bt_struct || ep->etype == bt_union) {
        ap = g_expr(ep, F_ALL);
        g_code(op_sub, 4, mk_immed(size), &esp_reg);
        structassign(&esp_reg, ap, size);
        freeop(ap);
        return size;
    }
    if (ep->etype == bt_double) {
        (void) g_expr(ep, F_FPSTACK);
        g_code(op_sub, 4, mk_immed(8l), &esp_reg);
        if (fpu_option) {
          ap = mk_reg(ESP);
          ap->mode = am_indx;
          ap->offset = 0;
          g_code(op_fstp, 9, ap, NIL_AMODE);
        } else {
          g_code(op_mov, 4, &esp_reg, &ecx_reg);
          call_library(".fpstpl");
        }
      return 8;
    }
    if (size != 4)
        fatal("push_param size");
    ap = g_expr(ep, F_ALL);
    g_code(op_push, 4, ap, NIL_AMODE);
    freeop(ap);
    return size;
}

long
g_parms(plist)
/*
 * push a list of parameters onto the stack and return the number of
 * parameters pushed.
 */
    struct enode   *plist;
{
    long            i;
    i = 0;
    while (plist != 0) {
	i += push_param(plist->v.p[0]);
	plist = plist->v.p[1];
    }
    return i;
}

struct amode   *
func_result(flags, bytes, floatstack)
    int             flags;
    long            bytes;
    int             floatstack;
{
    struct amode   *ap;
    if (bytes != 0)
	/* adjust stack pointer */
        if (bytes == 4)
            g_code(op_pop, 4, &ecx_reg, NIL_AMODE);
        else
	    g_code(op_add, 4, mk_immed(bytes), &esp_reg);
    if (floatstack) {
       if (flags & F_NOVALUE) {
           maybe_fppop(&fp_stack);
           return 0;
       }
       if (flags & F_FPSTACK) {
#ifdef FUNCS_USE_387
/*
 * .fpputstack may pop off the top of the hardware stack and put it
 * into the software stack. Useful when linking c386 code with functions
 * generated by other compilers.
 */
	   if (!fpu_option)
		call_library(".fpputstack");
#endif
           return &fp_stack;
       }
       fatal("FUNC_RESULT: FLOAT");
    }
    if (flags & F_NOVALUE)
        return 0;
    if (!(flags & F_REG))
        fatal("FUNC_RESULT");
    ap= get_register();
    if (ap->preg != RESULT)
        g_code(op_mov, 4, &eax_reg, ap);
    return ap;
}

maybe_fppop(ap)
/*
 * If ap is the top of the floating point stack,
 * flush it
 */
    struct amode *ap;
{
    if (ap == 0)
        return;
    if (ap->mode == am_fpstack)
        if (fpu_option)
           g_code(op_fpop, 0, NIL_AMODE, NIL_AMODE);
        else
           call_library(".fppop");
}

struct amode   *
g_fcall(node, flags)
/*
 * generate a function call node and return the address mode of the result.
 */
    struct enode   *node;
    int             flags;
{
    struct amode   *ap;
    long            i;
    int             floatstack;
    /* push any used registers */
    temp_inv();
    i = g_parms(node->v.p[1]);	/* generate parameters */
    /*
     * for functions returning a structure or a union, push a pointer to the
     * return value as additional argument The scratch space will be
     * allocated in the stack frame of the calling function.
     */
    if (node->etype == bt_struct || node->etype == bt_union) {
	ap = mk_scratch(node->esize);
	g_code(op_lea,  4, ap, &ecx_reg);
        g_code(op_push, 4, &ecx_reg, NIL_AMODE); 
        i += 4l;
        freeop(ap);
    }
    /* call the function */
    if (node->v.p[0]->nodetype == en_nacon ||
	node->v.p[0]->nodetype == en_labcon)
	g_code(op_call, 0, mk_offset(node->v.p[0]), NIL_AMODE);
    else {
	ap = g_expr(node->v.p[0], F_REG);
	freeop(ap);
	ap = copy_addr(ap);
	ap->mode = am_star;
	g_code(op_call, 0, ap, NIL_AMODE);
    }
    floatstack= (node->etype == bt_float || node->etype == bt_double);
    return func_result(flags, i, floatstack);
}

struct amode   *
g_cast(ap, typ1, typ2, flags)
    struct amode   *ap;
    int             flags;
    enum e_bt       typ1, typ2;
/*
 * generates code for a en_cast node
 *
 */
{
    long	   siz1, siz2;
    struct amode   *ap1;

    if (flags & F_NOVALUE) {
        freeop(ap);
        maybe_fppop(ap);
        return 0;
    }

/* casts to a narrower integer type are no-ops since the 386 is low-endian */
    /* to avoid code duplication, float/double is shared */
    if (typ1 == bt_float) siz1=4; else siz1=8;
    if (typ2 == bt_float) siz2=4; else siz2=8;
    switch (typ2) {
      /* type to cast to */
      case bt_float:
      case bt_double:
        switch (typ1) {
          case bt_double:
          case bt_float:
            ap = mk_legal(ap, F_FPSTACK, siz1);
            return mk_legal(ap, flags, siz2);
          case bt_uchar:
          case bt_char:
          case bt_short:
          case bt_ushort:
            ap = g_cast(ap, typ1, bt_long, F_ALL);
            return g_cast(ap, bt_long, typ2, flags);
          case bt_long:
          case bt_ulong:
          case bt_pointer:
/*
 * LIBRARY fpldi, fpldu
 *
 * fpldi and fpldu convert the long resp. unsigned long item in
 * %ecx to double and push that value onto the floating point stack.
 * No register other than %ecx may be clobbered.
 */
/*
 * For the conversion signed long --> float/double, there is
 * a 387 instruction
 */
            if (typ1==bt_long && fpu_option) {
                if (ap->mode == am_direct || ap->mode == am_indx ||
                    ap->mode == am_indx2) {
/*
 * FPU-code for a signed long that is in memory
 */
		    g_code(op_fild, 4, ap, NIL_AMODE);
	        } else {
/*
 * FPU-code for a signed long that is in a register:
 * the value is written to -4(%esp) and loaded from there
 * since there is no direct path between CPU and FPU registers.
 */
                    ap1 = mk_reg(ESP);
	            ap1->mode = am_indx;
                    ap1->offset = mk_icon(-4l);
		    g_code(op_mov, 4, ap, ap1);
		    g_code(op_fild, 4, ap1, NIL_AMODE);
	 	}
	        freeop(ap);
		return mk_legal(&fp_stack, flags, siz2);
	    }
/*
 * The general case (no inline-FPU code or unsigned conversion)
 */

            g_code(op_mov, 4, ap, &ecx_reg);
	    if (fpu_option)
                call_library(typ1 == bt_long ? "..fldi" : "..fldu");
	    else
                call_library(typ1 == bt_long ? ".fpldi" : ".fpldu");
            freeop(ap);
            return mk_legal(&fp_stack, flags, siz2);
        }
        break;
      case bt_uchar:
      case bt_char:
        flags |= F_NOEDI;
        switch (typ1) {
	  case bt_float:
	  case bt_double:
            (void) mk_legal(ap, F_FPSTACK, siz1);
            ap = get_register();
/*
 * LIBRARY fpsti fpstu
 * These functions convert the top of the FP stack to long resp. unsigned long,
 * and return the value in %ecx. No register other than %ecx may be clobbered.
 * The top of the FP Stack is popped thereafter
 */
	    if (fpu_option)
                call_library("..fsti");
	    else
                call_library(".fpsti");
            g_code (op_mov, 1, &ecx_reg, ap);
            return mk_legal(ap, flags, 1l);
          case bt_uchar:
          case bt_char:
          case bt_ushort:
          case bt_short:
          case bt_ulong:
          case bt_long:
          case bt_pointer:
	    return mk_legal (ap, flags, 1l);
	}
        break;
      case bt_short:
      case bt_ushort:
	switch (typ1) {
	  case bt_float:
	  case bt_double:
            (void) mk_legal(ap, F_FPSTACK, siz1);
            ap = get_register();
	    if (fpu_option)
                call_library("..fsti");
	    else
                call_library(".fpsti");
	    g_code(op_mov, 2, &ecx_reg, ap);
            return mk_legal(ap, flags, 2l);
	  case bt_uchar:
	    ap = mk_legal(ap, F_REG | F_VOL, 1l);
            g_code (op_movzbw, 0, ap, ap);
            return mk_legal (ap, flags, 2l);
          case bt_char:
	    ap = mk_legal(ap, F_REG | F_VOL, 1l);
            g_code (op_movsbw, 0, ap, ap);
            return mk_legal (ap, flags, 2l);
          case bt_short:
          case bt_ushort:
          case bt_long:
          case bt_pointer:
          case bt_ulong:
            return mk_legal (ap, flags, 2l);
	}
        break;
      case bt_ulong:
      case bt_long:
      case bt_pointer:
	switch (typ1) {
	  case bt_float:
          case bt_double:
            (void) mk_legal(ap, F_FPSTACK, siz1);
            ap = get_register();
	    if (fpu_option)
                call_library(typ2 == bt_long ? "..fsti" : "..fstu");
	    else
                call_library(typ2 == bt_long ? ".fpsti" : ".fpstu");
            g_code(op_mov, 4, &ecx_reg, ap);
            return mk_legal(ap, flags, 4l);
	  case bt_uchar:
	    ap = mk_legal(ap, F_REG | F_VOL, 1l);
            g_code (op_movzbl, 0, ap, ap);
            return mk_legal(ap, flags, 4l);
	  case bt_char:
	    ap = mk_legal(ap, F_REG | F_VOL, 1l);
            g_code (op_movsbl, 0, ap, ap);
            return mk_legal(ap, flags, 4l);
          case bt_short:
            ap = mk_legal(ap, F_REG | F_VOL, 2l);
            g_code (op_movswl, 0, ap, ap);
            return mk_legal(ap, flags, 4l);
          case bt_ushort:
	    ap = mk_legal(ap, F_REG | F_VOL, 2l);
            g_code (op_movzwl, 0, ap, ap);
            return mk_legal(ap, flags, 4l);
          case bt_ulong:
          case bt_long:
          case bt_pointer:
            return mk_legal(ap, flags, 4l);
	}
	break;
    }
    fatal ("G_CAST");
    /*NOTREACHED*/
}

struct amode   *
g_expr(node, flags)
/*
 * general expression evaluation. returns the addressing mode of the result.
 */
    struct enode   *node;
    int             flags;
{
    struct amode   *ap1, *ap2;
    unsigned int    lab0, lab1;
    long size;
    enum e_bt type;
    if (node == 0) {
	fatal("null node in g_expr");
    }
    size = node->esize;
    type = node->etype;
    if (tst_const(node)) {
	ap1 = (struct amode *) xalloc((int) sizeof(struct amode));
	ap1->mode = am_immed;
	ap1->offset = node;
	return mk_legal(ap1, flags, size);
    }
    switch (node->nodetype) {
      case en_autocon:
	ap1 = get_register();
	    ap2 = (struct amode *) xalloc((int) sizeof(struct amode));
	    ap2->mode = am_indx;
	    ap2->preg = FRAMEPTR;	/* frame pointer */
	    ap2->offset = node;	/* use as constant node */
	    g_code(op_lea, 4, ap2, ap1);
	return mk_legal(ap1, flags, size);
      case en_tempref:
        ap1=mk_reg((int) node->v.i);
        return mk_legal(ap1, flags, size);
      case en_ref:
        ap1=g_deref(node->v.p[0], type);
        if (type == bt_struct || type == bt_union)
            return mk_legal(ap1, flags, 4l);
        else
            return mk_legal(ap1, flags, node->esize);
      case en_fieldref:
        return g_fderef(node, flags);
      case en_uminus:
	return g_unary(node, flags, op_neg);
      case en_compl:
	return g_unary(node, flags, op_not);
      case en_add:
	return g_bin(node, flags, op_add);
      case en_sub:
	return g_bin(node, flags, op_sub);
      case en_and:
	return g_bin(node, flags, op_and);
      case en_or:
	return g_bin(node, flags, op_or);
      case en_xor:
	return g_bin(node, flags, op_xor);
      case en_assign:
	return g_assign(node, flags);
      case en_asadd:
        return g_asbin(node, flags, op_add);
      case en_assub:
        return g_asbin(node, flags, op_sub);
      case en_asand:
        return g_asbin(node, flags, op_and);
      case en_asor:
        return g_asbin(node, flags, op_or);
      case en_asxor:
        return g_asbin(node, flags, op_xor);
      case en_asmul:
        return g_asmul(node, flags);
      case en_asdiv:
        return g_asdiv(node, flags, 0);
      case en_asmod:
        return g_asdiv(node, flags, 1);
      case en_aslsh:
        return g_aslsh(node, flags);
      case en_asrsh:
        return g_asrsh(node, flags);
      case en_ainc:
        return g_aincdec(node, flags, op_add);
      case en_adec:
        return g_aincdec(node, flags, op_sub);
      case en_mul:
        return g_mul(node, flags);
      case en_div:
        return g_div(node, flags, 0);
      case en_mod:
        return g_div(node, flags, 1);
      case en_lsh:
        return g_lsh(node, flags);
      case en_rsh:
        return g_rsh(node, flags);
      case en_cond:
        return g_hook(node, flags);
      case en_land:
      case en_lor:
      case en_eq:
      case en_ne:
      case en_lt:
      case en_le:
      case en_gt:
      case en_ge:
      case en_not:
	lab0 = nextlabel++;
	lab1 = nextlabel++;
	falsejp(node, lab0);
	ap1 = get_register();
	g_code(op_mov, 4, mk_immed(1l), ap1);
	g_code(op_bra, 0, mk_label(lab1), NIL_AMODE);
	g_label(lab0);
	g_code(op_mov, 4, mk_immed(0l), ap1);
	g_label(lab1);
	return mk_legal(ap1, flags, size);
      case en_void:
	freeop(g_expr(node->v.p[0], F_ALL | F_NOVALUE));
	return g_expr(node->v.p[1], flags);
      case en_fcall:
	return g_fcall(node, flags);
      case en_cast:
	return g_cast(g_expr(node->v.p[0], F_ALL),
		      node->v.p[0]->etype,
		      node->etype, flags);
      case en_deref:
	/*
	 * The cases where this node occurs are handled automatically:
	 * g_assign and g_fcall return a pointer to a structure rather than a
	 * structure.
	 */
	return g_expr(node->v.p[0], flags);
      case en_fcon:
#ifdef NOFLOAT
	fatal ("Floating point constant");
#else
        if (flags & (F_MEM | F_FPSTACK) == 0)
            fatal("EN_FCON");
        lab0 = nextlabel++;
        dseg();
        nl();
        put_align(AL_DOUBLE);
        put_label(lab0);
        gendouble(node->v.f);
        ap1 = mk_label(lab0);
        return mk_legal(ap1, flags, 8l);
#endif
      default:
	fatal("uncoded node in g_expr");
	/* NOTREACHED */
    }
}

tst_const(node)
    struct enode   *node;
/*
 * tests if it is a constant node, that means either en_icon, en_nacon or
 * en_labcon, or sums or differences of such nodes
 */
{
    enum e_node     typ1 = node->nodetype;
    switch (typ1) {
      case en_icon:
      case en_nacon:
      case en_labcon:
        return 1;
      case en_add:
      case en_sub:
        return tst_const(node->v.p[0]) && tst_const(node->v.p[1]);
      case en_cast:
      case en_uminus:
        return tst_const(node->v.p[0]);
      default:
        return 0;
    }
}


static
g_compare(node)
/*
 * generate code to do a comparison of the two operands of node. returns 1 if
 * it was an unsigned comparison
 */
    struct enode   *node;
{
    struct amode   *ap1, *ap2;
    int             flagx;
    switch (node->v.p[0]->etype) {
      case bt_uchar:
      case bt_char:
      case bt_ushort:
      case bt_short:
      case bt_pointer:
      case bt_long:
      case bt_ulong:
	ap2 = g_expr(node->v.p[1], F_ALL);
        flagx = (ap2->mode == am_immed) ? F_MEM | F_REG : F_REG;
	ap1 = g_expr(node->v.p[0], flagx);
	validate(ap2);
	g_code(op_cmp, (int) node->v.p[0]->esize, ap2, ap1);
	freeop(ap1);
	freeop(ap2);
	if (node->v.p[0]->etype == bt_char ||
	    node->v.p[0]->etype == bt_short ||
	    node->v.p[0]->etype == bt_long)
	    return 0;
	return 1;
      case bt_double:
      case bt_float:
        (void) g_expr(node->v.p[1], F_FPSTACK);
        (void) g_expr(node->v.p[0], F_FPSTACK);
        if (fpu_option) {
            if (reg_in_use[0] >= 0) 
                temp_inv();
            g_code(op_fcompp, 0, NIL_AMODE, NIL_AMODE);
            g_code(op_fnstsw, 0, &ax_reg,   NIL_AMODE);
            g_code(op_sahf,   0, NIL_AMODE, NIL_AMODE);
            return 1;
        } else {
            call_library(".fpcmp");
/*
 * LIBRARY fpcmp
 * If the stack is a b .... before this operation, compare a with b.
 * Return as result in %ecx:
 * -1, if a < b
 *  0, if a == b
 *  1, if a > b
 *
 * Pop a and b from the FP stack thereafter
 */
            ap1 = &ecx_reg;
            g_code(op_test, 4, ap1, ap1);
            return 0;
        }
    }
    fatal("g_compare: illegal type");
    /* NOTREACHED */
}

truejp(node, label)
/*
 * generate a jump to label if the node passed evaluates to a true condition.
 */
    struct enode   *node;
    unsigned int    label;
{
    struct amode   *ap1;
    unsigned int    lab0;
    if (node == 0)
	fatal("TRUEJP: ZERO NODE");
    if (node->nodetype == en_icon) {
	if (node->v.i)
	    g_code(op_bra, 0, mk_label(label), NIL_AMODE);
	return;
    }
    switch (node->nodetype) {
      case en_eq:
	(void) g_compare(node);
	g_code(op_je, 0, mk_label(label), NIL_AMODE);
	return;
      case en_ne:
	(void) g_compare(node);
	g_code(op_jne, 0, mk_label(label), NIL_AMODE);
	return;
      case en_lt:
	g_compare(node) ?
	    g_code(op_jb, 0, mk_label(label), NIL_AMODE) :
	    g_code(op_jl, 0, mk_label(label), NIL_AMODE);
	return;
      case en_le:
	g_compare(node) ?
	    g_code(op_jbe, 0, mk_label(label), NIL_AMODE) :
	    g_code(op_jle, 0, mk_label(label), NIL_AMODE);
	return;
      case en_gt:
	g_compare(node) ?
	    g_code(op_ja, 0, mk_label(label), NIL_AMODE) :
	    g_code(op_jg, 0, mk_label(label), NIL_AMODE);
	return;
      case en_ge:
	g_compare(node) ?
	    g_code(op_jae, 0, mk_label(label), NIL_AMODE) :
	    g_code(op_jge, 0, mk_label(label), NIL_AMODE);
	return;
      case en_land:
	lab0 = nextlabel++;
	falsejp(node->v.p[0], lab0);
	truejp(node->v.p[1], label);
	g_label(lab0);
	return;
      case en_lor:
	truejp(node->v.p[0], label);
	truejp(node->v.p[1], label);
	return;
      case en_not:
	falsejp(node->v.p[0], label);
	return;
      default:
        switch (node->etype) {
          case bt_uchar:
          case bt_char:
          case bt_ushort:
          case bt_short:
          case bt_ulong:
          case bt_long:
          case bt_pointer:
	    ap1 = g_expr(node, F_REG);
	    g_code(op_test, (int) node->esize, ap1, ap1);
	    freeop(ap1);
	    g_code(op_jne, 0, mk_label(label), NIL_AMODE);
	    return;
          case bt_double:
          case bt_float:
            (void) g_expr(node, F_FPSTACK);
	    if (fpu_option) {
                if (reg_in_use[0] >= 0)
                    temp_inv();
                g_code(op_ftst, 0, NIL_AMODE, NIL_AMODE);
                g_code(op_fnstsw, 0, &ax_reg, NIL_AMODE);
		g_code(op_fpop, 0, NIL_AMODE, NIL_AMODE);
                g_code(op_sahf, 0, NIL_AMODE, NIL_AMODE);
            } else {
                call_library(".fptst");
                ap1 = &ecx_reg;
                g_code(op_test, 4, ap1, ap1);
            }
/*
 * LIBRARY fptst
 *
 * Return in %ecx
 *
 * 0, if the top of the FP stack is == 0
 * 1, if the top of the FP stack is != 0
 *
 * Pop the top of the FP stack thereafter.
 */
            g_code(op_jne, 0, mk_label(label), NIL_AMODE);
            return;
        }
        fatal ("truejp: illegal type");
    }
}

falsejp(node, label)
/*
 * generate code to execute a jump to label if the expression passed is
 * false.
 */
    struct enode   *node;
    unsigned int    label;
{
    struct amode   *ap;
    unsigned int    lab0;
    if (node == 0)
	fatal("FALSEJP");
    if (node->nodetype == en_icon) {
	if (!node->v.i)
	    g_code(op_bra, 0, mk_label(label), NIL_AMODE);
	return;
    }
    switch (node->nodetype) {
      case en_eq:
	(void) g_compare(node);
	g_code(op_jne, 0, mk_label(label), NIL_AMODE);
	return;
      case en_ne:
	(void) g_compare(node);
	g_code(op_je, 0, mk_label(label), NIL_AMODE);
	return;
      case en_lt:
	g_compare(node) ?
	    g_code(op_jae, 0, mk_label(label), NIL_AMODE) :
	    g_code(op_jge, 0, mk_label(label), NIL_AMODE);
	return;
      case en_le:
	g_compare(node) ?
	    g_code(op_ja, 0, mk_label(label), NIL_AMODE) :
	    g_code(op_jg, 0, mk_label(label), NIL_AMODE);
	return;
      case en_gt:
	g_compare(node) ?
	    g_code(op_jbe, 0, mk_label(label), NIL_AMODE) :
	    g_code(op_jle, 0, mk_label(label), NIL_AMODE);
	return;
      case en_ge:
	g_compare(node) ?
	    g_code(op_jb, 0, mk_label(label), NIL_AMODE) :
	    g_code(op_jl, 0, mk_label(label), NIL_AMODE);
	return;
      case en_land:
	falsejp(node->v.p[0], label);
	falsejp(node->v.p[1], label);
	return;
      case en_lor:
	lab0 = nextlabel++;
	truejp(node->v.p[0], lab0);
	falsejp(node->v.p[1], label);
	g_label(lab0);
	return;
      case en_not:
	truejp(node->v.p[0], label);
	return;
      default:
        switch (node->etype) {
          case bt_uchar:
          case bt_char:
          case bt_ushort:
          case bt_short:
          case bt_ulong:
          case bt_long:
          case bt_pointer:
	    ap = g_expr(node, F_REG);
	    g_code(op_test, (int) node->esize, ap, ap);
	    freeop(ap);
	    g_code(op_je, 0, mk_label(label), NIL_AMODE);
	    return;
         case bt_float:
         case bt_double:
           (void) g_expr(node, F_FPSTACK);
	    if (fpu_option) {
                if (reg_in_use[0] >= 0)
                    temp_inv();
                g_code(op_ftst, 0, NIL_AMODE, NIL_AMODE);
                g_code(op_fnstsw, 0, &ax_reg, NIL_AMODE);
		g_code(op_fpop, 0, NIL_AMODE, NIL_AMODE);
                g_code(op_sahf, 0, NIL_AMODE, NIL_AMODE);
            } else {
                call_library(".fptst");
                ap = &ecx_reg;
                g_code(op_test, 4, ap, ap);
            }
           g_code(op_je, 0, mk_label(label), NIL_AMODE);
           return;
        }
        fatal ("falsejp: illegal type");
    }
}
#endif /* INTEL_386 */
