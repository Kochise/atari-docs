|
| Copyright 1991, Christoph van Wuellen
| alloca function for c68
| can handle also __builtin_alloca()
|
	.text

	.globl	_alloca
	.globl ___builtin_alloca

_alloca:
___builtin_alloca:
	movl	sp@+, a0	| return address
	movq	#0, d0
	movw	sp@, d0		| argument (16 bit!)
	addql	#1, d0
	andl	#-2, d0		| align request
	subl	d0, sp		| adjust stack pointer
	movl	sp, d0		| return value
	addql	#2, d0		| adjust for pop-off (16 bit)
	jmp	a0@
