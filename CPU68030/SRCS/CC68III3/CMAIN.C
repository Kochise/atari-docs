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
#include	<signal.h>

static          openfiles();
static          closefiles();
static          summary();

static
exception(sig)
    int             sig;
{
    fprintf(stderr, "\n\nSIGNAL %d -- TERMINATING.\n", sig);
    fatal("EXCEPTION");
}

#ifndef _NSIG
#define _NSIG	NSIG
#endif

main(argc, argv)
    int             argc;
    char          **argv;
{
    int             i;

    for (i = 1; i < _NSIG; ++i)
	signal(i, exception);

    argc--;
    argv++;
    while ((argc > 0) && **argv == '-') {
	options(*argv++);
	argc--;
    }
    /*
     * set and check some global options
     */
    if (AL_DEFAULT > 2 && short_option) {
       fprintf(stderr,
       "Warning: option short not supported for this target\n");
       short_option=0;
    }
    /*
     * set 'int' and 'enum' type
     */
    if (short_option) {
	tp_int = tp_short;
	tp_uint = tp_ushort;
	int_bits = 16;
    } else {
	tp_int = tp_long;
	tp_uint = tp_ulong;
	int_bits = 32;
    }
    tp_econst = tp_int;
    tp_econst.val_flag=1;


    openfiles(argc, argv);
    /* return means that all files have been opened */
    out_init();
    initsym();
    getch();
    getsym();
    compile();
    if (list_option)
	summary();
    else
	/* This emits all the global and external directives */
	list_table(&gsyms, 0);
#ifdef VERBOSE
    fprintf(stderr, "\n -- %d errors found.\n", total_errors);
#endif
    rel_global();
    closefiles();
#ifdef VERBOSE
    decl_time -= parse_time;
    parse_time -= gen_time + flush_time;
    gen_time -= opt_time;
    fprintf(stderr, "Times: %6ld + %6ld + %6ld + %6ld + %6ld\n",
	    decl_time, parse_time, opt_time, gen_time, flush_time);
#endif
    if (total_errors > 0)
	exit(1);
    else
	exit(0);
}

int
options(s)
    char           *s;
{
    int value = 1;
    s++; /* forget '-' */
    if (*s == 'Q')
        s++; /* forget 'Q' */
    if (s[0] == 'n' && s[1] == 'o') {
	s += 2;
	value = 0;
    }
    if (!strcmp(s, "list")) {
	list_option = value;
	return;
    }
    if (!strcmp(s, "short")) {
	short_option = value;
	return;
    }
    if (!strcmp(s, "reg")) {
	reg_option = value;
	return;
    }
    if (!strcmp(s, "trans")) {
	trans_option = 1;
	return;
    }
    if (!strcmp(s, "opt")) {
	opt_option = value;
	return;
    }
    if (!strcmp(s, "warn")) {
	warn_option = value;
	return;
    }
    if (!strcmp(s, "fpu")) {
	fpu_option = value;
	return;
    }
#ifdef ICODE
    if (!strcmp(s, "icode")) {
	icode_option = 1;
	return;
    }
#endif
    fprintf(stderr, "Unknown option %s ignored.\n", --s);
}

static int
openfiles(argc, argv)
    int             argc;
    char          **argv;
{
    if (argc < 2) {
	fprintf(stderr, "input and output filename required\n");
	exit(2);
    }
    if ((input = fopen(*argv++, "r")) == NULL) {
	fprintf(stderr, "cant open input file\n");
	exit(2);
    }
    if ((output = fopen(*argv++, "w")) == NULL) {
	fprintf(stderr, "cant open output file\n");
	exit(2);
    }
    if (list_option && (list = fopen(LIST_NAME, "w")) == 0) {
	fprintf(stderr, " cant open listfile\n");
	exit(1);
    }
#ifdef ICODE
    if (icode_option && ((icode = fopen(ICODE_NAME, "w")) == 0)) {
	fprintf(stderr, " cant open icode file\n");
	exit(1);
    }
#endif
}

static
summary()
{
    if (gsyms.head != NULL) {
	fprintf(list, "\f\n *** global scope symbol table ***\n\n");
	list_table(&gsyms, 0);
    }
    if (gtags.head != NULL) {
	fprintf(list, "\n *** structures and unions ***\n\n");
	list_table(&gtags, 0);
    }
}

static int
closefiles()
{
    if (list_option)
	fclose(list);
#ifdef ICODE
    if (icode_option)
	fclose(icode);
#endif
}

fatal(message)
    char           *message;
{
    static int      beenhere = 0;

    fprintf(stderr, "FATAL error encountered.\n");
    fprintf(stderr, "Message: %s\n", message);
    fprintf(stderr, "this may occur due to a syntax error,\n");
    fprintf(stderr, "a feature left out of the compiler,\n");
    fprintf(stderr, "or just a compiler error.\n");
    if (!beenhere) {
	beenhere = 1;
	flush_peep();
    }
    exit(16);
}
