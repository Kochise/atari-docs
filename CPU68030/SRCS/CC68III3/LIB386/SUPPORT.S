	.file	"support.s"
	.optim
/
/ The floatingpoint stack
/
.lcomm stack, 1024
/
/ The stackpointer
/
	.data
	.align 4
stackptr:
	.long stack+ 992
        .align 4
.L16:	.double	4.294967296e9
/
/ Note that there is a small 'safety zone'
/ Due to this safety zone, it seems sufficient for me to check
/ for stack under/overflows only on fpld and fpst instructions
/ At the moment, stack checks are not yet implemented
/
stack_low = stack  +  32
stack_high = stack + 992
/
	.text
supp387_softstack:
	.align 4
	.globl	.fpldi
.fpldi:
        movl    %ecx,-4(%esp)
	fildl	-4(%esp)
	movl	stackptr,%ecx
	subl	$8,%ecx
	fstpl	(%ecx)
	movl	%ecx,stackptr
        ret
	.align 4
	.globl	.fpldu
.fpldu:
        movl    %ecx,-4(%esp)
	fildl	-4(%esp)
	testl	%ecx,%ecx
	jge	.L12
	faddl	.L16
.L12:
	movl	stackptr,%ecx
	subl	$8,%ecx
	fstpl	(%ecx)
	movl	%ecx,stackptr
        ret
	.align 4
	.globl	.fpsti
.fpsti:
	pushl	%ebp
	movl	%esp,%ebp
	subl	$12,%esp
	fstcw	-4(%ebp)
	movw	-4(%ebp),%cx
	orw	$0x0c00,%cx
	movw	%cx,-2(%ebp)
	fldcw	-2(%ebp)
	movl	stackptr,%ecx
	fldl	(%ecx)
	addl	$8,%ecx
	movl	%ecx,stackptr
	fistpl	-12(%ebp)
	fldcw	-4(%ebp)
	movl	-12(%ebp),%ecx
	leave	
	ret	
	.align 4
	.globl .fptst
.fptst:
	movl	stackptr,%ecx
	fldl	(%ecx)
	addl	$8,%ecx
	movl	%ecx,stackptr
	movl	%eax,%ecx
	ftst
	fnstsw	%ax
	fstp	%st(0)
	sahf
	je	is_zero
	movl	%ecx,%eax
	movl	$1,%ecx
	ret
is_zero:
	movl	%ecx,%eax
	xorl	%ecx,%ecx
	ret
	.align 4
	.globl .fplds
.fplds:
	flds	(%ecx)
	movl	stackptr,%ecx
	subl	$8,%ecx
	fstpl	(%ecx)
	movl	%ecx,stackptr
	ret
	.align 4
	.globl .fpldl
.fpldl:
	fldl	(%ecx)
	movl	stackptr,%ecx
	subl	$8,%ecx
	fstpl	(%ecx)
	movl	%ecx,stackptr
	ret
	.align 4
	.globl .fpsts
.fpsts:
	pushl	%ecx
	movl	stackptr,%ecx
	fldl	(%ecx)
	popl	%ecx
	fstps	(%ecx)
	ret
	.align 4
	.globl .fpstps
.fpstps:
	pushl	%ecx
	movl	stackptr,%ecx
	fldl	(%ecx)
	addl	$8,%ecx
	movl	%ecx,stackptr
	popl	%ecx
	fstps	(%ecx)
	ret
	.align 4
	.globl .fpstl
.fpstl:
	pushl	%ecx
	movl	stackptr,%ecx
	fldl	(%ecx)
	popl	%ecx
	fstpl	(%ecx)
	ret
	.align 4
	.globl .fpstpl
.fpstpl:
	pushl	%ecx
	movl	stackptr,%ecx
	fldl	(%ecx)
	addl	$8,%ecx
	movl	%ecx,stackptr
	popl	%ecx
	fstpl	(%ecx)
	ret
	.align 4
	.globl .fpcmp
.fpcmp:
	movl	stackptr,%ecx
	fldl	8(%ecx)
	fldl	(%ecx)
	addl	$16,%ecx
	movl	%ecx,stackptr
	movl %eax,%ecx
	fcompp
	fnstsw %ax
	sahf
	je   is_zero
	ja   is_big
is_small:
	movl %ecx,%eax
	movl $-1,%ecx
	ret
is_big:
	movl %ecx,%eax
	movl $1,%ecx
	ret
	.align 4
	.globl .fppop
.fppop:
	addl	$8,stackptr
	ret
	.align 4
	.globl .fpadd
.fpadd:
	movl	stackptr,%ecx
	fldl	(%ecx)
	addl	$8,%ecx
	fldl	(%ecx)
	fadd
	movl	%ecx,stackptr
	fstpl	(%ecx)
	ret
	.align 4
	.globl .fpsubr
.fpsubr:
	movl	stackptr,%ecx
	fldl	(%ecx)
	addl	$8,%ecx
	fldl	(%ecx)
	fsub
	movl	%ecx,stackptr
	fstpl	(%ecx)
	ret
	.align 4
	.globl .fpsub
.fpsub:
	movl	stackptr,%ecx
	fldl	(%ecx)
	addl	$8,%ecx
	fldl	(%ecx)
	fsubr
	movl	%ecx,stackptr
	fstpl	(%ecx)
	ret
	.align 4
	.globl .fpdivr
.fpdivr:
	movl	stackptr,%ecx
	fldl	(%ecx)
	addl	$8,%ecx
	fldl	(%ecx)
	fdiv
	movl	%ecx,stackptr
	fstpl	(%ecx)
	ret
	.align 4
	.globl .fpdiv
.fpdiv:
	movl	stackptr,%ecx
	fldl	(%ecx)
	addl	$8,%ecx
	fldl	(%ecx)
	fdivr
	movl	%ecx,stackptr
	fstpl	(%ecx)
	ret
	.align 4
	.globl .fpmult
.fpmult:
	movl	stackptr,%ecx
	fldl	(%ecx)
	addl	$8,%ecx
	fldl	(%ecx)
	fmul
	movl	%ecx,stackptr
	fstpl	(%ecx)
	ret
	.align 4
	.globl .fpneg
.fpneg:
	movl	stackptr,%ecx
	fldl	(%ecx)
	fchs
	fstpl	(%ecx)
	ret
	.align 4
	.globl	.fpputstack
.fpputstack:
	movl	stackptr,%ecx
	subl	$8,%ecx
	fstpl	(%ecx)
	movl	%ecx,stackptr
	ret
	.align 4
	.globl	.fpgetstack
.fpgetstack:
	movl	stackptr,%ecx
	fldl	(%ecx)
	addl	$8,%ecx
	movl	%ecx,stackptr
	ret
/
/ what follows are support function that directly operate on the
/ 80387 hardware stack -- they are called even if FPU inline code
/ is generated otherwise
/
	.align 4
	.globl	..fldu
..fldu:
        movl    %ecx,-4(%esp)
	fildl	-4(%esp)
	testl	%ecx,%ecx
	jge	.L13
	faddl	.L16
.L13:
        ret
	.align 4
	.globl	..fsti
..fsti:
	pushl	%ebp
	movl	%esp,%ebp
	subl	$12,%esp
	fstcw	-4(%ebp)
	movw	-4(%ebp),%cx
	orw	$0x0c00,%cx
	movw	%cx,-2(%ebp)
	fldcw	-2(%ebp)
	fistpl	-12(%ebp)
	fldcw	-4(%ebp)
	movl	-12(%ebp),%ecx
	leave	
	ret	
