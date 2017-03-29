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

/* genffp.c -- generate a MOTOROLA FastFloatingPoint number */

/*
 * The following floating-point operations are needed in this module:
 *
 * - comparision with 0.0, 0.5 and 1.0 - division by 2.0 - multiplication with
 * 2.0 (performed as addition here) - subtraction of 1.0
 */

#ifndef NOFLOAT
unsigned long
genffp(d)
    double          d;
{
    unsigned long   mantissa;
    int             sign = 0, exponent = 64, i;

    if (d < 0.0) {
	sign = 128;
	d = -d;
    }
    while (d < 0.5) {
	d += d;
	--exponent;
	if (exponent == 0)
	    return sign;	/* zero fp number */
    }

    while (d >= 1.0) {
	d /= 2.0;
	++exponent;
	if (exponent >= 127)
	    return 127 + sign;	/* +/- infinity */
    }

    /* 0.5 <=d <1.0 now: construct the mantissa */

    mantissa = 0;
    for (i = 0; i < 24; i++) {
	/* 24 mantissa bits */
	d += d;
	mantissa = mantissa + mantissa;
	if (d >= 1.0) {
	    ++mantissa;
	    d -= 1.0;
	}
    }

    /* round up, if the next bit would be 1 */
    if (d >= 0.5)
	++mantissa;
    /* check on mantissa overflow */
    if (mantissa > 0xFFFFFF) {
	++exponent;
	/* exponent overflow? */
	if (exponent >= 127)
	    return (127 + sign);
	mantissa >>= 1;
    }
    /* put the parts together and return the value */

    return (mantissa << 8) + sign + exponent;
}
#endif /* ! defined(NOFLOAT) */
