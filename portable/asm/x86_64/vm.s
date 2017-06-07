# Notes on the conversion: We want two callee-saved registers to hold IP and SP.
# For simplicity and uniformity between i386 and x86_64, those are:
# SP in rbx, IP in rbp

# I'm porting in two passes: first to use NEXT and IP in rbp.
# That one is much less likely to cause bugs.
# Then I'm porting to use SP in rbx.

# NEXT is defined as a macro, for simplicity of future changes.
	.macro NEXT
	movq    (%rbp), %rax
        addq    $8, %rbp
	jmp	*%rax
	.endm
        .macro EXIT_NEXT
	movq	rsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, rsp(%rip)
	movq	(%rax), %rbp
	NEXT
        .endm
        .macro POPRSP reg
        movq    rsp(%rip), \reg
        movq    (\reg), \reg
        addq    $8, rsp(%rip)
        .endm
        .macro PUSHRSP reg, thru
	movq	rsp(%rip), \thru
	subq	$8, \thru
	movq	\thru, rsp(%rip)
        movq    \reg, (\thru)
        .endm

        .macro WORD_HDR code_name, forth_name, name_length, key, previous
	.globl	header_\code_name
	.section	.rodata
.str_\code_name:
	.string	"\forth_name"
	.data
	.align 32
	.type	header_\code_name, @object
	.size	header_\code_name, 32
header_\code_name:
	.quad	\previous
	.quad	\name_length
	.quad	.str_\code_name
	.quad	code_\code_name
	.globl	key_\code_name
	.align 4
	.type	key_\code_name, @object
	.size	key_\code_name, 4
key_\code_name:
	.long	\key
	.text
	.globl	code_\code_name
	.type	code_\code_name, @function
code_\code_name:
	.endm

	.macro WORD_TAIL name
	.size	code_\name, .-code_\name
        .endm

	.macro INIT_WORD name
	movl	key_\name(%rip), %eax
	leal	-1(%rax), %edx
	movl	key_\name(%rip), %eax
	movl	%edx, %ecx
	salq	$4, %rcx
	addq	$primitives, %rcx
	movq	$code_\name, (%rcx)
	movl	%edx, %edx
	salq	$4, %rdx
	addq	$primitives+8, %rdx
	movl	%eax, (%rdx)
	.endm

	.file	"vm.c"
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
	.long	120
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

WORD_HDR plus, "+", 1, 1, 0
	movq    (%rbx), %rax
	addq    $8, %rbx
	addq    %rax, (%rbx)
	NEXT
WORD_TAIL plus
WORD_HDR minus, "-", 1, 2, header_plus
	movq	(%rbx), %rcx
	movq	8(%rbx), %rax
	subq	%rcx, %rax
        addq    $8, %rbx
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL minus
WORD_HDR times, "*", 1, 3, header_minus
        movq    (%rbx), %rdx
	addq	$8, %rbx
	movq	(%rbx), %rcx
	imulq	%rcx, %rdx
	movq	%rdx, (%rbx)
	NEXT
WORD_TAIL times
WORD_HDR div, "/", 1, 4, header_times
        movq    (%rbx), %rsi
        addq    $8, %rbx
        movq    (%rbx), %rax
	cqto
	idivq	%rsi
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL div
WORD_HDR udiv, "U/", 2, 5, header_div
        movq    (%rbx), %rsi
        addq    $8, %rbx
        movq    (%rbx), %rax
        movl    $0, %edx
	divq	%rsi
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL udiv
WORD_HDR mod, "MOD", 3, 6, header_udiv
        movq    (%rbx), %rsi
        addq    $8, %rbx
        movq    (%rbx), %rax
	cqto
	idivq	%rsi
	movq	%rdx, (%rbx)
	NEXT
WORD_TAIL mod
WORD_HDR umod, "UMOD", 4, 7, header_mod
        movq    (%rbx), %rsi
        addq    $8, %rbx
        movq    (%rbx), %rax
        movl    $0, %edx
	divq	%rsi      # modulus in %rdx
        movq    %rdx, (%rbx)
	NEXT
WORD_TAIL umod
WORD_HDR and, "AND", 3, 8, header_umod
        movq    (%rbx), %rdx
        addq    $8, %rbx
        movq    (%rbx), %rax
	andq	%rdx, %rax
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL and
WORD_HDR or, "OR", 2, 9, header_and
        movq    (%rbx), %rax
        addq    $8, %rbx
        movq    (%rbx), %rcx
	orq	%rcx, %rax
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL or
WORD_HDR xor, "XOR", 3, 10, header_or
        movq    (%rbx), %rax
        addq    $8, %rbx
	xorq	%rax, (%rbx)
	NEXT
WORD_TAIL xor
WORD_HDR lshift, "LSHIFT", 6, 11, header_xor
	movq	(%rbx), %rcx     # sp[0] -> %rcx
        addq    $8, %rbx
        movq    (%rbx), %rsi     # sp[1] -> %rsi
	salq	%cl, %rsi        # result in %rsi
	movq	%rsi, (%rbx)
	NEXT
WORD_TAIL lshift
WORD_HDR rshift, "RSHIFT", 6, 12, header_lshift
        movq    (%rbx), %rax
        movl    %eax, %ecx
        addq    $8, %rbx
        movq    (%rbx), %rsi
	shrq	%cl, %rsi
	movq	%rsi, (%rbx)
	NEXT
WORD_TAIL rshift
WORD_HDR base, "BASE", 4, 13, header_rshift
        subq    $8, %rbx
        movl    $base, %eax
        movq    %rax, (%rbx)
	NEXT
WORD_TAIL base
WORD_HDR less_than, "<", 1, 14, header_base
        movq    (%rbx), %rax
        addq    $8, %rbx
        movq    (%rbx), %rcx
	cmpq	%rax, %rcx
	jge	.L17
	movq	$-1, %rax
	jmp	.L18
.L17:
	movl	$0, %eax
.L18:
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL less_than
WORD_HDR less_than_unsigned, "U<", 2, 15, header_less_than
        movq    (%rbx), %rax
        addq    $8, %rbx
        movq    (%rbx), %rcx
	cmpq	%rax, %rcx
	jnb	.L20
	movq	$-1, %rax
	jmp	.L21
.L20:
	movl	$0, %eax
.L21:
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL less_than_unsigned
WORD_HDR equal, "=", 1, 16, header_less_than_unsigned
        movq    (%rbx), %rcx
        addq    $8, %rbx
        movq    (%rbx), %rax
	cmpq	%rax, %rcx
	jne	.L23
	movq	$-1, %rax
	jmp	.L24
.L23:
	movl	$0, %eax
.L24:
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL equal
WORD_HDR dup, "DUP", 3, 17, header_equal
        movq    (%rbx), %rax
	subq	$8, %rbx
        movq    %rax, (%rbx)
	NEXT
WORD_TAIL dup
WORD_HDR swap, "SWAP", 4, 18, header_dup
        movq    (%rbx), %rcx
        movq    8(%rbx), %rax
        movq    %rax, (%rbx)
        movq    %rcx, 8(%rbx)
	NEXT
WORD_TAIL swap
WORD_HDR drop, "DROP", 4, 19, header_swap
	addq	$8, %rbx
	NEXT
WORD_TAIL drop
WORD_HDR over, "OVER", 4, 20, header_drop
        movq    8(%rbx), %rax
	subq	$8, %rbx
        movq    %rax, (%rbx)
	NEXT
WORD_TAIL over
WORD_HDR rot, "ROT", 3, 21, header_over
	movq	(%rbx), %rdx # ( a c d -- c d a )
	movq	8(%rbx), %rcx
	movq	16(%rbx), %rax
        movq    %rcx, 16(%rbx)
        movq    %rdx, 8(%rbx)
        movq    %rax, (%rbx)
	NEXT
WORD_TAIL rot
WORD_HDR neg_rot, "-ROT", 4, 22, header_rot
	movq	(%rbx), %rdx # ( a c d -- d a c )
	movq	8(%rbx), %rcx
	movq	16(%rbx), %rax
	movq	%rdx, 16(%rbx)
	movq	%rax, 8(%rbx)
	movq	%rcx, 0(%rbx)
	NEXT
WORD_TAIL neg_rot
WORD_HDR two_drop, "2DROP", 5, 23, header_neg_rot
	addq	$16, %rbx
	NEXT
WORD_TAIL two_drop
WORD_HDR two_dup, "2DUP", 4, 24, header_two_drop
	subq	$16, %rbx
        movq    16(%rbx), %rax
        movq    %rax, (%rbx)
        movq    24(%rbx), %rax
        movq    %rax, 8(%rbx)
	NEXT
WORD_TAIL two_dup
WORD_HDR two_swap, "2SWAP", 5, 25, header_two_dup
	# Swap in pairs: 0/16, 8/24
        # First pair, 0/16
	movq	16(%rbx), %rax
	movq	(%rbx), %rcx
        movq    %rcx, 16(%rbx)
        movq    %rax, (%rbx)
        # Second pair, 8/24
	movq	24(%rbx), %rax
	movq	8(%rbx), %rcx
        movq    %rcx, 24(%rbx)
        movq    %rax, 8(%rbx)
	NEXT
WORD_TAIL two_swap
WORD_HDR two_over, "2OVER", 5, 26, header_two_swap
	subq	$16, %rbx
	movq	32(%rbx), %rax
        movq    %rax, (%rbx)
	movq	40(%rbx), %rax
        movq    %rax, 8(%rbx)
	NEXT
WORD_TAIL two_over
WORD_HDR to_r, ">R", 2, 27, header_two_over
        movq    (%rbx), %rax
        addq    $8, %rbx
        PUSHRSP %rax, %rcx
	NEXT
WORD_TAIL to_r
WORD_HDR from_r, "R>", 2, 28, header_to_r
        POPRSP %rax
        subq    $8, %rbx
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL from_r
WORD_HDR fetch, "@", 1, 29, header_from_r
        movq    (%rbx), %rax
        movq    (%rax), %rax
        movq    %rax, (%rbx)
	NEXT
WORD_TAIL fetch
WORD_HDR store, "!", 1, 30, header_fetch
	movq	(%rbx), %rdx
	movq	8(%rbx), %rax
	movq	%rax, (%rdx)
	addq	$16, %rbx
	NEXT
WORD_TAIL store
WORD_HDR cfetch, "C@", 2, 31, header_store
	movq	(%rbx), %rax
	movzbl	(%rax), %eax
	movzbl	%al, %eax
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL cfetch
WORD_HDR cstore, "C!", 2, 32, header_cfetch
	movq	(%rbx), %rax
	movq	8(%rbx), %rcx
	movb	%cl, (%rax)
	addq	$16, %rbx
	NEXT
WORD_TAIL cstore
WORD_HDR two_fetch, "2@", 2, 118, header_cstore
	movq    (%rbx), %rdx
	subq    $8, %rbx
	movq    (%rdx), %rax
	movq    %rax, (%rbx)
	movq    8(%rdx), %rax
	movq    %rax, 8(%rbx)
	NEXT
WORD_TAIL two_fetch
WORD_HDR two_store, "2!", 2, 119, header_two_fetch
	movq    (%rbx), %rdx   # %rdx is the target address
	movq    8(%rbx), %rax
	movq    %rax, (%rdx)
	movq    16(%rbx), %rax
	movq    %rax, 8(%rdx)
	addq    $24, %rbx
	NEXT
WORD_TAIL two_store
WORD_HDR raw_alloc, "(ALLOCATE)", 10, 33, header_two_store
	movq	(%rbx), %rax
	movq	%rax, %rdi
	call	malloc
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL raw_alloc
WORD_HDR here_ptr, "(>HERE)", 7, 34, header_raw_alloc
	subq	$8, %rbx
	movl	$dsp, %eax
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL here_ptr

	.section	.rodata
.LC36:
	.string	"%ld "
WORD_HDR print_internal, "(PRINT)", 7, 35, header_here_ptr
	movq	(%rbx), %rsi
	movl	$.LC36, %edi
	movl	$0, %eax
	call	printf
	addq	$8, %rbx
	NEXT
WORD_TAIL print_internal
WORD_HDR state, "STATE", 5, 36, header_print_internal
	movl	$state, %eax
	subq	$8, %rbx
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL state
WORD_HDR branch, "(BRANCH)", 8, 37, header_state
        movq    (%rbp), %rax   # The branch offset.
        addq    %rax, %rbp
        NEXT
WORD_TAIL branch
WORD_HDR zbranch, "(0BRANCH)", 9, 38, header_branch
        movq    (%rbx), %rax
        addq    $8, %rbx
	testq	%rax, %rax
	jne	.L49
        movq    (%rbp), %rax
	jmp	.L50
.L49:
	movl	$8, %eax
.L50:
        # Either way when we get down here, rax contains the delta.
        addq    %rax, %rbp
	NEXT
WORD_TAIL zbranch
WORD_HDR execute, "EXECUTE", 7, 39, header_zbranch
        movq    (%rbx), %rax
        addq    $8, %rbx
	movq	%rax, cfa(%rip)
	movq	(%rax), %rax
	movq	%rax, ca(%rip)
	jmp	*%rax
WORD_TAIL execute
WORD_HDR evaluate, "EVALUATE", 8, 40, header_execute
	addq	$1, inputIndex(%rip)
	movq	inputIndex(%rip), %rdx
	movq	(%rbx), %rax
	salq	$5, %rdx
	addq	$inputSources, %rdx
	movq	%rax, (%rdx)
	movq	inputIndex(%rip), %rax
	movq	8(%rbx), %rdx
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
	addq	$16, %rbx
	movq	rsp(%rip), %rax
	subq	$8, %rax
	movq	%rax, rsp(%rip)
	movq	rsp(%rip), %rax
	movq	%rbp, (%rax)
	jmp	*quit_inner(%rip)
WORD_TAIL evaluate


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
	movq	(%rax), %rbp
	NEXT
.L54:
	pushq	%r12
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
	movq	inputIndex(%rip), %r12
	movq	str1(%rip), %rdi
	call	strlen
	movq	%rax, %rdx
	movq	%r12, %rax
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
	popq	%r12
	.cfi_restore 3
	.cfi_def_cfa_offset 8
	ret
	.cfi_endproc
.LFE43:
	.size	refill_, .-refill_


WORD_HDR refill, "REFILL", 6, 41, header_evaluate
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+16, %rax
	movq	(%rax), %rax
	cmpq	$-1, %rax
	jne	.L69
	subq	$8, %rbx
	movq	(%rbx), %rax
	movq	$0, (%rax)
	jmp	.L70
.L69:
	subq	$8, %rbx
	call	refill_
	movq	%rax, (%rbx)
.L70:
	NEXT
WORD_TAIL refill
WORD_HDR accept, "ACCEPT", 6, 42, header_refill
	movl	$0, %edi
	call	readline
	movq	%rax, str1(%rip)
	movq	str1(%rip), %rdi
	call	strlen
	movq	%rax, c1(%rip)
	movq	(%rbx), %rdx
	movq	c1(%rip), %rax
	cmpq	%rax, %rdx
	jge	.L73
	movq	(%rbx), %rax
	movq	%rax, c1(%rip)
.L73:
	movq	8(%rbx), %rax
	movq	c1(%rip), %rdx
	movq	str1(%rip), %rsi
	movq	%rax, %rdi
	call	strncpy
	movq	c1(%rip), %rax
	addq	$8, %rbx
	movq	%rax, (%rbx)
	movq	str1(%rip), %rdi
	call	free
	NEXT
WORD_TAIL accept
WORD_HDR key, "KEY", 3, 43, header_accept
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
	subq	$8, %rbx
	call	getchar
	cltq
	movq	%rax, (%rbx)
	movl	$old_tio, %edx
	movl	$0, %esi
	movl	$0, %edi
	call	tcsetattr
	NEXT
WORD_TAIL key
WORD_HDR latest, "(LATEST)", 8, 44, header_key
	subq	$8, %rbx
	movq    compilationWordlist(%rip), %rax
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL latest
WORD_HDR dictionary_info, "(DICT-INFO)", 11, 117, header_latest
	subq    $24, %rbx
	movl	$compilationWordlist, %eax
	movq	%rax, 16(%rbx)
	movl	$searchIndex, %eax
	movq	%rax, 8(%rbx)
	movl    $searchArray, %eax
	movq    %rax, (%rbx)
	NEXT
WORD_TAIL dictionary_info
WORD_HDR in_ptr, ">IN", 3, 45, header_dictionary_info
	subq	$8, %rbx
	movq	inputIndex(%rip), %rdx
	salq	$5, %rdx
	addq	$inputSources, %rdx
	addq	$8, %rdx
	movq	%rdx, (%rbx)
	NEXT
WORD_TAIL in_ptr
WORD_HDR emit, "EMIT", 4, 46, header_in_ptr
	movq	stdout(%rip), %rdx
        movq    (%rbx), %rax
        addq    $8, %rbx
	movq	%rdx, %rsi
	movl	%eax, %edi
	call	fputc
	NEXT
WORD_TAIL emit
WORD_HDR source, "SOURCE", 6, 47, header_emit
	subq	$16, %rbx
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources, %rax
	movq	(%rax), %rax
	movq	%rax, (%rbx)
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+24, %rax
	movq	(%rax), %rax
	movq	%rax, 8(%rbx)
	NEXT
WORD_TAIL source
WORD_HDR source_id, "SOURCE-ID", 9, 48, header_source
	subq	$8, %rbx
	movq	inputIndex(%rip), %rax
	salq	$5, %rax
	addq	$inputSources+16, %rax
	movq	(%rax), %rax
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL source_id
WORD_HDR size_cell, "(/CELL)", 7, 49, header_source_id
	subq	$8, %rbx
	movq	$8, (%rbx)
	NEXT
WORD_TAIL size_cell
WORD_HDR size_char, "(/CHAR)", 7, 50, header_size_cell
	subq	$8, %rbx
	movq	$1, (%rbx)
	NEXT
WORD_TAIL size_char
WORD_HDR cells, "CELLS", 5, 51, header_size_char
	movq	(%rbx), %rax
	salq	$3, %rax
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL cells
WORD_HDR chars, "CHARS", 5, 52, header_cells
	NEXT
WORD_TAIL chars
WORD_HDR unit_bits, "(ADDRESS-UNIT-BITS)", 19, 53, header_chars
	subq	$8, %rbx
	movq	$8, (%rbx)
	NEXT
WORD_TAIL unit_bits
WORD_HDR stack_cells, "(STACK-CELLS)", 13, 54, header_unit_bits
	subq	$8, %rbx
	movq	$16384, (%rbx)
	NEXT
WORD_TAIL stack_cells
WORD_HDR return_stack_cells, "(RETURN-STACK-CELLS)", 20, 55, header_stack_cells
	subq	$8, %rbx
	movq	$1024, (%rbx)
	NEXT
WORD_TAIL return_stack_cells
WORD_HDR to_does, "(>DOES)", 7, 56, header_return_stack_cells
	movq	(%rbx), %rax
	addq	$32, %rax
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL to_does
WORD_HDR to_cfa, "(>CFA)", 6, 57, header_to_does
	movq	(%rbx), %rax
	addq	$24, %rax
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL to_cfa
WORD_HDR to_body, ">BODY", 5, 58, header_to_cfa
	movq	(%rbx), %rax
	addq	$16, %rax
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL to_body
WORD_HDR last_word, "(LAST-WORD)", 11, 59, header_to_body
	subq	$8, %rbx
	movq	lastWord(%rip), %rax
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL last_word
WORD_HDR docol, "(DOCOL)", 7, 60, header_last_word
	movq	rsp(%rip), %rax
	subq	$8, %rax
	movq	%rax, rsp(%rip)
	movq	%rbp, (%rax)
	movq	cfa(%rip), %rax
	addq	$8, %rax
	movq	%rax, %rbp
	NEXT
WORD_TAIL docol
WORD_HDR dolit, "(DOLIT)", 7, 61, header_docol
	subq	$8, %rbx
        movq    (%rbp), %rax
        movq    %rax, (%rbx)
        addq    $8, %rbp
	NEXT
WORD_TAIL dolit
WORD_HDR dostring, "(DOSTRING)", 10, 62, header_dolit
        # Flow: next byte on TOS, address after it below.
        # Advance the IP (%rbp) by that byte, + 1, and then align it.
        subq    $16, %rbx
        movzbl  (%rbp), %eax
        movsbq  %al, %rax    # Single byte length now in %rax
        movq    %rax, (%rbx) # And on TOS

        movq    %rbp, %rcx
        addq    $1, %rcx      # %rcx now holds the string address
        movq    %rcx, 8(%rbx) # which is next on the stack

        addq    %rcx, %rax    # %rax is now the point after the string.
        addq    $7, %rax
        andq    $-8, %rax     # which is now rounded up so as to be aligned.
        movq    %rax, %rbp    # and moved back to IP
	NEXT
WORD_TAIL dostring
WORD_HDR dodoes, "(DODOES)", 8, 63, header_dostring
        # Push the address of the data area (cfa + 2 cells).
        # Then check cfa + 1 cell: if nonzero, call into it.
	movq	cfa(%rip), %rax    # CFA in %rax
        movq    %rax, %rcx
        addq    $16, %rcx
        subq    $8, %rbx
        movq    %rcx, (%rbx)       # Push the data space address.
        addq    $8, %rax
        movq    (%rax), %rax       # Now %rax holds the does> address
        movq    %rax, %rcx         # Which I'll set aside.
	testq	%rax, %rax
	je	.L98
	movq	rsp(%rip), %rax
	subq	$8, %rax
	movq	%rax, rsp(%rip)
	movq	%rbp, (%rax)
	movq	%rcx, %rbp
.L98:
	NEXT
WORD_TAIL dodoes
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
	movq	$0, (%rbx)
	subq	$8, %rbx
	movq	$0, (%rbx)
	jmp	.L106
.L100:
	movq	(%rbx), %rax
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
	movq	str1(%rip), %rdx
	movq	%rdx, (%rbx)
	subq	$8, %rbx
	movq	c1(%rip), %rax
	movq	%rax, (%rbx)
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
        subq    $16, %rbx
	movq	str1(%rip), %rax
	movq	%rax, 8(%rbx)
	movq	c1(%rip), %rax
	movq	%rax, (%rbx)
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
	movq	24(%rbx), %rsi
	movq	c1(%rip), %rdx
	sall	$3, %edx
	movl	%edx, %ecx
	shrq	%cl, %rsi
	movq	%rsi, %rdx
	movb	%dl, numBuf(%rax)
	movq	c1(%rip), %rax
	addq	$8, %rax
	movq	16(%rbx), %rdx
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
	movq	(%rbx), %rax
	subq	$1, %rax
	movq	%rax, (%rbx)
	addq	$1, str1(%rip)
.L118:
	movq	(%rbx), %rax
	testq	%rax, %rax
	jg	.L126
	jmp	.L122
.L129:
	nop
.L122:
	movq	$0, 16(%rbx)
	movq	$0, 24(%rbx)
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

        orq     24(%rbx), %rax
        movq    %rax, 24(%rbx)

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

        orq     %rcx, 16(%rbx)
	addq	$1, c1(%rip)
.L127:
	movq	c1(%rip), %rax
	cmpq	$7, %rax
	jle	.L128
	movq	str1(%rip), %rax
	movq	%rax, 8(%rbx)
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
	movq	8(%rbx), %rax
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
	movq	8(%rbx), %rax
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
	subq	$1, (%rbx)
	jmp	.L138
.L133:
	movq	str1(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$39, %al
	jne	.L138
        subq    $3, (%rbx)
        addq    $3, 8(%rbx)
	movq	str1(%rip), %rax
	addq	$1, %rax
	movsbq	(%rax), %rax
	movq	%rax, 24(%rbx)
	jmp	.L131
.L138:
	movb	$0, ch1(%rip)
	movq	str1(%rip), %rax
	movzbl	(%rax), %eax
	cmpb	$45, %al
	jne	.L140
        subq    $1, (%rbx)
	addq	$1, str1(%rip)
	movb	$1, ch1(%rip)
.L140:
	call	to_number_int_
	movzbl	ch1(%rip), %eax
	testb	%al, %al
	je	.L131

        notq    16(%rbx)
        movq    24(%rbx), %rax
        notq    %rax
        addq    $1, %rax
        movq    %rax, 24(%rbx)

	testq	%rax, %rax
	jne	.L131
	addq	$1, 16(%rbx)
.L131:
	ret
	.cfi_endproc
.LFE71:
	.size	parse_number_, .-parse_number_
	.globl	find_
	.type	find_, @function
find_:
	movq    searchIndex(%rip), %r12    # r12 is reserved for the index.
.LF159:
	leaq    searchArray(%rip), %rax
	movq    (%rax,%r12,8), %rax
	movq    (%rax), %rax
	movq    %rax, tempHeader(%rip)   # Store it in tempHeader.
	jmp     .LF151

.LF156:
	movq    tempHeader(%rip), %rax
	movq    8(%rax), %rax  # The length word.
	andl	$511, %eax     # The length/hidden mask
	movq    (%rbx), %rcx
	cmpq    %rcx, %rax
	jne     .LF152

	# If we're still here, they're the same length and not hidden.
find_debug:
	movq    tempHeader(%rip), %rax
	movq    16(%rax), %rdi  # 1st arg: pointer to this word's name.
	movq    8(%rbx), %rsi   # 2nd arg: pointer to target name.
	movq    (%rbx), %rdx    # 3rd arg: length.

	# %rsp needs to be aligned to 16 bytes for C calls, but it already is,
	# because find_ is a C call itself.
	call strncasecmp
	testl   %eax, %eax  # ZF=1 when the response was 0, meaning equal.
	jne  .LF152  # If it's not equal, we didn't find it.

	# If they are equal, we found it.
find_found:
	movq    tempHeader(%rip), %rax
	addq    $24, %rax
	movq    %rax, 8(%rbx)   # CFA in next-but-top.

	movq    tempHeader(%rip), %rax
	movq    8(%rax), %rax   # Length
	andl    $512, %eax      # Immediate flag
	testl   %eax, %eax      # ZF=1 when not immediate
	jne     .LF153          # Set 1 when immediate
	movq    $-1, %rax
	jmp     .LF154
.LF153:
	movq    $1, %rax
.LF154:
	movq    %rax, (%rbx)
	jmp     .LF149

.LF152: # Mismatch, keep searching this linked list.
	movq    tempHeader(%rip), %rax
	movq    (%rax), %rax
	movq    %rax, tempHeader(%rip)

.LF151:
	movq    tempHeader(%rip), %rax
	testq   %rax, %rax
	jne     .LF156  # Nonzero, so loop back.
.LF150: # Reached the end of a wordlist. Try the next one, if any.
	testq   %r12, %r12
	je      .LF158  # Index = 0, bail.
	subq    $1, %r12 # If nonzero, subtract and loop.
	jmp     .LF159

.LF160:
	nop
.LF158: # Run out of wordlists too.
	movq $0, %rax
	movq %rax, 8(%rbx) # 0 underneath
	movq %rax, (%rbx)  # 0 on top
.LF149: # Returning
	ret
	.size	find_, .-find_


WORD_HDR parse, "PARSE", 5, 64, header_dodoes
	call	parse_
	NEXT
WORD_TAIL parse
WORD_HDR parse_name, "PARSE-NAME", 10, 65, header_parse
	call	parse_name_
	NEXT
WORD_TAIL parse_name
WORD_HDR to_number, ">NUMBER", 7, 66, header_parse_name
	call	to_number_
	NEXT
WORD_TAIL to_number
WORD_HDR create, "CREATE", 6, 67, header_to_number
        # TODO: Optimize. Low priority, CREATE is not very hot.
	call	parse_name_
	movq	dsp(%rip), %rax
	addq	$7, %rax
	andq	$-8, %rax
	movq	%rax, dsp(%rip)
	movq	%rax, tempHeader(%rip)
	addq	$32, dsp(%rip)
	movq	tempHeader(%rip), %rax
	movq	compilationWordlist(%rip), %rdx
	movq    (%rdx), %rdx
	movq	%rdx, (%rax)

	movq	tempHeader(%rip), %rax
	movq    compilationWordlist(%rip), %rdx
	movq    %rax, (%rdx)

	movq	tempHeader(%rip), %rax
	movq	(%rbx), %rdx
	movq	%rdx, 8(%rax)

	movq	tempHeader(%rip), %r12
	movq	(%rbx), %rdi
	call	malloc
	movq	%rax, 16(%r12)
	movq	(%rbx), %rdx
	movq	8(%rbx), %rsi
	movq	16(%r12), %rax
	movq	%rax, %rdi
	call	strncpy
	addq	$16, %rbx

	movq	tempHeader(%rip), %rax
	movq	$code_dodoes, 24(%rax)
	movq	dsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, dsp(%rip)
	movq	$0, (%rax)
	NEXT
WORD_TAIL create
WORD_HDR find, "(FIND)", 6, 68, header_create
	call	find_
	NEXT
WORD_TAIL find
WORD_HDR depth, "DEPTH", 5, 69, header_find
	movq	spTop(%rip), %rax
	subq	%rbx, %rax
	shrq	$3, %rax
        subq    $8, %rbx
        movq    %rax, (%rbx)
	NEXT
WORD_TAIL depth
WORD_HDR sp_fetch, "SP@", 3, 70, header_depth
        movq    %rbx, %rax
        subq    $8, %rbx
        movq    %rax, (%rbx)
	NEXT
WORD_TAIL sp_fetch
WORD_HDR sp_store, "SP!", 3, 71, header_sp_fetch
	movq	(%rbx), %rbx
	NEXT
WORD_TAIL sp_store
WORD_HDR rp_fetch, "RP@", 3, 72, header_sp_store
	subq	$8, %rbx
	movq	rsp(%rip), %rax
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL rp_fetch
WORD_HDR rp_store, "RP!", 3, 73, header_rp_fetch
	movq	(%rbx), %rax
        addq    $8, %rbx
	movq	%rax, rsp(%rip)
	NEXT
WORD_TAIL rp_store

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
	subq	%rbx, %rax
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
	cmpq	%rbx, %rdx
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


WORD_HDR dot_s, ".S", 2, 74, header_rp_store
	call	dot_s_
	NEXT
WORD_TAIL dot_s
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
	subq	%rbx, %rax
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
	cmpq	%rbx, %rdx
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


WORD_HDR u_dot_s, "U.S", 3, 75, header_dot_s
	call	u_dot_s_
	NEXT
WORD_TAIL u_dot_s

	.section	.rodata
.LC81:
	.string	"wb"
	.align 8
.LC82:
	.string	"*** Failed to open file for writing: %s\n"
	.align 8
.LC83:
	.string	"(Dumped %ld of %ld bytes to %s)\n"

WORD_HDR dump_file, "(DUMP-FILE)", 11, 76, header_u_dot_s
	movq    (%rbx), %rdx
	movq    8(%rbx), %rsi
	movl	$tempBuf, %edi
	call	strncpy
	movq	(%rbx), %rax
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
        movq    16(%rbx), %rdx
        movq    24(%rbx), %rdi
	movq	tempFile(%rip), %rcx
	movl	$1, %esi
	call	fwrite
	movq	%rax, c1(%rip)
        movq    16(%rbx), %rdx
	movl	$tempBuf, %ecx
	movq	c1(%rip), %rsi
	movl	$.LC83, %edi
	movl	$0, %eax
	call	printf
	movq	tempFile(%rip), %rdi
	call	fclose
	movq	$0, tempFile(%rip)
.L175:
	NEXT
WORD_TAIL dump_file

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
	movq	(%rbp), %rax
        addq    $8, %rbp
	movq	rsp(%rip), %r12
	subq	$8, %r12
	movq	%r12, rsp(%rip)
	movq	%rbp, (%r12)
	movq	%rax, %rbp
	NEXT
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
	movq	(%rbx), %rax
	movq	(%rax), %rax
	cmpq	$code_docol, %rax
	jne	.L208
	movq	queueTail(%rip), %rax
	movq	$call_, (%rax)
	movb	$1, 8(%rax)
	movq	%rax, %rdx

        movq    (%rbx), %rax
        addq    $8, %rbx
	addq	$8, %rax
	movq	%rax, 16(%rdx)

	movq	queueTail(%rip), %rax
	movl	key_call_(%rip), %edx
	movl	%edx, 24(%rax)
	jmp	.L213
.L208:
	movq	(%rbx), %rax
	movq	(%rax), %rax
	cmpq	$code_dodoes, %rax
	jne	.L210
	movq	queueTail(%rip), %rax
	movq	$code_dolit, (%rax)
	movb	$1, 8(%rax)

	movq	(%rbx), %rdx
	addq	$16, %rdx
	movq	%rdx, 16(%rax)
	movl	key_dolit(%rip), %edx
	movl	%edx, 24(%rax)
	movq	(%rbx), %rax
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
	movb	$1, 8(%rax)
	movq	(%rbx), %rdx
	addq	$8, %rdx
	movq	(%rdx), %rdx
	movq	%rdx, 16(%rax)
	movl	key_call_(%rip), %edx
	movl	%edx, 24(%rax)
.L211:
	addq	$8, %rbx
	jmp	.L213
.L210:
        movq    (%rbx), %rax
        addq    $8, %rbx
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
	movq    (%rbx), %rax
        addq    $8, %rbx
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
	movq	spTop(%rip), %rbx
	movq	rspTop(%rip), %rax
	movq	%rax, rsp(%rip)
	movq	$0, state(%rip)
	movzbl	firstQuit(%rip), %eax
	testb	%al, %al
	jne	.L219
	movq	$0, inputIndex(%rip)
.L219:
	movq	$.L220, quit_inner(%rip)  # quit_inner. Set it up natively.
	call	refill_

.L220:
	call	parse_name_
	movq	(%rbx), %rax
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
	addq	$16, %rbx
	call	refill_
	jmp	.L220
.L233:
	nop
	movq	8(%rbx), %rax
	movq	%rax, savedString(%rip)
	movq	(%rbx), %rax
	movq	%rax, savedLength(%rip)
	call	find_
	movq	(%rbx), %rax
	testq	%rax, %rax
	jne	.L224
	subq	$16, %rbx
	movq	savedLength(%rip), %rax
	movq	%rax, (%rbx)
	movq	savedString(%rip), %rax
	movq	%rax, 8(%rbx)
	call	parse_number_
	movq	(%rbx), %rax
	testq	%rax, %rax
	jne	.L225
	movq	state(%rip), %rax
	cmpq	$1, %rax
	jne	.L226
	addq	$24, %rbx
	movl	$0, %eax
	call	compile_lit_
	jmp	.L220
.L226:
	addq	$24, %rbx
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
	movq	(%rbx), %rax
	cmpq	$1, %rax
	je	.L229
	movq	state(%rip), %rax
	testq	%rax, %rax
	jne	.L230
.L229:
	movl	$.L220, %eax
	movq	%rax, quitTop(%rip)
	movq	$quitTop, %rbp
	movq	8(%rbx), %rax
	movq	%rax, cfa(%rip)
	addq	$16, %rbx
	movq	cfa(%rip), %rax
	movq	(%rax), %rax
#APP
# 1438 "vm.c" 1
	jmpq *%rax
# 0 "" 2
#NO_APP
.L230:
	addq	$8, %rbx
	movl	$0, %eax
	call	compile_
	jmp	.L220
	.cfi_endproc
.LFE94:
	.size	quit_, .-quit_

WORD_HDR quit, "QUIT", 4, 77, header_dump_file
	movq	$0, inputIndex(%rip)
	call	quit_
	NEXT
WORD_TAIL quit
WORD_HDR bye, "BYE", 3, 78, header_quit
	movl	$0, %edi
	call	exit
WORD_TAIL bye
WORD_HDR compile_comma, "COMPILE,", 8, 79, header_bye
	movl	$0, %eax
	call	compile_
	NEXT
WORD_TAIL compile_comma
WORD_HDR literal, "LITERAL", 519, 101, header_compile_comma
	movl	$0, %eax
	call	compile_lit_
	NEXT
WORD_TAIL literal
WORD_HDR compile_literal, "[LITERAL]", 9, 102, header_literal
	movl	$0, %eax
	call	compile_lit_
	NEXT
WORD_TAIL compile_literal
WORD_HDR compile_zbranch, "[0BRANCH]", 9, 103, header_compile_literal
	subq	$8, %rbx
	movl	$header_zbranch+24, %eax
	movq	%rax, (%rbx)
	movl	$0, %eax
	call	compile_
	jmp	.L244
.L245:
	call	drain_queue_
.L244:
	movl	queue_length(%rip), %eax
	testl	%eax, %eax
	jg	.L245
	subq	$8, %rbx
	movq	dsp(%rip), %rax
	movq	%rax, (%rbx)
        movq    $0, (%rax)
        addq    $8, %rax
        movq    %rax, dsp(%rip)
	NEXT
WORD_TAIL compile_zbranch
WORD_HDR compile_branch, "[BRANCH]", 8, 104, header_compile_zbranch
	subq	$8, %rbx
	movl	$header_branch+24, %edx
	movq	%rdx, (%rbx)
	movl	$0, %eax
	call	compile_
	jmp	.L248
.L249:
	call	drain_queue_
.L248:
	movl	queue_length(%rip), %eax
	testl	%eax, %eax
	jg	.L249
	subq	$8, %rbx
	movq	dsp(%rip), %rax
	movq	%rax, (%rbx)
	movq	dsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, dsp(%rip)
	movq	$0, (%rax)
	NEXT
WORD_TAIL compile_branch
WORD_HDR control_flush, "(CONTROL-FLUSH)", 15, 105, header_compile_branch
	jmp	.L252
.L253:
	call	drain_queue_
.L252:
	movl	queue_length(%rip), %eax
	testl	%eax, %eax
	jg	.L253
	NEXT
WORD_TAIL control_flush
WORD_HDR debug_break, "(DEBUG)", 7, 80, header_control_flush
	NEXT
WORD_TAIL debug_break
WORD_HDR close_file, "CLOSE-FILE", 10, 81, header_debug_break
	movq	(%rbx), %rdi
	call	fclose
	cltq
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
	NEXT
WORD_TAIL close_file
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


WORD_HDR create_file, "CREATE-FILE", 11, 82, header_close_file
	movq    8(%rbx), %rdx
	movq    16(%rbx), %rsi
	movl	$tempBuf, %edi
	call	strncpy
	movq	8(%rbx), %rax
	movb	$0, tempBuf(%rax)
	addq	$8, %rbx

	movq    (%rbx), %rax
        orq     $8, %rax
	movq	file_modes(,%rax,8), %rax
	movq	%rax, %rsi
	movl	$tempBuf, %edi
	call	fopen
	movq	%rax, 8(%rbx)
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
	NEXT
WORD_TAIL create_file
WORD_HDR open_file, "OPEN-FILE", 9, 83, header_create_file
        movq    8(%rbx), %rdx
        movq    16(%rbx), %rsi
	movl	$tempBuf, %edi
	call	strncpy
	movq	8(%rbx), %rax
	movb	$0, tempBuf(%rax)
	movq	(%rbx), %rax
	movq	file_modes(,%rax,8), %rax
	movq	%rax, %rsi
	movl	$tempBuf, %edi
	call	fopen
	movq	%rax, 16(%rbx)
	testq	%rax, %rax
	jne	.L264
	movq	(%rbx), %rax
	andl	$2, %eax
	testq	%rax, %rax
	je	.L264
	movq	(%rbx), %rax
	orq	$8, %rax
	movq	file_modes(,%rax,8), %rax
	movq	%rax, %rsi
	movl	$tempBuf, %edi
	call	fopen
	movq	%rax, 16(%rbx)
.L264:
	movq	16(%rbx), %rax
	testq	%rax, %rax
	jne	.L265
	call	__errno_location
	movl	(%rax), %eax
	cltq
	jmp	.L266
.L265:
	movl	$0, %eax
.L266:
	addq	$8, %rbx
	movq	%rax, (%rbx)
	NEXT
WORD_TAIL open_file
WORD_HDR delete_file, "DELETE-FILE", 11, 84, header_open_file
        movq    (%rbx), %rdx
        movq    8(%rbx), %rsi
	movl	$tempBuf, %edi
	call	strncpy
	movq	(%rbx), %rax
	movb	$0, tempBuf(%rax)
	addq	$8, %rbx
	movl	$tempBuf, %edi
	call	remove
	cltq
	movq	%rax, (%rbx)
	cmpq	$-1, %rax
	jne	.L269
	call	__errno_location
	movl	(%rax), %eax
	cltq
	movq	%rax, (%rbx)
.L269:
	NEXT
WORD_TAIL delete_file
WORD_HDR file_position, "FILE-POSITION", 13, 85, header_delete_file
	subq	$16, %rbx
        movq    $0, 8(%rbx)
        movq    16(%rbx), %rdi
	call	ftell
	movq	%rax, 16(%rbx)
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
	NEXT
WORD_TAIL file_position
WORD_HDR file_size, "FILE-SIZE", 9, 86, header_file_position
	subq	$16, %rbx
        movq    $0, 8(%rbx)
        movq    16(%rbx), %rdi
	call	ftell
	movq	%rax, c1(%rip)
	testq	%rax, %rax
	jns	.L276
	call	__errno_location
	movl	(%rax), %eax
	cltq
	movq	%rax, (%rbx)
	jmp	.L277
.L276:
	movl	$2, %edx
	movl	$0, %esi
	movq	16(%rbx), %rdi
	call	fseek
	cltq
	movq	%rax, c2(%rip)
	testq	%rax, %rax
	jns	.L278
	call	__errno_location
	movl	(%rax), %eax
	cltq
	movq	%rax, (%rbx)
	movq	16(%rbx), %rdi
	movl	$0, %edx
	movq	c1(%rip), %rsi
	call	fseek
	jmp	.L277
.L278:
	movq	16(%rbx), %rdi
	call	ftell
	movq	%rax, c2(%rip)
	movq	16(%rbx), %rdi
	movl	$0, %edx
	movq	c1(%rip), %rsi
	call	fseek
	movq	c2(%rip), %rax
	movq	%rax, 16(%rbx)
	movq	$0, (%rbx)
.L277:
	NEXT
WORD_TAIL file_size
WORD_HDR include_file, "INCLUDE-FILE", 12, 87, header_file_size
	addq	$1, inputIndex(%rip)
	movq	inputIndex(%rip), %rcx
	movq	(%rbx), %rax
	addq	$8, %rbx
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
	NEXT
WORD_TAIL include_file
WORD_HDR read_file, "READ-FILE", 9, 88, header_include_file
        movq    (%rbx), %rcx
        movq    8(%rbx), %rdx
	movl	$1, %esi
	movq	16(%rbx), %rdi
	call	fread
	movq	%rax, c1(%rip)
	testq	%rax, %rax
	jne	.L282
	movq	(%rbx), %rdi
	call	feof
	testl	%eax, %eax
	je	.L283
	addq	$8, %rbx
	movq	$0, (%rbx)
	movq	$0, 8(%rbx)
	jmp	.L285
.L283:
	movq	(%rbx), %rdi
	call	ferror
	cltq
	movq	%rax, 8(%rbx)
	movq	$0, 16(%rbx)
	jmp	.L285
.L282:
	addq	$8, %rbx
	movq	c1(%rip), %rax
	movq	%rax, 8(%rbx)
	movq	$0, (%rbx)
.L285:
	NEXT
WORD_TAIL read_file
WORD_HDR read_line, "READ-LINE", 9, 89, header_read_file
	movq	$0, str1(%rip)
	movq	$0, tempSize(%rip)
	movq	(%rbx), %rdx
	movl	$tempSize, %esi
	movl	$str1, %edi
	call	getline
	movq	%rax, c1(%rip)
	cmpq	$-1, %rax
	jne	.L288
	call	__errno_location
	movl	(%rax), %eax
	cltq
	movq	%rax, (%rbx)
	movq	$0, 8(%rbx)
	movq	$0, 16(%rbx)
	jmp	.L289
.L288:
	movq	c1(%rip), %rax
	testq	%rax, %rax
	jne	.L290
	movq	$0, (%rbx)
	movq	$0, 8(%rbx)
	movq	$0, 16(%rbx)
	jmp	.L289
.L290:
	movq	c1(%rip), %rax
	leaq	-1(%rax), %rdx
	movq	8(%rbx), %rax
	cmpq	%rax, %rdx
	jle	.L291
	movq	8(%rbx), %rdx
	movq	(%rbx), %rax
	movq	c1(%rip), %rcx
	subq	%rdx, %rcx
	movl	$1, %edx
	movq	%rcx, %rsi
	movq	%rax, %rdi
	call	fseek
	movq	8(%rbx), %rax
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
	movq	16(%rbx), %rax
	movq	str1(%rip), %rsi
	movq	%rax, %rdi
	call	strncpy
	movq	$0, (%rbx)
	movq	$-1, 8(%rbx)
	movq	c1(%rip), %rax
	subq	$1, %rax
	movq	%rax, 16(%rbx)
.L289:
	movq	str1(%rip), %rax
	testq	%rax, %rax
	je	.L293
	movq	str1(%rip), %rdi
	call	free
.L293:
	NEXT
WORD_TAIL read_line
WORD_HDR reposition_file, "REPOSITION-FILE", 15, 90, header_read_line
	movq	16(%rbx), %rsi
	movq	(%rbx), %rdi
	movl	$0, %edx
	call	fseek
	cltq
	movq	%rax, 16(%rbx)
	addq	$16, %rbx
	movq	(%rbx), %rax
	cmpq	$-1, %rax
	jne	.L296
	call	__errno_location
	movl	(%rax), %eax
	cltq
	movq	%rax, (%rbx)
.L296:
	NEXT
WORD_TAIL reposition_file
WORD_HDR resize_file, "RESIZE-FILE", 11, 91, header_reposition_file
        movq    (%rbx), %rdi
        call    fileno
        movl    %eax, %edi
        movq    16(%rbx), %rsi
	call	ftruncate
	cltq
	movq	%rax, 16(%rbx)
	addq	$16, %rbx
	movq	(%rbx), %rax
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
	NEXT
WORD_TAIL resize_file
WORD_HDR write_file, "WRITE-FILE", 10, 92, header_resize_file
	movq	(%rbx), %rcx
	movq	8(%rbx), %rdx
	movl	$1, %esi
	movq	16(%rbx), %rdi
	call	fwrite
	movq	%rax, c1(%rip)
	addq	$16, %rbx
	movq	$0, (%rbx)
	NEXT
WORD_TAIL write_file
WORD_HDR write_line, "WRITE-LINE", 10, 93, header_write_file
	movq	8(%rbx), %rdx
	movq	16(%rbx), %rsi
	movl	$tempBuf, %edi
	call	strncpy
	movq	8(%rbx), %rax
	movb	$10, tempBuf(%rax)
	movq	(%rbx), %rcx
	movq	8(%rbx), %rdx
        addq    $1, %rdx
        movl    $1, %esi
	movl	$tempBuf, %edi
	call	fwrite
	addq	$16, %rbx
	movq	$0, (%rbx)
	NEXT
WORD_TAIL write_line
WORD_HDR flush_file, "FLUSH-FILE", 10, 94, header_write_line
	movq	(%rbx), %rdi
	call	fileno
	movl	%eax, %edi
	call	fsync
	cltq
	movq	%rax, (%rbx)
	cmpq	$-1, %rax
	jne	.L307
	call	__errno_location
	movl	(%rax), %eax
	cltq
	movq	%rax, (%rbx)
.L307:
	NEXT
WORD_TAIL flush_file
	.section	.rodata
	.align 8
.LC117:
	.string	"*** Colon definition with no name\n"

WORD_HDR colon, ":", 1, 95, header_flush_file
	movq	dsp(%rip), %rax
	addq	$7, %rax
	andq	$-8, %rax
	movq	%rax, dsp(%rip)
	movq	%rax, tempHeader(%rip)
	addq	$32, dsp(%rip)
	movq	tempHeader(%rip), %rax
	movq	compilationWordlist(%rip), %rdx
	movq    (%rdx), %rcx   # The actual previous head.
	movq	%rcx, (%rax)   # Written to the new header.
	movq    %rax, (%rdx)   # And the new one into the compilation list
	call	parse_name_
	movq	(%rbx), %rax
	testq	%rax, %rax
	jne	.L310
	movq	stderr(%rip), %rcx
	movl	$34, %edx
	movl	$1, %esi
	movl	$.LC117, %edi
	call	fwrite
	call	code_quit
.L310:
	movq	tempHeader(%rip), %r12
	movq	(%rbx), %rdi
	call	malloc
	movq	%rax, 16(%r12)
	movq	(%rbx), %rdx
	movq	8(%rbx), %rsi
	movq	%rax, %rdi
	call	strncpy
	movq	tempHeader(%rip), %rax
	movq	(%rbx), %rdx
	orb	$1, %dh
	movq	%rdx, 8(%rax)
	addq	$16, %rbx
	movq	tempHeader(%rip), %rax
	movq	$code_docol, 24(%rax)
	movq	tempHeader(%rip), %rax
	addq	$24, %rax
	movq	%rax, lastWord(%rip)
	movq	$1, state(%rip)
	NEXT
WORD_TAIL colon
WORD_HDR colon_no_name, ":NONAME", 7, 96, header_colon
	movq	dsp(%rip), %rax
	addq	$7, %rax
	andq	$-8, %rax
	movq	%rax, dsp(%rip)
	movq	dsp(%rip), %rax
	movq	%rax, lastWord(%rip)
	subq	$8, %rbx
	movq	dsp(%rip), %rdx
	movq	%rdx, (%rbx)
	movq	dsp(%rip), %rax
	leaq	8(%rax), %rdx
	movq	%rdx, dsp(%rip)
	movl	$code_docol, %edx
	movq	%rdx, (%rax)
	movq	$1, state(%rip)
	NEXT
WORD_TAIL colon_no_name
WORD_HDR exit, "EXIT", 4, 97, header_colon_no_name
        # TODO: I think the below (equivalent to EXIT_NEXT macro) can be
        # shortened everywhere it appears. Replace it with a GAS macro?
	EXIT_NEXT
WORD_TAIL exit

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

WORD_HDR see, "SEE", 3, 98, header_exit
	call	parse_name_
	movl	$.LC121, %edi
	movl	$0, %eax
	call	printf
	movq	8(%rbx), %rax
	movq	(%rbx), %rsi
	movq	%rax, %rdi
	call	print
	movl	$10, %edi
	call	putchar
	call	find_
	movq	(%rbx), %rax
	testq	%rax, %rax
	jne	.L315
	movl	$.LC122, %edi
	call	puts
	jmp	.L316
.L315:
	movq	8(%rbx), %rax
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
	addq	$16, %rbx
	NEXT
WORD_TAIL see
WORD_HDR utime, "UTIME", 5, 106, header_see
	movl	$0, %esi
	movl	$timeVal, %edi
	call	gettimeofday
	subq	$16, %rbx
	movq	timeVal(%rip), %rdx
	imulq	$1000000, %rdx, %rdx
	movq	timeVal+8(%rip), %rcx
	addq	%rcx, %rdx
	movq	%rdx, 8(%rbx)
	movq	$0, (%rbx)
	NEXT
WORD_TAIL utime
WORD_HDR semicolon, ";", 513, 99, header_utime
	movq	compilationWordlist(%rip), %rax  # Pointer to the header
	movq    (%rax), %rax  # The header itself.
	movq	8(%rax), %rdx # The length word.
	andb	$254, %dh
	movq	%rdx, 8(%rax)
	subq    $8, %rbx
	movq	$header_exit+24, %rdx
	movq	%rdx, (%rbx)
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
	NEXT
WORD_TAIL semicolon

WORD_HDR loop_end, "(LOOP-END)", 10, 107, header_semicolon
        movq    rsp(%rip), %r9    # r9 holds the RSP
        movq    (%r9), %rcx       # rcx holds the index
        movq    %rcx, %rdx
        subq    8(%r9), %rdx      # rdx holds the index-limit
        movq    (%rbx), %r10      # r10 caches the delta

        # Calculate delta + limit-index
        movq    %r10, %rax
        addq    %rdx, %rax
        xorq    %rdx, %rax     # rax is now d+i-l XOR i-l
        # We want a truth flag that's true when the top bit is 0.
        testq   %rax, %rax
        js      .L9901         # Jumps when the top bit is 1.
        movq    $-1, %r11      # Sets flag true when top bit is 0.
        jmp     .L9902
.L9901:
        movq    $0, %r11       # Or false when top bit is 1.
.L9902:
        movq    %rdx, %rax     # rdx is the index-limit, remember.
        xorq    %r10, %rax     # now rax is delta XOR index-limit
        # Same flow as above: true flag when top bit is 0.
        # We OR the new result with the old one, in r11.
        testq   %rax, %rax
        js      .L9903         # Jumps when the top bit is 1.
        orq     $-1, %r11      # Sets flag true when top bit is 0.
        jmp     .L9904
.L9903:
        orq     $0, %r11       # Or false when top bit is 1.
.L9904:
        # Finally, negate the returned flag.
        xorq    $-1, %r11
        # Now r11 holds the flag we want to return, write it onto the stack.
        movq    %r11, (%rbx)
        # And write the delta + index onto the return stack.
        addq    %r10, %rcx
        movq    %rcx, (%r9)
	NEXT
WORD_TAIL loop_end

# Adding native words for calling C with return values.
# The no-return versions of these are written in Forth, they just drop the nonce
# return value.

WORD_HDR ccall_0, "CCALL0", 6, 108, header_loop_end
        movq    (%rbx), %rax  # Only argument is the C function address.
        call    *%rax
        movq    %rax, (%rbx)
        NEXT
WORD_TAIL ccall_0
WORD_HDR ccall_1, "CCALL1", 6, 109, header_ccall_0
        movq    8(%rbx), %rdi # TOS = first argument
        movq    (%rbx), %rax
        subq    $8, %rsp
        call    *%rax
        addq    $8, %rsp
        addq    $8, %rbx
        movq    %rax, (%rbx)
        NEXT
WORD_TAIL ccall_1
WORD_HDR ccall_2, "CCALL2", 6, 110, header_ccall_1
        movq    16(%rbx), %rdi # sp[2] = first argument
        movq    8(%rbx), %rsi # TOS = second argument
        movq    (%rbx), %rax
        subq    $8, %rsp # Align rsp to 16 bytes
        call    *%rax
        addq    $8, %rsp
        addq    $16, %rbx
        movq    %rax, (%rbx)
        NEXT
WORD_TAIL ccall_2
WORD_HDR ccall_3, "CCALL3", 6, 111, header_ccall_2
        movq    24(%rbx), %rdi # sp[3] = first argument
        movq    16(%rbx), %rsi # sp[2] = second argument
        movq    8(%rbx), %rdx # TOS = third argument
        movq    (%rbx), %rax
        subq    $8, %rsp # Align rsp to 16 bytes
        call    *%rax
        addq    $8, %rsp
        addq    $24, %rbx
        movq    %rax, (%rbx)
        NEXT
WORD_TAIL ccall_3
WORD_HDR ccall_4, "CCALL4", 6, 112, header_ccall_3
        movq    32(%rbx), %rdi # sp[4] = first argument
        movq    24(%rbx), %rsi # sp[3] = second argument
        movq    16(%rbx), %rdx # sp[2] = third argument
        movq    8(%rbx), %rcx # TOS = fourth argument
        movq    (%rbx), %rax
        subq    $8, %rsp # Align rsp to 16 bytes
        call    *%rax
        addq    $8, %rsp
        addq    $32, %rbx
        movq    %rax, (%rbx)
        NEXT
WORD_TAIL ccall_4
WORD_HDR ccall_5, "CCALL5", 6, 115, header_ccall_4
        movq    40(%rbx), %rdi # sp[5] = first argument
        movq    32(%rbx), %rsi # sp[4] = second argument
        movq    24(%rbx), %rdx # sp[3] = third argument
        movq    16(%rbx), %rcx # sp[2] = fourth argument
        movq    8(%rbx), %r8 # sp[1] = fifth argument
        movq    (%rbx), %rax
        subq    $8, %rsp # Align rsp to 16 bytes
        call    *%rax
        addq    $8, %rsp
        addq    $40, %rbx
        movq    %rax, (%rbx)
        NEXT
WORD_TAIL ccall_5
WORD_HDR ccall_6, "CCALL6", 6, 116, header_ccall_5
        movq    48(%rbx), %rdi # sp[6] = first argument
        movq    40(%rbx), %rsi # sp[5] = second argument
        movq    32(%rbx), %rdx # sp[4] = third argument
        movq    24(%rbx), %rcx # sp[3] = fourth argument
        movq    16(%rbx), %r8  # sp[2] = fifth argument
        movq    8(%rbx),  %r9  # sp[1] = sixth argument
        movq    (%rbx), %rax
        subq    $8, %rsp # Align rsp to 16 bytes
        call    *%rax
        addq    $8, %rsp
        addq    $48, %rbx
        movq    %rax, (%rbx)
        NEXT
WORD_TAIL ccall_6
WORD_HDR c_library, "C-LIBRARY", 9, 113, header_ccall_6
        # Expects a null-terminated C-style string on the stack, and dlopen()s
        # it, globally, so a generic dlsym() for it will work.
        movq    (%rbx), %rdi
        movq    $258, %rsi  # That's RTLD_NOW | RTLD_GLOBAL.
        subq    $8, %rsp # Align rsp to 16 bytes
        call    dlopen
        addq    $8, %rsp
        movq    %rax, (%rbx) # Push the result. NULL = 0 indicates an error.
        # That's a negated Forth flag.
        NEXT
WORD_TAIL c_library
WORD_HDR c_symbol, "C-SYMBOL", 8, 114, header_c_library
        # Expects the C-style null-terminated string on the stack, and dlsym()s
        # it, returning the resulting pointer on the stack.
        movq   (%rbx), %rsi
        movq   $0, %rdi      # 0 = RTLD_DEFAULT, searching everywhere.
        subq   $8, %rsp # Align rsp to 16 bytes
        call   dlsym
        addq   $8, %rsp
        movq   %rax, (%rbx)  # Put the void* result onto the stack.
        NEXT
WORD_TAIL c_symbol


.LFE123:
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
	# A word list is a linked list of word headers.
	# Each word list is a cell that points to the first header.
	# The indirection is needed so that a wordlist has a fixed identity,
	# even as it grows.
	# searchIndex is the index of the topmost wordlist in the search order.
	# searchArray is the buffer, with room for 16 searches.
	# compilationWordlist points to the current compilation wordlist.
	# Both of those default to the main Forth wordlist.
	# That main wordlist is pre-allocated as forthWordlist.
	movq    $header_c_symbol, %rax
	movq	%rax, forthWordlist(%rip)
	leaq    forthWordlist(%rip), %rax
	movq	%rax, searchArray(%rip)
	movq	%rax, compilationWordlist(%rip)

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
	movq	$_binary_core_file_fs_start, (%rax)
	movq	24(%rsp), %rax
	movq	$_binary_core_file_fs_end, 8(%rax)
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
	movq	$_binary_core_facility_fs_start, (%rax)
	movq	24(%rsp), %rax
	movq	$_binary_core_facility_fs_end, 8(%rax)
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
	movq	$_binary_core_tools_fs_start, (%rax)
	movq	24(%rsp), %rax
	movq	$_binary_core_tools_fs_end, 8(%rax)
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
	movq	$_binary_core_exception_fs_start, (%rax)
	movq	24(%rsp), %rax
	movq	$_binary_core_exception_fs_end, 8(%rax)
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
	movq	$_binary_core_ext_fs_start, (%rax)
	movq	24(%rsp), %rax
	movq	$_binary_core_ext_fs_end, 8(%rax)
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
	movq	$_binary_core_core_fs_start, (%rax)
	movq	24(%rsp), %rax
	movq	$_binary_core_core_fs_end, 8(%rax)
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
	INIT_WORD plus
	INIT_WORD minus
	INIT_WORD times
	INIT_WORD div
	INIT_WORD udiv
	INIT_WORD mod
	INIT_WORD umod
	INIT_WORD and
	INIT_WORD or
	INIT_WORD xor
	INIT_WORD lshift
	INIT_WORD rshift
	INIT_WORD base
	INIT_WORD less_than
	INIT_WORD less_than_unsigned
	INIT_WORD equal
	INIT_WORD dup
	INIT_WORD swap
	INIT_WORD drop
	INIT_WORD over
	INIT_WORD rot
	INIT_WORD neg_rot
	INIT_WORD two_drop
	INIT_WORD two_dup
	INIT_WORD two_swap
	INIT_WORD two_over
	INIT_WORD to_r
	INIT_WORD from_r
	INIT_WORD fetch
	INIT_WORD store
	INIT_WORD cfetch
	INIT_WORD cstore
	INIT_WORD raw_alloc
	INIT_WORD here_ptr
	INIT_WORD print_internal
	INIT_WORD state
	INIT_WORD branch
	INIT_WORD zbranch
	INIT_WORD execute
	INIT_WORD evaluate
	INIT_WORD refill
	INIT_WORD accept
	INIT_WORD key
	INIT_WORD latest
	INIT_WORD in_ptr
	INIT_WORD emit
	INIT_WORD source
	INIT_WORD source_id
	INIT_WORD size_cell
	INIT_WORD size_char
	INIT_WORD cells
	INIT_WORD chars
	INIT_WORD unit_bits
	INIT_WORD stack_cells
	INIT_WORD return_stack_cells
	INIT_WORD to_does
	INIT_WORD to_cfa
	INIT_WORD to_body
	INIT_WORD last_word
	INIT_WORD docol
	INIT_WORD dolit
	INIT_WORD dostring
	INIT_WORD dodoes
	INIT_WORD parse
	INIT_WORD parse_name
	INIT_WORD to_number
	INIT_WORD create
	INIT_WORD find
	INIT_WORD depth
	INIT_WORD sp_fetch
	INIT_WORD sp_store
	INIT_WORD rp_fetch
	INIT_WORD rp_store
	INIT_WORD dot_s
	INIT_WORD u_dot_s
	INIT_WORD dump_file
	INIT_WORD quit
	INIT_WORD bye
	INIT_WORD compile_comma
	INIT_WORD debug_break
	INIT_WORD close_file
	INIT_WORD create_file
	INIT_WORD open_file
	INIT_WORD delete_file
	INIT_WORD file_position
	INIT_WORD file_size
	INIT_WORD file_size
	INIT_WORD include_file
	INIT_WORD read_file
	INIT_WORD read_line
	INIT_WORD reposition_file
	INIT_WORD resize_file
	INIT_WORD write_file
	INIT_WORD write_line
	INIT_WORD flush_file
	INIT_WORD colon
	INIT_WORD colon_no_name
	INIT_WORD exit
	INIT_WORD see
	INIT_WORD semicolon
	INIT_WORD literal
	INIT_WORD compile_literal
	INIT_WORD compile_zbranch
	INIT_WORD compile_branch
	INIT_WORD control_flush
	INIT_WORD utime
	INIT_WORD loop_end

	INIT_WORD ccall_0
	INIT_WORD ccall_1
	INIT_WORD ccall_2
	INIT_WORD ccall_3
	INIT_WORD ccall_4
	INIT_WORD ccall_5
	INIT_WORD ccall_6
	INIT_WORD c_library
	INIT_WORD c_symbol

	INIT_WORD dictionary_info
	INIT_WORD two_fetch
	INIT_WORD two_store

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
	subq	$16, %rbx
	movq	rsp(%rip), %rcx
	movq	(%rcx), %rax
	movq	%rax, 8(%rbx)
	movq	8(%rcx), %rax
	movq	%rax, (%rbx)
	addq	$16, rsp(%rip)
	NEXT
	.cfi_endproc
.LFE126:
	.size	code_superinstruction_from_r_from_r, .-code_superinstruction_from_r_from_r
	.globl	code_superinstruction_fetch_exit
	.type	code_superinstruction_fetch_exit, @function
code_superinstruction_fetch_exit:
.LFB127:
	.cfi_startproc
	movq	(%rbx), %rax
	movq	(%rax), %rax
	movq	%rax, (%rbx)
	EXIT_NEXT
	.cfi_endproc
.LFE127:
	.size	code_superinstruction_fetch_exit, .-code_superinstruction_fetch_exit
	.globl	code_superinstruction_swap_to_r
	.type	code_superinstruction_swap_to_r, @function
code_superinstruction_swap_to_r:
.LFB128:
	.cfi_startproc
        movq    8(%rbx), %rax
        PUSHRSP %rax, %rcx
        movq    (%rbx), %rax
        movq    %rax, 8(%rbx)
        addq    $8, %rbx
	NEXT
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
	movq	(%rbx), %rdx
	movq	%rdx, (%rax)
        addq    $8, %rbx
        movq    (%rbx), %rax
        movq    8(%rbx), %rdx
        movq    %rax, 8(%rbx)
        movq    %rdx, (%rbx)
	NEXT
	.cfi_endproc
.LFE129:
	.size	code_superinstruction_to_r_swap, .-code_superinstruction_to_r_swap
	.globl	code_superinstruction_to_r_exit
	.type	code_superinstruction_to_r_exit, @function
code_superinstruction_to_r_exit:
.LFB130:
	.cfi_startproc
	movq	(%rbx), %rax
	addq    $8, %rbx
	movq	%rax, %rbp
	NEXT
	.cfi_endproc
.LFE130:
	.size	code_superinstruction_to_r_exit, .-code_superinstruction_to_r_exit
	.globl	code_superinstruction_from_r_dup
	.type	code_superinstruction_from_r_dup, @function
code_superinstruction_from_r_dup:
.LFB131:
	.cfi_startproc
        POPRSP %rax
	subq	$16, %rbx
        movq    %rax, (%rbx)
        movq    %rax, 8(%rbx)
	NEXT
	.cfi_endproc
.LFE131:
	.size	code_superinstruction_from_r_dup, .-code_superinstruction_from_r_dup
	.globl	code_superinstruction_dolit_equal
	.type	code_superinstruction_dolit_equal, @function
code_superinstruction_dolit_equal:
.LFB132:
	.cfi_startproc
        movq    (%rbp), %rax
        addq    $8, %rbp
        movq    (%rbx), %rcx
	cmpq	%rcx, %rax
	jne	.L347
	movq	$-1, %rdx
	jmp	.L348
.L347:
	movl	$0, %edx
.L348:
	movq	%rdx, (%rbx)
	NEXT
	.cfi_endproc
.LFE132:
	.size	code_superinstruction_dolit_equal, .-code_superinstruction_dolit_equal
	.globl	code_superinstruction_dolit_fetch
	.type	code_superinstruction_dolit_fetch, @function
code_superinstruction_dolit_fetch:
.LFB133:
	.cfi_startproc
        movq    (%rbp), %rax
        addq    $8, %rbp
	movq	(%rax), %rax
        subq    $8, %rbx
	movq	%rax, (%rbx)
	NEXT
	.cfi_endproc
.LFE133:
	.size	code_superinstruction_dolit_fetch, .-code_superinstruction_dolit_fetch
	.globl	code_superinstruction_dup_to_r
	.type	code_superinstruction_dup_to_r, @function
code_superinstruction_dup_to_r:
.LFB134:
	.cfi_startproc
        movq    (%rbx), %rax
        PUSHRSP %rax, %rcx
	NEXT
	.cfi_endproc
.LFE134:
	.size	code_superinstruction_dup_to_r, .-code_superinstruction_dup_to_r
	.globl	code_superinstruction_dolit_dolit
	.type	code_superinstruction_dolit_dolit, @function
code_superinstruction_dolit_dolit:
.LFB135:
	.cfi_startproc
	subq	$16, %rbx
        movq    (%rbp), %rax
        movq    %rax, 8(%rbx)
        movq    8(%rbp), %rax
        movq    %rax, (%rbx)
        addq    $16, %rbp
	NEXT
	.cfi_endproc
.LFE135:
	.size	code_superinstruction_dolit_dolit, .-code_superinstruction_dolit_dolit
	.globl	code_superinstruction_plus_exit
	.type	code_superinstruction_plus_exit, @function
code_superinstruction_plus_exit:
.LFB136:
	.cfi_startproc
        movq    (%rbx), %rax
        addq    $8, %rbx
        addq    %rax, (%rbx)
	EXIT_NEXT
	.cfi_endproc
.LFE136:
	.size	code_superinstruction_plus_exit, .-code_superinstruction_plus_exit
	.globl	code_superinstruction_dolit_plus
	.type	code_superinstruction_dolit_plus, @function
code_superinstruction_dolit_plus:
.LFB137:
	.cfi_startproc
        movq    (%rbp), %rax
        addq    $8, %rbp
	addq	%rax, (%rbx)
	NEXT
	.cfi_endproc
.LFE137:
	.size	code_superinstruction_dolit_plus, .-code_superinstruction_dolit_plus
	.globl	code_superinstruction_dolit_less_than
	.type	code_superinstruction_dolit_less_than, @function
code_superinstruction_dolit_less_than:
.LFB138:
	.cfi_startproc
        movq    (%rbx), %rsi
        movq    (%rbp), %rax
        addq    $8, %rbp
	cmpq	%rax, %rsi  # TOS -> %rsi, lit -> %rax
	jge	.L355
	movq	$-1, %rax
	jmp	.L356
.L355:
	movl	$0, %eax
.L356:
	movq	%rax, (%rbx)
	NEXT
	.cfi_endproc
.LFE138:
	.size	code_superinstruction_dolit_less_than, .-code_superinstruction_dolit_less_than
	.globl	code_superinstruction_plus_fetch
	.type	code_superinstruction_plus_fetch, @function
code_superinstruction_plus_fetch:
.LFB139:
	.cfi_startproc
        movq    (%rbx), %rax
        addq    $8, %rbx
        addq    (%rbx), %rax
        movq    (%rax), %rax
        movq    %rax, (%rbx)
	NEXT
	.cfi_endproc
.LFE139:
	.size	code_superinstruction_plus_fetch, .-code_superinstruction_plus_fetch
	.globl	code_superinstruction_to_r_to_r
	.type	code_superinstruction_to_r_to_r, @function
code_superinstruction_to_r_to_r:
.LFB140:
	.cfi_startproc
        movq    (%rbx), %rax
        PUSHRSP %rax, %rcx
        movq    8(%rbx), %rax
        PUSHRSP %rax, %rcx
        addq    $16, %rbx
	NEXT
	.cfi_endproc
.LFE140:
	.size	code_superinstruction_to_r_to_r, .-code_superinstruction_to_r_to_r
	.globl	code_superinstruction_dolit_call_
	.type	code_superinstruction_dolit_call_, @function
code_superinstruction_dolit_call_:
.LFB141:
	.cfi_startproc
	subq	$8, %rbx
        movq    (%rbp), %rax
        movq    %rax, (%rbx)
        movq    8(%rbp), %rax
        movq    %rax, ca(%rip)
        addq    $16, %rbp
        PUSHRSP %rbp, %rcx
        movq    %rax, %rbp
	NEXT
	.cfi_endproc
.LFE141:
	.size	code_superinstruction_dolit_call_, .-code_superinstruction_dolit_call_
	.globl	code_superinstruction_equal_exit
	.type	code_superinstruction_equal_exit, @function
code_superinstruction_equal_exit:
.LFB142:
	.cfi_startproc
        movq    (%rbx), %rax
        addq    $8, %rbx
        movq    (%rbx), %rcx
	cmpq	%rax, %rcx
	jne	.L361
	movq	$-1, %rax
	jmp	.L362
.L361:
	movl	$0, %eax
.L362:
	movq	%rax, (%rbx)
        EXIT_NEXT
	.cfi_endproc
.LFE142:
	.size	code_superinstruction_equal_exit, .-code_superinstruction_equal_exit
	.globl	code_superinstruction_to_r_swap_from_r
	.type	code_superinstruction_to_r_swap_from_r, @function
code_superinstruction_to_r_swap_from_r:
.LFB143:
	.cfi_startproc
        # Swapping 8 and 16 slots
        movq    8(%rbx), %rax
        movq    16(%rbx), %rcx
        movq    %rcx, 8(%rbx)
        movq    %rax, 16(%rbx)
	NEXT
	.cfi_endproc
.LFE143:
	.size	code_superinstruction_to_r_swap_from_r, .-code_superinstruction_to_r_swap_from_r
	.globl	code_superinstruction_swap_to_r_exit
	.type	code_superinstruction_swap_to_r_exit, @function
code_superinstruction_swap_to_r_exit:
.LFB144:
	.cfi_startproc
        movq    (%rbx), %rax
        movq    8(%rbx), %rcx
        movq    %rax, 8(%rbx)
        PUSHRSP %rcx, %rax
        addq    $8, %rbx
	EXIT_NEXT
	.cfi_endproc
.LFE144:
	.size	code_superinstruction_swap_to_r_exit, .-code_superinstruction_swap_to_r_exit
	.globl	code_superinstruction_from_r_from_r_dup
	.type	code_superinstruction_from_r_from_r_dup, @function
code_superinstruction_from_r_from_r_dup:
.LFB145:
	.cfi_startproc
        subq    $24, %rbx
        POPRSP %rax
        movq    %rax, 16(%rbx)
        POPRSP %rax
        movq    %rax, 8(%rbx)
        movq    %rax, (%rbx)
	NEXT
	.cfi_endproc
.LFE145:
	.size	code_superinstruction_from_r_from_r_dup, .-code_superinstruction_from_r_from_r_dup
	.globl	code_superinstruction_dup_to_r_swap
	.type	code_superinstruction_dup_to_r_swap, @function
code_superinstruction_dup_to_r_swap:
.LFB146:
	.cfi_startproc
        movq    (%rbx), %rax
        PUSHRSP %rax, %rcx
        movq    (%rbx), %rax
        movq    8(%rbx), %rcx
        movq    %rax, 8(%rbx)
        movq    %rcx, (%rbx)
	NEXT
	.cfi_endproc
.LFE146:
	.size	code_superinstruction_dup_to_r_swap, .-code_superinstruction_dup_to_r_swap
	.globl	code_superinstruction_from_r_dup_to_r
	.type	code_superinstruction_from_r_dup_to_r, @function
code_superinstruction_from_r_dup_to_r:
.LFB147:
	.cfi_startproc
	movq	rsp(%rip), %rax
	movq	(%rax), %rax
        subq    $8, %rbx
        movq    %rax, (%rbx)
	NEXT
	.cfi_endproc
.LFE147:
	.size	code_superinstruction_from_r_dup_to_r, .-code_superinstruction_from_r_dup_to_r
	.globl	code_superinstruction_dolit_fetch_exit
	.type	code_superinstruction_dolit_fetch_exit, @function
code_superinstruction_dolit_fetch_exit:
.LFB148:
	.cfi_startproc
        movq    (%rbp), %rax
        movq    (%rax), %rax
        subq    $8, %rbx
        movq    %rax, (%rbx)
        addq    $8, %rbp
	EXIT_NEXT
	.cfi_endproc
.LFE148:
	.size	code_superinstruction_dolit_fetch_exit, .-code_superinstruction_dolit_fetch_exit
	.globl	code_superinstruction_dolit_plus_exit
	.type	code_superinstruction_dolit_plus_exit, @function
code_superinstruction_dolit_plus_exit:
.LFB149:
	.cfi_startproc
        movq    (%rbp), %rax
        addq    $8, %rbp
	addq	%rax, (%rbx)
	EXIT_NEXT
	.cfi_endproc
.LFE149:
	.size	code_superinstruction_dolit_plus_exit, .-code_superinstruction_dolit_plus_exit
	.globl	code_superinstruction_dolit_less_than_exit
	.type	code_superinstruction_dolit_less_than_exit, @function
code_superinstruction_dolit_less_than_exit:
.LFB150:
	.cfi_startproc
        movq    (%rbp), %rax
	movq	(%rbx), %rdx
	cmpq	%rax, %rdx
	jge	.L371
	movq	$-1, %rax
	jmp	.L372
.L371:
	movl	$0, %eax
.L372:
	movq	%rax, (%rbx)
        addq    $8, %rbp
	EXIT_NEXT
	.cfi_endproc
.LFE150:
	.size	code_superinstruction_dolit_less_than_exit, .-code_superinstruction_dolit_less_than_exit
	.globl	code_superinstruction_dolit_dolit_plus
	.type	code_superinstruction_dolit_dolit_plus, @function
code_superinstruction_dolit_dolit_plus:
.LFB151:
	.cfi_startproc
        movq    (%rbp), %rax
        addq    8(%rbp), %rax
        subq    $8, %rbx
        movq    %rax, (%rbx)
        addq    $16, %rbp
	NEXT
	.cfi_endproc
.LFE151:
	.size	code_superinstruction_dolit_dolit_plus, .-code_superinstruction_dolit_dolit_plus
	.globl	code_superinstruction_cells_sp_fetch_plus
	.type	code_superinstruction_cells_sp_fetch_plus, @function
code_superinstruction_cells_sp_fetch_plus:
.LFB152:
	.cfi_startproc
        movq    (%rbx), %rax
        leaq    0(,%rax,8), %rax
        addq    %rbx, %rax
        movq    %rax, (%rbx)
	NEXT
	.cfi_endproc
.LFE152:
	.size	code_superinstruction_cells_sp_fetch_plus, .-code_superinstruction_cells_sp_fetch_plus
	.globl	code_superinstruction_to_r_swap_to_r
	.type	code_superinstruction_to_r_swap_to_r, @function
code_superinstruction_to_r_swap_to_r:
.LFB153:
	.cfi_startproc
        movq    (%rbx), %rax
        PUSHRSP %rax, %rcx
        movq    16(%rbx), %rax
        PUSHRSP %rax, %rcx
        movq    8(%rbx), %rax
        movq    %rax, 16(%rbx)
        addq    $16, %rbx
	NEXT
	.cfi_endproc
.LFE153:
	.size	code_superinstruction_to_r_swap_to_r, .-code_superinstruction_to_r_swap_to_r
	.globl	code_superinstruction_dolit_equal_exit
	.type	code_superinstruction_dolit_equal_exit, @function
code_superinstruction_dolit_equal_exit:
.LFB154:
	.cfi_startproc
        movq    (%rbx), %rax
        movq    (%rbp), %rcx
        addq    $8, %rbp
	cmpq	%rax, %rcx
	jne	.L377
	movq	$-1, %rax
	jmp	.L378
.L377:
	movl	$0, %eax
.L378:
	movq	%rax, (%rbx)
	EXIT_NEXT
	.cfi_endproc
.LFE154:
	.size	code_superinstruction_dolit_equal_exit, .-code_superinstruction_dolit_equal_exit
	.globl	code_superinstruction_sp_fetch_plus_fetch
	.type	code_superinstruction_sp_fetch_plus_fetch, @function
code_superinstruction_sp_fetch_plus_fetch:
.LFB155:
	.cfi_startproc
        movq    (%rbx), %rax
        addq    %rbx, %rax
        movq    (%rax), %rax
        movq    %rax, (%rbx)
	NEXT
	.cfi_endproc
.LFE155:
	.size	code_superinstruction_sp_fetch_plus_fetch, .-code_superinstruction_sp_fetch_plus_fetch
	.globl	code_superinstruction_plus_fetch_exit
	.type	code_superinstruction_plus_fetch_exit, @function
code_superinstruction_plus_fetch_exit:
.LFB156:
	.cfi_startproc
        movq    (%rbx), %rax
        addq    8(%rbx), %rax
        movq    (%rax), %rax
        addq    $8, %rbx
        movq    %rax, (%rbx)
	EXIT_NEXT
	.cfi_endproc
.LFE156:
	.size	code_superinstruction_plus_fetch_exit, .-code_superinstruction_plus_fetch_exit
	.globl	code_superinstruction_from_r_from_r_two_dup
	.type	code_superinstruction_from_r_from_r_two_dup, @function
code_superinstruction_from_r_from_r_two_dup:
.LFB157:
	.cfi_startproc
	subq	$32, %rbx
        POPRSP  %rax
        movq    %rax, 24(%rbx)
        movq    %rax, 8(%rbx)
        POPRSP  %rax
        movq    %rax, 16(%rbx)
        movq    %rax, (%rbx)
	NEXT
	.cfi_endproc
.LFE157:
	.size	code_superinstruction_from_r_from_r_two_dup, .-code_superinstruction_from_r_from_r_two_dup
	.globl	code_superinstruction_neg_rot_plus_to_r
	.type	code_superinstruction_neg_rot_plus_to_r, @function
code_superinstruction_neg_rot_plus_to_r:
.LFB158:
	.cfi_startproc
        # Bury, add the other two, and send to rsp.
        movq    8(%rbx), %rax
        addq    16(%rbx), %rax
        PUSHRSP %rax, %rcx
        movq    (%rbx), %rax
        addq    $16, %rbx
        movq    %rax, (%rbx)
	NEXT
	.cfi_endproc
.LFE158:
	.size	code_superinstruction_neg_rot_plus_to_r, .-code_superinstruction_neg_rot_plus_to_r
	.globl	code_superinstruction_two_dup_minus_to_r
	.type	code_superinstruction_two_dup_minus_to_r, @function
code_superinstruction_two_dup_minus_to_r:
.LFB159:
	.cfi_startproc
        movq    (%rbx), %rax
        movq    8(%rbx), %rcx
        subq    %rax, %rcx    # Subtracting TOS from second
        PUSHRSP %rcx, %rax
	NEXT
	.cfi_endproc
.LFE159:
	.size	code_superinstruction_two_dup_minus_to_r, .-code_superinstruction_two_dup_minus_to_r
	.globl	code_superinstruction_to_r_swap_to_r_exit
	.type	code_superinstruction_to_r_swap_to_r_exit, @function
code_superinstruction_to_r_swap_to_r_exit:
.LFB160:
	.cfi_startproc
        # This moves TOS to RSP, then third on stack to RSP, and then puts
        # second to third and pops two.
        movq    (%rbx), %rax
        PUSHRSP %rax, %rcx
        movq    16(%rbx), %rax
        PUSHRSP %rax, %rcx
        movq    8(%rbx), %rax
        addq    $16, %rbx
        movq    %rax, (%rbx)
	NEXT
	.cfi_endproc
.LFE160:
	.size	code_superinstruction_to_r_swap_to_r_exit, .-code_superinstruction_to_r_swap_to_r_exit
	.globl	code_superinstruction_dup_to_r_swap_to_r
	.type	code_superinstruction_dup_to_r_swap_to_r, @function
code_superinstruction_dup_to_r_swap_to_r:
.LFB161:
	.cfi_startproc
        movq    (%rbx), %rax
        PUSHRSP %rax, %rcx
        movq    8(%rbx), %rdx
        PUSHRSP %rdx, %rcx
        addq    $8, %rbx
        movq    %rax, (%rbx)
	NEXT
	.cfi_endproc
.LFE161:
	.size	code_superinstruction_dup_to_r_swap_to_r, .-code_superinstruction_dup_to_r_swap_to_r
	.globl	code_superinstruction_from_r_dup_to_r_swap
	.type	code_superinstruction_from_r_dup_to_r_swap, @function
code_superinstruction_from_r_dup_to_r_swap:
.LFB162:
	.cfi_startproc
        movq    (%rbx), %rax
        subq    $8, %rbx
        movq    %rax, (%rbx)
        movq    rsp(%rip), %rax
        movq    (%rax), %rax
        movq    %rax, 8(%rbx)
	NEXT
	.cfi_endproc
.LFE162:
	.size	code_superinstruction_from_r_dup_to_r_swap, .-code_superinstruction_from_r_dup_to_r_swap
	.globl	code_superinstruction_from_r_from_r_dup_to_r
	.type	code_superinstruction_from_r_from_r_dup_to_r, @function
code_superinstruction_from_r_from_r_dup_to_r:
.LFB163:
	.cfi_startproc
        subq    $16, %rbx
        POPRSP  %rax
        movq    %rax, 8(%rbx)
        movq    rsp(%rip), %rax
        movq    (%rax), %rax
        movq    %rax, (%rbx)
	NEXT
	.cfi_endproc
.LFE163:
	.size	code_superinstruction_from_r_from_r_dup_to_r, .-code_superinstruction_from_r_from_r_dup_to_r
	.globl	code_superinstruction_cells_sp_fetch_plus_fetch
	.type	code_superinstruction_cells_sp_fetch_plus_fetch, @function
code_superinstruction_cells_sp_fetch_plus_fetch:
.LFB164:
	.cfi_startproc
        movq    (%rbx), %rax
        leaq    (,%rax,8), %rax
        addq    %rbx, %rax
        movq    (%rax), %rax
        movq    %rax, (%rbx)
	NEXT
	.cfi_endproc
.LFE164:
	.size	code_superinstruction_cells_sp_fetch_plus_fetch, .-code_superinstruction_cells_sp_fetch_plus_fetch
	.globl	code_superinstruction_two_dup_minus_to_r_dolit
	.type	code_superinstruction_two_dup_minus_to_r_dolit, @function
code_superinstruction_two_dup_minus_to_r_dolit:
.LFB165:
	.cfi_startproc
        movq    (%rbx), %rax
        movq    8(%rbx), %rcx
        subq    %rax, %rcx
        PUSHRSP %rcx, %rax
        subq    $8, %rbx
        movq    (%rbp), %rax
        movq    %rax, (%rbx)
        addq    $8, %rbp
	NEXT
	.cfi_endproc
.LFE165:
	.size	code_superinstruction_two_dup_minus_to_r_dolit, .-code_superinstruction_two_dup_minus_to_r_dolit
	.globl	code_superinstruction_from_r_two_dup_minus_to_r
	.type	code_superinstruction_from_r_two_dup_minus_to_r, @function
code_superinstruction_from_r_two_dup_minus_to_r:
.LFB166:
	.cfi_startproc
        movq    (%rbx), %rax
        movq    rsp(%rip), %rcx
        subq    (%rcx), %rax
        movq    %rax, (%rcx)
	NEXT
	.cfi_endproc
.LFE166:
	.size	code_superinstruction_from_r_two_dup_minus_to_r, .-code_superinstruction_from_r_two_dup_minus_to_r
	.globl	code_superinstruction_from_r_from_r_two_dup_minus
	.type	code_superinstruction_from_r_from_r_two_dup_minus, @function
code_superinstruction_from_r_from_r_two_dup_minus:
.LFB167:
	.cfi_startproc
        subq    $24, %rbx
        POPRSP  %rax
        POPRSP  %rcx
        movq    %rax, 16(%rbx)
        movq    %rcx, 8(%rbx)
        subq    %rcx, %rax
        movq    %rax, (%rbx)
	NEXT
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
