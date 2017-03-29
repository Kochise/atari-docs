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

static struct kwblk {
    char           *word;
    enum e_sym      stype;
}               keywords[] = {

    {
	"int", kw_int
    }, {
	"char", kw_char
    }, {
	"long", kw_long
    },
    {
	"float", kw_float
    }, {
	"double", kw_double
    }, {
	"return", kw_return
    },
    {
	"struct", kw_struct
    }, {
	"union", kw_union
    }, {
	"typedef", kw_typedef
    },
    {
	"enum", kw_enum
    }, {
	"static", kw_static
    }, {
	"auto", kw_auto
    },
    {
	"sizeof", kw_sizeof
    }, {
	"do", kw_do
    }, {
	"if", kw_if
    },
    {
	"else", kw_else
    }, {
	"for", kw_for
    }, {
	"switch", kw_switch
    },
    {
	"while", kw_while
    }, {
	"short", kw_short
    }, {
	"extern", kw_extern
    },
    {
	"case", kw_case
    }, {
	"goto", kw_goto
    }, {
	"default", kw_default
    },
    {
	"register", kw_register
    }, {
	"unsigned", kw_unsigned
    },
    {
	"break", kw_break
    }, {
	"continue", kw_continue
    }, {
	"void", kw_void
    },
    {
	0, 0
    }
};

/*
 *
 * The inline expansion of strcmp in search and searchkw reduced the execution
 * time by over 25 percent.
 */
searchkw()
{
    register char  *s1;
    register char  *s2;
    register struct kwblk *kwbp;
    kwbp = keywords;
    while (kwbp->word != 0) {
	s1 = lastid;
	s2 = kwbp->word;
	kwbp++;
	for (;;) {
	    if (*s1++ != *s2)
		break;
	    if (*s2++ == '\0') {
		lastst = (--kwbp)->stype;
		return;
	    }
	}
    }
}
