	.file	"vm.c"
	.comm	_stack_data,131072,32
	.globl	spTop
	.data
	.align 8
	.type	spTop, @object
	.size	spTop, 8
spTop:
	.quad	_stack_data+131072
	.comm	sp,8,8
	.comm	_stack_return,8192,32
	.globl	rspTop
	.align 8
	.type	rspTop, @object
	.size	rspTop, 8
rspTop:
	.quad	_stack_return+8192
	.comm	rsp,8,8
	.comm	ip,8,8
	.comm	cfa,8,8
	.comm	ca,8,8
	.globl	firstQuit
	.type	firstQuit, @object
	.size	firstQuit, 1
firstQuit:
	.byte	1
	.globl	quitTop
	.bss
	.align 8
	.type	quitTop, @object
	.size	quitTop, 8
quitTop:
	.zero	8
	.globl	quitTopPtr
	.data
	.align 8
	.type	quitTopPtr, @object
	.size	quitTopPtr, 8
quitTopPtr:
	.quad	quitTop
	.comm	dsp,8,8
	.comm	state,8,8
	.comm	base,8,8
	.comm	dictionary,8,8
	.comm	lastWord,8,8
	.comm	parseBuffers,8192,32
	.comm	inputSources,1024,32
	.comm	inputIndex,8,8
	.comm	c1,8,8
	.comm	c2,8,8
	.comm	c3,8,8
	.comm	ch1,1,1
	.comm	str1,8,8
	.comm	strptr1,8,8
	.comm	tempSize,8,8
	.comm	tempHeader,8,8
	.comm	tempBuf,256,32
	.comm	numBuf,16,16
	.comm	tempFile,8,8
	.comm	tempStat,144,32
	.comm	quit_inner,8,8
	.comm	timeVal,16,16
	.comm	i64,8,8
	.comm	old_tio,60,32
	.comm	new_tio,60,32
	.globl	primitive_count
	.align 4
	.type	primitive_count, @object
	.size	primitive_count, 4
primitive_count:
	.long	107
	.globl	queue
	.bss
	.align 8
	.type	queue, @object
	.size	queue, 8
queue:
	.zero	8
	.globl	queueTail
	.align 8
	.type	queueTail, @object
	.size	queueTail, 8
queueTail:
	.zero	8
	.comm	tempQueue,8,8
	.comm	queueSource,160,32
	.globl	next_queue_source
	.align 4
	.type	next_queue_source, @object
	.size	next_queue_source, 4
next_queue_source:
	.zero	4
	.globl	queue_length
	.align 4
	.type	queue_length, @object
	.size	queue_length, 4
queue_length:
	.zero	4
	.comm	primitives,4096,32
	.comm	superinstructions,4096,32
	.globl	nextSuperinstruction
	.align 4
	.type	nextSuperinstruction, @object
	.size	nextSuperinstruction, 4
nextSuperinstruction:
	.zero	4
	.comm	key1,4,4
	.section	.rodata
.LC0:
	.string	"%s"
	.text
	.globl	print
	.type	print, @function
print:
.LFB2:
	.cfi_startproc
	subq	$24, %rsp
	.cfi_def_cfa_offset 32
	movq	%rdi, 8(%rsp)
	movq	%rsi, (%rsp)
	movq	(%rsp), %rax
	addq	$1, %rax
	movq	%rax, %rdi
	call	malloc
	movq	%rax, str1(%rip)
	movq	(%rsp), %rdx
	movq	8(%rsp), %rax
	movq	%rax, %rsi
	movq	str1(%rip), %rdi
	call	strncpy
	movq	str1(%rip), %rdx
	movq	(%rsp), %rax
	addq	%rdx, %rax
	movb	$0, (%rax)
	movq	str1(%rip), %rsi
	movl	$.LC0, %edi
	movl	$0, %eax
	call	printf
	movq	str1(%rip), %rdi
	call	free
	nop
	addq	$24, %rsp
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE2:
	.size	print, .-print
	.globl	header_plus
	.section	.rodata
.LC1:
	.string	"+"
	.data
	.align 32
	.type	header_plus, @object
	.size	header_plus, 32
header_plus:
	.quad	0
	.quad	1
	.quad	.LC1
	.quad	code_plus
	.globl	key_plus
	.align 4
	.type	key_plus, @object
	.size	key_plus, 4
key_plus:
	.long	1
	.text
	.globl	code_plus
	.type	code_plus, @function
code_plus:
.LFB3:
	.cfi_startproc
	movq	sp(%rip), %rax
        movq    (%rax), %rbx
	addq	$8, %rax
	movq	(%rax), %rcx
	addq	%rcx, %rbx
	movq	%rbx, (%rax)
	addq	$8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE3:
	.size	code_plus, .-code_plus
	.globl	header_minus
	.section	.rodata
.LC2:
	.string	"-"
	.data
	.align 32
	.type	header_minus, @object
	.size	header_minus, 32
header_minus:
	.quad	header_plus
	.quad	1
	.quad	.LC2
	.quad	code_minus
	.globl	key_minus
	.align 4
	.type	key_minus, @object
	.size	key_minus, 4
key_minus:
	.long	2
	.text
	.globl	code_minus
	.type	code_minus, @function
code_minus:
.LFB4:
	.cfi_startproc
	movq	sp(%rip), %rdx
        movq    (%rdx), %rbx
	addq	$8, %rdx
	movq	(%rdx), %rax
	subq	%rbx, %rax
	movq	%rax, (%rdx)
	addq	$8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE4:
	.size	code_minus, .-code_minus
	.globl	header_times
	.section	.rodata
.LC3:
	.string	"*"
	.data
	.align 32
	.type	header_times, @object
	.size	header_times, 32
header_times:
	.quad	header_minus
	.quad	1
	.quad	.LC3
	.quad	code_times
	.globl	key_times
	.align 4
	.type	key_times, @object
	.size	key_times, 4
key_times:
	.long	3
	.text
	.globl	code_times
	.type	code_times, @function
code_times:
.LFB5:
	.cfi_startproc
	movq	sp(%rip), %rax
        movq    (%rax), %rbx
	addq	$8, %rax
	movq	(%rax), %rcx
	imulq	%rcx, %rbx
	movq	%rbx, (%rax)
	addq	$8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE5:
	.size	code_times, .-code_times
	.globl	header_div
	.section	.rodata
.LC4:
	.string	"/"
	.data
	.align 32
	.type	header_div, @object
	.size	header_div, 32
header_div:
	.quad	header_times
	.quad	1
	.quad	.LC4
	.quad	code_div
	.globl	key_div
	.align 4
	.type	key_div, @object
	.size	key_div, 4
key_div:
	.long	4
	.text
	.globl	code_div
	.type	code_div, @function
code_div:
.LFB6:
	.cfi_startproc
	movq	sp(%rip), %rax
	leaq	8(%rax), %rcx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rsi
	cqto
	idivq	%rsi
	movq	%rax, (%rcx)
	addq	$8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE6:
	.size	code_div, .-code_div
	.globl	header_udiv
	.section	.rodata
.LC5:
	.string	"U/"
	.data
	.align 32
	.type	header_udiv, @object
	.size	header_udiv, 32
header_udiv:
	.quad	header_div
	.quad	2
	.quad	.LC5
	.quad	code_udiv
	.globl	key_udiv
	.align 4
	.type	key_udiv, @object
	.size	key_udiv, 4
key_udiv:
	.long	5
	.text
	.globl	code_udiv
	.type	code_udiv, @function
code_udiv:
.LFB7:
	.cfi_startproc
	movq	sp(%rip), %rax
	leaq	8(%rax), %rcx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movq	%rax, %rdx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, %rsi
	movq	%rdx, %rax
	movl	$0, %edx
	divq	%rsi
	movq	%rax, (%rcx)
	addq	$8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE7:
	.size	code_udiv, .-code_udiv
	.globl	header_mod
	.section	.rodata
.LC6:
	.string	"MOD"
	.data
	.align 32
	.type	header_mod, @object
	.size	header_mod, 32
header_mod:
	.quad	header_udiv
	.quad	3
	.quad	.LC6
	.quad	code_mod
	.globl	key_mod
	.align 4
	.type	key_mod, @object
	.size	key_mod, 4
key_mod:
	.long	6
	.text
	.globl	code_mod
	.type	code_mod, @function
code_mod:
.LFB8:
	.cfi_startproc
	movq	sp(%rip), %rax
	leaq	8(%rax), %rcx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rsi
	cqto
	idivq	%rsi
	movq	%rdx, %rax
	movq	%rax, (%rcx)
	addq	$8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE8:
	.size	code_mod, .-code_mod
	.globl	header_umod
	.section	.rodata
.LC7:
	.string	"UMOD"
	.data
	.align 32
	.type	header_umod, @object
	.size	header_umod, 32
header_umod:
	.quad	header_mod
	.quad	4
	.quad	.LC7
	.quad	code_umod
	.globl	key_umod
	.align 4
	.type	key_umod, @object
	.size	key_umod, 4
key_umod:
	.long	7
	.text
	.globl	code_umod
	.type	code_umod, @function
code_umod:
.LFB9:
	.cfi_startproc
	movq	sp(%rip), %rax
	leaq	8(%rax), %rcx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movq	%rax, %rdx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, %rsi
	movq	%rdx, %rax
	movl	$0, %edx
	divq	%rsi
	movq	%rdx, %rax
	movq	%rax, (%rcx)
	addq	$8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE9:
	.size	code_umod, .-code_umod
	.globl	header_and
	.section	.rodata
.LC8:
	.string	"AND"
	.data
	.align 32
	.type	header_and, @object
	.size	header_and, 32
header_and:
	.quad	header_umod
	.quad	3
	.quad	.LC8
	.quad	code_and
	.globl	key_and
	.align 4
	.type	key_and, @object
	.size	key_and, 4
key_and:
	.long	8
	.text
	.globl	code_and
	.type	code_and, @function
code_and:
.LFB10:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	(%rax), %rbx
	addq	$8, %rax
	movq	(%rax), %rcx
	andq	%rcx, %rbx
	movq	%rbx, (%rax)
	addq	$8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE10:
	.size	code_and, .-code_and
	.globl	header_or
	.section	.rodata
.LC9:
	.string	"OR"
	.data
	.align 32
	.type	header_or, @object
	.size	header_or, 32
header_or:
	.quad	header_and
	.quad	2
	.quad	.LC9
	.quad	code_or
	.globl	key_or
	.align 4
	.type	key_or, @object
	.size	key_or, 4
key_or:
	.long	9
	.text
	.globl	code_or
	.type	code_or, @function
code_or:
.LFB11:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	(%rax), %rbx
	addq	$8, %rax
	movq	(%rax), %rcx
	orq	%rcx, %rbx
	movq	%rbx, (%rax)
	addq	$8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE11:
	.size	code_or, .-code_or
	.globl	header_xor
	.section	.rodata
.LC10:
	.string	"XOR"
	.data
	.align 32
	.type	header_xor, @object
	.size	header_xor, 32
header_xor:
	.quad	header_or
	.quad	3
	.quad	.LC10
	.quad	code_xor
	.globl	key_xor
	.align 4
	.type	key_xor, @object
	.size	key_xor, 4
key_xor:
	.long	10
	.text
	.globl	code_xor
	.type	code_xor, @function
code_xor:
.LFB12:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	(%rax), %rbx
	addq	$8, %rax
	movq	(%rax), %rcx
	xorq	%rcx, %rbx
	movq	%rbx, (%rax)
	addq	$8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE12:
	.size	code_xor, .-code_xor
	.globl	header_lshift
	.section	.rodata
.LC11:
	.string	"LSHIFT"
	.data
	.align 32
	.type	header_lshift, @object
	.size	header_lshift, 32
header_lshift:
	.quad	header_xor
	.quad	6
	.quad	.LC11
	.quad	code_lshift
	.globl	key_lshift
	.align 4
	.type	key_lshift, @object
	.size	key_lshift, 4
key_lshift:
	.long	11
	.text
	.globl	code_lshift
	.type	code_lshift, @function
code_lshift:
.LFB13:
	.cfi_startproc
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movq	%rax, %rsi
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movl	%eax, %ecx
	salq	%cl, %rsi
	movq	%rsi, %rax
	movq	%rax, (%rdx)
	addq	$8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE13:
	.size	code_lshift, .-code_lshift
	.globl	header_rshift
	.section	.rodata
.LC12:
	.string	"RSHIFT"
	.data
	.align 32
	.type	header_rshift, @object
	.size	header_rshift, 32
header_rshift:
	.quad	header_lshift
	.quad	6
	.quad	.LC12
	.quad	code_rshift
	.globl	key_rshift
	.align 4
	.type	key_rshift, @object
	.size	key_rshift, 4
key_rshift:
	.long	12
	.text
	.globl	code_rshift
	.type	code_rshift, @function
code_rshift:
.LFB14:
	.cfi_startproc
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movq	%rax, %rsi
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movl	%eax, %ecx
	shrq	%cl, %rsi
	movq	%rsi, %rax
	movq	%rax, (%rdx)
	addq	$8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE14:
	.size	code_rshift, .-code_rshift
	.globl	header_base
	.section	.rodata
.LC13:
	.string	"BASE"
	.data
	.align 32
	.type	header_base, @object
	.size	header_base, 32
header_base:
	.quad	header_rshift
	.quad	4
	.quad	.LC13
	.quad	code_base
	.globl	key_base
	.align 4
	.type	key_base, @object
	.size	key_base, 4
key_base:
	.long	13
	.text
	.globl	code_base
	.type	code_base, @function
code_base:
.LFB15:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movl	$base, %edx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE15:
	.size	code_base, .-code_base
	.globl	header_less_than
	.section	.rodata
.LC14:
	.string	"<"
	.data
	.align 32
	.type	header_less_than, @object
	.size	header_less_than, 32
header_less_than:
	.quad	header_base
	.quad	1
	.quad	.LC14
	.quad	code_less_than
	.globl	key_less_than
	.align 4
	.type	key_less_than, @object
	.size	key_less_than, 4
key_less_than:
	.long	14
	.text
	.globl	code_less_than
	.type	code_less_than, @function
code_less_than:
.LFB16:
	.cfi_startproc
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rcx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	cmpq	%rax, %rcx
	jge	.L17
	movq	$-1, %rax
	jmp	.L18
.L17:
	movl	$0, %eax
.L18:
	movq	%rax, (%rdx)
	addq	$8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE16:
	.size	code_less_than, .-code_less_than
	.globl	header_less_than_unsigned
	.section	.rodata
.LC15:
	.string	"U<"
	.data
	.align 32
	.type	header_less_than_unsigned, @object
	.size	header_less_than_unsigned, 32
header_less_than_unsigned:
	.quad	header_less_than
	.quad	2
	.quad	.LC15
	.quad	code_less_than_unsigned
	.globl	key_less_than_unsigned
	.align 4
	.type	key_less_than_unsigned, @object
	.size	key_less_than_unsigned, 4
key_less_than_unsigned:
	.long	15
	.text
	.globl	code_less_than_unsigned
	.type	code_less_than_unsigned, @function
code_less_than_unsigned:
.LFB17:
	.cfi_startproc
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movq	%rax, %rcx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	cmpq	%rax, %rcx
	jnb	.L20
	movq	$-1, %rax
	jmp	.L21
.L20:
	movl	$0, %eax
.L21:
	movq	%rax, (%rdx)
	addq	$8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE17:
	.size	code_less_than_unsigned, .-code_less_than_unsigned
	.globl	header_equal
	.section	.rodata
.LC16:
	.string	"="
	.data
	.align 32
	.type	header_equal, @object
	.size	header_equal, 32
header_equal:
	.quad	header_less_than_unsigned
	.quad	1
	.quad	.LC16
	.quad	code_equal
	.globl	key_equal
	.align 4
	.type	key_equal, @object
	.size	key_equal, 4
key_equal:
	.long	16
	.text
	.globl	code_equal
	.type	code_equal, @function
code_equal:
.LFB18:
	.cfi_startproc
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	sp(%rip), %rax
	movq	(%rax), %rcx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	cmpq	%rax, %rcx
	jne	.L23
	movq	$-1, %rax
	jmp	.L24
.L23:
	movl	$0, %eax
.L24:
	movq	%rax, (%rdx)
	addq	$8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE18:
	.size	code_equal, .-code_equal
	.globl	header_dup
	.section	.rodata
.LC17:
	.string	"DUP"
	.data
	.align 32
	.type	header_dup, @object
	.size	header_dup, 32
header_dup:
	.quad	header_equal
	.quad	3
	.quad	.LC17
	.quad	code_dup
	.globl	key_dup
	.align 4
	.type	key_dup, @object
	.size	key_dup, 4
key_dup:
	.long	17
	.text
	.globl	code_dup
	.type	code_dup, @function
code_dup:
.LFB19:
	.cfi_startproc
	subq	$8, sp(%rip)
	movq	sp(%rip), %rdx
	movq	8(%rdx), %rax
	movq	%rax, (%rdx)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE19:
	.size	code_dup, .-code_dup
	.globl	header_swap
	.section	.rodata
.LC18:
	.string	"SWAP"
	.data
	.align 32
	.type	header_swap, @object
	.size	header_swap, 32
header_swap:
	.quad	header_dup
	.quad	4
	.quad	.LC18
	.quad	code_swap
	.globl	key_swap
	.align 4
	.type	key_swap, @object
	.size	key_swap, 4
key_swap:
	.long	18
	.text
	.globl	code_swap
	.type	code_swap, @function
code_swap:
.LFB20:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	(%rax), %rbx
	movq	8(%rax), %rcx
	movq	%rbx, 8(%rax)
	movq	%rcx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE20:
	.size	code_swap, .-code_swap
	.globl	header_drop
	.section	.rodata
.LC19:
	.string	"DROP"
	.data
	.align 32
	.type	header_drop, @object
	.size	header_drop, 32
header_drop:
	.quad	header_swap
	.quad	4
	.quad	.LC19
	.quad	code_drop
	.globl	key_drop
	.align 4
	.type	key_drop, @object
	.size	key_drop, 4
key_drop:
	.long	19
	.text
	.globl	code_drop
	.type	code_drop, @function
code_drop:
.LFB21:
	.cfi_startproc
	addq	$8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE21:
	.size	code_drop, .-code_drop
	.globl	header_over
	.section	.rodata
.LC20:
	.string	"OVER"
	.data
	.align 32
	.type	header_over, @object
	.size	header_over, 32
header_over:
	.quad	header_drop
	.quad	4
	.quad	.LC20
	.quad	code_over
	.globl	key_over
	.align 4
	.type	key_over, @object
	.size	key_over, 4
key_over:
	.long	20
	.text
	.globl	code_over
	.type	code_over, @function
code_over:
.LFB22:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	8(%rax), %rbx
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	%rbx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE22:
	.size	code_over, .-code_over
	.globl	header_rot
	.section	.rodata
.LC21:
	.string	"ROT"
	.data
	.align 32
	.type	header_rot, @object
	.size	header_rot, 32
header_rot:
	.quad	header_over
	.quad	3
	.quad	.LC21
	.quad	code_rot
	.globl	key_rot
	.align 4
	.type	key_rot, @object
	.size	key_rot, 4
key_rot:
	.long	21
	.text
	.globl	code_rot
	.type	code_rot, @function
code_rot:
.LFB23:
	.cfi_startproc
	movq	sp(%rip), %rax # ( b c d -- c d b )
	movq	16(%rax), %rbx
	movq	8(%rax), %rcx
	movq	(%rax), %rdx
        movq    %rcx, 16(%rax)
        movq    %rdx, 8(%rax)
        movq    %rbx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE23:
	.size	code_rot, .-code_rot
	.globl	header_neg_rot
	.section	.rodata
.LC22:
	.string	"-ROT"
	.data
	.align 32
	.type	header_neg_rot, @object
	.size	header_neg_rot, 32
header_neg_rot:
	.quad	header_rot
	.quad	4
	.quad	.LC22
	.quad	code_neg_rot
	.globl	key_neg_rot
	.align 4
	.type	key_neg_rot, @object
	.size	key_neg_rot, 4
key_neg_rot:
	.long	22
	.text
	.globl	code_neg_rot
	.type	code_neg_rot, @function
code_neg_rot:
.LFB24:
	.cfi_startproc
	movq	sp(%rip), %rax # ( b c d -- d b c )
	movq	16(%rax), %rbx
	movq	8(%rax), %rcx
	movq	(%rax), %rdx
	movq	%rdx, 16(%rax)
	movq	%rbx, 8(%rax)
	movq	%rcx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE24:
	.size	code_neg_rot, .-code_neg_rot
	.globl	header_two_drop
	.section	.rodata
.LC23:
	.string	"2DROP"
	.data
	.align 32
	.type	header_two_drop, @object
	.size	header_two_drop, 32
header_two_drop:
	.quad	header_neg_rot
	.quad	5
	.quad	.LC23
	.quad	code_two_drop
	.globl	key_two_drop
	.align 4
	.type	key_two_drop, @object
	.size	key_two_drop, 4
key_two_drop:
	.long	23
	.text
	.globl	code_two_drop
	.type	code_two_drop, @function
code_two_drop:
.LFB25:
	.cfi_startproc
	addq	$16, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE25:
	.size	code_two_drop, .-code_two_drop
	.globl	header_two_dup
	.section	.rodata
.LC24:
	.string	"2DUP"
	.data
	.align 32
	.type	header_two_dup, @object
	.size	header_two_dup, 32
header_two_dup:
	.quad	header_two_drop
	.quad	4
	.quad	.LC24
	.quad	code_two_dup
	.globl	key_two_dup
	.align 4
	.type	key_two_dup, @object
	.size	key_two_dup, 4
key_two_dup:
	.long	24
	.text
	.globl	code_two_dup
	.type	code_two_dup, @function
code_two_dup:
.LFB26:
	.cfi_startproc
	subq	$16, sp(%rip)
	movq	sp(%rip), %rax
        movq    16(%rax), %rbx
        movq    %rbx, (%rax)
        movq    24(%rax), %rbx
        movq    %rbx, 8(%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE26:
	.size	code_two_dup, .-code_two_dup
	.globl	header_two_swap
	.section	.rodata
.LC25:
	.string	"2SWAP"
	.data
	.align 32
	.type	header_two_swap, @object
	.size	header_two_swap, 32
header_two_swap:
	.quad	header_two_dup
	.quad	5
	.quad	.LC25
	.quad	code_two_swap
	.globl	key_two_swap
	.align 4
	.type	key_two_swap, @object
	.size	key_two_swap, 4
key_two_swap:
	.long	25
	.text
	.globl	code_two_swap
	.type	code_two_swap, @function
code_two_swap:
.LFB27:
	.cfi_startproc
	movq	sp(%rip), %rax # swap in pairs: 0/16, 8/24
        # First pair, 0/16
	movq	16(%rax), %rbx
	movq	(%rax), %rcx
        movq    %rcx, 16(%rax)
        movq    %rbx, (%rax)
        # Second pair, 8/24
	movq	24(%rax), %rbx
	movq	8(%rax), %rcx
        movq    %rcx, 24(%rax)
        movq    %rbx, 8(%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE27:
	.size	code_two_swap, .-code_two_swap
	.globl	header_two_over
	.section	.rodata
.LC26:
	.string	"2OVER"
	.data
	.align 32
	.type	header_two_over, @object
	.size	header_two_over, 32
header_two_over:
	.quad	header_two_swap
	.quad	5
	.quad	.LC26
	.quad	code_two_over
	.globl	key_two_over
	.align 4
	.type	key_two_over, @object
	.size	key_two_over, 4
key_two_over:
	.long	26
	.text
	.globl	code_two_over
	.type	code_two_over, @function
code_two_over:
.LFB28:
	.cfi_startproc
	subq	$16, sp(%rip)
	movq	sp(%rip), %rax
	movq	32(%rax), %rbx
        movq    %rbx, (%rax)
	movq	40(%rax), %rbx
        movq    %rbx, 8(%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE28:
	.size	code_two_over, .-code_two_over
	.globl	header_to_r
	.section	.rodata
.LC27:
	.string	">R"
	.data
	.align 32
	.type	header_to_r, @object
	.size	header_to_r, 32
header_to_r:
	.quad	header_two_over
	.quad	2
	.quad	.LC27
	.quad	code_to_r
	.globl	key_to_r
	.align 4
	.type	key_to_r, @object
	.size	key_to_r, 4
key_to_r:
	.long	27
	.text
	.globl	code_to_r
	.type	code_to_r, @function
code_to_r:
.LFB29:
	.cfi_startproc
	movq	rsp(%rip), %rax
	subq	$8, %rax
	movq	%rax, rsp(%rip)
	movq	sp(%rip), %rbx
        movq    (%rbx), %rcx
        movq    %rcx, (%rax)
        addq    $8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE29:
	.size	code_to_r, .-code_to_r
	.globl	header_from_r
	.section	.rodata
.LC28:
	.string	"R>"
	.data
	.align 32
	.type	header_from_r, @object
	.size	header_from_r, 32
header_from_r:
	.quad	header_to_r
	.quad	2
	.quad	.LC28
	.quad	code_from_r
	.globl	key_from_r
	.align 4
	.type	key_from_r, @object
	.size	key_from_r, 4
key_from_r:
	.long	28
	.text
	.globl	code_from_r
	.type	code_from_r, @function
code_from_r:
.LFB30:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	rsp(%rip), %rbx
        movq    (%rbx), %rbx
	movq	%rbx, (%rax)
        addq    $8, rsp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE30:
	.size	code_from_r, .-code_from_r
	.globl	header_fetch
	.section	.rodata
.LC29:
	.string	"@"
	.data
	.align 32
	.type	header_fetch, @object
	.size	header_fetch, 32
header_fetch:
	.quad	header_from_r
	.quad	1
	.quad	.LC29
	.quad	code_fetch
	.globl	key_fetch
	.align 4
	.type	key_fetch, @object
	.size	key_fetch, 4
key_fetch:
	.long	29
	.text
	.globl	code_fetch
	.type	code_fetch, @function
code_fetch:
.LFB31:
	.cfi_startproc
	movq	sp(%rip), %rdx
	movq	(%rdx), %rax
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE31:
	.size	code_fetch, .-code_fetch
	.globl	header_store
	.section	.rodata
.LC30:
	.string	"!"
	.data
	.align 32
	.type	header_store, @object
	.size	header_store, 32
header_store:
	.quad	header_fetch
	.quad	1
	.quad	.LC30
	.quad	code_store
	.globl	key_store
	.align 4
	.type	key_store, @object
	.size	key_store, 4
key_store:
	.long	30
	.text
	.globl	code_store
	.type	code_store, @function
code_store:
.LFB32:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	(%rax), %rbx
	movq	8(%rax), %rcx
	movq	%rcx, (%rbx)
	addq	$16, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE32:
	.size	code_store, .-code_store
	.globl	header_cfetch
	.section	.rodata
.LC31:
	.string	"C@"
	.data
	.align 32
	.type	header_cfetch, @object
	.size	header_cfetch, 32
header_cfetch:
	.quad	header_store
	.quad	2
	.quad	.LC31
	.quad	code_cfetch
	.globl	key_cfetch
	.align 4
	.type	key_cfetch, @object
	.size	key_cfetch, 4
key_cfetch:
	.long	31
	.text
	.globl	code_cfetch
	.type	code_cfetch, @function
code_cfetch:
.LFB33:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rdx
	movzbl	(%rdx), %edx
	movzbl	%dl, %edx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE33:
	.size	code_cfetch, .-code_cfetch
	.globl	header_cstore
	.section	.rodata
.LC32:
	.string	"C!"
	.data
	.align 32
	.type	header_cstore, @object
	.size	header_cstore, 32
header_cstore:
	.quad	header_cfetch
	.quad	2
	.quad	.LC32
	.quad	code_cstore
	.globl	key_cstore
	.align 4
	.type	key_cstore, @object
	.size	key_cstore, 4
key_cstore:
	.long	32
	.text
	.globl	code_cstore
	.type	code_cstore, @function
code_cstore:
.LFB34:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, %rdx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movb	%al, (%rdx)
	addq	$16, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE34:
	.size	code_cstore, .-code_cstore
	.globl	header_raw_alloc
	.section	.rodata
.LC33:
	.string	"(ALLOCATE)"
	.data
	.align 32
	.type	header_raw_alloc, @object
	.size	header_raw_alloc, 32
header_raw_alloc:
	.quad	header_cstore
	.quad	10
	.quad	.LC33
	.quad	code_raw_alloc
	.globl	key_raw_alloc
	.align 4
	.type	key_raw_alloc, @object
	.size	key_raw_alloc, 4
key_raw_alloc:
	.long	33
	.text
	.globl	code_raw_alloc
	.type	code_raw_alloc, @function
code_raw_alloc:
.LFB35:
	.cfi_startproc
	movq	sp(%rip), %rbx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, %rdi
	call	malloc
	movq	%rax, (%rbx)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE35:
	.size	code_raw_alloc, .-code_raw_alloc
	.globl	header_here_ptr
	.section	.rodata
.LC34:
	.string	"(>HERE)"
	.data
	.align 32
	.type	header_here_ptr, @object
	.size	header_here_ptr, 32
header_here_ptr:
	.quad	header_raw_alloc
	.quad	7
	.quad	.LC34
	.quad	code_here_ptr
	.globl	key_here_ptr
	.align 4
	.type	key_here_ptr, @object
	.size	key_here_ptr, 4
key_here_ptr:
	.long	34
	.text
	.globl	code_here_ptr
	.type	code_here_ptr, @function
code_here_ptr:
.LFB36:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movl	$dsp, %edx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE36:
	.size	code_here_ptr, .-code_here_ptr
	.globl	header_print_internal
	.section	.rodata
.LC35:
	.string	"(PRINT)"
	.data
	.align 32
	.type	header_print_internal, @object
	.size	header_print_internal, 32
header_print_internal:
	.quad	header_here_ptr
	.quad	7
	.quad	.LC35
	.quad	code_print_internal
	.globl	key_print_internal
	.align 4
	.type	key_print_internal, @object
	.size	key_print_internal, 4
key_print_internal:
	.long	35
	.section	.rodata
.LC36:
	.string	"%ld "
	.text
	.globl	code_print_internal
	.type	code_print_internal, @function
code_print_internal:
.LFB37:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	(%rax), %rsi
	movl	$.LC36, %edi
	movl	$0, %eax
	call	printf
	addq	$8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE37:
	.size	code_print_internal, .-code_print_internal
	.globl	header_state
	.section	.rodata
.LC37:
	.string	"STATE"
	.data
	.align 32
	.type	header_state, @object
	.size	header_state, 32
header_state:
	.quad	header_print_internal
	.quad	5
	.quad	.LC37
	.quad	code_state
	.globl	key_state
	.align 4
	.type	key_state, @object
	.size	key_state, 4
key_state:
	.long	36
	.text
	.globl	code_state
	.type	code_state, @function
code_state:
.LFB38:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movl	$state, %edx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE38:
	.size	code_state, .-code_state
	.globl	header_branch
	.section	.rodata
.LC38:
	.string	"(BRANCH)"
	.data
	.align 32
	.type	header_branch, @object
	.size	header_branch, 32
header_branch:
	.quad	header_state
	.quad	8
	.quad	.LC38
	.quad	code_branch
	.globl	key_branch
	.align 4
	.type	key_branch, @object
	.size	key_branch, 4
key_branch:
	.long	37
	.text
	.globl	code_branch
	.type	code_branch, @function
code_branch:
.LFB39:
	.cfi_startproc
	movq	ip(%rip), %rax
        movq    (%rax), %rbx
        addq    %rbx, %rax
        movq    %rax, ip(%rip)
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE39:
	.size	code_branch, .-code_branch
	.globl	header_zbranch
	.section	.rodata
.LC39:
	.string	"(0BRANCH)"
	.data
	.align 32
	.type	header_zbranch, @object
	.size	header_zbranch, 32
header_zbranch:
	.quad	header_branch
	.quad	9
	.quad	.LC39
	.quad	code_zbranch
	.globl	key_zbranch
	.align 4
	.type	key_zbranch, @object
	.size	key_zbranch, 4
key_zbranch:
	.long	38
	.text
	.globl	code_zbranch
	.type	code_zbranch, @function
code_zbranch:
.LFB40:
	.cfi_startproc
	movq	sp(%rip), %rbx
        movq    (%rbx), %rbx   # rbx = TOS
        addq    $8, sp(%rip)
	testq	%rbx, %rbx
	jne	.L49
	movq	ip(%rip), %rax
	movq	(%rax), %rax
	jmp	.L50
.L49:
	movl	$8, %eax
.L50:
        # Either way when we get down here, rax contains the delta.
	movq	ip(%rip), %rbx
        addq    %rbx, %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE40:
	.size	code_zbranch, .-code_zbranch
	.globl	header_execute
	.section	.rodata
.LC40:
	.string	"EXECUTE"
	.data
	.align 32
	.type	header_execute, @object
	.size	header_execute, 32
header_execute:
	.quad	header_zbranch
	.quad	7
	.quad	.LC40
	.quad	code_execute
	.globl	key_execute
	.align 4
	.type	key_execute, @object
	.size	key_execute, 4
key_execute:
	.long	39
	.text
	.globl	code_execute
	.type	code_execute, @function
code_execute:
.LFB41:
	.cfi_startproc
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, sp(%rip)
	movq	(%rax), %rax
	movq	%rax, cfa(%rip)
	movq	cfa(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, ca(%rip)
	jmp	*ca(%rip)
	.cfi_endproc
.LFE41:
	.size	code_execute, .-code_execute
	.globl	header_evaluate
	.section	.rodata
.LC41:
	.string	"EVALUATE"
	.data
	.align 32
	.type	header_evaluate, @object
	.size	header_evaluate, 32
header_evaluate:
	.quad	header_execute
	.quad	8
	.quad	.LC41
	.quad	code_evaluate
	.globl	key_evaluate
	.align 4
	.type	key_evaluate, @object
	.size	key_evaluate, 4
key_evaluate:
	.long	40
	.text
	.globl	code_evaluate
	.type	code_evaluate, @function
code_evaluate:
.LFB42:
	.cfi_startproc
	addq	$1, inputIndex(%rip)
	movq	inputIndex(%rip), %rdx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	salq	$5, %rdx
	addq	$inputSources, %rdx
	movq	%rax, (%rdx)
	movq	inputIndex(%rip), %rax
	movq	sp(%rip), %rdx
	addq	$8, %rdx
	movq	(%rdx), %rdx
	salq	$5, %rax
	addq	$inputSources+24, %rax
	movq	%rdx, (%rax)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+16, %rax
	movq	$-1, (%rax)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	$0, (%rax)
	addq	$16, sp(%rip)
	movq	rsp(%rip), %rax
	subq	$8, %rax
	movq	%rax, rsp(%rip)
	movq	rsp(%rip), %rax
	movq	ip(%rip), %rdx
	movq	%rdx, (%rax)
	jmp	*quit_inner(%rip)
	.cfi_endproc
.LFE42:
	.size	code_evaluate, .-code_evaluate
	.section	.rodata
.LC42:
	.string	"> "
	.text
	.globl	refill_
	.type	refill_, @function
refill_:
.LFB43:
	.cfi_startproc
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+16, %rax
	movq	(%rax), %rax
	cmpq	$-1, %rax
	jne	.L54
	subq	$1, inputIndex(%rip)
	movq	rsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, rsp(%rip)
	movq	(%rax), %rax
	movq	%rax, ip(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
.L54:
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset 3, -16
	subq	$16, %rsp
	.cfi_def_cfa_offset 32
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+16, %rax
	movq	(%rax), %rax
	testq	%rax, %rax
	jne	.L55
	movl	$.LC42, %edi
	call	readline
	movq	%rax, str1(%rip)
	movq	inputIndex(%rip), %rbx
	movq	str1(%rip), %rdi
	call	strlen
	movq	%rax, %rdx
	movq	%rbx, %rax
	salq	$5, %rax
	addq	$inputSources, %rax
	movq	%rdx, (%rax)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources, %rax
	movq	(%rax), %rax
	movq	inputIndex(%rip), %rdx
	salq	$5, %rdx
	leaq	inputSources+24(%rdx), %rcx
	movq	%rax, %rdx
	movq	str1(%rip), %rsi
	movq	(%rcx), %rdi
	call	strncpy
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	$0, (%rax)
	movq	str1(%rip), %rdi
	call	free
	movq	$-1, %rax
	jmp	.L56
.L55:
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+16, %rax
	movq	(%rax), %rax
	andl	$1, %eax
	testq	%rax, %rax
	je	.L57
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+16, %rax
	movq	(%rax), %rax
	andq	$-2, %rax
	movq	%rax, 8(%rsp)
	movq	8(%rsp), %rax
	movq	(%rax), %rdx
	movq	8(%rsp), %rax
	movq	8(%rax), %rax
	cmpq	%rax, %rdx
	jb	.L58
	subq	$1, inputIndex(%rip)
	movl	$0, %eax
	jmp	.L56
.L58:
	movq	8(%rsp), %rax
	movq	(%rax), %rax
	movq	%rax, str1(%rip)
	jmp	.L59
.L61:
	addq	$1, str1(%rip)
.L59:
	movq	8(%rsp), %rax
	movq	8(%rax), %rdx
	movq	str1(%rip), %rax
	cmpq	%rax, %rdx
	jbe	.L60
	movq	str1(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$10, %al
	jne	.L61
.L60:
	movq	inputIndex(%rip), %rcx
	movq	8(%rsp), %rax
	movq	(%rax), %rax
	movq	str1(%rip), %rdx
	subq	%rax, %rdx
	movq	%rcx, %rax
	salq	$5, %rax
	addq	$inputSources, %rax
	movq	%rdx, (%rax)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources, %rax
	movq	(%rax), %rdx
	movq	8(%rsp), %rax
	movq	(%rax), %rax
	movq	inputIndex(%rip), %rcx
	salq	$5, %rcx
	addq	$inputSources+24, %rcx
	movq	%rax, %rsi
	movq	(%rcx), %rdi
	call	strncpy
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	$0, (%rax)
	movq	8(%rsp), %rax
	movq	8(%rax), %rdx
	movq	str1(%rip), %rax
	cmpq	%rax, %rdx
	jbe	.L62
	movq	str1(%rip), %rax
	addq	$1, %rax
	jmp	.L63
.L62:
	movq	8(%rsp), %rax
	movq	8(%rax), %rax
.L63:
	movq	8(%rsp), %rdx
	movq	%rax, (%rdx)
	movq	$-1, %rax
	jmp	.L56
.L57:
	movq	$0, str1(%rip)
	movq	$0, tempSize(%rip)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+16, %rax
	movq	(%rax), %rax
	movq	%rax, %rdx
	movl	$tempSize, %esi
	movl	$str1, %edi
	call	getline
	movq	%rax, c1(%rip)
	movq	c1(%rip), %rax
	cmpq	$-1, %rax
	jne	.L64
	subq	$1, inputIndex(%rip)
	movl	$0, %eax
	jmp	.L56
.L64:
	movq	str1(%rip), %rdx
	movq	c1(%rip), %rax
	addq	%rdx, %rax
	subq	$1, %rax
	movzbl	(%rax), %eax
	cmpb	$10, %al
	jne	.L65
	subq	$1, c1(%rip)
.L65:
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+24, %rax
	movq	c1(%rip), %rdx
	movq	str1(%rip), %rsi
	movq	(%rax), %rdi
	call	strncpy
	movq	str1(%rip), %rdi
	call	free
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	leaq	inputSources(%rax), %rdx
	movq	c1(%rip), %rax
	movq	%rax, (%rdx)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	$0, (%rax)
	movq	$-1, %rax
.L56:
	addq	$16, %rsp
	.cfi_def_cfa_offset 16
	popq	%rbx
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE43:
	.size	refill_, .-refill_
	.globl	header_refill
	.section	.rodata
.LC43:
	.string	"REFILL"
	.data
	.align 32
	.type	header_refill, @object
	.size	header_refill, 32
header_refill:
	.quad	header_evaluate
	.quad	6
	.quad	.LC43
	.quad	code_refill
	.globl	key_refill
	.align 4
	.type	key_refill, @object
	.size	key_refill, 4
key_refill:
	.long	41
	.text
	.globl	code_refill
	.type	code_refill, @function
code_refill:
.LFB44:
	.cfi_startproc
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+16, %rax
	movq	(%rax), %rax
	cmpq	$-1, %rax
	jne	.L69
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movq	$0, (%rax)
	jmp	.L70
.L69:
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rbx
	call	refill_
	movq	%rax, (%rbx)
.L70:
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE44:
	.size	code_refill, .-code_refill
	.globl	header_accept
	.section	.rodata
.LC44:
	.string	"ACCEPT"
	.data
	.align 32
	.type	header_accept, @object
	.size	header_accept, 32
header_accept:
	.quad	header_refill
	.quad	6
	.quad	.LC44
	.quad	code_accept
	.globl	key_accept
	.align 4
	.type	key_accept, @object
	.size	key_accept, 4
key_accept:
	.long	42
	.text
	.globl	code_accept
	.type	code_accept, @function
code_accept:
.LFB45:
	.cfi_startproc
	movl	$0, %edi
	call	readline
	movq	%rax, str1(%rip)
	movq	str1(%rip), %rdi
	call	strlen
	movq	%rax, c1(%rip)
	movq	sp(%rip), %rax
	movq	(%rax), %rdx
	movq	c1(%rip), %rax
	cmpq	%rax, %rdx
	jge	.L73
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, c1(%rip)
.L73:
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movq	c1(%rip), %rdx
	movq	str1(%rip), %rsi
	movq	%rax, %rdi
	call	strncpy
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	c1(%rip), %rax
	movq	%rax, (%rdx)
	addq	$8, sp(%rip)
	movq	str1(%rip), %rdi
	call	free
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE45:
	.size	code_accept, .-code_accept
	.globl	header_key
	.section	.rodata
.LC45:
	.string	"KEY"
	.data
	.align 32
	.type	header_key, @object
	.size	header_key, 32
header_key:
	.quad	header_accept
	.quad	3
	.quad	.LC45
	.quad	code_key
	.globl	key_key
	.align 4
	.type	key_key, @object
	.size	key_key, 4
key_key:
	.long	43
	.text
	.globl	code_key
	.type	code_key, @function
code_key:
.LFB46:
	.cfi_startproc
	movl	$old_tio, %esi
	movl	$0, %edi
	call	tcgetattr
	movq	old_tio(%rip), %rax
	movq	%rax, new_tio(%rip)
	movq	old_tio+8(%rip), %rax
	movq	%rax, new_tio+8(%rip)
	movq	old_tio+16(%rip), %rax
	movq	%rax, new_tio+16(%rip)
	movq	old_tio+24(%rip), %rax
	movq	%rax, new_tio+24(%rip)
	movq	old_tio+32(%rip), %rax
	movq	%rax, new_tio+32(%rip)
	movq	old_tio+40(%rip), %rax
	movq	%rax, new_tio+40(%rip)
	movq	old_tio+48(%rip), %rax
	movq	%rax, new_tio+48(%rip)
	movl	old_tio+56(%rip), %eax
	movl	%eax, new_tio+56(%rip)
	andl	$-11, new_tio+12(%rip)
	movl	$new_tio, %edx
	movl	$0, %esi
	movl	$0, %edi
	call	tcsetattr
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rbx
	call	getchar
	cltq
	movq	%rax, (%rbx)
	movl	$old_tio, %edx
	movl	$0, %esi
	movl	$0, %edi
	call	tcsetattr
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE46:
	.size	code_key, .-code_key
	.globl	header_latest
	.section	.rodata
.LC46:
	.string	"(LATEST)"
	.data
	.align 32
	.type	header_latest, @object
	.size	header_latest, 32
header_latest:
	.quad	header_key
	.quad	8
	.quad	.LC46
	.quad	code_latest
	.globl	key_latest
	.align 4
	.type	key_latest, @object
	.size	key_latest, 4
key_latest:
	.long	44
	.text
	.globl	code_latest
	.type	code_latest, @function
code_latest:
.LFB47:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movl	$dictionary, %edx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE47:
	.size	code_latest, .-code_latest
	.globl	header_in_ptr
	.section	.rodata
.LC47:
	.string	">IN"
	.data
	.align 32
	.type	header_in_ptr, @object
	.size	header_in_ptr, 32
header_in_ptr:
	.quad	header_latest
	.quad	3
	.quad	.LC47
	.quad	code_in_ptr
	.globl	key_in_ptr
	.align 4
	.type	key_in_ptr, @object
	.size	key_in_ptr, 4
key_in_ptr:
	.long	45
	.text
	.globl	code_in_ptr
	.type	code_in_ptr, @function
code_in_ptr:
.LFB48:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movq	inputIndex(%rip), %rdx
	salq	$5, %rdx
	addq	$inputSources, %rdx
	addq	$8, %rdx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE48:
	.size	code_in_ptr, .-code_in_ptr
	.globl	header_emit
	.section	.rodata
.LC48:
	.string	"EMIT"
	.data
	.align 32
	.type	header_emit, @object
	.size	header_emit, 32
header_emit:
	.quad	header_in_ptr
	.quad	4
	.quad	.LC48
	.quad	code_emit
	.globl	key_emit
	.align 4
	.type	key_emit, @object
	.size	key_emit, 4
key_emit:
	.long	46
	.text
	.globl	code_emit
	.type	code_emit, @function
code_emit:
.LFB49:
	.cfi_startproc
	movq	stdout(%rip), %rdx
	movq	sp(%rip), %rax
	leaq	8(%rax), %rcx
	movq	%rcx, sp(%rip)
	movq	(%rax), %rax
	movq	%rdx, %rsi
	movl	%eax, %edi
	call	fputc
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE49:
	.size	code_emit, .-code_emit
	.globl	header_source
	.section	.rodata
.LC49:
	.string	"SOURCE"
	.data
	.align 32
	.type	header_source, @object
	.size	header_source, 32
header_source:
	.quad	header_emit
	.quad	6
	.quad	.LC49
	.quad	code_source
	.globl	key_source
	.align 4
	.type	key_source, @object
	.size	key_source, 4
key_source:
	.long	47
	.text
	.globl	code_source
	.type	code_source, @function
code_source:
.LFB50:
	.cfi_startproc
	subq	$16, sp(%rip)
	movq	sp(%rip), %rax
	movq	inputIndex(%rip), %rdx
	salq	$5, %rdx
	addq	$inputSources, %rdx
	movq	(%rdx), %rdx
	movq	%rdx, (%rax)
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	inputIndex(%rip), %rdx
	salq	$5, %rdx
	addq	$inputSources+24, %rdx
	movq	(%rdx), %rdx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE50:
	.size	code_source, .-code_source
	.globl	header_source_id
	.section	.rodata
.LC50:
	.string	"SOURCE-ID"
	.data
	.align 32
	.type	header_source_id, @object
	.size	header_source_id, 32
header_source_id:
	.quad	header_source
	.quad	9
	.quad	.LC50
	.quad	code_source_id
	.globl	key_source_id
	.align 4
	.type	key_source_id, @object
	.size	key_source_id, 4
key_source_id:
	.long	48
	.text
	.globl	code_source_id
	.type	code_source_id, @function
code_source_id:
.LFB51:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movq	inputIndex(%rip), %rdx
	salq	$5, %rdx
	addq	$inputSources+16, %rdx
	movq	(%rdx), %rdx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE51:
	.size	code_source_id, .-code_source_id
	.globl	header_size_cell
	.section	.rodata
.LC51:
	.string	"(/CELL)"
	.data
	.align 32
	.type	header_size_cell, @object
	.size	header_size_cell, 32
header_size_cell:
	.quad	header_source_id
	.quad	7
	.quad	.LC51
	.quad	code_size_cell
	.globl	key_size_cell
	.align 4
	.type	key_size_cell, @object
	.size	key_size_cell, 4
key_size_cell:
	.long	49
	.text
	.globl	code_size_cell
	.type	code_size_cell, @function
code_size_cell:
.LFB52:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	$8, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE52:
	.size	code_size_cell, .-code_size_cell
	.globl	header_size_char
	.section	.rodata
.LC52:
	.string	"(/CHAR)"
	.data
	.align 32
	.type	header_size_char, @object
	.size	header_size_char, 32
header_size_char:
	.quad	header_size_cell
	.quad	7
	.quad	.LC52
	.quad	code_size_char
	.globl	key_size_char
	.align 4
	.type	key_size_char, @object
	.size	key_size_char, 4
key_size_char:
	.long	50
	.text
	.globl	code_size_char
	.type	code_size_char, @function
code_size_char:
.LFB53:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	$1, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE53:
	.size	code_size_char, .-code_size_char
	.globl	header_cells
	.section	.rodata
.LC53:
	.string	"CELLS"
	.data
	.align 32
	.type	header_cells, @object
	.size	header_cells, 32
header_cells:
	.quad	header_size_char
	.quad	5
	.quad	.LC53
	.quad	code_cells
	.globl	key_cells
	.align 4
	.type	key_cells, @object
	.size	key_cells, 4
key_cells:
	.long	51
	.text
	.globl	code_cells
	.type	code_cells, @function
code_cells:
.LFB54:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	(%rax), %rdx
	salq	$3, %rdx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE54:
	.size	code_cells, .-code_cells
	.globl	header_chars
	.section	.rodata
.LC54:
	.string	"CHARS"
	.data
	.align 32
	.type	header_chars, @object
	.size	header_chars, 32
header_chars:
	.quad	header_cells
	.quad	5
	.quad	.LC54
	.quad	code_chars
	.globl	key_chars
	.align 4
	.type	key_chars, @object
	.size	key_chars, 4
key_chars:
	.long	52
	.text
	.globl	code_chars
	.type	code_chars, @function
code_chars:
.LFB55:
	.cfi_startproc
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE55:
	.size	code_chars, .-code_chars
	.globl	header_unit_bits
	.section	.rodata
.LC55:
	.string	"(ADDRESS-UNIT-BITS)"
	.data
	.align 32
	.type	header_unit_bits, @object
	.size	header_unit_bits, 32
header_unit_bits:
	.quad	header_chars
	.quad	19
	.quad	.LC55
	.quad	code_unit_bits
	.globl	key_unit_bits
	.align 4
	.type	key_unit_bits, @object
	.size	key_unit_bits, 4
key_unit_bits:
	.long	53
	.text
	.globl	code_unit_bits
	.type	code_unit_bits, @function
code_unit_bits:
.LFB56:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	$8, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE56:
	.size	code_unit_bits, .-code_unit_bits
	.globl	header_stack_cells
	.section	.rodata
.LC56:
	.string	"(STACK-CELLS)"
	.data
	.align 32
	.type	header_stack_cells, @object
	.size	header_stack_cells, 32
header_stack_cells:
	.quad	header_unit_bits
	.quad	13
	.quad	.LC56
	.quad	code_stack_cells
	.globl	key_stack_cells
	.align 4
	.type	key_stack_cells, @object
	.size	key_stack_cells, 4
key_stack_cells:
	.long	54
	.text
	.globl	code_stack_cells
	.type	code_stack_cells, @function
code_stack_cells:
.LFB57:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movq	$16384, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE57:
	.size	code_stack_cells, .-code_stack_cells
	.globl	header_return_stack_cells
	.section	.rodata
.LC57:
	.string	"(RETURN-STACK-CELLS)"
	.data
	.align 32
	.type	header_return_stack_cells, @object
	.size	header_return_stack_cells, 32
header_return_stack_cells:
	.quad	header_stack_cells
	.quad	20
	.quad	.LC57
	.quad	code_return_stack_cells
	.globl	key_return_stack_cells
	.align 4
	.type	key_return_stack_cells, @object
	.size	key_return_stack_cells, 4
key_return_stack_cells:
	.long	55
	.text
	.globl	code_return_stack_cells
	.type	code_return_stack_cells, @function
code_return_stack_cells:
.LFB58:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movq	$1024, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE58:
	.size	code_return_stack_cells, .-code_return_stack_cells
	.globl	header_to_does
	.section	.rodata
.LC58:
	.string	"(>DOES)"
	.data
	.align 32
	.type	header_to_does, @object
	.size	header_to_does, 32
header_to_does:
	.quad	header_return_stack_cells
	.quad	7
	.quad	.LC58
	.quad	code_to_does
	.globl	key_to_does
	.align 4
	.type	key_to_does, @object
	.size	key_to_does, 4
key_to_does:
	.long	56
	.text
	.globl	code_to_does
	.type	code_to_does, @function
code_to_does:
.LFB59:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, tempHeader(%rip)
	movq	sp(%rip), %rax
	movq	tempHeader(%rip), %rdx
	addq	$24, %rdx
	addq	$8, %rdx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE59:
	.size	code_to_does, .-code_to_does
	.globl	header_to_cfa
	.section	.rodata
.LC59:
	.string	"(>CFA)"
	.data
	.align 32
	.type	header_to_cfa, @object
	.size	header_to_cfa, 32
header_to_cfa:
	.quad	header_to_does
	.quad	6
	.quad	.LC59
	.quad	code_to_cfa
	.globl	key_to_cfa
	.align 4
	.type	key_to_cfa, @object
	.size	key_to_cfa, 4
key_to_cfa:
	.long	57
	.text
	.globl	code_to_cfa
	.type	code_to_cfa, @function
code_to_cfa:
.LFB60:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, tempHeader(%rip)
	movq	sp(%rip), %rax
	movq	tempHeader(%rip), %rdx
	addq	$24, %rdx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE60:
	.size	code_to_cfa, .-code_to_cfa
	.globl	header_to_body
	.section	.rodata
.LC60:
	.string	">BODY"
	.data
	.align 32
	.type	header_to_body, @object
	.size	header_to_body, 32
header_to_body:
	.quad	header_to_cfa
	.quad	5
	.quad	.LC60
	.quad	code_to_body
	.globl	key_to_body
	.align 4
	.type	key_to_body, @object
	.size	key_to_body, 4
key_to_body:
	.long	58
	.text
	.globl	code_to_body
	.type	code_to_body, @function
code_to_body:
.LFB61:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rdx
	addq	$16, %rdx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE61:
	.size	code_to_body, .-code_to_body
	.globl	header_last_word
	.section	.rodata
.LC61:
	.string	"(LAST-WORD)"
	.data
	.align 32
	.type	header_last_word, @object
	.size	header_last_word, 32
header_last_word:
	.quad	header_to_body
	.quad	11
	.quad	.LC61
	.quad	code_last_word
	.globl	key_last_word
	.align 4
	.type	key_last_word, @object
	.size	key_last_word, 4
key_last_word:
	.long	59
	.text
	.globl	code_last_word
	.type	code_last_word, @function
code_last_word:
.LFB62:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movq	lastWord(%rip), %rdx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE62:
	.size	code_last_word, .-code_last_word
	.globl	header_docol
	.section	.rodata
.LC62:
	.string	"(DOCOL)"
	.data
	.align 32
	.type	header_docol, @object
	.size	header_docol, 32
header_docol:
	.quad	header_last_word
	.quad	7
	.quad	.LC62
	.quad	code_docol
	.globl	key_docol
	.align 4
	.type	key_docol, @object
	.size	key_docol, 4
key_docol:
	.long	60
	.text
	.globl	code_docol
	.type	code_docol, @function
code_docol:
.LFB63:
	.cfi_startproc
	movq	rsp(%rip), %rax
	subq	$8, %rax
	movq	%rax, rsp(%rip)
	movq	ip(%rip), %rdx
	movq	%rdx, (%rax)
	movq	cfa(%rip), %rax
	addq	$8, %rax
	movq	%rax, ip(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE63:
	.size	code_docol, .-code_docol
	.globl	header_dolit
	.section	.rodata
.LC63:
	.string	"(DOLIT)"
	.data
	.align 32
	.type	header_dolit, @object
	.size	header_dolit, 32
header_dolit:
	.quad	header_docol
	.quad	7
	.quad	.LC63
	.quad	code_dolit
	.globl	key_dolit
	.align 4
	.type	key_dolit, @object
	.size	key_dolit, 4
key_dolit:
	.long	61
	.text
	.globl	code_dolit
	.type	code_dolit, @function
code_dolit:
.LFB64:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	ip(%rip), %rdx
        movq    (%rdx), %rcx
        movq    %rcx, (%rax)
	leaq	8(%rdx), %rcx
	movq	%rcx, ip(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE64:
	.size	code_dolit, .-code_dolit
	.globl	header_dostring
	.section	.rodata
.LC64:
	.string	"(DOSTRING)"
	.data
	.align 32
	.type	header_dostring, @object
	.size	header_dostring, 32
header_dostring:
	.quad	header_dolit
	.quad	10
	.quad	.LC64
	.quad	code_dostring
	.globl	key_dostring
	.align 4
	.type	key_dostring, @object
	.size	key_dostring, 4
key_dostring:
	.long	62
	.text
	.globl	code_dostring
	.type	code_dostring, @function
code_dostring:
.LFB65:
	.cfi_startproc
        # TODO Maybe optimize this more? Complex and not that hot, though.
	movq	ip(%rip), %rax
	movq	%rax, str1(%rip)
	movq	str1(%rip), %rax
	movzbl	(%rax), %eax
	movsbq	%al, %rax
	movq	%rax, c1(%rip)
	subq	$16, sp(%rip)
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	str1(%rip), %rdx
	addq	$1, %rdx
	movq	%rdx, (%rax)
	movq	sp(%rip), %rax
	movq	c1(%rip), %rdx
	movq	%rdx, (%rax)
	movq	c1(%rip), %rax
	addq	$8, %rax
	addq	%rax, str1(%rip)
	movq	str1(%rip), %rax
	andq	$-8, %rax
	movq	%rax, str1(%rip)
	movq	str1(%rip), %rax
	movq	%rax, ip(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE65:
	.size	code_dostring, .-code_dostring
	.globl	header_dodoes
	.section	.rodata
.LC65:
	.string	"(DODOES)"
	.data
	.align 32
	.type	header_dodoes, @object
	.size	header_dodoes, 32
header_dodoes:
	.quad	header_dostring
	.quad	8
	.quad	.LC65
	.quad	code_dodoes
	.globl	key_dodoes
	.align 4
	.type	key_dodoes, @object
	.size	key_dodoes, 4
key_dodoes:
	.long	63
	.text
	.globl	code_dodoes
	.type	code_dodoes, @function
code_dodoes:
.LFB66:
	.cfi_startproc
        # TODO: Optimize this. It's tricky, but called reasonably often.
	movq	cfa(%rip), %rax
	movq	%rax, str1(%rip)
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movq	str1(%rip), %rdx
	addq	$16, %rdx
	movq	%rdx, (%rax)
	movq	str1(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movq	%rax, c1(%rip)
	movq	c1(%rip), %rax
	testq	%rax, %rax
	je	.L98
	movq	rsp(%rip), %rax
	subq	$8, %rax
	movq	%rax, rsp(%rip)
	movq	rsp(%rip), %rax
	movq	ip(%rip), %rdx
	movq	%rdx, (%rax)
	movq	c1(%rip), %rax
	movq	%rax, ip(%rip)
.L98:
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE66:
	.size	code_dodoes, .-code_dodoes
	.globl	parse_
	.type	parse_, @function
parse_:
.LFB67:
	.cfi_startproc
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	(%rax), %rdx
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources, %rax
	movq	(%rax), %rax
	cmpq	%rax, %rdx
	jl	.L100
	movq	sp(%rip), %rax
	movq	$0, (%rax)
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movq	$0, (%rax)
	jmp	.L106
.L100:
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movb	%al, ch1(%rip)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+24, %rax
	movq	(%rax), %rdx
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	(%rax), %rax
	addq	%rdx, %rax
	movq	%rax, str1(%rip)
	movq	$0, c1(%rip)
	jmp	.L102
.L104:
	movq	inputIndex(%rip), %rax
	movq	%rax, %rdx
	salq	$5, %rdx
	addq	$inputSources+8, %rdx
	movq	(%rdx), %rdx
	salq	$5, %rax
	addq	$inputSources+8, %rax
	addq	$1, %rdx
	movq	%rdx, (%rax)
	addq	$1, c1(%rip)
.L102:
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	(%rax), %rdx
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources, %rax
	movq	(%rax), %rax
	cmpq	%rax, %rdx
	jge	.L103
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+24, %rax
	movq	(%rax), %rdx
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	(%rax), %rax
	movzbl	(%rdx,%rax), %edx
	movzbl	ch1(%rip), %eax
	cmpb	%al, %dl
	jne	.L104
.L103:
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	(%rax), %rdx
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources, %rax
	movq	(%rax), %rax
	cmpq	%rax, %rdx
	jge	.L105
	movq	inputIndex(%rip), %rax
	movq	%rax, %rdx
	salq	$5, %rdx
	addq	$inputSources+8, %rdx
	movq	(%rdx), %rdx
	salq	$5, %rax
	addq	$inputSources+8, %rax
	addq	$1, %rdx
	movq	%rdx, (%rax)
.L105:
	movq	sp(%rip), %rax
	movq	str1(%rip), %rdx
	movq	%rdx, (%rax)
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movq	c1(%rip), %rdx
	movq	%rdx, (%rax)
.L106:
	nop
	ret
	.cfi_endproc
.LFE67:
	.size	parse_, .-parse_
	.globl	parse_name_
	.type	parse_name_, @function
parse_name_:
.LFB68:
	.cfi_startproc
	jmp	.L108
.L110:
	movq	inputIndex(%rip), %rax
	movq	%rax, %rdx
	salq	$5, %rdx
	addq	$inputSources+8, %rdx
	movq	(%rdx), %rdx
	salq	$5, %rax
	addq	$inputSources+8, %rax
	addq	$1, %rdx
	movq	%rdx, (%rax)
.L108:
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	(%rax), %rdx
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources, %rax
	movq	(%rax), %rax
	cmpq	%rax, %rdx
	jge	.L109
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+24, %rax
	movq	(%rax), %rdx
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	(%rax), %rax
	movzbl	(%rdx,%rax), %eax
	cmpb	$32, %al
	je	.L110
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+24, %rax
	movq	(%rax), %rdx
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	(%rax), %rax
	movzbl	(%rdx,%rax), %eax
	cmpb	$9, %al
	je	.L110
.L109:
	movq	$0, c1(%rip)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+24, %rax
	movq	(%rax), %rdx
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	(%rax), %rax
	addq	%rdx, %rax
	movq	%rax, str1(%rip)
	jmp	.L111
.L113:
	movq	inputIndex(%rip), %rax
	movq	%rax, %rdx
	salq	$5, %rdx
	addq	$inputSources+8, %rdx
	movq	(%rdx), %rdx
	salq	$5, %rax
	addq	$inputSources+8, %rax
	addq	$1, %rdx
	movq	%rdx, (%rax)
	addq	$1, c1(%rip)
.L111:
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	(%rax), %rdx
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources, %rax
	movq	(%rax), %rax
	cmpq	%rax, %rdx
	jge	.L112
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+24, %rax
	movq	(%rax), %rdx
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	(%rax), %rax
	movzbl	(%rdx,%rax), %eax
	cmpb	$32, %al
	jne	.L113
.L112:
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	(%rax), %rdx
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources, %rax
	movq	(%rax), %rax
	cmpq	%rax, %rdx
	jge	.L114
	movq	inputIndex(%rip), %rax
	movq	%rax, %rdx
	salq	$5, %rdx
	addq	$inputSources+8, %rdx
	movq	(%rdx), %rdx
	salq	$5, %rax
	addq	$inputSources+8, %rax
	addq	$1, %rdx
	movq	%rdx, (%rax)
.L114:
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movq	str1(%rip), %rdx
	movq	%rdx, (%rax)
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movq	c1(%rip), %rdx
	movq	%rdx, (%rax)
	nop
	ret
	.cfi_endproc
.LFE68:
	.size	parse_name_, .-parse_name_
	.globl	to_number_int_
	.type	to_number_int_, @function
to_number_int_:
.LFB69:
	.cfi_startproc
	movq	$0, c1(%rip)
	jmp	.L116
.L117:
	movq	c1(%rip), %rax
	movq	sp(%rip), %rdx
	addq	$24, %rdx
	movq	(%rdx), %rdx
	movq	%rdx, %rsi
	movq	c1(%rip), %rdx
	sall	$3, %edx
	movl	%edx, %ecx
	shrq	%cl, %rsi
	movq	%rsi, %rdx
	movb	%dl, numBuf(%rax)
	movq	c1(%rip), %rax
	addq	$8, %rax
	movq	sp(%rip), %rdx
	addq	$16, %rdx
	movq	(%rdx), %rdx
	movq	%rdx, %rsi
	movq	c1(%rip), %rdx
	sall	$3, %edx
	movl	%edx, %ecx
	shrq	%cl, %rsi
	movq	%rsi, %rdx
	movb	%dl, numBuf(%rax)
	addq	$1, c1(%rip)
.L116:
	movq	c1(%rip), %rax
	cmpq	$7, %rax
	jle	.L117
	jmp	.L118
.L126:
	movq	str1(%rip), %rax
	movzbl	(%rax), %eax
	movsbq	%al, %rax
	movq	%rax, c1(%rip)
	movq	c1(%rip), %rax
	cmpq	$47, %rax
	jle	.L119
	movq	c1(%rip), %rax
	cmpq	$57, %rax
	jg	.L119
	subq	$48, c1(%rip)
	jmp	.L120
.L119:
	movq	c1(%rip), %rax
	cmpq	$64, %rax
	jle	.L121
	movq	c1(%rip), %rax
	cmpq	$90, %rax
	jg	.L121
	movq	c1(%rip), %rax
	subq	$55, %rax
	movq	%rax, c1(%rip)
	jmp	.L120
.L121:
	movq	c1(%rip), %rax
	cmpq	$96, %rax
	jle	.L122
	movq	c1(%rip), %rax
	cmpq	$122, %rax
	jg	.L122
	movq	c1(%rip), %rax
	subq	$87, %rax
	movq	%rax, c1(%rip)
.L120:
	movq	c1(%rip), %rdx
	movq	tempSize(%rip), %rax
	cmpq	%rax, %rdx
	jge	.L129
	movq	$0, c3(%rip)
	jmp	.L124
.L125:
	movq	c3(%rip), %rax
	addq	$numBuf, %rax
	movzbl	(%rax), %eax
	movzbl	%al, %eax
	imulq	tempSize(%rip), %rax
	movq	%rax, %rdx
	movq	c1(%rip), %rax
	addq	%rdx, %rax
	movq	%rax, c2(%rip)
	movq	c3(%rip), %rax
	movq	c2(%rip), %rdx
	movb	%dl, numBuf(%rax)
	movq	c2(%rip), %rax
	sarq	$8, %rax
	movzbl	%al, %eax
	movq	%rax, c1(%rip)
	addq	$1, c3(%rip)
.L124:
	movq	c3(%rip), %rax
	cmpq	$15, %rax
	jle	.L125
	movq	sp(%rip), %rax
	movq	(%rax), %rdx
	subq	$1, %rdx
	movq	%rdx, (%rax)
	addq	$1, str1(%rip)
.L118:
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	testq	%rax, %rax
	jg	.L126
	jmp	.L122
.L129:
	nop
.L122:
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	$0, (%rax)
	movq	sp(%rip), %rax
	addq	$24, %rax
	movq	$0, (%rax)
	movq	$0, c1(%rip)
	jmp	.L127
.L128:
	movq	c1(%rip), %rax
	addq	$numBuf, %rax
	movzbl	(%rax), %eax
	movzbl	%al, %edx
	movq	c1(%rip), %rax
	sall	$3, %eax
	movl	%eax, %ecx
	salq	%cl, %rdx
	movq	%rdx, %rax
	movq	%rax, %rcx
	movq	sp(%rip), %rax
	leaq	24(%rax), %rdx
	movq	sp(%rip), %rax
	addq	$24, %rax
	orq	(%rax), %rcx
	movq	%rcx, %rax
	movq	%rax, (%rdx)
	movq	c1(%rip), %rax
	addq	$8, %rax
	movzbl	numBuf(%rax), %eax
	movzbl	%al, %edx
	movq	c1(%rip), %rax
	sall	$3, %eax
	movl	%eax, %ecx
	salq	%cl, %rdx
	movq	%rdx, %rax
	movq	%rax, %rcx
	movq	sp(%rip), %rax
	leaq	16(%rax), %rdx
	movq	sp(%rip), %rax
	addq	$16, %rax
	orq	(%rax), %rcx
	movq	%rcx, %rax
	movq	%rax, (%rdx)
	addq	$1, c1(%rip)
.L127:
	movq	c1(%rip), %rax
	cmpq	$7, %rax
	jle	.L128
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	str1(%rip), %rax
	movq	%rax, (%rdx)
	nop
	ret
	.cfi_endproc
.LFE69:
	.size	to_number_int_, .-to_number_int_
	.globl	to_number_
	.type	to_number_, @function
to_number_:
.LFB70:
	.cfi_startproc
	movq	base(%rip), %rax
	movq	%rax, tempSize(%rip)
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movq	%rax, str1(%rip)
	call	to_number_int_
	nop
	ret
	.cfi_endproc
.LFE70:
	.size	to_number_, .-to_number_
	.globl	parse_number_
	.type	parse_number_, @function
parse_number_:
.LFB71:
	.cfi_startproc
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movq	%rax, str1(%rip)
	movq	base(%rip), %rax
	movq	%rax, tempSize(%rip)
	movq	str1(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$36, %al
	je	.L132
	movq	str1(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$35, %al
	je	.L132
	movq	str1(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$37, %al
	jne	.L133
.L132:
	movq	str1(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$36, %al
	je	.L134
	movq	str1(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$35, %al
	jne	.L135
	movl	$10, %eax
	jmp	.L137
.L135:
	movl	$2, %eax
	jmp	.L137
.L134:
	movl	$16, %eax
.L137:
	movq	%rax, tempSize(%rip)
	addq	$1, str1(%rip)
	movq	sp(%rip), %rax
	movq	(%rax), %rdx
	subq	$1, %rdx
	movq	%rdx, (%rax)
	jmp	.L138
.L133:
	movq	str1(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$39, %al
	jne	.L138
	movq	sp(%rip), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rdx
	subq	$3, %rdx
	movq	%rdx, (%rax)
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	sp(%rip), %rdx
	addq	$8, %rdx
	movq	(%rdx), %rdx
	addq	$3, %rdx
	movq	%rdx, (%rax)
	movq	sp(%rip), %rax
	leaq	24(%rax), %rdx
	movq	str1(%rip), %rax
	addq	$1, %rax
	movsbq	(%rax), %rax
	movq	%rax, (%rdx)
	jmp	.L131
.L138:
	movb	$0, ch1(%rip)
	movq	str1(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$45, %al
	jne	.L140
	movq	sp(%rip), %rax
	movq	(%rax), %rdx
	subq	$1, %rdx
	movq	%rdx, (%rax)
	addq	$1, str1(%rip)
	movb	$1, ch1(%rip)
.L140:
	call	to_number_int_
	movzbl	ch1(%rip), %eax
	testb	%al, %al
	je	.L131
	movq	sp(%rip), %rax
	addq	$24, %rax
	movq	sp(%rip), %rdx
	addq	$24, %rdx
	movq	(%rdx), %rdx
	notq	%rdx
	movq	%rdx, (%rax)
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	sp(%rip), %rdx
	addq	$16, %rdx
	movq	(%rdx), %rdx
	notq	%rdx
	movq	%rdx, (%rax)
	movq	sp(%rip), %rax
	addq	$24, %rax
	movq	(%rax), %rdx
	addq	$1, %rdx
	movq	%rdx, (%rax)
	movq	sp(%rip), %rax
	addq	$24, %rax
	movq	(%rax), %rax
	testq	%rax, %rax
	jne	.L131
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	(%rax), %rdx
	addq	$1, %rdx
	movq	%rdx, (%rax)
.L131:
	ret
	.cfi_endproc
.LFE71:
	.size	parse_number_, .-parse_number_
	.globl	find_
	.type	find_, @function
find_:
.LFB72:
	.cfi_startproc
	subq	$8, %rsp
	.cfi_def_cfa_offset 16
	movq	dictionary(%rip), %rax
	movq	%rax, tempHeader(%rip)
	jmp	.L142
.L147:
	movq	tempHeader(%rip), %rax
	movq	8(%rax), %rax
	andl	$511, %eax
	movq	%rax, %rdx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	cmpq	%rax, %rdx
	jne	.L143
	movq	sp(%rip), %rax
	movq	(%rax), %rdx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rcx
	movq	tempHeader(%rip), %rax
	movq	16(%rax), %rax
	movq	%rcx, %rsi
	movq	%rax, %rdi
	call	strncasecmp
	testl	%eax, %eax
	jne	.L143
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	tempHeader(%rip), %rdx
	addq	$24, %rdx
	movq	%rdx, (%rax)
	movq	sp(%rip), %rax
	movq	tempHeader(%rip), %rdx
	movq	8(%rdx), %rdx
	andl	$512, %edx
	testq	%rdx, %rdx
	jne	.L144
	movq	$-1, %rdx
	jmp	.L145
.L144:
	movl	$1, %edx
.L145:
	movq	%rdx, (%rax)
	jmp	.L141
.L143:
	movq	tempHeader(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, tempHeader(%rip)
.L142:
	movq	tempHeader(%rip), %rax
	testq	%rax, %rax
	jne	.L147
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	$0, (%rax)
	movq	sp(%rip), %rax
	movq	$0, (%rax)
.L141:
	addq	$8, %rsp
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE72:
	.size	find_, .-find_
	.globl	header_parse
	.section	.rodata
.LC66:
	.string	"PARSE"
	.data
	.align 32
	.type	header_parse, @object
	.size	header_parse, 32
header_parse:
	.quad	header_dodoes
	.quad	5
	.quad	.LC66
	.quad	code_parse
	.globl	key_parse
	.align 4
	.type	key_parse, @object
	.size	key_parse, 4
key_parse:
	.long	64
	.text
	.globl	code_parse
	.type	code_parse, @function
code_parse:
.LFB73:
	.cfi_startproc
	call	parse_
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE73:
	.size	code_parse, .-code_parse
	.globl	header_parse_name
	.section	.rodata
.LC67:
	.string	"PARSE-NAME"
	.data
	.align 32
	.type	header_parse_name, @object
	.size	header_parse_name, 32
header_parse_name:
	.quad	header_parse
	.quad	10
	.quad	.LC67
	.quad	code_parse_name
	.globl	key_parse_name
	.align 4
	.type	key_parse_name, @object
	.size	key_parse_name, 4
key_parse_name:
	.long	65
	.text
	.globl	code_parse_name
	.type	code_parse_name, @function
code_parse_name:
.LFB74:
	.cfi_startproc
	call	parse_name_
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE74:
	.size	code_parse_name, .-code_parse_name
	.globl	header_to_number
	.section	.rodata
.LC68:
	.string	">NUMBER"
	.data
	.align 32
	.type	header_to_number, @object
	.size	header_to_number, 32
header_to_number:
	.quad	header_parse_name
	.quad	7
	.quad	.LC68
	.quad	code_to_number
	.globl	key_to_number
	.align 4
	.type	key_to_number, @object
	.size	key_to_number, 4
key_to_number:
	.long	66
	.text
	.globl	code_to_number
	.type	code_to_number, @function
code_to_number:
.LFB75:
	.cfi_startproc
	call	to_number_
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE75:
	.size	code_to_number, .-code_to_number
	.globl	header_create
	.section	.rodata
.LC69:
	.string	"CREATE"
	.data
	.align 32
	.type	header_create, @object
	.size	header_create, 32
header_create:
	.quad	header_to_number
	.quad	6
	.quad	.LC69
	.quad	code_create
	.globl	key_create
	.align 4
	.type	key_create, @object
	.size	key_create, 4
key_create:
	.long	67
	.text
	.globl	code_create
	.type	code_create, @function
code_create:
.LFB76:
	.cfi_startproc
        # TODO: Optimize. Low priority, CREATE is not very hot.
	call	parse_name_
	movq	dsp(%rip), %rax
	addq	$7, %rax
	andq	$-8, %rax
	movq	%rax, dsp(%rip)
	movq	dsp(%rip), %rax
	movq	%rax, tempHeader(%rip)
	addq	$32, dsp(%rip)
	movq	tempHeader(%rip), %rax
	movq	dictionary(%rip), %rdx
	movq	%rdx, (%rax)
	movq	tempHeader(%rip), %rax
	movq	%rax, dictionary(%rip)
	movq	tempHeader(%rip), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rdx
	movq	%rdx, 8(%rax)
	movq	tempHeader(%rip), %rbx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, %rdi
	call	malloc
	movq	%rax, 16(%rbx)
	movq	sp(%rip), %rax
	movq	(%rax), %rdx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rcx
	movq	tempHeader(%rip), %rax
	movq	16(%rax), %rax
	movq	%rcx, %rsi
	movq	%rax, %rdi
	call	strncpy
	addq	$16, sp(%rip)
	movq	tempHeader(%rip), %rax
	movq	$code_dodoes, 24(%rax)
	movq	dsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, dsp(%rip)
	movq	$0, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE76:
	.size	code_create, .-code_create
	.globl	header_find
	.section	.rodata
.LC70:
	.string	"(FIND)"
	.data
	.align 32
	.type	header_find, @object
	.size	header_find, 32
header_find:
	.quad	header_create
	.quad	6
	.quad	.LC70
	.quad	code_find
	.globl	key_find
	.align 4
	.type	key_find, @object
	.size	key_find, 4
key_find:
	.long	68
	.text
	.globl	code_find
	.type	code_find, @function
code_find:
.LFB77:
	.cfi_startproc
	call	find_
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE77:
	.size	code_find, .-code_find
	.globl	header_depth
	.section	.rodata
.LC71:
	.string	"DEPTH"
	.data
	.align 32
	.type	header_depth, @object
	.size	header_depth, 32
header_depth:
	.quad	header_find
	.quad	5
	.quad	.LC71
	.quad	code_depth
	.globl	key_depth
	.align 4
	.type	key_depth, @object
	.size	key_depth, 4
key_depth:
	.long	69
	.text
	.globl	code_depth
	.type	code_depth, @function
code_depth:
.LFB78:
	.cfi_startproc
	movq	spTop(%rip), %rax
	subq	sp(%rip), %rax
	shrq	$3, %rax
	movq	%rax, c1(%rip)
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movq	c1(%rip), %rdx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE78:
	.size	code_depth, .-code_depth
	.globl	header_sp_fetch
	.section	.rodata
.LC72:
	.string	"SP@"
	.data
	.align 32
	.type	header_sp_fetch, @object
	.size	header_sp_fetch, 32
header_sp_fetch:
	.quad	header_depth
	.quad	3
	.quad	.LC72
	.quad	code_sp_fetch
	.globl	key_sp_fetch
	.align 4
	.type	key_sp_fetch, @object
	.size	key_sp_fetch, 4
key_sp_fetch:
	.long	70
	.text
	.globl	code_sp_fetch
	.type	code_sp_fetch, @function
code_sp_fetch:
.LFB79:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	%rax, %rbx
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	%rbx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE79:
	.size	code_sp_fetch, .-code_sp_fetch
	.globl	header_sp_store
	.section	.rodata
.LC73:
	.string	"SP!"
	.data
	.align 32
	.type	header_sp_store, @object
	.size	header_sp_store, 32
header_sp_store:
	.quad	header_sp_fetch
	.quad	3
	.quad	.LC73
	.quad	code_sp_store
	.globl	key_sp_store
	.align 4
	.type	key_sp_store, @object
	.size	key_sp_store, 4
key_sp_store:
	.long	71
	.text
	.globl	code_sp_store
	.type	code_sp_store, @function
code_sp_store:
.LFB80:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE80:
	.size	code_sp_store, .-code_sp_store
	.globl	header_rp_fetch
	.section	.rodata
.LC74:
	.string	"RP@"
	.data
	.align 32
	.type	header_rp_fetch, @object
	.size	header_rp_fetch, 32
header_rp_fetch:
	.quad	header_sp_store
	.quad	3
	.quad	.LC74
	.quad	code_rp_fetch
	.globl	key_rp_fetch
	.align 4
	.type	key_rp_fetch, @object
	.size	key_rp_fetch, 4
key_rp_fetch:
	.long	72
	.text
	.globl	code_rp_fetch
	.type	code_rp_fetch, @function
code_rp_fetch:
.LFB81:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	rsp(%rip), %rdx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE81:
	.size	code_rp_fetch, .-code_rp_fetch
	.globl	header_rp_store
	.section	.rodata
.LC75:
	.string	"RP!"
	.data
	.align 32
	.type	header_rp_store, @object
	.size	header_rp_store, 32
header_rp_store:
	.quad	header_rp_fetch
	.quad	3
	.quad	.LC75
	.quad	code_rp_store
	.globl	key_rp_store
	.align 4
	.type	key_rp_store, @object
	.size	key_rp_store, 4
key_rp_store:
	.long	73
	.text
	.globl	code_rp_store
	.type	code_rp_store, @function
code_rp_store:
.LFB82:
	.cfi_startproc
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, sp(%rip)
	movq	(%rax), %rax
	movq	%rax, rsp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE82:
	.size	code_rp_store, .-code_rp_store
	.section	.rodata
.LC76:
	.string	"[%ld] "
	.text
	.globl	dot_s_
	.type	dot_s_, @function
dot_s_:
.LFB83:
	.cfi_startproc
	subq	$8, %rsp
	.cfi_def_cfa_offset 16
	movq	spTop(%rip), %rax
	subq	sp(%rip), %rax
	shrq	$3, %rax
	movq	%rax, %rsi
	movl	$.LC76, %edi
	movl	$0, %eax
	call	printf
	movq	spTop(%rip), %rax
	subq	$8, %rax
	movq	%rax, c1(%rip)
	jmp	.L162
.L163:
	movq	c1(%rip), %rax
	movq	(%rax), %rsi
	movl	$.LC36, %edi
	movl	$0, %eax
	call	printf
	subq	$8, c1(%rip)
.L162:
	movq	c1(%rip), %rdx
	movq	sp(%rip), %rax
	cmpq	%rax, %rdx
	jge	.L163
	movl	$10, %edi
	call	putchar
	nop
	addq	$8, %rsp
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE83:
	.size	dot_s_, .-dot_s_
	.globl	header_dot_s
	.section	.rodata
.LC77:
	.string	".S"
	.data
	.align 32
	.type	header_dot_s, @object
	.size	header_dot_s, 32
header_dot_s:
	.quad	header_rp_store
	.quad	2
	.quad	.LC77
	.quad	code_dot_s
	.globl	key_dot_s
	.align 4
	.type	key_dot_s, @object
	.size	key_dot_s, 4
key_dot_s:
	.long	74
	.text
	.globl	code_dot_s
	.type	code_dot_s, @function
code_dot_s:
.LFB84:
	.cfi_startproc
	call	dot_s_
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE84:
	.size	code_dot_s, .-code_dot_s
	.section	.rodata
.LC78:
	.string	"%lx "
	.text
	.globl	u_dot_s_
	.type	u_dot_s_, @function
u_dot_s_:
.LFB85:
	.cfi_startproc
	subq	$8, %rsp
	.cfi_def_cfa_offset 16
	movq	spTop(%rip), %rax
	subq	sp(%rip), %rax
	shrq	$3, %rax
	movq	%rax, %rsi
	movl	$.LC76, %edi
	movl	$0, %eax
	call	printf
	movq	spTop(%rip), %rax
	subq	$8, %rax
	movq	%rax, c1(%rip)
	jmp	.L168
.L169:
	movq	c1(%rip), %rax
	movq	(%rax), %rsi
	movl	$.LC78, %edi
	movl	$0, %eax
	call	printf
	subq	$8, c1(%rip)
.L168:
	movq	c1(%rip), %rdx
	movq	sp(%rip), %rax
	cmpq	%rax, %rdx
	jge	.L169
	movl	$10, %edi
	call	putchar
	nop
	addq	$8, %rsp
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE85:
	.size	u_dot_s_, .-u_dot_s_
	.globl	header_u_dot_s
	.section	.rodata
.LC79:
	.string	"U.S"
	.data
	.align 32
	.type	header_u_dot_s, @object
	.size	header_u_dot_s, 32
header_u_dot_s:
	.quad	header_dot_s
	.quad	3
	.quad	.LC79
	.quad	code_u_dot_s
	.globl	key_u_dot_s
	.align 4
	.type	key_u_dot_s, @object
	.size	key_u_dot_s, 4
key_u_dot_s:
	.long	75
	.text
	.globl	code_u_dot_s
	.type	code_u_dot_s, @function
code_u_dot_s:
.LFB86:
	.cfi_startproc
	call	u_dot_s_
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE86:
	.size	code_u_dot_s, .-code_u_dot_s
	.globl	header_dump_file
	.section	.rodata
.LC80:
	.string	"(DUMP-FILE)"
	.data
	.align 32
	.type	header_dump_file, @object
	.size	header_dump_file, 32
header_dump_file:
	.quad	header_u_dot_s
	.quad	11
	.quad	.LC80
	.quad	code_dump_file
	.globl	key_dump_file
	.align 4
	.type	key_dump_file, @object
	.size	key_dump_file, 4
key_dump_file:
	.long	76
	.section	.rodata
.LC81:
	.string	"wb"
	.align 8
.LC82:
	.string	"*** Failed to open file for writing: %s\n"
	.align 8
.LC83:
	.string	"(Dumped %ld of %ld bytes to %s)\n"
	.text
	.globl	code_dump_file
	.type	code_dump_file, @function
code_dump_file:
.LFB87:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	(%rax), %rdx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movq	%rax, %rsi
	movl	$tempBuf, %edi
	call	strncpy
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movb	$0, tempBuf(%rax)
	movl	$.LC81, %esi
	movl	$tempBuf, %edi
	call	fopen
	movq	%rax, tempFile(%rip)
	movq	tempFile(%rip), %rax
	testq	%rax, %rax
	jne	.L174
	movl	$tempBuf, %edx
	movl	$.LC82, %esi
	movq	stderr(%rip), %rdi
	movl	$0, %eax
	call	fprintf
	jmp	.L175
.L174:
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	(%rax), %rdx
	movq	sp(%rip), %rax
	addq	$24, %rax
	movq	(%rax), %rax
	movq	tempFile(%rip), %rcx
	movl	$1, %esi
	movq	%rax, %rdi
	call	fwrite
	movq	%rax, c1(%rip)
	movq	sp(%rip), %rax
	addq	$16, %rax
	movl	$tempBuf, %ecx
	movq	(%rax), %rdx
	movq	c1(%rip), %rsi
	movl	$.LC83, %edi
	movl	$0, %eax
	call	printf
	movq	tempFile(%rip), %rdi
	call	fclose
	movq	$0, tempFile(%rip)
.L175:
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE87:
	.size	code_dump_file, .-code_dump_file
	.globl	key_call_
	.data
	.align 4
	.type	key_call_, @object
	.size	key_call_, 4
key_call_:
	.long	100
	.text
	.globl	call_
	.type	call_, @function
call_:
.LFB88:
	.cfi_startproc
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	movq	rsp(%rip), %rbx
	subq	$8, %rbx
	movq	%rbx, rsp(%rip)
	movq	%rdx, (%rbx)
	movq	%rax, ip(%rip)
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE88:
	.size	call_, .-call_
	.globl	lookup_primitive
	.type	lookup_primitive, @function
lookup_primitive:
.LFB89:
	.cfi_startproc
	movq	$0, c2(%rip)
	jmp	.L179
.L182:
	movq	c2(%rip), %rax
	salq	$4, %rax
	addq	$primitives, %rax
	movq	(%rax), %rdx
	movq	c1(%rip), %rax
	cmpq	%rax, %rdx
	jne	.L180
	movq	c2(%rip), %rax
	salq	$4, %rax
	addq	$primitives+8, %rax
	movl	(%rax), %eax
	movl	%eax, key1(%rip)
	jmp	.L183
.L180:
	addq	$1, c2(%rip)
.L179:
	movl	primitive_count(%rip), %eax
	movslq	%eax, %rdx
	movq	c2(%rip), %rax
	cmpq	%rax, %rdx
	jg	.L182
	subq	$8, %rsp
	.cfi_def_cfa_offset 16
	movl	$40, %edi
	call	exit
.L183:
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE89:
	.size	lookup_primitive, .-lookup_primitive
	.globl	drain_queue_
	.type	drain_queue_, @function
drain_queue_:
.LFB90:
	.cfi_startproc
	movl	$0, key1(%rip)
	movq	queue(%rip), %rax
	movq	%rax, tempQueue(%rip)
	movq	$0, c1(%rip)
	jmp	.L188
.L189:
	movq	tempQueue(%rip), %rax
	movl	24(%rax), %edx
	movq	c1(%rip), %rax
	sall	$3, %eax
	movl	%eax, %ecx
	sall	%cl, %edx
	movl	%edx, %eax
	orl	%eax, key1(%rip)
	addq	$1, c1(%rip)
	movq	tempQueue(%rip), %rax
	movq	32(%rax), %rax
	movq	%rax, tempQueue(%rip)
.L188:
	movq	tempQueue(%rip), %rax
	testq	%rax, %rax
	jne	.L189
	jmp	.L190
.L199:
	movq	$0, c2(%rip)
	jmp	.L191
.L198:
	movq	c2(%rip), %rax
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	(%rax), %edx
	movl	key1(%rip), %eax
	cmpl	%eax, %edx
	jne	.L192
	movq	dsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, dsp(%rip)
	movq	c2(%rip), %rdx
	salq	$4, %rdx
	addq	$superinstructions, %rdx
	movq	(%rdx), %rdx
	movq	%rdx, (%rax)
	jmp	.L193
.L195:
	movq	queue(%rip), %rax
	movzbl	8(%rax), %eax
	testb	%al, %al
	je	.L194
	movq	dsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, dsp(%rip)
	movq	queue(%rip), %rdx
	movq	16(%rdx), %rdx
	movq	%rdx, (%rax)
.L194:
	movq	queue(%rip), %rax
	movq	32(%rax), %rax
	movq	%rax, queue(%rip)
	subl	$1, queue_length(%rip)
	subq	$1, c1(%rip)
.L193:
	movq	c1(%rip), %rax
	testq	%rax, %rax
	jg	.L195
	movq	queue(%rip), %rax
	testq	%rax, %rax
	jne	.L202
	movq	$0, queueTail(%rip)
	jmp	.L202
.L192:
	addq	$1, c2(%rip)
.L191:
	movl	nextSuperinstruction(%rip), %eax
	movslq	%eax, %rdx
	movq	c2(%rip), %rax
	cmpq	%rax, %rdx
	jg	.L198
	subq	$1, c1(%rip)
	movl	$4, %eax
	subq	c1(%rip), %rax
	sall	$3, %eax
	movl	$-1, %edx
	movl	%eax, %ecx
	shrl	%cl, %edx
	movl	%edx, %eax
	andl	%eax, key1(%rip)
.L190:
	movq	c1(%rip), %rax
	cmpq	$1, %rax
	jg	.L199
	movq	dsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, dsp(%rip)
	movq	queue(%rip), %rdx
	movq	(%rdx), %rdx
	movq	%rdx, (%rax)
	movq	queue(%rip), %rax
	movzbl	8(%rax), %eax
	testb	%al, %al
	je	.L200
	movq	dsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, dsp(%rip)
	movq	queue(%rip), %rdx
	movq	16(%rdx), %rdx
	movq	%rdx, (%rax)
.L200:
	movq	queue(%rip), %rax
	movq	32(%rax), %rax
	movq	%rax, queue(%rip)
	movq	queue(%rip), %rax
	testq	%rax, %rax
	jne	.L201
	movq	$0, queueTail(%rip)
.L201:
	subl	$1, queue_length(%rip)
	jmp	.L187
.L202:
	nop
.L187:
	ret
	.cfi_endproc
.LFE90:
	.size	drain_queue_, .-drain_queue_
	.globl	bump_queue_tail_
	.type	bump_queue_tail_, @function
bump_queue_tail_:
.LFB91:
	.cfi_startproc
	movq	queueTail(%rip), %rax
	testq	%rax, %rax
	jne	.L204
	movl	next_queue_source(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, next_queue_source(%rip)
	movslq	%eax, %rdx
	movq	%rdx, %rax
	salq	$2, %rax
	addq	%rdx, %rax
	salq	$3, %rax
	addq	$queueSource, %rax
	movq	%rax, queueTail(%rip)
	movq	queueTail(%rip), %rax
	movq	%rax, queue(%rip)
	jmp	.L205
.L204:
	movq	queueTail(%rip), %rcx
	movl	next_queue_source(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, next_queue_source(%rip)
	movslq	%eax, %rdx
	movq	%rdx, %rax
	salq	$2, %rax
	addq	%rdx, %rax
	salq	$3, %rax
	addq	$queueSource, %rax
	movq	%rax, 32(%rcx)
	movq	queueTail(%rip), %rax
	movq	32(%rax), %rax
	movq	%rax, queueTail(%rip)
.L205:
	movq	queueTail(%rip), %rax
	movq	$0, 32(%rax)
	andl	$3, next_queue_source(%rip)
	addl	$1, queue_length(%rip)
	nop
	ret
	.cfi_endproc
.LFE91:
	.size	bump_queue_tail_, .-bump_queue_tail_
	.globl	compile_
	.type	compile_, @function
compile_:
.LFB92:
	.cfi_startproc
	subq	$8, %rsp
	.cfi_def_cfa_offset 16
	movl	queue_length(%rip), %eax
	cmpl	$3, %eax
	jle	.L207
	call	drain_queue_
.L207:
	movl	$0, %eax
	call	bump_queue_tail_
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	(%rax), %rax
	cmpq	$code_docol, %rax
	jne	.L208
	movq	queueTail(%rip), %rax
	movq	$call_, (%rax)
	movq	queueTail(%rip), %rax
	movb	$1, 8(%rax)
	movq	queueTail(%rip), %rdx
	movq	sp(%rip), %rax
	leaq	8(%rax), %rcx
	movq	%rcx, sp(%rip)
	movq	(%rax), %rax
	addq	$8, %rax
	movq	%rax, 16(%rdx)
	movq	queueTail(%rip), %rax
	movl	key_call_(%rip), %edx
	movl	%edx, 24(%rax)
	jmp	.L213
.L208:
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	(%rax), %rax
	cmpq	$code_dodoes, %rax
	jne	.L210
	movq	queueTail(%rip), %rax
	movq	$code_dolit, (%rax)
	movq	queueTail(%rip), %rax
	movb	$1, 8(%rax)
	movq	queueTail(%rip), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rdx
	addq	$16, %rdx
	movq	%rdx, 16(%rax)
	movq	queueTail(%rip), %rax
	movl	key_dolit(%rip), %edx
	movl	%edx, 24(%rax)
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	testq	%rax, %rax
	je	.L211
	movl	queue_length(%rip), %eax
	cmpl	$4, %eax
	jne	.L212
	call	drain_queue_
.L212:
	movl	$0, %eax
	call	bump_queue_tail_
	movq	queueTail(%rip), %rax
	movq	$call_, (%rax)
	movq	queueTail(%rip), %rax
	movb	$1, 8(%rax)
	movq	queueTail(%rip), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rdx
	addq	$8, %rdx
	movq	(%rdx), %rdx
	movq	%rdx, 16(%rax)
	movq	queueTail(%rip), %rax
	movl	key_call_(%rip), %edx
	movl	%edx, 24(%rax)
.L211:
	addq	$8, sp(%rip)
	jmp	.L213
.L210:
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, sp(%rip)
	movq	(%rax), %rax
	movq	(%rax), %rax
	movq	%rax, c1(%rip)
	movl	$0, %eax
	call	lookup_primitive
	movq	queueTail(%rip), %rax
	movq	c1(%rip), %rdx
	movq	%rdx, (%rax)
	movq	queueTail(%rip), %rax
	movb	$0, 8(%rax)
	movq	queueTail(%rip), %rax
	movl	key1(%rip), %edx
	movl	%edx, 24(%rax)
.L213:
	nop
	addq	$8, %rsp
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE92:
	.size	compile_, .-compile_
	.globl	compile_lit_
	.type	compile_lit_, @function
compile_lit_:
.LFB93:
	.cfi_startproc
	movl	queue_length(%rip), %eax
	cmpl	$3, %eax
	jle	.L216
	call	drain_queue_
.L216:
	movl	$0, %eax
	call	bump_queue_tail_
	movq	queueTail(%rip), %rax
	movq	$code_dolit, (%rax)
	movq	queueTail(%rip), %rax
	movb	$1, 8(%rax)
	movq	queueTail(%rip), %rdx
	movq	sp(%rip), %rax
	leaq	8(%rax), %rcx
	movq	%rcx, sp(%rip)
	movq	(%rax), %rax
	movq	%rax, 16(%rdx)
	movq	queueTail(%rip), %rax
	movl	key_dolit(%rip), %edx
	movl	%edx, 24(%rax)
	nop
	ret
	.cfi_endproc
.LFE93:
	.size	compile_lit_, .-compile_lit_
	.comm	savedString,8,8
	.comm	savedLength,8,8
	.section	.rodata
.LC84:
	.string	"  ok"
.LC85:
	.string	"*** Unrecognized word: %s\n"
	.text
	.globl	quit_
	.type	quit_, @function
quit_:
.LFB94:
	.cfi_startproc
	subq	$8, %rsp
	.cfi_def_cfa_offset 16
.L218:
	movq	spTop(%rip), %rax
	movq	%rax, sp(%rip)
	movq	rspTop(%rip), %rax
	movq	%rax, rsp(%rip)
	movq	$0, state(%rip)
	movzbl	firstQuit(%rip), %eax
	testb	%al, %al
	jne	.L219
	movq	$0, inputIndex(%rip)
.L219:
	movq	$.L220, quit_inner(%rip)
	call	refill_
.L220:
	call	parse_name_
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	testq	%rax, %rax
	jne	.L233
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+16, %rax
	movq	(%rax), %rax
	testq	%rax, %rax
	jne	.L223
	movl	$.LC84, %edi
	call	puts
.L223:
	addq	$16, sp(%rip)
	call	refill_
	jmp	.L220
.L233:
	nop
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movq	%rax, savedString(%rip)
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, savedLength(%rip)
	call	find_
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	testq	%rax, %rax
	jne	.L224
	subq	$16, sp(%rip)
	movq	sp(%rip), %rax
	movq	savedLength(%rip), %rdx
	movq	%rdx, (%rax)
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	savedString(%rip), %rax
	movq	%rax, (%rdx)
	call	parse_number_
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	testq	%rax, %rax
	jne	.L225
	movq	state(%rip), %rax
	cmpq	$1, %rax
	jne	.L226
	addq	$24, sp(%rip)
	movl	$0, %eax
	call	compile_lit_
	jmp	.L220
.L226:
	addq	$24, sp(%rip)
	jmp	.L220
.L225:
	movq	savedLength(%rip), %rdx
	movq	savedString(%rip), %rsi
	movl	$tempBuf, %edi
	call	strncpy
	movq	savedLength(%rip), %rax
	movb	$0, tempBuf(%rax)
	movl	$tempBuf, %edx
	movl	$.LC85, %esi
	movq	stderr(%rip), %rdi
	movl	$0, %eax
	call	fprintf
	jmp	.L218
.L224:
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	cmpq	$1, %rax
	je	.L229
	movq	state(%rip), %rax
	testq	%rax, %rax
	jne	.L230
.L229:
	movl	$.L220, %eax
	movq	%rax, quitTop(%rip)
	movq	$quitTop, ip(%rip)
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movq	%rax, cfa(%rip)
	addq	$16, sp(%rip)
	movq	cfa(%rip), %rax
	movq	(%rax), %rax
#APP
# 1438 "vm.c" 1
	jmpq *%rax
# 0 "" 2
#NO_APP
.L230:
	addq	$8, sp(%rip)
	movl	$0, %eax
	call	compile_
	jmp	.L220
	.cfi_endproc
.LFE94:
	.size	quit_, .-quit_
	.globl	header_quit
	.section	.rodata
.LC86:
	.string	"QUIT"
	.data
	.align 32
	.type	header_quit, @object
	.size	header_quit, 32
header_quit:
	.quad	header_dump_file
	.quad	4
	.quad	.LC86
	.quad	code_quit
	.globl	key_quit
	.align 4
	.type	key_quit, @object
	.size	key_quit, 4
key_quit:
	.long	77
	.text
	.globl	code_quit
	.type	code_quit, @function
code_quit:
.LFB95:
	.cfi_startproc
	movq	$0, inputIndex(%rip)
	call	quit_
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE95:
	.size	code_quit, .-code_quit
	.globl	header_bye
	.section	.rodata
.LC87:
	.string	"BYE"
	.data
	.align 32
	.type	header_bye, @object
	.size	header_bye, 32
header_bye:
	.quad	header_quit
	.quad	3
	.quad	.LC87
	.quad	code_bye
	.globl	key_bye
	.align 4
	.type	key_bye, @object
	.size	key_bye, 4
key_bye:
	.long	78
	.text
	.globl	code_bye
	.type	code_bye, @function
code_bye:
.LFB96:
	.cfi_startproc
	movl	$0, %edi
	call	exit
	.cfi_endproc
.LFE96:
	.size	code_bye, .-code_bye
	.globl	header_compile_comma
	.section	.rodata
.LC88:
	.string	"COMPILE,"
	.data
	.align 32
	.type	header_compile_comma, @object
	.size	header_compile_comma, 32
header_compile_comma:
	.quad	header_bye
	.quad	8
	.quad	.LC88
	.quad	code_compile_comma
	.globl	key_compile_comma
	.align 4
	.type	key_compile_comma, @object
	.size	key_compile_comma, 4
key_compile_comma:
	.long	79
	.text
	.globl	code_compile_comma
	.type	code_compile_comma, @function
code_compile_comma:
.LFB97:
	.cfi_startproc
	movl	$0, %eax
	call	compile_
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE97:
	.size	code_compile_comma, .-code_compile_comma
	.globl	header_literal
	.section	.rodata
.LC89:
	.string	"LITERAL"
	.data
	.align 32
	.type	header_literal, @object
	.size	header_literal, 32
header_literal:
	.quad	header_compile_comma
	.quad	519
	.quad	.LC89
	.quad	code_literal
	.globl	key_literal
	.align 4
	.type	key_literal, @object
	.size	key_literal, 4
key_literal:
	.long	101
	.text
	.globl	code_literal
	.type	code_literal, @function
code_literal:
.LFB98:
	.cfi_startproc
	movl	$0, %eax
	call	compile_lit_
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE98:
	.size	code_literal, .-code_literal
	.globl	header_compile_literal
	.section	.rodata
.LC90:
	.string	"[LITERAL]"
	.data
	.align 32
	.type	header_compile_literal, @object
	.size	header_compile_literal, 32
header_compile_literal:
	.quad	header_literal
	.quad	9
	.quad	.LC90
	.quad	code_compile_literal
	.globl	key_compile_literal
	.align 4
	.type	key_compile_literal, @object
	.size	key_compile_literal, 4
key_compile_literal:
	.long	102
	.text
	.globl	code_compile_literal
	.type	code_compile_literal, @function
code_compile_literal:
.LFB99:
	.cfi_startproc
	movl	$0, %eax
	call	compile_lit_
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE99:
	.size	code_compile_literal, .-code_compile_literal
	.globl	header_compile_zbranch
	.section	.rodata
.LC91:
	.string	"[0BRANCH]"
	.data
	.align 32
	.type	header_compile_zbranch, @object
	.size	header_compile_zbranch, 32
header_compile_zbranch:
	.quad	header_compile_literal
	.quad	9
	.quad	.LC91
	.quad	code_compile_zbranch
	.globl	key_compile_zbranch
	.align 4
	.type	key_compile_zbranch, @object
	.size	key_compile_zbranch, 4
key_compile_zbranch:
	.long	103
	.text
	.globl	code_compile_zbranch
	.type	code_compile_zbranch, @function
code_compile_zbranch:
.LFB100:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movl	$header_zbranch+24, %edx
	movq	%rdx, (%rax)
	movl	$0, %eax
	call	compile_
	jmp	.L244
.L245:
	call	drain_queue_
.L244:
	movl	queue_length(%rip), %eax
	testl	%eax, %eax
	jg	.L245
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movq	dsp(%rip), %rdx
	movq	%rdx, (%rax)
	movq	dsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, dsp(%rip)
	movq	$0, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE100:
	.size	code_compile_zbranch, .-code_compile_zbranch
	.globl	header_compile_branch
	.section	.rodata
.LC92:
	.string	"[BRANCH]"
	.data
	.align 32
	.type	header_compile_branch, @object
	.size	header_compile_branch, 32
header_compile_branch:
	.quad	header_compile_zbranch
	.quad	8
	.quad	.LC92
	.quad	code_compile_branch
	.globl	key_compile_branch
	.align 4
	.type	key_compile_branch, @object
	.size	key_compile_branch, 4
key_compile_branch:
	.long	104
	.text
	.globl	code_compile_branch
	.type	code_compile_branch, @function
code_compile_branch:
.LFB101:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movl	$header_branch+24, %edx
	movq	%rdx, (%rax)
	movl	$0, %eax
	call	compile_
	jmp	.L248
.L249:
	call	drain_queue_
.L248:
	movl	queue_length(%rip), %eax
	testl	%eax, %eax
	jg	.L249
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movq	dsp(%rip), %rdx
	movq	%rdx, (%rax)
	movq	dsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, dsp(%rip)
	movq	$0, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE101:
	.size	code_compile_branch, .-code_compile_branch
	.globl	header_control_flush
	.section	.rodata
.LC93:
	.string	"(CONTROL-FLUSH)"
	.data
	.align 32
	.type	header_control_flush, @object
	.size	header_control_flush, 32
header_control_flush:
	.quad	header_compile_branch
	.quad	15
	.quad	.LC93
	.quad	code_control_flush
	.globl	key_control_flush
	.align 4
	.type	key_control_flush, @object
	.size	key_control_flush, 4
key_control_flush:
	.long	105
	.text
	.globl	code_control_flush
	.type	code_control_flush, @function
code_control_flush:
.LFB102:
	.cfi_startproc
	jmp	.L252
.L253:
	call	drain_queue_
.L252:
	movl	queue_length(%rip), %eax
	testl	%eax, %eax
	jg	.L253
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE102:
	.size	code_control_flush, .-code_control_flush
	.globl	header_debug_break
	.section	.rodata
.LC94:
	.string	"(DEBUG)"
	.data
	.align 32
	.type	header_debug_break, @object
	.size	header_debug_break, 32
header_debug_break:
	.quad	header_control_flush
	.quad	7
	.quad	.LC94
	.quad	code_debug_break
	.globl	key_debug_break
	.align 4
	.type	key_debug_break, @object
	.size	key_debug_break, 4
key_debug_break:
	.long	80
	.text
	.globl	code_debug_break
	.type	code_debug_break, @function
code_debug_break:
.LFB103:
	.cfi_startproc
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE103:
	.size	code_debug_break, .-code_debug_break
	.globl	header_close_file
	.section	.rodata
.LC95:
	.string	"CLOSE-FILE"
	.data
	.align 32
	.type	header_close_file, @object
	.size	header_close_file, 32
header_close_file:
	.quad	header_debug_break
	.quad	10
	.quad	.LC95
	.quad	code_close_file
	.globl	key_close_file
	.align 4
	.type	key_close_file, @object
	.size	key_close_file, 4
key_close_file:
	.long	81
	.text
	.globl	code_close_file
	.type	code_close_file, @function
code_close_file:
.LFB104:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, %rdi
	call	fclose
	cltq
	movq	%rax, c1(%rip)
	movq	sp(%rip), %rbx
	movq	c1(%rip), %rax
	testq	%rax, %rax
	je	.L256
	call	__errno_location
	movl	(%rax), %eax
	cltq
	jmp	.L257
.L256:
	movl	$0, %eax
.L257:
	movq	%rax, (%rbx)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE104:
	.size	code_close_file, .-code_close_file
	.globl	file_modes
	.section	.rodata
.LC96:
	.string	"r"
.LC97:
	.string	"r+"
.LC98:
	.string	"rb"
.LC99:
	.string	"r+b"
.LC100:
	.string	"w+"
.LC101:
	.string	"w"
.LC102:
	.string	"w+b"
	.data
	.align 32
	.type	file_modes, @object
	.size	file_modes, 128
file_modes:
	.quad	0
	.quad	.LC96
	.quad	.LC97
	.quad	.LC97
	.quad	0
	.quad	.LC98
	.quad	.LC99
	.quad	.LC99
	.quad	0
	.quad	.LC100
	.quad	.LC101
	.quad	.LC100
	.quad	0
	.quad	.LC102
	.quad	.LC81
	.quad	.LC102
	.globl	header_create_file
	.section	.rodata
.LC103:
	.string	"CREATE-FILE"
	.data
	.align 32
	.type	header_create_file, @object
	.size	header_create_file, 32
header_create_file:
	.quad	header_close_file
	.quad	11
	.quad	.LC103
	.quad	code_create_file
	.globl	key_create_file
	.align 4
	.type	key_create_file, @object
	.size	key_create_file, 4
key_create_file:
	.long	82
	.text
	.globl	code_create_file
	.type	code_create_file, @function
code_create_file:
.LFB105:
	.cfi_startproc
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rdx
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	(%rax), %rax
	movq	%rax, %rsi
	movl	$tempBuf, %edi
	call	strncpy
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movb	$0, tempBuf(%rax)
	addq	$8, sp(%rip)
	movq	sp(%rip), %rax
	leaq	8(%rax), %rbx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	orq	$8, %rax
	movq	file_modes(,%rax,8), %rax
	movq	%rax, %rsi
	movl	$tempBuf, %edi
	call	fopen
	movq	%rax, (%rbx)
	movq	sp(%rip), %rbx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	testq	%rax, %rax
	jne	.L260
	call	__errno_location
	movl	(%rax), %eax
	cltq
	jmp	.L261
.L260:
	movl	$0, %eax
.L261:
	movq	%rax, (%rbx)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE105:
	.size	code_create_file, .-code_create_file
	.globl	header_open_file
	.section	.rodata
.LC104:
	.string	"OPEN-FILE"
	.data
	.align 32
	.type	header_open_file, @object
	.size	header_open_file, 32
header_open_file:
	.quad	header_create_file
	.quad	9
	.quad	.LC104
	.quad	code_open_file
	.globl	key_open_file
	.align 4
	.type	key_open_file, @object
	.size	key_open_file, 4
key_open_file:
	.long	83
	.text
	.globl	code_open_file
	.type	code_open_file, @function
code_open_file:
.LFB106:
	.cfi_startproc
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rdx
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	(%rax), %rax
	movq	%rax, %rsi
	movl	$tempBuf, %edi
	call	strncpy
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movb	$0, tempBuf(%rax)
	movq	sp(%rip), %rax
	leaq	16(%rax), %rbx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	file_modes(,%rax,8), %rax
	movq	%rax, %rsi
	movl	$tempBuf, %edi
	call	fopen
	movq	%rax, (%rbx)
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	(%rax), %rax
	testq	%rax, %rax
	jne	.L264
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	andl	$2, %eax
	testq	%rax, %rax
	je	.L264
	movq	sp(%rip), %rax
	leaq	16(%rax), %rbx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	orq	$8, %rax
	movq	file_modes(,%rax,8), %rax
	movq	%rax, %rsi
	movl	$tempBuf, %edi
	call	fopen
	movq	%rax, (%rbx)
.L264:
	movq	sp(%rip), %rax
	leaq	8(%rax), %rbx
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	(%rax), %rax
	testq	%rax, %rax
	jne	.L265
	call	__errno_location
	movl	(%rax), %eax
	cltq
	jmp	.L266
.L265:
	movl	$0, %eax
.L266:
	movq	%rax, (%rbx)
	addq	$8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE106:
	.size	code_open_file, .-code_open_file
	.globl	header_delete_file
	.section	.rodata
.LC105:
	.string	"DELETE-FILE"
	.data
	.align 32
	.type	header_delete_file, @object
	.size	header_delete_file, 32
header_delete_file:
	.quad	header_open_file
	.quad	11
	.quad	.LC105
	.quad	code_delete_file
	.globl	key_delete_file
	.align 4
	.type	key_delete_file, @object
	.size	key_delete_file, 4
key_delete_file:
	.long	84
	.text
	.globl	code_delete_file
	.type	code_delete_file, @function
code_delete_file:
.LFB107:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	(%rax), %rdx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movq	%rax, %rsi
	movl	$tempBuf, %edi
	call	strncpy
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movb	$0, tempBuf(%rax)
	addq	$8, sp(%rip)
	movq	sp(%rip), %rbx
	movl	$tempBuf, %edi
	call	remove
	cltq
	movq	%rax, (%rbx)
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	cmpq	$-1, %rax
	jne	.L269
	movq	sp(%rip), %rbx
	call	__errno_location
	movl	(%rax), %eax
	cltq
	movq	%rax, (%rbx)
.L269:
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE107:
	.size	code_delete_file, .-code_delete_file
	.globl	header_file_position
	.section	.rodata
.LC106:
	.string	"FILE-POSITION"
	.data
	.align 32
	.type	header_file_position, @object
	.size	header_file_position, 32
header_file_position:
	.quad	header_delete_file
	.quad	13
	.quad	.LC106
	.quad	code_file_position
	.globl	key_file_position
	.align 4
	.type	key_file_position, @object
	.size	key_file_position, 4
key_file_position:
	.long	85
	.text
	.globl	code_file_position
	.type	code_file_position, @function
code_file_position:
.LFB108:
	.cfi_startproc
	subq	$16, sp(%rip)
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	$0, (%rax)
	movq	sp(%rip), %rax
	leaq	16(%rax), %rbx
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	(%rax), %rax
	movq	%rax, %rdi
	call	ftell
	movq	%rax, (%rbx)
	movq	sp(%rip), %rbx
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	(%rax), %rax
	cmpq	$-1, %rax
	jne	.L272
	call	__errno_location
	movl	(%rax), %eax
	cltq
	jmp	.L273
.L272:
	movl	$0, %eax
.L273:
	movq	%rax, (%rbx)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE108:
	.size	code_file_position, .-code_file_position
	.globl	header_file_size
	.section	.rodata
.LC107:
	.string	"FILE-SIZE"
	.data
	.align 32
	.type	header_file_size, @object
	.size	header_file_size, 32
header_file_size:
	.quad	header_file_position
	.quad	9
	.quad	.LC107
	.quad	code_file_size
	.globl	key_file_size
	.align 4
	.type	key_file_size, @object
	.size	key_file_size, 4
key_file_size:
	.long	86
	.text
	.globl	code_file_size
	.type	code_file_size, @function
code_file_size:
.LFB109:
	.cfi_startproc
	subq	$16, sp(%rip)
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	$0, (%rax)
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	(%rax), %rax
	movq	%rax, %rdi
	call	ftell
	movq	%rax, c1(%rip)
	movq	c1(%rip), %rax
	testq	%rax, %rax
	jns	.L276
	movq	sp(%rip), %rbx
	call	__errno_location
	movl	(%rax), %eax
	cltq
	movq	%rax, (%rbx)
	jmp	.L277
.L276:
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	(%rax), %rax
	movl	$2, %edx
	movl	$0, %esi
	movq	%rax, %rdi
	call	fseek
	cltq
	movq	%rax, c2(%rip)
	movq	c2(%rip), %rax
	testq	%rax, %rax
	jns	.L278
	movq	sp(%rip), %rbx
	call	__errno_location
	movl	(%rax), %eax
	cltq
	movq	%rax, (%rbx)
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	(%rax), %rax
	movl	$0, %edx
	movq	c1(%rip), %rsi
	movq	%rax, %rdi
	call	fseek
	jmp	.L277
.L278:
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	(%rax), %rax
	movq	%rax, %rdi
	call	ftell
	movq	%rax, c2(%rip)
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	(%rax), %rax
	movl	$0, %edx
	movq	c1(%rip), %rsi
	movq	%rax, %rdi
	call	fseek
	movq	sp(%rip), %rax
	leaq	16(%rax), %rdx
	movq	c2(%rip), %rax
	movq	%rax, (%rdx)
	movq	sp(%rip), %rax
	movq	$0, (%rax)
.L277:
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE109:
	.size	code_file_size, .-code_file_size
	.globl	header_include_file
	.section	.rodata
.LC108:
	.string	"INCLUDE-FILE"
	.data
	.align 32
	.type	header_include_file, @object
	.size	header_include_file, 32
header_include_file:
	.quad	header_file_size
	.quad	12
	.quad	.LC108
	.quad	code_include_file
	.globl	key_include_file
	.align 4
	.type	key_include_file, @object
	.size	key_include_file, 4
key_include_file:
	.long	87
	.text
	.globl	code_include_file
	.type	code_include_file, @function
code_include_file:
.LFB110:
	.cfi_startproc
	addq	$1, inputIndex(%rip)
	movq	inputIndex(%rip), %rcx
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, sp(%rip)
	movq	(%rax), %rax
	salq	$5, %rcx
	movq	%rcx, %rdx
	addq	$inputSources+16, %rdx
	movq	%rax, (%rdx)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	$0, (%rax)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources, %rax
	movq	$0, (%rax)
	movq	inputIndex(%rip), %rax
	movq	inputIndex(%rip), %rdx
	salq	$8, %rdx
	addq	$parseBuffers, %rdx
	salq	$5, %rax
	addq	$inputSources+24, %rax
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE110:
	.size	code_include_file, .-code_include_file
	.globl	header_read_file
	.section	.rodata
.LC109:
	.string	"READ-FILE"
	.data
	.align 32
	.type	header_read_file, @object
	.size	header_read_file, 32
header_read_file:
	.quad	header_include_file
	.quad	9
	.quad	.LC109
	.quad	code_read_file
	.globl	key_read_file
	.align 4
	.type	key_read_file, @object
	.size	key_read_file, 4
key_read_file:
	.long	88
	.text
	.globl	code_read_file
	.type	code_read_file, @function
code_read_file:
.LFB111:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	(%rax), %rcx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rdx
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	(%rax), %rax
	movl	$1, %esi
	movq	%rax, %rdi
	call	fread
	movq	%rax, c1(%rip)
	movq	c1(%rip), %rax
	testq	%rax, %rax
	jne	.L282
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, %rdi
	call	feof
	testl	%eax, %eax
	je	.L283
	addq	$8, sp(%rip)
	movq	sp(%rip), %rax
	movq	$0, (%rax)
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	$0, (%rax)
	jmp	.L285
.L283:
	movq	sp(%rip), %rax
	leaq	8(%rax), %rbx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, %rdi
	call	ferror
	cltq
	movq	%rax, (%rbx)
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	$0, (%rax)
	addq	$8, sp(%rip)
	jmp	.L285
.L282:
	addq	$8, sp(%rip)
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	c1(%rip), %rax
	movq	%rax, (%rdx)
	movq	sp(%rip), %rax
	movq	$0, (%rax)
.L285:
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE111:
	.size	code_read_file, .-code_read_file
	.globl	header_read_line
	.section	.rodata
.LC110:
	.string	"READ-LINE"
	.data
	.align 32
	.type	header_read_line, @object
	.size	header_read_line, 32
header_read_line:
	.quad	header_read_file
	.quad	9
	.quad	.LC110
	.quad	code_read_line
	.globl	key_read_line
	.align 4
	.type	key_read_line, @object
	.size	key_read_line, 4
key_read_line:
	.long	89
	.text
	.globl	code_read_line
	.type	code_read_line, @function
code_read_line:
.LFB112:
	.cfi_startproc
	movq	$0, str1(%rip)
	movq	$0, tempSize(%rip)
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, %rdx
	movl	$tempSize, %esi
	movl	$str1, %edi
	call	getline
	movq	%rax, c1(%rip)
	movq	c1(%rip), %rax
	cmpq	$-1, %rax
	jne	.L288
	movq	sp(%rip), %rbx
	call	__errno_location
	movl	(%rax), %eax
	cltq
	movq	%rax, (%rbx)
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	$0, (%rax)
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	$0, (%rax)
	jmp	.L289
.L288:
	movq	c1(%rip), %rax
	testq	%rax, %rax
	jne	.L290
	movq	sp(%rip), %rax
	movq	$0, (%rax)
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	$0, (%rax)
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	$0, (%rax)
	jmp	.L289
.L290:
	movq	c1(%rip), %rax
	leaq	-1(%rax), %rdx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	cmpq	%rax, %rdx
	jle	.L291
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rdx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	c1(%rip), %rcx
	subq	%rdx, %rcx
	movl	$1, %edx
	movq	%rcx, %rsi
	movq	%rax, %rdi
	call	fseek
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	addq	$1, %rax
	movq	%rax, c1(%rip)
	jmp	.L292
.L291:
	movq	str1(%rip), %rdx
	movq	c1(%rip), %rax
	addq	%rdx, %rax
	subq	$1, %rax
	movzbl	(%rax), %eax
	cmpb	$10, %al
	je	.L292
	addq	$1, c1(%rip)
.L292:
	movq	c1(%rip), %rax
	leaq	-1(%rax), %rdx
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	(%rax), %rax
	movq	str1(%rip), %rsi
	movq	%rax, %rdi
	call	strncpy
	movq	sp(%rip), %rax
	movq	$0, (%rax)
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	$-1, (%rax)
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	c1(%rip), %rdx
	subq	$1, %rdx
	movq	%rdx, (%rax)
.L289:
	movq	str1(%rip), %rax
	testq	%rax, %rax
	je	.L293
	movq	str1(%rip), %rdi
	call	free
.L293:
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE112:
	.size	code_read_line, .-code_read_line
	.globl	header_reposition_file
	.section	.rodata
.LC111:
	.string	"REPOSITION-FILE"
	.data
	.align 32
	.type	header_reposition_file, @object
	.size	header_reposition_file, 32
header_reposition_file:
	.quad	header_read_line
	.quad	15
	.quad	.LC111
	.quad	code_reposition_file
	.globl	key_reposition_file
	.align 4
	.type	key_reposition_file, @object
	.size	key_reposition_file, 4
key_reposition_file:
	.long	90
	.text
	.globl	code_reposition_file
	.type	code_reposition_file, @function
code_reposition_file:
.LFB113:
	.cfi_startproc
	movq	sp(%rip), %rax
	leaq	16(%rax), %rbx
	movq	sp(%rip), %rax
	leaq	16(%rax), %rcx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movl	$0, %edx
	movq	(%rcx), %rsi
	movq	%rax, %rdi
	call	fseek
	cltq
	movq	%rax, (%rbx)
	addq	$16, sp(%rip)
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	cmpq	$-1, %rax
	jne	.L296
	movq	sp(%rip), %rbx
	call	__errno_location
	movl	(%rax), %eax
	cltq
	movq	%rax, (%rbx)
.L296:
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE113:
	.size	code_reposition_file, .-code_reposition_file
	.globl	header_resize_file
	.section	.rodata
.LC112:
	.string	"RESIZE-FILE"
	.data
	.align 32
	.type	header_resize_file, @object
	.size	header_resize_file, 32
header_resize_file:
	.quad	header_reposition_file
	.quad	11
	.quad	.LC112
	.quad	code_resize_file
	.globl	key_resize_file
	.align 4
	.type	key_resize_file, @object
	.size	key_resize_file, 4
key_resize_file:
	.long	91
	.text
	.globl	code_resize_file
	.type	code_resize_file, @function
code_resize_file:
.LFB114:
	.cfi_startproc
	movq	sp(%rip), %rax
	leaq	16(%rax), %rbp
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	(%rax), %rbx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, %rdi
	call	fileno
	movq	%rbx, %rsi
	movl	%eax, %edi
	call	ftruncate
	cltq
	movq	%rax, 0(%rbp)
	addq	$16, sp(%rip)
	movq	sp(%rip), %rbx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	cmpq	$-1, %rax
	jne	.L299
	call	__errno_location
	movl	(%rax), %eax
	cltq
	jmp	.L300
.L299:
	movl	$0, %eax
.L300:
	movq	%rax, (%rbx)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE114:
	.size	code_resize_file, .-code_resize_file
	.globl	header_write_file
	.section	.rodata
.LC113:
	.string	"WRITE-FILE"
	.data
	.align 32
	.type	header_write_file, @object
	.size	header_write_file, 32
header_write_file:
	.quad	header_resize_file
	.quad	10
	.quad	.LC113
	.quad	code_write_file
	.globl	key_write_file
	.align 4
	.type	key_write_file, @object
	.size	key_write_file, 4
key_write_file:
	.long	92
	.text
	.globl	code_write_file
	.type	code_write_file, @function
code_write_file:
.LFB115:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	(%rax), %rcx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rdx
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	(%rax), %rax
	movl	$1, %esi
	movq	%rax, %rdi
	call	fwrite
	movq	%rax, c1(%rip)
	addq	$16, sp(%rip)
	movq	sp(%rip), %rax
	movq	$0, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE115:
	.size	code_write_file, .-code_write_file
	.globl	header_write_line
	.section	.rodata
.LC114:
	.string	"WRITE-LINE"
	.data
	.align 32
	.type	header_write_line, @object
	.size	header_write_line, 32
header_write_line:
	.quad	header_write_file
	.quad	10
	.quad	.LC114
	.quad	code_write_line
	.globl	key_write_line
	.align 4
	.type	key_write_line, @object
	.size	key_write_line, 4
key_write_line:
	.long	93
	.text
	.globl	code_write_line
	.type	code_write_line, @function
code_write_line:
.LFB116:
	.cfi_startproc
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rdx
	movq	sp(%rip), %rax
	addq	$16, %rax
	movq	(%rax), %rax
	movq	%rax, %rsi
	movl	$tempBuf, %edi
	call	strncpy
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movb	$10, tempBuf(%rax)
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	sp(%rip), %rdx
	addq	$8, %rdx
	movq	(%rdx), %rdx
	addq	$1, %rdx
	movq	%rax, %rcx
	movl	$1, %esi
	movl	$tempBuf, %edi
	call	fwrite
	movq	%rax, c1(%rip)
	addq	$16, sp(%rip)
	movq	sp(%rip), %rax
	movq	$0, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE116:
	.size	code_write_line, .-code_write_line
	.globl	header_flush_file
	.section	.rodata
.LC115:
	.string	"FLUSH-FILE"
	.data
	.align 32
	.type	header_flush_file, @object
	.size	header_flush_file, 32
header_flush_file:
	.quad	header_write_line
	.quad	10
	.quad	.LC115
	.quad	code_flush_file
	.globl	key_flush_file
	.align 4
	.type	key_flush_file, @object
	.size	key_flush_file, 4
key_flush_file:
	.long	94
	.text
	.globl	code_flush_file
	.type	code_flush_file, @function
code_flush_file:
.LFB117:
	.cfi_startproc
	movq	sp(%rip), %rbx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, %rdi
	call	fileno
	movl	%eax, %edi
	call	fsync
	cltq
	movq	%rax, (%rbx)
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	cmpq	$-1, %rax
	jne	.L307
	movq	sp(%rip), %rbx
	call	__errno_location
	movl	(%rax), %eax
	cltq
	movq	%rax, (%rbx)
.L307:
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE117:
	.size	code_flush_file, .-code_flush_file
	.globl	header_colon
	.section	.rodata
.LC116:
	.string	":"
	.data
	.align 32
	.type	header_colon, @object
	.size	header_colon, 32
header_colon:
	.quad	header_flush_file
	.quad	1
	.quad	.LC116
	.quad	code_colon
	.globl	key_colon
	.align 4
	.type	key_colon, @object
	.size	key_colon, 4
key_colon:
	.long	95
	.section	.rodata
	.align 8
.LC117:
	.string	"*** Colon definition with no name\n"
	.text
	.globl	code_colon
	.type	code_colon, @function
code_colon:
.LFB118:
	.cfi_startproc
	movq	dsp(%rip), %rax
	addq	$7, %rax
	andq	$-8, %rax
	movq	%rax, dsp(%rip)
	movq	dsp(%rip), %rax
	movq	%rax, tempHeader(%rip)
	addq	$32, dsp(%rip)
	movq	tempHeader(%rip), %rax
	movq	dictionary(%rip), %rdx
	movq	%rdx, (%rax)
	movq	tempHeader(%rip), %rax
	movq	%rax, dictionary(%rip)
	call	parse_name_
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	testq	%rax, %rax
	jne	.L310
	movq	stderr(%rip), %rcx
	movl	$34, %edx
	movl	$1, %esi
	movl	$.LC117, %edi
	call	fwrite
	call	code_quit
.L310:
	movq	tempHeader(%rip), %rbx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, %rdi
	call	malloc
	movq	%rax, 16(%rbx)
	movq	sp(%rip), %rax
	movq	(%rax), %rdx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rcx
	movq	tempHeader(%rip), %rax
	movq	16(%rax), %rax
	movq	%rcx, %rsi
	movq	%rax, %rdi
	call	strncpy
	movq	tempHeader(%rip), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rdx
	orb	$1, %dh
	movq	%rdx, 8(%rax)
	addq	$16, sp(%rip)
	movq	tempHeader(%rip), %rax
	movq	$code_docol, 24(%rax)
	movq	tempHeader(%rip), %rax
	addq	$24, %rax
	movq	%rax, lastWord(%rip)
	movq	$1, state(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE118:
	.size	code_colon, .-code_colon
	.globl	header_colon_no_name
	.section	.rodata
.LC118:
	.string	":NONAME"
	.data
	.align 32
	.type	header_colon_no_name, @object
	.size	header_colon_no_name, 32
header_colon_no_name:
	.quad	header_colon
	.quad	7
	.quad	.LC118
	.quad	code_colon_no_name
	.globl	key_colon_no_name
	.align 4
	.type	key_colon_no_name, @object
	.size	key_colon_no_name, 4
key_colon_no_name:
	.long	96
	.text
	.globl	code_colon_no_name
	.type	code_colon_no_name, @function
code_colon_no_name:
.LFB119:
	.cfi_startproc
	movq	dsp(%rip), %rax
	addq	$7, %rax
	andq	$-8, %rax
	movq	%rax, dsp(%rip)
	movq	dsp(%rip), %rax
	movq	%rax, lastWord(%rip)
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movq	dsp(%rip), %rdx
	movq	%rdx, (%rax)
	movq	dsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, dsp(%rip)
	movl	$code_docol, %edx
	movq	%rdx, (%rax)
	movq	$1, state(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE119:
	.size	code_colon_no_name, .-code_colon_no_name
	.globl	header_exit
	.section	.rodata
.LC119:
	.string	"EXIT"
	.data
	.align 32
	.type	header_exit, @object
	.size	header_exit, 32
header_exit:
	.quad	header_colon_no_name
	.quad	4
	.quad	.LC119
	.quad	code_exit
	.globl	key_exit
	.align 4
	.type	key_exit, @object
	.size	key_exit, 4
key_exit:
	.long	97
	.text
	.globl	code_exit
	.type	code_exit, @function
code_exit:
.LFB120:
	.cfi_startproc
        # TODO: I think the below (equivalent to EXIT_NEXT macro) can be
        # shortened everywhere it appears. Replace it with a GAS macro?
	movq	rsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, rsp(%rip)
	movq	(%rax), %rax
	movq	%rax, ip(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE120:
	.size	code_exit, .-code_exit
	.globl	header_see
	.section	.rodata
.LC120:
	.string	"SEE"
	.data
	.align 32
	.type	header_see, @object
	.size	header_see, 32
header_see:
	.quad	header_exit
	.quad	3
	.quad	.LC120
	.quad	code_see
	.globl	key_see
	.align 4
	.type	key_see, @object
	.size	key_see, 4
key_see:
	.long	98
	.section	.rodata
.LC121:
	.string	"Decompiling "
.LC122:
	.string	"NOT FOUND!"
	.align 8
.LC123:
	.string	"Not compiled using DOCOL; can't SEE native words."
.LC124:
	.string	"%lu: (literal) %ld\n"
.LC125:
	.string	"%lu: branch by %ld to: %lu\n"
.LC126:
	.string	"%d "
.LC127:
	.string	"\"%s\"\n"
.LC128:
	.string	"%lu: "
	.text
	.globl	code_see
	.type	code_see, @function
code_see:
.LFB121:
	.cfi_startproc
	call	parse_name_
	movl	$.LC121, %edi
	movl	$0, %eax
	call	printf
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rsi
	movq	%rax, %rdi
	call	print
	movl	$10, %edi
	call	putchar
	call	find_
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	testq	%rax, %rax
	jne	.L315
	movl	$.LC122, %edi
	call	puts
	jmp	.L316
.L315:
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	movq	%rax, cfa(%rip)
	movq	cfa(%rip), %rax
	movq	(%rax), %rax
	cmpq	$code_docol, %rax
	je	.L317
	movl	$.LC123, %edi
	call	puts
	jmp	.L316
.L317:
	movq	$0, tempHeader(%rip)
.L325:
	addq	$8, cfa(%rip)
	movq	tempHeader(%rip), %rax
	cmpq	$header_dolit, %rax
	jne	.L318
	movq	$0, tempHeader(%rip)
	movq	cfa(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, c1(%rip)
	movq	c1(%rip), %rdx
	movq	cfa(%rip), %rsi
	movl	$.LC124, %edi
	movl	$0, %eax
	call	printf
	jmp	.L319
.L318:
	movq	tempHeader(%rip), %rax
	cmpq	$header_zbranch, %rax
	je	.L320
	movq	tempHeader(%rip), %rax
	cmpq	$header_branch, %rax
	jne	.L321
.L320:
	movq	$0, tempHeader(%rip)
	movq	cfa(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, c1(%rip)
	movq	cfa(%rip), %rdx
	movq	c1(%rip), %rax
	addq	%rdx, %rax
	movq	%rax, c1(%rip)
	movq	cfa(%rip), %rax
	movq	(%rax), %rax
	movq	c1(%rip), %rcx
	movq	%rax, %rdx
	movq	cfa(%rip), %rsi
	movl	$.LC125, %edi
	movl	$0, %eax
	call	printf
	jmp	.L319
.L321:
	movq	tempHeader(%rip), %rax
	cmpq	$header_dostring, %rax
	jne	.L322
	movq	$0, tempHeader(%rip)
	movq	cfa(%rip), %rax
	movq	%rax, str1(%rip)
	movq	str1(%rip), %rax
	movzbl	(%rax), %eax
	movsbq	%al, %rax
	movq	%rax, c1(%rip)
	addq	$1, str1(%rip)
	movq	c1(%rip), %rdx
	movq	str1(%rip), %rsi
	movl	$tempBuf, %edi
	call	strncpy
	movq	c1(%rip), %rax
	movb	$0, tempBuf(%rax)
	jmp	.L323
.L324:
	movq	str1(%rip), %rax
	movzbl	(%rax), %eax
	movsbl	%al, %eax
	movl	%eax, %esi
	movl	$.LC126, %edi
	movl	$0, %eax
	call	printf
	addq	$1, str1(%rip)
	subq	$1, c1(%rip)
.L323:
	movq	c1(%rip), %rax
	testq	%rax, %rax
	jg	.L324
	movl	$tempBuf, %esi
	movl	$.LC127, %edi
	movl	$0, %eax
	call	printf
	movq	str1(%rip), %rax
	addq	$7, %rax
	andq	$-8, %rax
	movq	%rax, cfa(%rip)
	jmp	.L319
.L322:
	movq	cfa(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, str1(%rip)
	movq	str1(%rip), %rax
	subq	$24, %rax
	movq	%rax, tempHeader(%rip)
	movq	cfa(%rip), %rsi
	movl	$.LC128, %edi
	movl	$0, %eax
	call	printf
	movq	tempHeader(%rip), %rax
	movq	8(%rax), %rdx
	movq	tempHeader(%rip), %rax
	movzbl	%dl, %edx
	movq	16(%rax), %rax
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	print
	movl	$10, %edi
	call	putchar
.L319:
	movq	cfa(%rip), %rax
	movq	(%rax), %rax
	movl	$header_exit+24, %edx
	cmpq	%rdx, %rax
	je	.L316
	jmp	.L325
.L316:
	addq	$16, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE121:
	.size	code_see, .-code_see
	.globl	header_utime
	.section	.rodata
.LC129:
	.string	"UTIME"
	.data
	.align 32
	.type	header_utime, @object
	.size	header_utime, 32
header_utime:
	.quad	header_see
	.quad	5
	.quad	.LC129
	.quad	code_utime
	.globl	key_utime
	.align 4
	.type	key_utime, @object
	.size	key_utime, 4
key_utime:
	.long	106
	.text
	.globl	code_utime
	.type	code_utime, @function
code_utime:
.LFB122:
	.cfi_startproc
	movl	$0, %esi
	movl	$timeVal, %edi
	call	gettimeofday
	subq	$16, sp(%rip)
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	timeVal(%rip), %rdx
	imulq	$1000000, %rdx, %rdx
	movq	timeVal+8(%rip), %rcx
	addq	%rcx, %rdx
	movq	%rdx, (%rax)
	movq	sp(%rip), %rax
	movq	$0, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE122:
	.size	code_utime, .-code_utime
	.globl	header_semicolon
	.section	.rodata
.LC130:
	.string	";"
	.data
	.align 32
	.type	header_semicolon, @object
	.size	header_semicolon, 32
header_semicolon:
	.quad	header_utime
	.quad	513
	.quad	.LC130
	.quad	code_semicolon
	.globl	key_semicolon
	.align 4
	.type	key_semicolon, @object
	.size	key_semicolon, 4
key_semicolon:
	.long	99
	.text
	.globl	code_semicolon
	.type	code_semicolon, @function
code_semicolon:
.LFB123:
	.cfi_startproc
	movq	dictionary(%rip), %rax
	movq	dictionary(%rip), %rdx
	movq	8(%rdx), %rdx
	andb	$254, %dh
	movq	%rdx, 8(%rax)
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movl	$header_exit+24, %edx
	movq	%rdx, (%rax)
	movl	$0, %eax
	call	compile_
	jmp	.L330
.L331:
	call	drain_queue_
.L330:
	movl	queue_length(%rip), %eax
	testl	%eax, %eax
	jne	.L331
	movq	$0, state(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE123:
	.size	code_semicolon, .-code_semicolon
	.section	.rodata
	.align 8
.LC131:
	.string	"Could not load input file: %s\n"
	.text
	.globl	main
	.type	main, @function
main:
.LFB124:
	.cfi_startproc
	movl	%edi, 12(%rsp)
	movq	%rsi, (%rsp)
	movq	$header_semicolon, dictionary(%rip)
	movq	$10, base(%rip)
	movq	$0, inputIndex(%rip)
	movq	inputIndex(%rip), %rcx
	movq	inputIndex(%rip), %rax
	movq	inputIndex(%rip), %rdx
	movq	%rdx, %rsi
	salq	$5, %rsi
	addq	$inputSources+8, %rsi
	movq	$0, (%rsi)
	salq	$5, %rdx
	addq	$inputSources+8, %rdx
	movq	(%rdx), %rdx
	movq	%rax, %rsi
	salq	$5, %rsi
	addq	$inputSources, %rsi
	movq	%rdx, (%rsi)
	salq	$5, %rax
	addq	$inputSources, %rax
	movq	(%rax), %rax
	salq	$5, %rcx
	movq	%rcx, %rdx
	addq	$inputSources+16, %rdx
	movq	%rax, (%rdx)
	movq	inputIndex(%rip), %rax
	movq	inputIndex(%rip), %rdx
	salq	$8, %rdx
	addq	$parseBuffers, %rdx
	salq	$5, %rax
	addq	$inputSources+24, %rax
	movq	%rdx, (%rax)
	subl	$1, 12(%rsp)
	jmp	.L334
.L336:
	addq	$1, inputIndex(%rip)
	movq	inputIndex(%rip), %rbx
	movl	12(%rsp), %eax
	cltq
	leaq	0(,%rax,8), %rdx
	movq	(%rsp), %rax
	addq	%rdx, %rax
	movl	$.LC96, %esi
	movq	(%rax), %rdi
	call	fopen
	movq	%rax, %rdx
	movq	%rbx, %rax
	salq	$5, %rax
	addq	$inputSources+16, %rax
	movq	%rdx, (%rax)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+16, %rax
	movq	(%rax), %rax
	testq	%rax, %rax
	jne	.L335
	movl	12(%rsp), %eax
	cltq
	leaq	0(,%rax,8), %rdx
	movq	(%rsp), %rax
	addq	%rdx, %rax
	movq	(%rax), %rdx
	movl	$.LC131, %esi
	movq	stderr(%rip), %rdi
	movl	$0, %eax
	call	fprintf
	movl	$1, %edi
	call	exit
.L335:
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	$0, (%rax)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources, %rax
	movq	$0, (%rax)
	movq	inputIndex(%rip), %rax
	movq	inputIndex(%rip), %rdx
	salq	$8, %rdx
	addq	$parseBuffers, %rdx
	salq	$5, %rax
	addq	$inputSources+24, %rax
	movq	%rdx, (%rax)
	subl	$1, 12(%rsp)
.L334:
	cmpl	$0, 12(%rsp)
	jg	.L336
	addq	$1, inputIndex(%rip)
	movl	$16, %edi
	call	malloc
	movq	%rax, 24(%rsp)
	movq	24(%rsp), %rax
	movq	$_binary_lib_file_fs_start, (%rax)
	movq	24(%rsp), %rax
	movq	$_binary_lib_file_fs_end, 8(%rax)
	movq	inputIndex(%rip), %rax
	movq	24(%rsp), %rdx
	orq	$1, %rdx
	salq	$5, %rax
	addq	$inputSources+16, %rax
	movq	%rdx, (%rax)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	$0, (%rax)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources, %rax
	movq	$0, (%rax)
	movq	inputIndex(%rip), %rax
	movq	inputIndex(%rip), %rdx
	salq	$8, %rdx
	addq	$parseBuffers, %rdx
	salq	$5, %rax
	addq	$inputSources+24, %rax
	movq	%rdx, (%rax)
	addq	$1, inputIndex(%rip)
	movl	$16, %edi
	call	malloc
	movq	%rax, 24(%rsp)
	movq	24(%rsp), %rax
	movq	$_binary_lib_facility_fs_start, (%rax)
	movq	24(%rsp), %rax
	movq	$_binary_lib_facility_fs_end, 8(%rax)
	movq	inputIndex(%rip), %rax
	movq	24(%rsp), %rdx
	orq	$1, %rdx
	salq	$5, %rax
	addq	$inputSources+16, %rax
	movq	%rdx, (%rax)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	$0, (%rax)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources, %rax
	movq	$0, (%rax)
	movq	inputIndex(%rip), %rax
	movq	inputIndex(%rip), %rdx
	salq	$8, %rdx
	addq	$parseBuffers, %rdx
	salq	$5, %rax
	addq	$inputSources+24, %rax
	movq	%rdx, (%rax)
	addq	$1, inputIndex(%rip)
	movl	$16, %edi
	call	malloc
	movq	%rax, 24(%rsp)
	movq	24(%rsp), %rax
	movq	$_binary_lib_tools_fs_start, (%rax)
	movq	24(%rsp), %rax
	movq	$_binary_lib_tools_fs_end, 8(%rax)
	movq	inputIndex(%rip), %rax
	movq	24(%rsp), %rdx
	orq	$1, %rdx
	salq	$5, %rax
	addq	$inputSources+16, %rax
	movq	%rdx, (%rax)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	$0, (%rax)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources, %rax
	movq	$0, (%rax)
	movq	inputIndex(%rip), %rax
	movq	inputIndex(%rip), %rdx
	salq	$8, %rdx
	addq	$parseBuffers, %rdx
	salq	$5, %rax
	addq	$inputSources+24, %rax
	movq	%rdx, (%rax)
	addq	$1, inputIndex(%rip)
	movl	$16, %edi
	call	malloc
	movq	%rax, 24(%rsp)
	movq	24(%rsp), %rax
	movq	$_binary_lib_exception_fs_start, (%rax)
	movq	24(%rsp), %rax
	movq	$_binary_lib_exception_fs_end, 8(%rax)
	movq	inputIndex(%rip), %rax
	movq	24(%rsp), %rdx
	orq	$1, %rdx
	salq	$5, %rax
	addq	$inputSources+16, %rax
	movq	%rdx, (%rax)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	$0, (%rax)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources, %rax
	movq	$0, (%rax)
	movq	inputIndex(%rip), %rax
	movq	inputIndex(%rip), %rdx
	salq	$8, %rdx
	addq	$parseBuffers, %rdx
	salq	$5, %rax
	addq	$inputSources+24, %rax
	movq	%rdx, (%rax)
	addq	$1, inputIndex(%rip)
	movl	$16, %edi
	call	malloc
	movq	%rax, 24(%rsp)
	movq	24(%rsp), %rax
	movq	$_binary_lib_ext_fs_start, (%rax)
	movq	24(%rsp), %rax
	movq	$_binary_lib_ext_fs_end, 8(%rax)
	movq	inputIndex(%rip), %rax
	movq	24(%rsp), %rdx
	orq	$1, %rdx
	salq	$5, %rax
	addq	$inputSources+16, %rax
	movq	%rdx, (%rax)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	$0, (%rax)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources, %rax
	movq	$0, (%rax)
	movq	inputIndex(%rip), %rax
	movq	inputIndex(%rip), %rdx
	salq	$8, %rdx
	addq	$parseBuffers, %rdx
	salq	$5, %rax
	addq	$inputSources+24, %rax
	movq	%rdx, (%rax)
	addq	$1, inputIndex(%rip)
	movl	$16, %edi
	call	malloc
	movq	%rax, 24(%rsp)
	movq	24(%rsp), %rax
	movq	$_binary_lib_core_fs_start, (%rax)
	movq	24(%rsp), %rax
	movq	$_binary_lib_core_fs_end, 8(%rax)
	movq	inputIndex(%rip), %rax
	movq	24(%rsp), %rdx
	orq	$1, %rdx
	salq	$5, %rax
	addq	$inputSources+16, %rax
	movq	%rdx, (%rax)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+8, %rax
	movq	$0, (%rax)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources, %rax
	movq	$0, (%rax)
	movq	inputIndex(%rip), %rax
	movq	inputIndex(%rip), %rdx
	salq	$8, %rdx
	addq	$parseBuffers, %rdx
	salq	$5, %rax
	addq	$inputSources+24, %rax
	movq	%rdx, (%rax)
	call	init_primitives
	call	init_superinstructions
	call	quit_
	movl	$0, %eax
	addq	$32, %rsp
	.cfi_def_cfa_offset 16
	popq	%rbx
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE124:
	.size	main, .-main
	.globl	init_primitives
	.type	init_primitives, @function
init_primitives:
.LFB125:
	.cfi_startproc
	movl	key_plus(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_plus(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_plus, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_minus(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_minus(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_minus, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_times(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_times(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_times, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_div(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_div(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_div, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_udiv(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_udiv(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_udiv, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_mod(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_mod(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_mod, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_umod(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_umod(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_umod, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_and(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_and(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_and, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_or(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_or(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_or, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_xor(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_xor(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_xor, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_lshift(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_lshift(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_lshift, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_rshift(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_rshift(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_rshift, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_base(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_base(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_base, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_less_than(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_less_than(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_less_than, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_less_than_unsigned(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_less_than_unsigned(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_less_than_unsigned, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_equal(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_equal(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_equal, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_dup(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_dup(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_dup, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_swap(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_swap(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_swap, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_drop(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_drop(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_drop, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_over(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_over(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_over, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_rot(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_rot(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_rot, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_neg_rot(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_neg_rot(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_neg_rot, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_two_drop(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_two_drop(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_two_drop, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_two_dup(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_two_dup(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_two_dup, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_two_swap(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_two_swap(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_two_swap, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_two_over(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_two_over(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_two_over, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_to_r(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_to_r(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_to_r, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_from_r(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_from_r(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_from_r, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_fetch(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_fetch(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_fetch, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_store(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_store(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_store, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_cfetch(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_cfetch(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_cfetch, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_cstore(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_cstore(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_cstore, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_raw_alloc(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_raw_alloc(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_raw_alloc, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_here_ptr(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_here_ptr(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_here_ptr, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_print_internal(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_print_internal(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_print_internal, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_state(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_state(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_state, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_branch(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_branch(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_branch, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_zbranch(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_zbranch(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_zbranch, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_execute(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_execute(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_execute, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_evaluate(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_evaluate(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_evaluate, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_refill(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_refill(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_refill, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_accept(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_accept(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_accept, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_key(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_key(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_key, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_latest(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_latest(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_latest, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_in_ptr(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_in_ptr(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_in_ptr, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_emit(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_emit(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_emit, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_source(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_source(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_source, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_source_id(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_source_id(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_source_id, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_size_cell(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_size_cell(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_size_cell, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_size_char(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_size_char(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_size_char, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_cells(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_cells(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_cells, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_chars(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_chars(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_chars, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_unit_bits(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_unit_bits(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_unit_bits, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_stack_cells(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_stack_cells(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_stack_cells, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_return_stack_cells(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_return_stack_cells(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_return_stack_cells, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_to_does(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_to_does(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_to_does, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_to_cfa(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_to_cfa(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_to_cfa, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_to_body(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_to_body(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_to_body, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_last_word(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_last_word(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_last_word, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_docol(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_docol(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_docol, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_dolit(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_dolit(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_dolit, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_dostring(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_dostring(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_dostring, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_dodoes(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_dodoes(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_dodoes, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_parse(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_parse(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_parse, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_parse_name(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_parse_name(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_parse_name, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_to_number(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_to_number(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_to_number, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_create(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_create(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_create, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_find(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_find(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_find, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_depth(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_depth(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_depth, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_sp_fetch(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_sp_fetch(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_sp_fetch, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_sp_store(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_sp_store(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_sp_store, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_rp_fetch(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_rp_fetch(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_rp_fetch, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_rp_store(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_rp_store(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_rp_store, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_dot_s(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_dot_s(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_dot_s, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_u_dot_s(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_u_dot_s(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_u_dot_s, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_dump_file(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_dump_file(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_dump_file, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_quit(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_quit(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_quit, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_bye(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_bye(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_bye, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_compile_comma(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_compile_comma(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_compile_comma, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_debug_break(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_debug_break(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_debug_break, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_close_file(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_close_file(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_close_file, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_create_file(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_create_file(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_create_file, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_open_file(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_open_file(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_open_file, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_delete_file(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_delete_file(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_delete_file, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_file_position(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_file_position(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_file_position, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_file_size(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_file_size(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_file_size, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_file_size(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_file_size(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_file_size, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_include_file(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_include_file(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_include_file, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_read_file(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_read_file(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_read_file, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_read_line(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_read_line(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_read_line, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_reposition_file(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_reposition_file(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_reposition_file, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_resize_file(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_resize_file(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_resize_file, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_write_file(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_write_file(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_write_file, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_write_line(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_write_line(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_write_line, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_flush_file(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_flush_file(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_flush_file, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_colon(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_colon(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_colon, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_colon_no_name(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_colon_no_name(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_colon_no_name, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_exit(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_exit(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_exit, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_see(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_see(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_see, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_semicolon(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_semicolon(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_semicolon, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_literal(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_literal(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_literal, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_compile_literal(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_compile_literal(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_compile_literal, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_compile_zbranch(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_compile_zbranch(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_compile_zbranch, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_compile_branch(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_compile_branch(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_compile_branch, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_control_flush(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_control_flush(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_control_flush, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	movl	key_utime(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_utime(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_utime, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	nop
	ret
	.cfi_endproc
.LFE125:
	.size	init_primitives, .-init_primitives
	.globl	code_superinstruction_from_r_from_r
	.type	code_superinstruction_from_r_from_r, @function
code_superinstruction_from_r_from_r:
.LFB126:
	.cfi_startproc
	subq	$16, sp(%rip)
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	rsp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	movq	sp(%rip), %rax
	movq	rsp(%rip), %rdx
	movq	8(%rdx), %rdx
	movq	%rdx, (%rax)
	addq	$16, rsp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE126:
	.size	code_superinstruction_from_r_from_r, .-code_superinstruction_from_r_from_r
	.globl	code_superinstruction_fetch_exit
	.type	code_superinstruction_fetch_exit, @function
code_superinstruction_fetch_exit:
.LFB127:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rdx
	movq	(%rdx), %rdx
	movq	%rdx, (%rax)
	movq	rsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, rsp(%rip)
	movq	(%rax), %rax
	movq	%rax, ip(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE127:
	.size	code_superinstruction_fetch_exit, .-code_superinstruction_fetch_exit
	.globl	code_superinstruction_swap_to_r
	.type	code_superinstruction_swap_to_r, @function
code_superinstruction_swap_to_r:
.LFB128:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	8(%rax), %rax
	movq	%rax, c1(%rip)
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	addq	$8, sp(%rip)
	movq	rsp(%rip), %rax
	subq	$8, %rax
	movq	%rax, rsp(%rip)
	movq	rsp(%rip), %rax
	movq	c1(%rip), %rdx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE128:
	.size	code_superinstruction_swap_to_r, .-code_superinstruction_swap_to_r
	.globl	code_superinstruction_to_r_swap
	.type	code_superinstruction_to_r_swap, @function
code_superinstruction_to_r_swap:
.LFB129:
	.cfi_startproc
	movq	rsp(%rip), %rax
	subq	$8, %rax
	movq	%rax, rsp(%rip)
	movq	rsp(%rip), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rdx
	movq	%rdx, (%rax)
	movq	sp(%rip), %rax
	movq	16(%rax), %rax
	movq	%rax, c1(%rip)
	movq	sp(%rip), %rax
	leaq	16(%rax), %rdx
	movq	sp(%rip), %rax
	movq	8(%rax), %rax
	movq	%rax, (%rdx)
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	c1(%rip), %rax
	movq	%rax, (%rdx)
	addq	$8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE129:
	.size	code_superinstruction_to_r_swap, .-code_superinstruction_to_r_swap
	.globl	code_superinstruction_to_r_exit
	.type	code_superinstruction_to_r_exit, @function
code_superinstruction_to_r_exit:
.LFB130:
	.cfi_startproc
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, sp(%rip)
	movq	(%rax), %rax
	movq	%rax, ip(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE130:
	.size	code_superinstruction_to_r_exit, .-code_superinstruction_to_r_exit
	.globl	code_superinstruction_from_r_dup
	.type	code_superinstruction_from_r_dup, @function
code_superinstruction_from_r_dup:
.LFB131:
	.cfi_startproc
	subq	$16, sp(%rip)
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	rsp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	movq	sp(%rip), %rax
	movq	rsp(%rip), %rdx
	movq	(%rdx), %rdx
	movq	%rdx, (%rax)
	addq	$8, rsp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE131:
	.size	code_superinstruction_from_r_dup, .-code_superinstruction_from_r_dup
	.globl	code_superinstruction_dolit_equal
	.type	code_superinstruction_dolit_equal, @function
code_superinstruction_dolit_equal:
.LFB132:
	.cfi_startproc
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	movq	%rax, c1(%rip)
	movq	sp(%rip), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rcx
	movq	c1(%rip), %rdx
	cmpq	%rdx, %rcx
	jne	.L347
	movq	$-1, %rdx
	jmp	.L348
.L347:
	movl	$0, %edx
.L348:
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE132:
	.size	code_superinstruction_dolit_equal, .-code_superinstruction_dolit_equal
	.globl	code_superinstruction_dolit_fetch
	.type	code_superinstruction_dolit_fetch, @function
code_superinstruction_dolit_fetch:
.LFB133:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rdx
	movq	ip(%rip), %rax
	leaq	8(%rax), %rcx
	movq	%rcx, ip(%rip)
	movq	(%rax), %rax
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE133:
	.size	code_superinstruction_dolit_fetch, .-code_superinstruction_dolit_fetch
	.globl	code_superinstruction_dup_to_r
	.type	code_superinstruction_dup_to_r, @function
code_superinstruction_dup_to_r:
.LFB134:
	.cfi_startproc
	movq	rsp(%rip), %rax
	subq	$8, %rax
	movq	%rax, rsp(%rip)
	movq	rsp(%rip), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rdx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE134:
	.size	code_superinstruction_dup_to_r, .-code_superinstruction_dup_to_r
	.globl	code_superinstruction_dolit_dolit
	.type	code_superinstruction_dolit_dolit, @function
code_superinstruction_dolit_dolit:
.LFB135:
	.cfi_startproc
	subq	$16, sp(%rip)
	movq	sp(%rip), %rax
	leaq	8(%rax), %rcx
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	movq	%rax, (%rcx)
	movq	sp(%rip), %rdx
	movq	ip(%rip), %rax
	leaq	8(%rax), %rcx
	movq	%rcx, ip(%rip)
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE135:
	.size	code_superinstruction_dolit_dolit, .-code_superinstruction_dolit_dolit
	.globl	code_superinstruction_plus_exit
	.type	code_superinstruction_plus_exit, @function
code_superinstruction_plus_exit:
.LFB136:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	(%rax), %rcx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	sp(%rip), %rdx
	addq	$8, %rdx
	movq	(%rdx), %rdx
	addq	%rcx, %rdx
	movq	%rdx, (%rax)
	addq	$8, sp(%rip)
	movq	rsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, rsp(%rip)
	movq	(%rax), %rax
	movq	%rax, ip(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE136:
	.size	code_superinstruction_plus_exit, .-code_superinstruction_plus_exit
	.globl	code_superinstruction_dolit_plus
	.type	code_superinstruction_dolit_plus, @function
code_superinstruction_dolit_plus:
.LFB137:
	.cfi_startproc
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	movq	%rax, %rcx
	movq	sp(%rip), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rdx
	addq	%rcx, %rdx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE137:
	.size	code_superinstruction_dolit_plus, .-code_superinstruction_dolit_plus
	.globl	code_superinstruction_dolit_less_than
	.type	code_superinstruction_dolit_less_than, @function
code_superinstruction_dolit_less_than:
.LFB138:
	.cfi_startproc
	movq	sp(%rip), %rdx
	movq	sp(%rip), %rax
	movq	(%rax), %rsi
	movq	ip(%rip), %rax
	leaq	8(%rax), %rcx
	movq	%rcx, ip(%rip)
	movq	(%rax), %rax
	cmpq	%rax, %rsi
	jge	.L355
	movq	$-1, %rax
	jmp	.L356
.L355:
	movl	$0, %eax
.L356:
	movq	%rax, (%rdx)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE138:
	.size	code_superinstruction_dolit_less_than, .-code_superinstruction_dolit_less_than
	.globl	code_superinstruction_plus_fetch
	.type	code_superinstruction_plus_fetch, @function
code_superinstruction_plus_fetch:
.LFB139:
	.cfi_startproc
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	sp(%rip), %rax
	movq	(%rax), %rcx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	addq	%rcx, %rax
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	addq	$8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE139:
	.size	code_superinstruction_plus_fetch, .-code_superinstruction_plus_fetch
	.globl	code_superinstruction_to_r_to_r
	.type	code_superinstruction_to_r_to_r, @function
code_superinstruction_to_r_to_r:
.LFB140:
	.cfi_startproc
	subq	$16, rsp(%rip)
	movq	rsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	movq	rsp(%rip), %rax
	movq	sp(%rip), %rdx
	movq	8(%rdx), %rdx
	movq	%rdx, (%rax)
	addq	$16, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE140:
	.size	code_superinstruction_to_r_to_r, .-code_superinstruction_to_r_to_r
	.globl	code_superinstruction_dolit_call_
	.type	code_superinstruction_dolit_call_, @function
code_superinstruction_dolit_call_:
.LFB141:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rdx
	movq	ip(%rip), %rax
	leaq	8(%rax), %rcx
	movq	%rcx, ip(%rip)
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	movq	%rax, ca(%rip)
	movq	rsp(%rip), %rax
	subq	$8, %rax
	movq	%rax, rsp(%rip)
	movq	rsp(%rip), %rax
	movq	ip(%rip), %rdx
	movq	%rdx, (%rax)
	movq	ca(%rip), %rax
	movq	%rax, ip(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE141:
	.size	code_superinstruction_dolit_call_, .-code_superinstruction_dolit_call_
	.globl	code_superinstruction_equal_exit
	.type	code_superinstruction_equal_exit, @function
code_superinstruction_equal_exit:
.LFB142:
	.cfi_startproc
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rcx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	cmpq	%rax, %rcx
	jne	.L361
	movq	$-1, %rax
	jmp	.L362
.L361:
	movl	$0, %eax
.L362:
	movq	%rax, (%rdx)
	addq	$8, sp(%rip)
	movq	rsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, rsp(%rip)
	movq	(%rax), %rax
	movq	%rax, ip(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE142:
	.size	code_superinstruction_equal_exit, .-code_superinstruction_equal_exit
	.globl	code_superinstruction_to_r_swap_from_r
	.type	code_superinstruction_to_r_swap_from_r, @function
code_superinstruction_to_r_swap_from_r:
.LFB143:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	16(%rax), %rax
	movq	%rax, c1(%rip)
	movq	sp(%rip), %rax
	leaq	16(%rax), %rdx
	movq	sp(%rip), %rax
	movq	8(%rax), %rax
	movq	%rax, (%rdx)
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	c1(%rip), %rax
	movq	%rax, (%rdx)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE143:
	.size	code_superinstruction_to_r_swap_from_r, .-code_superinstruction_to_r_swap_from_r
	.globl	code_superinstruction_swap_to_r_exit
	.type	code_superinstruction_swap_to_r_exit, @function
code_superinstruction_swap_to_r_exit:
.LFB144:
	.cfi_startproc
	movq	rsp(%rip), %rax
	subq	$8, %rax
	movq	%rax, rsp(%rip)
	movq	rsp(%rip), %rax
	movq	sp(%rip), %rdx
	movq	8(%rdx), %rdx
	movq	%rdx, (%rax)
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	addq	$8, sp(%rip)
	movq	rsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, rsp(%rip)
	movq	(%rax), %rax
	movq	%rax, ip(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE144:
	.size	code_superinstruction_swap_to_r_exit, .-code_superinstruction_swap_to_r_exit
	.globl	code_superinstruction_from_r_from_r_dup
	.type	code_superinstruction_from_r_from_r_dup, @function
code_superinstruction_from_r_from_r_dup:
.LFB145:
	.cfi_startproc
	subq	$24, sp(%rip)
	movq	sp(%rip), %rax
	leaq	16(%rax), %rdx
	movq	rsp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	movq	sp(%rip), %rdx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	rsp(%rip), %rcx
	movq	8(%rcx), %rcx
	movq	%rcx, (%rax)
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	addq	$16, rsp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE145:
	.size	code_superinstruction_from_r_from_r_dup, .-code_superinstruction_from_r_from_r_dup
	.globl	code_superinstruction_dup_to_r_swap
	.type	code_superinstruction_dup_to_r_swap, @function
code_superinstruction_dup_to_r_swap:
.LFB146:
	.cfi_startproc
	movq	rsp(%rip), %rax
	subq	$8, %rax
	movq	%rax, rsp(%rip)
	movq	rsp(%rip), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rdx
	movq	%rdx, (%rax)
	movq	sp(%rip), %rax
	movq	8(%rax), %rax
	movq	%rax, c1(%rip)
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	movq	sp(%rip), %rax
	movq	c1(%rip), %rdx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE146:
	.size	code_superinstruction_dup_to_r_swap, .-code_superinstruction_dup_to_r_swap
	.globl	code_superinstruction_from_r_dup_to_r
	.type	code_superinstruction_from_r_dup_to_r, @function
code_superinstruction_from_r_dup_to_r:
.LFB147:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movq	rsp(%rip), %rdx
	movq	(%rdx), %rdx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE147:
	.size	code_superinstruction_from_r_dup_to_r, .-code_superinstruction_from_r_dup_to_r
	.globl	code_superinstruction_dolit_fetch_exit
	.type	code_superinstruction_dolit_fetch_exit, @function
code_superinstruction_dolit_fetch_exit:
.LFB148:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rdx
	movq	ip(%rip), %rax
	leaq	8(%rax), %rcx
	movq	%rcx, ip(%rip)
	movq	(%rax), %rax
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	movq	rsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, rsp(%rip)
	movq	(%rax), %rax
	movq	%rax, ip(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE148:
	.size	code_superinstruction_dolit_fetch_exit, .-code_superinstruction_dolit_fetch_exit
	.globl	code_superinstruction_dolit_plus_exit
	.type	code_superinstruction_dolit_plus_exit, @function
code_superinstruction_dolit_plus_exit:
.LFB149:
	.cfi_startproc
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	movq	%rax, %rcx
	movq	sp(%rip), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rdx
	addq	%rcx, %rdx
	movq	%rdx, (%rax)
	movq	rsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, rsp(%rip)
	movq	(%rax), %rax
	movq	%rax, ip(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE149:
	.size	code_superinstruction_dolit_plus_exit, .-code_superinstruction_dolit_plus_exit
	.globl	code_superinstruction_dolit_less_than_exit
	.type	code_superinstruction_dolit_less_than_exit, @function
code_superinstruction_dolit_less_than_exit:
.LFB150:
	.cfi_startproc
	movq	sp(%rip), %rdx
	movq	sp(%rip), %rax
	movq	(%rax), %rsi
	movq	ip(%rip), %rax
	leaq	8(%rax), %rcx
	movq	%rcx, ip(%rip)
	movq	(%rax), %rax
	cmpq	%rax, %rsi
	jge	.L371
	movq	$-1, %rax
	jmp	.L372
.L371:
	movl	$0, %eax
.L372:
	movq	%rax, (%rdx)
	movq	rsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, rsp(%rip)
	movq	(%rax), %rax
	movq	%rax, ip(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE150:
	.size	code_superinstruction_dolit_less_than_exit, .-code_superinstruction_dolit_less_than_exit
	.globl	code_superinstruction_dolit_dolit_plus
	.type	code_superinstruction_dolit_dolit_plus, @function
code_superinstruction_dolit_dolit_plus:
.LFB151:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movq	ip(%rip), %rdx
	movq	(%rdx), %rcx
	movq	ip(%rip), %rdx
	movq	8(%rdx), %rdx
	addq	%rcx, %rdx
	movq	%rdx, (%rax)
	addq	$16, ip(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE151:
	.size	code_superinstruction_dolit_dolit_plus, .-code_superinstruction_dolit_dolit_plus
	.globl	code_superinstruction_cells_sp_fetch_plus
	.type	code_superinstruction_cells_sp_fetch_plus, @function
code_superinstruction_cells_sp_fetch_plus:
.LFB152:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rdx
	leaq	0(,%rdx,8), %rcx
	movq	sp(%rip), %rdx
	addq	%rcx, %rdx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE152:
	.size	code_superinstruction_cells_sp_fetch_plus, .-code_superinstruction_cells_sp_fetch_plus
	.globl	code_superinstruction_to_r_swap_to_r
	.type	code_superinstruction_to_r_swap_to_r, @function
code_superinstruction_to_r_swap_to_r:
.LFB153:
	.cfi_startproc
	movq	rsp(%rip), %rax
	subq	$8, %rax
	movq	%rax, rsp(%rip)
	movq	rsp(%rip), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rdx
	movq	%rdx, (%rax)
	movq	rsp(%rip), %rax
	subq	$8, %rax
	movq	%rax, rsp(%rip)
	movq	rsp(%rip), %rax
	movq	sp(%rip), %rdx
	movq	16(%rdx), %rdx
	movq	%rdx, (%rax)
	movq	sp(%rip), %rax
	leaq	16(%rax), %rdx
	movq	sp(%rip), %rax
	movq	8(%rax), %rax
	movq	%rax, (%rdx)
	addq	$16, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE153:
	.size	code_superinstruction_to_r_swap_to_r, .-code_superinstruction_to_r_swap_to_r
	.globl	code_superinstruction_dolit_equal_exit
	.type	code_superinstruction_dolit_equal_exit, @function
code_superinstruction_dolit_equal_exit:
.LFB154:
	.cfi_startproc
	movq	sp(%rip), %rdx
	movq	sp(%rip), %rax
	movq	(%rax), %rsi
	movq	ip(%rip), %rax
	leaq	8(%rax), %rcx
	movq	%rcx, ip(%rip)
	movq	(%rax), %rax
	cmpq	%rax, %rsi
	jne	.L377
	movq	$-1, %rax
	jmp	.L378
.L377:
	movl	$0, %eax
.L378:
	movq	%rax, (%rdx)
	movq	rsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, rsp(%rip)
	movq	(%rax), %rax
	movq	%rax, ip(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE154:
	.size	code_superinstruction_dolit_equal_exit, .-code_superinstruction_dolit_equal_exit
	.globl	code_superinstruction_sp_fetch_plus_fetch
	.type	code_superinstruction_sp_fetch_plus_fetch, @function
code_superinstruction_sp_fetch_plus_fetch:
.LFB155:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rdx
	leaq	0(,%rdx,8), %rcx
	movq	sp(%rip), %rdx
	addq	%rcx, %rdx
	movq	(%rdx), %rdx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE155:
	.size	code_superinstruction_sp_fetch_plus_fetch, .-code_superinstruction_sp_fetch_plus_fetch
	.globl	code_superinstruction_plus_fetch_exit
	.type	code_superinstruction_plus_fetch_exit, @function
code_superinstruction_plus_fetch_exit:
.LFB156:
	.cfi_startproc
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	sp(%rip), %rax
	movq	(%rax), %rcx
	movq	sp(%rip), %rax
	addq	$8, %rax
	movq	(%rax), %rax
	salq	$3, %rcx
	addq	%rcx, %rax
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	addq	$8, sp(%rip)
	movq	rsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, rsp(%rip)
	movq	(%rax), %rax
	movq	%rax, ip(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE156:
	.size	code_superinstruction_plus_fetch_exit, .-code_superinstruction_plus_fetch_exit
	.globl	code_superinstruction_from_r_from_r_two_dup
	.type	code_superinstruction_from_r_from_r_two_dup, @function
code_superinstruction_from_r_from_r_two_dup:
.LFB157:
	.cfi_startproc
	subq	$32, sp(%rip)
	movq	sp(%rip), %rax
	leaq	24(%rax), %rdx
	movq	rsp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	rsp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	movq	sp(%rip), %rax
	leaq	16(%rax), %rdx
	movq	rsp(%rip), %rax
	movq	8(%rax), %rax
	movq	%rax, (%rdx)
	movq	sp(%rip), %rax
	movq	rsp(%rip), %rdx
	movq	8(%rdx), %rdx
	movq	%rdx, (%rax)
	addq	$16, rsp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE157:
	.size	code_superinstruction_from_r_from_r_two_dup, .-code_superinstruction_from_r_from_r_two_dup
	.globl	code_superinstruction_neg_rot_plus_to_r
	.type	code_superinstruction_neg_rot_plus_to_r, @function
code_superinstruction_neg_rot_plus_to_r:
.LFB158:
	.cfi_startproc
	movq	rsp(%rip), %rax
	subq	$8, %rax
	movq	%rax, rsp(%rip)
	movq	rsp(%rip), %rax
	movq	sp(%rip), %rdx
	addq	$8, %rdx
	movq	(%rdx), %rcx
	movq	sp(%rip), %rdx
	addq	$16, %rdx
	movq	(%rdx), %rdx
	addq	%rcx, %rdx
	movq	%rdx, (%rax)
	movq	sp(%rip), %rax
	leaq	16(%rax), %rdx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	addq	$16, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE158:
	.size	code_superinstruction_neg_rot_plus_to_r, .-code_superinstruction_neg_rot_plus_to_r
	.globl	code_superinstruction_two_dup_minus_to_r
	.type	code_superinstruction_two_dup_minus_to_r, @function
code_superinstruction_two_dup_minus_to_r:
.LFB159:
	.cfi_startproc
	movq	rsp(%rip), %rax
	subq	$8, %rax
	movq	%rax, rsp(%rip)
	movq	rsp(%rip), %rax
	movq	sp(%rip), %rdx
	addq	$8, %rdx
	movq	(%rdx), %rcx
	movq	sp(%rip), %rdx
	movq	(%rdx), %rdx
	subq	%rdx, %rcx
	movq	%rcx, %rdx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE159:
	.size	code_superinstruction_two_dup_minus_to_r, .-code_superinstruction_two_dup_minus_to_r
	.globl	code_superinstruction_to_r_swap_to_r_exit
	.type	code_superinstruction_to_r_swap_to_r_exit, @function
code_superinstruction_to_r_swap_to_r_exit:
.LFB160:
	.cfi_startproc
	movq	rsp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, c1(%rip)
	movq	rsp(%rip), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rdx
	movq	%rdx, (%rax)
	movq	sp(%rip), %rax
	movq	c1(%rip), %rdx
	movq	%rdx, (%rax)
	movq	rsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, rsp(%rip)
	movq	(%rax), %rax
	movq	%rax, ip(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE160:
	.size	code_superinstruction_to_r_swap_to_r_exit, .-code_superinstruction_to_r_swap_to_r_exit
	.globl	code_superinstruction_dup_to_r_swap_to_r
	.type	code_superinstruction_dup_to_r_swap_to_r, @function
code_superinstruction_dup_to_r_swap_to_r:
.LFB161:
	.cfi_startproc
	subq	$16, rsp(%rip)
	movq	rsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	movq	rsp(%rip), %rax
	movq	sp(%rip), %rdx
	movq	8(%rdx), %rdx
	movq	%rdx, (%rax)
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	sp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	addq	$8, sp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE161:
	.size	code_superinstruction_dup_to_r_swap_to_r, .-code_superinstruction_dup_to_r_swap_to_r
	.globl	code_superinstruction_from_r_dup_to_r_swap
	.type	code_superinstruction_from_r_dup_to_r_swap, @function
code_superinstruction_from_r_dup_to_r_swap:
.LFB162:
	.cfi_startproc
	addq	$8, sp(%rip)
	movq	sp(%rip), %rax
	movq	sp(%rip), %rdx
	movq	8(%rdx), %rdx
	movq	%rdx, (%rax)
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	rsp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE162:
	.size	code_superinstruction_from_r_dup_to_r_swap, .-code_superinstruction_from_r_dup_to_r_swap
	.globl	code_superinstruction_from_r_from_r_dup_to_r
	.type	code_superinstruction_from_r_from_r_dup_to_r, @function
code_superinstruction_from_r_from_r_dup_to_r:
.LFB163:
	.cfi_startproc
	subq	$16, sp(%rip)
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	rsp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	movq	sp(%rip), %rax
	movq	rsp(%rip), %rdx
	movq	8(%rdx), %rdx
	movq	%rdx, (%rax)
	addq	$8, rsp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE163:
	.size	code_superinstruction_from_r_from_r_dup_to_r, .-code_superinstruction_from_r_from_r_dup_to_r
	.globl	code_superinstruction_cells_sp_fetch_plus_fetch
	.type	code_superinstruction_cells_sp_fetch_plus_fetch, @function
code_superinstruction_cells_sp_fetch_plus_fetch:
.LFB164:
	.cfi_startproc
	movq	sp(%rip), %rax
	movq	sp(%rip), %rdx
	movq	(%rdx), %rdx
	leaq	0(,%rdx,8), %rcx
	movq	sp(%rip), %rdx
	addq	%rcx, %rdx
	movq	(%rdx), %rdx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE164:
	.size	code_superinstruction_cells_sp_fetch_plus_fetch, .-code_superinstruction_cells_sp_fetch_plus_fetch
	.globl	code_superinstruction_two_dup_minus_to_r_dolit
	.type	code_superinstruction_two_dup_minus_to_r_dolit, @function
code_superinstruction_two_dup_minus_to_r_dolit:
.LFB165:
	.cfi_startproc
	movq	rsp(%rip), %rax
	subq	$8, %rax
	movq	%rax, rsp(%rip)
	movq	rsp(%rip), %rax
	movq	sp(%rip), %rdx
	addq	$8, %rdx
	movq	(%rdx), %rcx
	movq	sp(%rip), %rdx
	movq	(%rdx), %rdx
	subq	%rdx, %rcx
	movq	%rcx, %rdx
	movq	%rdx, (%rax)
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rdx
	movq	ip(%rip), %rax
	leaq	8(%rax), %rcx
	movq	%rcx, ip(%rip)
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE165:
	.size	code_superinstruction_two_dup_minus_to_r_dolit, .-code_superinstruction_two_dup_minus_to_r_dolit
	.globl	code_superinstruction_from_r_two_dup_minus_to_r
	.type	code_superinstruction_from_r_two_dup_minus_to_r, @function
code_superinstruction_from_r_two_dup_minus_to_r:
.LFB166:
	.cfi_startproc
	movq	sp(%rip), %rax
	subq	$8, %rax
	movq	%rax, sp(%rip)
	movq	sp(%rip), %rax
	movq	rsp(%rip), %rdx
	movq	(%rdx), %rdx
	movq	%rdx, (%rax)
	movq	rsp(%rip), %rax
	movq	sp(%rip), %rdx
	addq	$8, %rdx
	movq	(%rdx), %rcx
	movq	sp(%rip), %rdx
	movq	(%rdx), %rdx
	subq	%rdx, %rcx
	movq	%rcx, %rdx
	movq	%rdx, (%rax)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE166:
	.size	code_superinstruction_from_r_two_dup_minus_to_r, .-code_superinstruction_from_r_two_dup_minus_to_r
	.globl	code_superinstruction_from_r_from_r_two_dup_minus
	.type	code_superinstruction_from_r_from_r_two_dup_minus, @function
code_superinstruction_from_r_from_r_two_dup_minus:
.LFB167:
	.cfi_startproc
	subq	$24, sp(%rip)
	movq	sp(%rip), %rax
	leaq	16(%rax), %rdx
	movq	rsp(%rip), %rax
	movq	(%rax), %rax
	movq	%rax, (%rdx)
	movq	sp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	rsp(%rip), %rax
	movq	8(%rax), %rax
	movq	%rax, (%rdx)
	movq	sp(%rip), %rax
	movq	sp(%rip), %rdx
	addq	$16, %rdx
	movq	(%rdx), %rcx
	movq	sp(%rip), %rdx
	addq	$8, %rdx
	movq	(%rdx), %rdx
	subq	%rdx, %rcx
	movq	%rcx, %rdx
	movq	%rdx, (%rax)
	addq	$16, rsp(%rip)
	movq	ip(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, ip(%rip)
	movq	(%rax), %rax
	jmp	*%rax
	.cfi_endproc
.LFE167:
	.size	code_superinstruction_from_r_from_r_two_dup_minus, .-code_superinstruction_from_r_from_r_two_dup_minus
	.globl	init_superinstructions
	.type	init_superinstructions, @function
init_superinstructions:
.LFB168:
	.cfi_startproc
	movl	$0, nextSuperinstruction(%rip)
	movl	nextSuperinstruction(%rip), %edx
	movl	key_from_r(%rip), %eax
	sall	$8, %eax
	orl	key_from_r(%rip), %eax
	movslq	%edx, %rdx
	salq	$4, %rdx
	addq	$superinstructions+8, %rdx
	movl	%eax, (%rdx)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_from_r_from_r, (%rax)
	movl	nextSuperinstruction(%rip), %edx
	movl	key_exit(%rip), %eax
	sall	$8, %eax
	orl	key_fetch(%rip), %eax
	movslq	%edx, %rdx
	salq	$4, %rdx
	addq	$superinstructions+8, %rdx
	movl	%eax, (%rdx)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_fetch_exit, (%rax)
	movl	nextSuperinstruction(%rip), %edx
	movl	key_to_r(%rip), %eax
	sall	$8, %eax
	orl	key_swap(%rip), %eax
	movslq	%edx, %rdx
	salq	$4, %rdx
	addq	$superinstructions+8, %rdx
	movl	%eax, (%rdx)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_swap_to_r, (%rax)
	movl	nextSuperinstruction(%rip), %edx
	movl	key_swap(%rip), %eax
	sall	$8, %eax
	orl	key_to_r(%rip), %eax
	movslq	%edx, %rdx
	salq	$4, %rdx
	addq	$superinstructions+8, %rdx
	movl	%eax, (%rdx)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_to_r_swap, (%rax)
	movl	nextSuperinstruction(%rip), %edx
	movl	key_exit(%rip), %eax
	sall	$8, %eax
	orl	key_to_r(%rip), %eax
	movslq	%edx, %rdx
	salq	$4, %rdx
	addq	$superinstructions+8, %rdx
	movl	%eax, (%rdx)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_to_r_exit, (%rax)
	movl	nextSuperinstruction(%rip), %edx
	movl	key_dup(%rip), %eax
	sall	$8, %eax
	orl	key_from_r(%rip), %eax
	movslq	%edx, %rdx
	salq	$4, %rdx
	addq	$superinstructions+8, %rdx
	movl	%eax, (%rdx)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_from_r_dup, (%rax)
	movl	nextSuperinstruction(%rip), %edx
	movl	key_equal(%rip), %eax
	sall	$8, %eax
	orl	key_dolit(%rip), %eax
	movslq	%edx, %rdx
	salq	$4, %rdx
	addq	$superinstructions+8, %rdx
	movl	%eax, (%rdx)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_dolit_equal, (%rax)
	movl	nextSuperinstruction(%rip), %edx
	movl	key_fetch(%rip), %eax
	sall	$8, %eax
	orl	key_dolit(%rip), %eax
	movslq	%edx, %rdx
	salq	$4, %rdx
	addq	$superinstructions+8, %rdx
	movl	%eax, (%rdx)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_dolit_fetch, (%rax)
	movl	nextSuperinstruction(%rip), %edx
	movl	key_to_r(%rip), %eax
	sall	$8, %eax
	orl	key_dup(%rip), %eax
	movslq	%edx, %rdx
	salq	$4, %rdx
	addq	$superinstructions+8, %rdx
	movl	%eax, (%rdx)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_dup_to_r, (%rax)
	movl	nextSuperinstruction(%rip), %edx
	movl	key_dolit(%rip), %eax
	sall	$8, %eax
	orl	key_dolit(%rip), %eax
	movslq	%edx, %rdx
	salq	$4, %rdx
	addq	$superinstructions+8, %rdx
	movl	%eax, (%rdx)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_dolit_dolit, (%rax)
	movl	nextSuperinstruction(%rip), %edx
	movl	key_exit(%rip), %eax
	sall	$8, %eax
	orl	key_plus(%rip), %eax
	movslq	%edx, %rdx
	salq	$4, %rdx
	addq	$superinstructions+8, %rdx
	movl	%eax, (%rdx)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_plus_exit, (%rax)
	movl	nextSuperinstruction(%rip), %edx
	movl	key_plus(%rip), %eax
	sall	$8, %eax
	orl	key_dolit(%rip), %eax
	movslq	%edx, %rdx
	salq	$4, %rdx
	addq	$superinstructions+8, %rdx
	movl	%eax, (%rdx)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_dolit_plus, (%rax)
	movl	nextSuperinstruction(%rip), %edx
	movl	key_less_than(%rip), %eax
	sall	$8, %eax
	orl	key_dolit(%rip), %eax
	movslq	%edx, %rdx
	salq	$4, %rdx
	addq	$superinstructions+8, %rdx
	movl	%eax, (%rdx)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_dolit_less_than, (%rax)
	movl	nextSuperinstruction(%rip), %edx
	movl	key_fetch(%rip), %eax
	sall	$8, %eax
	orl	key_plus(%rip), %eax
	movslq	%edx, %rdx
	salq	$4, %rdx
	addq	$superinstructions+8, %rdx
	movl	%eax, (%rdx)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_plus_fetch, (%rax)
	movl	nextSuperinstruction(%rip), %edx
	movl	key_to_r(%rip), %eax
	sall	$8, %eax
	orl	key_to_r(%rip), %eax
	movslq	%edx, %rdx
	salq	$4, %rdx
	addq	$superinstructions+8, %rdx
	movl	%eax, (%rdx)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_to_r_to_r, (%rax)
	movl	nextSuperinstruction(%rip), %edx
	movl	key_call_(%rip), %eax
	sall	$8, %eax
	orl	key_dolit(%rip), %eax
	movslq	%edx, %rdx
	salq	$4, %rdx
	addq	$superinstructions+8, %rdx
	movl	%eax, (%rdx)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_dolit_call_, (%rax)
	movl	nextSuperinstruction(%rip), %edx
	movl	key_exit(%rip), %eax
	sall	$8, %eax
	orl	key_equal(%rip), %eax
	movslq	%edx, %rdx
	salq	$4, %rdx
	addq	$superinstructions+8, %rdx
	movl	%eax, (%rdx)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_equal_exit, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_swap(%rip), %edx
	sall	$8, %edx
	orl	key_to_r(%rip), %edx
	movl	key_from_r(%rip), %ecx
	sall	$16, %ecx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_to_r_swap_from_r, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_to_r(%rip), %edx
	sall	$8, %edx
	orl	key_swap(%rip), %edx
	movl	key_exit(%rip), %ecx
	sall	$16, %ecx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_swap_to_r_exit, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_from_r(%rip), %edx
	sall	$8, %edx
	orl	key_from_r(%rip), %edx
	movl	key_dup(%rip), %ecx
	sall	$16, %ecx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_from_r_from_r_dup, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_to_r(%rip), %edx
	sall	$8, %edx
	orl	key_dup(%rip), %edx
	movl	key_swap(%rip), %ecx
	sall	$16, %ecx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_dup_to_r_swap, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_sp_fetch(%rip), %edx
	sall	$8, %edx
	orl	key_cells(%rip), %edx
	movl	key_plus(%rip), %ecx
	sall	$16, %ecx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_cells_sp_fetch_plus, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_swap(%rip), %edx
	sall	$8, %edx
	orl	key_to_r(%rip), %edx
	movl	key_to_r(%rip), %ecx
	sall	$16, %ecx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_to_r_swap_to_r, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_equal(%rip), %edx
	sall	$8, %edx
	orl	key_dolit(%rip), %edx
	movl	key_exit(%rip), %ecx
	sall	$16, %ecx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_dolit_equal_exit, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_dup(%rip), %edx
	sall	$8, %edx
	orl	key_from_r(%rip), %edx
	movl	key_to_r(%rip), %ecx
	sall	$16, %ecx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_from_r_dup_to_r, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_plus(%rip), %edx
	sall	$8, %edx
	orl	key_dolit(%rip), %edx
	movl	key_exit(%rip), %ecx
	sall	$16, %ecx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_dolit_plus_exit, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_less_than(%rip), %edx
	sall	$8, %edx
	orl	key_dolit(%rip), %edx
	movl	key_exit(%rip), %ecx
	sall	$16, %ecx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_dolit_less_than_exit, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_plus(%rip), %edx
	sall	$8, %edx
	orl	key_sp_fetch(%rip), %edx
	movl	key_fetch(%rip), %ecx
	sall	$16, %ecx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_sp_fetch_plus_fetch, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_fetch(%rip), %edx
	sall	$8, %edx
	orl	key_plus(%rip), %edx
	movl	key_exit(%rip), %ecx
	sall	$16, %ecx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_plus_fetch_exit, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_from_r(%rip), %edx
	sall	$8, %edx
	orl	key_from_r(%rip), %edx
	movl	key_two_dup(%rip), %ecx
	sall	$16, %ecx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_from_r_from_r_two_dup, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_plus(%rip), %edx
	sall	$8, %edx
	orl	key_neg_rot(%rip), %edx
	movl	key_to_r(%rip), %ecx
	sall	$16, %ecx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_neg_rot_plus_to_r, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_minus(%rip), %edx
	sall	$8, %edx
	orl	key_two_dup(%rip), %edx
	movl	key_to_r(%rip), %ecx
	sall	$16, %ecx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_two_dup_minus_to_r, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_swap(%rip), %edx
	sall	$8, %edx
	orl	key_to_r(%rip), %edx
	movl	key_to_r(%rip), %ecx
	sall	$16, %ecx
	orl	%edx, %ecx
	movl	key_exit(%rip), %edx
	sall	$24, %edx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_to_r_swap_to_r_exit, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_to_r(%rip), %edx
	sall	$8, %edx
	orl	key_dup(%rip), %edx
	movl	key_swap(%rip), %ecx
	sall	$16, %ecx
	orl	%edx, %ecx
	movl	key_to_r(%rip), %edx
	sall	$24, %edx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_dup_to_r_swap_to_r, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_dup(%rip), %edx
	sall	$8, %edx
	orl	key_from_r(%rip), %edx
	movl	key_to_r(%rip), %ecx
	sall	$16, %ecx
	orl	%edx, %ecx
	movl	key_swap(%rip), %edx
	sall	$24, %edx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_from_r_dup_to_r_swap, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_from_r(%rip), %edx
	sall	$8, %edx
	orl	key_from_r(%rip), %edx
	movl	key_dup(%rip), %ecx
	sall	$16, %ecx
	orl	%edx, %ecx
	movl	key_to_r(%rip), %edx
	sall	$24, %edx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_from_r_from_r_dup_to_r, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_sp_fetch(%rip), %edx
	sall	$8, %edx
	orl	key_cells(%rip), %edx
	movl	key_plus(%rip), %ecx
	sall	$16, %ecx
	orl	%edx, %ecx
	movl	key_fetch(%rip), %edx
	sall	$24, %edx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_cells_sp_fetch_plus_fetch, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_minus(%rip), %edx
	sall	$8, %edx
	orl	key_two_dup(%rip), %edx
	movl	key_to_r(%rip), %ecx
	sall	$16, %ecx
	orl	%edx, %ecx
	movl	key_dolit(%rip), %edx
	sall	$24, %edx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_two_dup_minus_to_r_dolit, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_two_dup(%rip), %edx
	sall	$8, %edx
	orl	key_from_r(%rip), %edx
	movl	key_minus(%rip), %ecx
	sall	$16, %ecx
	orl	%edx, %ecx
	movl	key_to_r(%rip), %edx
	sall	$24, %edx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_from_r_two_dup_minus_to_r, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	movl	key_from_r(%rip), %edx
	sall	$8, %edx
	orl	key_from_r(%rip), %edx
	movl	key_two_dup(%rip), %ecx
	sall	$16, %ecx
	orl	%edx, %ecx
	movl	key_minus(%rip), %edx
	sall	$24, %edx
	orl	%ecx, %edx
	cltq
	salq	$4, %rax
	addq	$superinstructions+8, %rax
	movl	%edx, (%rax)
	movl	nextSuperinstruction(%rip), %eax
	leal	1(%rax), %edx
	movl	%edx, nextSuperinstruction(%rip)
	cltq
	salq	$4, %rax
	addq	$superinstructions, %rax
	movq	$code_superinstruction_from_r_from_r_two_dup_minus, (%rax)
	nop
	ret
	.cfi_endproc
.LFE168:
	.size	init_superinstructions, .-init_superinstructions
	.ident	"GCC: (GNU) 6.1.1 20160602"
	.section	.note.GNU-stack,"",@progbits
        # TODO: Optimize the superinstructions - many of them are very
        # shortenable.
