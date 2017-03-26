/*
 * 68kdb: 680X0 Debugger
 * Bart Trzynadlowski
 */

/*
 * debug.c: Debugger module
 */


#include "debug.h"
#ifdef DEBUG_CONIO
    #include <conio.h>
#endif
#include <ctype.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if DEBUG_TYPE == 68000
    #define TURBO68KCONTEXT turbo68kcontext_68000
#else
    #define TURBO68KCONTEXT turbo68kcontext_68010
#endif

#define WATCH_NUM   16          /* maximum number of watches */

void (*_printf)(const char *, ...);
void (*_fgets)(char *, int, FILE *);

char                dis_op[64], dis_inst[256], dis_arg[2];
char                *tmp;           /* used by strtoul() */
TURBO68K_UINT32     data_pos = 0;   /* disassembly and dump position */
char                *watch[WATCH_NUM] = { NULL };


/*****************************************************************************
* Watch Processing                                                          */

TURBO68K_INT32 InvalidWatch(TURBO68K_INT32 num)
{
    free(watch[num]);
    watch[num] = NULL;
    _printf("Warning: Watch #%d is invalid and has been removed\n", num);
    return 0;
}

TURBO68K_INT32 GetWatchData(char *e, TURBO68K_UINT32 *var)
{   /* 0=success, 1=error */
    TURBO68K_INT32  size = -1;  /* 0=byte, 1=word, 2=long-word */
    TURBO68K_INT32  i;
    TURBO68K_UINT32 data;

    switch (e[0])   /* type of data */
    {
    case 'r':   /* register */
        switch (e[1])   /* reg size */
        {
        case 'b':   size = 0; break;
        case 'w':   size = 1; break;
        case 'l':   size = 2; break;
        default:    return 1;   /* unknown size */
        }
        if (e[2] == 'a' || e[2] == 'd') /* A0-A7 or D0-D7 */
        {
            i = strtoul(&e[3], &tmp, 10);
            if (i > 7)
                return 1;
            if (e[2] == 'a')    data = TURBO68KCONTEXT.a[i];
            if (e[2] == 'd')    data = TURBO68KCONTEXT.d[i];
        }
        else if (!strcmp(&e[2], "pc"))  /* PC */
            data = Turbo68KReadPC();
        else if (!strcmp(&e[2], "sr"))  /* SR */
            data = TURBO68KCONTEXT.sr;
        else if (!strcmp(&e[2], "ccr")) /* CCR */
            data = TURBO68KCONTEXT.sr & 0x1f;
#if DEBUG_TYPE == 68010
        else if (!strcmp(&e[2], "vbr")) /* VBR */
            data = TURBO68KCONTEXT.vbr;
        else if (!strcmp(&e[2], "sfc")) /* SFC */
            data = TURBO68KCONTEXT.fc & 7;
        else if (!strcmp(&e[2], "dfc")) /* DFC */
            data = (TURBO68KCONTEXT.fc >> 8) & 7;
#endif
        else
            return 1;
        break;
    case '@':   /* indirect */
        switch (e[1])   /* reg size */
        {
        case 'b':   size = 0; break;
        case 'w':   size = 1; break;
        case 'l':   size = 2; break;
        case '#':   /* immediate address */
            i = strtoul(&e[2], &tmp, 16);
            data = Turbo68KReadByte(i);
            *var = data;
            return 0;
        default:    return 1;   /* unknown size */
        }
        if (e[2] == 'a' || e[2] == 'd') /* A0-A7 or D0-D7 */
        {
            i = strtoul(&e[3], &tmp, 10);
            if (i > 7)
                return 1;
            if (e[2] == 'a')    i = TURBO68KCONTEXT.a[i];
            if (e[2] == 'd')    i = TURBO68KCONTEXT.d[i];
        }
        else if (!strcmp(&e[2], "pc"))  /* PC */
            i = Turbo68KReadPC();
#if DEBUG_TYPE == 68010
        else if (!strcmp(&e[2], "vbr")) /* VBR */
            i = TURBO68KCONTEXT.vbr;
#endif
        else
            return 1;
        switch (size)
        {
        case 0: data = Turbo68KReadByte(i); break;
        case 1: data = Turbo68KReadWord(i); break;
        case 2: data = Turbo68KReadLong(i); break;
        }
        break;
    case '#':   /* immediate data */
        data = strtoul(&e[1], &tmp, 16);
        size = 2;   /* long-word size */
        break;        
    default:    /* unknown */
        return 1;
    }

    switch (size)
    {
    case 0: data &= 0xff; break;
    case 1: data &= 0xffff; break;
    case 2: break;
    }
    *var = data;
    return 0;
}
 
TURBO68K_INT32 ProcessWatch(TURBO68K_INT32 num) /* 0=error, 1=success */
{
    TURBO68K_INT32  t = 0;  /* t = 1 if true, 0 if false */
    TURBO68K_UINT32 p, s;
    char            tmp[256], *primary, *condition, *secondary;

    if (watch[num] == NULL)
        return 0;
    memset(tmp, '\0', 256);
    strncpy(tmp, watch[num], 255);
    primary = strtok(tmp, ":");
    condition = strtok(NULL, ":");
    secondary = strtok(NULL, ":");
    if (primary == NULL || condition == NULL || secondary == NULL)
        return InvalidWatch(num);

    if (GetWatchData(primary, &p) || GetWatchData(secondary, &s))
        return InvalidWatch(num);

    /* process condition */
    if (!strcmp(condition, "="))
        { if (p == s)   t = 1; }
    else if (!strcmp(condition, ">"))
        { if (p > s)    t = 1; }
    else if (!strcmp(condition, "<"))
        { if (p < s)    t = 1; }
    else if (!strcmp(condition, ">="))
        { if (p >= s)   t = 1; }
    else if (!strcmp(condition, "<="))
        { if (p <= s)   t = 1; }
    else if (!strcmp(condition, "!="))
        { if (p != s)   t = 1; }
    else if (!strcmp(condition, "1"))
        t = 1;
    else if (!strcmp(condition, "0"))
        t = 0;
    else    /* unknown condition */
        return InvalidWatch(num);

    return t;   /* return truth status */
}

TURBO68K_INT32 CheckWatches()
{
    TURBO68K_INT32  i, j, k;

    for (i = k = 0; i < WATCH_NUM; i++)
    {
        j = ProcessWatch(i);
        k |= j;
        if (j)
            _printf("Watch #%d evaluated true: %s\n", i, watch[i]);
    }

    return k;
}
    
void Watch(char **cmnd)
{
    TURBO68K_INT32  i, j;

    if (cmnd[1] == NULL)
    {
        for (i = j = 0; i < WATCH_NUM; i++)
        {
            if (watch[i] != NULL)
            {
                _printf("Watch #%d: %s\n", i, watch[i]);
                j = 1;
            }
        }
        if (!j)
            _printf("No watches active\n");
    }
    else
    {
        if (strcmp(cmnd[1], "+") && strcmp(cmnd[1], "-"))
        {
            _printf("Error: Unknown watch operation, use + or - only\n");
            return;
        }
        if (!strcmp(cmnd[1], "+"))  /* add a watch expression */
        {
            if (cmnd[2] == NULL)
            {
                _printf("Error: No watch expression specified\n");
                return;
            }
            for (i = j = 0; i < WATCH_NUM; i++)
            {
                if (watch[i] == NULL)
                {
                    if ((watch[i] = calloc(strlen(cmnd[2]) + 1, sizeof(char))) == NULL)                    
                        _printf("Error: Not enough memory to add watch\n");
                    else
                    {
                        strcpy(watch[i], cmnd[2]);
                        _printf("Watch #%d: %s\n", i, cmnd[2]);
                    }
                    j = 1;
                    break;
                }
            }
            if (!j)
                _printf("Error: Watch list full\n");
        }
        else                        /* subtract a watch expression */
        {
            if (cmnd[2][0] == '*')  /* remove all watches */
            {
                for (i = 0; i < WATCH_NUM; i++)
                {
                    if (watch[i] != NULL)
                    {
                        free(watch[i]);
                        watch[i] = NULL;
                    }
                }
                _printf("All watches removed\n");
                return;
            }                    
            i = strtoul(cmnd[2], &tmp, 16);
            if (i >= WATCH_NUM)
                _printf("Error: Invalid watch number\n");
            else
            {
                if (watch[i] != NULL)
                {
                    free(watch[i]);
                    watch[i] = NULL;
                    _printf("Watch #%d removed\n", i);
                }
                else
                    _printf("Watch #%d is already free\n", i);
            }
        }
    }
}


/*****************************************************************************
* Register Command                                                          */

void RegisterDisplay()
{
    _printf("D0=0x%08X D4=0x%08X A0=0x%08X A4=0x%08X SSP=0x%08X\n", TURBO68KCONTEXT.d[0], TURBO68KCONTEXT.d[4], TURBO68KCONTEXT.a[0], TURBO68KCONTEXT.a[4], (TURBO68KCONTEXT.sr & 0x2000) ? TURBO68KCONTEXT.a[7] : TURBO68KCONTEXT.sp);
    _printf("D1=0x%08X D5=0x%08X A1=0x%08X A5=0x%08X USP=0x%08X\n", TURBO68KCONTEXT.d[1], TURBO68KCONTEXT.d[5], TURBO68KCONTEXT.a[1], TURBO68KCONTEXT.a[5], (TURBO68KCONTEXT.sr & 0x2000) ? TURBO68KCONTEXT.sp : TURBO68KCONTEXT.a[7]);
    _printf("D2=0x%08X D6=0x%08X A2=0x%08X A6=0x%08X  SR=0x%04X\n", TURBO68KCONTEXT.d[2], TURBO68KCONTEXT.d[6], TURBO68KCONTEXT.a[2], TURBO68KCONTEXT.a[6], TURBO68KCONTEXT.sr);
    _printf("D3=0x%08X D7=0x%08X A3=0x%08X A7=0x%08X CCR=[",    TURBO68KCONTEXT.d[3], TURBO68KCONTEXT.d[7], TURBO68KCONTEXT.a[3], TURBO68KCONTEXT.a[7]);
    /* CCR = ...XNZVC */
    if (TURBO68KCONTEXT.sr & 0x10) _printf("X"); else _printf("-");
    if (TURBO68KCONTEXT.sr & 0x08) _printf("N"); else _printf("-");
    if (TURBO68KCONTEXT.sr & 0x04) _printf("Z"); else _printf("-");
    if (TURBO68KCONTEXT.sr & 0x02) _printf("V"); else _printf("-");
    if (TURBO68KCONTEXT.sr & 0x01) _printf("C]\n"); else _printf("-]\n");
#if DEBUG_TYPE == 68010
    if (TURBO68KCONTEXT.sr & 0x2000)
    {
        _printf("PC=0x%08X SFC/DFC=%d/%d  VBR=0x%08X   ", Turbo68KReadPC(), TURBO68KCONTEXT.fc & 7, (TURBO68KCONTEXT.fc >> 8) & 7, TURBO68KCONTEXT.vbr);
        if (TURBO68KCONTEXT.status & 2)
            _printf("< STOPPED > ");
        else
            _printf("            ");
        _printf("< SUPERVISOR >\n");
    }
    else
    {
        _printf("PC=0x%08X SFC/DFC=%d/%d  VBR=0x%08X   ", Turbo68KReadPC(), TURBO68KCONTEXT.fc & 7, (TURBO68KCONTEXT.fc >> 8) & 7, TURBO68KCONTEXT.vbr);
        if (TURBO68KCONTEXT.status & 2)
            _printf("< STOPPED > ");
        else
            _printf("            ");
        _printf("< USER >\n");
    }
#else
    if (TURBO68KCONTEXT.sr & 0x2000)
    {
        _printf("PC=0x%08X                               ", Turbo68KReadPC());
        if (TURBO68KCONTEXT.status & 2)
            _printf("< STOPPED > ");
        else
            _printf("            ");
        _printf("< SUPERVISOR >\n");
    }
    else
    {
        _printf("PC=0x%08X                               ", Turbo68KReadPC());
        if (TURBO68KCONTEXT.status & 2)
            _printf("< STOPPED > ");
        else
            _printf("            ");
        _printf("< USER >\n");
    }
#endif
    if ((int) Turbo68KFetchPtr(Turbo68KReadPC()) == 0)
        _printf("Warning: PC is out of bounds (0x%08X). Try allocating more memory\n", Turbo68KReadPC());
    else
    {
        Dis680X0One(Turbo68KReadPC(), Turbo68KFetchPtr(Turbo68KReadPC()), dis_op, dis_inst, dis_arg);
        _printf("0x%08X: %s %s\n", Turbo68KReadPC(), dis_op, dis_inst);
    }
    data_pos = Turbo68KReadPC();   /* reset disassembler position */
}

void Register(char **cmnd)
{
    TURBO68K_UINT32 i;

    if (cmnd[1] == NULL)
        RegisterDisplay();
    else
    {
        if (!strcmp(cmnd[1], "pc"))
        {
            if (cmnd[2] != NULL)    
                TURBO68KCONTEXT.pc = strtoul(cmnd[2], &tmp, 16);
            _printf("PC=0x%08X\n", Turbo68KReadPC());
            data_pos = Turbo68KReadPC();   /* reset disassembler position */
        }
        else if (!strcmp(cmnd[1], "usp"))
        {
            if (cmnd[2] != NULL)    
            {
                if (TURBO68KCONTEXT.sr & 0x2000)
                    TURBO68KCONTEXT.sp = strtoul(cmnd[2], &tmp, 16);
                else
                    TURBO68KCONTEXT.a[7] = strtoul(cmnd[2], &tmp, 16);
            }
            if (TURBO68KCONTEXT.sr & 0x2000)
                _printf("USP=0x%08X\n", TURBO68KCONTEXT.sp);
            else
                _printf("USP=0x%08X\n", TURBO68KCONTEXT.a[7]);
        }
        else if (!strcmp(cmnd[1], "ssp"))
        {
            if (cmnd[2] != NULL)    
            {
                if (TURBO68KCONTEXT.sr & 0x2000)
                    TURBO68KCONTEXT.a[7] = strtoul(cmnd[2], &tmp, 16);
                else
                    TURBO68KCONTEXT.sp = strtoul(cmnd[2], &tmp, 16);
            }
            if (TURBO68KCONTEXT.sr & 0x2000)
                _printf("SSP=0x%08X\n", TURBO68KCONTEXT.a[7]);
            else
                _printf("SSP=0x%08X\n", TURBO68KCONTEXT.sp);
        }
        else if (!strcmp(cmnd[1], "sr"))
        {
            if (cmnd[2] != NULL)    
            {
                i = TURBO68KCONTEXT.sr; /* save old SR */
                TURBO68KCONTEXT.sr = strtoul(cmnd[2], &tmp, 16);
                if ((i & 0x2000) != (TURBO68KCONTEXT.sr & 0x2000))
                {   /* privilege changed, so swap SP */
                    i = TURBO68KCONTEXT.sp;
                    TURBO68KCONTEXT.sp = TURBO68KCONTEXT.a[7];
                    TURBO68KCONTEXT.a[7] = i;
                }               
            }
            _printf("SR=0x%04X\n", TURBO68KCONTEXT.sr);
        }
        else if (!strcmp(cmnd[1], "ccr"))
        {
            if (cmnd[2] != NULL)    
            {
                TURBO68KCONTEXT.sr &= ~0x1f;
                TURBO68KCONTEXT.sr |= strtoul(cmnd[2], &tmp, 16) & 0x1f;
            }
            /* CCR = ...XNZVC */
            _printf("CCR=[");
            if (TURBO68KCONTEXT.sr & 0x10) _printf("X"); else _printf("-");
            if (TURBO68KCONTEXT.sr & 0x08) _printf("N"); else _printf("-");
            if (TURBO68KCONTEXT.sr & 0x04) _printf("Z"); else _printf("-");
            if (TURBO68KCONTEXT.sr & 0x02) _printf("V"); else _printf("-");
            if (TURBO68KCONTEXT.sr & 0x01) _printf("C]\n"); else _printf("-]\n");
        }
#if DEBUG_TYPE == 68010
        else if (!strcmp(cmnd[1], "vbr"))
        {
            if (cmnd[2] != NULL)    
                TURBO68KCONTEXT.vbr = strtoul(cmnd[2], &tmp, 16);
            _printf("VBR=0x%08X\n", TURBO68KCONTEXT.vbr);
        }
        else if (!strcmp(cmnd[1], "sfc"))
        {
            if (cmnd[2] != NULL)    
            {
                TURBO68KCONTEXT.fc &= ~7;
                TURBO68KCONTEXT.fc |= (strtoul(cmnd[2], &tmp, 16) & 7);
            }
            _printf("SFC=0x%08X\n", TURBO68KCONTEXT.fc & 7);
        }
        else if (!strcmp(cmnd[1], "dfc"))
        {
            if (cmnd[2] != NULL)    
            {
                TURBO68KCONTEXT.fc &= ~0x700;
                TURBO68KCONTEXT.fc |= ((strtoul(cmnd[2], &tmp, 16) & 7) << 8);
            }
            _printf("DFC=0x%08X\n", (TURBO68KCONTEXT.fc >> 8) & 7);
        }
#endif
        else if (cmnd[1][0] == 'd')
        {
            sscanf(cmnd[1], "d%d", &i);
            if (i > 7)
            {
                _printf("Error: No such register: D%d\n", i);
                return;
            }
            if (cmnd[1][1] == '\0')
            {
                _printf("Error: No such register: D\n");
                return;
            }
            if (cmnd[2] != NULL)
                TURBO68KCONTEXT.d[i] = strtoul(cmnd[2], &tmp, 16);
            _printf("D%d=0x%08X\n", i, TURBO68KCONTEXT.d[i]);
        }
        else if (cmnd[1][0] == 'a')
        {
            sscanf(cmnd[1], "a%d", &i);
            if (i > 7)
            {
                _printf("Error: No such register: A%d\n", i);
                return;
            }
            if (cmnd[1][1] == '\0')
            {
                _printf("Error: No such register: A\n");
                return;
            }
            if (cmnd[2] != NULL)
                TURBO68KCONTEXT.a[i] = strtoul(cmnd[2], &tmp, 16);
            _printf("A%d=0x%08X\n", i, TURBO68KCONTEXT.a[i]);
        }
        else
            _printf("Error: No such register: %s\n", cmnd[1]);
    }
}

/*****************************************************************************
* Help                                                                      */

void ShowDebuggerHelp()
{
    _printf("Help:\n");
    _printf("All values are in hexadecimal unless specified otherwise\n");
    _printf("?                       Show this help text\n");
    _printf("b <addr>                Execute until breakpoint or watch\n");
    _printf("d [addr] [num]          Dump; number lines = decimal\n");
    _printf("e <cycles>              Execute number of cycles (decimal)\n");
    _printf("i <level> [vector]      Interrupt\n");
    _printf("j <addr>                Jump\n");
    _printf("l <file> [addr]         Load file\n");
    _printf("m <addr> [b/w/l] [data] Memory\n");
    _printf("p [num]                 Switch processor (decimal)\n");
    _printf("q                       Quit\n");
    _printf("r [reg] [data]          Register\n");
    _printf("reset                   Reset 68K\n");
    _printf("s                       Skip instruction\n");
    _printf("t                       Trace (with watch)\n");
    _printf("u [addr] [num]          Unassemble; number = decimal\n");
    _printf("w [+/-] [expr/num]      Watch\n");
}


/*****************************************************************************
* Parsing                                                                   */

TURBO68K_INT32 Process(char *input, char **cmnd)
{
    TURBO68K_INT32  i = 1, j, k = 0;

    cmnd[0] = cmnd[1] = cmnd[2] = cmnd[3] = NULL;

    for (j = 0; j < strlen(input); j++)     /* get rid of newlines */
    {
        if (input[j] == '\n' || input[j] == '\r')
            input[j] = '\0';
        else if (input[j] != ' ' && input[j] != '\t')
            k = 1;
    }
    if (!k || (cmnd[0] = strtok(input, " \t")) == NULL)
        return 1;       /* no command */
    while (i < 4)
    {
        cmnd[i] = strtok(NULL, " \t");
        i++;
    }
    return 0;           /* found a command */
}


/*****************************************************************************
* Debugger                                                                  */

TURBO68K_INT32 Debug680X0(void (*dbg_printf)(const char *, ...),
                          void (*dbg_fgets)(char *, int, FILE *),
                          void (*dbg_switch)(TURBO68K_INT32))
{
    char            input[256];
    TURBO68K_UINT32 i, j, k, l;
    char            *cmnd[4] = { NULL, NULL, NULL, NULL };
    FILE            *fp;

    if (dbg_printf != NULL)
        _printf = dbg_printf;
    else
        _printf = (void (*)(const char *, ...)) printf;
    if (dbg_fgets != NULL)
        _fgets = dbg_fgets;
    else
        _fgets = (void (*)(char *, int, FILE *)) fgets;

    while (1)
    {
        _printf("-");
        _fgets(input, 256, stdin);
        for (i = 0; i < 255; i++)   /* convert to lowercase */
        {
            if (isupper(input[i]))
                input[i] = tolower(input[i]);
        }

        if (Process(input, cmnd))           /* no command... */
            ;
        else if (cmnd[0][0] == 'q')         /* quit */
            break;              
        else if (!strcmp(cmnd[0], "b"))
        {
            if (cmnd[1] == NULL)
                _printf("Error: No breakpoint address specified\n");
            else
            {
                i = strtoul(cmnd[1], &tmp, 16);
                while (1)
                {
                    if ((j = Turbo68KRun(1)) != TURBO68K_OKAY)
                    {
                        switch (j)
                        {
                        case TURBO68K_ERROR_INVINST:
                            _printf("Invalid instruction -- failed to execute\n");
                            break;
                        case TURBO68K_ERROR_FETCH:
                            _printf("PC is out of bounds -- failed to execute\n");
                            break;
                        case TURBO68K_ERROR_STACKFRAME:
                            _printf("Unsupported/invalid stack frame -- failed to execute\n");
                            break;
                        default:
                            _printf("Turbo68KRun() returned an unknown error: %d\n", i);
                            break;
                        }
                        break;
                    }
                    if (CheckWatches())
                    {
                        j = ~TURBO68K_OKAY;   /* not at breakpoint */
                        break;
                    }
                    if (Turbo68KReadPC() == i)
                        break;
#ifdef DEBUG_CONIO
                    if (kbhit())
                    {
                        getch();                /* remove key from buffer */
                        _printf("Terminated by keystroke\n");
                        j = ~TURBO68K_OKAY;   /* not at breakpoint */
                        break;
                    }
#endif
                }
                if (j == TURBO68K_OKAY)
                    _printf("Stopped at breakpoint: 0x%08X\n", i);
                RegisterDisplay();
                data_pos = i;
            }
        }
        else if (!strcmp(cmnd[0], "d"))
        {
            if (!data_pos && cmnd[1] == NULL)
                data_pos = Turbo68KReadPC();
            else if (cmnd[1] != NULL)
                data_pos = strtoul(cmnd[1], &tmp, 16);
            if (cmnd[2] == NULL)
                j = 16;
            else
                j = strtoul(cmnd[2], &tmp, 10);
                
            for (; (j > 0); j--)
            {
                l = data_pos;   /* save start of line */
                _printf("0x%08X:  ", data_pos);
                for (k = 16; (k > 0); k--)
                {
                    _printf("%02X ", Turbo68KReadByte(data_pos));
                    data_pos++;
                }
                data_pos = l;  /* now print as ascii */
                _printf(" ");
                for (; k > 0; k--)  _printf("   ");                
                for (k = 16; (k > 0); k--)
                {
                    if (Turbo68KReadByte(data_pos) == 0 || Turbo68KReadByte(data_pos)  == '\t')
                        _printf(".");
                    else if (isalpha(Turbo68KReadByte(data_pos)) || isdigit(Turbo68KReadByte(data_pos)) || strchr("0123456789`~!@#$%^&*()-=_+[]\{}|;':\",./<>? ", Turbo68KReadByte(data_pos)) != NULL)
                        _printf("%c", Turbo68KReadByte(data_pos));
                    else
                        _printf(".");
                    data_pos++;
                }                    
                _printf("\n");
            }
        }
        else if (!strcmp(cmnd[0], "e"))     /* execute */
        {
            if (cmnd[1] == NULL)
                _printf("Error: No cycle amount specified\n");
            else
            {
                if ((i = Turbo68KRun(strtoul(cmnd[1], &tmp, 10))) != TURBO68K_OKAY)
                {
                    switch (i)
                    {
                    case TURBO68K_ERROR_INVINST:
                        _printf("Invalid instruction -- executed %d cycles\n", Turbo68KGetElapsedCycles());
                        break;
                    case TURBO68K_ERROR_FETCH:
                        _printf("PC is out of bounds -- executed %d cycles\n", Turbo68KGetElapsedCycles());
                        break;
                    case TURBO68K_ERROR_STACKFRAME:
                        _printf("Unsupported/invalid stack frame -- failed to execute\n");
                        break;
                    default:
                        _printf("Turbo68KRun() returned an unknown error: %d\n", i);
                        break;
                    }
                }
                if (i == TURBO68K_OKAY)
                    _printf("Executed %d cycles\n", Turbo68KGetElapsedCycles());
                RegisterDisplay();
                data_pos = Turbo68KReadPC();
            }
        }
        else if (!strcmp(cmnd[0], "i"))     /* interrupt */
        {
            if (cmnd[1] == NULL)
                _printf("Error: No level specified\n");
            else
            {
                i = strtoul(cmnd[1], &tmp, 10);
                if (cmnd[2] == NULL)
                    j = TURBO68K_AUTOVECTOR;
                else
                    j = strtoul(cmnd[2], &tmp, 16);
                switch (Turbo68KInterrupt(i, j))
                {
                case TURBO68K_ERROR_INTLEVEL:
                    _printf("Error: Invalid level (use 1-7 only)\n");
                    break;
                case TURBO68K_ERROR_INTVECTOR:
                    _printf("Error: Invalid vector (use 2-FF only)\n");
                    break;
                case TURBO68K_ERROR_INTPENDING:
                    _printf("Error: Interrupt already pending at level %d\n", i);
                    break;
                default:
                    _printf("Interrupt level %d generated\n", i);
                    break;
                }
            }
            Turbo68KProcessInterrupts();
            RegisterDisplay();
        }
        else if (!strcmp(cmnd[0], "j"))     /* jump */
        {
            if (cmnd[1] == NULL)
                _printf("Error: No target address specified\n");
            else
            {
                i = strtoul(cmnd[1], &tmp, 16);
                TURBO68KCONTEXT.pc = i;
                _printf("Jumped to 0x%08X\n", Turbo68KReadPC());
                if ((int) Turbo68KFetchPtr(Turbo68KReadPC()) == 0)
                    _printf("Warning: PC is out of bounds (0x%08X)\n", Turbo68KReadPC());
                else
                {
                    Dis680X0One(Turbo68KReadPC(), Turbo68KFetchPtr(Turbo68KReadPC()), dis_op, dis_inst, dis_arg);
                    _printf("0x%08X: %s %s\n", Turbo68KReadPC(), dis_op, dis_inst);
                }
            }
        }
        else if (!strcmp(cmnd[0], "l"))     /* load file */
        {
            if (cmnd[1] == NULL)
                _printf("Error: No file specified to load\n");
            else
            {
                if ((fp = fopen(cmnd[1], "rb")) == NULL)
                    _printf("Error: Failed to open file: %s\n", cmnd[1]);
                else
                {
                    if (cmnd[2] == NULL)        /* default loading position = 0 */
                        i = 0;
                    else
                        i = strtoul(cmnd[2], &tmp, 16);
                    fseek(fp, 0, SEEK_END);
                    fgetpos(fp, (void *) &j);          
                    rewind(fp);
                    for (k = 0; k < j; k++)
                    {
                        Turbo68KWriteByte(i, (TURBO68K_UINT8) fgetc(fp));
                        i++;
                    }
                    _printf("Loaded %s: %d bytes at 0x%08X\n", cmnd[1], j, i - k);
                    fclose(fp);
                }
            }
        }
        else if (!strcmp(cmnd[0], "m"))     /* memory */
        {
            if (cmnd[1] == NULL)
                _printf("Error: No address specified\n");
            else
            {
                i = strtoul(cmnd[1], &tmp, 16);
                if (cmnd[2] == NULL)
                    _printf("0x%08X: 0x%02X 0x%02X 0x%02X 0x%02X\n", i, Turbo68KReadByte(i), Turbo68KReadByte(i+1), Turbo68KReadByte(i+2), Turbo68KReadByte(i+3));
                else if (!isalpha(cmnd[2][0]))
                    _printf("Error: No size specified\n");
                else
                {    
                    j = strtoul(cmnd[3], &tmp, 16);
                    if (!strcmp(cmnd[2], "b"))      /* byte */
                    {
                        if (cmnd[3] != NULL)
                            Turbo68KWriteByte(i, j);
                        _printf("0x%08X: 0x%02X\n", i, Turbo68KReadByte(i));
                    }
                    else if (!strcmp(cmnd[2], "w")) /* word */
                    {
                        if (cmnd[3] != NULL)
                            Turbo68KWriteWord(i, j);
                        _printf("0x%08X: 0x%04X\n", i, Turbo68KReadWord(i));
                    }
                    else if (!strcmp(cmnd[2], "l")) /* long */
                    {
                        if (cmnd[3] != NULL)
                            Turbo68KWriteLong(i, j);
                        _printf("0x%08X: 0x%08X\n", i, Turbo68KReadLong(i));
                    }
                    else
                        _printf("Error: Unrecognized size specifier\n");
                }
            }
        }
        else if (!strcmp(cmnd[0], "p"))     /* switch processor */
        {
            if (cmnd[1] != NULL)
                i = strtoul(cmnd[1], &tmp, 10);
            else
                i = 0;
            if (dbg_switch != NULL)
                dbg_switch(i);
            else
                _printf("No other 680X0 processors to switch to\n");
        }
        else if (!strcmp(cmnd[0], "r"))     /* register */
            Register(cmnd);
        else if (!strcmp(cmnd[0], "reset"))     /* reset */
        {
            if (Turbo68KReset() != TURBO68K_OKAY)
                _printf("Error: Failed to reset 68K\n");
            else
                _printf("68K reset\n");
        }
        else if (!strcmp(cmnd[0], "s"))     /* skip */
        {
            _printf("Skipped over instruction at 0x%08X\n", Turbo68KReadPC());
            TURBO68KCONTEXT.pc = Turbo68KReadPC() + Dis680X0One(Turbo68KReadPC(), Turbo68KFetchPtr(Turbo68KReadPC()), dis_op, dis_inst, dis_arg);
            Dis680X0One(Turbo68KReadPC(), Turbo68KFetchPtr(Turbo68KReadPC()), dis_op, dis_inst, dis_arg);
            _printf("0x%08X: %s %s\n", Turbo68KReadPC(), dis_op, dis_inst);
            data_pos = Turbo68KReadPC();
        }
        else if (!strcmp(cmnd[0], "t"))     /* trace */
        {
            if ((i = Turbo68KRun(1)) != TURBO68K_OKAY)
            {
                switch (i)
                {
                case TURBO68K_ERROR_INVINST:
                    _printf("Invalid instruction -- failed to execute\n");
                    break;
                case TURBO68K_ERROR_FETCH:
                    _printf("PC is out of bounds -- failed to execute\n");
                    break;
                 case TURBO68K_ERROR_STACKFRAME:
                     _printf("Unsupported/invalid stack frame -- failed to execute\n");
                     break;
                default:
                    _printf("Turbo68KRun() returned an unknown error: %d\n", i);
                    break;
                }
            }
            CheckWatches();
            RegisterDisplay();
            data_pos = Turbo68KReadPC();
        }
        else if (!strcmp(cmnd[0], "u"))
        {
            if (!data_pos && cmnd[1] == NULL)
                data_pos = Turbo68KReadPC();
            else if (cmnd[1] != NULL)
                data_pos = strtoul(cmnd[1], &tmp, 16);
            if (cmnd[2] == NULL)
                i = 16;
            else
                i = strtoul(cmnd[2], &tmp, 10);
            while (i > 0)
            {
                if ((int) Turbo68KFetchPtr(data_pos) == 0)
                {
                    _printf("Error: Out of bounds (0x%08X)\n", data_pos);
                    break;
                }
                j = Dis680X0One(data_pos, Turbo68KFetchPtr(data_pos), dis_op, dis_inst, dis_arg);
                _printf("0x%08X: %s %s\n", data_pos, dis_op, dis_inst);
                data_pos += j;
                i--;
            }
        }
        else if (!strcmp(cmnd[0], "w"))
            Watch(cmnd);
        else if (!strcmp(cmnd[0], "?"))     /* help */
            ShowDebuggerHelp();
        else
            _printf("Error: Unrecognized command. Type ? for help\n");
    }
    return 0;
}


/*****************************************************************************
* Disassembler                                                              */

/*
 * NOTE: The following code was written by Aaron Giles. It was modified by me
 * (bug fixes, format changes, etc.) for inclusion in the 68kdb project.
 */


/*
 *   A MC68000/MC68010 disassembler
 *
 *   Note: this is probably not the most efficient disassembler in the world :-)
 *
 *   This code written by Aaron Giles (agiles@sirius.com) for the MAME project
 *
 */

typedef int             INT32;
typedef unsigned        UINT32;
typedef unsigned short  UINT16;

static char *ccodes[16] = { "T ", "F ", "HI", "LS", "CC", "CS", "NE", "EQ", "VC", "VS", "PL", "MI", "GE", "LT", "GT", "LE" };

#ifdef LITTLE_ENDIAN
#define	PARAM_WORD(v) ((v) = (UINT16) ((p[0] << 8) | p[1]), p += 2)
#define	PARAM_LONG(v) ((v) = (UINT32) ((p[0] << 24) | (p[1] << 16) | (p[2] << 8) | (p[3])), p += 4)
#else
#define PARAM_WORD(v) ((v) = *(unsigned short *)&p[0], p += 2)
#define PARAM_LONG(v) ((v) = (*(unsigned short *)&p[0] << 16) + *(unsigned short *)&p[2], p += 4)
#endif

static char *MakeEA (int lo, unsigned char *pBase, int size, int *count, int pc)
{
	static char buffer[2][80];
	static int which;

	unsigned char *p = pBase;
	char *buf = buffer[which];
	int reg = lo & 7;
	unsigned long pm;
	int temp;

	which ^= 1;
	switch ((lo >> 3) & 7)
	{
		case 0:
			sprintf (buf, "D%d", reg);
			break;
		case 1:
			sprintf (buf, "A%d", reg);
			break;
		case 2:
			sprintf (buf, "(A%d)", reg);
			break;
		case 3:
			sprintf (buf, "(A%d)+", reg);
			break;
		case 4:
			sprintf (buf, "-(A%d)", reg);
			break;
		case 5:
			PARAM_WORD (pm);
			if (pm & 0x8000)
                                sprintf (buf, "(-0x%X,A%d)", -(signed short)pm & 0xffff, reg);
			else
                                sprintf (buf, "(0x%lX,A%d)", pm, reg);
			break;
		case 6:
			PARAM_WORD (pm);
			temp = pm & 0xff;
			if (temp & 0x80)
                                sprintf (buf, "(-0x%X,A%d,D%ld.%c)", -(signed char)temp & 0xff, reg, (pm >> 12) & 7, (pm & 0x800) ? 'L' : 'W');
			else
                                sprintf (buf, "(0x%X,A%d,D%ld.%c)", temp, reg, (pm >> 12) & 7, (pm & 0x800) ? 'L' : 'W');
			break;
		case 7:
			switch (reg)
			{
				case 0:
					PARAM_WORD (pm);
                                        sprintf (buf, "0x%lX", pm);
					break;
				case 1:
					PARAM_LONG (pm);
                                        sprintf (buf, "0x%lX", pm);
					break;
				case 2:
					PARAM_WORD (pm);
					if (pm & 0x8000)
                                                sprintf (buf, "(-0x%X,PC) [0x%X]", -(signed short)pm & 0xffff, pc + (signed short)pm + 2);
					else
                                                sprintf (buf, "(0x%lX,PC) [0x%lX]", pm, pc + pm + 2);
					break;
				case 3:
					PARAM_WORD (pm);
					temp = pm & 0xff;
					if (temp & 0x80)
                                                sprintf (buf, "(-0x%X,PC,%c%ld.%c)", -(signed char)temp & 0xff, (pm & 0x8000) ? 'A' : 'D',(pm >> 12) & 7, (pm & 0x800) ? 'L' : 'W');
					else
                                                sprintf (buf, "(0x%X,PC,%c%ld.%c)", temp, (pm & 0x8000) ? 'A' : 'D',(pm >> 12) & 7, (pm & 0x800) ? 'L' : 'W');
					break;
				case 4:
					if (size == 1)
					{
						PARAM_WORD (pm);
						temp = pm & 0xff;
                                                sprintf (buf, "#0x%X", temp);
					}
					else if (size == 2)
					{
						PARAM_WORD (pm);
                                                sprintf (buf, "#0x%lX", pm);
					}
					else
					{
						PARAM_LONG (pm);
                                                sprintf (buf, "#0x%lX", pm);
					}
					break;
                default:
                    sprintf(buf, "<???>");
                    break;
			}
            break;
    default:
        sprintf(buf, "<???>");
        break;
	}

	*count = p - pBase;
	return buf;
}

static char *MakeRegList (char *p, unsigned short pm)
{
	int start = -1, sep = 0;
	int i;

	for (i = 0; i < 8; i++, pm >>= 1)
	{
		if ((pm & 1) && start == -1)
			start = i;
		else if (!(pm & 1) && start != -1)
		{
			if (sep++) p += sprintf (p, "/");
			if (start == i - 1) p += sprintf (p, "D%d", start);
			else p += sprintf (p, "D%d-D%d", start, i - 1);
			start = -1;
		}
	}
	if (start != -1)
	{
		if (sep++) p += sprintf (p, "/");
		if (start == 7) p += sprintf (p, "D7");
		else p += sprintf (p, "D%d-D7", start);
		start = -1;
	}

	for (i = 0; i < 8; i++, pm >>= 1)
	{
		if ((pm & 1) && start == -1)
			start = i;
		else if (!(pm & 1) && start != -1)
		{
			if (sep++) p += sprintf (p, "/");
			if (start == i - 1) p += sprintf (p, "A%d", start);
			else p += sprintf (p, "A%d-A%d", start, i - 1);
			start = -1;
		}
	}
	if (start != -1)
	{
		if (sep++) p += sprintf (p, "/");
		if (start == 7) p += sprintf (p, "A7");
		else p += sprintf (p, "A%d-A7", start);
	}

	return p;
}

static char *MakeRevRegList (char *p, unsigned short pm)
{
	int start = -1, sep = 0;
	int i;

	for (i = 0; i < 8; i++, pm <<= 1)
	{
		if ((pm & 0x8000) && start == -1)
			start = i;
		else if (!(pm & 0x8000) && start != -1)
		{
			if (sep++) p += sprintf (p, "/");
			if (start == i - 1) p += sprintf (p, "D%d", start);
			else p += sprintf (p, "D%d-D%d", start, i - 1);
			start = -1;
		}
	}
	if (start != -1)
	{
		if (sep++) p += sprintf (p, "/");
		if (start == 7) p += sprintf (p, "D7");
		else p += sprintf (p, "D%d-D7", start);
		start = -1;
	}

	for (i = 0; i < 8; i++, pm <<= 1)
	{
		if ((pm & 0x8000) && start == -1)
			start = i;
		else if (!(pm & 0x8000) && start != -1)
		{
			if (sep++) p += sprintf (p, "/");
			if (start == i - 1) p += sprintf (p, "A%d", start);
			else p += sprintf (p, "A%d-A%d", start, i - 1);
			start = -1;
		}
	}
	if (start != -1)
	{
		if (sep++) p += sprintf (p, "/");
		if (start == 7) p += sprintf (p, "A7");
		else p += sprintf (p, "A%d-A7", start);
	}

	return p;
}

UINT32 Dis680X0One(UINT32 dwVirtPc, unsigned char *pbOpcode,
                   char *pbOpcodeBytesAsText, char *pbInstruction,
                   char *pbArgument)
{
	INT32 dwVirtualAddress = (INT32) dwVirtPc;
	UINT32 dwLen = 0;
	unsigned char *p = (unsigned char *) pbOpcode;
	char *buffer;
	unsigned short op, lo, rhi, rlo;
	unsigned long pm;
	char *ea, *ea2;
	int count;

	buffer = pbInstruction;
	*pbArgument = '\0';

	PARAM_WORD(op);

	lo = op & 0x3f;
	rhi = (op >> 9) & 7;
	rlo = op & 7;
	switch (op & 0xffc0)
	{
		case 0x0000:
			PARAM_WORD(pm);
			if (lo == 0x3c)
                                sprintf (buffer, "ORI      #0x%lX,CCR", pm & 0xff);
			else
			{
				ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
                                sprintf (buffer, "ORI.B    #0x%lX,%s", pm & 0xff, ea);
			}
			break;
		case 0x0040:
			PARAM_WORD(pm);
			if (lo == 0x3c)
                                sprintf (buffer, "ORI      #0x%lX,SR", pm & 0xffff);
			else
			{
				ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
                                sprintf (buffer, "ORI.W    #0x%lX,%s", pm & 0xffff, ea);
			}
			break;
		case 0x0080:
			PARAM_LONG(pm); ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
                        sprintf (buffer, "ORI.L    #0x%lX,%s", pm, ea);
			break;
		case 0x0100: case 0x0300: case 0x0500: case 0x0700: case 0x0900: case 0x0b00: case 0x0d00: case 0x0f00:
			if ((lo & 0x38) == 0x08)
			{
				PARAM_WORD(pm);
                                sprintf (buffer, "MOVEP.W  (0x%lX,A%d),D%d", pm, rlo, rhi);
			}
			else
			{
				ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
				sprintf (buffer, "BTST     D%d,%s", rhi, ea);
			}
			break;
		case 0x0140: case 0x0340: case 0x0540: case 0x0740: case 0x0940: case 0x0b40: case 0x0d40: case 0x0f40:
			if ((lo & 0x38) == 0x08)
			{
				PARAM_WORD(pm);
                                sprintf (buffer, "MOVEP.L  (0x%lX,A%d),D%d", pm, rlo, rhi);
			}
			else
			{
				ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
				sprintf (buffer, "BCHG     D%d,%s", rhi, ea);
			}
			break;
		case 0x0180: case 0x0380: case 0x0580: case 0x0780: case 0x0980: case 0x0b80: case 0x0d80: case 0x0f80:
			if ((lo & 0x38) == 0x08)
			{
				PARAM_WORD(pm);
                                sprintf (buffer, "MOVEP.W  D%d,(0x%lX,A%d)", rhi, pm, rlo);
			}
			else
			{
				ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
				sprintf (buffer, "BCLR     D%d,%s", rhi, ea);
			}
			break;
		case 0x01c0: case 0x03c0: case 0x05c0: case 0x07c0: case 0x09c0: case 0x0bc0: case 0x0dc0: case 0x0fc0:
			if ((lo & 0x38) == 0x08)
			{
				PARAM_WORD(pm);
                                sprintf (buffer, "MOVEP.L  D%d,(0x%lX,A%d)", rhi, pm, rlo);
			}
			else
			{
				ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
				sprintf (buffer, "BSET     D%d,%s", rhi, ea);
			}
			break;
		case 0x0200:
			PARAM_WORD(pm);
			if (lo == 0x3c)
                                sprintf (buffer, "ANDI     #0x%lX,CCR", pm & 0xff);
			else
			{
				ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
                                sprintf (buffer, "ANDI.B   #0x%lX,%s", pm & 0xff, ea);
			}
			break;
		case 0x0240:
			PARAM_WORD(pm);
			if (lo == 0x3c)
                                sprintf (buffer, "ANDI     #0x%lX,SR", pm & 0xffff);
			else
			{
				ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
                                sprintf (buffer, "ANDI.W   #0x%lX,%s", pm & 0xffff, ea);
			}
			break;
		case 0x0280:
			PARAM_LONG(pm); ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
                        sprintf (buffer, "ANDI.L   #0x%lX,%s", pm, ea);
			break;
		case 0x0400:
			PARAM_WORD(pm); ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
                        sprintf (buffer, "SUBI.B   #0x%lX,%s", pm & 0xff, ea);
			break;
		case 0x0440:
			PARAM_WORD(pm); ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
                        sprintf (buffer, "SUBI.W   #0x%lX,%s", pm & 0xffff, ea);
			break;
		case 0x0480:
			PARAM_LONG(pm); ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
                        sprintf (buffer, "SUBI.L   #0x%lX,%s", pm, ea);
			break;
		case 0x0600:
			PARAM_WORD(pm); ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
                        sprintf (buffer, "ADDI.B   #0x%lX,%s", pm & 0xff, ea);
			break;
		case 0x0640:
			PARAM_WORD(pm); ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
                        sprintf (buffer, "ADDI.W   #0x%lX,%s", pm & 0xffff, ea);
			break;
		case 0x0680:
			PARAM_LONG(pm); ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
                        sprintf (buffer, "ADDI.L   #0x%lX,%s", pm, ea);
			break;
		case 0x0800:
			PARAM_WORD(pm); ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
                        sprintf (buffer, "BTST     #0x%lX,%s", pm & 0xff, ea);
			break;
		case 0x0840:
			PARAM_WORD(pm); ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
                        sprintf (buffer, "BCHG     #0x%lX,%s", pm & 0xff, ea);
			break;
		case 0x0880:
			PARAM_WORD(pm); ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
                        sprintf (buffer, "BCLR     #0x%lX,%s", pm & 0xff, ea);
			break;
		case 0x08c0:
			PARAM_WORD(pm); ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
                        sprintf (buffer, "BSET     #0x%lX,%s", pm & 0xff, ea);
			break;
		case 0x0a00:
			PARAM_WORD(pm);
			if (lo == 0x3c)
                                sprintf (buffer, "EORI     #0x%lX,CCR", pm & 0xff);
			else
			{
				ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
                                sprintf (buffer, "EORI.B   #0x%lX,%s", pm & 0xff, ea);
			}
			break;
		case 0x0a40:
			PARAM_WORD(pm);
			if (lo == 0x3c)
                                sprintf (buffer, "EORI     #0x%lX,SR", pm & 0xffff);
			else
			{
				ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
                                sprintf (buffer, "EORI.W   #0x%lX,%s", pm & 0xffff, ea);
			}
			break;
		case 0x0a80:
			PARAM_LONG(pm); ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
                        sprintf (buffer, "EORI.L   #0x%lX,%s", pm, ea);
			break;
		case 0x0c00:
			PARAM_WORD(pm); ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
                        sprintf (buffer, "CMPI.B   #0x%lX,%s", pm & 0xff, ea);
			break;
		case 0x0c40:
			PARAM_WORD(pm); ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
                        sprintf (buffer, "CMPI.W   #0x%lX,%s", pm & 0xffff, ea);
			break;
		case 0x0c80:
			PARAM_LONG(pm); ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
                        sprintf (buffer, "CMPI.L   #0x%lX,%s", pm, ea);
			break;
		case 0x0e00:
			PARAM_WORD(pm); ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
			if (pm & 0x0800)
			{
				if (pm & 0x8000)
					sprintf (buffer, "MOVES.B  A%ld,%s", (pm >> 12) & 7, ea);
				else
					sprintf (buffer, "MOVES.B  D%ld,%s", (pm >> 12) & 7, ea);
			}
			else
			{
				if (pm & 0x8000)
					sprintf (buffer, "MOVES.B  %s,A%ld", ea, (pm >> 12) & 7);
				else
					sprintf (buffer, "MOVES.B  %s,D%ld", ea, (pm >> 12) & 7);
			}
			break;
		case 0x0e40:
			PARAM_WORD(pm); ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			if (pm & 0x0800)
			{
				if (pm & 0x8000)
					sprintf (buffer, "MOVES.W  A%ld,%s", (pm >> 12) & 7, ea);
				else
					sprintf (buffer, "MOVES.W  D%ld,%s", (pm >> 12) & 7, ea);
			}
			else
			{
				if (pm & 0x8000)
					sprintf (buffer, "MOVES.W  %s,A%ld", ea, (pm >> 12) & 7);
				else
					sprintf (buffer, "MOVES.W  %s,D%ld", ea, (pm >> 12) & 7);
			}
			break;
		case 0x0e80:
			PARAM_WORD(pm); ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			if (pm & 0x0800)
			{
				if (pm & 0x8000)
					sprintf (buffer, "MOVES.L  A%ld,%s", (pm >> 12) & 7, ea);
				else
					sprintf (buffer, "MOVES.L  D%ld,%s", (pm >> 12) & 7, ea);
			}
			else
			{
				if (pm & 0x8000)
					sprintf (buffer, "MOVES.L  %s,A%ld", ea, (pm >> 12) & 7);
				else
					sprintf (buffer, "MOVES.L  %s,D%ld", ea, (pm >> 12) & 7);
			}
			break;
		case 0x1000: case 0x1080: case 0x10c0: case 0x1100: case 0x1140: case 0x1180: case 0x11c0:
		case 0x1200: case 0x1280: case 0x12c0: case 0x1300: case 0x1340: case 0x1380: case 0x13c0:
		case 0x1400: case 0x1480: case 0x14c0: case 0x1500: case 0x1540: case 0x1580:
		case 0x1600: case 0x1680: case 0x16c0: case 0x1700: case 0x1740: case 0x1780:
		case 0x1800: case 0x1880: case 0x18c0: case 0x1900: case 0x1940: case 0x1980:
		case 0x1a00: case 0x1a80: case 0x1ac0: case 0x1b00: case 0x1b40: case 0x1b80:
		case 0x1c00: case 0x1c80: case 0x1cc0: case 0x1d00: case 0x1d40: case 0x1d80:
		case 0x1e00: case 0x1e80: case 0x1ec0: case 0x1f00: case 0x1f40: case 0x1f80:
			ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count; ea2 = MakeEA (((op >> 9) & 0x07) + ((op >> 3) & 0x38), p, 1, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "MOVE.B   %s,%s", ea, ea2);
			break;
		case 0x2000: case 0x2080: case 0x20c0: case 0x2100: case 0x2140: case 0x2180: case 0x21c0:
		case 0x2200: case 0x2280: case 0x22c0: case 0x2300: case 0x2340: case 0x2380: case 0x23c0:
		case 0x2400: case 0x2480: case 0x24c0: case 0x2500: case 0x2540: case 0x2580:
		case 0x2600: case 0x2680: case 0x26c0: case 0x2700: case 0x2740: case 0x2780:
		case 0x2800: case 0x2880: case 0x28c0: case 0x2900: case 0x2940: case 0x2980:
		case 0x2a00: case 0x2a80: case 0x2ac0: case 0x2b00: case 0x2b40: case 0x2b80:
		case 0x2c00: case 0x2c80: case 0x2cc0: case 0x2d00: case 0x2d40: case 0x2d80:
		case 0x2e00: case 0x2e80: case 0x2ec0: case 0x2f00: case 0x2f40: case 0x2f80:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count; ea2 = MakeEA (((op >> 9) & 0x07) + ((op >> 3) & 0x38), p, 4, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "MOVE.L   %s,%s", ea, ea2);
			break;
		case 0x2040: case 0x2240: case 0x2440: case 0x2640: case 0x2840: case 0x2a40: case 0x2c40: case 0x2e40:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "MOVEA.L  %s,A%d", ea, rhi);
			break;
		case 0x3000: case 0x3080: case 0x30c0: case 0x3100: case 0x3140: case 0x3180: case 0x31c0:
		case 0x3200: case 0x3280: case 0x32c0: case 0x3300: case 0x3340: case 0x3380: case 0x33c0:
		case 0x3400: case 0x3480: case 0x34c0: case 0x3500: case 0x3540: case 0x3580:
		case 0x3600: case 0x3680: case 0x36c0: case 0x3700: case 0x3740: case 0x3780:
		case 0x3800: case 0x3880: case 0x38c0: case 0x3900: case 0x3940: case 0x3980:
		case 0x3a00: case 0x3a80: case 0x3ac0: case 0x3b00: case 0x3b40: case 0x3b80:
		case 0x3c00: case 0x3c80: case 0x3cc0: case 0x3d00: case 0x3d40: case 0x3d80:
		case 0x3e00: case 0x3e80: case 0x3ec0: case 0x3f00: case 0x3f40: case 0x3f80:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count; ea2 = MakeEA (((op >> 9) & 0x07) + ((op >> 3) & 0x38), p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "MOVE.W   %s,%s", ea, ea2);
			break;
		case 0x3040: case 0x3240: case 0x3440: case 0x3640: case 0x3840: case 0x3a40: case 0x3c40: case 0x3e40:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "MOVEA.W  %s,A%d", ea, rhi);
			break;
		case 0x4000:
			ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "NEGX.B   %s", ea);
			break;
		case 0x4040:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "NEGX.W   %s", ea);
			break;
		case 0x4080:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "NEGX.L   %s", ea);
			break;
		case 0x40c0:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "MOVE     SR,%s", ea);
			break;
		case 0x4180: case 0x4380: case 0x4580: case 0x4780: case 0x4980: case 0x4b80: case 0x4d80: case 0x4f80:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "CHK.W    %s,D%d", ea, rhi);
			break;
		case 0x41c0: case 0x43c0: case 0x45c0: case 0x47c0: case 0x49c0: case 0x4bc0: case 0x4dc0: case 0x4fc0:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "LEA      %s,A%d", ea, rhi);
			break;
		case 0x4200:
			ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "CLR.B    %s", ea);
			break;
		case 0x4240:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "CLR.W    %s", ea);
			break;
		case 0x4280:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "CLR.L    %s", ea);
			break;
		case 0x42c0:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "MOVE     CCR,%s", ea);
			break;
		case 0x4400:
			ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "NEG.B    %s", ea);
			break;
		case 0x4440:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "NEG.W    %s", ea);
			break;
		case 0x4480:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "NEG.L    %s", ea);
			break;
		case 0x44c0:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "MOVE     %s,CCR", ea);
			break;
		case 0x4600:
			ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "NOT.B    %s", ea);
			break;
		case 0x4640:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "NOT.W    %s", ea);
			break;
		case 0x4680:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "NOT.L    %s", ea);
			break;
		case 0x46c0:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "MOVE     %s,SR", ea);
			break;
		case 0x4800:
			ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "NBCD.B   %s", ea);
			break;
		case 0x4840:
			if ((lo & 0x38) == 0x00)
				sprintf (buffer, "SWAP     D%d", rlo);
            else if ((lo & 0x38) == 0x08)   /* Bart, April 24, 2001 */
                sprintf (buffer, "BKPT     #%d", lo & 7);
			else
			{
				ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
				sprintf (buffer, "PEA      %s", ea);
			}
			break;
		case 0x4880:
			if ((lo & 0x38) == 0x00)
				sprintf (buffer, "EXT.W    D%d", rlo);
			else
			{
				char *b = buffer;
				PARAM_WORD (pm);	ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
				b += sprintf (b, "MOVEM.W  ");
				if ((lo & 0x38) != 0x20) b = MakeRegList (b, (unsigned short) pm);
				else b = MakeRevRegList (b, (unsigned short) pm);
				sprintf (b, ",%s", ea);
			}
			break;
		case 0x48c0:
			if ((lo & 0x38) == 0x00)
				sprintf (buffer, "EXT.L    D%d", rlo);
			else
			{
				char *b = buffer;
				PARAM_WORD (pm);	ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
				b += sprintf (b, "MOVEM.L  ");
				if ((lo & 0x38) != 0x20) b = MakeRegList (b, (unsigned short) pm);
				else b = MakeRevRegList (b, (unsigned short) pm);
				sprintf (b, ",%s", ea);
			}
			break;
		case 0x4a00:
			ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "TST.B    %s", ea);
			break;
		case 0x4a40:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "TST.W    %s", ea);
			break;
		case 0x4a80:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "TST.L    %s", ea);
			break;
		case 0x4ac0:
            if (op == 0x4afc)   /* ILLEGAL: illegal instruction trap */
                sprintf(buffer, "ILLEGAL");
            else
            {
                ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
                sprintf (buffer, "TAS.B    %s", ea);
            }
            break;
		case 0x4c80:
			{
				char *b = buffer;
				PARAM_WORD (pm);	ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
				b += sprintf (b, "MOVEM.W  %s,", ea);
				b = MakeRegList (b, (unsigned short) pm);
			}
			break;
		case 0x4cc0:
			{
				char *b = buffer;
				PARAM_WORD (pm);	ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
				b += sprintf (b, "MOVEM.L  %s,", ea);
				b = MakeRegList (b, (unsigned short) pm);
			}
			break;
		case 0x4e40:
			if ((lo & 0x30) == 0x00)
                                sprintf (buffer, "TRAP     #0x%X", lo & 15);
			else if ((lo & 0x38) == 0x10)
			{
				PARAM_WORD (pm);
                                sprintf (buffer, "LINK     A%d,#0x%lX", rlo, pm);
			}
			else if ((lo & 0x38) == 0x18)
			{
				sprintf (buffer, "UNLK     A%d", rlo);
			}
			else if ((lo & 0x38) == 0x20)
				sprintf (buffer, "MOVE     A%d,USP", rlo);
			else if ((lo & 0x38) == 0x28)
				sprintf (buffer, "MOVE     USP,A%d", rlo);
			else if (lo == 0x30)
				sprintf (buffer, "RESET");
			else if (lo == 0x31)
				sprintf (buffer, "NOP");
			else if (lo == 0x32)
            {
                PARAM_WORD(pm);
                sprintf (buffer, "STOP     #0x%04X", (UINT16) pm);  /* Bart, April 28, 2001 (changed %02X->%04X) */
            }
            else if (lo == 0x34)    /* Bart, April 28, 2001 */
            {
                PARAM_WORD(pm);
                sprintf (buffer, "RTD      #0x%04X", (UINT16) pm);
            }
			else if (lo == 0x33)
				sprintf (buffer, "RTE");
			else if (lo == 0x35)
				sprintf (buffer, "RTS");
			else if (lo == 0x36)
				sprintf (buffer, "TRAPV");
			else if (lo == 0x37)
				sprintf (buffer, "RTR");
			else if (lo == 0x3a)
			{
				PARAM_WORD (pm);
				switch (pm & 0xfff)
				{
					case 0x000:	ea = "SFC";	break;
					case 0x001:	ea = "DFC"; break;
					case 0x800: ea = "USP"; break;
					case 0x801: ea = "VBR"; break;
					default: ea = "???"; break;
				}
				if (pm & 0x8000)
					sprintf (buffer, "MOVEC    %s,A%ld", ea, (pm >> 12) & 7);
				else
					sprintf (buffer, "MOVEC    %s,D%ld", ea, (pm >> 12) & 7);
			}
			else if (lo == 0x3b)
			{
				PARAM_WORD (pm);
				switch (pm & 0xfff)
				{
					case 0x000:	ea = "SFC";	break;
					case 0x001:	ea = "DFC"; break;
					case 0x800: ea = "USP"; break;
					case 0x801: ea = "VBR"; break;
					default: ea = "???"; break;
				}
				if (pm & 0x8000)
					sprintf (buffer, "MOVEC    A%ld,%s", (pm >> 12) & 7, ea);
				else
					sprintf (buffer, "MOVEC    D%ld,%s", (pm >> 12) & 7, ea);
			}
			else
                                sprintf (buffer, "UNRECOGNIZED");
			break;
		case 0x4e80:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "JSR      %s", ea);
			break;
		case 0x4ec0:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "JMP      %s", ea);
			break;
		case 0x5000: case 0x5200: case 0x5400: case 0x5600: case 0x5800: case 0x5a00: case 0x5c00: case 0x5e00:
			ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "ADDQ.B   #%d,%s", (rhi == 0) ? 8 : rhi, ea);
			break;
		case 0x5040: case 0x5240: case 0x5440: case 0x5640: case 0x5840: case 0x5a40: case 0x5c40: case 0x5e40:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "ADDQ.W   #%d,%s", (rhi == 0) ? 8 : rhi, ea);
			break;
		case 0x5080: case 0x5280: case 0x5480: case 0x5680: case 0x5880: case 0x5a80: case 0x5c80: case 0x5e80:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "ADDQ.L   #%d,%s", (rhi == 0) ? 8 : rhi, ea);
			break;
		case 0x50c0: case 0x52c0: case 0x54c0: case 0x56c0: case 0x58c0: case 0x5ac0: case 0x5cc0: case 0x5ec0:
		case 0x51c0: case 0x53c0: case 0x55c0: case 0x57c0: case 0x59c0: case 0x5bc0: case 0x5dc0: case 0x5fc0:
			if ((lo & 0x38) == 0x08)
			{
				PARAM_WORD (pm);
				if (pm & 0x8000)
                                        sprintf (buffer, "DB%s     D%d,*-0x%X [0x%X]", ccodes[(op >> 8) & 15], rlo, (-(signed short)pm) - 2, (UINT32) (dwVirtualAddress + (signed short)pm + 2));
				else
                                        sprintf (buffer, "DB%s     D%d,*+0x%lX [0x%lX]", ccodes[(op >> 8) & 15], rlo, pm - 2, dwVirtualAddress + pm + 2);
			}
			else
			{
				ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
				sprintf (buffer, "S%s.B    %s", ccodes[(op >> 8) & 15], ea);
			}
			break;
		case 0x5100: case 0x5300: case 0x5500: case 0x5700: case 0x5900: case 0x5b00: case 0x5d00: case 0x5f00:
			ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "SUBQ.B   #%d,%s", (rhi == 0) ? 8 : rhi, ea);
			break;
		case 0x5140: case 0x5340: case 0x5540: case 0x5740: case 0x5940: case 0x5b40: case 0x5d40: case 0x5f40:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "SUBQ.W   #%d,%s", (rhi == 0) ? 8 : rhi, ea);
			break;
		case 0x5180: case 0x5380: case 0x5580: case 0x5780: case 0x5980: case 0x5b80: case 0x5d80: case 0x5f80:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "SUBQ.L   #%d,%s", (rhi == 0) ? 8 : rhi, ea);
			break;
		case 0x6000: case 0x6040: case 0x6080: case 0x60c0:
			pm = op & 0xff;
			if (pm == 0)
			{
				PARAM_WORD(pm);
				if (pm & 0x8000)
                                        sprintf (buffer, "BRA      *-0x%X [0x%X]", (int)(-(signed short)pm) - 2, (UINT32) (dwVirtualAddress + (signed short)pm + 2));
				else
                                        sprintf (buffer, "BRA      *+0x%lX [0x%lX]", pm + 2, dwVirtualAddress + pm + 2);
			}
			else
			{
				if (pm & 0x80)
                                        sprintf (buffer, "BRA.S    *-0x%X [0x%X]", (int)(-(signed char)pm) - 2, (UINT32) (dwVirtualAddress + (signed char)pm + 2));
				else
                                        sprintf (buffer, "BRA.S    *+0x%lX [0x%lX]", pm + 2, dwVirtualAddress + pm + 2);
			}
			break;
		case 0x6100: case 0x6140: case 0x6180: case 0x61c0:
			pm = op & 0xff;
			if (pm == 0)
			{
				PARAM_WORD(pm);
				if (pm & 0x8000)
                                        sprintf (buffer, "BSR      *-0x%X [0x%X]", (int)(-(signed short)pm) - 2, (UINT32) (dwVirtualAddress + (signed short)pm + 2));
				else
                                        sprintf (buffer, "BSR      *+0x%lX [0x%lX]", pm + 2, dwVirtualAddress + pm + 2);
			}
			else
			{
				if (pm & 0x80)
                                        sprintf (buffer, "BSR.S    *-0x%X [0x%X]", (int)(-(signed char)pm) - 2, (UINT32) (dwVirtualAddress + (signed char)pm + 2));
				else
                                        sprintf (buffer, "BSR.S    *+0x%lX [0x%lX]", pm + 2, dwVirtualAddress + pm + 2);
			}
			break;
		case 0x6200: case 0x6240: case 0x6280: case 0x62c0: case 0x6300: case 0x6340: case 0x6380: case 0x63c0:
		case 0x6400: case 0x6440: case 0x6480: case 0x64c0: case 0x6500: case 0x6540: case 0x6580: case 0x65c0:
		case 0x6600: case 0x6640: case 0x6680: case 0x66c0: case 0x6700: case 0x6740: case 0x6780: case 0x67c0:
		case 0x6800: case 0x6840: case 0x6880: case 0x68c0: case 0x6900: case 0x6940: case 0x6980: case 0x69c0:
		case 0x6a00: case 0x6a40: case 0x6a80: case 0x6ac0: case 0x6b00: case 0x6b40: case 0x6b80: case 0x6bc0:
		case 0x6c00: case 0x6c40: case 0x6c80: case 0x6cc0: case 0x6d00: case 0x6d40: case 0x6d80: case 0x6dc0:
		case 0x6e00: case 0x6e40: case 0x6e80: case 0x6ec0: case 0x6f00: case 0x6f40: case 0x6f80: case 0x6fc0:
			pm = op & 0xff;
			if (pm == 0)
			{
				PARAM_WORD(pm);
				if (pm & 0x8000)
                                        sprintf (buffer, "B%s      *-0x%X [0x%X]", ccodes[(op >> 8) & 15], (int)(-(signed short)pm) - 2, (UINT32) (dwVirtualAddress + (signed short)pm + 2));
				else
                                        sprintf (buffer, "B%s      *+0x%lX [0x%lX]", ccodes[(op >> 8) & 15], pm + 2, dwVirtualAddress + pm + 2);
			}
			else
			{
				if (pm & 0x80)
                                        sprintf (buffer, "B%s.S    *-0x%X [0x%X]", ccodes[(op >> 8) & 15], (int)(-(signed char)pm) - 2, (UINT32) (dwVirtualAddress + (signed char)pm + 2));
				else
                                        sprintf (buffer, "B%s.S    *+0x%lX [0x%lX]", ccodes[(op >> 8) & 15], pm + 2, dwVirtualAddress + pm + 2);
			}
			break;
		case 0x7000: case 0x7040: case 0x7080: case 0x70c0:
		case 0x7200: case 0x7240: case 0x7280: case 0x72c0:
		case 0x7400: case 0x7440: case 0x7480: case 0x74c0:
		case 0x7600: case 0x7640: case 0x7680: case 0x76c0:
		case 0x7800: case 0x7840: case 0x7880: case 0x78c0:
		case 0x7a00: case 0x7a40: case 0x7a80: case 0x7ac0:
		case 0x7c00: case 0x7c40: case 0x7c80: case 0x7cc0:
		case 0x7e00: case 0x7e40: case 0x7e80: case 0x7ec0:
			pm = op & 0xff;
			if (pm & 0x80)
                                sprintf (buffer, "MOVEQ    #-0x%X,D%d", -(signed char)pm, rhi);
			else
                                sprintf (buffer, "MOVEQ    #0x%lX,D%d", pm, rhi);
			break;
		case 0x8000: case 0x8200: case 0x8400: case 0x8600: case 0x8800: case 0x8a00: case 0x8c00: case 0x8e00:
			ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "OR.B     %s,D%d", ea, rhi);
			break;
		case 0x8040: case 0x8240: case 0x8440: case 0x8640: case 0x8840: case 0x8a40: case 0x8c40: case 0x8e40:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "OR.W     %s,D%d", ea, rhi);
			break;
		case 0x8080: case 0x8280: case 0x8480: case 0x8680: case 0x8880: case 0x8a80: case 0x8c80: case 0x8e80:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "OR.L     %s,D%d", ea, rhi);
			break;
		case 0x80c0: case 0x82c0: case 0x84c0: case 0x86c0: case 0x88c0: case 0x8ac0: case 0x8cc0: case 0x8ec0:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "DIVU.W   %s,D%d", ea, rhi);
			break;
		case 0x8100: case 0x8300: case 0x8500: case 0x8700: case 0x8900: case 0x8b00: case 0x8d00: case 0x8f00:
			if ((lo & 0x30) == 0)
			{
				if (lo & 0x08)
					sprintf (buffer, "SBCD.B   -(A%d),-(A%d)", rlo, rhi);
				else
					sprintf (buffer, "SBCD.B   D%d,D%d", rlo, rhi);
			}
			else
			{
				ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
				sprintf (buffer, "OR.B     D%d,%s", rhi, ea);
			}
			break;
		case 0x8140: case 0x8340: case 0x8540: case 0x8740: case 0x8940: case 0x8b40: case 0x8d40: case 0x8f40:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "OR.W     D%d,%s", rhi, ea);
			break;
		case 0x8180: case 0x8380: case 0x8580: case 0x8780: case 0x8980: case 0x8b80: case 0x8d80: case 0x8f80:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "OR.L     D%d,%s", rhi, ea);
			break;
		case 0x81c0: case 0x83c0: case 0x85c0: case 0x87c0: case 0x89c0: case 0x8bc0: case 0x8dc0: case 0x8fc0:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "DIVS.W   %s,D%d", ea, rhi);
			break;
		case 0x9000: case 0x9200: case 0x9400: case 0x9600: case 0x9800: case 0x9a00: case 0x9c00: case 0x9e00:
			ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "SUB.B    %s,D%d", ea, rhi);
			break;
		case 0x9040: case 0x9240: case 0x9440: case 0x9640: case 0x9840: case 0x9a40: case 0x9c40: case 0x9e40:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "SUB.W    %s,D%d", ea, rhi);
			break;
		case 0x9080: case 0x9280: case 0x9480: case 0x9680: case 0x9880: case 0x9a80: case 0x9c80: case 0x9e80:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "SUB.L    %s,D%d", ea, rhi);
			break;
		case 0x90c0: case 0x92c0: case 0x94c0: case 0x96c0: case 0x98c0: case 0x9ac0: case 0x9cc0: case 0x9ec0:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "SUBA.W   %s,A%d", ea, rhi);
			break;
		case 0x9100: case 0x9300: case 0x9500: case 0x9700: case 0x9900: case 0x9b00: case 0x9d00: case 0x9f00:
			if ((lo & 0x30) == 0)
			{
				if (lo & 0x08)
					sprintf (buffer, "SUBX.B   -(A%d),-(A%d)", rlo, rhi);
				else
					sprintf (buffer, "SUBX.B   D%d,D%d", rlo, rhi);
			}
			else
			{
				ea = MakeEA (lo, p, 1,&count, dwVirtualAddress); p += count;
				sprintf (buffer, "SUB.B    D%d,%s", rhi, ea);
			}
			break;
		case 0x9140: case 0x9340: case 0x9540: case 0x9740: case 0x9940: case 0x9b40: case 0x9d40: case 0x9f40:
			if ((lo & 0x30) == 0)
			{
				if (lo & 0x08)
					sprintf (buffer, "SUBX.W   -(A%d),-(A%d)", rlo, rhi);
				else
					sprintf (buffer, "SUBX.W   D%d,D%d", rlo, rhi);
			}
			else
			{
				ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
				sprintf (buffer, "SUB.W    D%d,%s", rhi, ea);
			}
			break;
		case 0x9180: case 0x9380: case 0x9580: case 0x9780: case 0x9980: case 0x9b80: case 0x9d80: case 0x9f80:
			if ((lo & 0x30) == 0)
			{
				if (lo & 0x08)
					sprintf (buffer, "SUBX.L   -(A%d),-(A%d)", rlo, rhi);
				else
					sprintf (buffer, "SUBX.L   D%d,D%d", rlo, rhi);
			}
			else
			{
				ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
				sprintf (buffer, "SUB.L    D%d,%s", rhi, ea);
			}
			break;
		case 0x91c0: case 0x93c0: case 0x95c0: case 0x97c0: case 0x99c0: case 0x9bc0: case 0x9dc0: case 0x9fc0:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "SUBA.L   %s,A%d", ea, rhi);
			break;
		case 0xb000: case 0xb200: case 0xb400: case 0xb600: case 0xb800: case 0xba00: case 0xbc00: case 0xbe00:
			ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "CMP.B    %s,D%d", ea, rhi);
			break;
		case 0xb040: case 0xb240: case 0xb440: case 0xb640: case 0xb840: case 0xba40: case 0xbc40: case 0xbe40:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "CMP.W    %s,D%d", ea, rhi);
			break;
		case 0xb080: case 0xb280: case 0xb480: case 0xb680: case 0xb880: case 0xba80: case 0xbc80: case 0xbe80:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "CMP.L    %s,D%d", ea, rhi);
			break;
		case 0xb0c0: case 0xb2c0: case 0xb4c0: case 0xb6c0: case 0xb8c0: case 0xbac0: case 0xbcc0: case 0xbec0:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "CMPA.W   %s,A%d", ea, rhi);
			break;
		case 0xb100: case 0xb300: case 0xb500: case 0xb700: case 0xb900: case 0xbb00: case 0xbd00: case 0xbf00:
			if ((lo & 0x38) == 0x08)
				sprintf (buffer, "CMPM.B   (A%d)+,(A%d)+", rlo, rhi);
			else
			{
				ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
				sprintf (buffer, "EOR.B    D%d,%s", rhi, ea);
			}
			break;
		case 0xb140: case 0xb340: case 0xb540: case 0xb740: case 0xb940: case 0xbb40: case 0xbd40: case 0xbf40:
			if ((lo & 0x38) == 0x08)
				sprintf (buffer, "CMPM.W   (A%d)+,(A%d)+", rlo, rhi);
			else
			{
				ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
				sprintf (buffer, "EOR.W    D%d,%s", rhi, ea);
			}
			break;
		case 0xb180: case 0xb380: case 0xb580: case 0xb780: case 0xb980: case 0xbb80: case 0xbd80: case 0xbf80:
			if ((lo & 0x38) == 0x08)
				sprintf (buffer, "CMPM.L   (A%d)+,(A%d)+", rlo, rhi);
			else
			{
				ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
				sprintf (buffer, "EOR.L    D%d,%s", rhi, ea);
			}
			break;
		case 0xb1c0: case 0xb3c0: case 0xb5c0: case 0xb7c0: case 0xb9c0: case 0xbbc0: case 0xbdc0: case 0xbfc0:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "CMPA.L   %s,A%d", ea, rhi);
			break;
		case 0xc000: case 0xc200: case 0xc400: case 0xc600: case 0xc800: case 0xca00: case 0xcc00: case 0xce00:
			ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "AND.B    %s,D%d", ea, rhi);
			break;
		case 0xc040: case 0xc240: case 0xc440: case 0xc640: case 0xc840: case 0xca40: case 0xcc40: case 0xce40:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "AND.W    %s,D%d", ea, rhi);
			break;
		case 0xc080: case 0xc280: case 0xc480: case 0xc680: case 0xc880: case 0xca80: case 0xcc80: case 0xce80:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "AND.L    %s,D%d", ea, rhi);
			break;
		case 0xc0c0: case 0xc2c0: case 0xc4c0: case 0xc6c0: case 0xc8c0: case 0xcac0: case 0xccc0: case 0xcec0:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "MULU.W   %s,D%d", ea, rhi);
			break;
		case 0xc100: case 0xc300: case 0xc500: case 0xc700: case 0xc900: case 0xcb00: case 0xcd00: case 0xcf00:
			if ((lo & 0x30) == 0)
			{
				if (lo & 0x08)
					sprintf (buffer, "ABCD.B   -(A%d),-(A%d)", rlo, rhi);
				else
					sprintf (buffer, "ABCD.B   D%d,D%d", rlo, rhi);
			}
			else
			{
				ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
				sprintf (buffer, "AND.B    D%d,%s", rhi, ea);
			}
			break;
		case 0xc140: case 0xc340: case 0xc540: case 0xc740: case 0xc940: case 0xcb40: case 0xcd40: case 0xcf40:
			if ((lo & 0x30) == 0)
			{
				if (lo & 0x08)
					sprintf (buffer, "EXG      A%d,A%d", rhi, rlo);
				else
					sprintf (buffer, "EXG      D%d,D%d", rhi, rlo);
			}
			else
			{
				ea = MakeEA (lo, p, 2,&count, dwVirtualAddress); p += count;
				sprintf (buffer, "AND.W    D%d,%s", rhi, ea);
			}
			break;
		case 0xc180: case 0xc380: case 0xc580: case 0xc780: case 0xc980: case 0xcb80: case 0xcd80: case 0xcf80:
			if ((lo & 0x38) == 0x08)
				sprintf (buffer, "EXG      D%d,A%d", rhi, rlo);
			else
			{
				ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
				sprintf (buffer, "AND.L    D%d,%s", rhi, ea);
			}
			break;
		case 0xc1c0: case 0xc3c0: case 0xc5c0: case 0xc7c0: case 0xc9c0: case 0xcbc0: case 0xcdc0: case 0xcfc0:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "MULS.W   %s,D%d", ea, rhi);
			break;
		case 0xd000: case 0xd200: case 0xd400: case 0xd600: case 0xd800: case 0xda00: case 0xdc00: case 0xde00:
			ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "ADD.B    %s,D%d", ea, rhi);
			break;
		case 0xd040: case 0xd240: case 0xd440: case 0xd640: case 0xd840: case 0xda40: case 0xdc40: case 0xde40:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "ADD.W    %s,D%d", ea, rhi);
			break;
		case 0xd080: case 0xd280: case 0xd480: case 0xd680: case 0xd880: case 0xda80: case 0xdc80: case 0xde80:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "ADD.L    %s,D%d", ea, rhi);
			break;
		case 0xd0c0: case 0xd2c0: case 0xd4c0: case 0xd6c0: case 0xd8c0: case 0xdac0: case 0xdcc0: case 0xdec0:
			ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "ADDA.W   %s,A%d", ea, rhi);
			break;
		case 0xd100: case 0xd300: case 0xd500: case 0xd700: case 0xd900: case 0xdb00: case 0xdd00: case 0xdf00:
			if ((lo & 0x30) == 0)
			{
				if (lo & 0x08)
					sprintf (buffer, "ADDX.B   -(A%d),-(A%d)", rlo, rhi);
				else
					sprintf (buffer, "ADDX.B   D%d,D%d", rlo, rhi);
			}
			else
			{
				ea = MakeEA (lo, p, 1, &count, dwVirtualAddress); p += count;
				sprintf (buffer, "ADD.B    D%d,%s", rhi, ea);
			}
			break;
		case 0xd140: case 0xd340: case 0xd540: case 0xd740: case 0xd940: case 0xdb40: case 0xdd40: case 0xdf40:
			if ((lo & 0x30) == 0)
			{
				if (lo & 0x08)
					sprintf (buffer, "ADDX.W   -(A%d),-(A%d)", rlo, rhi);
				else
					sprintf (buffer, "ADDX.W   D%d,D%d", rlo, rhi);
			}
			else
			{
				ea = MakeEA (lo, p, 2, &count, dwVirtualAddress); p += count;
				sprintf (buffer, "ADD.W    D%d,%s", rhi, ea);
			}
			break;
		case 0xd180: case 0xd380: case 0xd580: case 0xd780: case 0xd980: case 0xdb80: case 0xdd80: case 0xdf80:
			if ((lo & 0x30) == 0)
			{
				if (lo & 0x08)
					sprintf (buffer, "ADDX.L   -(A%d),-(A%d)", rlo, rhi);
				else
					sprintf (buffer, "ADDX.L   D%d,D%d", rlo, rhi);
			}
			else
			{
				ea = MakeEA (lo, p, 4,&count, dwVirtualAddress); p += count;
				sprintf (buffer, "ADD.L    D%d,%s", rhi, ea);
			}
			break;
		case 0xd1c0: case 0xd3c0: case 0xd5c0: case 0xd7c0: case 0xd9c0: case 0xdbc0: case 0xddc0: case 0xdfc0:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			sprintf (buffer, "ADDA.L   %s,A%d", ea, rhi);
			break;
		case 0xe000: case 0xe200: case 0xe400: case 0xe600: case 0xe800: case 0xea00: case 0xec00: case 0xee00:
			switch ((lo >> 3) & 7)
			{
				case 0:	sprintf (buffer, "ASR.B    #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 1:	sprintf (buffer, "LSR.B    #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 2:	sprintf (buffer, "ROXR.B   #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 3:	sprintf (buffer, "ROR.B    #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 4:	sprintf (buffer, "ASR.B    D%d,D%d", rhi, rlo);		break;
				case 5:	sprintf (buffer, "LSR.B    D%d,D%d", rhi, rlo);		break;
				case 6:	sprintf (buffer, "ROXR.B   D%d,D%d", rhi, rlo);		break;
				case 7:	sprintf (buffer, "ROR.B    D%d,D%d", rhi, rlo);		break;
			}
			break;
		case 0xe040: case 0xe240: case 0xe440: case 0xe640: case 0xe840: case 0xea40: case 0xec40: case 0xee40:
			switch ((lo >> 3) & 7)
			{
				case 0:	sprintf (buffer, "ASR.W    #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 1:	sprintf (buffer, "LSR.W    #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 2:	sprintf (buffer, "ROXR.W   #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 3:	sprintf (buffer, "ROR.W    #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 4:	sprintf (buffer, "ASR.W    D%d,D%d", rhi, rlo);		break;
				case 5:	sprintf (buffer, "LSR.W    D%d,D%d", rhi, rlo);		break;
				case 6:	sprintf (buffer, "ROXR.W   D%d,D%d", rhi, rlo);		break;
				case 7:	sprintf (buffer, "ROR.W    D%d,D%d", rhi, rlo);		break;
			}
			break;
		case 0xe080: case 0xe280: case 0xe480: case 0xe680: case 0xe880: case 0xea80: case 0xec80: case 0xee80:
			switch ((lo >> 3) & 7)
			{
				case 0:	sprintf (buffer, "ASR.L    #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 1:	sprintf (buffer, "LSR.L    #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 2:	sprintf (buffer, "ROXR.L   #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 3:	sprintf (buffer, "ROR.L    #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 4:	sprintf (buffer, "ASR.L    D%d,D%d", rhi, rlo);		break;
				case 5:	sprintf (buffer, "LSR.L    D%d,D%d", rhi, rlo);		break;
				case 6:	sprintf (buffer, "ROXR.L   D%d,D%d", rhi, rlo);		break;
				case 7:	sprintf (buffer, "ROR.L    D%d,D%d", rhi, rlo);		break;
			}
			break;
        case 0xe0c0: case 0xe2c0: case 0xe4c0: case 0xe6c0:
        case 0xe1c0: case 0xe3c0: case 0xe5c0: case 0xe7c0:
			ea = MakeEA (lo, p, 4, &count, dwVirtualAddress); p += count;
			switch ((op >> 8) & 7)
			{
                case 0: sprintf (buffer, "ASR      %s", ea);    break;
                case 1: sprintf (buffer, "ASL      %s", ea);    break;
                case 2: sprintf (buffer, "LSR      %s", ea);    break;
                case 3: sprintf (buffer, "LSL      %s", ea);    break;
                case 4: sprintf (buffer, "ROXR     %s", ea);    break;
                case 5: sprintf (buffer, "ROXL     %s", ea);    break;
                case 6: sprintf (buffer, "ROR      %s", ea);    break;
                case 7: sprintf (buffer, "ROL      %s", ea);    break;
			}
			break;
		case 0xe100: case 0xe300: case 0xe500: case 0xe700: case 0xe900: case 0xeb00: case 0xed00: case 0xef00:
			switch ((lo >> 3) & 7)
			{
				case 0:	sprintf (buffer, "ASL.B    #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 1:	sprintf (buffer, "LSL.B    #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 2:	sprintf (buffer, "ROXL.B   #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 3:	sprintf (buffer, "ROL.B    #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 4:	sprintf (buffer, "ASL.B    D%d,D%d", rhi, rlo);		break;
				case 5:	sprintf (buffer, "LSL.B    D%d,D%d", rhi, rlo);		break;
				case 6:	sprintf (buffer, "ROXL.B   D%d,D%d", rhi, rlo);		break;
				case 7:	sprintf (buffer, "ROL.B    D%d,D%d", rhi, rlo);		break;
			}
			break;
		case 0xe140: case 0xe340: case 0xe540: case 0xe740: case 0xe940: case 0xeb40: case 0xed40: case 0xef40:
			switch ((lo >> 3) & 7)
			{
				case 0:	sprintf (buffer, "ASL.W    #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 1:	sprintf (buffer, "LSL.W    #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 2:	sprintf (buffer, "ROXL.W   #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 3:	sprintf (buffer, "ROL.W    #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 4:	sprintf (buffer, "ASL.W    D%d,D%d", rhi, rlo);		break;
				case 5:	sprintf (buffer, "LSL.W    D%d,D%d", rhi, rlo);		break;
				case 6:	sprintf (buffer, "ROXL.W   D%d,D%d", rhi, rlo);		break;
				case 7:	sprintf (buffer, "ROL.W    D%d,D%d", rhi, rlo);		break;
			}
			break;
		case 0xe180: case 0xe380: case 0xe580: case 0xe780: case 0xe980: case 0xeb80: case 0xed80: case 0xef80:
			switch ((lo >> 3) & 7)
			{
				case 0:	sprintf (buffer, "ASL.L    #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 1:	sprintf (buffer, "LSL.L    #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 2:	sprintf (buffer, "ROXL.L   #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 3:	sprintf (buffer, "ROL.L    #%d,D%d", (rhi == 0) ? 8 : rhi, rlo);		break;
				case 4:	sprintf (buffer, "ASL.L    D%d,D%d", rhi, rlo);		break;
				case 5:	sprintf (buffer, "LSL.L    D%d,D%d", rhi, rlo);		break;
				case 6:	sprintf (buffer, "ROXL.L   D%d,D%d", rhi, rlo);		break;
				case 7:	sprintf (buffer, "ROL.L    D%d,D%d", rhi, rlo);		break;
			}
			break;
		default:
                        sprintf (buffer, "UNRECOGNIZED");
			break;
	}

	// Get the length of things

	dwLen = (UINT32) p - (UINT32) pbOpcode;
	*pbOpcodeBytesAsText = '\0';

	if (2 == dwLen)
	{
                sprintf(pbOpcodeBytesAsText, "0x%02X%02X                             ", *(pbOpcode + 1), *(pbOpcode));
	}
	else
	if (4 == dwLen)
	{
                sprintf(pbOpcodeBytesAsText, "0x%02X%02X 0x%02X%02X                      ", *(pbOpcode + 1), *(pbOpcode + 0), *(pbOpcode + 3), *(pbOpcode + 2));
	}
	else
	if (6 == dwLen)
	{
                sprintf(pbOpcodeBytesAsText, "0x%02X%02X 0x%02X%02X 0x%02X%02X               ", *(pbOpcode + 1), *(pbOpcode + 0), *(pbOpcode + 3), *(pbOpcode + 2), *(pbOpcode + 5), *(pbOpcode + 4));
	}
	else
	if (8 == dwLen)
	{
                sprintf(pbOpcodeBytesAsText, "0x%02X%02X 0x%02X%02X 0x%02X%02X 0x%02X%02X        ", *(pbOpcode + 1), *(pbOpcode + 0), *(pbOpcode + 3), *(pbOpcode + 2), *(pbOpcode + 5), *(pbOpcode + 4), *(pbOpcode + 7), *(pbOpcode + 6));
    }
    else
    if (10 == dwLen)    
    {
                sprintf(pbOpcodeBytesAsText, "0x%02X%02X 0x%02X%02X 0x%02X%02X 0x%02X%02X 0x%02X%02X ", *(pbOpcode + 1), *(pbOpcode + 0), *(pbOpcode + 3), *(pbOpcode + 2), *(pbOpcode + 5), *(pbOpcode + 4), *(pbOpcode + 7), *(pbOpcode + 6), *(pbOpcode + 9), *(pbOpcode + 8));
    }
	else		// what???? Unknown length!
	{
                sprintf(pbOpcodeBytesAsText, "<UNKNOWN LENGTH: %u> ", dwLen);
	}

	return(dwLen);
}
