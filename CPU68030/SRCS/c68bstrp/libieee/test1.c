

long test(void)
{
	double d;
	long r ;

	struct {
		int s:16;
		unsigned int u:16;
	} b;

	d = 1.2;

	b.s = 10;	 b.s *= d;
	r = b.s ;
	return r ;
}
