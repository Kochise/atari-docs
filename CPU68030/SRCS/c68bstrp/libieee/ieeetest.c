/*
 *	ieeetest.c
 *
 *	This program is intended to do a first level confidence check
 *	on the IEEE support routines for C68.  More detailed checks
 *	should be performed as part of a serious library test suite.
 *	(such as the Plum Hall validation suite).
 *
 *	AMENDMENT HISTORY
 *	~~~~~~~~~~~~~~~~~
 *	29 Dec 95	DJW   - Fixed to make sure all support routines called
 *						(i.e. removed use of constants which compiler optimised out!)
 *
 *	12 Feb 96	DJW   - Merged in tests for LHS op= RHS routines where LHS is
 *						an integral value and RHS is a FP value (these were
 *						previously in a separate test program).
 *					  - Added tests for new support routines.
 */

#include <stdio.h>
#include <time.h>

char	_progname[]="IEEEtest";
char	_version[] ="v1.20";
char	_copyright[] =	"(c)1992-1996, D.J.Walker";

#ifdef QDOS
#include <qdos.h>
struct	WINDOWDEF _condetails = {2,1,0,7,452,235,30,10};
void	(*_consetup)() = consetup_title;
#endif /* QDOS */

double frexp (double value, int *eptr);
double ldexp (double value, int exp);
double modf  (double value, double *iptr);
float  modff (float  value, float *iptr);

union  F {
	float f;
	unsigned long  v;
	} xf, yf, zf;

union  D {
	double d;
	unsigned long  v[2];
	} xd, yd, zd;

void
printf_float (msg, f)
char *msg;
union F *f;
{
	printf (" float (%s):  sign=%d,  exp= %02.2x  mant=%06.6lx\n",
		msg,
		(int)((f->v >> 31) & 0x01),
		(int)((f->v >> 23) & 0xFF),
		(long)((f->v << 1) & 0xFFFFFF));
}

void
printf_double (msg, d)
char *msg;
union D *d;
{
	printf ("double (%s):  sign=%d,  exp=%03.3x mant=%05.5lx%08.8lx\n",
		msg,
		(int)((d->v[0] >> 31) & 0x01),
		(int)((d->v[0] >> 20) & 0x7FF),
		(long)((d->v[0] ) & 0xFFFFF),
		(unsigned long)d->v[1]);
}

void  print_result (char * str, int actual, int expected)
{
	printf ("%s.  Result=%d      ", str, actual);
	if (actual == expected)
		printf ("OK");
	else 
		printf ("**** ERROR ****");
	printf ("\n");
	return;
}

asop_tests()
{
	double d;
	float f;

	char c;
	short s;
	int i;
	long l;

	unsigned char uc;
	unsigned short us;
	unsigned int ui;
	unsigned long ul;

	struct {
		int s:16;
		unsigned int u:16;
	} b;

	printf ("\nTest of 'double' variants\n\n");
	/*
	 *	 Positive =* positive
	 */
	d = 1.2;

	c = 10;    c *= d;
	print_result ("c(=10) *= 1.2", c, 12);

	s = 10;    s *= d;
	print_result ("s(=10) *= 1.2", s, 12);

	i = 10;    i *= d;
	print_result ("i(=10) *= 1.2", i, 12);

	l = 10;    l *= d;
	print_result ("l(=10) *= 1.2", l, 12);

	b.s = 10;	 b.s *= d;
	print_result ("b.s(=10) *= 1.2", b.s, 12);

	uc = 10;	uc *= d;
	print_result ("uc(=10) *= 1.2", uc, 12);

	us = 10;	us *= d;
	print_result ("us(=10) *= 1.2", us, 12);

	ui = 10;	ui *= d;
	print_result ("ui(=10) *= 1.2", ui, 12);

	ul = 10;	ul *= d;
	print_result ("ul(=10) *= 1.2", ul, 12);

	b.u = 10;	 b.u *= d;
	print_result ("b.u(=10) *= 1.2", b.u, 12);

	/*
	 *	 Positive =* negative
	 */
	d = -1.2;

	c = 10;    c *= d;
	print_result ("c(=10) *= -1.2", c, -12);

	s = 10;    s *= d;
	print_result ("s(=10) *= -1.2", s, -12);

	i = 10;    i *= d;
	print_result ("i(=10) *= -1.2", i, -12);

	l = 10;    l *= d;
	print_result ("l(=10) *= -1.2", l, -12);

	b.s = 10;	 b.s *= d;
	print_result ("b.s(=10) *= -1.2", b.s, -12);

	uc = 10;	uc *= d;
	print_result ("uc(=10) *= -1.2", uc, ((unsigned char)-12));

	us = 10;	us *= d;
	print_result ("us(=10) *= -1.2", us, ((unsigned short)-12));

	ui = 10;	ui *= d;
	print_result ("ui(=10) *= -1.2", ui, ((unsigned int)-12));

	ul = 10;	ul *= d;
	print_result ("ul(=10) *= -1.2", ul, ((unsigned long)-12));

	b.u = 10;	 b.u *= d;
	print_result ("b.u(=10) *= -1.2", b.u, ((unsigned short)-12));

	/*
	 *	 Positive /* positive
	 */
	d = 1.2;

	c = 10;    c /= d;
	print_result ("c(=10) /= 1.2", c, 8);
	c = 10; 
	print_result ("c(=10) /= 1.2", c /= d, 8);

	s = 10;    s /= d;
	print_result ("s(=10) /= 1.2", s, 8);

	i = 10;    i /= d;
	print_result ("i(=10) /= 1.2", i, 8);

	l = 10;    l /= d;
	print_result ("l(=10) /= 1.2", l, 8);

	b.s = 10;	 b.s /= d;
	print_result ("b.s(=10) /= 1.2", b.s, 8);

	uc = 10;	uc /= d;
	print_result ("uc(=10) /= 1.2", uc, 8);

	us = 10;	us /= d;
	print_result ("us(=10) /= 1.2", us, 8);

	ui = 10;	ui /= d;
	print_result ("ui(=10) /= 1.2", ui, 8);

	ul = 10;	ul /= d;
	print_result ("ul(=10) /= 1.2", ul, 8);

	b.u = 10;	 b.u /= d;
	print_result ("b.u(=10) /= 1.2", b.u, 8);

	/*
	 *	 Positive /= negative
	 */
	d = -1.2;

	c = 10;    c /= d;
	print_result ("c(=10) /= -1.2", c, -8);

	s = 10;    s /= d;
	print_result ("s(=10) /= -1.2", s, -8);

	i = 10;    i /= d;
	print_result ("i(=10) /= -1.2", i, -8);

	l = 10;    l /= d;
	print_result ("l(=10) /= -1.2", l, -8);

	b.s = 10;	 b.s /= d;
	print_result ("b.s(=10) /= -1.2", b.s, -8);

	uc = 10;	uc /= d;
	print_result ("uc(=10) /= -1.2", uc, ((unsigned char)-8));

	us = 10;	us /= d;
	print_result ("us(=10) /= -1.2", us, ((unsigned short)-8));

	ui = 10;	ui /= d;
	print_result ("ui(=10) /= -1.2", ui, ((unsigned int)-8));

	ul = 10;	ul /= d;
	print_result ("ul(=10) /= -1.2", ul, ((unsigned long)-8));

	b.u = 10;	 b.u /= d;
	print_result ("b.u(=10) /= -1.2", b.u, ((unsigned short)-8));


	/*
	 *	 Positive =* positive
	 */
	printf ("\nTest of 'float' variants\n\n");
	f = 1.2F;

	c = 10;    c *= f;
	print_result ("c(=10) *= 1.2", c, 12);

	s = 10;    s *= f;
	print_result ("s(=10) *= 1.2", s, 12);

	i = 10;    i *= f;
	print_result ("i(=10) *= 1.2", i, 12);

	l = 10;    l *= f;
	print_result ("l(=10) *= 1.2", l, 12);

	b.s = 10;	 b.s *= f;
	print_result ("b.s(=10) *= 1.2", b.s, 12);

	uc = 10;	uc *= f;
	print_result ("uc(=10) *= 1.2", uc, 12);

	us = 10;	us *= f;
	print_result ("us(=10) *= 1.2", us, 12);

	ui = 10;	ui *= f;
	print_result ("ui(=10) *= 1.2", ui, 12);

	ul = 10;	ul *= f;
	print_result ("ul(=10) *= 1.2", ul, 12);

	b.u = 10;	 b.u *= f;
	print_result ("b.u(=10) *= 1.2", b.u, 12);


	/*
	 *	 Positive =* negative
	 */
	f = -1.2F;

	c = 10;    c *= f;
	print_result ("c(=10) *= -1.2", c, -12);

	s = 10;    s *= f;
	print_result ("s(=10) *= -1.2", s, -12);

	i = 10;    i *= f;
	print_result ("i(=10) *= -1.2", i, -12);

	l = 10;    l *= f;
	print_result ("l(=10) *= -1.2", l, -12);

	b.s = 10;	 b.s *= f;
	print_result ("b.s(=10) *= -1.2", b.s, -12);

	uc = 10;	uc *= f;
	print_result ("uc(=10) *= -1.2", uc, ((unsigned char)-12));

	us = 10;	us *= f;
	print_result ("us(=10) *= -1.2", us, ((unsigned short)-12));

	ui = 10;	ui *= f;
	print_result ("ui(=10) *= -1.2", ui, ((unsigned int)-12));

	ul = 10;	ul *= f;
	print_result ("ul(=10) *= -1.2", ul, ((unsigned long)-12));

	b.u = 10;	 b.u *= f;
	print_result ("b.u(=10) *= -1.2", b.u, ((unsigned short)-12));

	/*
	 *	 Positive /* positive
	 */
	f = 1.2F;

	c = 10;    c /= f;
	print_result ("c(=10) /= 1.2", c, 8);
	c = 10; 
	print_result ("c(=10) /= 1.2", c /= f, 8);

	s = 10;    s /= f;
	print_result ("s(=10) /= 1.2", s, 8);

	i = 10;    i /= f;
	print_result ("i(=10) /= 1.2", i, 8);

	l = 10;    l /= f;
	print_result ("l(=10) /= 1.2", l, 8);

	b.s = 10;	 b.s /= f;
	print_result ("b.s(=10) /= 1.2", b.s, 8);

	uc = 10;	uc /= f;
	print_result ("uc(=10) /= 1.2", uc, 8);

	us = 10;	us /= f;
	print_result ("us(=10) /= 1.2", us, 8);

	ui = 10;	ui /= f;
	print_result ("ui(=10) /= 1.2", ui, 8);

	ul = 10;	ul /= f;
	print_result ("ul(=10) /= 1.2", ul, 8);

	b.u = 10;	 b.u /= f;
	print_result ("b.u(=10) /= 1.2", b.u, 8);

	/*
	 *	 Positive /= negative
	 */
	f = -1.2F;

	c = 10;    c /= f;
	print_result ("c(=10) /= -1.2", c, -8);

	s = 10;    s /= f;
	print_result ("s(=10) /= -1.2", s, -8);

	i = 10;    i /= f;
	print_result ("i(=10) /= -1.2", i, -8);

	l = 10;    l /= f;
	print_result ("l(=10) /= -1.2", l, -8);

	b.s = 10;	 b.s /= f;
	print_result ("b.s(=10) /= -1.2", b.s, -8);

	uc = 10;	uc /= f;
	print_result ("uc(=10) /= -1.2", uc, ((unsigned char)-8));

	us = 10;	us /= f;
	print_result ("us(=10) /= -1.2", us, ((unsigned short)-8));

	ui = 10;	ui /= f;
	print_result ("ui(=10) /= -1.2", ui, ((unsigned int)-8));

	ul = 10;	ul /= f;
	print_result ("ul(=10) /= -1.2", ul, ((unsigned long)-8));

	b.u = 10;	 b.u /= f;
	print_result ("b.u(=10) /= -1.2", b.u, ((unsigned short)-8));
}


main()
{
	unsigned long ul;
	unsigned int ui;
	long	l;
	int i;
	time_t	now;

	now = time(NULL);
	printf("\n%s %s\t\t%s\t%s\n",_progname, _version, _copyright, ctime(&now));

	printf("\n---------------- simple assignments -------------\n\n");
	xf.f = 10.0F; printf_float ("xf=10.0", &xf);
	xd.d = 10.0; printf_double ("xd=10.0", &xd);

	xf.f = -xf.f; printf_float ("xf = -xf",&xf);
	xd.d = -xd.d; printf_double ("xd = -xd",&xd);

	printf("\n---------------- arithmetic operators -------------\n\n");
	yd.d = 1.0;
	xd.d = 1.0 + yd.d; printf_double ("double add (1.0+1.0)",&xd);
	xd.d = 2.0 - yd.d; printf_double ("double sub (2.0-1.0)",&xd);

	printf("\n");
	yf.f = 1.0F;
	xf.f = 1.0F + yf.f; printf_float ("float add (1.0+1.0)",&xf);
	xf.f = 2.0F - yf.f; printf_float ("float sub (2.0-1.0)",&xf);

	printf("\n");
	yd.d = 2.0;
	xd.d = 2.0 * yd.d; printf_double ("multiply 2.0 * 2.0",&xd);
	xd.d = 4.0 / yd.d; printf_double ("divide   4.0 / 2.0",&xd);

	printf("\n");
	yf.f = 2.0F;
	xf.f = 2.0F * yf.f; printf_float ("multiply 2.0 * 2.0",&xf);
	xf.f = 4.0F / yf.f; printf_float ("divide   4.0 / 2.0",&xf);

	printf("\n---------------- operator assignment -------------\n\n");
	xd.d = 1.0;
	xd.d += 1.0; printf_double ("plus assign     1.0 += 1.0", &xd);
	xd.d -= 1.0; printf_double ("minus assign    2.0 -= 1.0", &xd);
	xd.d *= 2.0; printf_double ("multiply assign 1.0 *= 2.0", &xd);
	xd.d /= 2.0; printf_double ("divide assign   2.0 /= 2.0", &xd);

	printf("\n");
	xf.f = 1.0; 
	xf.f += 1.0; printf_float ("plus assign)    1.0 += 1.0", &xf);
	xf.f -= 1.0; printf_float ("minus assign    2.0 -= 1.0", &xf);
	xf.f *= 2.0; printf_float ("multiply assign 1.0 *= 2.0", &xf);
	xf.f /= 2.0; printf_float ("divide assign   2.0 /= 2.0", &xf);

	printf("\n---------------- arithmetic compares -------------\n\n");
	printf ("double compare (equal       ) is\t%d\t%d\n",1.0==1.0, 1.0==2.0);
	printf ("double compare (not equal   ) is\t%d\t%d\n",1.0!=2.0, 1.0!=1.0);
	printf ("double compare (less than   ) is\t%d\t%d\n",1.0< 2.0, 1.0<-1.0);
	printf ("double compare (greater than) is\t%d\t%d\n",1.0>-1.0, 1.0>2.0);

	printf ("\n");
	printf (" float compare (equal       ) is\t%d\t%d\n",1.0==1.0, 1.0==2.0);
	printf (" float compare (not equal   ) is\t%d\t%d\n",1.0!=2.0, 1.0!=1.0);
	printf (" float compare (less than   ) is\t%d\t%d\n",1.0< 2.0, 1.0<-1.0);
	printf (" float compare (greater than) is\t%d\t%d\n",1.0>-1.0, 1.0>2.0);

	printf("\n---------------- logical compares -------------\n\n");
	xd.d = 1.0;
	printf ("double test true=%d, false=%d\n",(xd.d ? 1 : 0),(!xd.d ? 1 : 0));
	xf.f = 1.0;
	printf ("float  test true=%d, false=%d\n",(xf.f ? 1  :0),(!xf.f ? 1 : 0));

	printf("\n---------------- conversions (fp to fp )-------------\n\n");
	xd.d = 1.0; xf.f = xd.d; printf_float ("from double:  1.0",&xf);
	xd.d =-1.0; xf.f = xd.d; printf_float ("from double: -1.0",&xf);
	xf.f = 1.0; xd.d = xf.f; printf_double ("from float:  1.0",&xd);
	xf.f =-1.0; xd.d = xf.f; printf_double ("from float: -1.0",&xd);

	printf("\n---------------- conversions (integers to fp) -------------\n\n");
	l = 1;	xd.d = l;  printf_double(" long(1) to double",&xd);
	i = 1;	xd.d = i;  printf_double("  int(1) to double",&xd);
	ul = 1; xd.d = ul; printf_double("ulong(1) to double",&xd);
	ui = 1; xd.d = ui; printf_double(" uint(1) to double",&xd);
	l = 1;	xf.f = l;  printf_float (" long(1) to float",&xf);
	i = 1;	xf.f = i;  printf_float ("  int(1) to float",&xf);
	ul = 1; xf.f = ul; printf_float ("ulong(1) to float",&xf);
	ui = 1; xf.f = ui; printf_float (" uint(1) to float",&xf);
	printf("\n");
	l = -1;  xd.d = l;	printf_double(" long(-1) to double",&xd);
	i = -1;  xd.d = i;	printf_double("  int(-1) to double",&xd);
	ul = -1; xd.d = ul; printf_double("ulong(-1) to double",&xd);
	ui = -1; xd.d = ui; printf_double(" uint(-1) to double",&xd);
	l = -1;  xf.f = l;	printf_float (" long(-1) to float",&xf);
	i = -1;  xf.f = i;	printf_float ("  int(-1) to float",&xf);
	ul = -1; xf.f = ul; printf_float ("ulong(-1) to float",&xf);
	ui = -1; xf.f = ui; printf_float (" uint(-1) to float",&xf);

	printf("\n---------------- conversions (fp to integers )-------------\n\n");
	xd.d = 1.1;
	i = xd.d;  printf ("double(1.1) to int   = %d\n", i);
	l = xd.d;  printf ("double(1.1) to long  = %ld\n", l);
	ui = xd.d; printf ("double(1.1) to uint  = %d\n", ui);
	ul = xd.d; printf ("double(1.1) to ulong = %ld\n", ul);
	xd.d = -1.1;
	i = xd.d;  printf ("double(-1.1) to int   = %d\n", i);
	l = xd.d;  printf ("double(-1.1) to long  = %ld\n", l);
	ui = xd.d; printf ("double(-1.1) to uint  = %d\n", ui);
	ul = xd.d; printf ("double(-1.1) to ulong = %ld\n", ul);
	xf.f = 1.1;
	i = xf.f;  printf ("float(1.1) to int   = %d\n", i);
	l = xf.f;  printf ("float(1.1) to long  = %ld\n", l);
	ui = xf.f; printf ("float(1.1) to uint  = %d\n", ui);
	ul = xf.f; printf ("float(1.1) to ulong = %ld\n", ul);
	xf.f = -1.1;
	i = xf.f;  printf ("float(-1.1) to int   = %d\n", i);
	l = xf.f;  printf ("float(-1.1) to long  = %ld\n", l);
	ui = xf.f; printf ("float(-1.1) to uint  = %d\n", ui);
	ul = xf.f; printf ("float(-1.1) to ulong = %ld\n", ul);

	printf("\n---------------- post-increment/post-decrment -------------\n\n");

	xd.d = 1.0; printf_double ("double:  1.0",&xd);
	xf.f = 1.0; printf_float  ("float:  1.0",&xf);
	xd.d = 1.0; yd.d = xd.d++ ; printf_double ("double:  (++)  1.0",&yd);
								printf_double ("         (new) 2.0",&xd);
	xd.d = 2.0; yd.d = xd.d-- ; printf_double ("double:  (--)  2.0",&yd);
								printf_double ("         (new) 1.0",&xd);
	xf.f = 1.0; yf.f = xf.f++ ; printf_float ("float:   (++)  1.0",&yf);
								printf_float ("         (new) 2.0",&xf);
	xf.f = 2.0; yf.f = xf.f-- ; printf_float ("float:   (--)  2.0",&yf);
								printf_float ("         (new) 1.0",&xf);

	printf("\n---------------- int op= fp (op = mul/div) -------------\n\n");
	asop_tests();


/*
 *	The next section checks the standard libc routines that are direectly
 *	aware of the bit representation of the floating point numbers and are
 *	resposnsible for splitting them up/assembling them.
 *	NOTE.	If your routines for printing floating point numbers are not
 *		working properly, then you may get some strange results.  Check
 *		the bit patterns for the floating point numbers as well.
 */

	printf("\n---------------- frexp -------------\n\n");
	printf ("yd.d=frexp (xd.d(=+3.4), &i)\n");
	xd.d = 3.4; yd.d = frexp (xd.d, &i);
	printf ("    %g     ",xd.d); printf_double ("xd.d", &xd);
	printf ("    %g     ",yd.d); printf_double ("yd.d", &yd);
	printf ("    %d     integer (i)\n",i);

	printf("\n");
	printf ("yd.d=frexp (xd.d(=-3.4), &i)\n");
	xd.d = -3.4;	yd.d = frexp (xd.d, &i);
	printf ("   %g  ",xd.d); printf_double ("xd.d", &xd);
	printf ("   %g  ",yd.d); printf_double ("yd.d", &yd);
	printf ("   %d      integer (i)\n",i);

	printf("\n");
	printf ("yd.d=frexp (xd.d(=+0.34), &i)\n");
	xd.d = 0.34;	yd.d = frexp (xd.d, &i);
	printf ("    %g ",xd.d); printf_double ("xd.d", &xd);
	printf ("    %g ",yd.d); printf_double ("yd.d", &yd);
	printf ("    %d     integer (i)\n",i);

	printf("\n");
	printf ("yd.d=frexp (xd.d(=0.0), &i)\n");
	xd.d = 0.0; yd.d = frexp (xd.d, &i);
	printf ("    %g     ",xd.d); printf_double ("xd.d", &xd);
	printf ("    %g     ",yd.d); printf_double ("yd.d", &yd);
	printf ("    %d     integer (i)\n",i);

	printf("\n---------------- ldexp -------------\n\n");
	printf ("yd.d=ldexp (xd.d(=+0.85), 2)\n");
	xd.d = 0.85;	yd.d = ldexp (xd.d, 2);
	printf ("    %g     ",xd.d); printf_double ("xd.d", &xd);
	printf ("    %g     ",yd.d); printf_double ("yd.d", &yd);

	printf("\n");
	printf ("yd.d=ldexp (xd.d(=-0.85), 2)\n");
	xd.d = -0.85;	yd.d = ldexp (xd.d, 2);
	printf ("   %g  ",xd.d); printf_double ("xd.d", &xd);
	printf ("   %g  ",yd.d); printf_double ("yd.d", &yd);
	printf("\n");

	printf ("yd.d=ldexp (xd.d(=0.0), 0)\n");
	xd.d = 0.0; yd.d = ldexp (xd.d, 0);
	printf ("    %g     ",xd.d); printf_double ("xd.d", &xd);
	printf ("    %g     ",yd.d); printf_double ("yd.d", &yd);

	printf("\n---------------- modf -------------\n\n");
	printf ("yd.d=modf (xd.d(=+3.4), &zd.d)\n");
	xd.d = 3.4; yd.d = modf (xd.d, &zd.d);
	printf ("    %g     ",xd.d); printf_double ("xd.d", &xd);
	printf ("    %g     ",yd.d); printf_double ("yd.d", &yd);
	printf ("    %g     ",zd.d); printf_double ("zd.d", &zd);

	printf("\n"); 
	printf ("yd.d=modf (xd.d(=-3.4), &zd.d)\n");
	xd.d = -3.4;	yd.d = modf (xd.d, &zd.d);
	printf ("   %g  ",xd.d); printf_double ("xd.d", &xd);
	printf ("   %g  ",yd.d); printf_double ("yd.d", &yd);
	printf ("   %g  ",zd.d); printf_double ("zd.d", &zd);

	printf("\n"); 
	printf ("yd.d=modf (xd.d(=0.0), &zd.d)\n");
	xd.d = 0.0; yd.d = modf (xd.d, &zd.d);
	printf ("   %g  ",xd.d); printf_double ("xd.d", &xd);
	printf ("   %g  ",yd.d); printf_double ("yd.d", &yd);
	printf ("   %g  ",zd.d); printf_double ("zd.d", &zd);

	printf("---------------- modff -------------\n\n");
	printf ("yf.f=modff (xf.f(=+3.4), &zf.f)\n");
	xf.f = 3.4; yf.f = modff (xf.f, &zf.f);
	printf ("    %g     ",xf.f); printf_float ("xf.f", &xf);
	printf ("    %g     ",yf.f); printf_float ("yf.f", &yf);
	printf ("    %g     ",zf.f); printf_float ("zf.f", &zf);

	printf("\n");
	printf ("yf.f=modff (xf.f(=-3.4), &zf.f)\n");
	xf.f = -3.4;	yf.f = modff (xf.f, &zf.f);
	printf ("   %g  ",xf.f); printf_float ("xf.f", &xf);
	printf ("   %g  ",yf.f); printf_float ("yf.f", &yf);
	printf ("   %g  ",zf.f); printf_float ("zf.f", &zf);

	printf("\n"); 
	printf ("yf.f=modff (xf.f(=0.0), &zf.f)\n");
	xf.f = 0.0; yf.f = modff (xf.f, &zf.f);
	printf ("   %g  ",xf.f); printf_float ("xf.f", &xf);
	printf ("   %g  ",yf.f); printf_float ("yf.f", &yf);
	printf ("   %g  ",zf.f); printf_float ("zf.f", &zf);

	printf ("\n\n");
}
