/*
 * C compiler
 * ==========
 *
 * Copyright 1989, 1990, 1991 Christoph van Wuellen.
 * Credits to Matthew Brandt.
 * All commercial rights reserved.
 *
 * This compiler may be redistributed as long there is no
 * commercial interest. The compiler must not be redistributed
 * without its full sources. This notice must stay intact.
 *
 * History:
 *
 * 1989   starting an 68000 C compiler, starting with material
 *        originally by M. Brandt
 * 1990   68000 C compiler further bug fixes
 *        started i386 port (December)
 * 1991   i386 port finished (January)
 *        further corrections in the front end and in the 68000
 *        code generator.
 *        The next port will be a SPARC port
 */

#include	"c.h"
#include	"expr.h"
#include	"gen.h"
#include	"cglbdec.h"

#ifdef INTEL_386

/* variable initialization */

enum e_gt {
    nogen, bytegen, wordgen, longgen, floatgen
};
enum e_sg {
    noseg, codeseg, dataseg
};

/*
 * This module can be set up to prepend underscores to the
 * names shipped out by this module.
 * Names starting with a dot are not translated, theses are
 * compiler support functions which should not fall in the
 * user's namespace
 *
 * The default setup is:
 * Prepend underscores in the GAS version, but do not
 * prepend underscores in the Sun version.
 */

#ifdef SUN_ASM_SYNTAX
#define outlate(X) (X)
#else
static char    *
outlate(s)
    char           *s;
{
    static char     symbol[MAX_ID_LEN + 1];
    if (*s == '.')
        return s;
    symbol[0] = '_';
    strcpy(symbol + 1, s);
    return symbol;
}
#endif /* SUN_ASM_SYNTAX */


enum e_gt       gentype;
enum e_sg       curseg;
int             outcol;

static char *regname[NUMREG+1];

struct oplst {
    char           *s;
    enum e_op       ov;
}               opl[] =

{
"mov",		op_mov,
"movsbl",	op_movsbl,
"movzbl",	op_movzbl,
"movswl",	op_movswl,
"movzwl",	op_movzwl,
"movzbw",	op_movzbw,
"movsbw",	op_movsbw,
"cltd",  	op_cltd,
"push",  	op_push,
"pop",   	op_pop,
"add",   	op_add,
"sub",   	op_sub,
"inc",   	op_inc,
"dec",   	op_dec,
"imul",  	op_imul,
"idiv",  	op_idiv,
"and",   	op_and,
"neg",   	op_neg,
"not",   	op_not,
"or",    	op_or,
"xor",   	op_xor,
"shl",   	op_shl,
"shr",   	op_shr,
"sar",   	op_asr,
"cmp",   	op_cmp,
"lea",   	op_lea,
"jmp",   	op_bra,
"jmp",   	op_jmp,
"call",  	op_call,
"je",    	op_je,
"jne",   	op_jne,
"jle",   	op_jle,
"jge",   	op_jge,
"jl",    	op_jl,
"jg",    	op_jg,
"jbe",   	op_jbe,
"jae",   	op_jae,
"jb",    	op_jb,
"ja",    	op_ja,
"leave", 	op_leave,
"ret",   	op_ret,
"rep",   	op_rep,
#ifdef SUN_ASM_SYNTAX
"smov",  	op_smov,
#else
"movs",  	op_smov,
#endif
"test",  	op_test,
"fadd",  	op_fadd,
"fsub",  	op_fsub,
"fsubr", 	op_fsubr,
"fmul",  	op_fmul,
"fdiv",  	op_fdiv,
"fdivr", 	op_fdivr,
"fchs",  	op_fchs,
"fld",   	op_fld,
"fild",  	op_fild,
"fst",    	op_fst,
"fstp",       	op_fstp,
"fstp %st(0)",	op_fpop,
"fcompp",     	op_fcompp,
"ftst",       	op_ftst,
"fnstsw",     	op_fnstsw,
"sahf",       	op_sahf,
0, 0
};

out_init()
{
    int i;

    fprintf(output,"\t.file\t\"C386GENERATED\"\n");
    fprintf(output,"\t.version\t\"C386 V 1.0\"\n");
    fprintf(output,"\t.optim\n");
    fputs("c386_compiled.:\n", output);
    curseg = noseg;
    gentype = nogen;
    outcol = 0;
    for (i=0; i<=NUMREG; i++)
        regname[i]="%INVALID_REGISTER";
    regname[EAX]="%eax";
    regname[EBX]="%ebx";
    regname[ECX]="%ecx";
    regname[EDX]="%edx";
    regname[EDI]="%edi";
    regname[ESI]="%esi";
    regname[EBP]="%ebp";
    regname[ESP]="%esp";
    regname[AX] ="%ax";
    regname[BX] ="%bx";
    regname[CX] ="%cx";
    regname[DX] ="%dx";
    regname[DI] = "%di";
    regname[SI] = "%si";
    regname[AL] ="%al";
    regname[BL] ="%bl";
    regname[CL] ="%cl";
    regname[DL] ="%dl";
}

putop(op)
    enum e_op       op;
{
    int             i;
    i = 0;
    while (opl[i].s) {
	if (opl[i].ov == op) {
	    fputs(opl[i].s, output);
	    return;
	}
	++i;
    }
    fatal("illegal opcode");
}

putconst(offset)
/*
 * put a constant to the output file.
 */
    struct enode   *offset;
{

    if (offset == 0)
        fatal("PUTCONST");
    switch (offset->nodetype) {
      case en_autocon:
      case en_icon:
	fprintf(output, "%ld", offset->v.i);
	break;
      case en_labcon:
#ifdef SUN_ASM_SYNTAX
	fprintf(output, ".L%ld", offset->v.i);
#else
	fprintf(output, "L%ld", offset->v.i);
#endif
	break;
      case en_nacon:
	fputs(outlate(offset->v.sp), output);
	break;
      case en_add:
	putconst(offset->v.p[0]);
	putc('+', output);
	putconst(offset->v.p[1]);
	break;
      case en_sub:
	putconst(offset->v.p[0]);
	putc('-', output);
	putconst(offset->v.p[1]);
	break;
      case en_uminus:
	putc('-', output);
	putconst(offset->v.p[0]);
	break;
      case en_cast:
        putconst(offset->v.p[0]);
        break;
      default:
	fatal("illegal constant node");
	break;
    }
}

putlen(l)
/*
 * append the length field to an instruction.
 */
    int             l;
{
    if (l == 0)
	return;
    switch (l) {
      case 1:
	putc('b', output);
	break;
      case 2:
	putc('w', output);
	break;
      case 4:
	putc('l', output);
	break;
      case 5:
        /* special value for single precision float */
        putc('s', output);
        break;
      case 9:
        /* special value for double precision float */
        putc('l', output);
        break;
      default:
	fatal("illegal length field");
	break;
    }
}

putamode(ap,len)
/*
 * output a general addressing mode.
 */
    struct amode   *ap;
{
    int reg;
    switch (ap->mode) {
      case am_immed:
	putc('$', output);
      case am_direct:
	putconst(ap->offset);
	break;
      case am_star:
        putc('*',output);
      case am_reg:
        reg=ap->preg;
        if (len == 1) reg=REG8(reg);
        if (len == 2) reg=REG16(reg);
        fputs (regname[reg], output);
	break;
      case am_indx:
	if (ap->offset != 0)
            putconst(ap->offset);
        fprintf(output,"(%s)",regname[ap->preg]);
	break;
      case am_indx2:
	if (ap->offset != 0)
            putconst(ap->offset);
        fprintf(output,"(%s,%s)",regname[ap->preg],regname[ap->sreg]);
        break;
      default:
	fatal("illegal address mode");
	break;
    }
}

put_code(op, len, aps, apd)
/*
 * output a generic instruction.
 */
    struct amode   *aps, *apd;
    int             len;
    enum e_op       op;
{
    int len1=len, len2=len;
/*
 * this is expensive, but some assemblers require it
 * this is to be moved to the peephole optimizer
 */
    switch(op) {
      case op_movsbw:
      case op_movzbw:
        len2=2;
      case op_movsbl:
      case op_movzbl:
        len1=1;
        break;
      case op_movswl:
      case op_movzwl:
        len1=2;
        break;
    }

    putop(op);
    putlen(len);
/*
 * Sun reverses the INTEL syntax:
 * The source comes first
 * The destination comes second
 * The imul instruction is special (3 operands), this
 * is handled here
 */
    if (aps != 0) {
	putc(' ', output);
	putamode(aps,len1);
	if (apd != 0) {
	    putc(',', output);
	    putamode(apd,len2);
/*
 * Assembler has strange syntax
 */
            if (op == op_imul && aps->mode == am_immed && apd->mode == am_reg) {
                putc(',',output);
                putamode(apd,len2);
            }
	}
    }
    putc('\n', output);
}


g_strlab(s)
/*
 * generate a named label.
 */
    char           *s;
{
    fputs(outlate(s), output);
    putc(':', output);
    putc('\n', output);
}

put_label(lab)
/*
 * output a compiler generated label.
 */
    unsigned int    lab;
{
#ifdef SUN_ASM_SYNTAX
    fprintf(output, ".L%u:\n", lab);
#else
    fprintf(output, "L%u:\n", lab);
#endif
}

genbyte(val)
    int             val;
{
    if (gentype == bytegen && outcol < 60) {
	fprintf(output, ",%d", val & 0x00ff);
	outcol += 4;
    } else {
	nl();
	fprintf(output, "\t.byte %d", val & 0x00ff);
	gentype = bytegen;
	outcol = 19;
    }
}

genword(val)
    int             val;
{
    /* stupid assembler has no .word */
    /* emit low byte, high byte */
    genbyte(val & 255);
    genbyte((val >> 8) & 255);
}

#ifndef NOFLOAT
genfloat(val)
    double          val;
{
    nl();
    fprintf(output,"\t.float %20.15e\n",val);
}

gendouble(val)
    double          val;
{
    nl();
    fprintf(output,"\t.double %20.15e\n",val);
}
#endif

genlong(val)
    long            val;
{
    if (gentype == longgen && outcol < 56) {
	fprintf(output, ",%ld", val);
	outcol += 10;
    } else {
	nl();
	fprintf(output, "\t.long %ld", val);
	gentype = longgen;
	outcol = 25;
    }
}

genptr(node)
    struct enode   *node;
{
    if (gentype == longgen && outcol < 56) {
	putc(',', output);
	putconst(node);
	outcol += 10;
    } else {
	nl();
	fputs("\t.long ", output);
	putconst(node);
	gentype = longgen;
	outcol = 25;
    }
}


genstorage(sp, align)
    struct sym     *sp;
    int             align;
{
    long size = sp->tp->size;
    long remain;
    nl();
/*
 * round up size so that it will fit all needs
 */
    remain = size % AL_DEFAULT;
    if (remain != 0)
        size = size + AL_DEFAULT - remain;
    if (sp->storage_class == sc_static) {
#ifdef SUN_ASM_SYNTAX
	fprintf(output, ".lcomm .L%ld,%ld\n", sp->value.i, size);
#else
	fprintf(output, ".lcomm L%ld,%ld\n", sp->value.i, size);
#endif
        lc_bss += sp->tp->size;
     } else
	fprintf(output, ".comm %s,%ld\n", outlate(sp->name),size);
}


int
stringlit(s, len)
/*
 * mk_ s a string literal and return it's label number.
 */
    char           *s;
    int             len;	/* without \0 */
{
    struct slit    *lp;
    char           *p;
    int             local_global = global_flag;
    global_flag = 0;		/* always allocate from local space. */
    lp = (struct slit *) xalloc((int) sizeof(struct slit));
    lp->label = nextlabel++;
    p = lp->str = (char *) xalloc(len);
    lp->len = len;
    while (len--)
	*p++ = *s++;
    lp->next = strtab;
    strtab = lp;
    global_flag = local_global;
    return lp->label;
}

dumplits()
/*
 * dump the string literal pool.
 */
{
    char           *cp;
    int             len;
    while (strtab != 0) {
	cseg();
	nl();
	put_label((unsigned int) strtab->label);
	cp = strtab->str;
	len = strtab->len;
	while (len--)
	    genbyte(*cp++);
	genbyte(0);
	strtab = strtab->next;
    }
    nl();
}


put_external(s)
    char           *s;
/* put the definition of an external name in the ouput file */
{
    fputs(".globl ", output);
    fputs(outlate(s), output);
    putc('\n', output);
}


put_global(s)
    char           *s;
/* put the definition of a global name in the output file */
{
    put_external(s);
}

put_align(align)
    int             align;
/* align the following data */
{
/*
 * In the default GAS setup, .align n aligns to a boundary of
 * 2**n
 */
    switch (align) {
      case 1:
        break;
      case 2:
#ifdef SUN_ASM_SYNTAX
        fputs("\t.align 2\n",output);
#else
        fputs("\t.align 1\n",output);
#endif
        break;
      case 4:
#ifdef SUN_ASM_SYNTAX
        fputs("\t.align 4\n",output);
#else
        fputs("\t.align 2\n",output);
#endif
        break;
      default:
        fatal("PUT_ALIGN");
    }
}

nl()
{
    if (outcol > 0) {
	putc('\n', output);
	outcol = 0;
	gentype = nogen;
    }
}

cseg()
{
    if (curseg != codeseg) {
	nl();
	fputs("\t.text\n", output);
	curseg = codeseg;
    }
}

dseg()
{
    if (curseg != dataseg) {
	nl();
	fputs("\t.data\n", output);
	curseg = dataseg;
    }
}
#endif /* INTEL_386 */
