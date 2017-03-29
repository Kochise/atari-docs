	.file "alloca.s"
	.optim
	.text
alloca:
__builtin_alloca:
	popl	%ecx
	movl	(%esp),%eax
	addl	$3,%eax
	andl	$-4,%eax
	subl	%eax,%esp
	movl	%esp,%eax
	addl	$4,%eax
	jmp	*%ecx
.globl alloca
.globl __builtin_alloca
