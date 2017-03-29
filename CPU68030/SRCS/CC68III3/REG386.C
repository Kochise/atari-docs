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
 * Register allocation (for the expression evaluation)
 * This modules handles the management of scratch registers.
 * It keeps track of the allocated registers and of the stack
 * Although large parts are identical to the 68000 version,
 * the diffs are so big that I maintain two different files
 */

#ifdef INTEL_386

       int      reg_in_use[MAX_REG+1];
static int	next_reg;

#define		MAX_REG_STACK	30

static struct {
    int             reg;
    int             flag;	/* flags if pushed or corresponding reg_alloc
				 * number */
}               reg_stack[MAX_REG_STACK + 1], reg_alloc[MAX_REG_STACK + 1];

static int      reg_stack_ptr;
static int      reg_alloc_ptr;

g_push(reg, number)
/*
 * this routine generates code to push a register onto the stack
 */
    int             reg;
    int             number;
{
    struct amode   *ap;
    ap = (struct amode *) xalloc((int) sizeof(struct amode));
    ap->mode = am_reg;
    ap->preg = reg;
    g_code(op_push, 4, ap, NIL_AMODE);
    reg_stack[reg_stack_ptr].reg = reg;
    reg_stack[reg_stack_ptr].flag = number;
    /* is already pushed */
    if (reg_alloc[number].flag)
	fatal("G_PUSH/1");
    reg_alloc[number].flag = 1;
    /* check on stack overflow */
    if (++reg_stack_ptr > MAX_REG_STACK)
	fatal("G_PUSH/2");
}

g_pop(reg, number)
/*
 * generate code to pop a register from the stack.
 */
    int             reg;
    int             number;
{
    struct amode   *ap;

    /* check on stack underflow */
    if (reg_stack_ptr-- == 0)
	fatal("G_POP/1");
    /* check if the desired register really is on stack */
    if (reg_stack[reg_stack_ptr].flag != number)
	fatal("G_POP/2");
    /* check if the register which is restored is really void */
    if (reg_in_use[reg] >= 0)
	fatal("G_POP/3");
    reg_in_use[reg] = number;
    ap = (struct amode *) xalloc((int) sizeof(struct amode));
    ap->mode = am_reg;
    ap->preg = reg;
    g_code(op_pop, 4, ap, NIL_AMODE);
    /* clear the push_flag */
    reg_alloc[number].flag = 0;
}

initstack()
/*
 * this routine should be called before each expression is evaluated to make
 * sure the stack is balanced and all of the registers are marked free.
 * This is also a good place to free all 'pseudo' registers in the stack frame
 * by clearing act_scratch.
 */
{
    int             i;
    for (i=0; i<= MAX_REG; i++)
        reg_in_use[i]= -1;
    next_reg=0;
    reg_stack_ptr = 0;
    reg_alloc_ptr = 0;
    act_scratch = 0;
}

checkstack()
/*
 * this routine checks if all allocated registers were freed correctly
 */
{
    int i;
    for (i=0; i<= MAX_REG; i++)
        if (reg_in_use[i] != -1)
            fatal("CHECKSTACK/1");
    if (next_reg != 0)
        fatal("CHECKSTACK/2");
    if (reg_stack_ptr != 0)
        fatal("CHECKSTACK/3");
    if (reg_alloc_ptr != 0)
        fatal("CHECKSTACK/4");
}


validate(ap)
/*
 * validate will make sure that if a register within an address mode has been
 * pushed onto the stack that it is popped back at this time.
 */
    struct amode   *ap;
{
    int reg;
    switch (ap->mode) {
      case am_reg:
      case am_indx:
        reg = ap->preg;
	break;
      case am_indx2:
        reg = ap->sreg;
        break;
      default:
        return;
    }
    if (reg > MAX_REG)
        return;
    if (reg_alloc[ap->deep].flag)
        g_pop(reg, (int) ap->deep);
}


struct amode   *
get_register()
/*
 * allocate a register
 */
{
    struct amode *ap;
/*
 * if the register is in use, push it to the stack
 */
    if (reg_in_use[next_reg] >= 0)
        g_push ( next_reg, reg_in_use[next_reg] );
    reg_in_use[next_reg] = reg_alloc_ptr;
    ap = (struct amode *) xalloc((int) sizeof(struct amode));
    ap->mode = am_reg;
    ap->preg = next_reg;
    ap->deep = reg_alloc_ptr;
    reg_alloc[reg_alloc_ptr].reg = next_reg;
    reg_alloc[reg_alloc_ptr].flag = 0;
    ++next_reg;
    if (next_reg > MAX_REG) next_reg=0;
    if (++reg_alloc_ptr >= MAX_REG_STACK)
        fatal("GET_REGISTER");
    return ap;
}

int
uses_temp(ap)
/*
 * tells if an address mode uses a scratch register
 */
    struct amode   *ap;
{
    if (ap == 0)
        fatal ("USES_TEMP");
    switch (ap->mode) {
      case am_reg:
      case am_indx:
        return (ap->preg <= MAX_REG);
      case am_indx2:
        return (ap->sreg <= MAX_REG);
      default:
        return 0;
    }
}

freeop(ap)
/*
 * release any temporary registers used in an addressing mode.
 */
    struct amode   *ap;
{
    int             number;
    int             reg;
    if (ap == 0)
	/* This can happen freeing a NOVALUE result */
	return;
    switch (ap->mode) {
      case am_reg:
      case am_indx:
            reg = ap->preg;
	    break;
      case am_indx2:
            reg = ap->sreg;
            break;
      default:
	return;
    }
    if (reg > MAX_REG)
        return;
    number = reg_in_use[reg];
    reg_in_use[reg] = -1;
    next_reg--;
    if (next_reg < 0) next_reg = MAX_REG;
    /* some consistency checks */
    if (number != ap->deep)
	fatal("FREEOP/1");
    /* we should only free the most recently allocated register */
    if (reg_alloc_ptr-- == 0)
	fatal("FREEOP/2");
    if (reg_alloc_ptr != number)
	fatal("FREEOP/3");
    /* the just freed register should not be on stack */
    if (reg_alloc[number].flag)
	fatal("FREEOP/4");
}

temp_inv()
/*
 * push any used temporary registers.
 * This is necessary across function calls
 * The reason for this hacking is actually that temp_inv should dump
 * the registers in the correct order,
 * the least recently allocate register first.
 * the most recently allocated register last.
 *
 */
{
    int             i;

    for (i = 0; i < reg_alloc_ptr; i++)
	if (reg_alloc[i].flag == 0) {
	    g_push(reg_alloc[i].reg, i);
	    /* mark the register void */
            reg_in_use[reg_alloc[i].reg] = -1;
	}
}
#endif /* INTEL_386 */
