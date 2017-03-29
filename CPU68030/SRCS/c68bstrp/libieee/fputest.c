/*
 *	Test program for checking out hardware FPU support
 */

#define VERSION  "v1.20"

#include <stdio.h>
#include <time.h>
#include <stdlib.h>

char _prog_name[] = "FPUtest";
char _version[] = VERSION;
char _copyright[] = "(c)1995-1996, D.J.Walker";

#ifdef QDOS
#include <qdos.h>
struct	WINDOWDEF _condetails = {2,1,0,7,452,235,30,10};
void	(*_consetup)() = consetup_title;
#endif /* QDOS */

#define LOOP_COUNT 500000

#define FPU_FLAG_POINTER	((char *)0x280d0)

#define  MULTIPLY	0
#define  DIVIDE 	1
#define  ADD		2
#define  SUBTRACT	3
#define  FPCONV 	4
#define  LONGCONV	5

#define  TESTCOUNT	6

#define  SWFLOAT	0
#define  SWDOUBLE	1
#define  HWFLOAT	2
#define  HWDOUBLE	3
#define  INFLOAT	4
#define  INDOUBLE	5

#define  TIMECOUNT	6

long	loopcount;

time_t	timings[TESTCOUNT][TIMECOUNT];
time_t	start, floatlooptime, doublelooptime;
int 	opertype, floattype, doubletype;

void
print_result (char * string, int count)
{
#if 0
	printf (" %2ld %2ld %2ld %2ld %2ld %2ld\n",
			timings[SWFLOAT][count],
			timings[SWDOUBLE][count],
			timings[HWFLOAT][count],
			timings[HWDOUBLE][count],
			timings[INFLOAT][count],
			timings[INDOUBLE][count]);
#endif
	printf ("%12s", string);
	printf ("    %4.2f (%2ld/%2ld)",
				((double)timings[SWFLOAT][count])/((double)timings[HWFLOAT][count]),
				timings[SWFLOAT][count],
				timings[HWFLOAT][count]);
	printf ("  %4.2f (%2ld/%2ld)",
				((double)timings[SWDOUBLE][count])/((double)timings[HWDOUBLE][count]),
				timings[SWDOUBLE][count],
				timings[HWDOUBLE][count]);
	printf ("    %4.2f (%2ld/%2ld)",
				((double)timings[SWFLOAT][count])/((double)timings[INFLOAT][count]),
				timings[SWFLOAT][count],
				timings[INFLOAT][count]);
	printf ("  %4.2f (%2ld/%2ld)",
				((double)timings[SWDOUBLE][count])/((double)timings[INDOUBLE][count]),
				timings[SWDOUBLE][count],
				timings[INDOUBLE][count]);
	printf ("\n");
	return;
}

void
operation (int oper, int f, int d)
{
static	char *	operstr[TESTCOUNT] = {
			"Multiply",
			"Divide",
			"Add",
			"Subtract",
			"FP Convert",
			"LONG Convert"
			};

	printf ("  %-15.15s", operstr[oper]);
	printf ("  double ...");
	opertype = oper;
	floattype = f;
	doubletype = d;
	return;
}

void
double_done (void)
{
	time_t * ptr = &timings[doubletype][opertype];

	*ptr = time(NULL)-start - doublelooptime;
	if (*ptr == 0)
		*ptr += 1;	   /* Safety for later */
	printf ("\b\b\b\b=%2ld, float ...", *ptr);
	return;
}

void
float_done (void)
{
	time_t * ptr  = &timings[floattype][opertype];
	*ptr = time(NULL)-start - floatlooptime;
	if (*ptr == 0)
		*ptr += 1;
	printf ("\b\b\b\b=%2ld \n", *ptr);
	return;
}

void
dummy_loop (void)
{
	int 	x;
	double	d1, d2;
	float	f1, f2;
	long	l1, l2;

	printf ("==== calibration loop ====\n");
	printf ("  Loop Count = %d\n", loopcount);
	for (x=0, d1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
	}
	doublelooptime = time(NULL)-start;

	for (x=0, f1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
	}
	floatlooptime = time(NULL)-start;
}

void
software_loop (void)
{
#pragma fpu=no
	int 	x;
	double	d1, d2;
	float	f1, f2;
	long	l1, l2;

	printf ("==== library calls (using software) ====\n");
	*FPU_FLAG_POINTER = 0x00;

	operation(MULTIPLY, SWFLOAT, SWDOUBLE);
	for (x=0, d1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		d2 = d1 * 3.3;
	}
	double_done();
	for (x=0, f1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		f2 = f1 * (float)3.3;
	}
	float_done();

	operation(DIVIDE, SWFLOAT, SWDOUBLE);
	for (x=0, d1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		d2 = d1 / 3.3;
	}
	double_done();
	for (x=0, f1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		f2 = f1 / (float)3.3;
	}
	float_done();

	operation(ADD, SWFLOAT, SWDOUBLE);
	for (x=0, d1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		d2 = d1 + 3.3;
	}
	double_done();
	for (x=0, f1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		f2 = f1 + (float)3.3;
	}
	float_done();

	operation(SUBTRACT, SWFLOAT, SWDOUBLE);
	for (x=0, d1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		d2 = d1 - 3.3;
	}
	double_done();
	for (x=0, f1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		f2 = f1 - (float)3.3;
	}
	float_done();

	operation(FPCONV, SWFLOAT, SWDOUBLE);
	for (x=0, d1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		d2 = f1;
	}
	double_done();
	for (x=0, f1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		f2 = d1;
	}
	float_done();

	operation (LONGCONV, SWFLOAT, SWDOUBLE);
	l1 = 123 ; l2 = 1234567;
	for (x=0, start=time(NULL) ; x < loopcount ; x++) {
		d1 = l1;  d2 = l2;
	}
	double_done();
	for (x=0, start=time(NULL) ; x < loopcount ; x++) {
		f1 = l1;   f2 = l2;
	}
	float_done();
}

void
hardware_loop (void)
{
#pragma fpu=no
	int 	x;
	double	d1, d2;
	float	f1, f2;
	long	l1, l2;

	printf ("==== library calls (using hardware) ====\n");
	*FPU_FLAG_POINTER = 0x04;

	operation (MULTIPLY, HWFLOAT, HWDOUBLE);
	for (x=0, d1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		d2 = d1 * 3.3;
	}
	double_done();
	for (x=0, f1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		f2 = f1 * (float)3.3;
	}
	float_done();

	operation (DIVIDE, HWFLOAT, HWDOUBLE);
	for (x=0, d1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		d2 = d1 / 3.3;
	}
	double_done ();
	for (x=0, f1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		f2 = f1 / (float)3.3;
	}
	float_done();

	operation(ADD, HWFLOAT, HWDOUBLE);
	for (x=0, d1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		d2 = d1 + 3.3;
	}
	double_done();
	for (x=0, f1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		f2 = f1 + (float)3.3;
	}
	float_done();

	operation(SUBTRACT, HWFLOAT, HWDOUBLE);
	for (x=0, d1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		d2 = d1 - 3.3;
	}
	double_done();
	for (x=0, f1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		f2 = f1 - (float)3.3;
	}
	float_done();

	operation(FPCONV, HWFLOAT, HWDOUBLE);
	for (x=0, d1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		d2 = f1;
	}
	double_done();
	for (x=0, f1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		f2 = d1;
	}
	float_done();

	operation(LONGCONV, HWFLOAT, HWDOUBLE);
	l1 = 123 ; l2 = 1234567;
	for (x=0, start=time(NULL) ; x < loopcount ; x++) {
		d1 = l1;  d2 = l2;
	}
	double_done();
	for (x=0, start=time(NULL) ; x < loopcount ; x++) {
		f1 = l1;   f2 = l2;
	}
	float_done ();
}

void
inline_loop (void)
{
#pragma fpu=yes
	int 	x;
	double	d1, d2;
	float	f1, f2;
	long	l1, l2;

	printf ("==== inline hardware instructions ====\n");
	*FPU_FLAG_POINTER = 0x04;

	operation (MULTIPLY, INFLOAT, INDOUBLE);
	for (x=0, d1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		d2 = d1 * 3.3;
	}
	double_done();
	for (x=0, f1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		f2 = f1 * (float)3.3;
	}
	float_done();

	operation (DIVIDE, INFLOAT, INDOUBLE);
	for (x=0, d1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		d2 = d1 / 3.3;
	}
	double_done();
	for (x=0, f1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		f2 = f1 / (float)3.3;
	}
	float_done();

	operation (ADD, INFLOAT, INDOUBLE);
	for (x=0, d1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		d2 = d1 + 3.3;
	}
	double_done();
	for (x=0, f1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		f2 = f1 + (float)3.3;
	}
	float_done();

	operation (SUBTRACT, INFLOAT, INDOUBLE);
	for (x=0, d1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		d2 = d1 - 3.3;
	}
	double_done();
	for (x=0, f1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		f2 = f1 - (float)3.3;
	}
	float_done();

	operation (FPCONV, INFLOAT, INDOUBLE);
	for (x=0, d1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		d2 = f1;
	}
	double_done();
	for (x=0, f1 = 2.3, start=time(NULL) ; x < loopcount ; x++) {
		f2 = d1;
	}
	float_done();

	operation (LONGCONV, INFLOAT, INDOUBLE);
	l1 = 123 ; l2 = 1234567;
	for (x=0, start=time(NULL) ; x < loopcount ; x++) {
		d1 = l1;  d2 = l2;
	}
	double_done();
	for (x=0, start=time(NULL) ; x < loopcount ; x++) {
		f1 = l1;   f2 = l2;
	}
	float_done();
}

main(int argc, char *argv[])
{
#pragma fpu=no
	time_t	now;
	char	save = *FPU_FLAG_POINTER;

	loopcount = (argc == 2) ? atol(argv[1]) : LOOP_COUNT;

	now = time(NULL);
	printf ("%s %s\t%s\t%s\n",_prog_name, _version, _copyright, ctime(&now));
	printf ("Timing Test of Hardware FPU support\n");
	printf (" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");

	dummy_loop();
	software_loop();
	hardware_loop();
	inline_loop();

	*FPU_FLAG_POINTER = 0x00;

	printf ("\n\t\t****** TEST RESULTS *******\n\n");
	printf ("                (Library Software/Hardware)  (Library Software/Inline)\n");
	printf (" operation      Float         Double          Float        Double\n");
	printf (" ~~~~~~~~~      ~~~~~         ~~~~~~          ~~~~~        ~~~~~~\n");
	print_result ("multiply",	  MULTIPLY);
	print_result ("divide", 	  DIVIDE);
	print_result ("add",		  ADD);
	print_result ("subtract",	  SUBTRACT);
	print_result ("FP Convert",   FPCONV);
	print_result ("Long Convert", LONGCONV);
	printf ("\n");
}
