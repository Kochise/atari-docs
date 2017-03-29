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

/* addressing modes */

#ifdef MC680X0
#define F_DREG	1		/* data register direct mode allowed */
#define F_AREG	2		/* address register direct mode allowed */
#define F_MEM	4		/* memory alterable modes allowed */
#define F_IMMED 8		/* immediate mode allowed */
#define F_ALT	7		/* alterable modes */
#define F_DALT	5		/* data alterable modes */
#define F_ALL	15		/* all modes allowed */
#define F_VOL	16		/* need volitile operand */
#define F_NOVALUE 32		/* dont need result value */
#define F_USES	  64		/* need result value more than once */
 /* this forbids autoincrement modes */
#endif /* MC680X0 */

#ifdef INTEL_386
#define F_REG	    1		/* a register, like %eax, %edi etc. */
#define F_MEM       2		/* direct, indirect, indexed */
#define F_IMMED     4           /* immedate */
#define F_FPSTACK   8           /* top of floating-point stack */
#define F_NOVALUE  16           /* dont need result value */
#define F_VOL      32		/* need scratch register */
#define F_ALL      15		/* any mode */
#define F_NOEDI    64           /* do not use %edi and %esi */
#endif /* INTEL_386 */

/* The instructions */

/*
 * The order of the branch instructions must not be changed
 * since array revcond[] in the peephole optimizer relies on
 * them.
 */
#ifdef MC680X0
enum e_op {
    op_move, op_moveq, op_add, op_addi, op_addq, op_sub, op_subi,
    op_subq, op_muls, op_mulu, op_divs, op_divu, op_and, op_andi,
    op_or, op_ori, op_eor, op_asl, op_lsr, op_jmp, op_jsr, op_movem,
    op_rts, op_bra, op_beq, op_bne, op_blt, op_ble, op_bgt, op_bge,
    op_bhi, op_bhs, op_blo, op_bls, op_tst, op_ext, op_lea, op_swap,
    op_neg, op_not, op_cmp, op_clr, op_link, op_unlk, op_label,
    op_pea, op_cmpi, op_dbra, op_asr
};
#endif

#ifdef INTEL_386
enum e_op {
    op_movsbl, op_movzbl, op_movswl, op_movzwl,
    op_movsbw, op_movzbw,
    op_cltd,
    op_mov, op_lea,
    op_not, op_neg,
    op_add, op_sub, op_imul, op_idiv,
    op_and, op_or, op_xor,
    op_inc, op_dec,
    op_cmp,
    op_push, op_pop,
    op_jmp, op_bra, op_call, op_leave, op_ret,
    op_test,
    op_je, op_jne,
    op_jl, op_jle, op_jg, op_jge,
    op_ja, op_jae, op_jb, op_jbe,
    op_rep, op_smov,
    op_shl, op_shr, op_asr,
    op_fadd, op_fsub, op_fdiv, op_fmul,
    op_fsubr, op_fdivr,
    op_fld, op_fst, op_fstp, op_fpop,
    op_fild, op_ftst,
    op_fchs, op_fcompp, op_fnstsw, op_sahf,
    op_label
};
#endif

#ifdef MC680X0
enum e_am {
    am_dreg, am_areg, am_ind, am_ainc, am_adec, am_indx, am_indx2,
    am_direct, am_immed, am_mask1, am_mask2,
    am_none, am_indx3
};
#endif

#ifdef INTEL_386
enum e_am {
    am_reg, am_indx, am_indx2, am_direct, am_immed, am_star, am_fpstack
};
#endif

/* addressing mode structure */

struct amode {
    enum e_am       mode;
    struct enode   *offset;
/*
 * these chars may be unsigned...
 */
    char            preg, sreg;
    char   	    deep;
};

#define NIL_AMODE ( (struct amode *) 0)

/* output code structure */

struct ocode {
    enum e_op       opcode;
    struct amode   *oper1, *oper2;
    struct ocode   *fwd, *back;
    int             length;
};

/* register naming, special registers */

#ifdef MC680X0
#define RESULT	  0		/* register returning function results */
#define FRAMEPTR  14		/* frame pointer register */
#define STACKPTR  15		/* system stack pointer register */
#endif /* MC680X0 */

#ifdef INTEL_386
#define RESULT		0       /* reg ret. integer-type function results */
#define EAX		0
#define EDX		1
#define EBX		2
#define ECX		3
#define ESI		4
#define EDI		5
#define ESP		6
#define STACKPTR	6       /* system stack pointer */
#define EBP		7       /* frame pointer */
#define FRAMEPTR	7
/* attention: same order as above */
#define	AX		8
#define DX		9
#define BX		10
#define CX		11
#define SI		12
#define DI		13
/* attention: same order as above */
#define AL		14
#define DL		15
#define BL		16
#define CL		17

#define NUMREG		REG8(EBP)

/*
 * The code generator does not distinguish between %eax, %ax, %al
 * because some assemblers want it strict, the real register names
 * are determined when the assembly instruction is PRINTED, e.g.
 * code generator produces movb junk,%eax,
 * assembly code printer prints movb junk,%al
 * The conversion is done by the following macros
 */
#define REG16(X) ((X)-EAX+AX)
#define REG8(X)  ((X)-EAX+AL)
#endif

#ifdef MC680X0
#define MAX_ADDR 1		/* max. scratch address register (A1) */
#define MAX_DATA 2		/* max. scratch data	register (D2) */
#endif
#ifdef INTEL_386
#define MAX_REG  1		/* scratch registers: %eax..%edx */
#endif

struct amode   *g_expr();
struct amode   *mk_reg();
#ifdef MC680X0
struct amode   *temp_data();
struct amode   *temp_addr();
#endif
#ifdef INTEL_386
struct amode   *get_register();
#endif
struct amode   *mk_offset();
struct amode   *g_cast();
struct amode   *g_fcall();
struct amode   *func_result();
struct amode   *as_fcall();
#ifdef MC68000
struct amode   *mk_rmask();
struct amode   *mk_smask();
#endif
struct amode   *mk_label();
struct amode   *mk_strlab();
struct amode   *mk_immed();
struct amode   *g_offset();
struct amode   *mk_legal();
struct amode   *copy_addr();
