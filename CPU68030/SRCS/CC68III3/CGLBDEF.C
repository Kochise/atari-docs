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

/* global definitions	 */

FILE           *input, *list, *output;
#ifdef ICODE
FILE           *icode;
#endif
unsigned int    nextlabel;
int             lastch;
enum e_sym      lastst;
char            lastid[MAX_ID_LEN+1];
char            laststr[MAX_STRLEN + 1];
int             lstrlen;
unsigned long   ival;
#ifndef NOFLOAT
double          rval;
#endif

TABLE           gsyms, gtags, lsyms, labsyms, ltags;

struct slit    *strtab;
long            lc_auto;
long            max_scratch;
long		act_scratch;
long            lc_bss;
int             global_flag;
#ifdef MC680X0
unsigned int    save_mask;
#endif


/* These are the default options */

int             list_option = 0;
#ifdef MC68000
int             short_option = 1;
int		fpu_option   = 0;
#endif
#ifdef INTEL_386
int		short_option = 0;
int		fpu_option   = 1;
#endif
int             opt_option = 1;
int             trans_option = 0;
int		warn_option = 0;
int             reg_option = 1;
#ifdef ICODE
int             icode_option = 0;
#endif

TYP            *ret_type;
int             regptr;
long            reglst[REG_LIST];
int             autoptr;
long            autolst[AUTO_LIST];
struct enode   *init_node;
#ifdef VERBOSE
struct tms      tms_buf;
long            decl_time = 0, parse_time = 0, opt_time = 0, gen_time = 0, flush_time = 0;
#endif

TYP             tp_void = {{0, 0}, 0, 0, -1, bt_void, 0, 1};
TYP             tp_long = {{0, 0}, 0, 0, 4, bt_long, 0, 1};
TYP             tp_ulong = {{0, 0}, 0, 0, 4, bt_ulong, 0, 1};
TYP             tp_char = {{0, 0}, 0, 0, 1, bt_char, 0, 1};
TYP             tp_uchar = {{0, 0}, 0, 0, 1, bt_uchar, 0, 1};
TYP             tp_short = {{0, 0}, 0, 0, 2, bt_short, 0, 1};
TYP             tp_ushort = {{0, 0}, 0, 0, 2, bt_ushort, 0, 1};
TYP             tp_float = {{0, 0}, 0, 0, 4, bt_float, 0, 1};
#ifdef MC68000
TYP             tp_double = {{0, 0}, 0, 0, 4, bt_double, 0, 1};
#endif
#ifdef INTEL_386
TYP		tp_double = {{0, 0}, 0, 0, 8, bt_double, 0, 1};
#endif
TYP             tp_string = {{0, 0}, &tp_char, 0, 4, bt_pointer, 0, 1};
TYP             tp_int, tp_econst;
TYP             tp_uint;
TYP             tp_func = {{0, 0}, &tp_int, 0, 4, bt_func, 1, 1};

int             int_bits;

#ifdef MC680X0
struct amode    push = {am_adec, 0, STACKPTR - 8, 0, 0},
                pop =  {am_ainc, 0, STACKPTR - 8, 0, 0};
#endif
int		uses_structassign;
int		regs_used;
int		is_leaf_function;
#ifdef INTEL_386
int		edi_used, esi_used, ebx_used;
#endif

TYP            *head = 0, *tail = 0;

int             total_errors;
