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
 */

#ifdef MC680X0

static int      next_data, next_addr;

static int      dreg_in_use[MAX_DATA + 1];
static int      areg_in_use[MAX_ADDR + 1];

#define		MAX_REG_STACK	30

static struct {
    enum e_am       mode;
    int             reg;
    int             flag;	/* flags if pushed or corresponding reg_alloc
				 * number */
}               reg_stack[MAX_REG_STACK + 1], reg_alloc[MAX_REG_STACK + 1];

static int      reg_stack_ptr;
static int      reg_alloc_ptr;

g_push(reg, rmode, number)
/*
 * this routine generates code to push a register onto the stack
 */
    int             reg;
    enum e_am       rmode;
    int             number;
{
    struct amode   *ap;
    ap = (struct amode *) xalloc((int) sizeof(struct amode));
    ap->preg = reg;
    ap->mode = rmode;
    g_code(op_move, 4, ap, &push);
    reg_stack[reg_stack_ptr].mode = rmode;
    reg_stack[reg_stack_ptr].reg = reg;
    reg_stack[reg_stack_ptr].flag = number;
    if (reg_alloc[number].flag)
	fatal("G_PUSH/1");
    reg_alloc[number].flag = 1;
    /* check on stack overflow */
    if (++reg_stack_ptr > MAX_REG_STACK)
	fatal("G_PUSH/2");
}

g_pop(reg, rmode, number)
/*
 * generate code to pop a register from the stack.
 */
    int             reg;
    enum e_am       rmode;
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
    if (rmode == am_dreg) {
	if (dreg_in_use[reg] >= 0)
	    fatal("G_POP/3");
	dreg_in_use[reg] = number;
    } else {
	if (areg_in_use[reg] >= 0)
	    fatal("G_POP/4");
	areg_in_use[reg] = number;
    }
    ap = (struct amode *) xalloc((int) sizeof(struct amode));
    ap->mode = rmode;
    ap->preg = reg;
    g_code(op_move, 4, &pop, ap);
    /* clear the push_flag */
    reg_alloc[number].flag = 0;
}

initstack()
/*
 * this routine should be called before each expression is evaluated to make
 * sure the stack is balanced and all of the registers are marked free.
 * This is also a good place to free all 'pseudo' registers in the
 * stack frame by setting act_scratch to zero
 */
{
    int             i;
    next_data = 0;
    next_addr = 0;
    for (i = 0; i <= MAX_DATA; i++)
	dreg_in_use[i] = -1;
    for (i = 0; i <= MAX_ADDR; i++)
	areg_in_use[i] = -1;
    reg_stack_ptr = 0;
    reg_alloc_ptr = 0;
    act_scratch = 0;
}

checkstack()
/*
 * this routines checks if all allocated registers were freed
 */
{
    int i;
    for (i=0; i<= MAX_DATA; i++)
        if (dreg_in_use[i] != -1)
            fatal("CHECKSTACK/1");
    for (i=0; i<= MAX_ADDR; i++)
        if (areg_in_use[i] != -1)
            fatal("CHECKSTACK/2");
    if (next_data != 0)
        fatal("CHECKSTACK/3");
    if (next_addr != 0)
        fatal("CHECKSTACK/4");
    if (reg_stack_ptr != 0)
        fatal("CHECKSTACK/5");
    if (reg_alloc_ptr != 0)
        fatal("CHECKSTACK/6");
}

validate(ap)
/*
 * validate will make sure that if a register within an address mode has been
 * pushed onto the stack that it is popped back at this time.
 */
    struct amode   *ap;
{
    switch (ap->mode) {
      case am_dreg:
	if (ap->preg <= MAX_DATA && reg_alloc[ap->deep].flag) {
	    g_pop(ap->preg, am_dreg, (int) ap->deep);
	}
	break;
      case am_indx2:
	if (ap->sreg <= MAX_DATA && reg_alloc[ap->deep].flag) {
	    g_pop(ap->sreg, am_dreg, (int) ap->deep);
	}
	goto common;
      case am_indx3:
	if (ap->sreg <= MAX_ADDR && reg_alloc[ap->deep].flag) {
	    g_pop(ap->sreg, am_areg, (int) ap->deep);
	}
	goto common;
      case am_areg:
      case am_ind:
      case am_indx:
      case am_ainc:
      case am_adec:
common:
	if (ap->preg <= MAX_ADDR && reg_alloc[ap->deep].flag) {
	    g_pop(ap->preg, am_areg, (int) ap->deep);
	}
	break;
    }
}

struct amode   *
temp_data()
/*
 * allocate a temporary data register and return it's addressing mode.
 */
{
    struct amode   *ap;
    ap = (struct amode *) xalloc((int) sizeof(struct amode));
    if (dreg_in_use[next_data] >= 0)
	/*
	 * The next available register is already in use. it must be pushed
	 */
	g_push(next_data, am_dreg, dreg_in_use[next_data]);
    dreg_in_use[next_data] = reg_alloc_ptr;
    ap->mode = am_dreg;
    ap->preg = next_data;
    ap->deep = reg_alloc_ptr;
    reg_alloc[reg_alloc_ptr].reg = next_data;
    reg_alloc[reg_alloc_ptr].mode = am_dreg;
    reg_alloc[reg_alloc_ptr].flag = 0;
    if (next_data++ == MAX_DATA)
	next_data = 0;		/* wrap around */
    if (reg_alloc_ptr++ == MAX_REG_STACK)
	fatal("TEMP_DATA");
    return ap;
}

struct amode   *
temp_addr()
/*
 * allocate a temporary addr register and return it's addressing mode.
 */
{
    struct amode   *ap;
    ap = (struct amode *) xalloc((int) sizeof(struct amode));
    if (areg_in_use[next_addr] >= 0)
	/*
	 * The next available register is already in use. it must be pushed
	 */
	g_push(next_addr, am_areg, areg_in_use[next_addr]);
    areg_in_use[next_addr] = reg_alloc_ptr;
    ap->mode = am_areg;
    ap->preg = next_addr;
    ap->deep = reg_alloc_ptr;
    reg_alloc[reg_alloc_ptr].reg = next_addr;
    reg_alloc[reg_alloc_ptr].mode = am_areg;
    reg_alloc[reg_alloc_ptr].flag = 0;
    if (next_addr++ == MAX_ADDR)
	next_addr = 0;		/* wrap around */
    if (reg_alloc_ptr++ == MAX_REG_STACK)
	fatal("TEMP_ADDR");
    return ap;
}

free_data()
/*
 * returns TRUE if a data register is available at ,,no cost'' (no push).
 * Used to determine e.g. wether cmp.w #0,An or move.l An,Dm is better
 */
{
    return (dreg_in_use[next_data] < 0);
}

freeop(ap)
/*
 * release any temporary registers used in an addressing mode.
 */
    struct amode   *ap;
{
    int             number;
    if (ap == 0)
	/* This can happen freeing a NOVALUE result */
	return;
    switch (ap->mode) {
      case am_dreg:
	if (ap->preg <= MAX_DATA) {
	    if (next_data-- == 0)
		next_data = MAX_DATA;
	    number = dreg_in_use[ap->preg];
	    dreg_in_use[ap->preg] = -1;
	    break;
	}
	return;
      case am_indx2:
	if (ap->sreg <= MAX_DATA) {
	    if (next_data-- == 0)
		next_data = MAX_DATA;
	    number = dreg_in_use[ap->sreg];
	    dreg_in_use[ap->sreg] = -1;
	    break;
	}
	goto common;
      case am_indx3:
	if (ap->sreg <= MAX_ADDR) {
	    if (next_addr-- == 0)
		next_addr = MAX_ADDR;
	    number = areg_in_use[ap->sreg];
	    areg_in_use[ap->sreg] = -1;
	    break;
	}
	goto common;
      case am_areg:
      case am_ind:
      case am_indx:
      case am_ainc:
      case am_adec:
common:
	if (ap->preg <= MAX_ADDR) {
	    if (next_addr-- == 0)
		next_addr = MAX_ADDR;
	    number = areg_in_use[ap->preg];
	    areg_in_use[ap->preg] = -1;
	    break;
	}
	return;
      default:
	return;
    }
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
	    g_push(reg_alloc[i].reg, reg_alloc[i].mode, i);
	    /* mark the register void */
	    if (reg_alloc[i].mode == am_dreg)
		dreg_in_use[reg_alloc[i].reg] = -1;
	    else
		areg_in_use[reg_alloc[i].reg] = -1;
	}
}
#endif /* MC680X0 */
