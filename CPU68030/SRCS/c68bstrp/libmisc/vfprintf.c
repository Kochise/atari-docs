#include <lib.h>
#include <stdarg.h>
#include <stdio.h>

int vfprintf(file, fmt, args)
FILE *file;
_CONST char *fmt;
va_list args;
{
    _doprintf(file, fmt, args);
    if (testflag(file, PERPRINTF)) fflush(file);
    return 0;  /* WRONG, but a right way requires _doprintf to return the length output */
}
