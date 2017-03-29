/*
 *	test.c
 *
 *	This program is intended to do a first level confidence check
 *	on the multiply and divide support routines for C68.  More detailed
 *	checks should be performed as part of a serious library test suite.
 *	(such as the Plum Hall validation suite).
 */

#include <stdio.h>

char    _progname[]="68k Test";
char    _version[] ="v1.0";
char    _copyright[] =  "(c) D.J.Walker, 1994";

#ifdef QDOS
#include <qdos.h>
struct  WINDOWDEF _condetails = {2,1,0,7,452,235,30,10};
void    (*_consetup)() = consetup_title;
#endif /* QDOS */

main()
{
	unsigned long ulx, uly, ulz;
	long	lx, ly, lz;
	short	sx, sy, sz;

#ifndef QDOS
	printf("\n%s %s\t\t%s\n",_progname, _version, _copyright);
#endif /* QDOS */

	printf("\n---------------- multiply -------------\n\n");
	lx = 3; ly = 3; lz = lx * ly;
	printf ("signed:   +3 * +3 = %ld\n", lz);
	lx = -3; ly = -3; lz = lx * ly;
	printf ("signed:   -3 * -3 = %ld\n", lz);
	lx = 3; ly = -3; lz = lx * ly;
	printf ("signed:   -3 * +3 = %ld\n", lz);
	lx = 3; ly = -3; lz = lx * ly;
	printf ("signed:   +3 * -3 = %ld\n", lz);
	ulx = 3; uly = 3; ulz = ulx * uly;
	printf ("unsigned: 3 x 3 = %ld\n", ulz);
	
	printf("\n------------ multiply (power of 2) -------------\n\n");
	lx = 3; ly = 4; lz = lx * ly;
	printf ("signed:   +3 * +4 = %ld\n", lz);
	lx = -3; ly = -4; lz = lx * ly;
	printf ("signed:   -3 * -4 = %ld\n", lz);
	lx = 3; ly = -4; lz = lx * ly;
	printf ("signed:   -3 * +4 = %ld\n", lz);
	lx = 3; ly = -4; lz = lx * ly;
	printf ("signed:   +3 * -4 = %ld\n", lz);
	ulx = 3; uly = 4; ulz = ulx * uly;
	printf ("unsigned: 3 x 4 = %ld\n", ulz);

	getchar();
	printf("\n---------------- divide -------------\n\n");
	lx = 5; ly = 3; lz = lx / ly;
	printf ("signed:   +5 / +3 = %ld\n", lz);
	lx = -5; ly = -3; lz = lx / ly;
	printf ("signed:   -5 / -3 = %ld\n", lz);
	lx = 5; ly = -3; lz = lx / ly;
	printf ("signed:   -5 / +3 = %ld\n", lz);
	lx = 5; ly = -3; lz = lx / ly;
	printf ("signed:   +5 / -3 = %ld\n", lz);
	ulx = 5; uly = 3; ulz = ulx / uly;
	printf ("unsigned: 5 / 3 = %ld\n", ulz);
	ulx = 5; uly = 3; ulz = ulx / uly;

	sx = -5; sy = -3; sz = sx / sy;
	printf ("signed short:   -5 / -3 = %d\n", sz);
	sx = 5; sy = -3; sz = sx / sy;
	printf ("signed short:   -5 / +3 = %d\n", sz);
	sx = 5; sy = -3; sz = sx / sy;
	printf ("signed short:   +5 / -3 = %d\n", sz);

	printf("\n---------------- modulus -------------\n\n");
	lx = 5; ly = 3; lz = lx % ly;
	printf ("signed:   +5 %% +3 = %ld\n", lz);
	lx = -5; ly = -3; lz = lx % ly;
	printf ("signed:   -5 %% -3 = %ld\n", lz);
	lx = -5; ly = 3; lz = lx % ly;
	printf ("signed:   -5 %% +3 = %ld\n", lz);
	lx = 5; ly = -3; lz = lx % ly;
	printf ("signed:   +5 %% -3 = %ld\n", lz);
	ulx = 5; uly = 3; ulz = ulx % uly;
	printf ("unsigned: 5 %% 3 = %ld\n", ulz);

	sx = -5; sy = -3; sz = sx % sy;
	printf ("signed short:   -5 %% -3 = %d\n", sz);
	sx = -5; sy = 3; sz = sx % sy;
	printf ("signed short:   -5 %% +3 = %d\n", sz);
	sx = 5; sy = -3; sz = sx % sy;
	printf ("signed short:   +5 %% -3 = %d\n", sz);

	getchar();
	printf("\n-------------- divide (power of 2)-------------\n\n");
	lx = 7; ly = 4; lz = lx / ly;
	printf ("signed:   +7 / +4 = %ld\n", lz);
	lx = -7; ly = -4; lz = lx / ly;
	printf ("signed:   -7 / -4 = %ld\n", lz);
	lx = 7; ly = -4; lz = lx / ly;
	printf ("signed:   -7 / +4 = %ld\n", lz);
	lx = 7; ly = -4; lz = lx / ly;
	printf ("signed:   +7 / -4 = %ld\n", lz);
	ulx = 7; uly = 4; ulz = ulx / uly;
	printf ("unsigned: 7 / 4 = %ld\n", ulz);

	sx = -7; sy = -4; sz = sx / sy;
	printf ("signed short:   -7 / -4 = %d\n", sz);
	sx = 7; sy = -4; sz = sx / sy;
	printf ("signed short:   -7 / +4 = %d\n", sz);
	sx = 7; sy = -4; sz = sx / sy;
	printf ("signed short:   +7 / -4 = %d\n", sz);

	printf("\n---------------- modulus (power of 2) -------------\n\n");
	lx = 7; ly = 4; lz = lx % ly;
	printf ("signed:   +7 %% +4 = %ld\n", lz);
	lx = -7; ly = -4; lz = lx % ly;
	printf ("signed:   -7 %% -4 = %ld\n", lz);
	lx = -7; ly = 4; lz = lx % ly;
	printf ("signed:   -7 %% +4 = %ld\n", lz);
	lx = 7; ly = -4; lz = lx % ly;
	printf ("signed:   +7 %% -4 = %ld\n", lz);
	ulx = 7; uly = 4; ulz = ulx % uly;
	printf ("unsigned: 7 %% 4 = %ld\n", ulz);

	sx = -7; sy = -4; sz = sx % sy;
	printf ("signed short:   -7 %% -4 = %d\n", sz);
	sx = -7; sy = 4; sz = sx % sy;
	printf ("signed short:   -7 %% +4 = %d\n", sz);
	sx = 7; sy = -4; sz = sx % sy;
	printf ("signed short:   +7 %% -4 = %d\n", sz);

	getchar();
	printf("\n---------------- assign multiply -------------\n\n");
	lx = 3; ly = 3; lx *= ly;
	printf ("signed:   +3 *= +3   = %ld\n", lx);
	lx = -3; ly = -3; lx *= ly;
	printf ("signed:   -3 *= -3   = %ld\n", lx);
	lx = 3; ly = -3; lx *= ly;
	printf ("signed:   -3 *= +3   = %ld\n", lx);
	lx = 3; ly = -3; lx *= ly;
	printf ("signed:   +3 *= -3   = %ld\n", lx);
	ulx = 3; uly = 3; ulx *= uly;
	printf ("unsigned: 3 *= 3     = %ld\n", ulx);
	
	printf("\n---------------- assign divide -------------\n\n");
	lx = 5; ly = 3; lx /= ly;
	printf ("signed:   +5 /= +3   = %ld\n", lx);
	lx = -5; ly = -3; lx /= ly;
	printf ("signed:   -5 /= -3   = %ld\n", lx);
	lx = -5; ly = 3; lx /= ly;
	printf ("signed:   -5 /= +3   = %ld\n", lx);
	lx = 5; ly = -3; lx /= ly;
	printf ("signed:   +5 /= -3   = %ld\n", lx);
	ulx = 5; uly = 3; ulx /= uly;
	printf ("unsigned: 5 /= 3     = %ld\n", ulx);

	printf("\n---------------- assign modulus -------------\n\n");
	lx = 5; ly = 3; lx %= ly;
	printf ("signed:   +5 %%= +3   = %ld\n", lx);
	lx = -5; ly = -3; lx %= ly;
	printf ("signed:   -5 %%= -3   = %ld\n", lx);
	lx = -5; ly = 3; lx %= ly;
	printf ("signed:   -5 %%= +3   = %ld\n", lx);
	lx = 5; ly = -3; lx %= ly;
	printf ("signed:   +5 %%= -3   = %ld\n", lx);
	ulx = 5; uly = 3; ulx %= uly;
	printf ("unsigned: 5 %%= 3     = %ld\n", ulx);

	printf ("\n");
}
