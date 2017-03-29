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

static TYP     *save_type();
static          declenum();
static          enumbody();
static          declstruct();
static          structbody();
static          decl2();
static          declbegin();

static char    *declid;

/* variables for function parameter lists */
static int      nparms;
static char    *names[MAX_PARAMS];

/* variable for bit fields */
static int      bit_offset;	/* the actual offset */
static int      bit_width;	/* the actual width */
static int      bit_next;	/* offset for next variable */
static int      decl1_level = 0;

static long
imax(i, j)
    long            i, j;
{
    return (i > j) ? i : j;
}

char           *
strsave(s)
    char           *s;
{
    char           *p, *q;
    q = p = (char *) xalloc(strlen(s) + 1);
    while (*p++ = *s++);
    return q;
}

TYP            *
mk_type(bt, siz)
    enum e_bt       bt;
    int             siz;
{
    TYP            *tp;
    tp = (TYP *) xalloc((int) sizeof(TYP));
    tp->val_flag = 0;
    tp->size = siz;
    tp->type = bt;
    tp->sname = 0;
    tp->lst.head = 0;
    tp->st_flag = 0;
    if (global_flag)
	tp->st_flag = 1;
    return tp;
}

int
decl(table)
    TABLE          *table;
{
    struct sym     *sp;

    /*
     * at top level, 'int' is changed to 'short' or 'long'
     */

    switch (lastst) {
      case kw_void:
	head = tail = &tp_void;
	getsym();
	break;
      case kw_char:
	head = tail = &tp_char;
	getsym();
	break;
      case kw_short:
        getsym();
        if (lastst == kw_unsigned) {
            getsym();
            head = tail = &tp_ushort;
        } else
            head = tail = &tp_short;
	if (lastst == kw_int)
	    getsym();
	break;
      case kw_int:
	head = tail = &tp_int;
	getsym();
	break;
      case kw_long:
	getsym();
        if (lastst == kw_unsigned) {
            getsym();
            head = tail = &tp_ulong;
        } else
            head = tail = &tp_long;
	if (lastst == kw_int)
	    getsym();
	break;
      case kw_unsigned:
	getsym();
	switch (lastst) {
	  case kw_long:
	    getsym();
	    head = tail = &tp_ulong;
	    if (lastst == kw_int)
		getsym();
	    break;
	  case kw_char:
	    getsym();
	    head = tail = &tp_uchar;
	    break;
	  case kw_short:
	    getsym();
	    head = tail = &tp_ushort;
	    if (lastst == kw_int)
		getsym();
	    break;
	  case kw_int:
	    getsym();
	  default:
	    head = tail = &tp_uint;
	    break;
	}
	break;
      case id:
	if ((sp = gsearch(lastid)) != 0 &&
	    sp->storage_class == sc_typedef)
	    /* type identifier */
	{
	    getsym();
	    head = tail = sp->tp;
	    break;
	}
	/* else fall through */
      case openpa:
      case star:
	/* default type is int */
	head = tail = &tp_int;
	break;
      case kw_float:
	head = tail = &tp_float;
	getsym();
	break;
      case kw_double:
        head = tail = &tp_double;
	getsym();
	break;
      case kw_enum:
	getsym();
	declenum(table);
	break;
      case kw_struct:
	getsym();
	declstruct(bt_struct);
	break;
      case kw_union:
	getsym();
	declstruct(bt_union);
	break;
    }
}

decl1()
{
    TYP            *temp1, *temp2, *temp3, *temp4;
    decl1_level++;
    switch (lastst) {
      case id:
	declid = strsave(lastid);
	getsym();
	if (lastst != colon) {
	    decl2();
	    break;
	}
	/* FALLTHROUGH */
      case colon:
	getsym();
	if (decl1_level != 1)
	    error(ERR_FIELD);
	if (head->type != tp_int.type && head->type != tp_uint.type)
#if 0
	    error(ERR_FTYPE);
#else
	    {
	    do_warning();
	    fprintf(stderr,"field type should be unsigned or int\n");
	    }
#endif
	bit_width = intexpr();
	bit_offset = bit_next;
	if (bit_width < 0 || bit_width > int_bits) {
	    error(ERR_WIDTH);
	    bit_width = 1;
	}
	if (bit_width == 0 || bit_offset + bit_width > int_bits)
	    bit_offset = 0;
	bit_next = bit_offset + bit_width;
	break;
      case star:
	temp1 = mk_type(bt_pointer, 4);
	temp1->btp = head;
	head = temp1;
	if (tail == NULL)
	    tail = head;
	getsym();
	decl1();
	break;
      case openpa:
	getsym();
	temp1 = head;
	temp2 = tail;
	head = tail = NULL;
	decl1();
	needpunc(closepa);
	temp3 = head;
	temp4 = tail;
	head = temp1;
	tail = temp2;
	decl2();
	if (temp4 != NULL) {
	    temp4->btp = head;
	    if (temp4->type == bt_pointer &&
		temp4->val_flag != 0 && head != NULL)
		temp4->size *= head->size;
	    head = temp3;
	}
	break;
      default:
	decl2();
	break;
    }
    decl1_level--;
    /*
     * Any non-bitfield type resets the next offset
     */
    if (bit_width == -1)
	bit_next = 0;
}

static
decl2()
{
    TYP            *temp1;
    long            i;
    switch (lastst) {
      case openbr:
	getsym();
	if (lastst == closebr)
	    i = 0;
	else
	    i = intexpr();
	needpunc(closebr);
	if (lastst == openbr)
	    decl2();
	temp1 = mk_type(bt_pointer, 0);
	temp1->val_flag = 1;
	temp1->btp = head;
	if (head != 0)
	    temp1->size = i * head->size;
	else
	    temp1->size = i;
	head = temp1;
	if (tail == NULL)
	    tail = head;
	decl2();
	break;
      case openpa:
	getsym();
	temp1 = mk_type(bt_func, 4);
	temp1->val_flag = 1;
	temp1->btp = head;
	head = temp1;
	if (tail == NULL)
	    tail = head;
	if (lastst == kw_void) {
	    getsym();
	    if (lastst != closepa)
		error(ERR_PARMS);
	}
	if (lastst == closepa)
	    getsym();
	else {
	    if (nparms != 0)
		error(ERR_PARMS);
	    while (lastst == id) {
                if (nparms >= MAX_PARAMS)
		    fatal("MAX_PARAMS");
		names[nparms++] = strsave(lastid);
		getsym();
		if (lastst == comma)
		    getsym();
	    }
	    needpunc(closepa);
	}
	break;
    }
}

static int
alignment(tp)
    TYP            *tp;
{
    switch (tp->type) {
      case bt_uchar:
      case bt_char:
	return AL_CHAR;
      case bt_ushort:
      case bt_short:
	return AL_SHORT;
      case bt_ulong:
      case bt_long:
	return AL_LONG;
      case bt_pointer:
	if (tp->val_flag)
	    return alignment(tp->btp);
	else
	    return AL_POINTER;
      case bt_func:
	return AL_FUNC;
      case bt_float:
	return AL_FLOAT;
      case bt_double:
	return AL_DOUBLE;
      case bt_struct:
      case bt_union:
	return AL_STRUCT;
      case bt_void:
        return 1;
      default:
	fatal("alignment: illegal type");
    }
}

static long
declare(table, al, ilc, ztype, regflag)
/*
 * process declarations of the form:
 *
 * <type>	<decl>, <decl>...;
 *
 * leaves the declarations in the symbol table pointed to by table and returns
 * the number of bytes declared. al is the allocation type to assign, ilc is
 * the initial location counter. if al is sc_member then no initialization
 * will be processed. ztype should be bt_struct for normal and in structure
 * declarations and sc_union for in union declarations.
 *
 * regflag values:
 *     -2:	union  component
 *     -1:	struct component
 *	0:	static, global, extern
 *	1:	auto
 *	2:	register auto
 *	3:	argument
 *	4:	register argument
 */
    TABLE          *table;
    enum e_sc       al;
    long            ilc;
    enum e_bt       ztype;
    int             regflag;
{
    struct sym     *sp, *sp1;
    TYP            *dhead;
    long            nbytes;
    int             func_flag;
    int             no_append;
    static long     old_nbytes;
    nbytes = 0;
    decl(table);
    dhead = head;
    for (;;) {
	declid = 0;
	bit_width = -1;
	decl1();
	if (declid != 0) {	/* otherwise just struct tag... */
            if (head->size == 0 && head->type == bt_pointer
                                && al == sc_typedef) {
	        do_warning();
	        fprintf(stderr,
	          "zero-sized typedef may be changed by initializations\n");
	    }
	    func_flag = 0;
	    if (head->type == bt_func && (lastst == begin || nparms > 0))
		func_flag = 1;
	    sp = (struct sym *) xalloc((int) sizeof(struct sym));
	    sp->name = declid;
	    sp->storage_class = al;

	    if (bit_width > 0 && bit_offset > 0) {
		/*
		 * share the storage word with the previously defined field
		 */
		nbytes = old_nbytes - ilc;
	    }
            old_nbytes = ilc + nbytes;
	    while ((ilc + nbytes) % alignment(head))
		nbytes++;
	    if (al == sc_static)
		sp->value.i = nextlabel++;
	    else if (ztype == bt_union)
		sp->value.i = ilc;
	    else if (al != sc_auto)
		sp->value.i = ilc + nbytes;
	    else
		sp->value.i = -(ilc + nbytes + head->size);

/*
 * The following code determines possible candidates for
 * register variables.
 */
	    switch (head->type) {
	      case bt_pointer:
		if (head->val_flag && regflag < 3)
		    break;
		/* FALLTHROUGH */
	      case bt_char:
	      case bt_uchar:
	      case bt_short:
	      case bt_ushort:
	      case bt_long:
	      case bt_ulong:
              case bt_float:
              case bt_double:
		switch (regflag) {
		  case 1:
		  case 3:
		    if (autoptr < AUTO_LIST)
			autolst[autoptr++] = sp->value.i;
		    break;
		  case 2:
		  case 4:
		    if (regptr < REG_LIST)
			reglst[regptr++] = sp->value.i;
		    break;
		}
	    }

	    if (bit_width == -1) {
		sp->tp = head;
	    } else {
		sp->tp = (struct typ *) xalloc((int) sizeof(struct typ));
		*(sp->tp) = *head;
		sp->tp->type = bt_bitfield;
		sp->tp->size = tp_int.size;
		sp->tp->bit_width = bit_width;
		sp->tp->bit_offset = bit_offset;
	    }
/*
 * The following stuff deals with inconsistencies in the
 * C syntax and semantics, namely the scope of locally
 * declared functions and its default storage class (extern,
 * not auto) etc.
 */
	    no_append = 0;
/*
 * The flag no_append will be set if some stuff is forwarded to the
 * global symbol table here and thus should not be repeated in the local
 * symbol table
 */
/*
 * extern function definitions with function body are global
 */
	    if (func_flag && sp->storage_class == sc_external)
		sp->storage_class = sc_global;
/*
 * global function declarations without function body are external
 */
	    if (sp->tp->type == bt_func && sp->storage_class == sc_global
		&& !func_flag) {
		sp->storage_class = sc_external;
	    }
/*
 * [auto] int test() is not an auto declaration, it should be
 * external
 */
	    if (sp->tp->type == bt_func && sp->storage_class == sc_auto) {
		/*
		 * althouh the following if-statement is not necessary since
		 * it this check is performed in append() anyway, it saves
		 * global storage if the functions has previously been
		 * defined.
		 */
		if ((sp1 = search(sp->name, gsyms.tail)) == 0) {
		    /* put entry in the global symbol table */
		    ++global_flag;
		    sp1 = (struct sym *) xalloc((int) sizeof(struct sym));
		    sp1->name = strsave(sp->name);
		    sp1->storage_class = sc_external;
		    sp1->tp = save_type(sp->tp);
		    append(&sp1, &gsyms);
		    --global_flag;
		} else {
		    /* already defined in global symbol table */
		    if (!eq_type(sp->tp, sp1->tp))
			error(ERR_REDECL);
		}
		no_append = 1;
		sp = sp1;
	    }
/*
 * static local function declarations should be put in the
 * global symbol table to retain the compiler generated
 * label number
 */
	    if (sp->tp->type == bt_func && sp->storage_class == sc_static
		&& table == &lsyms) {
		if ((sp1 = search(sp->name, gsyms.tail)) == 0) {
		    /* put it into the global symbol table */
		    ++global_flag;
		    sp1 = (struct sym *) xalloc((int) sizeof(struct sym));
		    sp1->name = strsave(sp->name);
		    sp1->storage_class = sc_static;
		    sp1->tp = save_type(sp->tp);
		    sp1->value.i = sp->value.i;
		    append(&sp1, &gsyms);
		    --global_flag;
		} else {
		    if (!eq_type(sp->tp, sp1->tp))
			error(ERR_REDECL);
		}
		no_append = 1;
		sp = sp1;
	    }
	    if (ztype == bt_union)
		nbytes = imax(nbytes, sp->tp->size);
	    else if (al != sc_external)
		nbytes += sp->tp->size;
	    if (!no_append)
		append(&sp, table);
	    if (func_flag) {
		/* function body follows */
		int             local_nparms = nparms;
		ret_type = sp->tp->btp;
		if (!global_flag)
		    error(ERR_SYNTAX);
		nparms = 0;
		funcbody(sp, names, local_nparms);
		return nbytes;
	    }
	    if ((al == sc_global || al == sc_static) &&
		sp->tp->type != bt_func && sp->used != -1)
		doinit(sp, alignment(head));
	    else if (lastst == assign)
		if (regflag == 1 || regflag == 2)
		    auto_init(sp);
		else {
		    error(ERR_ILLINIT);
		    doinit(sp, alignment(head));
		}
	    /* Just a small check, it was proposed that I should make it */
	    if (sp->tp->size == 0 && sp->storage_class != sc_external
                                  && sp->storage_class != sc_typedef
                                  && regflag < 3) {
		do_warning();
		fprintf(stderr,"Attempt to allocate zero storage\n");
	    }
	}			/* end of if (declid != 0) ..... */
	if (lastst == semicolon)
	    break;
	needpunc(comma);
	if (declbegin(lastst) == 0)
	    break;
	head = dhead;
    }
    getsym();
    return nbytes;
}

static int
declbegin(st)
    enum e_sym      st;
{
    return st == star || st == id || st == openpa ||
	st == openbr || st == colon;
}

static
declenum(table)
    TABLE          *table;
{
    struct sym     *sp;
    TYP            *tp;
    if (lastst == id) {
	if ((sp = search(lastid, ltags.tail)) == 0 &&
	    (sp = search(lastid, gtags.tail)) == 0) {
	    sp = (struct sym *) xalloc((int) sizeof(struct sym));
            if (short_option)
	        sp->tp = mk_type(bt_short, 2);
            else
                sp->tp = mk_type(bt_long, 4);
	    sp->storage_class = sc_type;
	    sp->name = strsave(lastid);
	    sp->tp->sname = sp->name;
	    getsym();
	    if (lastst != begin)
		error(ERR_INCOMPLETE);
	    else {
		if (global_flag)
		    append(&sp, &gtags);
		else
		    append(&sp, &ltags);
		getsym();
		enumbody(table);
	    }
	} else
	    getsym();
	head = sp->tp;
    } else {
        if (short_option)
	    tp = mk_type(bt_short, 2);
        else
            tp = mk_type(bt_long, 4);
	if (lastst != begin)
	    error(ERR_INCOMPLETE);
	else {
	    getsym();
	    enumbody(table);
	}
	head = tp;
    }
}

static
enumbody(table)
    TABLE          *table;
{
    long            evalue;
    struct sym     *sp;
    evalue = 0;
    while (lastst == id) {
	sp = (struct sym *) xalloc((int) sizeof(struct sym));
	sp->value.i = evalue++;
	sp->name = strsave(lastid);
	sp->storage_class = sc_const;
	sp->tp = &tp_econst;
	append(&sp, table);
	getsym();
	if (lastst == assign) {
	    getsym();
	    evalue = sp->value.i = intexpr();
	    evalue++;
	}
	if (short_option &&(sp->value.i < -32768 || sp->value.i > 32767))
	    error(ERR_ENUMVAL);
	if (lastst == comma)
	    getsym();
	else if (lastst != end)
	    break;
    }
    needpunc(end);
}

static
declstruct(ztype)
/*
 * declare a structure or union type. ztype should be either bt_struct or
 * bt_union.
 *
 * References to structures/unions not yet declared are allowed now. The
 * declaration has to be done before the structure is used the first time
 */
    enum e_bt       ztype;
{
    struct sym     *sp;
    TYP            *tp;
    if (lastst == id) {
	if ((sp = search(lastid, ltags.tail)) == 0 &&
	    (sp = search(lastid, gtags.tail)) == 0) {
	    sp = (struct sym *) xalloc((int) sizeof(struct sym));
	    sp->name = strsave(lastid);
	    sp->tp = mk_type(ztype, 0);
	    sp->tp->lst.head = 0;
	    sp->storage_class = sc_type;
	    sp->tp->sname = sp->name;
	    if (global_flag)
		append(&sp, &gtags);
	    else
		append(&sp, &ltags);
	}
	if (sp->tp->lst.head != 0)
	    getsym();
	else {
	    getsym();
	    /* allow, e.g. struct x *p; before x is defined */
	    if (lastst == begin) {
		getsym();
		structbody(sp->tp, ztype);
	    }
	}
	head = sp->tp;
    } else {
	tp = mk_type(ztype, 0);
	tp->sname = 0;
	tp->lst.head = 0;
	if (lastst != begin)
	    error(ERR_INCOMPLETE);
	else {
	    getsym();
	    structbody(tp, ztype);
	}
	head = tp;
    }
}

static
structbody(tp, ztype)
    TYP            *tp;
    enum e_bt       ztype;
{
    long            slc;
    slc = 0;
    bit_next = 0;
    while (lastst != end) {
	if (ztype == bt_struct)
	    slc += declare(&(tp->lst), sc_member, slc, ztype, -1);
	else
	    slc = imax(slc, declare(&tp->lst, sc_member, 0l, ztype, -2));
    }
    /*
     * consider alignment of structs in arrays...
     */
    if (slc % AL_DEFAULT != 0)
	slc += AL_DEFAULT - (slc % AL_DEFAULT);
    tp->size = slc;
    getsym();
    bit_next = 0;
}

compile()
/*
 * main compiler routine. this routine parses all of the declarations using
 * declare which will call funcbody as functions are encountered.
 */
{
#ifdef VERBOSE
    time_t          ltime;
#endif

#ifdef VERBOSE
    times(&tms_buf);
    ltime = tms_buf.tms_utime;
#endif

    global_flag = 1;
    strtab = 0;
    lc_bss = 0;
    gsyms.head = gsyms.tail = 0;
    gtags.head = gtags.tail = 0;
    lsyms.head = lsyms.tail = 0;
    ltags.head = ltags.tail = 0;
    labsyms.head = labsyms.tail = 0;
    nextlabel = 1;
    while (lastst != eof) {
	dodecl(sc_global);
	if (lastst != eof)
	    getsym();
    }
#ifdef VERBOSE
    times(&tms_buf);
    decl_time += tms_buf.tms_utime - ltime;
#endif
    dumplits();
}

dodecl(defclass)
    enum e_sc       defclass;
{
    struct sym     *sp;
    int             regflag;
    long            slc = 0;
    for (;;) {
	regflag = 1;
	switch (lastst) {
	  case kw_register:
	    regflag = 2;
	    getsym();
	    if (defclass != sc_auto && defclass != sc_parms)
		error(ERR_ILLCLASS);
	    goto do_decl;
	  case kw_auto:
	    getsym();
	    if (defclass != sc_auto)
		error(ERR_ILLCLASS);
	    goto do_decl;
	  case id:
	    /*
	     * If it is a typedef identifier, do the declaration.
	     */
	    if ((sp = gsearch(lastid)) != 0 && sp->storage_class == sc_typedef)
		goto do_decl;
	    /* else fall through */
	    /*
	     * If defclass == sc_global (we are outside any function), almost
	     * anything can start a declaration, look, e.g. mined:
	     * (*escfunc(c))() ,,almost anything'' is not exact: id (no
	     * typedef id), star, or openpa.
	     */
	  case openpa:
	  case star:
	    if (defclass == sc_global)
		goto do_decl;
	    return;
	    /* else fall through to declare	 */
	  case kw_char:
	  case kw_short:
	  case kw_unsigned:
	  case kw_long:
	  case kw_struct:
	  case kw_union:
	  case kw_enum:
	  case kw_void:
	  case kw_float:
	  case kw_double:
	  case kw_int:
    do_decl:
	    if (defclass == sc_global)
		(void) declare(&gsyms, sc_global, 0l, bt_struct, 0);
	    else if (defclass == sc_auto)
		lc_auto +=
		    declare(&lsyms, sc_auto, lc_auto, bt_struct, regflag);
	    else		/* defclass == sc_parms (parameter decl.) */
		slc +=
		    declare(&lsyms, sc_auto, slc, bt_struct, regflag + 2);
	    break;
	  case kw_static:
	    getsym();
	    if (defclass == sc_member)
		error(ERR_ILLCLASS);
	    if (defclass == sc_auto)
		(void) declare(&lsyms, sc_static, 0l, bt_struct, 0);
	    else
		(void) declare(&gsyms, sc_static, 0l, bt_struct, 0);
	    break;
	  case kw_typedef:
	    getsym();
	    if (defclass == sc_member)
		error(ERR_ILLCLASS);
	    if (defclass == sc_auto)
		(void) declare(&lsyms, sc_typedef, 0l, bt_struct, 0);
	    else
		(void) declare(&gsyms, sc_typedef, 0l, bt_struct, 0);
	    break;
	  case kw_extern:
	    getsym();
	    if (defclass == sc_member)
		error(ERR_ILLCLASS);
	    ++global_flag;
	    (void) declare(&gsyms, sc_external, 0l, bt_struct, 0);
	    --global_flag;
	    break;
	  default:
	    return;
	}
    }
}

int
eq_type(tp1, tp2)
    TYP            *tp1, *tp2;
/*
 * This is used to tell valid from invalid redeclarations
 */
{
    if (tp1 == 0 || tp2 == 0)
	return 0;

    if (tp1 == tp2)
	return 1;

    if (tp1->type != tp2->type)
	return 0;

    if (tp1->type == bt_pointer || tp1->type == bt_func)
	return eq_type(tp1->btp, tp2->btp);

    if (tp1->type == bt_struct || tp1->type == bt_union)
	return (tp1->lst.head == tp2->lst.head);

    return 1;
}

static TYP     *
save_type(tp)
    TYP            *tp;
{
    TYP            *ret_tp;
/* the type structure referenced by tp may be in local tables.
   Copy it to global tables and return a pointer to it.
 */
    if (tp->st_flag != 0)
	return tp;
    ++global_flag;
    ret_tp = (TYP *) xalloc((int) sizeof(TYP));

/* copy TYP structure */
    *ret_tp = *tp;
    ret_tp->st_flag = 1;

    if (tp->type == bt_func || tp->type == bt_pointer)
	ret_tp->btp = save_type(tp->btp);

    if (tp->type == bt_struct || tp->type == bt_union) {
	/*
	 * It consumes very much memory to duplicate the symbol table, so we
	 * don't do it. I think we needn't do it if it is in local tables, so
	 * this warning is perhaps meaningless.
	 */
	do_warning();
	fprintf(stderr, "didn't copy local struct/union in save_type\n");
	ret_tp->lst.head = (struct sym *) 0;
	ret_tp->lst.tail = (struct sym *) 0;
    }
    --global_flag;
    return ret_tp;
}
