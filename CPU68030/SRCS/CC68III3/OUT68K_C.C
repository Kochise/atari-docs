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
    noseg, codeseg, dataseg, bssseg
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
    fputs("* C68-generated assembler output\n", output);
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
	fprintf(output, "$%lx", genffp(offset->v.f));
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
    putc('.', output);
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
	fprintf(output, "(a%d)", ap->preg);
	break;
      case am_ainc:
	fprintf(output, "(a%d)+", ap->preg);
	break;
      case am_adec:
	fprintf(output, "-(a%d)", ap->preg);
	break;
      case am_indx:
	putconst(ap->offset);
	fprintf(output, "(a%d)", ap->preg);
	break;
      case am_indx2:
	putconst(ap->offset);
	fprintf(output, "(a%d,d%d.l)", ap->preg, ap->sreg);
	break;
      case am_indx3:
	putconst(ap->offset);
	fprintf(output, "(a%d,a%d.l)", ap->preg, ap->sreg);
	break;
      case am_mask1:
	put_rmask((int) ap->offset->v.i);
	break;
      case am_mask2:
	put_smask((int) ap->offset->v.i);
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
	putc('\t', output);
	putamode(aps);
	if (apd != 0) {
	    putc(',', output);
	    putamode(apd);
	}
    }
    putc('\n', output);
}

put_rmask(mask)
/*
 * generate a register mask for save.
 */
    int             mask;
{
    int             i, pending;
    pending = 0;
    if ((mask >> 15) & 1) {
	putreg(0);
	pending = 1;
    }
    for (i = 14; i >= 0; i--)
	if ((mask >> i) & 1) {
	    if (pending)
		putc('/', output);
	    putreg(15 - i);
	    pending = 1;
	}
}

put_smask(mask)
/*
 * generate a register mask for save.
 */
    int             mask;
{
    int             i, pending;
    pending = 0;
    if (mask & 1) {
	putreg(0);
	pending = 1;
    }
    for (i = 1; i <= 15; i++)
	if ((mask = mask >> 1) & 1) {
	    if (pending)
		putc('/', output);
	    putreg(i);
	    pending = 1;
	}
}

putreg(r)
/*
 * generate a register name from a tempref number.
 */
    int             r;
{
    if (r < 8)
	fprintf(output, "d%d", r);
    else
	fprintf(output, "a%d", r - 8);
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
	fprintf(output, "dc.b\t%d", val & 0x00ff);
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
	fprintf(output, "dc.w\t%d", val);
	gentype = wordgen;
	outcol = 21;
    }
}

#ifndef NOFLOAT
genfloat(val)
    double          val;
{
    if (gentype == floatgen && outcol < 56) {
	fprintf(output, ",$%lx", genffp(val));
	outcol += 10;
    } else {
	nl();
	fprintf(output, "dc.l\t$%lx", genffp(val));
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
	fprintf(output, "dc.l\t%ld", val);
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
	fputs("dc.l\t", output);
	putconst(node);
	gentype = longgen;
	outcol = 25;
    }
}

genstorage(sp, align)
    struct sym     *sp;
    int             align;
{
    nl();
    bseg();
    put_align(align);
    if (sp->storage_class != sc_static) {
	fputs(outlate(sp->name), output);
	putc(':', output);
	putc('\n', output);
    } else
	fprintf(output, "L%ld:\n", sp->value.i);
    fprintf(output, "ds.b\t%ld\n", sp->tp->size);
    lc_bss += sp->tp->size;
}


int
stringlit(s, len)
/*
 * mk_ s a string literal and return it's label number.
 */
    char           *s;
    int             len;	/* lenght without the \0 at the end */
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
}

put_global(s)
    char           *s;
/* put the definition of a global name in the output file */
{
    fputs(".globl ", output);
    fputs(outlate(s), output);
    putc('\n', output);
}

put_align(align)
    int             align;
/* align the following data */
{
    switch (align) {
      case 1:
	break;
      case 2:
	fputs(".even\n", output);
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
	fputs(".text\n", output);
	curseg = codeseg;
    }
}

dseg()
{
    if (curseg != dataseg) {
	nl();
	fputs(".data\n", output);
	curseg = dataseg;
    }
}

bseg()
{
    if (curseg != bssseg) {
	nl();
	fputs(".bss\n", output);
	curseg = bssseg;
    }
}

/*
 * outlate: translate symbol names before output for CP/M, since external
 * symbols are truncated to eight characters adopt the algorithm used in
 * ,,scanaout''
 */


char           *
outlate(string)
    char           *string;
{
    long            check;
    int             j, k;
    static char     symname[MAX_ID_LEN + 1];

    if (*string == '.')
        return string;
    symname[0] = '_';
    strcpy(symname + 1, string);

    if ((k = strlen(symname)) < 9) {
	if (*string >= 'a' && *string <= 'z' && (!short_option))
	    symname[0] = 'X';
    } else if (trans_option) {
	/*
	 * translate symbol name 140603: prime number smaller than 52**3
	 */
	check = 0;
	for (j = 0; j < k; j++)
	    check = (check + check + symname[j]) % 140603;
	j = check % 52;
	check = check / 52;
	symname[0] = (j < 26) ? 'a' + j : 'A' + j - 26;
	j = check % 52;
	check = check / 52;
	symname[1] = (j < 26) ? 'a' + j : 'A' + j - 26;
	j = check % 52;
	symname[2] = (j < 26) ? 'a' + j : 'A' + j - 26;
	symname[8] = '\0';
    }
    return symname;
}
#endif /* MC680X0 */
