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

#include <ctype.h>

#define MAX_NUM_ERRS 80
static int      err_num[MAX_NUM_ERRS];
static int      numerrs;
static char     linein[500];
static char    *lptr;
static int      act_line;
static char     act_file[100] = "<no filename spec.>";
static int      lineno;


#ifndef isalnum
static int
isalnum(c)
    char            c;
{
/*
 * This function makes assumptions about the character codes.
 */
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
	(c >= '0' && c <= '9');
}

#endif

#ifndef isidch
static int
isidch(c)
    char            c;
{
    return isalnum(c) || c == '_' || c == '$';
}

#endif

#ifndef isspace
int
isspace(c)
    char            c;
{
    return c == ' ' || c == '\t' || c == '\n';
}

#endif

#ifndef isdigit
static int
isdigit(c)
    char            c;
{
/*
 * This function makes assumptions about the character codes.
 */
    return (c >= '0' && c <= '9');
}

#endif

void
initsym()
{
    lptr = linein;
    linein[0] = 0;
    numerrs = 0;
    total_errors = 0;
    lineno = 0;
}


static char    *__err[] = {
    " general error ",
    " illegal character ",
    " illegal floating-point constant ",
    " illegal type ",
    " undefined identifier ",
    " no field allowed here ",
    " expected symbol not found ",
    " identifier expected ",
    " initialization invalid ",
    " incomplete struct/union/enum declaration",
    " illegal initialization ",
    " too many initializers ",
    " illegal storage class ",
    " function body expected",
    " pointer type expected ",
    " function type expected ",
    " struct/union member expected ",
    " l-value required ",
    " error dereferencing a pointer ",
    " type mismatch error ",
    " expression expected ",
    " 'while' expected in do-loop ",
    " enum value out of range ",
    " duplicate case label ",
    " undefined label ",
    " Problem with CPP output ",
    " declared argument missing",
    " illegal field width ",
    " illegal constant integer expression ",
    " error doing a cast ",
    " integer-valued type expected ",
    " error casting a constant",
    " illegal redeclaration ",
    " scanning parameter list",
    " bad field type, must be unsigned or int ",
};
static int
getline()
{
    int             i;
    if (lineno > 0 && list_option) {
	fprintf(list, "%6d\t%s", lineno, linein);
	for (i = 0; i < numerrs; i++)
	    fprintf(list, " *** error: %s\n", __err[err_num[i]]);
	numerrs = 0;
    }
    ++lineno;
    ++act_line;
    if (fgets(linein, 499, input) == NULL)
	return 1;
    lptr = linein;
    if (linein[0] == '#') {
	++lptr;
	lastch = ' ';
	getsym();
	if (lastst == id && !strcmp(lastid, "line"))
	    getsym();
	if (lastst != iconst)
	    error(ERR_PREPROC);
	act_line = ival-1;
	/* scan file name */
	i = 0;
	while (isspace(*lptr))
	    lptr++;
	if (*lptr == '"')
	    lptr++;
	/* assume that a filename does not end with double-quotes */
	while (*lptr != '\0' && *lptr != '"' && !isspace(*lptr))
	    act_file[i++] = *lptr++;
	/*
         * DECUS cpp suppresses the name if it has not changed
	 * in this case, i is simply zero, and then we keep the 
	 * old name
	 */
	if (i > 0)
	    act_file[i] = '\0';
	return getline();
    }
    return 0;
}

/*
 * getch - basic get character routine.
 */
void
getch()
{
    while ((lastch = *lptr++) == '\0') {
	if (getline()) {
	    lastch = -1;
	    break;
	}
    }
    return;
}

/*
 * error - print error information
 */
void
error(n)
    int             n;
{
    if (numerrs < MAX_NUM_ERRS)
        err_num[numerrs++] = n;
    ++total_errors;
    fprintf(stderr, "\"%s\", line %d: error %d: %s\n",
	    act_file, act_line, n, __err[n]);
/*
 * Do not proceed if more than MAX_ERROR_COUNT errors were detected.
 * MAX_ERROR_COUNT should be high since each error might be reported
 * more than once
 */
    if (total_errors > MAX_ERROR_COUNT) {
        fprintf(stderr, "\n\nProgram terminated due to maximum error count\n");
        exit(1);
    }
}

void do_warning()
{
    fprintf(stderr, "\"%s\", line %d: warning: ", act_file, act_line);
}

int
warning()
{
    if (! warn_option)
	return 0;
    do_warning();
    return 1;

}

/*
 * getid - get an identifier.
 *
 * identifiers are any isidch conglomerate that doesn't start with a numeric
 * character. this set INCLUDES keywords.
 */
void
getid()
{
    register int    i;
    i = 0;
    while (isidch(lastch)) {
	if (i < MAX_ID_LEN)
	    lastid[i++] = lastch;
	getch();
    }
    lastid[i] = '\0';
    lastst = id;
}

/*
 * getsch - get a character in a quoted string.
 *
 * this routine handles all of the escape mechanisms for characters in strings
 * and character constants.
 * flag is 0, if a character constant is being scanned,
 * flag is 1, if a string constant is being scanned
 */
int
getsch(flag)
    int flag;
{				/* return an in-quote character */
    register int    i, j;
/*
 * if we scan a string constant, stop if '"' is seen
 */
    if (lastch == '\n' || (flag && lastch == '"'))
	return -1;
    if (lastch != '\\') {
	i = lastch;
	getch();
	return i;
    }
    getch();			/* get an escaped character */
    if (isdigit(lastch)) {
	i = 0;
	for (j = 0; j < 3; ++j) {
	    if (isdigit(lastch) && lastch <= '7')
		i = 8*i + radix36(lastch);
	    else
		break;
	    getch();
	}
        /* signed characters lie in the range -128..127 */
        if ((i &= 0377) >= 128) i -= 256;
	return i;
    }
    i = lastch;
    getch();
    switch (i) {
      case '\n':
	return getsch(1);
      case 'b':
	return '\b';
      case 'f':
	return '\f';
      case 'n':
	return '\n';
      case 'r':
	return '\r';
      case 't':
	return '\t';
      case 'a':
	return '\a';
      case 'v':
	return '\v';
      default:
	return i;
    }
}

int
radix36(c)
    char            c;
{
/*
 * This function makes assumptions about the character codes.
 */
    if (isdigit(c))
	return c - '0';
    if (c >= 'a' && c <= 'z')
	return c - 'a' + 10;
    if (c >= 'A' && c <= 'Z')
	return c - 'A' + 10;
    return -1;
}

static void
test_int(hex_or_octal)
    int             hex_or_octal;
/* test on long or unsigned constants */
{
    if (lastch == 'l' || lastch == 'L') {
	getch();
	lastst = lconst;
	return;
    }
    if (lastch == 'u' || lastch == 'U') {
	if (!hex_or_octal)
	    getch();
	lastst = uconst;
	if (short_option && ival > 65535)
	    lastst = lconst;
	return;
    }
    /* -32768 thus is stored as (unary minus)(32768l) */
/*
 * Although I think it is not correct, octal or hexadecimal
 * constants in the range 0x8000 ... 0xffff are unsigned in 16-bit mode
 */
    if (short_option) {
        if (hex_or_octal && ival > 32767 && ival < 65536) {
            lastst = uconst;
            return;
        }
        if (ival > 32767) {
            /* -32768 thus is stored as (unary minus)(32768l) */
            lastst = lconst;
            return;
        }
    }
}

/*
 * getbase - get an integer in any base.
 */
static void
getbase(b)
    int             b;
{
    /*
     * rval is computed simultaneously - this handles floating point
     * constants whose integer part is greater than INT_MAX correctly, e. g.
     * 10000000000000000000000.0
     */
    register unsigned long i=0;
    register int    j;
#ifndef NOFLOAT
    register double r = 0.0;
#endif

    if (b == 10) {
	while (isdigit(lastch)) {
	    j = radix36(lastch);
	    i = 8 * i + 2 * i + j;
#ifndef NOFLOAT
	    r = 10.0 * r + (double) j;
#endif
	    getch();
	}
    } else {
	while (isalnum(lastch)) {
	    if ((j = radix36(lastch)) < b) {
		i = i * b + j;
		getch();
	    } else
		break;
	}
    }
    ival = i;
#ifndef NOFLOAT
    rval = r;
#endif
    lastst = iconst;
}

/*
 * getfrac - get fraction part of a floating number.
 */
static void
getfrac()
{
#ifndef NOFLOAT
    double          frmul;
    frmul = 0.1;
    while (isdigit(lastch)) {
	rval += frmul * radix36(lastch);
	getch();
	frmul *= 0.1;
    }
#endif
}

/*
 * getexp - get exponent part of floating number.
 *
 * this algorithm is primative but usefull.  Floating exponents are limited to
 * +/-255 but most hardware won't support more anyway.
 */
static void
getexp()
{
#ifndef NOFLOAT
    double          expo, exmul;
    expo = rval;
    if (lastch == '-') {
	exmul = 0.1;
	getch();
    } else
	exmul = 10.0;
    getbase(10);
    lastst = rconst;
    while (ival--)
        expo *= exmul;
    rval = expo;
#endif
}

/*
 * getnum - get a number from input.
 *
 * getnum handles all of the numeric input. it accepts decimal, octal,
 * hexidecimal, and floating point numbers.
 */
static void
getnum()
{
    if (lastch == '0') {
	getch();
	if (lastch == 'x' || lastch == 'X') {
	    getch();
	    getbase(16);
	    test_int(1);
	    return;
	}
	if (lastch != '.' && lastst != 'e' && lastst != 'E') {
	    getbase(8);
	    test_int(1);
	    return;
	}
    }
    getbase(10);
    if (lastch == '.') {
	/* rval already set */
	getch();
	getfrac();		/* add the fractional part */
	lastst = rconst;
    }
    if (lastch == 'e' || lastch == 'E') {
	getch();
	getexp();		/* get the exponent */
    }
    /*
     * look for l and u qualifiers
     */
    if (lastst == iconst)
	test_int(0);
    /*
     * look for (but ignore) f and l qualifiers
     */
    if (lastst == rconst)
        if (lastch == 'f' || lastch == 'F' || lastch == 'l' ||
            lastch == 'L')
            getch();
}

/*
 * getsym - get next symbol from input stream.
 *
 * getsym is the basic lexical analyzer.
 * It builds basic tokens out of the characters on the input stream
 * and sets the following global variables:
 *
 * lastch:	A look behind buffer.
 * lastst:	type of last symbol read.
 * laststr:	last string constant read.
 * lastid:	last identifier read.
 * ival:	last integer constant read.
 * rval:	last real constant read.
 *
 * getsym should be called for all your input needs...
 */
void
getsym()
{
    register int    i, j;
restart:			/* we come back here after comments */
    while (isspace(lastch))
	getch();
    if (lastch == -1)
	lastst = eof;
    else if (isdigit(lastch))
	getnum();
    else if (isidch(lastch))
	getid();
    else
	switch (lastch) {
	  case '+':
	    getch();
	    if (lastch == '+') {
		getch();
		lastst = autoinc;
	    } else if (lastch == '=') {
		getch();
		lastst = asplus;
	    } else
		lastst = plus;
	    break;
	  case '-':
	    getch();
	    if (lastch == '-') {
		getch();
		lastst = autodec;
	    } else if (lastch == '=') {
		getch();
		lastst = asminus;
	    } else if (lastch == '>') {
		getch();
		lastst = pointsto;
	    } else
		lastst = minus;
	    break;
	  case '*':
	    getch();
	    if (lastch == '=') {
		getch();
		lastst = astimes;
	    } else
		lastst = star;
	    break;
	  case '/':
	    getch();
	    if (lastch == '=') {
		getch();
		lastst = asdivide;
	    } else if (lastch == '*') {
		getch();
		for (;;) {
		    if (lastch == '*') {
			getch();
			if (lastch == '/') {
			    getch();
			    goto restart;
			}
		    } else
			getch();
		}
	    } else
		lastst = divide;
	    break;
	  case '^':
	    getch();
	    if (lastch == '=') {
		getch();
		lastst = asuparrow;
	    } else
		lastst = uparrow;
	    break;
	  case ';':
	    getch();
	    lastst = semicolon;
	    break;
	  case ':':
	    getch();
	    lastst = colon;
	    break;
	  case '=':
	    getch();
	    if (lastch == '=') {
		getch();
		lastst = eq;
	    } else
		lastst = assign;
	    break;
	  case '>':
	    getch();
	    if (lastch == '=') {
		getch();
		lastst = geq;
	    } else if (lastch == '>') {
		getch();
		if (lastch == '=') {
		    getch();
		    lastst = asrshift;
		} else
		    lastst = rshift;
	    } else
		lastst = gt;
	    break;
	  case '<':
	    getch();
	    if (lastch == '=') {
		getch();
		lastst = leq;
	    } else if (lastch == '<') {
		getch();
		if (lastch == '=') {
		    getch();
		    lastst = aslshift;
		} else
		    lastst = lshift;
	    } else
		lastst = lt;
	    break;
	  case '\'':
	    getch();
	    ival = getsch(0);	/* get a string char */
	    if (lastch != '\'')
		error(ERR_SYNTAX);
	    else
		getch();
	    lastst = iconst;
	    break;
	  case '\"':
	    getch();
	    for (i = 0; ; ++i) {
		if ((j = getsch(1)) == -1)
		    break;
                if (i < MAX_STRLEN)
		    laststr[i] = j;
	    }
	    /*
	     * Attention: laststr may contain zeroes!
	     */
            if (i > MAX_STRLEN) {
                i = MAX_STRLEN;
                do_warning();
                fprintf(stderr,"Too long string constant was cut\n");
            }
	    lstrlen = i;
	    laststr[i] = 0;
	    lastst = sconst;
	    if (lastch != '\"')
		error(ERR_SYNTAX);
	    else
		getch();
	    break;
	  case '!':
	    getch();
	    if (lastch == '=') {
		getch();
		lastst = neq;
	    } else
		lastst = not;
	    break;
	  case '%':
	    getch();
	    if (lastch == '=') {
		getch();
		lastst = asmodop;
	    } else
		lastst = modop;
	    break;
	  case '~':
	    getch();
	    lastst = compl;
	    break;
	  case '.':
	    getch();
	    if (isdigit(lastch)) {
#ifndef NOFLOAT
		rval = 0.0;
#endif
		getfrac();
		lastst = rconst;
		if (lastch=='e' || lastch=='E') {
		    getch();
		    getexp();
		}
	    } else
		lastst = dot;
	    break;
	  case ',':
	    getch();
	    lastst = comma;
	    break;
	  case '&':
	    getch();
	    if (lastch == '&') {
		lastst = land;
		getch();
	    } else if (lastch == '=') {
		lastst = asand;
		getch();
	    } else
		lastst = and;
	    break;
	  case '|':
	    getch();
	    if (lastch == '|') {
		lastst = lor;
		getch();
	    } else if (lastch == '=') {
		lastst = asor;
		getch();
	    } else
		lastst = or;
	    break;
	  case '(':
	    getch();
	    lastst = openpa;
	    break;
	  case ')':
	    getch();
	    lastst = closepa;
	    break;
	  case '[':
	    getch();
	    lastst = openbr;
	    break;
	  case ']':
	    getch();
	    lastst = closebr;
	    break;
	  case '{':
	    getch();
	    lastst = begin;
	    break;
	  case '}':
	    getch();
	    lastst = end;
	    break;
	  case '?':
	    getch();
	    lastst = hook;
	    break;
	  default:
	    getch();
	    error(ERR_ILLCHAR);
	    goto restart;	/* get a real token */
	}
    if (lastst == id)
	searchkw();
}

void
needpunc(p)
    enum e_sym      p;
{
    if (lastst == p)
	getsym();
    else
	error(ERR_PUNCT);
}
