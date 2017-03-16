/************************************************************************
 *									*
 *				N O T I C E				*
 *									*
 *			Copyright Abandoned, 1987, Fred Fish		*
 *									*
 *	This previously copyrighted work has been placed into the	*
 *	public domain by the author (Fred Fish) and may be freely used	*
 *	for any purpose, private or commercial.  I would appreciate	*
 *	it, as a courtesy, if this notice is left in all copies and	*
 *	derivative works.  Thank you, and enjoy...			*
 *									*
 *	The author makes no warranty of any kind with respect to this	*
 *	product and explicitly disclaims any implied warranties of	*
 *	merchantability or fitness for any particular purpose.		*
 *									*
 ************************************************************************
 */

/*
 *  FILE
 *
 *	dd2d.c   test dual double to double math functions
 *
 *  KEY WORDS
 *
 *	portable math library
 *	test functions
 *
 *  DESCRIPTION
 *
 *	Tests double precision functions for the Portable Math
 *	Library.  Tests those functions which expect two
 *	double precision arguments and return a double.
 *
 *	Most of the test data in the current data file (dd2d.dat)
 *	was generated using double precision FORTRAN arithmetic
 *	on a Decsystem-20.
 *
 *	Note that the ordering of functions is important for
 *	optimum error information.  Since some functions call
 *	others in the library, the functions being called should
 *	be tested first.  Naturally, an error in a lower level
 *	function will cause propagation of errors up to higher
 *	level functions.
 *
 *  USAGE
 *
 *	dd2d [-esv] [-l limit]
 *
 *		-e	=>	force error for each test
 *				to verify error handling
 *
 *		-l	=>	report errors greater than
 *				specified limit (default 10**-6)
 *
 *		-s	=>	print summary after tests
 *
 *		-v	=>	print each function, argument,
 *				and result
 *
 *	Test directives are read from the standard input, which
 *	may be redirected to the provided test file (dd2d.dat),
 *	and any relative errors are automatically written to standard
 *	output if they exceed a maximum allowable limit.
 *	Each test directive has the form:
 *
 *		<name> <arg1> <arg2> <expected result>
 *
 *	Each field is separated by a one or more space character(s).
 *	The first field, "name", is the name of the function
 *	to test (sqrt, ln, exp, etc).  The second and third fields
 *	are the arguments to use in calling the specified function.
 *	The last field is the expected result.
 *		
 *  PROGRAMMER
 *
 *	Fred Fish
 *	Tempe, Az 85281
 *	(602) 966-8871
 *
 */


#include <stdio.h>
#include <math.h>
#include "pml.h"

#ifdef atarist
#define STDERR	stdout
#else
#define STDERR stderr
#endif

#define MAX_ABS_ERR 1.0e-6	/* Set to catch only gross errors */

static int vflag;		/* Flag for verbose option */
static int eflag;		/* Simulate an error to error printout */
static int sflag;		/* Flag to show final statistics */

static double max_abs_err = MAX_ABS_ERR;

extern double atan2 ();

#ifdef max
#undef min
#undef max

extern double max ();
extern double min ();

#endif 0

/*
 *	Define all recognized test functions.  Each function
 *	must have an entry in this table, where each
 *	entry contains the information specified in the 
 *	structure "test".
 *
 */

struct test {			/* Structure of each function to be tested */
    char *name;			/* Name of the function to test */
    double (*func)();		/* Pointer to the function's entry point */
    double max_err;		/* Error accumulator for this function */
};

static struct test tests[] = {	/* Table of all recognized functions */
    "atan2", atan2, 0.0,	/* Arc tangent with two args */
    "max", max, 0.0,		/* Maximum value */
    "min", min, 0.0,		/* Minimum value */
    NULL, NULL, 0.0		/* Function list end marker */
};


/*
 *  FUNCTION
 *
 *	main   entry point for dd2d test utility
 *
 *  PSEUDO CODE
 *
 *	Begin main
 *	    Process any options in command line.
 *	    Do all tests requested by stdin directives.
 *	    Report final statistics (if enabled).
 *	End main
 *
 */

main (argc, argv)
int argc;
char *argv[];
{
    options (argc, argv);
    dotests (argv);
    statistics ();
}


/*
 *  FUNCTION
 *
 *	dotests   process each test from stdin directives
 *
 *  ERROR REPORTING
 *
 *	Note that in most cases, the error criterion is based
 *	on relative error, defined as:
 *
 *	    error = (result - expected) / expected
 *
 *	Naturally, if the expected result is zero, some
 *	other criterion must be used.  In this case, the
 *	absolute error is used.  That is:
 *
 *	    error = result
 *
 *  PSEUDO CODE
 *
 *	Begin dotests
 *	    While a test directive is successfully read from stdin
 *		Default function name to "{null}"
 *		Default argument 1 to 0.0
 *		Default argument 2 to 0.0
 *		Default expected result to 0.0
 *		Extract function name, argument and expected result
 *		Lookup test in available test list
 *		If no test was found then
 *		    Tell user that unknown function was specified
 *		Else
 *		    Call function with argument and save result
 *		    If the verify flag is set then
 *			Print function name, argument, and result
 *		    End if
 *		    If the expected result is not zero then
 *			Compute the relative error
 *		    Else
 *			Use the absolute error
 *		    End if
 *		    Get absolute value of error
 *		    If error exceeds limit or error force flag set
 *			Print error notification on stderr
 *		    End if
 *		    If this error is max for given function then
 *			Remember this error for summary
 *		    End if
 *		End if
 *	    End while
 *	End dotests
 *
 */


dotests (argv)
char *argv[];
{
    char buffer[256];		/* Directive buffer */
    char function[64];		/* Specified function name */
    double arg1;		/* Specified function argument 1 */
    double arg2;		/* Specified function argument 2 */
    double expected;		/* Specified expected result */
    double result;		/* Actual result */
    double error;		/* Relative or absolute error */
    double abs_err;		/* Absolute value of error */
    struct test *testp;		/* Pointer to function test */
    struct test *lookup ();	/* Returns function test pointer */
    register char *strp;	/* Pointer to next token in string */
    extern char *strtok ();
    extern double atof ();

#ifdef MJR
    FILE * save_stdin, * re_stdin;
    save_stdin = stdin;
    re_stdin = freopen("dd2d.dat","r",stdin);
    if( re_stdin == (FILE *)NULL ) {
	exit(-33);
    }
#endif
    while (fgets (buffer, sizeof(buffer), stdin) != NULL) {
	strcpy (function, "{null}");
	arg1 = 0.0;
	arg2 = 0.0;
	expected = 0.0;
	sscanf (buffer, "%s %le %le %le", function, &arg1, &arg2, &expected);
        testp = lookup (function);
        if (testp == NULL) {
            fprintf (STDERR, "%s: unknown function \"%s\".\n",
	    	argv[0], function);
        } else {
	    result = (*testp -> func)(arg1, arg2);
	    if (vflag) {
	        printf ("%s(%le,%le) = %30.23le.\n",
		function, arg1, arg2, result);
	    }
	    if (expected != 0.0) {
	        error = (result - expected) / expected;
	    } else {
	        error = result;
	    }
	    if (error < 0.0) {
		abs_err = -error;
	    } else {
		abs_err = error;
	    }
            if ((abs_err > max_abs_err) || eflag) {
		fprintf (STDERR, "%s: error in \"%s\"\n", argv[0], function);
		fprintf (STDERR, "\targument 1\t%25.20le\n", arg1);
		fprintf (STDERR, "\targument 2\t%25.20le\n", arg2);
		fprintf (STDERR, "\tresult\t\t%25.20le\n", result);
		fprintf (STDERR, "\texpected\t%25.20le\n", expected);
            }
	    if (abs_err > testp -> max_err) {
	        testp -> max_err = abs_err;
	    }
        }
    }
#ifdef MJR
    fclose( re_stdin );
#endif
}


/*
 *  FUNCTION
 *
 *	options   process command line options
 *
 *  PSEUDO CODE
 *
 *	Begin options
 *	    Reset all flags to FALSE by default
 *	    Initialize flag argument scan pointer
 *	    If there is a second command line argument then
 *		If the argument specifies flags then
 *		    While there is an unprocessed flag
 *			Switch on flag
 *			Case "force error flag":
 *			    Set the "force error" flag
 *			    Break switch
 *			Case "print summary":
 *			    Set "print summary" flag
 *			    Break switch
 *			Case "verbose":
 *			    Set "verbose" flag
 *			    Break switch
 *			Default:
 *			    Tell user unknown flag
 *			    Break switch
 *			End switch
 *		    End while
 *		End if
 *	    End if
 *	End options
 *
 */


options (argc, argv)
int argc;
char *argv[];
{
    register int flag;
    extern int getopt ();
    extern char *optarg;

    eflag = sflag = vflag = FALSE;
    while ((flag = getopt (argc, argv, "#:el:sv")) != EOF) {
	switch (flag) {
	    case '#':
		break;
	    case 'e':
		eflag = TRUE;
		break;
	    case 'l':
	        sscanf (optarg, "%le", &max_abs_err);
		break;
	    case 's':
		sflag = TRUE;
		break;
	    case 'v':
		vflag = TRUE;
		break;
	}
    }
}


/*
 *  FUNCTION
 *
 *	loopup   lookup test in known test list
 *
 *  DESCRIPTION
 *
 *	Given the name of a desired test, looks up the test
 *	in the known test list and returns a pointer to the
 *	test structure.
 *
 *	Since the table is so small we simply use a linear
 *	search.
 *
 *  PSEUDO CODE
 *
 *	Begin lookup
 *	    For each known test
 *		If the test's name matches the desired test name
 *		    Return pointer to the test structure
 *		End if
 *	    End for
 *	End lookup
 *
 */

struct test *lookup (funcname)
char *funcname;
{
    struct test *testp;
    struct test *rtnval;

    rtnval = (struct test *) NULL;
    for (testp = tests; testp -> name != NULL && rtnval == NULL; testp++) {
	if (!strcmp (testp -> name, funcname)) {
	    rtnval = testp;
 	}
    }
    return (rtnval);
}


/*
 *  FUNCTION
 *
 *	statistics   print final statistics if desired
 *
 *  PSEUDO CODE
 *
 *	Begin statistics
 *	    If a final statistics (summary) is desired then
 *		For each test in the known test list
 *		    Print the maximum error encountered
 *		End for
 *	    End if
 *	End statistics
 *
 */

statistics ()
{
    struct test *tp;

    if (sflag) {
        for (tp = tests; tp -> name != NULL; tp++) {
	    printf ("%s:\tmaximum relative error %le\n", 
	    	tp -> name, tp -> max_err);
	}
    }
}
