/*
from: Electronic design/june 26, 1995
      Frank N. Vitaljic


  the calc_coeffs() function can calculate FIR filter coefficients h(i) for
low-pass, high-pass, bandpass, and band-reject filter types. For an odd-
valued filter length N, coefficient values having even-symmetry about
the h[(N-1)/2] coefficient (i.e., h(i)=h(N-1-i)) will exhibit linear phase.
This makes the filter's time delay (Td) independent of frequency.
Td=(N-1)/2fs, where fs is the sampling frequency in hertz. The first half
of the coefficients, 0 through (N-1)/2, are stored in the filter_coeffs(MAX)
array.
  To reduce stopband ripple, a Hamming window (window_type=SNGL) is applied
as weighted factors to the filter coefficients. By applying the window
a second time (window_type=DUAL), the stopband attenuation substantially
improved at the price of broadening the transition region.
  All filter types and filter lengths above 15 exhibit excellent passband
ripple of less than 0.1 dB with respect to unity gain. The low-pass
characteristics illustrate both the broadening of the transition region
and deep stopband attenuation.
  The FIR filter gain H(f) can be calculated as follows:

                      (N-3)/2
H(f) = h[(N-1)/2] + 2   sum   h(i) cos[2 pi ((N-1)/2-i) f]
                        i=0

for f=0 to 0.5 Hz

  The f1 and f2 definitions (normalized) are:
Low-pass filter             : f1=0; f2=cut-off frequency
High-pass filter            : f1=pass frequency; f2=0.5
Bandpass/band-reject filter : f1=f_low; f2=f_high
  At the pass frequencies, the gain is down 6 dB. A frequency offset (plus
or minus) should be applied for other values of gain.
*/


#include <math.h>

#define	MAXLEN	127			//maximum filter length
#define	MAX	((MAXLEN+1)/2)
#define	PI	(4.0*atan(1.0))		//define pi constant
#define	LPF	1
#define	HPF	2
#define	BPF	3
#define	BRF	4
#define	SNGL	1			//Hamming window
#define	DUAL	2			//Hamming window squared

void calc_coeffs( int filter_type, int filter_len, int window_type,
		double f1, double f2, double *filter_coeffs)
// Calculates FIR filter coefficients for the four filter types:
// Low Pass LPF, High Pass HPF, Band Pass BPF, and Band Reject BRF.
// The coefficients are stored in the filter_coeffs array.
{
	int i, flag=0;
	double ham_coeffs[MAX], A, B, C, F1, F2;

	//Clear filter_coeffs array
	for (i=0; i<MAX; i++)
		filter_coeffs[i]=0.0;

	//Calculate Hamming Window Coefficients
	for (i=0; i<=(filter_len-1)/2; i++)
	{
		double arg;
		arg=2.0*PI/(filter_len-1);
		ham_coeffs[i]= 0.54-0.46*cos(arg*i);
		if (window_type==DUAL)
			ham_coeffs[i]*=ham_coeffs[i];
	}

	//Calculate filter coefficients and pass through window
	if (filter_type==BRF)
	{
		F1=0.0;
		F2=f1;
	}
	else
	{
		F1=f1;
		F2=f2;
	}
	for(;;)
	{
		for (i=0; i<(filter_len-1)/2;i++)
		{
			A=sin(2.0 * PI * ((filter_len-1)/2-i) * F1);
			B=sin(2.0 * PI * ((filter_len-1)/2-i) * F2);
			C=PI * ((filter_len-1)/2-i);
			filter_coeffs[i] += ((B-A)/C) * ham_coeffs[i];
		}
		if ((filter_type==BRF) && (!flag))
		{
			flag=1;
			F1=f2;
			F2=0.5;
		}
		else
			break;
	}
	// Calculate DC component value of coefficients
	if (filter_type==LPF)
		filter_coeffs[i]=2.0 * f2;
	if (filter_type==HPF)
		filter_coeffs[i]=2.0 * (0.5-f1);
	if (filter_type==BPF)
		filter_coeffs[i]=2.0 * (f2-f1);
	if (filter_type==BRF)
		filter_coeffs[i]=1.0 - 2.0 * (f2-f1);
}
