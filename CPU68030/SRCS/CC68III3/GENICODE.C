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

/*
 * This module performs a symbolic dump of the parse tree
 */
#ifdef ICODE

static char    *
type(node)
    struct enode   *node;
{
    switch (node->etype) {
      case bt_char:
	return ("char");
      case bt_uchar:
	return ("unsigned char");
      case bt_short:
	return ("short");
      case bt_ushort:
	return ("unsigned short");
      case bt_long:
	return ("long");
      case bt_ulong:
	return ("unsigned long");
      case bt_pointer:
	return ("pointer");
      case bt_struct:
      case bt_union:
	return ("struct/union");
      case bt_func:
	return ("function");
      case bt_double:
        return ("double");
      case bt_float:
	return ("float");
      case bt_void:
	return ("void");
      default:
	fatal("type: unknown");
    }
    /* NOTREACHED */
}

g_icode(node)
/*
 * general expression evaluation. symbolic dump.
 */
    struct enode   *node;
{
    if (node == 0) {
	fatal("null node in g_icode");
	fprintf(icode, "*NULL\n");
	return 0;
    }
#define gen0 g_icode(node->v.p[0])
#define gen1 g_icode(node->v.p[1])
#define typ  type(node)
#define size node->esize

    switch (node->nodetype) {
      case en_icon:
	fprintf(icode, "*icon %s %ld %ld\n", typ, size, node->v.i);
	break;
      case en_labcon:
	fprintf(icode, "*labcon %s %ld L%ld\n",
		typ, size, node->v.i);
	break;
      case en_nacon:
	fprintf(icode, "*nacon %s %ld %s\n", typ, size,
		node->v.sp);
	break;
      case en_fcon:
#ifdef NOFLOAT
        fprintf(icode, "*fcon <NOFLOAT>\n");
#endif
#ifndef NOFLOAT
	fprintf(icode, "*fcon %20.10lf\n", node->v.f);
#endif
	break;
      case en_autocon:
	fprintf(icode, "*autocon %s %ld %ld\n", typ, size, node->v.i);
	break;
      case en_ref:
	fprintf(icode, "*ref %s %ld\n", typ, size);
	gen0;
	break;
      case en_fieldref:
	fprintf(icode, "*fref %s %ld (%d,%d)\n", typ, size,
		node->bit_offset, node->bit_width);
	gen0;
	break;
      case en_tempref:
	fprintf(icode, "*tempref %s %ld", typ, size);
	if (node->v.i < 8)
	    fprintf(icode, " D%ld\n", node->v.i);
	else
	    fprintf(icode, " A%ld\n", node->v.i - 8);
	break;
      case en_uminus:
	fprintf(icode, "*uminus %s %ld\n", typ, size);
	gen0;
	break;
      case en_compl:
	fprintf(icode, "*compl %s %ld\n", typ, size);
	gen0;
	break;
      case en_add:
	fprintf(icode, "*add %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_sub:
	fprintf(icode, "*sub %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_and:
	fprintf(icode, "*and %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_or:
	fprintf(icode, "*or %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_xor:
	fprintf(icode, "*xor %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_mul:
	fprintf(icode, "*mul %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_div:
	fprintf(icode, "*div %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_mod:
	fprintf(icode, "*mod %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_lsh:
	fprintf(icode, "*lsh %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_rsh:
	fprintf(icode, "*rsh %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_asadd:
	fprintf(icode, "*asadd %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_assub:
	fprintf(icode, "*assub %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_asand:
	fprintf(icode, "*asand %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_asor:
	fprintf(icode, "*asor %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_aslsh:
	fprintf(icode, "*aslsh %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_asrsh:
	fprintf(icode, "*asrsh %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_asmul:
	fprintf(icode, "*asmul %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_asdiv:
	fprintf(icode, "*asdiv %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_asmod:
	fprintf(icode, "*asmod %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_assign:
	fprintf(icode, "*assign %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_ainc:
	fprintf(icode, "*ainc %s %ld value=%ld\n",
		typ, size, node->v.p[1]->v.i);
	gen0;
	break;
      case en_adec:
	fprintf(icode, "*adec %s %ld value=%ld\n",
		typ, size, node->v.p[1]->v.i);
	gen0;
	break;
      case en_land:
	fprintf(icode, "*land\n");
	gen0;
	gen1;
	break;
      case en_lor:
	fprintf(icode, "*lor\n");
	gen0;
	gen1;
	break;
      case en_eq:
	fprintf(icode, "*eq %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_ne:
	fprintf(icode, "*ne %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_lt:
	fprintf(icode, "*lt %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_le:
	fprintf(icode, "*le %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_gt:
	fprintf(icode, "*gt %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_ge:
	fprintf(icode, "*ge %s %ld\n", typ, size);
	gen0;
	gen1;
	break;
      case en_not:
	fprintf(icode, "*not %s %ld\n", typ, size);
	gen0;
	break;
      case en_cond:
	fprintf(icode, "*cond %s %ld\n", typ, size);
	gen0;
	node = node->v.p[1];
	gen0;
	gen1;
	break;
      case en_void:
	fprintf(icode, "*void %s %ld\n", typ, size);
	gen0;
	if (node->v.p[1] != 0)
	    gen1;
	else
	    fprintf(icode, "*null\n");
	break;
      case en_fcall:
	fprintf(icode, "*fcall %s %ld\n", typ, size);
	gen0;
	if (node->v.p[1] != 0)
	    gen1;
	else
	    fprintf(icode, "*null\n");
	break;
      case en_cast:
	fprintf(icode, "*cast %s %ld\n", typ, size);
	gen0;
	break;
      case en_deref:
	fprintf(icode, "*deref %s %ld\n", typ, size);
	gen0;
	break;
      default:
	fatal("uncoded node in g_icode");
    }
    return 0;
}

#endif
