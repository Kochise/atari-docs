/*
 * bftest.c  : bit field test
 *
 *
 *
 */ 

#include <stdio.h>
#include <stdlib.h>

void test1(void)
{
  struct B {
    int a1 : 8 ;
    int a2 : 8 ;
    int a3 : 8 ;
    int a4 : 8 ;
  } b ;

  /* clear it */
  *(long *)&b = 0 ;

  b.a1 = 1 ;
  printf("a1=%d;\ta2=%d;\ta3=%d;\ta4=%d;\n",b.a1,b.a2,b.a3,b.a4);
  b.a2 = 2 ;
  printf("a1=%d;\ta2=%d;\ta3=%d;\ta4=%d;\n",b.a1,b.a2,b.a3,b.a4);
  b.a3 = 3 ;
  printf("a1=%d;\ta2=%d;\ta3=%d;\ta4=%d;\n",b.a1,b.a2,b.a3,b.a4);
  b.a4 = 4 ;
  printf("a1=%d;\ta2=%d;\ta3=%d;\ta4=%d;\n",b.a1,b.a2,b.a3,b.a4);
}

void test2(void)
{
  struct B {
    int a1 : 16 ;
    unsigned int a2 : 16 ;
  } b ;
  int k = 3 ;

  /* clear it */
  *(long *)&b = 0 ;

  b.a1 = 1 ;
  printf("a1=%d;\ta2=%d;\n",b.a1,b.a2);
  b.a2 = 2 ;
  printf("a1=%d;\ta2=%d;\n",b.a1,b.a2);
  b.a1 *= k ;
  printf("a1=%d;\ta2=%d;\n",b.a1,b.a2);
  b.a2 *= k ;
  printf("a1=%d;\ta2=%d;\n",b.a1,b.a2);
}

main()
{
  test1();
  test2();
}
