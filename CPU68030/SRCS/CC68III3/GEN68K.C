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

#ifdef MC680X0

struct amode   *
mk_scratch(size)
/*
 * returns addressing mode of form offset(FRAMEPTR)
 * size is rounded up to AL_DEFAULT
 */
    long            size;
{
    struct amode   *ap;

    /* round up the request */
    if (size % AL_DEFAULT)
        size += AL_DEFAULT - (size % AL_DEFAULT);

    /* allocate the storage */
    act_scratch += size;

/*
 * The next statement could be deferred and put into the
 * routine checkstack(), but this is just safer.
 */
    if (act_scratch > max_scratch)
        max_scratch = act_scratch;

    ap = (struct amode *) xalloc((int) sizeof(struct amode));
    ap->mode = am_indx;
    ap->preg = FRAMEPTR - 8;
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
    long            size;
{
    struct amode   *ap2;

    if (flags & F_NOVALUE) {
        freeop(ap);
	return 0;
    }

    switch (ap->mode) {
      case am_immed:
	if (flags & F_IMMED)
	    return ap;	/* mode ok */
	break;
	case am_areg:
	  if (flags & F_AREG && (!(flags & F_VOL) || ap->preg <= MAX_ADDR))
	      return ap;
	  break;
	case am_dreg:
	  if (flags & F_DREG && (!(flags & F_VOL) || ap->preg <= MAX_DATA))
	      return ap;
	  break;
	case am_ind:
	case am_indx:
	case am_indx2:
	case am_direct:
	case am_indx3:
	case am_ainc:
	  if (flags & F_MEM)
	      return ap;
	  break;
    }
    if ((flags & F_DREG) && (flags & F_AREG)) {
	/* decide, which mode is better */
	if (ap->mode == am_immed) {
	    if (isbyte(ap->offset))
		flags &= F_DREG;
	    else if (isshort(ap->offset) && size == 4)
		flags &= F_AREG;
	}
    }
    if (flags & F_DREG) {
	freeop(ap);		/* maybe we can use it... */
	ap2 = temp_data();	/* allocate to dreg */
	g_code(op_move, (int) size, ap, ap2);
	return ap2;
    }
    if (!(flags & F_AREG))
	fatal("MK_LEGAL");
    if (size < 2)
	fatal("illegal: size<2 --> An");
    freeop(ap);
    ap2 = temp_addr();
    g_code(op_move, (int) size, ap, ap2);
    return ap2;
}


int
isshort(node)
/*
 * return true if the node passed can be generated as a short offset.
 */
    struct enode   *node;
{
    return node->nodetype == en_icon &&
	(node->v.i >= -32768 && node->v.i <= 32767);
}

int
isbyte(node)
    struct enode   *node;
{
    return node->nodetype == en_icon &&
	(node->v.i >= -128 && node->v.i <= 127);
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
	fatal("COPY_ADDR");
    newap = (struct amode *) xalloc((int) sizeof(struct amode));
    *newap = *ap;
    return newap;
}


struct amode   *
g_index(node)
/*
 * generate code to evaluate an index node and return the addressing
 * mode of the result.
 */
    struct enode   *node;
{
    struct amode   *ap1, *ap2;
    if (node->v.p[0]->nodetype == en_tempref &&
	node->v.p[1]->nodetype == en_tempref &&
	(node->v.p[0]->v.i >= 8 || node->v.p[1]->v.i >= 8)) {
	/* both nodes are registers, one is address */
	if (node->v.p[0]->v.i < 8)
	    /* first node is data register */
	{
	    ap1 = g_expr(node->v.p[1], F_AREG);
	    ap1 = copy_addr(ap1);
	    ap1->sreg = node->v.p[0]->v.i;
	    ap1->mode = am_indx2;	/* 0(Ax,Dx) */
	    ap1->offset = mk_icon(0l);
	    return ap1;
	} else {
	    /* first node is address register */
	    ap1 = g_expr(node->v.p[0], F_AREG);
	    ap1 = copy_addr(ap1);
	    ap2 = g_expr(node->v.p[1], F_AREG | F_DREG);
	    if (ap2->mode == am_dreg) {
		/* 0(Ax,Dx) */
		ap1->mode = am_indx2;
		ap1->sreg = ap2->preg;
	    } else {
		/* 0(Ax,Ay) */
		ap1->mode = am_indx3;
		ap1->sreg = ap2->preg;
	    }
	    ap1->offset = mk_icon(0l);
	    return ap1;
	}
    }
    /* The general case (no tempref) */
    /* put address temprefs first place, data temprefs second place */
    if (node->v.p[1]->nodetype == en_tempref && node->v.p[1]->v.i >= 8)
	swap_nodes(node);
    else if (node->v.p[0]->nodetype == en_tempref && node->v.p[0]->v.i < 8)
	swap_nodes(node);

    ap1 = g_expr(node->v.p[0], F_AREG | F_IMMED);
    if (ap1->mode == am_areg) {
	ap2 = g_expr(node->v.p[1], F_AREG | F_DREG | F_IMMED);
	validate(ap1);
    } else {
	ap2 = ap1;
	ap1 = g_expr(node->v.p[1], F_AREG | F_IMMED);
	validate(ap2);
    }
    /*
     * possible combinations:
     * 
     * F_IMMED + F_IMMED F_AREG  + F_IMMED F_AREG  + F_DREG F_AREG  + F_AREG
     */


    /* watch out for: tempref(addr) + temp_addr, tempref(addr + temp_data */

    if (ap1->mode == am_areg && ap1->preg > MAX_ADDR) {
	/* ap1 = tempref address register */
	ap1 = copy_addr(ap1);
	if (ap2->mode == am_dreg) {
	    /* 0(Ax,Dy) */
	    ap1->mode = am_indx2;
	    ap1->sreg = ap2->preg;
	    ap1->deep = ap2->deep;
	    ap1->offset = mk_icon(0l);
	    return ap1;
	}
	if (ap2->mode == am_areg) {
	    /* 0(Ax,Ay) */
	    ap1->mode = am_indx3;
	    ap1->sreg = ap2->preg;
	    ap1->deep = ap2->deep;
	    ap1->offset = mk_icon(0l);
	    return ap1;
	}
	if (ap2->mode == am_immed && (!isshort(ap2->offset)))
	    /* we want to add to ap1 later... */
	    ap1 = mk_legal(ap1, F_AREG | F_VOL, 4l);

    }
    /* watch out for: temp_addr + tempref(data) */

    if (ap1->mode == am_areg && ap2->mode == am_dreg && ap2->preg > MAX_DATA) {
	ap1 = copy_addr(ap1);
	ap1->mode = am_indx2;
	ap1->sreg = ap2->preg;
	ap1->offset = mk_icon(0l);
	return ap1;
    }
    if (ap1->mode == am_immed && ap2->mode == am_immed) {
	ap1 = copy_addr(ap1);
	ap1->offset = mk_node(en_add, ap1->offset, ap2->offset);
	ap1->mode = am_direct;
	return ap1;
    }
    if (ap2->mode == am_immed && isshort(ap2->offset)) {
	ap1 = mk_legal(ap1, F_AREG, 4l);
	ap1 = copy_addr(ap1);
	ap1->mode = am_indx;
	ap1->offset = ap2->offset;
	return ap1;
    }
    /* ap1 is volatile ... */
    g_code(op_add, 4, ap2, ap1);/* add left to address reg */
    ap1 = copy_addr(ap1);
    ap1->mode = am_ind;		/* mk_ indirect */
    freeop(ap2);		/* release any temps in ap2 */
    return ap1;			/* return indirect */
}

struct amode   *
g_deref(node, type, flags, size)
/*
 * return the addressing mode of a dereferenced node.
 */
    struct enode    *node;
    enum e_bt        type;
    int              flags; /* determines if ainc modes are acceptable */
    long             size;
{
    struct amode   *ap1;
/*
 * If a reference to a struct/union is required, return a pointer to the
 * struct instead
 */
    if (type == bt_struct || type == bt_union) {
        return g_expr(node, F_ALL);
    }
    if (node->nodetype == en_add) {
	return g_index(node);
    }
    if (node->nodetype == en_autocon) {
	if (node->v.i >= -32768 && node->v.i < 32767) {
	    ap1 = (struct amode *) xalloc((int) sizeof(struct amode));
	    ap1->mode = am_indx;
	    ap1->preg = 6;
	    ap1->offset = mk_icon((long) node->v.i);
	} else {
	    ap1 = temp_addr();
	    g_code(op_move, 4, mk_immed((long) node->v.i), ap1);
	    g_code(op_add, 4, mk_reg(FRAMEPTR), ap1);
	    ap1 = copy_addr(ap1);
	    ap1->mode = am_ind;
	}
	return ap1;
    }
    /* special 68000 instructions */
    if (node->nodetype == en_ainc
        && (size ==1 || size ==2 || size ==4)
	&& node->v.p[1]->v.i == size
	&& node->v.p[0]->nodetype == en_tempref
	&& node->v.p[0]->v.i >= 8
	&& !(flags & F_USES)) {
	/* (An)+ */
	ap1 = (struct amode *) xalloc((int) sizeof(struct amode));
	ap1->mode = am_ainc;
	ap1->preg = node->v.p[0]->v.i - 8;
	return ap1;
    }
    ap1 = g_expr(node, F_AREG | F_IMMED);	/* generate address */
    ap1 = copy_addr(ap1);
    if (ap1->mode == am_areg) {
	ap1->mode = am_ind;
	return ap1;
    }
    ap1->mode = am_direct;
    return ap1;
}

struct amode   *
g_fderef(node, flags)
    struct enode   *node;
    int             flags;
/*
 * get a bitfield value
 */
{
    struct amode   *ap, *ap1;
    long            mask;
    int             width = node->bit_width + 1;

    ap = g_deref(node, node->etype, flags, node->esize);
    ap = mk_legal(ap, flags, node->esize);
    if (node->bit_offset > 0) {
	if (node->bit_offset <= 8) {
	    /* can shift with quick constant */
	    g_code(op_lsr, (int) node->esize,
		   mk_immed((long) node->bit_offset), ap);
	} else {
	    /* must load constant first */
	    ap1 = temp_data();
	    g_code(op_moveq, 0, mk_immed((long) node->bit_offset), ap1);
	    g_code(op_lsr, (int) node->esize, ap1, ap);
	    freeop(ap1);
	}
    }
    mask = 0;
    while (--width)
	mask = mask + mask + 1;
    g_code(op_and, (int) node->esize, mk_immed(mask), ap);

    return mk_legal(ap, flags, node->esize);
}


struct amode   *
g_unary(node, flags, op)
/*
 * generate code to evaluate a unary minus or complement. float: unary minus
 * calls a library function
 */
    struct enode   *node;
    int             flags;
    enum e_op       op;
{
    struct amode   *ap;
    long            i;
    switch (node->etype) {
      case bt_uchar:
      case bt_char:
      case bt_short:
      case bt_ushort:
      case bt_long:
      case bt_ulong:
      case bt_pointer:
	ap = g_expr(node->v.p[0], F_DREG | F_VOL);
	g_code(op, (int) node->esize, ap, NIL_AMODE);
	return mk_legal(ap, flags, node->esize);
      case bt_float:
      case bt_double:
	if (op == op_neg) {
	    temp_inv();
	    i = push_param(node->v.p[0]);
	    call_library(".fpneg");
	    return func_result(flags, i);
	}
    }
    fatal("g_unary: illegal type or operation");
    /* NOTREACHED */
}

struct amode   *
g_addsub(node, flags, op)
/*
 * generate code to evaluate a binary node and return the addressing mode of
 * the result.
 */
    struct enode   *node;
    int             flags;
    enum e_op       op;
{
    struct amode   *ap1, *ap2;
    long            i;
    switch (node->etype) {
      case bt_uchar:
      case bt_char:
      case bt_short:
      case bt_ushort:
      case bt_long:
      case bt_ulong:
      case bt_pointer:
	flags &= (F_DREG | F_AREG);
	ap1 = g_expr(node->v.p[0], F_VOL | flags);
	ap2 = g_expr(node->v.p[1], F_ALL);
	validate(ap1);		/* in case push occurred */
	g_code(op, (int) node->esize, ap2, ap1);
	freeop(ap2);
	return mk_legal(ap1, flags, node->esize);
      case bt_double:
	temp_inv();
	i = push_param(node->v.p[1]);
	i += push_param(node->v.p[0]);
	switch (op) {
	  case op_add:
	    call_library(".fpadd");
	    break;
	  case op_sub:
	    call_library(".fpsub");
	    break;
	}
	return func_result(flags, i);
    }

    fatal("g_addsub illegal type");
    /* NOTREACHED */
}

struct amode   *
g_xbin(node, flags, op)
/*
 * generate code to evaluate a restricted binary node and return the
 * addressing mode of the result.
 * these are bitwise operators so don't care about the type.
 * This needs to be revised with scalar types longer than 32 bit
 */
    struct enode   *node;
    int             flags;
    enum e_op       op;
{
    struct amode   *ap1, *ap2;
    ap1 = g_expr(node->v.p[0], F_VOL | F_DREG);
    ap2 = g_expr(node->v.p[1], F_DREG);
    validate(ap1);		/* in case push occurred */
    g_code(op, (int) node->esize, ap2, ap1);
    freeop(ap2);
    return mk_legal(ap1, flags, node->esize);
}

struct amode   *
g_ybin(node, flags, op)
/*
 * generate code to evaluate a restricted binary node and return the
 * addressing mode of the result.
 */
    struct enode   *node;
    int             flags;
    enum e_op       op;
{
    struct amode   *ap1, *ap2;
    ap1 = g_expr(node->v.p[0], F_VOL | F_DREG);
    ap2 = g_expr(node->v.p[1], F_ALL & ~F_AREG);
    validate(ap1);		/* in case push occurred */
    g_code(op, (int) node->esize, ap2, ap1);
    freeop(ap2);
    return mk_legal(ap1, flags, node->esize);
}

struct amode   *
g_shift(node, flags, op)
/*
 * generate code to evaluate a shift node and return the address mode of the
 * result.
 */
    struct enode   *node;
    int             flags;
    enum e_op       op;
{
    struct amode   *ap1, *ap2;

    if (op == op_asl && node->v.p[1]->nodetype == en_icon
	&& node->v.p[1]->v.i >= 1
	&& node->v.p[1]->v.i <= 2) {
	int             i;
	ap1 = g_expr(node->v.p[0], F_VOL | (flags & (F_DREG | F_AREG)));
	for (i = 1; i <= node->v.p[1]->v.i; ++i)
	    g_code(op_add, (int) node->esize, ap1, ap1);
    } else {
	ap1 = g_expr(node->v.p[0], F_DREG | F_VOL);
	ap2 = g_expr(node->v.p[1], F_DREG | F_IMMED);

	/* quick constant only legal if 1<=const<=8 */

	if (ap2->mode == am_immed && ap2->offset->nodetype == en_icon
	    && (ap2->offset->v.i > 8 || ap2->offset->v.i < 1)) {
	    if (ap2->offset->v.i <= 0 || ap2->offset->v.i > 32)
		fprintf(stderr, "warning: shift constant out of range\n");
	    ap2 = mk_legal(ap2, F_DREG, 1l);
	}
	validate(ap1);
	g_code(op, (int) node->esize, ap2, ap1);
	freeop(ap2);
    }

    return mk_legal(ap1, flags, node->esize);
}

struct amode   *
g_div(node, flags)
/*
 * generate code to evaluate a divide operator
 */
    struct enode   *node;
    int             flags;
{
    struct amode   *ap1, *ap2;
    long            i;
    switch (node->etype) {
      case bt_short:
      case bt_ushort:
	ap1 = g_expr(node->v.p[0], F_DREG | F_VOL);
	ap2 = g_expr(node->v.p[1], F_ALL);
	validate(ap1);
	if (node->etype == bt_short) {
	    g_code(op_ext, 4, ap1, NIL_AMODE);
	    g_code(op_divs, 0, ap2, ap1);
	} else {
	    g_code(op_and, 4, mk_immed(65535l), ap1);
	    g_code(op_divu, 0, ap2, ap1);
	}
	freeop(ap2);
	return mk_legal(ap1, flags, 2l);
      case bt_long:
      case bt_ulong:
      case bt_double:
	temp_inv();
	i = push_param(node->v.p[1]);
	i += push_param(node->v.p[0]);
	switch (node->etype) {
	  case bt_long:
	    call_library(".ldiv");
	    break;
	  case bt_ulong:
	    call_library(".uldiv");
	    break;
          case bt_double:
	    call_library(".fpdiv");
	    break;
	}
	return func_result(flags, i);
    }
    fatal("g_div: illegal type");
    /* NOTREACHED */
}

struct amode   *
g_mod(node, flags)
/*
 * generate code to evaluate a mod operator
 */
    struct enode   *node;
    int             flags;
{
    struct amode   *ap1, *ap2;
    long            i;
    switch (node->etype) {
      case bt_short:
      case bt_ushort:
	ap1 = g_expr(node->v.p[0], F_DREG | F_VOL);
	ap2 = g_expr(node->v.p[1], F_ALL);
	validate(ap1);
	if (node->etype == bt_short) {
	    g_code(op_ext, 4, ap1, NIL_AMODE);
	    g_code(op_divs, 0, ap2, ap1);
	} else {
	    g_code(op_and, 4, mk_immed(65535l), ap1);
	    g_code(op_divu, 0, ap2, ap1);
	}
	g_code(op_swap, 0, ap1, NIL_AMODE);
	freeop(ap2);
	return mk_legal(ap1, flags, 2l);
      case bt_long:
      case bt_ulong:
	temp_inv();
	i = push_param(node->v.p[1]);
	i += push_param(node->v.p[0]);
	if (node->etype == bt_long)
	    call_library(".lrem");
	else
	    call_library(".ulrem");
	return func_result(flags, i);
    }
    fatal("g_mod: illegal type");
    /* NOTREACHED */
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

struct amode   *
g_mul(node, flags)
/*
 * */
    struct enode   *node;
    int             flags;
{
    struct amode   *ap1, *ap2;
    long            i;
    switch (node->etype) {
      case bt_short:
      case bt_ushort:
	if (node->v.p[0]->nodetype == en_icon)
	    swap_nodes(node);
	ap1 = g_expr(node->v.p[0], F_DREG | F_VOL);
	ap2 = g_expr(node->v.p[1], F_ALL);
	validate(ap1);
	if (node->etype == bt_short)
	    g_code(op_muls, 0, ap2, ap1);
	else
	    g_code(op_mulu, 0, ap2, ap1);
	freeop(ap2);
	return mk_legal(ap1, flags, 2l);
      case bt_ulong:
      case bt_long:
      case bt_pointer:
      case bt_double:
	temp_inv();
	i = push_param(node->v.p[1]);
	i += push_param(node->v.p[0]);
	if (node->etype == bt_ulong)
	    call_library(".ulmul");
	else if (node->etype == bt_double)
	    call_library(".fpmult");
	else
	    call_library(".lmul");
	return func_result(flags, i);
    }
    fatal("g_mul: illegal type");
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
    int		    flagx;
    int		    result_is_void;
    long size=node->esize;
    false_label = nextlabel++;
    end_label = nextlabel++;

    result_is_void = ( node->etype == bt_void);
    if (node->etype == bt_struct || node->etype == bt_union) {
        size = 4;
    }

    if (!result_is_void) {
        flagx = (flags & (F_DREG | F_AREG)) == F_AREG ?
            F_AREG | F_VOL : F_DREG | F_VOL;
    } else {
        flagx = F_ALL | F_NOVALUE;
    }

    temp_inv(); /* I do not think I can avoid that */

    /* all scratch registers are void */

    falsejp(node->v.p[0], false_label);
    node = node->v.p[1];

    /* all scratch registers are void */

    ap1 = g_expr(node->v.p[0], flagx);
    freeop(ap1);

    /* all scratch registers are void */

    g_code(op_bra, 0, mk_label(end_label), NIL_AMODE);

    g_label(false_label);

    ap2 = g_expr(node->v.p[1], flagx);

    if (!result_is_void && !equal_address(ap1,ap2))
       fatal("G_HOOK: INCONSISTENCY");

    g_label(end_label);

    return mk_legal(ap2, flags, size);
}

struct amode   *
g_asadd(node, flags, op)
/*
 * generate a plus equal or a minus equal node.
 */
    struct enode   *node;
    int             flags;
    enum e_op       op;
{
    int             f;
    struct amode   *ap1, *ap2;
    switch (node->etype) {
      case bt_char:
      case bt_uchar:
      case bt_short:
      case bt_ushort:
      case bt_long:
      case bt_ulong:
      case bt_pointer:
	if (flags & F_NOVALUE)
	    f = F_ALL;
	else
	    f = F_ALL | F_USES;
	ap1 = g_expr(node->v.p[0], f);
	ap2 = g_expr(node->v.p[1], F_DREG | F_IMMED);
	validate(ap1);
	g_code(op, (int) node->esize, ap2, ap1);
	freeop(ap2);
	return mk_legal(ap1, flags, node->esize);
      case bt_float:
      case bt_double:
	if (op == op_add)
	    return as_fcall(node, flags, ".fpadd", ".asfpadd");
	else
	    return as_fcall(node, flags, ".fpsub", ".asfpsub");
    }
    fatal("asadd: illegal type");
    /* NOTREACHED */
}

struct amode   *
g_asxor(node, flags)
/*
 * generate an ^= node
 */
    struct enode   *node;
    int             flags;
{
    int             f;
    struct amode   *ap1, *ap2;
    switch (node->etype) {
      case bt_char:
      case bt_uchar:
      case bt_short:
      case bt_ushort:
      case bt_long:
      case bt_ulong:
      case bt_pointer:
	if (flags & F_NOVALUE)
	    f = F_ALL;
	else
	    f = F_ALL | F_USES;
	ap1 = g_expr(node->v.p[0], f);
	ap2 = g_expr(node->v.p[1], F_DREG | F_IMMED);
	validate(ap1);
	g_code(op_eor, (int) node->esize, ap2, ap1);
	freeop(ap2);
	return mk_legal(ap1, flags, node->esize);
    }
    fatal("asxor: illegal type");
    /* NOTREACHED */
}

struct amode   *
g_aslogic(node, flags, op)
/*
 * generate a and equal or a or equal node.
 */
    struct enode   *node;
    int             flags;
    enum e_op       op;
{
    int             f;
    struct amode   *ap1, *ap2, *ap3;
    if (flags & F_NOVALUE)
	f = F_ALL;
    else
	f = F_ALL | F_USES;
    ap1 = g_expr(node->v.p[0], f);
    ap2 = g_expr(node->v.p[1], F_DREG | F_IMMED);
    validate(ap1);
    if (ap1->mode != am_areg)
	g_code(op, (int) node->esize, ap2, ap1);
    else {
	ap3 = temp_data();
	g_code(op_move, 4, ap1, ap3);
	g_code(op, (int) node->esize, ap2, ap3);
	g_code(op_move, (int) node->esize, ap3, ap1);
	freeop(ap3);
    }
    freeop(ap2);
    return mk_legal(ap1, flags, node->esize);
}

struct amode   *
g_asshift(node, flags, op)
/*
 * generate shift equals operators.
 */
    struct enode   *node;
    int             flags;
    enum e_op       op;
{
    int             f;
    struct amode   *ap1, *ap2, *ap3;
    switch (node->etype) {
      case bt_uchar:
      case bt_char:
      case bt_ushort:
      case bt_short:
      case bt_ulong:
      case bt_long:
	if (flags & F_NOVALUE)
	    f = F_ALL;
	else
	    f = F_ALL | F_USES;
	ap1 = g_expr(node->v.p[0], f);
	if (ap1->mode != am_dreg) {
	    ap3 = temp_data();
	    g_code(op_move, (int) node->esize, ap1, ap3);
	} else
	    ap3 = ap1;
	ap2 = g_expr(node->v.p[1], F_DREG | F_IMMED);

	/* quick constant if 1<=const<=8 */

	if (ap2->mode == am_immed && ap2->offset->nodetype == en_icon
	    && (ap2->offset->v.i > 8 || ap2->offset->v.i < 1)) {
	    if (ap2->offset->v.i <= 0)
		fprintf(stderr, "warning: non-positive shift constant\n");
	    ap2 = mk_legal(ap2, F_DREG, 1l);
	}
	validate(ap3);
	g_code(op, (int) node->esize, ap2, ap3);
	freeop(ap2);
	if (ap3 != ap1) {
	    g_code(op_move, (int) node->esize, ap3, ap1);
	    freeop(ap3);
	}
	return mk_legal(ap1, flags, node->esize);
    }
    fatal("g_asshift: illegal type");
    /* NOTREACHED */
}

struct amode   *
g_asmul(node, flags)
/*
 * generate a *= node.
 */
    struct enode   *node;
    int             flags;
{
    struct amode   *ap1, *ap2, *ap3;
    enum e_op       op = op_mulu;
    switch (node->etype) {
      case bt_char:
	ap1 = g_expr(node->v.p[0], F_ALL | F_USES);
	if (ap1->mode != am_dreg) {
	    ap2 = temp_data();
	    g_code(op_move, 1, ap1, ap2);
	} else
	    ap2 = ap1;
	g_code(op_ext, 2, ap2, NIL_AMODE);
	ap3 = g_expr(node->v.p[1], F_DREG | F_IMMED);
	freeop(ap3);
	if (ap3->mode == am_dreg)
	    g_code(op_ext, 2, ap3, NIL_AMODE);
	g_code(op_muls, 0, ap3, ap2);
	if (ap2 != ap1) {
	    freeop(ap2);
	    g_code(op_move, 1, ap2, ap1);
	}
	return mk_legal(ap1, flags, node->esize);
      case bt_uchar:
	ap1 = g_expr(node->v.p[0], F_ALL | F_USES);
	if (ap1->mode != am_dreg) {
	    ap2 = temp_data();
	    g_code(op_move, 1, ap1, ap2);
	} else
	    ap2 = ap1;
	g_code(op_and, 2, mk_immed(255l), ap2);
	ap3 = g_expr(node->v.p[1], F_DREG | F_IMMED);
	freeop(ap3);
	if (ap3->mode == am_dreg)
	    g_code(op_and, 2, mk_immed(255l), ap3);
	g_code(op_mulu, 0, ap3, ap2);
	if (ap2 != ap1) {
	    freeop(ap2);
	    g_code(op_move, 1, ap2, ap1);
	}
	return mk_legal(ap1, flags, node->esize);
      case bt_short:
	op = op_muls;
      case bt_ushort:
	ap1 = g_expr(node->v.p[0], F_ALL | F_USES);
	ap2 = g_expr(node->v.p[1], F_ALL);
	if (ap1->mode != am_dreg) {
	    ap3 = temp_data();
	    validate(ap1);
	    freeop(ap2);
	    freeop(ap3);
	    g_code(op_move, 2, ap1, ap3);
	    g_code(op, 0, ap2, ap3);
	    g_code(op_move, 2, ap3, ap1);
	} else {
	    validate(ap1);
	    g_code(op_muls, 0, ap2, ap1);
	    freeop(ap2);
	}
	return mk_legal(ap1, flags, node->esize);
      case bt_long:
	return as_fcall(node, flags, ".lmul", ".aslmul");
      case bt_ulong:
      case bt_pointer:
	return as_fcall(node, flags, ".ulmul", ".asulmul");
      case bt_float:
      case bt_double:
	return as_fcall(node, flags, ".fpmult",".asfpmult");
    }
    fatal("asmul: illegal type");
    /* NOTREACHED */
}

struct amode   *
g_asdiv(node, flags)
/*
 * generate /= and %= nodes.
 */
    struct enode   *node;
    int             flags;
{
    struct amode   *ap1, *ap2, *ap3;
    switch (node->etype) {
      case bt_char:
	ap1 = g_expr(node->v.p[0], F_ALL | F_USES);
	if (ap1->mode != am_dreg) {
	    ap2 = temp_data();
	    g_code(op_move, 1, ap1, ap2);
	} else
	    ap2 = ap1;
	g_code(op_ext, 2, ap2, NIL_AMODE);
	g_code(op_ext, 4, ap2, NIL_AMODE);
	ap3 = g_expr(node->v.p[1], F_DREG | F_IMMED);
	freeop(ap3);
	if (ap3->mode == am_dreg)
	    g_code(op_ext, 2, ap3, NIL_AMODE);
	g_code(op_divs, 0, ap3, ap2);
	if (ap2 != ap1) {
	    freeop(ap2);
	    g_code(op_move, 1, ap2, ap1);
	}
	return mk_legal(ap1, flags, node->esize);
      case bt_uchar:
	ap1 = g_expr(node->v.p[0], F_ALL | F_USES);
	if (ap1->mode != am_dreg) {
	    ap2 = temp_data();
	    g_code(op_move, 1, ap1, ap2);
	} else
	    ap2 = ap1;
	g_code(op_and, 4, mk_immed(255l), ap2);
	ap3 = g_expr(node->v.p[1], F_DREG | F_IMMED);
	freeop(ap3);
	if (ap3->mode == am_dreg)
	    g_code(op_and, 2, mk_immed(255l), ap3);
	g_code(op_divu, 0, ap3, ap2);
	if (ap2 != ap1) {
	    freeop(ap2);
	    g_code(op_move, 1, ap2, ap1);
	}
	return mk_legal(ap1, flags, node->esize);
      case bt_short:
      case bt_ushort:
	ap1 = temp_data();
	ap2 = g_expr(node->v.p[0], F_ALL | F_USES);
	validate(ap1);
	g_code(op_move, 2, ap2, ap1);
	ap3 = g_expr(node->v.p[1], F_ALL & ~F_AREG);
	validate(ap2);
	validate(ap1);
	if (node->etype == bt_short) {
	    g_code(op_ext, 4, ap1, NIL_AMODE);
	    g_code(op_divs, 0, ap3, ap1);
	} else {
	    g_code(op_and, 4, mk_immed(65535l), ap1);
	    g_code(op_divu, 0, ap3, ap1);
	}
	freeop(ap3);
	g_code(op_move, 2, ap1, ap2);
	freeop(ap2);
	return mk_legal(ap1, flags, 2l);
      case bt_long:
	return as_fcall(node, flags, ".ldiv", ".asldiv");
      case bt_ulong:
      case bt_pointer:
	return as_fcall(node, flags, ".uldiv", ".asuldiv");
      case bt_double:
      case bt_float:
	return as_fcall(node, flags, ".fpdiv", ".asfpdiv");
    }
    fatal("asdiv: illegal type");
    /* NOTREACHED */
}

struct amode   *
g_asmod(node, flags)
/*
 * generate /= and %= nodes.
 */
    struct enode   *node;
    int             flags;
{
    struct amode   *ap1, *ap2, *ap3;
    switch (node->etype) {
      case bt_short:
      case bt_ushort:
	ap1 = temp_data();
	ap2 = g_expr(node->v.p[0], F_ALL | F_USES);
	validate(ap1);
	g_code(op_move, 2, ap2, ap1);
	ap3 = g_expr(node->v.p[1], F_ALL & ~F_AREG);
	validate(ap2);
	validate(ap1);
	if (node->etype == bt_short) {
	    g_code(op_ext, 4, ap1, NIL_AMODE);
	    g_code(op_divs, 0, ap3, ap1);
	} else {
	    g_code(op_and, 4, mk_immed(65535l), ap1);
	    g_code(op_divu, 0, ap3, ap1);
	}
	g_code(op_swap, 0, ap1, NIL_AMODE);
	freeop(ap3);
	g_code(op_move, 2, ap1, ap2);
	freeop(ap2);
	return mk_legal(ap1, flags, 2l);
      case bt_long:
	return as_fcall(node, flags, ".lrem", ".aslrem");
      case bt_ulong:
      case bt_pointer:
	return as_fcall(node, flags, ".ulrem", ".asulrem");
    }
    fatal("asmod: illegal type");
    /* NOTREACHED */
}

structassign(ap1, ap2, size)
/*
 * assign structure from ap1 to ap2
 * ap1, ap2 are scratch address registers
 */
    struct amode   *ap1, *ap2;
    long            size;
{
    long            loop;
    int             rest;
    long            i;
    struct amode   *ap3;
    unsigned int    label;

    ap1 = copy_addr(ap1);
    ap2 = copy_addr(ap2);
    ap1->mode = am_ainc;
    ap2->mode = am_ainc;
    loop = size / 4l;
    rest = (int) (size % 4l);
    if (loop <= 10)		/* loop-unrolling */
	for (i = 1; i <= loop; i++)
	    g_code(op_move, 4, ap1, ap2);
    else {
	loop--;			/* for dbra */
	ap3 = temp_data();
	freeop(ap3);
	label = nextlabel++;
	if (loop <= 65535) {	/* single loop */
	    g_code(op_move, 2, mk_immed(loop), ap3);
	    g_label(label);
	    g_code(op_move, 4, ap1, ap2);
	    g_code(op_dbra, 0, ap3, mk_label(label));
	} else {		/* extended loop */
	    g_code(op_move, 4, mk_immed(loop), ap3);
	    g_label(label);
	    g_code(op_move, 4, ap1, ap2);
	    g_code(op_dbra, 0, ap3, mk_label(label));
	    g_code(op_sub, 4, mk_immed(65536l), ap3);
	    g_code(op_bhs, 0, mk_label(label), NIL_AMODE);
	}
    }
    if (rest >= 2) {
	rest -= 2;
	g_code(op_move, 2, ap1, ap2);
    }
/* This cannot happen if the size of structures is always even */
    if (rest >= 1)
	g_code(op_move, 1, ap1, ap2);
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
    struct enode   *ep;
    long            size = node->esize;
    /*
     * */
    if (flags & F_NOVALUE)
	f = F_ALL;
    else
	f = F_ALL | F_USES;
    if (node->etype == bt_struct || node->etype == bt_union) {
/*
 * Other parts of this module return a pointer to a struct in a register,
 * not the struct itself
 */
	ap1 = g_expr(node->v.p[1], F_AREG | F_VOL);
	ap2 = g_expr(node->v.p[0], F_AREG | F_VOL);
	validate(ap1);

	/* hacky: save ap1 if needed later, structassign destroys it */
	if (!(flags & F_NOVALUE)) {
	    ap3 = temp_addr();
	    /* BTW, this code gets eliminated with MAX_ADDR = 1 */
	    g_code(op_move, 4, ap1, ap3);
	    structassign(ap3, ap2, size);
	    freeop(ap3);
	    freeop(ap2);
	    validate(ap1);
	    return mk_legal(ap1, flags, 4l);
	} else {
	    /* no need to save any registers */
	    structassign(ap1, ap2, node->esize);
	    freeop(ap2);
	    /* mk_legal is a no-op here */
	    return mk_legal(ap1, flags, 4l);
	}
    }
    if (node->v.p[0]->nodetype == en_fieldref) {
	long            mask;
	int             i;
	/*
	 * Field assignment
	 */
	/* get the value */
	ap1 = g_expr(node->v.p[1], F_DREG | F_VOL);
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
	    ap3 = temp_data();
	    g_code(op_move, 4, ap1, ap3);
	} else
	    ap3 = ap1;
	if (node->v.p[0]->bit_offset > 0) {
	    if (node->v.p[0]->bit_offset < 9) {
		g_code(op_asl, (int) size,
		       mk_immed((long) node->v.p[0]->bit_offset), ap3);
	    } else {
		ap2 = temp_data();
		g_code(op_moveq, 0,
		       mk_immed((long) node->v.p[0]->bit_offset), ap2);
		g_code(op_asl, (int) size, ap2, ap3);
		freeop(ap2);
	    }
	}
	ep = mk_node(en_ref, node->v.p[0]->v.p[0], NIL_ENODE);
	ap2 = g_expr(ep, F_MEM);
        validate(ap3);
	g_code(op_and, (int) size, mk_immed(~mask), ap2);
	g_code(op_or, (int) size, ap3, ap2);
	freeop(ap2);
        if (!(flags & F_NOVALUE)) {
            freeop(ap3);
	    validate(ap1);
        }
	return mk_legal(ap1, flags, size);
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
	ap1 = g_expr(node->v.p[0], f);
	ap2 = g_expr(node->v.p[1], F_ALL);
	validate(ap1);
	g_code(op_move, (int) size, ap2, ap1);
	freeop(ap2);
	return mk_legal(ap1, flags, size);
    } else {
	/* pass the right side as expr. value */
	/* normally, this is more efficient */
	ap1 = g_expr(node->v.p[1], f);
	ap2 = g_expr(node->v.p[0], F_ALL);
	validate(ap1);
	g_code(op_move, (int) size, ap1, ap2);
	freeop(ap2);
	return mk_legal(ap1, flags, size);
    }
}

struct amode   *
g_aincdec(node, flags, op)
/*
 * generate an auto increment or decrement node. op should be either op_add
 * (for increment) or op_sub (for decrement).
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
	if (flags & F_NOVALUE) {/* dont need result */
	    ap1 = g_expr(node->v.p[0], F_ALL);
	    g_code(op, (int) node->esize, mk_immed((long) node->v.p[1]->v.i),
		   ap1);
	    return mk_legal(ap1, flags, node->esize);
	}
	if (flags & F_DREG)
	    ap1 = temp_data();
	else
	    ap1 = temp_addr();
	ap2 = g_expr(node->v.p[0], F_ALL | F_USES);
	validate(ap1);
	g_code(op_move, (int) node->esize, ap2, ap1);
	g_code(op, (int) node->esize, mk_immed((long) node->v.p[1]->v.i), ap2);
	freeop(ap2);
	return mk_legal(ap1, flags, node->esize);
    }
    fatal("g_aincdec: illegal type or float");
    /* NOTREACHED */
}

long
push_param(ep)
/*
 * push the operand expression onto the stack. return the number of bytes
 * pushed
 */
    struct enode   *ep;
{
    struct amode   *ap, *ap1;
    long            size = ep->esize;

    /* pushing of structures and unions */
    if (ep->etype == bt_struct || ep->etype == bt_union) {
	if (lvalue(ep))
	    ep = ep->v.p[0];
        /* all other cases return a pointer to the struct anyway */
	/* allocate stack space */
	g_code(op_sub, 4, mk_immed(size), mk_reg(STACKPTR));
/*
 * F_VOL was missing in the following line --
 * it took a hard-core debugging session to find this error
 */
	ap = g_expr(ep, F_AREG | F_VOL);
	ap1 = temp_addr();
	validate(ap);
	g_code(op_move, 4, mk_reg(STACKPTR), ap1);
	/* now, copy it on stack - the same as structassign */
	structassign(ap, ap1, size);
	freeop(ap1);
	freeop(ap);
	return size;
    }
    ap = g_expr(ep, F_ALL);

    /*
     * This is a hook for the peephole optimizer, which will convert lea
     * <ea>,An + pea (An) ==> pea <ea>
     */

    if (ap->mode == am_areg && size == 4 && ap->preg <= MAX_ADDR) {
	ap = copy_addr(ap);
	ap->mode = am_ind;
	g_code(op_pea, 0, ap, NIL_AMODE);
    } else
	g_code(op_move, (int) size, ap, &push);
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
func_result(flags, bytes)
    int             flags;
    long            bytes;
{
    /*
     * saves a function call result in D0 it is assumed that flags contain
     * either F_DREG or F_AREG return value is the addressing mode of the
     * result bytes is the number of bytes to pop off the stack
     *
     * This routine does not use mk_legal and takes care of the stuff itself.
     */
    struct amode   *ap;
    if (bytes != 0)
	/* adjust stack pointer */
	g_code(op_add, 4, mk_immed(bytes), mk_reg(STACKPTR));
    if (flags & F_NOVALUE)
        return 0;
    if (flags & F_DREG) {
	ap = temp_data();
	g_code(op_move, 4, mk_reg(RESULT), ap);
    } else if (flags & F_AREG) {
	ap = temp_addr();
	g_code(op_move, 4, mk_reg(RESULT), ap);
    } else {
	fatal("func_result: illegal addressing mode");
    }
    return ap; 
}

struct amode   *
as_fcall(node, flags, libnam1,libnam2)
    struct enode   *node;
    int             flags;
    char           *libnam1;
    char	   *libnam2;
/* assignment operations with library calls */
{
/*
 * example: libnam1 = ".ldiv", libnam2 = ".asldiv"
 */
    long            i;
    struct amode   *ap1;
    long            size;
    size = node->esize;
    temp_inv();
    i = push_param(node->v.p[1]);
    if (node->v.p[0]->nodetype == en_tempref) {
	/* ap1 cannot be destroyed, no problem */
	ap1 = g_expr(node->v.p[0], F_DREG | F_AREG);
	g_code(op_move, (int) size, ap1, &push);
	i += size;
	call_library(libnam1);
	/* ap1 is always valid and not equal to RESULT */
	g_code(op_move, (int) size, mk_reg(RESULT), ap1);
    } else {
	/* pass a pointer to the left side, call special function */
	i += push_param(node->v.p[0]->v.p[0]);
	call_library(libnam2);
    }
    g_code(op_add, 4, mk_immed((long) i), mk_reg(STACKPTR));
    if (!(flags & F_NOVALUE)) {
	if (flags & F_AREG)
	    ap1 = temp_addr();
	else
	    ap1 = temp_data();
	g_code(op_move, 4, mk_reg(RESULT), ap1);
	return mk_legal(ap1, flags, size);
    } else
	return 0;

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
    /* push any used addr&data temps */
    temp_inv();
    i = g_parms(node->v.p[1]);	/* generate parameters */
    /*
     * for functions returning a structure or a union, push a pointer to the
     * return value as additional argument The scratch space will be
     * allocated in the stack frame of the calling function.
     */
    if (node->etype == bt_struct || node->etype == bt_union) {
	ap = mk_scratch(node->esize);
	g_code(op_pea, 0, ap, NIL_AMODE);
	i += 4l;
	freeop(ap);
    }
    /* call the function */
    if (node->v.p[0]->nodetype == en_nacon ||
	node->v.p[0]->nodetype == en_labcon)
	g_code(op_jsr, 0, mk_offset(node->v.p[0]), NIL_AMODE);
    else {
	ap = g_expr(node->v.p[0], F_AREG);
	ap = copy_addr(ap);
	ap->mode = am_ind;
	freeop(ap);
	g_code(op_jsr, 0, ap, NIL_AMODE);
    }
    return func_result(flags, i);
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
    struct amode   *ap1;
    int            f;

    if (flags & F_NOVALUE) {
        freeop(ap);
	return 0;
    }

    if (typ1 == typ2)
	/*
	 * this can happen in with the g_xmul stuff, where a cast from
	 * (u)short to long now casts from (u)short to (u)short for an 68000
	 * mulu or muls instruction.
	 * It is save to cut things short then.
	 * It should not happen with types other than (u)short, but
	 * it does not harm either.
	 */
	if (typ1 == bt_short || typ1 == bt_ushort)
	    return mk_legal(ap, flags, 2l);
	else
	    fprintf(stderr,"DEBUG: g_cast: typ1 == typ2\n");

    switch (typ2) {
	/* switch: type to cast to */
      case bt_char:
      case bt_uchar:
	switch (typ1) {
	  case bt_uchar:
	  case bt_char:
	    return mk_legal(ap, flags, 1l);
	  case bt_ushort:
	  case bt_short:
	    if ((ap1 = g_offset(ap, 1)) == 0)
		ap1 = mk_legal(ap, F_DREG, 2l);
	    return mk_legal(ap1, flags, 1l);
	  case bt_ulong:
	  case bt_long:
	  case bt_pointer:
	    if ((ap1 = g_offset(ap, 3)) == 0)
		ap1 = mk_legal(ap, F_DREG, 4l);
	    return mk_legal(ap1, flags, 1l);
	  case bt_float:
          case bt_double:
	    return g_cast(g_cast(ap, bt_double, bt_long, F_DREG),
			  bt_long, typ2, F_DREG);
	}
        break;
      case bt_ushort:
      case bt_short:
	switch (typ1) {
	  case bt_uchar:
	    ap = mk_legal(ap, F_DREG | F_VOL, 1l);
	    g_code(op_and, 2, mk_immed(255l), ap);
	    return mk_legal(ap, flags, 2l);
	  case bt_char:
	    ap = mk_legal(ap, F_DREG, 1l);
	    g_code(op_ext, 2, ap, NIL_AMODE);
	    return mk_legal(ap, flags, 2l);
	  case bt_short:
	  case bt_ushort:
	    return mk_legal(ap, flags, 2l);
	  case bt_long:
	  case bt_ulong:
	  case bt_pointer:
	    if ((ap1 = g_offset(ap, 2)) == 0)
		ap1 = mk_legal(ap, F_DREG, 4l);
	    return mk_legal(ap1, flags, 2l);
	  case bt_float:
          case bt_double:
	    return g_cast(g_cast(ap, bt_double, bt_long, F_DREG),
			  bt_long, typ2, F_DREG);
	}
        break;
      case bt_long:
      case bt_ulong:
      case bt_pointer:
	switch (typ1) {
	  case bt_uchar:
	    ap = mk_legal(ap, F_DREG | F_VOL, 1l);
	    g_code(op_and, 4, mk_immed(255l), ap);
	    return mk_legal(ap, flags, 4l);
	  case bt_char:
	    ap = mk_legal(ap, F_DREG, 1l);
	    g_code(op_ext, 2, ap, NIL_AMODE);
	    g_code(op_ext, 4, ap, NIL_AMODE);
	    return mk_legal(ap, flags, 4l);
	  case bt_ushort:
	    ap = mk_legal(ap, F_DREG | F_VOL, 2l);
	    g_code(op_and, 4, mk_immed(65535l), ap);
	    return mk_legal(ap, flags, 4l);
	  case bt_short:
            f = flags & (F_DREG | F_AREG);
            if (f == 0) f = F_DREG | F_AREG;
	    ap = mk_legal(ap, f, 2l);
	    if (ap->mode == am_dreg)
		g_code(op_ext, 4, ap, NIL_AMODE);
	    return mk_legal(ap, flags, 4l);
	  case bt_long:
	  case bt_ulong:
	  case bt_pointer:
	    return mk_legal(ap, flags, 4l);
	  case bt_float:
          case bt_double:
	    /* library call */
	    freeop(ap);
	    temp_inv();
	    g_code(op_move, 4, ap, &push);
	    if (typ2 == bt_long)
		call_library(".fpftol");
	    else
		call_library(".fpftou");
	    return func_result(flags, 4l);
	}
        break;
      case bt_float:
      case bt_double:
	switch (typ1) {
	  case bt_char:
	  case bt_uchar:
	  case bt_short:
	  case bt_ushort:
	    ap = g_cast(ap, typ1, bt_long, F_ALL);
	  case bt_long:
	  case bt_ulong:
	  case bt_pointer:
	    /* library call */
	    freeop(ap);
	    temp_inv();
	    g_code(op_move, 4, ap, &push);
	    if (typ1 == bt_ulong || typ1 == bt_pointer)
		call_library(".fputof");
	    else
		call_library(".fpltof");
	    return func_result(flags, 4l);
	  case bt_float:
          case bt_double:
	    return mk_legal(ap, flags, 4l);
	}
        break;
    }
    fatal("g_cast: illegal combination");
    /* NOTREACHED */
}

struct amode   *
g_offset(ap, off)
    struct amode   *ap;
    int             off;
/*
 * return true, if ap can be switched to address a location with a short
 * offset. typical application: cast long -> short: 8(a6) --> 10(a6) offset
 * is a small number (1,2 or 3)
 */
{
    switch (ap->mode) {
      case am_ind:
	ap = copy_addr(ap);
	ap->mode = am_indx;
	ap->offset = mk_icon((long) off);
	return ap;
      case am_indx:
	if (ap->offset->nodetype == en_icon &&
	    off + ap->offset->v.i <= 32767) {
	    ap = copy_addr(ap);
	    ap->offset->v.i += off;
	    return ap;
	}
	break;
      case am_indx2:
      case am_indx3:
	if (ap->offset->nodetype == en_icon &&
	    off + ap->offset->v.i <= 127) {
	    ap = copy_addr(ap);
	    ap->offset->v.i += off;
	    return ap;
	}
	break;
      case am_direct:
	ap = copy_addr(ap);
	ap->offset = mk_node(en_add, ap->offset,
			     mk_icon((long) off));
	return ap;
    }
    /* special value indicating that it must be done by hand */
    return 0;
}

struct amode   *
g_xmul(node, flags, op)
/*
 * performs a mixed-mode multiplication
 */
    struct enode   *node;
    int             flags;
    enum e_op       op;
{
    struct amode   *ap1, *ap2;

    ap1 = g_expr(node->v.p[1], F_DREG | F_VOL);
    ap2 = g_expr(node->v.p[0], F_ALL & ~F_AREG);
    validate(ap1);

    g_code(op, 0, ap2, ap1);
    freeop(ap2);
    return mk_legal(ap1, flags, node->esize);
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
    enum e_bt       type;
    if (node == 0) {
	fatal("null node in g_expr");
    }
    if (tst_const(node)) {
	ap1 = (struct amode *) xalloc((int) sizeof(struct amode));
	ap1->mode = am_immed;
	ap1->offset = node;
	return mk_legal(ap1, flags, node->esize);
    }
    type = node->etype;
    size = node->esize;
    switch (node->nodetype) {
      case en_autocon:
	ap1 = temp_addr();
	if (node->v.i >= -32768 && node->v.i <= 32767) {
	    ap2 = (struct amode *) xalloc((int) sizeof(struct amode));
	    ap2->mode = am_indx;
	    ap2->preg = FRAMEPTR - 8;	/* frame pointer */
	    ap2->offset = node;	/* use as constant node */
	    g_code(op_lea, 0, ap2, ap1);
	} else {
	    g_code(op_move, 4, mk_immed((long) node->v.p[0]->v.i), ap1);
	    g_code(op_add, 4, mk_reg(FRAMEPTR), ap1);
	    ap1 = copy_addr(ap1);
	    ap1->mode = am_ind;
	}
	return mk_legal(ap1, flags, size);
      case en_ref:
/*
 * g_deref uses flags and size only to test F_USES
 */
        ap1 = g_deref(node->v.p[0], type, flags, node->esize);
        if (type == bt_struct || type == bt_union)
            return mk_legal(ap1, flags, 4l);
        else
	    return mk_legal(ap1, flags, size);
      case en_fieldref:
	return g_fderef(node, flags);
      case en_tempref:
	ap1 = (struct amode *) xalloc((int) sizeof(struct amode));
	if (node->v.i < 8) {
	    ap1->mode = am_dreg;
	    ap1->preg = node->v.i;
	} else {
	    ap1->mode = am_areg;
	    ap1->preg = node->v.i - 8;
	}
	return mk_legal(ap1, flags, size);
      case en_uminus:
	return g_unary(node, flags, op_neg);
      case en_compl:
	return g_unary(node, flags, op_not);
      case en_add:
	return g_addsub(node, flags, op_add);
      case en_sub:
	return g_addsub(node, flags, op_sub);
      case en_and:
	return g_ybin(node, flags, op_and);
      case en_or:
	return g_ybin(node, flags, op_or);
      case en_xor:
	return g_xbin(node, flags, op_eor);
      case en_mul:
	/*
	 * special optimization possible if there are patterns matching the
	 * 68000 mulu, muls instructions. ugly, but it gives a big
	 * performance increase
	 */
	if (type == bt_long || type == bt_ulong || type == bt_pointer) {
	    if (tst_ushort(node->v.p[0]) && tst_ushort(node->v.p[1])) {
		node->v.p[0]->etype = bt_ushort;
		node->v.p[0]->esize = 2;
		node->v.p[1]->etype = bt_ushort;
		node->v.p[1]->esize = 2;
		return g_xmul(node, flags, op_mulu);
	    } else if (tst_short(node->v.p[0]) && tst_short(node->v.p[1])) {
		node->v.p[0]->etype = bt_short;
		node->v.p[0]->esize = 2;
		node->v.p[1]->etype = bt_short;
		node->v.p[1]->esize = 2;
		return g_xmul(node, flags, op_muls);
	    }
	}
	return g_mul(node, flags);
      case en_div:
	return g_div(node, flags);
      case en_mod:
	return g_mod(node, flags);
      case en_lsh:
	return g_shift(node, flags, op_asl);
      case en_rsh:
        if (type==bt_ulong || type==bt_ushort || type==bt_uchar)
	    return g_shift(node, flags, op_lsr);
	else
	    return g_shift(node, flags, op_asr);
      case en_asadd:
	return g_asadd(node, flags, op_add);
      case en_assub:
	return g_asadd(node, flags, op_sub);
      case en_asand:
	return g_aslogic(node, flags, op_and);
      case en_asor:
	return g_aslogic(node, flags, op_or);
      case en_aslsh:
	return g_asshift(node, flags, op_asl);
      case en_asrsh:
        if (type==bt_ulong || type==bt_ushort || type==bt_uchar)
	    return g_asshift(node, flags, op_lsr);
	else
	    return g_asshift(node, flags, op_asr);
      case en_asmul:
	return g_asmul(node, flags);
      case en_asdiv:
	return g_asdiv(node, flags);
      case en_asmod:
	return g_asmod(node, flags);
      case en_asxor:
	return g_asxor(node, flags);
      case en_assign:
	return g_assign(node, flags);
      case en_ainc:
	return g_aincdec(node, flags, op_add);
      case en_adec:
	return g_aincdec(node, flags, op_sub);
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
	ap1 = temp_data();
	g_code(op_moveq, 0, mk_immed(1l), ap1);
	g_code(op_bra, 0, mk_label(lab1), NIL_AMODE);
	g_label(lab0);
	g_code(op_moveq, 0, mk_immed(0l), ap1);
	g_label(lab1);
	return mk_legal(ap1, flags, size);
      case en_cond:
	return g_hook(node, flags);
      case en_void:
	freeop(g_expr(node->v.p[0], F_ALL | F_NOVALUE));
	return g_expr(node->v.p[1], flags);
      case en_fcall:
	return g_fcall(node, flags);
      case en_cast:
        /*
         * On the 68000, suppress all casts between any of
         * long, unsigned long, pointer
         */
        if (type == bt_pointer || type == bt_long || type == bt_ulong) {
            type = node->v.p[0]->etype;
            if (type == bt_pointer || type == bt_long || type == bt_ulong)
                return g_expr(node->v.p[0], flags);
        }
        /*
         * The cast really results in some work
         */
	return g_cast(g_expr(node->v.p[0], F_ALL | F_USES),
		      node->v.p[0]->etype,
		      node->etype, flags);
      case en_deref:
	/*
	 * The cases where this node occurs are handled automatically:
	 * g_assign and g_fcall return a pointer to a structure rather than a
	 * structure.
	 */
	return g_expr(node->v.p[0], flags);
      default:
	fatal("uncoded node in g_expr");
	/* NOTREACHED */
    }
}

tst_ushort(node)
    struct enode   *node;
/*
 * tests if node is a integer constant falling in the range of uns. short or
 * if node is cast from uns. short, uns. char or char.
 */
{
    enum e_bt       type;

    if (node->nodetype == en_icon && 0 <= node->v.i && node->v.i <= 65535)
	return 1;

    if (node->nodetype == en_cast) {
	type = node->v.p[0]->etype;
	if (type == bt_ushort || type == bt_uchar || type == bt_char)
	    return 1;
    }
    return 0;
}

tst_short(node)
    struct enode   *node;
/*
 * tests if node is a integer constant falling in the range of short or if
 * node is cast from short.
 */
{
    enum e_bt       type;

    if (node->nodetype == en_icon && -32768 <= node->v.i && node->v.i <= 32767)
	return 1;

    if (node->nodetype == en_cast) {
	type = node->v.p[0]->etype;
	if (type == bt_short || type == bt_char || type == bt_uchar)
	    return 1;
    }
    return 0;
}

tst_const(node)
    struct enode   *node;
/*
 * tests if it is a constant node, that means either en_icon, en_nacon or
 * en_labcon, or sums or differences of such nodes
 */
{
    enum e_node     typ1 = node->nodetype;
    enum e_node     typ2;
    if (typ1 == en_icon || typ1 == en_nacon || typ1 == en_labcon
	|| typ1 == en_fcon)
	return 1;

    if (typ1 == en_add || typ1 == en_sub) {
	typ1 = node->v.p[0]->nodetype;
	typ2 = node->v.p[1]->nodetype;
	if (((typ1 == en_nacon || typ1 == en_labcon) && typ2 == en_icon) ||
	    ((typ2 == en_nacon || typ2 == en_labcon) && typ1 == en_icon))
	    return 1;
    }
    return 0;
}


static
g_compare(node)
/*
 * generate code to do a comparison of the two operands of node. returns 1 if
 * it was an unsigned comparison
 */
    struct enode   *node;
{
    struct amode   *ap1, *ap2, *ap3;
    long            i;
    switch (node->v.p[0]->etype) {
      case bt_uchar:
      case bt_char:
      case bt_ushort:
      case bt_short:
      case bt_pointer:
      case bt_long:
      case bt_ulong:
	ap2 = g_expr(node->v.p[1], F_ALL);
	if (ap2->mode == am_immed)
	    ap1 = g_expr(node->v.p[0], F_ALL & ~F_IMMED);
	else
	    ap1 = g_expr(node->v.p[0], F_AREG | F_DREG);
	validate(ap2);
	/*
	 * sorry, no tst.l An on the 68000, but we can move to a data
	 * register if one is free
	 */
	if (ap1->mode == am_areg && node->v.p[1]->nodetype == en_icon
	    && node->v.p[1]->v.i == 0 && free_data()) {
	    ap3 = temp_data();
	    g_code(op_move, 4, ap1, ap3);
	    /* tst.l ap3 not needed */
	    freeop(ap3);
	} else
	    g_code(op_cmp, (int) node->v.p[0]->esize, ap2, ap1);
	freeop(ap1);
	freeop(ap2);
	if (node->v.p[0]->etype == bt_char ||
	    node->v.p[0]->etype == bt_short ||
	    node->v.p[0]->etype == bt_long)
	    return 0;
	return 1;
      case bt_float:
      case bt_double:
	temp_inv();
	i = push_param(node->v.p[1]);
	i += push_param(node->v.p[0]);
	call_library(".fpcmp");
	g_code(op_add, 4, mk_immed((long) i), mk_reg(STACKPTR));
	return 0;
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
    struct amode   *ap;
    unsigned int    lab0;
    if (node == 0)
	fatal("TRUEJP");
    if (node->nodetype == en_icon) {
	if (node->v.i)
	    g_code(op_bra, 0, mk_label(label), NIL_AMODE);
	return;
    }
    opt_compare(node);
    switch (node->nodetype) {
      case en_eq:
	(void) g_compare(node);
	g_code(op_beq, 0, mk_label(label), NIL_AMODE);
	break;
      case en_ne:
	(void) g_compare(node);
	g_code(op_bne, 0, mk_label(label), NIL_AMODE);
	break;
      case en_lt:
	g_compare(node) ?
	    g_code(op_blo, 0, mk_label(label), NIL_AMODE) :
	    g_code(op_blt, 0, mk_label(label), NIL_AMODE);
	break;
      case en_le:
	g_compare(node) ?
	    g_code(op_bls, 0, mk_label(label), NIL_AMODE) :
	    g_code(op_ble, 0, mk_label(label), NIL_AMODE);
	break;
      case en_gt:
	g_compare(node) ?
	    g_code(op_bhi, 0, mk_label(label), NIL_AMODE) :
	    g_code(op_bgt, 0, mk_label(label), NIL_AMODE);
	break;
      case en_ge:
	g_compare(node) ?
	    g_code(op_bhs, 0, mk_label(label), NIL_AMODE) :
	    g_code(op_bge, 0, mk_label(label), NIL_AMODE);
	break;
      case en_land:
	lab0 = nextlabel++;
	falsejp(node->v.p[0], lab0);
	truejp(node->v.p[1], label);
	g_label(lab0);
	break;
      case en_lor:
	truejp(node->v.p[0], label);
	truejp(node->v.p[1], label);
	break;
      case en_not:
	falsejp(node->v.p[0], label);
	break;
      default:
	if (node->etype == bt_float || node->etype == bt_double) {
	    long            i;
	    temp_inv();
	    i = push_param(node);
	    call_library(".fptst");
	    /* The pop-off does not change the condition codes */
	    g_code(op_add, 4, mk_immed((long) i), mk_reg(STACKPTR));
	} else {
	    ap = g_expr(node, F_DALT);
	    g_code(op_tst, (int) node->esize, ap, NIL_AMODE);
	    freeop(ap);
	}
	g_code(op_bne, 0, mk_label(label), NIL_AMODE);
	break;
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
    opt_compare(node);
    switch (node->nodetype) {
      case en_eq:
	(void) g_compare(node);
	g_code(op_bne, 0, mk_label(label), NIL_AMODE);
	break;
      case en_ne:
	(void) g_compare(node);
	g_code(op_beq, 0, mk_label(label), NIL_AMODE);
	break;
      case en_lt:
	g_compare(node) ?
	    g_code(op_bhs, 0, mk_label(label), NIL_AMODE) :
	    g_code(op_bge, 0, mk_label(label), NIL_AMODE);
	break;
      case en_le:
	g_compare(node) ?
	    g_code(op_bhi, 0, mk_label(label), NIL_AMODE) :
	    g_code(op_bgt, 0, mk_label(label), NIL_AMODE);
	break;
      case en_gt:
	g_compare(node) ?
	    g_code(op_bls, 0, mk_label(label), NIL_AMODE) :
	    g_code(op_ble, 0, mk_label(label), NIL_AMODE);
	break;
      case en_ge:
	g_compare(node) ?
	    g_code(op_blo, 0, mk_label(label), NIL_AMODE) :
	    g_code(op_blt, 0, mk_label(label), NIL_AMODE);
	break;
      case en_land:
	falsejp(node->v.p[0], label);
	falsejp(node->v.p[1], label);
	break;
      case en_lor:
	lab0 = nextlabel++;
	truejp(node->v.p[0], lab0);
	falsejp(node->v.p[1], label);
	g_label(lab0);
	break;
      case en_not:
	truejp(node->v.p[0], label);
	break;
      default:
	if (node->etype == bt_float || node->etype == bt_double) {
	    long            i;
	    temp_inv();
	    i = push_param(node);
	    call_library(".fptst");
	    /* The pop-off does not change the condition codes */
	    g_code(op_add, 4, mk_immed((long) i), mk_reg(STACKPTR));
	} else {
	    ap = g_expr(node, F_DALT);
	    g_code(op_tst, (int) node->esize, ap, NIL_AMODE);
	    freeop(ap);
	}
	g_code(op_beq, 0, mk_label(label), NIL_AMODE);
	break;
    }
}

opt_compare(node)
    struct enode   *node;
{
    /* temprefs should be the second operand to a cmp instruction */
    enum e_node     t = node->nodetype;
    if ((t == en_eq || t == en_ne || t == en_le || t == en_ge
	 || t == en_lt || t == en_gt)
	&& (node->v.p[1]->nodetype == en_tempref ||
	    node->v.p[0]->nodetype == en_icon)) {

        swap_nodes(node);
	/* if you change the operands, change the comparison operator */
	switch (t) {
	  case en_le:
	    node->nodetype = en_ge;
	    break;
	  case en_ge:
	    node->nodetype = en_le;
	    break;
	  case en_lt:
	    node->nodetype = en_gt;
	    break;
	  case en_gt:
	    node->nodetype = en_lt;
	    break;
	}
    }
}
#endif /* MC680X0 */
