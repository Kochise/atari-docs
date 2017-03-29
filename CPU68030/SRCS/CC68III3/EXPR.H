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

/* expression tree descriptions	 */

enum e_node {
    en_void,
    en_icon, en_fcon, en_labcon, en_nacon, en_autocon,
    en_fcall, en_tempref, en_add, en_sub, en_mul, en_mod,
    en_div, en_lsh, en_rsh, en_cond, en_assign, en_eq, en_ne,
    en_asadd, en_assub, en_asmul, en_asdiv, en_asmod, en_asrsh,
    en_asxor,
    en_aslsh, en_asand, en_asor, en_uminus, en_not, en_compl,
    en_lt, en_le, en_gt, en_ge, en_and, en_or, en_land, en_lor,
    en_xor, en_ainc, en_adec,
    en_ref, en_cast, en_deref,
    en_fieldref,
};

/* statement node descriptions	 */

enum e_stmt {
    st_expr, st_while, st_for, st_do, st_if, st_switch,
    st_case, st_goto, st_break, st_continue, st_label,
    st_return, st_compound, st_default
};

struct enode {
    enum e_node     nodetype;
    enum e_bt       etype;
    long            esize;
    char            bit_width, bit_offset; /* possibly unsigned char */
    union {
	long            i;
#ifndef NOFLOAT
	double          f;
#endif
	char           *sp;
	struct enode   *p[2];
    }               v;
};

#define lvalue(NODE) ((NODE)->nodetype == en_ref)
#define NIL_ENODE ( (struct enode *) 0)

struct snode {
    enum e_stmt     stype;
    struct snode   *next;	/* next statement */
    struct enode   *exp;	/* condition or expression */
    struct snode   *s1;		/* internal statement */
    union {
	struct enode   *e;	/* condition or expression */
	struct snode   *s;	/* internal statement (else) */
	long            i;	/* (case)label or flag */
    }               v1, v2;
};

#define NIL_SNODE ( (struct snode *) 0)


struct cse {
    struct cse     *next;
    struct enode   *exp;	/* optimizable expression */
    unsigned short  uses;	/* number of uses */
    unsigned short  duses;	/* number of dereferenced uses */
    short           voidf;	/* cannot optimize flag */
    short           reg;	/* allocated register */
};

struct enode   *mk_node();
struct enode   *mk_icon();
struct enode   *parmlist();
struct enode   *copynode();
struct snode   *statement();
struct snode   *compound();
