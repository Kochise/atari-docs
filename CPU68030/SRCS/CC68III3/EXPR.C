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
#include	<ctype.h>

static unsigned char sizeof_flag = 0;

/*
 * expression evaluation
 *
 * this set of routines builds a parse tree for an expression. no code is
 * generated for the expressions during the build, this is the job of the
 * codegen module. for most purposes expression() is the routine to call. it
 * will allow all of the C operators. for the case where the comma operator
 * is not valid (function parameters for instance) call exprnc().
 *
 * each of the routines returns a pointer to a describing type structure. each
 * routine also takes one parameter which is a pointer to an expression node
 * by reference (address of pointer). the completed expression is returned in
 * this pointer. all routines return either a pointer to a valid type or NULL
 * if the hierarchy of the next operator is too low or the next symbol is not
 * part of an expression.
 */

static TYP     *primary();
static TYP     *unary();
static TYP     *multops();
static TYP     *addops();
static          isscalar();

struct enode   *
mk_node(nt, v1, v2)
/*
 * build an expression node with a node type of nt and values v1 and v2.
 */
    enum e_node     nt;
    struct enode   *v1, *v2;
{
    struct enode   *ep;
    ep = (struct enode *) xalloc((int) sizeof(struct enode));
    ep->nodetype = nt;
    ep->etype = bt_void;
    ep->esize = -1;
    ep->v.p[0] = v1;
    ep->v.p[1] = v2;
    return ep;
}

struct enode   *
mk_icon(i)
/*
 * build an expression node forming an integer constant
 */
    long            i;
{
    struct enode   *ep;
    ep = (struct enode *) xalloc((int) sizeof(struct enode));
    ep->nodetype = en_icon;
    ep->etype = bt_void;
    ep->esize = 0;
    ep->v.i = i;
    return ep;
}

TYP            *
deref(node, tp)
/*
 * build the proper dereference operation for a node using the type pointer
 * tp.
 */
    struct enode  **node;
    TYP            *tp;
{
    switch (tp->type) {
      case bt_char:
      case bt_uchar:
      case bt_short:
      case bt_ushort:
      case bt_long:
      case bt_pointer:
      case bt_ulong:
      case bt_struct:
      case bt_union:
      case bt_float:
      case bt_double:
	*node = mk_node(en_ref, *node, NIL_ENODE);
	(*node)->etype = tp->type;
	(*node)->esize = tp->size;
	break;
      case bt_bitfield:
	*node = mk_node(en_fieldref, *node, NIL_ENODE);
	(*node)->bit_width = tp->bit_width;
	(*node)->bit_offset = tp->bit_offset;
	/*
	 * maybe it should be 'unsigned'
	 */
	(*node)->etype = tp_int.type;
	(*node)->esize = tp_int.size;
	tp = &tp_int;
	break;
      default:
	error(ERR_DEREF);
	break;
    }
    return tp;
}

TYP            *
cond_deref(node, tp)
    struct enode  **node;
    TYP            *tp;
{
    TYP            *tp1;
    /*
     * dereference the node if val_flag is zero. If val_flag is non_zero and
     * tp->type is bt_pointer (array reference) set the size field to the
     * pointer size if this code is not executed on behalf of a sizeof
     * operator
     */

    if (tp->val_flag == 0)
	return deref(node, tp);
    if (tp->type == bt_pointer && sizeof_flag == 0) {
	tp1 = tp->btp;
	tp = mk_type(bt_pointer, 4);
	tp->btp = tp1;
    }
    return tp;
}


TYP            *
nameref(node)
/*
 * nameref will build an expression tree that references an identifier. if
 * the identifier is not in the global or local symbol table then a
 * look-ahead to the next character is done and if it indicates a function
 * call the identifier is coerced to an external function name. non-value
 * references generate an additional level of indirection.
 */
    struct enode  **node;
{
    struct sym     *sp;
    TYP            *tp;
    sp = gsearch(lastid);
    if (sp == 0) {
	while (isspace(lastch))
	    getch();
	if (lastch == '(') {
	    ++global_flag;
	    sp = (struct sym *) xalloc((int) sizeof(struct sym));
	    sp->tp = &tp_func;
	    sp->name = strsave(lastid);
	    sp->storage_class = sc_external;
	    append(&sp, &gsyms);
	    --global_flag;
	    tp = &tp_func;
	    *node = mk_node(en_nacon, NIL_ENODE, NIL_ENODE);
	    (*node)->v.sp = sp->name;
	    sp->used = 1;
	    (*node)->etype = bt_pointer;
	    (*node)->esize = 4;
	} else {
	    tp = 0;
	    error(ERR_UNDEFINED);
	}
    } else {
	if ((tp = sp->tp) == 0) {
	    error(ERR_UNDEFINED);
	    return 0;		/* guard against untyped entries */
	}
	switch (sp->storage_class) {
	  case sc_static:
	    *node = mk_node(en_labcon, NIL_ENODE, NIL_ENODE);
	    (*node)->v.i = sp->value.i;
	    (*node)->etype = bt_pointer;
	    (*node)->esize = 4;
	    break;
	  case sc_global:
	  case sc_external:
	    *node = mk_node(en_nacon, NIL_ENODE, NIL_ENODE);
	    (*node)->v.sp = sp->name;
	    sp->used = 1;
	    (*node)->etype = bt_pointer;
	    (*node)->esize = 4;
	    break;
	  case sc_const:
	    *node = mk_icon((long) sp->value.i);
	    (*node)->etype = tp_econst.type;
	    (*node)->esize = tp_econst.size;
	    break;
	  default:		/* auto and any errors */
	    if (sp->storage_class != sc_auto)
		error(ERR_ILLCLASS);
	    *node = mk_node(en_autocon, NIL_ENODE, NIL_ENODE);
	    (*node)->v.i = sp->value.i;
	    (*node)->etype = bt_pointer;
	    (*node)->esize = 4;
	    break;
	}
	tp = cond_deref(node, tp);

    }
    getsym();
    return tp;
}

struct enode   *
parmlist()
/*
 * parmlist will build a list of parameter expressions in a function call and
 * return a pointer to the last expression parsed. since parameters are
 * generally pushed from right to left we get just what we asked for...
 */
{
    struct enode   *ep1, *ep2;
    TYP            *tp;
    ep1 = 0;
    while (lastst != closepa) {
	tp = exprnc(&ep2);	/* evaluate a parameter */
        if (tp == 0)
            return 0;
#ifdef INTEL_386
            /* trap struct assigns */
            if (tp->type == bt_struct | tp->type == bt_union)
		uses_structassign=1;
#endif
	/*
	 * do the default promotions
	 */
        if (tp->type == bt_float)
	    tp = cast_op(&ep2, tp, &tp_double);
        if (short_option) {
            if (tp->type == bt_char || tp->type == bt_uchar)
		    (void) cast_op(&ep2, tp, &tp_short);
	} else {
	    if (tp->type == bt_uchar || tp->type == bt_char ||
	        tp->type == bt_short || tp->type == bt_ushort)
		    (void) cast_op(&ep2, tp, &tp_long);
	}
	ep1 = mk_node(en_void, ep2, ep1);
	if (lastst != comma)
	    break;
	getsym();
    }
    return ep1;
}

int
castbegin(st)
/*
 * return 1 if st in set of [ kw_char, kw_short, kw_long, kw_float,
 * kw_double, kw_struct, kw_union ] CVW change: or kw_void CVW change: or an
 * type identifier
 */
    enum e_sym      st;
{
    struct sym     *sp;
    if (st == kw_char || st == kw_short || st == kw_int ||
	st == kw_long || st == kw_float || st == kw_double ||
	st == kw_struct || st == kw_union || st == kw_unsigned ||
	st == kw_void || st == kw_enum)
	return 1;
    if (st == id && (sp = gsearch(lastid)) != 0 &&
	sp->storage_class == sc_typedef)
	return 1;
    return 0;
}

static TYP     *
primary(node)
/*
 * primary will parse a primary expression and set the node pointer returning
 * the type of the expression parsed. primary expressions are any of:
 * id
 * constant
 * string
 * ( expression )
 * primary[ expression ]
 * primary.id
 * primary->id
 * primary( parameter list )
 * -- or just a semicolon, yields empty expression --
 *
 */
    struct enode  **node;
{
    struct enode   *pnode, *qnode, *rnode;
    struct sym     *sp;
    TYP            *tptr;
    TYP            *tp1,*tp2;
    switch (lastst) {

      case id:
	tptr = nameref(&pnode);
        if (tptr == 0)
            break;
        /*
         * function names alone are pointers to functions.
         * If followed by '(', the reference is stripped off
         * later.
         */
        if (tptr->type == bt_func) {
	   tp1 = mk_type(bt_pointer, 4);
	   tp1->btp = tptr;
           tptr = tp1;
	}
	break;
      case iconst:
      case uconst:
      case lconst:
	pnode = mk_icon(0l);
	pnode->v.i = ival;
	if (lastst == uconst) {
	    tptr = &tp_uint;
	    pnode->etype = tp_uint.type;
	    pnode->esize = tp_uint.size;
	} else if (lastst == lconst) {
	    tptr = &tp_long;
	    pnode->etype = bt_long;
	    pnode->esize = 4;
	} else {
	    tptr = &tp_int;
	    pnode->etype = tp_int.type;
	    pnode->esize = tp_int.size;
	}
	getsym();
	break;
      case rconst:
        tptr = &tp_double;
	pnode = mk_node(en_fcon, NIL_ENODE, NIL_ENODE);
#ifndef NOFLOAT
	pnode->v.f = rval;
#endif
        pnode->etype = tp_double.type;
        pnode->esize = tp_double.size;
	getsym();
	break;
      case sconst:
	if (sizeof_flag) {
	    tptr = mk_type(bt_pointer, 0);
	    tptr->size = lstrlen + 1;
	    tptr->btp = &tp_char;
	    tptr->val_flag = 1;
	} else
	    tptr = &tp_string;
	pnode = mk_node(en_labcon, NIL_ENODE, NIL_ENODE);
	if (sizeof_flag == 0)
	    pnode->v.i = stringlit(laststr, lstrlen);
	pnode->etype = bt_pointer;
	pnode->esize = 4;
	getsym();
	break;
      case openpa:
	getsym();
	if (!castbegin(lastst)) {
	    tptr = expression(&pnode);
	    needpunc(closepa);
	} else {		/* cast operator */
	    struct typ *local_head = head, *local_tail=tail;
	    decl((TABLE *) 0);	/* do cast declaration */
	    decl1();
	    tptr = head;
	    needpunc(closepa);
	    if ((tp1 = unary(&pnode)) == 0) {
		error(ERR_IDEXPECT);
		tptr = 0;
	    }
	    /* do the cast */
	    tptr = cast_op(&pnode, tp1, tptr);
	    head = local_head;
	    tail = local_tail;
	}
	break;
      default:
	tptr=0;
        break;
    }
    if (tptr == 0)
        return 0;
    for (;;) {
	switch (lastst) {
	  case openbr:		/* build a subscript reference */
	    getsym();
/*
 * a[b] is defined as *(a+b), such exactly one of (a,b) must be a pointer
 * and one of (a,b) must be an integer expression
 */
	    if (tptr->type == bt_pointer) {
	        tp2 = expression(&rnode);
		tp1 = tptr;
	    } else {
		tp2 = tptr;
		rnode = pnode;
		tp1 = expression(&pnode);
		tptr = tp1;
	    }

/*
 * now, pnode and tp1 describe the pointer,
 *      rnode and tp2 describe the integral value
 */

	    if (tptr->type != bt_pointer)
		error (ERR_NOPOINTER);
	    else
		tptr = tptr->btp;

	    qnode = mk_icon((long) tptr->size);
	    qnode->etype = bt_long;
	    qnode->esize = 4;
/*
 * qnode is the size of the referenced object
 */
	    (void) cast_op(&rnode, tp2, &tp_long);
	    /*
	     * we could check the type of the expression here...
	     */
	    qnode = mk_node(en_mul, qnode, rnode);
	    qnode->etype = bt_long;
	    qnode->esize = 4;
	    (void) cast_op(&qnode, &tp_long, tp1);
	    pnode = mk_node(en_add, qnode, pnode);
	    pnode->etype = bt_pointer;
	    pnode->esize = 4;
	    tptr = cond_deref(&pnode, tptr);
	    needpunc(closebr);
	    break;
	  case pointsto:
	    if (tptr->type != bt_pointer)
		error(ERR_NOPOINTER);
	    else
		tptr = tptr->btp;
	    /*
	     * tptr->type should be bt_struct or bt_union tptr->val_flag
	     * should be 0 the ref node will be stripped off in a minute
	     */
	    tptr = cond_deref(&pnode, tptr);
	    /*
	     * fall through to dot operation
	     */
	  case dot:
	    getsym();		/* past -> or . */
	    if (lastst != id)
		error(ERR_IDEXPECT);
	    else {
		sp = search(lastid, tptr->lst.tail);
		if (sp == 0)
		    error(ERR_NOMEMBER);
		else {
		    /* strip off the en_ref node on top */
		    if (lvalue(pnode))
			pnode = pnode->v.p[0];
		    else {
			pnode = mk_node(en_deref, pnode, NIL_ENODE);
			pnode->etype = bt_pointer;
			pnode->esize = 4;
		    }
		    tptr = sp->tp;
		    qnode = mk_icon((long) sp->value.i);
		    qnode->etype = bt_long;
		    qnode->esize = 4;
		    pnode = mk_node(en_add, pnode, qnode);
		    pnode->etype = bt_pointer;
		    pnode->esize = 4;
		    tptr = cond_deref(&pnode, tptr);
		}
		getsym();	/* past id */
	    }
	    break;
	  case openpa:		/* function reference */
	    getsym();
	    /*
	     *  the '*' may be ommitted with pointers to functions
	     *  we have included another indirection (see above, case id:)
	     */
	    if (tptr->type == bt_pointer)
		tptr = tptr->btp;
	    if (tptr->type != bt_func)
		error(ERR_NOFUNC);
	    else
		tptr = tptr->btp;

            /*
             * This hack lets us remember that this function itself calls
             * other functions.
             * The code generator might use this information to generate
             * safer register-pop-off code.
             */
            is_leaf_function = 0;

	    pnode = mk_node(en_fcall, pnode, parmlist());
	    pnode->etype = tptr->type;
	    pnode->esize = tptr->size;
	    needpunc(closepa);
	    break;
	  default:
	    goto fini;
	}
    }
fini:*node = pnode;
    return tptr;
}

static TYP     *
unary(node)
/*
 * unary evaluates unary expressions and returns the type of the expression
 * evaluated. unary expressions are any of:
 *
 * primary
 * primary++
 * primary--
 * !unary
 * ~unary
 * ++unary
 * --unary
 * -unary
 * *unary
 * &unary
 * (typecast)unary
 * sizeof(typecast)
 * sizeof unary
 *
 */
    struct enode  **node;
{
    TYP            *tp, *tp1;
    struct enode   *ep1, *ep2;
    int             flag;
    long            i;
    flag = 0;
    switch (lastst) {
      case autodec:
	flag = 1;
	/* fall through to common increment */
      case autoinc:
	getsym();
	tp = unary(&ep1);
	if (tp == 0) {
	    error(ERR_IDEXPECT);
	    return 0;
	}
	if (lvalue(ep1)) {
	    if (tp->type == bt_pointer)
		ep2 = mk_icon((long) tp->btp->size);
	    else {
		ep2 = mk_icon(1l);
		if (!integral(tp))
		    error(ERR_INTEGER);
	    }

	    ep2->etype = bt_long;
	    ep2->esize = 4;
	    ep1 = mk_node(flag ? en_assub : en_asadd, ep1, ep2);
	    ep1->etype = tp->type;
	    ep1->esize = tp->size;
	} else
	    error(ERR_LVALUE);
	break;
      case minus:
	getsym();
	tp = unary(&ep1);
	if (tp == 0) {
	    error(ERR_IDEXPECT);
	    return 0;
	}
	ep1 = mk_node(en_uminus, ep1, NIL_ENODE);
	ep1->etype = tp->type;
	ep1->esize = tp->size;
	break;
      case not:
	getsym();
	tp = unary(&ep1);
	if (tp == 0) {
	    error(ERR_IDEXPECT);
	    return 0;
	}
	ep1 = mk_node(en_not, ep1, NIL_ENODE);
	tp = &tp_int;
	ep1->etype = tp_int.type;
	ep1->esize = tp_int.size;
	break;
      case compl:
	getsym();
	tp = unary(&ep1);
	if (tp == 0) {
	    error(ERR_IDEXPECT);
	    return 0;
	}
	ep1 = mk_node(en_compl, ep1, NIL_ENODE);
	ep1->etype = tp->type;
	ep1->esize = tp->size;
	if (!integral(tp))
	    error(ERR_INTEGER);
	break;
      case star:
	getsym();
	tp = unary(&ep1);
	if (tp == 0) {
	    error(ERR_IDEXPECT);
	    return 0;
	}
	if (tp->btp == 0)
	    error(ERR_DEREF);
	else
	    tp = tp->btp;
	tp = cond_deref(&ep1, tp);
	break;
      case and:
	getsym();
	tp = unary(&ep1);
	if (tp == 0) {
	    error(ERR_IDEXPECT);
	    return 0;
	}
	if (lvalue(ep1)) {
	    ep1 = ep1->v.p[0];
	    tp1 = mk_type(bt_pointer, 4);
	    tp1->st_flag = 0;
	    tp1->btp = tp;
	    tp = tp1;
	} else if (tp->type == bt_pointer && tp->btp->type == bt_func) {
	    do_warning();
	    fprintf(stderr,"Address operator on function ignored.\n");
	} else
	    error(ERR_LVALUE);
	break;
      case kw_sizeof:
	getsym();
	if (lastst == openpa) {
	    flag = 1;
	    getsym();
	}
	if (flag && castbegin(lastst)) {
	    /*
	     * save head and tail, since we may be called from inside decl
	     * imagine: int x[sizeof(...)];
	     */
	    tp = head;
	    tp1 = tail;
	    decl((TABLE *) 0);
	    decl1();
	    if (head != 0) {
		ep1 = mk_icon((long) head->size);
                /*
                 * Guard against the size of not-yet-declared struct/unions
                 */
                if (head->size ==  0) {
		    do_warning();
                    fprintf(stderr," value of 'sizeof' is zero\n");
                }
	    } else
		ep1 = mk_icon(1l);
	    head = tp;
	    tail = tp1;
	} else {
/*
 * This is a mess.
 * Normally, we treat array names just as pointers, but with sizeof,
 * we want to get the real array size.
 * sizeof_flag != 0 tells cond_deref not to convert array names to pointers
 */
	    sizeof_flag++;
	    tp = unary(&ep1);
	    sizeof_flag--;
	    if (tp == 0) {
		error(ERR_SYNTAX);
		ep1 = mk_icon(1l);
	    } else
		ep1 = mk_icon((long) tp->size);
	}
	if (short_option && ep1->v.i > 65535) {
	    do_warning();
	    fprintf(stderr, "'sizeof' value greater than 65535\n");
	}
	tp = &tp_uint;
	ep1->etype = tp_uint.type;
	ep1->esize = tp_uint.size;
	if (flag)
	    needpunc(closepa);
	break;
      default:
	tp = primary(&ep1);
	if (tp != 0) {
	    if (tp->type == bt_pointer)
		i = tp->btp->size;
	    else
		i = 1;
	    if (lastst == autoinc) {
		if (lvalue(ep1)) {
		    ep2 = mk_icon((long) i);
		    ep1 = mk_node(en_ainc, ep1, ep2);
		    ep1->etype = tp->type;
		    ep1->esize = tp->size;
		} else
		    error(ERR_LVALUE);
		getsym();
	    } else if (lastst == autodec) {
		if (lvalue(ep1)) {
		    ep2 = mk_icon((long) i);
		    ep1 = mk_node(en_adec, ep1, ep2);
		    ep1->etype = tp->type;
		    ep1->esize = tp->size;
		} else
		    error(ERR_LVALUE);
		getsym();
	    }
	}
	break;
    }
    *node = ep1;
    return tp;
}

TYP            *
forcefit(node1, tp1, node2, tp2)
/*
 * forcefit will coerce the nodes passed into compatable types and return the
 * type of the resulting expression.
 */
    struct enode  **node1, **node2;
    TYP            *tp1, *tp2;
{
    /* cast short and char to int */
    if (short_option) {
	if (tp1->type == bt_char || tp1->type == bt_uchar)
	    tp1 = cast_op(node1, tp1, &tp_short);
	if (tp2->type == bt_char || tp2->type == bt_uchar)
	    tp2 = cast_op(node2, tp2, &tp_short);
    } else {
	if (tp1->type == bt_char || tp1->type == bt_uchar ||
	    tp1->type == bt_short || tp1->type == bt_ushort)
	    tp1 = cast_op(node1, tp1, &tp_long);

	if (tp2->type == bt_char || tp2->type == bt_uchar ||
	    tp2->type == bt_short || tp2->type == bt_ushort)
	    tp2 = cast_op(node2, tp2, &tp_long);
    }
   
    /* cast float to double */
    if (tp1->type == bt_float)
        tp1 = cast_op(node1, tp1, &tp_double);
    if (tp2->type == bt_float)
        tp2 = cast_op(node2, tp2, &tp_double);

    if (tp1->type == bt_double && isscalar(tp2))
	tp2 = cast_op(node2, tp2, &tp_double);
    else if (tp2->type == bt_double && isscalar(tp1))
	tp1 = cast_op(node1, tp1, &tp_double);

    if (tp1->type == bt_ulong && isscalar(tp2))
	tp2 = cast_op(node2, tp2, tp1);
    else if (tp2->type == bt_ulong && isscalar(tp1))
	tp1 = cast_op(node1, tp1, tp2);

    if (tp1->type == bt_long && isscalar(tp2))
	tp2 = cast_op(node2, tp2, tp1);
    else if (tp2->type == bt_long && isscalar(tp2))
	tp1 = cast_op(node1, tp1, tp2);

    if (tp1->type == bt_ushort && isscalar(tp2))
	tp2 = cast_op(node2, tp2, tp1);
    else if (tp2->type == bt_ushort && isscalar(tp2))
	tp1 = cast_op(node1, tp1, tp2);

    if (isscalar(tp1) && isscalar(tp2))
	return (tp1);

    /* pointers may be combined with integer constant 0 */
    if (tp1->type == bt_pointer && (*node2)->nodetype == en_icon &&
	(*node2)->v.i == 0)
	return tp1;
    if (tp2->type == bt_pointer && (*node1)->nodetype == en_icon &&
	(*node2)->v.i == 0)
	return tp2;

    if (tp1->type == bt_pointer && tp2->type == bt_pointer)
	return tp1;

    /* report mismatch error */

    error(ERR_MISMATCH);
    return tp1;
}

TYP            *
forceft2(node1, tp1, node2, tp2)
    struct enode  **node1, **node2;
    TYP            *tp1, *tp2;
/*
 * ,,forcefit'' for comparisons:
 * When comparing two char's, it is not necessary to cast
 * both of them to long in advance
 *
 * Perhaps not strictly K&R, but more efficient.
 * If you don't like it, use forcefit in ALL cases
 */
{


    /* short cut: */
    if (tp1->type == tp2->type)
	return tp1;

    /* comparison with integer constant */

    if ((*node1)->nodetype == en_icon) {
	struct enode  **node = node1;
	TYP            *tp = tp1;
	node1 = node2;
	tp1 = tp2;
	node2 = node;
	tp2 = tp;
    }
    if ((*node2)->nodetype == en_icon) {
	long            val = (*node2)->v.i;
	enum e_bt       typ1 = tp1->type;
	if (
	    (typ1 == bt_char && -128 <= val && val <= 127) ||
	    (typ1 == bt_uchar && 0 <= val && val <= 255) ||
	    (typ1 == bt_short && -32768 <= val && val <= 32767) ||
	    (typ1 == bt_ushort && 0 <= val && val <= 65535) ||
	    (typ1 == bt_pointer && val == 0)
	    )
	    return cast_op(node2, tp2, tp1);
    }

    switch (tp1->type) {
	/* Type of first operand */
      case bt_char:
      case bt_uchar:
	switch (tp2->type) {
	  case bt_char:
	  case bt_uchar:
	    (void) cast_op(node1, tp1, &tp_short);
	    return cast_op(node2, tp2, &tp_short);
	  case bt_short:
	  case bt_long:
	  case bt_ushort:
	  case bt_ulong:
	  case bt_float:
	  case bt_double:
	    return cast_op(node1, tp1, tp2);
	}
	break;
      case bt_short:
      case bt_ushort:
	switch (tp2->type) {
	  case bt_char:
	  case bt_uchar:
	    return cast_op(node2, tp2, tp1);
	  case bt_ushort:
            if (short_option)
               return cast_op (node1, tp1, &tp_ushort);
            else {
               (void) cast_op (node1, tp1, &tp_long);
               return cast_op (node2, tp2, &tp_long);
            }
	  case bt_short:
	    if (short_option)
		return cast_op(node2, tp2, &tp_ushort);
	    else {
               (void) cast_op (node1, tp1, &tp_long);
               return cast_op (node2, tp2, &tp_long);
            }
	  case bt_long:
	  case bt_ulong:
	  case bt_float:
	  case bt_double:
	    return cast_op(node1, tp1, tp2);
	}
	break;
      case bt_long:
      case bt_ulong:
	switch (tp2->type) {
	  case bt_char:
	  case bt_uchar:
	  case bt_short:
	  case bt_ushort:
	    return cast_op(node2, tp2, tp1);
          case bt_long:
            return cast_op(node2, tp2, tp1);
	  case bt_ulong:
            return cast_op(node1, tp1, tp2);
	  case bt_float:
	  case bt_double:
	    return cast_op(node1, tp1, tp2);
	}
	break;
      case bt_float:
      case bt_double:
	switch (tp2->type) {
	  case bt_char:
	  case bt_uchar:
	  case bt_short:
	  case bt_ushort:
	  case bt_long:
	  case bt_ulong:
	  case bt_float:
            return cast_op(node2, tp2, tp1);
          case bt_double:
	    return cast_op(node1, tp1, tp2);
	}
	break;
	/*
	 * pointers are equivalent to function names
	 */
      case bt_pointer:
	if (tp2->type == bt_func)
	    return cast_op(node2, tp2, tp1);
	break;
      case bt_func:
	if (tp2->type == bt_pointer)
	    return cast_op(node1, tp1, tp2);
	break;
    }
    error(ERR_MISMATCH);
    return 0;
}


static int
isscalar(tp)
/*
 * this function returns true when the type of the argument is a scalar type
 * (enum included)
 */
    TYP            *tp;
{
    return tp->type == bt_char ||
	tp->type == bt_uchar ||
	tp->type == bt_ushort ||
	tp->type == bt_short ||
	tp->type == bt_long ||
	tp->type == bt_ulong ||
	tp->type == bt_float ||
	tp->type == bt_double;
}

static TYP     *
multops(node)
/*
 * multops parses the multiply priority operators. the syntax of this group
 * is:
 *
 * unary multop * unary multop / unary multop % unary
 */
    struct enode  **node;
{
    struct enode   *ep1, *ep2;
    TYP            *tp1, *tp2;
    enum e_sym      oper;
    tp1 = unary(&ep1);
    if (tp1 == 0)
	return 0;
    while (lastst == star || lastst == divide || lastst == modop) {
	oper = lastst;
	getsym();		/* move on to next unary op */
	tp2 = unary(&ep2);
	if (tp2 == 0) {
	    error(ERR_IDEXPECT);
	    *node = ep1;
	    return tp1;
	}
	tp1 = forcefit(&ep1, tp1, &ep2, tp2);
	switch (oper) {
	  case star:
	    ep1 = mk_node(en_mul, ep1, ep2);
	    break;
	  case divide:
	    ep1 = mk_node(en_div, ep1, ep2);
	    break;
	  case modop:
	    ep1 = mk_node(en_mod, ep1, ep2);
	    break;
	}
	ep1->etype = tp1->type;
	ep1->esize = tp1->size;
    }
    *node = ep1;
    return tp1;
}

static TYP     *
addops(node)
/*
 * addops handles the addition and subtraction operators.
 */
    struct enode  **node;
{
    struct enode   *ep1, *ep2, *ep3;
    TYP            *tp1, *tp2;
    int             oper;
    tp1 = multops(&ep1);
    if (tp1 == 0)
	return 0;
    while (lastst == plus || lastst == minus) {
	oper = (lastst == plus);
	getsym();
	tp2 = multops(&ep2);
	if (tp2 == 0) {
	    error(ERR_IDEXPECT);
	    *node = ep1;
	    return tp1;
	}
	if (tp1->type == bt_pointer && tp2->type == bt_pointer
	    && tp1->btp->size == tp2->btp->size && (!oper)) {
	    /* pointer subtraction */
	    ep1 = mk_node(en_sub, ep1, ep2);
	    ep1->etype = bt_pointer;
	    ep1->esize = 4;
	    (void) cast_op(&ep1, tp1, &tp_long);
	    /* divide the result by the size */
	    ep2 = mk_icon((long) tp1->btp->size);
	    ep2->etype = bt_long;
	    ep2->esize = 4;
	    ep1 = mk_node(en_div, ep1, ep2);
	    ep1->etype = bt_long;
	    ep1->esize = 4;
	    /*
	     * cast the result to ,,int''. K&R says that pointer subtraction
	     * yields an int result so I do it although it is not sensible on
	     * an 68000 with 32-bit pointers and 16-bit ints. In my opinion,
	     * it should remain ,,long''.
	     */
	    if (short_option && warning())
		fprintf(stderr, "pointer difference casted to 16-bit 'int'\n");
	    tp1 = cast_op(&ep1, &tp_long, &tp_int);
	    *node = ep1;
	    continue;
	}
	if (tp1->type == bt_pointer) {
	    /* pointer +/- integer */
	    if (!integral(tp2))
		error(ERR_INTEGER);
	    (void) cast_op(&ep2, tp2, &tp_long);
	    ep3 = mk_icon((long) tp1->btp->size);
	    ep3->etype = bt_long;
	    ep3->esize = 4;
	    ep2 = mk_node(en_mul, ep3, ep2);
	    ep2->etype = bt_pointer;
	    ep2->esize = 4;
	    ep1 = mk_node(oper ? en_add : en_sub, ep1, ep2);
	    ep1->etype = bt_pointer;
	    ep1->esize = 4;
	    continue;
	}
	if (tp2->type == bt_pointer && oper) {
	    /* integer + pointer */
	    if (!integral(tp1))
		error(ERR_INTEGER);
	    (void) cast_op(&ep1, tp1, &tp_long);
	    ep3 = mk_icon((long) tp2->btp->size);
	    ep3->etype = bt_long;
	    ep3->esize = 4;
	    ep1 = mk_node(en_mul, ep3, ep1);
	    ep1->etype = bt_pointer;
	    ep1->esize = 4;
	    ep1 = mk_node(en_add, ep1, ep2);
	    ep1->etype = bt_pointer;
	    ep1->esize = 4;
	    tp1 = tp2;
	    continue;
	}
	tp1 = forcefit(&ep1, tp1, &ep2, tp2);
	ep1 = mk_node(oper ? en_add : en_sub, ep1, ep2);
	ep1->etype = tp1->type;
	ep1->esize = tp1->size;
    }
    *node = ep1;
    return tp1;
}

TYP            *
shiftop(node)
/*
 * shiftop handles the shift operators << and >>.
 */
    struct enode  **node;
{
    struct enode   *ep1, *ep2;
    TYP            *tp1, *tp2;
    int             oper;
    tp1 = addops(&ep1);
    if (tp1 == 0)
	return 0;
    while (lastst == lshift || lastst == rshift) {
	oper = (lastst == lshift);
	getsym();
	tp2 = addops(&ep2);
	if (tp2 == 0)
	    error(ERR_IDEXPECT);
	else {
	    tp1 = forcefit(&ep1, tp1, &ep2, tp2);
	    ep1 = mk_node(oper ? en_lsh : en_rsh, ep1, ep2);
	    ep1->etype = tp1->type;
	    ep1->esize = tp1->size;
	    if (!integral(tp1))
		error(ERR_INTEGER);
	}
    }
    *node = ep1;
    return tp1;
}

TYP            *
relation(node)
/*
 * relation handles the relational operators < <= > and >=.
 */
    struct enode  **node;
{
    struct enode   *ep1, *ep2;
    TYP            *tp1, *tp2;
    enum e_node     nt;
    tp1 = shiftop(&ep1);
    if (tp1 == 0)
	return 0;
    for (;;) {
	switch (lastst) {

	  case lt:
	    nt = en_lt;
	    break;
	  case gt:
	    nt = en_gt;
	    break;
	  case leq:
	    nt = en_le;
	    break;
	  case geq:
	    nt = en_ge;
	    break;
	  default:
	    goto fini;
	}
	getsym();
	tp2 = shiftop(&ep2);
	if (tp2 == 0)
	    error(ERR_IDEXPECT);
	else {
	    tp1 = forceft2(&ep1, tp1, &ep2, tp2);
	    ep1 = mk_node(nt, ep1, ep2);
	    tp1 = &tp_int;
	    ep1->etype = tp_int.type;
	    ep1->esize = tp_int.size;
	}
    }
fini:*node = ep1;
    return tp1;
}

TYP            *
equalops(node)
/*
 * equalops handles the equality and inequality operators.
 */
    struct enode  **node;
{
    struct enode   *ep1, *ep2;
    TYP            *tp1, *tp2;
    int             oper;
    tp1 = relation(&ep1);
    if (tp1 == 0)
	return 0;
    while (lastst == eq || lastst == neq) {
	oper = (lastst == eq);
	getsym();
	tp2 = relation(&ep2);
	if (tp2 == 0)
	    error(ERR_IDEXPECT);
	else {
	    tp1 = forceft2(&ep1, tp1, &ep2, tp2);
	    ep1 = mk_node(oper ? en_eq : en_ne, ep1, ep2);
	    tp1 = &tp_int;
	    ep1->etype = tp_int.type;
	    ep1->esize = tp_int.size;
	}
    }
    *node = ep1;
    return tp1;
}

TYP            *
binop(node, xfunc, nt, sy)
/*
 * binop is a common routine to handle all of the legwork and error checking
 * for bitand, bitor, bitxor
 */
    struct enode  **node;
    TYP            *(*xfunc) ();
enum e_node     nt;
enum e_sym      sy;
{
    struct enode   *ep1, *ep2;
    TYP            *tp1, *tp2;
    tp1 = (*xfunc) (&ep1);
    if (tp1 == 0)
	return 0;
    while (lastst == sy) {
	getsym();
	tp2 = (*xfunc) (&ep2);
	if (tp2 == 0)
	    error(ERR_IDEXPECT);
	else {
	    tp1 = forceft2(&ep1, tp1, &ep2, tp2);
	    ep1 = mk_node(nt, ep1, ep2);
	    ep1->etype = tp1->type;
	    ep1->esize = tp1->size;
	    if (!integral(tp1))
		error(ERR_INTEGER);
	}
    }
    *node = ep1;
    return tp1;
}

TYP            *
binlog(node, xfunc, nt, sy)
/*
 * binlog is a common routine to handle all of the legwork and error checking
 * for logical and, or
 */
    struct enode  **node;
    TYP            *(*xfunc) ();
enum e_node     nt;
enum e_sym      sy;
{
    struct enode   *ep1, *ep2;
    TYP            *tp1, *tp2;
    tp1 = (*xfunc) (&ep1);
    if (tp1 == 0)
	return 0;
    while (lastst == sy) {
	getsym();
	tp2 = (*xfunc) (&ep2);
	if (tp2 == 0)
	    error(ERR_IDEXPECT);
	else {
	    ep1 = mk_node(nt, ep1, ep2);
	    tp1 = &tp_int;
	    ep1->etype = tp_int.type;
	    ep1->esize = tp_int.size;
	}
    }
    *node = ep1;
    return tp1;
}
TYP            *
bitand(node)
/*
 * the bitwise and operator...
 */
    struct enode  **node;
{
    return binop(node, equalops, en_and, and);
}

TYP            *
bitxor(node)
    struct enode  **node;
{
    return binop(node, bitand, en_xor, uparrow);
}

TYP            *
bitor(node)
    struct enode  **node;
{
    return binop(node, bitxor, en_or, or);
}

TYP            *
andop(node)
    struct enode  **node;
{
    return binlog(node, bitor, en_land, land);
}

TYP            *
orop(node)
    struct enode  **node;
{
    return binlog(node, andop, en_lor, lor);
}

TYP            *
conditional(node)
/*
 * this routine processes the hook operator.
 */
    struct enode  **node;
{
    TYP            *tp1, *tp2, *tp3;
    struct enode   *ep1, *ep2, *ep3;
    tp1 = orop(&ep1);		/* get condition */
    if (tp1 == 0)
	return 0;
    if (lastst == hook) {
	getsym();
	if ((tp2 = expression(&ep2)) == 0) {
	    error(ERR_IDEXPECT);
	    return 0;
	}
	needpunc(colon);
	if ((tp3 = exprnc(&ep3)) == 0) {
	    error(ERR_IDEXPECT);
	    return 0;
	}
/*
 * If either type is void and the other is not, cast the other one to void.
 * I dare not doing this in forceft2
 * Strict ANSI does not allow that only one part of the sentence is void,
 * that is what gcc -pedantic tells me.
 * But since such conditionals occur even in GNU Software (look at obstack.h),
 * I allow such constructs here.
 */
        if (tp2->type == bt_void && tp3->type != bt_void)
            tp3 = cast_op(&ep3, tp3, tp2);
        else if (tp3->type == bt_void && tp2->type != bt_void)
            tp2 = cast_op(&ep2, tp2, tp3);

	tp1 = forceft2(&ep2, tp2, &ep3, tp3);
        if (tp1 == 0)
            return 0;
	ep2 = mk_node(en_void, ep2, ep3);
	ep1 = mk_node(en_cond, ep1, ep2);
	ep1->etype = tp1->type;
	ep1->esize = tp1->size;
    }
    *node = ep1;
    return tp1;
}

TYP            *
asnop(node)
/*
 * asnop handles the assignment operators.
 */
    struct enode  **node;
{
    struct enode   *ep1, *ep2, *ep3;
    TYP            *tp1, *tp2;
    enum e_node     op;
    tp1 = conditional(&ep1);
    if (tp1 == 0)
	return 0;
    for (;;) {
	switch (lastst) {
	  case assign:
	    op = en_assign;
    ascomm:getsym();
	    tp2 = asnop(&ep2);
    ascomm2:
	    if (tp2 == 0)
                break;
	    if (ep1->nodetype != en_ref && ep1->nodetype != en_fieldref)
		error(ERR_LVALUE);
	    tp1 = cast_op(&ep2, tp2, tp1);
            if (tp1 == 0)
                break;
	    ep1 = mk_node(op, ep1, ep2);
	    ep1->etype = tp1->type;
	    ep1->esize = tp1->size;
#ifdef INTEL_386
            /* trap struct assigns */
            if (tp1->type == bt_struct | tp1->type == bt_union)
		uses_structassign=1;
#endif
	    break;
	  case asplus:
	    op = en_asadd;
    ascomm3:
	    getsym();
	    tp2 = asnop(&ep2);
            if (tp2 == 0)
                break;
	    if (tp1->type == bt_pointer && integral(tp2)) {
		(void) cast_op(&ep2, tp2, &tp_long);
		ep3 = mk_icon((long) tp1->btp->size);
		ep3->etype = bt_long;
		ep3->esize = 4;
		ep2 = mk_node(en_mul, ep2, ep3);
		ep2->etype = bt_long;
		ep2->esize = 4;
		tp2 = cast_op(&ep2, &tp_long, tp1);
	    }
	    goto ascomm2;
	  case asminus:
	    op = en_assub;
	    goto ascomm3;
	  case astimes:
	    op = en_asmul;
	    goto ascomm;
	  case asdivide:
	    op = en_asdiv;
	    goto ascomm;
	  case asmodop:
	    op = en_asmod;
	    goto ascomm;
	  case aslshift:
	    op = en_aslsh;
	    goto ascomm;
	  case asrshift:
	    op = en_asrsh;
	    goto ascomm;
	  case asand:
	    op = en_asand;
	    goto ascomm;
	  case asor:
	    op = en_asor;
	    goto ascomm;
	  case asuparrow:
	    op = en_asxor;
	    goto ascomm;
	  default:
	    goto asexit;
	}
    }
asexit:
   *node = ep1;
    return tp1;
}

TYP            *
exprnc(node)
/*
 * evaluate an expression where the comma operator is not legal.
 */
    struct enode  **node;
{
    TYP            *tp;
    tp = asnop(node);
    if (tp == 0)
	*node = 0;
    return tp;
}

TYP            *
commaop(node)
/*
 * evaluate the comma operator. comma operators are kept as void nodes.
 */
    struct enode  **node;
{
    TYP            *tp1;
    struct enode   *ep1, *ep2;
    tp1 = asnop(&ep1);
    if (tp1 == 0)
	return 0;
    if (lastst == comma) {
	getsym();
	tp1 = commaop(&ep2);
	if (tp1 == 0) {
	    error(ERR_IDEXPECT);
	    goto coexit;
	}
	ep1 = mk_node(en_void, ep1, ep2);
	ep1->esize = ep2->esize;
	ep1->etype = ep2->etype;
    }
coexit:*node = ep1;
    return tp1;
}

TYP            *
expression(node)
/*
 * evaluate an expression where all operators are legal.
 */
    struct enode  **node;
{
    TYP            *tp;
    tp = commaop(node);
    if (tp == 0)
	*node = 0;
    return tp;
}

TYP            *
cast_op(ep, tp1, tp2)
    struct enode  **ep;
    TYP            *tp1, *tp2;

{
    struct enode   *ep2;

    if (tp1 == 0 || tp2 == 0) {
	error(ERR_CAST);
	return 0;
    }
    if (tp1->type == tp2->type) {
	if (!eq_type(tp1, tp2) && warning())
	    fprintf(stderr, "conversion between incompatible %s types\n",
		    (tp1->type == bt_pointer) ? "pointer" : "");
	if (tp1->type == bt_struct || tp1->type == bt_union) {
	    if (tp1->size != tp2->size)
		error(ERR_CAST);
	}
	return tp2;
    }
    opt0(ep);			/* to make a constant really a constant */

    if ((*ep)->nodetype == en_icon)
	if (integral(tp2) || tp2->type == bt_pointer || tp2->type == bt_void) {
	    long            j = (*ep)->v.i;
	    (*ep)->etype = tp2->type;
	    (*ep)->esize = tp2->size;
	    /*
	     * The cast may affect the value of (*ep)->v.i
	     */
	    (*ep)->v.i = strip_icon(j, tp2->type);
	    if (j != (*ep)->v.i && warning()) {
		fprintf(stderr, "A cast changed an integer constant.\n");
		fprintf(stderr, "From: %08lx To: %08lx\n", j, (*ep)->v.i);
	    }
	    return tp2;
	} else if (tp2->type == bt_float || tp2->type == bt_double) {
	    (*ep)->nodetype = en_fcon;
	    (*ep)->etype = tp2->type;
#ifndef NOFLOAT
	    (*ep)->v.f = (double) (*ep)->v.i;
#endif
	    (*ep)->esize =
            tp2->type == bt_float ? tp_float.size : tp_double.size;
	    return tp2;
	} else {
	    error(ERR_CASTCON);
	    return 0;
	}
    if (tp2->type != bt_void && tp1->size > tp2->size && warning())
	fprintf(stderr, "A cast to a narrower type looses accuracy.\n");
    if (tp2->type == bt_pointer && tp1->size < 4 && warning())
	fprintf(stderr, "A cast from short to pointer is dangerous.\n");


    ep2 = mk_node(en_cast, *ep, NIL_ENODE);
    ep2->etype = tp2->type;
    ep2->esize = tp2->size;

    *ep = ep2;

    return tp2;
}

int
integral(tp)
    TYP            *tp;
/* returns true it tp is an integral type */
{
    return tp->type == bt_char || tp->type == bt_uchar ||
	tp->type == bt_short || tp->type == bt_ushort ||
	tp->type == bt_long || tp->type == bt_ulong;
}

long
strip_icon(i, type)
    long            i;
    enum e_bt       type;
/*
 * This function handles the adjustment of integer constants upon
 * casts. It forces the constant into the range acceptable for
 * the given type.
 * This code assumes somehow that longs are 32 bit on t
 * machine that runs the compiler, but how do you get this
 * machine independent?
 */
{
    switch (type) {
      case bt_uchar:		/* 0 .. 255 */
	i &= 0xff;
	break;
      case bt_char:		/* -128 .. 127 */
	i &= 0xff;
	if (i >= 128)
	    i |= 0xffffff00;
	break;
      case bt_ushort:		/* 0 .. 65535 */
	i &= 0xffff;
	break;
      case bt_short:		/* -32768 .. 32767 */
	i &= 0xffff;
	if (i >= 32768)
	    i |= 0xffff0000;
	break;
    }
    return i;
}
