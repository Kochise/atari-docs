#include	<stdio.h>
#include	<math.h>
#include	<float.h>
#include	"flonum.h"

	union double_di _dd;

main()	{
	_dd.d = DBL_MAX;
	printf(" %lx %lx\n",_dd.i[0],_dd.i[1] );
	_dd.d = log(-1.0);
	printf(" %lx %lx\n",_dd.i[0],_dd.i[1] );
	printf("%g\n",log( 1.0));
	printf("%g\n",log( 0.0));
	printf("%g\n",log(-1.0));
	printf("%g\n",log( 0.0));
	printf("%g\n",log(-1.0));
	printf("%g\n",5000.);	
	_dd.d = DBL_MAX;
	printf(" %lx %lx\n",_dd.i[0],_dd.i[1] );
	printf("%g\n",DBL_MAX);	
}
