/*
 * 68kdb: 680X0 Debugger
 * Bart Trzynadlowski
 */

/*
 * debug.h: Debugger header
 */

#include <stdio.h>


/*****************************************************************************
* Configuration                                                             */

#include "turbo68k.h"       /* include the Turbo68K header */
#define DEBUG_TYPE  68000   /* 68000 or 68010 */
/* #define DEBUG_CONIO */   /* define this for kbhit() support under DOS */


/*****************************************************************************
* Functions                                                                 */

TURBO68K_INT32  Debug680X0(void (*)(const char *, ...),
                           void (*)(char *, int, FILE *),
                           void (*)(TURBO68K_INT32));
TURBO68K_UINT32 Dis680X0One(TURBO68K_UINT32, TURBO68K_UINT8 *, char *, char *,
                            char *);

