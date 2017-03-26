/*
 * 68kdb: 680X0 Debugger
 * Bart Trzynadlowski
 */

/*
 * 68kdb.c: Main module
 */

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include "debug.h"

#define VERSION "0.6"

#if DEBUG_TYPE == 68000
    #define TURBO68KCONTEXT turbo68kcontext_68000
#else
    #define TURBO68KCONTEXT turbo68kcontext_68010
#endif

TURBO68K_UINT8  *mem;   /* address space */

struct TURBO68K_FETCHREGION fetch_68k[] =
{
    { 0x000000, 0x000000,   TURBO68K_NULL },
    { -1,       -1,         TURBO68K_NULL }
};

struct TURBO68K_DATAREGION  read_68k[] =
{
    { 0x000000, 0x000000,   TURBO68K_NULL,  TURBO68K_NULL },
    { -1,       -1,         TURBO68K_NULL,  TURBO68K_NULL }
};

struct TURBO68K_DATAREGION  write_68k[] =
{
    { 0x000000, 0x000000,   TURBO68K_NULL,  TURBO68K_NULL },
    { -1,       -1,         TURBO68K_NULL,  TURBO68K_NULL }
};


/*****************************************************************************
* Utility functions                                                         */

void Error(char *input, ...)
{
    va_list arg;
    char    text[256];

    va_start(arg, input);
    vsprintf(text, input, arg);
    va_end(arg);
    fprintf(stderr, "68kdb: %s", text);
    exit(1);
}

void Warning(char *input, ...)
{
    va_list arg;
    char    text[256];

    va_start(arg, input);
    vsprintf(text, input, arg);
    va_end(arg);
    fprintf(stderr, "68kdb: Warning: %s", text);
}

int FindV(char *option, int p, int h, int u, int argc, char **argv, int m)
{
    static int  t[128] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                         };
    TURBO68K_INT32  i;
    char            *c;
          
    if (m)  /* mark as touched */
    {
        if (m < 128)
            t[m] = 1;
        return 0;
    }
    if (argc > 128)
        argc = 128;     /* maximum this function can handle is 128 */

    if (u)  /* find first untouched element */
    {
        for (i = 1; i < argc; i++)
        {
            if (!t[i])      /* 0 indicates untouched */
                return i;
        }
        return 0;
    }

    if (p)  /* find option and return integer value following it */
    {
        for (i = 1; i < argc; i++)
        {        
            if (strcmp(argv[i], option) == 0)       /* found */
            {
                if (i >= (argc - 1))        /* bounds! */
                    return 0;
                t[i + 1] = t[i] = 1;        /* touched */
                if (!h)
                    return atoi(argv[i + 1]);
                else
                    return strtoul(argv[i + 1], &c, 16);
            }
        }
        return 0;                       /* no match */
    }
    else    /* find option and return position  */    
    {
        for (i = 1; i < argc; i++)
        {        
            if (strcmp(argv[i], option) == 0)
            {
                t[i] = 1;
                return i;       /* found! return position */
            }
        }                              
        return 0;
    }
    return 0;
}

void SwapMemory(TURBO68K_UINT8 *buffer, TURBO68K_UINT32 length)
{
    TURBO68K_INT32  i, j;

    /* swap bytes in each word */
    for (i = 0; i < length; i += 2)
    {
        j = buffer[i];
        buffer[i] = buffer[i + 1];
        buffer[i + 1] = j;
    }
}


/*****************************************************************************
* main() and Friends                                                        */

void IntAck(TURBO68K_UINT32 vector)
{
    printf("Interrupt acknowledged (vector = 0x%02X)\n", vector);
}

void InitContext(TURBO68K_UINT32 size)
{
    fetch_68k[0].limit = read_68k[0].limit = write_68k[0].limit = size - 1;
    fetch_68k[0].ptr = (TURBO68K_UINT32) mem;
    read_68k[0].ptr = write_68k[0].ptr = (TURBO68K_UINT32) mem;

    Turbo68KSetFetch(fetch_68k, TURBO68K_SUPERVISOR);
    Turbo68KSetReadByte(read_68k, TURBO68K_SUPERVISOR);
    Turbo68KSetReadWord(read_68k, TURBO68K_SUPERVISOR);
    Turbo68KSetReadLong(read_68k, TURBO68K_SUPERVISOR);
    Turbo68KSetWriteByte(write_68k, TURBO68K_SUPERVISOR);
    Turbo68KSetWriteWord(write_68k, TURBO68K_SUPERVISOR);
    Turbo68KSetWriteLong(write_68k, TURBO68K_SUPERVISOR);

    Turbo68KSetFetch(fetch_68k, TURBO68K_USER);
    Turbo68KSetReadByte(read_68k, TURBO68K_USER);
    Turbo68KSetReadWord(read_68k, TURBO68K_USER);
    Turbo68KSetReadLong(read_68k, TURBO68K_USER);
    Turbo68KSetWriteByte(write_68k, TURBO68K_USER);
    Turbo68KSetWriteWord(write_68k, TURBO68K_USER);
    Turbo68KSetWriteLong(write_68k, TURBO68K_USER);

    TURBO68KCONTEXT.InterruptAcknowledge = &IntAck;
    TURBO68KCONTEXT.Reset = TURBO68K_NULL;
#if DEBUG_TYPE != 68000 /* must be 68010! */
    TURBO68KCONTEXT.Bkpt = TURBO68K_NULL;
#endif
}

int main(int argc, char **argv)
{
    FILE            *fp;
    TURBO68K_UINT32 i, j, a, f_size;

    if (argc <= 1 || FindV("-?", 0, 0, 0, argc, argv, 0) || FindV("-h", 0, 0, 0, argc, argv, 0))
    {
        printf("68kdb Version "VERSION" by Bart Trzynadlowski: 680X0 Debugger\n");
        printf("Usage:      68kdb <file> [options]\n");
        printf("Options:    -?,-h   Show this help text\n");
        printf("            -a #    Allocate # bytes of RAM for address space (hexadecimal)\n");
        exit(0);
    }

    a = FindV("-a", 1, 1, 0, argc, argv, 0);
    i = FindV(NULL, 0, 0, 1, argc, argv, 0);
    if (!i) Error("No input file specified\n");
    else
    {
        if ((fp = fopen(argv[i], "rb")) == NULL)
            Error("Failed to open input file: %s\n", argv[i]);
    }
    fseek(fp, 0, SEEK_END);
    fgetpos(fp, (void *) &j);
    if (j < 2)      /* must be at least 2 bytes */
        Error("File is too small (%d bytes), 2 bytes is the minimum\n", j);
    if (j & 1)      /* must be even */
    {
        Warning("File size is odd (%d bytes), padding out to %d bytes\n", j, j + 1);
        j++;
    }
    if (!a) a = j;  /* no allocation amount specified, set to file size */
    if (j > a)      /* make memory size the size of the file */
    {
        a = j;
        Warning("Allocated memory is too small, resizing to 0x%X bytes\n", a);
    }
    if (a & 1)      /* must be even */
    {
        Warning("Memory size is odd (%d bytes), padding out to %d bytes\n", a, a + 1);
        a++;
    }
    rewind(fp);
    if ((mem = (TURBO68K_UINT8 *) calloc(a, sizeof(unsigned char))) == NULL)
        Error("Failed to allocate 0x%X bytes of memory\n", a);
    fread(mem, sizeof(unsigned char), j, fp);
    f_size = j;
    fclose(fp);

    /*
     * Set up Turbo68K
     */
    
    Turbo68KInit();
    SwapMemory(mem, a);
    InitContext(a);
    if (Turbo68KReset() != TURBO68K_OKAY)
        Warning("Failed to reset 68K. PC (and possibly SP) is invalid\n");

    printf("68kdb Version "VERSION": %s loaded\n", argv[i]);
    printf("Type ? for usage help, q to quit\n");

    Debug680X0(NULL, NULL, NULL);

    free(mem);
    return 0;
}
