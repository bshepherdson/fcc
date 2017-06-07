# Directly included asm header for x86_64 on Linux.
# Mostly defining global variables and setting up other machine-specific state.


	.comm	_stack_data,131072,64
	.globl	spTop
	.data
	.align 8
	.type	spTop, @object
	.size	spTop, 8
spTop:
	.quad	_stack_data+131072
	.comm	sp,8,8
	.comm	_stack_return,8192,64
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

	# A word list is a linked list of word headers.
	# Each word list is a cell that points to the first header.
	# The indirection is needed so that a wordlist has a fixed identity,
	# even as it grows.
	# searchIndex is the index of the topmost wordlist in the search order.
	# searchArray is the buffer, with room for 16 searches.
	# compilationWordlist points to the current compilation wordlist.
	# Both of those default to the main Forth wordlist.
	# That main wordlist is pre-allocated as forthWordlist.
	.comm   searchArray,128,8
	.comm   searchIndex,8,8
	.comm   compilationWordlist,8,8
	.comm   forthWordlist,8,8
	.comm   lastWord,8,8
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
	.comm	timeVal,16,16
	.comm	i64,8,8
	.comm	old_tio,60,32
	.comm	new_tio,60,32




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

