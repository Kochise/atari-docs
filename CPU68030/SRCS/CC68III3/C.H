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

#include <sys/types.h>
#include <sys/times.h>
#include <stdio.h>

#ifdef CPU_DEFINED
#undef CPU_DEFINED
#endif

#ifdef MC68000
#define MC680X0
#ifdef CPU_DEFINED
error, define only one target CPU!
#endif
#define CPU_DEFINED
#define LIST_NAME  "c68.list"
#define ICODE_NAME "c68.icode"
#endif

#ifdef MC68010
#define MC680X0
#ifdef CPU_DEFINED
error, define only one target CPU!
#endif
#define CPU_DEFINED
#define LIST_NAME  "c68.list"
#define ICODE_NAME "c68.icode"
#endif

#ifdef MC68020
#define MC680X0
#ifdef CPU_DEFINED
error, define only one target CPU!
#endif
#define CPU_DEFINED
#define LIST_NAME  "c68.list"
#define ICODE_NAME "c68.icode"
#endif

#ifdef MC68030
#define MC680X0
#ifdef CPU_DEFINED
error, define only one target CPU!
#endif
#define CPU_DEFINED
#define LIST_NAME  "c68.list"
#define ICODE_NAME "c68.icode"
#endif

#ifdef MC68040
#define MC680X0
#ifdef CPU_DEFINED
error, define only one target CPU!
#endif
#define CPU_DEFINED
#define LIST_NAME  "c68.list"
#define ICODE_NAME "c68.icode"
#endif

#ifdef  INTEL_486
#ifndef INTEL_386
#define INTEL_386
#endif
#endif

#ifdef INTEL_386
#ifdef CPU_DEFINED
error, define only one target CPU!
#endif
#define CPU_DEFINED
#define LIST_NAME  "c386.list"
#define ICODE_NAME "c386.icode"
/*
 * if FUNCS_USE_387 is defined, extra library calls are generated if the
 * nofpu option is in effect that allows to use code generated by
 * this compiler to be linked with functions that return values
 * on the 387 stack
 */
#define FUNCS_USE_387
#endif

#ifndef CPU_DEFINED
error, target CPU type must be defined
#endif

/* the tokens returned from lexical analysis */

enum e_sym {
    cconst, iconst, lconst, sconst, rconst, plus, minus,
    divide, lshift, rshift, modop, eq, neq, lt, leq, gt,
    geq, assign, asplus, asminus, astimes, asdivide, asmodop,
    asuparrow,
    aslshift, asrshift, asand, asor, autoinc, autodec, hook, compl,
    comma, colon, semicolon, uparrow, openbr, closebr, begin, end,
    closepa, pointsto, dot, lor, land, not, or, and,
    star, openpa, id, kw_int,
    kw_void, kw_char, kw_float, kw_double, kw_struct, kw_union,
    kw_enum,
    kw_long, kw_short, kw_unsigned, kw_auto, kw_extern,
    kw_register, kw_typedef, kw_static, kw_goto, kw_return,
    kw_sizeof, kw_break, kw_continue, kw_if, kw_else, kw_for,
    kw_do, kw_while, kw_switch, kw_case, kw_default,
    uconst, eof
};

/* storage classes */

enum e_sc {
    sc_static, sc_auto, sc_global, sc_external, sc_type, sc_const,
    sc_member, sc_label, sc_ulabel, sc_typedef, sc_parms
};

/* basic data types */

enum e_bt {
    bt_char, bt_short, bt_long, bt_float, bt_double, bt_pointer,
    bt_ulong, bt_struct, bt_union, bt_func,
    bt_void, bt_uchar, bt_ushort, bt_bitfield
};

/* these form the string literal pool */

struct slit {
    struct slit    *next;
    char           *str;
    unsigned short  label;
    short           len;
};

/* a symbol table */

struct stab {
    struct sym     *head;
    struct sym     *tail;
};

/* structure defining a data type */

struct typ {
    struct stab     lst;
    struct typ     *btp;
    char           *sname;
    long            size;
    enum e_bt       type;
/*
 * The following four chars may be unsigned -- no harm.
 * They could be ints without restriction -- this is to save memory
 */
    char            val_flag;
    char            st_flag;
    char            bit_width;
    char            bit_offset;
};

/* a symbol table entry */

struct sym {
    struct sym     *next;
    struct sym     *prev;
    char           *name;
    struct typ     *tp;
    union {
	long            i;
	unsigned long   u;
	char           *s;
    }
                    value;
    enum e_sc       storage_class;
    int             used;
};

#define TYP	struct typ
#define TABLE	struct stab

#define MAX_ERROR_COUNT 200
#define MAX_STRLEN	1500
#define MAX_ID_LEN	50
#define MAX_PARAMS	100
#define REG_LIST	20
#define AUTO_LIST	100

#define ERR_SYNTAX	0	/* general error */
#define ERR_ILLCHAR	1	/* illegal character */
#define ERR_FPCON	2	/* illegal floating-point constant */
#define ERR_ILLTYPE	3	/* illegal type */
#define ERR_UNDEFINED	4	/* undefined identifier */
#define ERR_FIELD	5	/* no field allowed here */
#define ERR_PUNCT	6	/* expected symbol not found */
#define ERR_IDEXPECT	7	/* identifier expected */
#define ERR_NOINIT	8	/* initialization invalid */
#define ERR_INCOMPLETE	9
#define ERR_ILLINIT	10	/* illegal initialization */
#define ERR_INITSIZE	11	/* too many initializers */
#define ERR_ILLCLASS	12	/* illegal storage class */
#define ERR_BLOCK	13
#define ERR_NOPOINTER	14	/* pointer type expected */
#define ERR_NOFUNC	15	/* function type expected */
#define ERR_NOMEMBER	16	/* struct/union member expected */
#define ERR_LVALUE	17	/* l-value required */
#define ERR_DEREF	18	/* error dereferencing a pointer */
#define ERR_MISMATCH	19	/* type mismatch error */
#define ERR_EXPREXPECT	20	/* expression expected */
#define ERR_WHILEXPECT	21	/* 'while' expected in do-loop */
#define ERR_ENUMVAL	22	/* enum value out of range */
#define ERR_DUPCASE	23	/* duplicate case label */
#define ERR_LABEL	24	/* undefined label */
#define ERR_PREPROC	25	/* Problem with CPP output */
#define ERR_ARG		26	/* declared Argument missing */
#define ERR_WIDTH	27	/* illegal field width */
#define ERR_INTEXPR	28	/* illegal constant integer expression */
#define ERR_CAST	29	/* error doing a cast */
#define ERR_INTEGER	30	/* integer-valued type expected */
#define ERR_CASTCON	31	/* error casting a constant */
#define ERR_REDECL	32	/* illegal redeclaration */
#define ERR_PARMS	33	/* error while scanning a parameter list */
#define ERR_FTYPE	34	/* bad host type for bit fields */

/* alignment sizes */

#ifdef MC68000
/*
 * MC68000 is a 16-bit processor. Word alignment is OK in all cases
 */
#define AL_CHAR 	1
#define AL_SHORT	2
#define AL_LONG 	2
#define AL_POINTER	2
#define AL_FLOAT	2
#define AL_DOUBLE	2
#define AL_STRUCT	2
#define AL_FUNC		2

#define AL_DEFAULT	2	/* alignment suitable for all types */
#endif /* MC68000 */

#ifdef MC68010
/*
 * MC68010 is a 16-bit processor. Word alignment is OK in all cases
 */
#define AL_CHAR 	1
#define AL_SHORT	2
#define AL_LONG 	2
#define AL_POINTER	2
#define AL_FLOAT	2
#define AL_DOUBLE	2
#define AL_STRUCT	2
#define AL_FUNC		2

#define AL_DEFAULT	2	/* alignment suitable for all types */
#endif /* MC68010 */

#ifdef MC68020
/*
 * perhaps not necessary, but useful: 32-bit alignment for 32-bit types
 */
#define AL_CHAR 	1
#define AL_SHORT	2
#define AL_LONG 	4
#define AL_POINTER	4
#define AL_FLOAT	4
#define AL_DOUBLE	4
#define AL_STRUCT	4
#define AL_FUNC		4

#define AL_DEFAULT	4	/* alignment suitable for all types */
#endif /* MC68020 */

#ifdef MC68030
/*
 * perhaps not necessary, but useful: 32-bit alignment for 32-bit types
 */
#define AL_CHAR 	1
#define AL_SHORT	2
#define AL_LONG 	4
#define AL_POINTER	4
#define AL_FLOAT	4
#define AL_DOUBLE	4
#define AL_STRUCT	4
#define AL_FUNC		4

#define AL_DEFAULT	4	/* alignment suitable for all types */
#endif /* MC68030 */

#ifdef MC68040
/*
 * perhaps not necessary, but useful: 32-bit alignment for 32-bit types
 */
#define AL_CHAR 	1
#define AL_SHORT	2
#define AL_LONG 	4
#define AL_POINTER	4
#define AL_FLOAT	4
#define AL_DOUBLE	4
#define AL_STRUCT	4
#define AL_FUNC		4

#define AL_DEFAULT	4	/* alignment suitable for all types */
#endif /* MC68040 */

#ifdef INTEL_386
/*
 * perhaps not necessary, but useful: 32-bit alignment for 32-bit types
 */
#define AL_CHAR 	1
#define AL_SHORT	2
#define AL_LONG 	4
#define AL_POINTER	4
#define AL_FLOAT	4
#define AL_DOUBLE	4
#define AL_STRUCT	4
#define AL_FUNC		4

#define AL_DEFAULT	4	/* alignment suitable for all types */
#endif /* INTEL_386 */


#ifdef SPARC
#define AL_CHAR 	1
#define AL_SHORT	2
#define AL_LONG 	4
#define AL_POINTER	4
#define AL_FLOAT	4
#define AL_DOUBLE	8
#define AL_STRUCT	8
#define AL_FUNC		4

#define AL_DEFAULT	8	/* alignment suitable for all types */
#endif /* SPARC */

char           *strcpy();


int            *xalloc();
struct sym     *search();
struct sym     *gsearch();
char           *strsave();
TYP            *expression();
TYP            *exprnc();
TYP            *cast_op();
TYP            *mk_type();
long            intexpr();
void            getch();
void            error();
void            getsym();
void            needpunc();
void            initsym();
void            append();
int             warning();
long            strip_icon();
long            push_param();
void		do_warning();
