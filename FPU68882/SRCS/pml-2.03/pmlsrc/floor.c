/*
 * floor and ceil
 * 	from pete housels posting
 */

#if !defined (__M68881__) || !defined (sfp004)
#if __STDC__
double	modf(double, double *);
#else
double	modf();
#endif

double
floor(x)
double x;
{
 double fract;

 fract = modf(x, &x);

 if(fract < 0.0)
    return x - 1.0;
 else
    return x;
}

double
ceil(x)
double x;
{
	return(-floor(-x));
}
#endif

#ifdef __M68881_

double ceil (double x)
{
  int rounding_mode, round_up;
  double value;

  __asm volatile ("fmove%.l fpcr,%0"
		  : "=dm" (rounding_mode)
		  : /* no inputs */ );
  round_up = rounding_mode | 0x30;
  __asm volatile ("fmove%.l %0,fpcr"
		  : /* no outputs */
		  : "dmi" (round_up));
  __asm volatile ("fint%.x %1,%0"
		  : "=f" (value)
		  : "f" (x));
  __asm volatile ("fmove%.l %0,fpcr"
		  : /* no outputs */
		  : "dmi" (rounding_mode));
  return value;
}

double floor (double x)
{
  int rounding_mode, round_down;
  double value;

  __asm volatile ("fmove%.l fpcr,%0"
		  : "=dm" (rounding_mode)
		  : /* no inputs */ );
  round_down = (rounding_mode & ~0x10)
		| 0x20;
  __asm volatile ("fmove%.l %0,fpcr"
		  : /* no outputs */
		  : "dmi" (round_down));
  __asm volatile ("fint%.x %1,%0"
		  : "=f" (value)
		  : "f" (x));
  __asm volatile ("fmove%.l %0,fpcr"
		  : /* no outputs */
		  : "dmi" (rounding_mode));
  return value;
}
#endif __M68881__

#ifdef	sfp004
#endif	sfp004
