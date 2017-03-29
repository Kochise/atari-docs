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

/*
 * the statement module handles all of the possible c statements and builds a
 * parse tree of the statements.
 *
 * each routine returns a pointer to a statement parse node which reflects the
 * statement just parsed.
 */


struct snode   *
whilestmt()
/*
 * whilestmt parses the c while statement.
 */
{
    struct snode   *snp;
    snp = (struct snode *) xalloc((int) sizeof(struct snode));
    snp->stype = st_while;
    getsym();
    if (lastst != openpa)
	error(ERR_EXPREXPECT);
    else {
	getsym();
	if (expression(&(snp->exp)) == 0)
	    error(ERR_EXPREXPECT);
	needpunc(closepa);
	snp->s1 = statement();
    }
    return snp;
}

struct snode   *
dostmt()
/*
 * dostmt parses the c do-while construct.
 */
{
    struct snode   *snp;
    snp = (struct snode *) xalloc((int) sizeof(struct snode));
    snp->stype = st_do;
    getsym();
    snp->s1 = statement();
    if (lastst != kw_while)
	error(ERR_WHILEXPECT);
    else {
	getsym();
	if (lastst != openpa)
	    error(ERR_EXPREXPECT);
	else {
	    getsym();
	    if (expression(&(snp->exp)) == 0)
		error(ERR_EXPREXPECT);
	    needpunc(closepa);
	}
	if (lastst != end)
	    needpunc(semicolon);
    }
    return snp;
}

struct snode   *
forstmt()
{
    struct snode   *snp;
    snp = (struct snode *) xalloc((int) sizeof(struct snode));
    getsym();
    needpunc(openpa);
    if (expression(&(snp->exp)) == 0)
	snp->exp = 0;
    needpunc(semicolon);
    snp->stype = st_for;
    if (expression(&(snp->v1.e)) == 0)
	snp->v1.e = 0;
    needpunc(semicolon);
    if (expression(&(snp->v2.e)) == 0)
	snp->v2.e = 0;
    needpunc(closepa);
    snp->s1 = statement();
    return snp;
}

struct snode   *
ifstmt()
/*
 * ifstmt parses the c if statement and an else clause if one is present.
 */
{
    struct snode   *snp;
    snp = (struct snode *) xalloc((int) sizeof(struct snode));
    snp->stype = st_if;
    getsym();
    if (lastst != openpa)
	error(ERR_EXPREXPECT);
    else {
	getsym();
	if (expression(&(snp->exp)) == 0)
	    error(ERR_EXPREXPECT);
	needpunc(closepa);
	snp->s1 = statement();
	if (lastst == kw_else) {
	    getsym();
	    snp->v1.s = statement();
	} else
	    snp->v1.s = 0;
    }
    return snp;
}

/*
 * consider the following piece of code:
 *
 *	switch (i) {
 *		case 1:
 *			if (j) {
 *				.....
 *			} else
 *		case 2:
 *			....
 *	}
 *
 * case statements may be deep inside, so we need a global variable
 * last_case to link them
 */
static struct snode *last_case;	/* last case statement within this switch */

struct snode   *
casestmt()
/*
 * cases are returned as seperate statements. for normal cases label is the
 * case value and v1.i is zero. for the default case v1.i is nonzero.
 */
{
    struct snode   *snp;
    snp = (struct snode *) xalloc((int) sizeof(struct snode));
    snp->s1 = NIL_SNODE;
    if (lastst == kw_case) {
	getsym();
	snp->stype = st_case;
	snp->v2.i = intexpr();
    } else {
	/* lastst is kw_default */
	getsym();
	/* CVW: statement type needed for analyze etc. */
	snp->stype = st_default;
    }
    last_case = last_case->s1 = snp;
    needpunc(colon);
    if (lastst != end)
	snp->v1.s = statement();
    return snp;
}

int
checkcases(head)
/*
 * checkcases will check to see if any duplicate cases exist in the case list
 * pointed to by head.
 */
    struct snode   *head;
{
    struct snode   *top, *cur;
    cur = top = head;
    while (top != 0) {
	cur = top->s1;
	while (cur != 0) {
	    if (cur->stype != st_default && top->stype != st_default
		&& cur->v2.i == top->v2.i) {
		fprintf(stderr, " duplicate case label %ld\n", cur->v2.i);
		return 1;
	    }
	    if (cur->stype == st_default && top->stype == st_default) {
		fprintf(stderr, " duplicate default label\n");
		return 1;
	    }
	    cur = cur->s1;
	}
	top = top->s1;
    }
    return 0;
}

struct snode   *
switchstmt()
{
    struct snode   *snp;
    struct snode   *local_last_case;
    local_last_case = last_case;
    snp = (struct snode *) xalloc((int) sizeof(struct snode));
    last_case = snp;
    snp->s1 = 0;
    snp->stype = st_switch;
    getsym();
    needpunc(openpa);
    if ((expression(&(snp->exp))) == 0)
	error(ERR_EXPREXPECT);
    needpunc(closepa);
    needpunc(begin);
    snp->v1.s = compound(1);
    if (checkcases(snp->s1))
	error(ERR_DUPCASE);
    last_case = local_last_case;
    return snp;
}

struct snode   *
retstmt()
{
    struct snode   *snp;
    TYP            *tp;
    snp = (struct snode *) xalloc((int) sizeof(struct snode));
    snp->stype = st_return;
    getsym();
    tp = expression(&(snp->exp));
    if (snp->exp != 0)
	(void) cast_op(&(snp->exp), tp, ret_type);
    if (lastst != end)
	needpunc(semicolon);
    return snp;
}

struct snode   *
breakstmt()
{
    struct snode   *snp;
    snp = (struct snode *) xalloc((int) sizeof(struct snode));
    snp->stype = st_break;
    getsym();
    if (lastst != end)
	needpunc(semicolon);
    return snp;
}

struct snode   *
contstmt()
{
    struct snode   *snp;
    snp = (struct snode *) xalloc((int) sizeof(struct snode));
    snp->stype = st_continue;
    getsym();
    if (lastst != end)
	needpunc(semicolon);
    return snp;
}

struct snode   *
exprstmt()
/*
 * exprstmt is called whenever a statement does not begin with a keyword. the
 * statement should be an expression.
 */
{
    struct snode   *snp;
    snp = (struct snode *) xalloc((int) sizeof(struct snode));
    snp->stype = st_expr;
/*
 * I have a problem here.
 * If expression() fails on the first character and does not do a getsym(),
 * there may be an infinite loop since we will continue coming up here.
 * Since the compiler will stop after MAX_ERROR_COUNT calls to error(),
 * this might not be THAT problem.
 */
    if (expression(&(snp->exp)) == 0)
	error(ERR_EXPREXPECT);
    if (lastst != end)
	needpunc(semicolon);
    return snp;
}


auto_init(sp)
    struct sym     *sp;
/*
 * generated assignment statements for initialization of auto and register
 * variables. The initialization is generated like comma operators so a
 * single statement does all the initializations
 */
{
    struct enode   *ep1, *ep2;
    struct typ     *tp;
    int             brace_level = 0;
    getsym();
    while (lastst == begin) {
	brace_level++;
	getsym();
    }
    tp = exprnc(&ep2);
    if (tp == 0 || sp->tp->type == bt_struct || sp->tp->type == bt_union ||
	sp->tp->val_flag) {
	error(ERR_ILLINIT);
    } else {
	(void) cast_op(&ep2, tp, sp->tp);

	ep1 = mk_node(en_autocon, NIL_ENODE, NIL_ENODE);
	ep1->v.i = sp->value.i;
	ep1->etype = sp->tp->type;
	ep1->esize = sp->tp->size;

	ep1 = mk_node(en_ref, ep1, NIL_ENODE);
	ep1->etype = sp->tp->type;
	ep1->esize = sp->tp->size;

	ep1 = mk_node(en_assign, ep1, ep2);
	ep1->etype = sp->tp->type;
	ep1->esize = sp->tp->size;

	if (init_node == 0) {
	    init_node = ep1;
	} else {
	    init_node = mk_node(en_void, init_node, ep1);
	}
    }
    while (brace_level--)
	needpunc(end);
}

struct snode   *
compound(no_init)
/*
 * compound processes a block of statements and forms a linked list of the
 * statements within the block.
 *
 * compound expects the input pointer to already be past the begin symbol of the
 * block.
 *
 * If no_init is true, auto initializations are not desirable
 */
    int             no_init;
{
    struct snode   *head, *tail, *snp;
    struct sym     *local_tail, *local_tagtail;
    TABLE           symtab;
    local_tail = lsyms.tail;
    local_tagtail = ltags.tail;
    dodecl(sc_auto);
    if (init_node == 0) {
	head = 0;
    } else {
	if (no_init) {
	    do_warning();
	    fprintf(stderr, "auto initialization not reached\n");
	}
	head = tail = (struct snode *) xalloc((int) sizeof(struct snode));
	head->stype = st_expr;
	head->exp = init_node;
	head->next = 0;
    }
    init_node = 0;
    while (lastst != end) {
	if (head == 0)
	    head = tail = statement();
	else {
	    tail->next = statement();
	    if (tail->next != 0)
		tail = tail->next;
	}
    }
    getsym();
    if (list_option) {
	if (local_tail != lsyms.tail) {
	    if (local_tail != 0)
		symtab.head = local_tail->next;
	    else
		symtab.head = lsyms.head;
	    symtab.tail = lsyms.tail;
	    fprintf(list, "\n*** local symbol table ***\n\n");
	    list_table(&symtab, 0);
	    fprintf(list, "\n");
	}
	if (local_tagtail != ltags.tail) {
	    if (local_tagtail != 0)
		symtab.head = local_tagtail->next;
	    else
		symtab.head = ltags.head;
	    symtab.tail = ltags.tail;
	    fprintf(list, "\n*** local structures and unions ***\n\n");
	    list_table(&symtab, 0);
	    fprintf(list, "\n");
	}
    }
    if (local_tagtail != 0) {
	ltags.tail = local_tagtail;
	ltags.tail->next = 0;
    } else {
	ltags.head = 0;
	ltags.tail = 0;
    }


    if (local_tail != 0) {
	lsyms.tail = local_tail;
	lsyms.tail->next = 0;
    } else {
	lsyms.tail = 0;
	lsyms.head = 0;
    }

    snp = (struct snode *) xalloc((int) sizeof(struct snode));
    snp->stype = st_compound;
    snp->s1 = head;
    return snp;
}

struct snode   *
labelstmt()
/*
 * labelstmt processes a label that appears before a statement as a seperate
 * statement.
 */
{
    struct snode   *snp;
    struct sym     *sp;
    snp = (struct snode *) xalloc((int) sizeof(struct snode));
    snp->stype = st_label;
    if ((sp = search(lastid, labsyms.tail)) == 0) {
	sp = (struct sym *) xalloc((int) sizeof(struct sym));
	sp->name = strsave(lastid);
	sp->storage_class = sc_label;
	sp->tp = 0;
	sp->value.i = nextlabel++;
	append(&sp, &labsyms);
    } else {
	if (sp->storage_class != sc_ulabel)
	    error(ERR_LABEL);
	else
	    sp->storage_class = sc_label;
    }
    getsym();			/* get past id */
    needpunc(colon);
    if (sp->storage_class == sc_label) {
	snp->v2.i = sp->value.i;
	if (lastst != end)
	    snp->s1 = statement();
	return snp;
    }
    return 0;
}

struct snode   *
gotostmt()
/*
 * gotostmt processes the goto statement and puts undefined labels into the
 * symbol table.
 */
{
    struct snode   *snp;
    struct sym     *sp;
    getsym();
    if (lastst != id) {
	error(ERR_IDEXPECT);
	return 0;
    }
    snp = (struct snode *) xalloc((int) sizeof(struct snode));
    if ((sp = search(lastid, labsyms.tail)) == 0) {
	sp = (struct sym *) xalloc((int) sizeof(struct sym));
	sp->name = strsave(lastid);
	sp->value.i = nextlabel++;
	sp->storage_class = sc_ulabel;
	sp->tp = 0;
	append(&sp, &labsyms);
    }
    getsym();			/* get past label name */
    if (lastst != end)
	needpunc(semicolon);
    if (sp->storage_class != sc_label && sp->storage_class != sc_ulabel)
	error(ERR_LABEL);
    else {
	snp->stype = st_goto;
	snp->v2.i = sp->value.i;
	snp->next = 0;
	return snp;
    }
    return 0;
}

struct snode   *
statement()
/*
 * statement figures out which of the statement processors should be called
 * and transfers control to the proper routine.
 */
{
    struct snode   *snp;
    switch (lastst) {
      case semicolon:
	getsym();
	snp = 0;
	break;
      case begin:
	getsym();
	snp = compound(0);
	break;
      case kw_if:
	snp = ifstmt();
	break;
      case kw_while:
	snp = whilestmt();
	break;
      case kw_for:
	snp = forstmt();
	break;
      case kw_return:
	snp = retstmt();
	break;
      case kw_break:
	snp = breakstmt();
	break;
      case kw_goto:
	snp = gotostmt();
	break;
      case kw_continue:
	snp = contstmt();
	break;
      case kw_do:
	snp = dostmt();
	break;
      case kw_switch:
	snp = switchstmt();
	break;
      case kw_case:
      case kw_default:
	snp = casestmt();
	break;
      case id:
	while (isspace(lastch))
	    getch();
	if (lastch == ':') {
	    snp = labelstmt();
	    break;
	}
	/* else fall through to process expression */
      default:
	snp = exprstmt();
	break;
    }
    if (snp != 0)
	snp->next = 0;
    return snp;
}
