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

#ifdef MC680X0

/* variable initialization */

enum e_gt {
    nogen, bytegen, wordgen, longgen, floatgen
};
enum e_sg {
    noseg, codeseg, dataseg
};


char           *outlate();
#ifndef NOFLOAT
unsigned long   genffp();
#endif

enum e_gt       gentype;
enum e_sg       curseg;
int             outcol;

struct oplst {
    char           *s;
    enum e_op       ov;
}               opl[] =

{{
	"move", op_move
}, {
    "moveq", op_moveq
}, {
    "add", op_add
},
{
    "add", op_addi
}, {
    "addq", op_addq
}, {
    "sub", op_sub
},
{
    "sub", op_subi
}, {
    "subq", op_subq
}, {
    "and", op_and
},
{
    "or", op_or
}, {
    "eor", op_eor
}, {
    "muls", op_muls
},
{
    "divs", op_divs
}, {
    "swap", op_swap
}, {
    "beq", op_beq
},
{
    "bhi", op_bhi
}, {
    "bcc", op_bhs
}, {
    "bcs", op_blo
},
{
    "bls", op_bls
}, {
    "mulu", op_mulu
}, {
    "divu", op_divu
},
{
    "bne", op_bne
}, {
    "blt", op_blt
}, {
    "ble", op_ble
},
{
    "bgt", op_bgt
}, {
    "bge", op_bge
}, {
    "neg", op_neg
},
{
    "not", op_not
}, {
    "cmp", op_cmp
}, {
    "ext", op_ext
},
{
    "jmp", op_jmp
}, {
    "jsr", op_jsr
}, {
    "rts", op_rts
},
{
    "lea", op_lea
}, {
    "asr", op_asr
}, {
    "lsr", op_lsr
}, {
    "asl", op_asl
},
{
    "clr", op_clr
}, {
    "link", op_link
}, {
    "unlk", op_unlk
},
{
    "bra", op_bra
}, {
    "movem", op_movem
}, {
    "pea", op_pea
},
{
    "cmp", op_cmpi
}, {
    "tst", op_tst
}, {
    "dbra", op_dbra
},
{
    0, 0
}
};

out_init()
{
    fputs("#NO_APP\n", output);
    fputs("c68_compiled.:\n", output);
    curseg = noseg;
    gentype = nogen;
    outcol = 0;
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

    switch (offset->nodetype) {
      case en_autocon:
      case en_icon:
	fprintf(output, "%ld", offset->v.i);
	break;
#ifndef NOFLOAT
      case en_fcon:
	fprintf(output, "0x%lx", genffp(offset->v.f));
	break;
#endif
      case en_labcon:
	fprintf(output, "L%ld", offset->v.i);
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
      default:
	fatal("illegal length field");
	break;
    }
}

putamode(ap)
/*
 * output a general addressing mode.
 */
    struct amode   *ap;
{
    switch (ap->mode) {
      case am_immed:
	putc('#', output);
      case am_direct:
	putconst(ap->offset);
	break;
      case am_areg:
	fprintf(output, "a%d", ap->preg);
	break;
      case am_dreg:
	fprintf(output, "d%d", ap->preg);
	break;
      case am_ind:
	fprintf(output, "a%d@", ap->preg);
	break;
      case am_ainc:
	fprintf(output, "a%d@+", ap->preg);
	break;
      case am_adec:
	fprintf(output, "a%d@-", ap->preg);
	break;
      case am_indx:
	fprintf(output, "a%d@(", ap->preg);
	putconst(ap->offset);
	putc(')', output);
	break;
      case am_indx2:
	fprintf(output, "a%d@(", ap->preg);
	putconst(ap->offset);
	fprintf(output, ",d%d:l)", ap->sreg);
	break;
      case am_indx3:
	fprintf(output, "a%d@(", ap->preg);
	putconst(ap->offset);
	fprintf(output, ",a%d:l)", ap->sreg);
	break;
      case am_mask1:
      case am_mask2:
	fprintf(output, "#0x%04x", (int) ap->offset->v.i);
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
    putop(op);
    putlen(len);
    if (aps != 0) {
	putc(' ', output);
	putamode(aps);
	if (apd != 0) {
	    putc(',', output);
	    putamode(apd);
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
    fprintf(output, "L%u:\n", lab);
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
    val &= 0xffff;
    if (gentype == wordgen && outcol < 58) {
	fprintf(output, ",%d", val);
	outcol += 6;
    } else {
	nl();
	fputs("\t.even\n", output);
	fprintf(output, "\t.word %d", val);
	gentype = wordgen;
	outcol = 21;
    }
}

#ifndef NOFLOAT
genfloat(val)
    double          val;
{
    if (gentype == floatgen && outcol < 56) {
	fprintf(output, ",0x%lx", genffp(val));
	outcol += 10;
    } else {
	nl();
	fputs("\t.even\n", output);
	fprintf(output, "\t.long 0x%lx", genffp(val));
	gentype = floatgen;
	outcol = 25;
    }
}

gendouble(val)
    double val;
{
    genfloat(val);
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
	fputs("\t.even\n", output);
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
	fputs("\t.even\n\t.long ", output);
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
	fprintf(output, ".lcomm L%ld,%ld\n", sp->value.i, size);
        lc_bss += sp->tp->size;
     } else
	fprintf(output, ".lcomm %s,%ld\n", outlate(sp->name),size);
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
/*
 * The ACK assembler may produce a .text section of an uneven length.
 * This will eventually bomb the linker when it tries to relocate
 * something in a following (.data) section, which then is misaligned
 * as a whole in memory (perhaps this is just a bug in the linker).
 *
 * To avoid this (it can only happen if the string pool is the last
 * thing dumped to the assembler file) we count the total number of
 * bytes in the string pool and emit a zero filler byte if that
 * number was uneven.
 * This is perhaps an ugly hack, but in virtually all of the cases
 * this filler byte is inserted anyway by the assembler when
 * doing the alignment necessary for the next function body.
 */
    long	    count=0;

    while (strtab != 0) {
	cseg();
	nl();
	put_label((unsigned int) strtab->label);
	cp = strtab->str;
	len = strtab->len;
	count += (len+1);
	while (len--)
	    genbyte(*cp++);
	genbyte(0);
	strtab = strtab->next;
    }
    if (count & 1)
	genbyte(0);
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
    switch (align) {
      case 1:
	break;
      case 2:
	fputs("\n\t.even\n", output);
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

char           *
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

#endif /* MC680X0 */
