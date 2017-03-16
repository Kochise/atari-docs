#! /bin/sh
/bin/time ./c2c -v -s <c2c.dat >c2c.out 2>&1
/bin/time ./cc2c -v -s <cc2c.dat >cc2c.out 2>&1
/bin/time ./c2d -v -s <c2d.dat >c2d.out 2>&1
/bin/time ./d2d -v -s <d2d.dat >d2d.out 2>&1
/bin/time ./dd2d -v -s <dd2d.dat >dd2d.out 2>&1
