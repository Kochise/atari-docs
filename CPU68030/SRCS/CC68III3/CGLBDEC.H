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

extern FILE    *input, *list, *output;
#ifdef ICODE
extern FILE    *icode;
#endif
extern unsigned int nextlabel;
extern int      lastch;
extern enum e_sym lastst;
extern char     lastid[MAX_ID_LEN+1];
extern char     laststr[MAX_STRLEN + 1];
extern int      lstrlen;
extern unsigned long ival;
#ifndef NOFLOAT
extern double   rval;
#endif

extern TABLE    gsyms, lsyms, labsyms, gtags, ltags;

extern struct slit *strtab;
extern long     lc_auto;
extern long     max_scratch;
extern long	act_scratch;
extern long     lc_bss;		/* local bss counter */
extern int      global_flag;
#ifdef MC680X0
extern unsigned save_mask;	/* register save mask */
#endif

extern int      list_option;
extern int      short_option;
extern int      opt_option;
extern int      trans_option;
extern int	warn_option;
extern int	fpu_option;
extern int	reg_option;
#ifdef ICODE
extern int      icode_option;
#endif
extern TYP     *ret_type;

extern int      regptr;
extern long     reglst[REG_LIST];
extern int      autoptr;
extern long     autolst[AUTO_LIST];

extern struct enode *init_node;

#ifdef VERBOSE
extern struct tms tms_buf;
extern long     decl_time, parse_time, opt_time, gen_time, flush_time;
#endif				/* VERBOSE */

extern TYP      tp_void, tp_long, tp_ulong, tp_char, tp_uchar;
extern TYP      tp_short, tp_ushort, tp_float;
extern TYP      tp_econst, tp_string, tp_int, tp_uint, tp_func;
extern TYP	tp_double;

extern int      int_bits;

#ifdef MC680X0
extern struct amode push, pop;
#endif
extern int uses_structassign;
extern int regs_used;
extern int is_leaf_function;
#ifdef INTEL_386
extern int edi_used, esi_used, ebx_used;
#endif

extern TYP     *head, *tail;

extern int      total_errors;
