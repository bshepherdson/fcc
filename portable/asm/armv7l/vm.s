        @ r11 holds IP, sp/r13 the Forth stack pointer
        @ it's saved by the callee, so that should work
        @ r9 is reserved as the dump slot before calling
        @ external C functions. (It should only appear in the CALL and
        @ CALL_REG macros, below, as well as ccall5 and 6.)
	.arch armv7-a
	.eabi_attribute 28, 1
	.eabi_attribute 20, 1
	.eabi_attribute 21, 1
	.eabi_attribute 23, 3
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 2
	.eabi_attribute 30, 6
	.eabi_attribute 34, 1
	.eabi_attribute 18, 4
	.file	"vm.c"

        .macro NEXT
	ldr	r2, [r11]
	add	r11, r11, #4
	bx	r2
        .endm

        @ TODO: These could be faster with write-back LDR and STR.
        .macro PUSHRSP reg, thru_addr, thru_val
	movw	\thru_addr, #:lower16:rsp
	movt	\thru_addr, #:upper16:rsp
	ldr	\thru_val, [\thru_addr]
	sub	\thru_val, \thru_val, #4
        str     \reg, [\thru_val]
        str     \thru_val, [\thru_addr]
        .endm

        .macro POPRSP reg, thru_addr, thru_val
	movw	\thru_addr, #:lower16:rsp
	movt	\thru_addr, #:upper16:rsp
	ldr	\thru_val, [\thru_addr]
        ldr     \reg, [\thru_val]
	add	\thru_val, \thru_val, #4
        str     \thru_val, [\thru_addr]
        .endm

        .macro EXIT_NEXT
        POPRSP r11, r1, r2
        NEXT
        .endm

        .macro CALL label
        mov     r9, sp
        bic     sp, sp, #7
        bl      \label
        mov     sp, r9
        .endm

        .macro CALL_REG reg
        mov     r9, sp
        bic     sp, sp, #7
        blx     \reg
        mov     sp, r9
        .endm

        .macro CALL_NEXT
        movw    r0, #:lower16:ca
        movt    r0, #:upper16:ca
        ldr     r1, [r11], #4
        str     r1, [r0]
        PUSHRSP r11, r2, r3
        mov     r11, r1
        NEXT
        .endm

        .macro INIT_WORD name
	movw	r3, #:lower16:key_\name
	movt	r3, #:upper16:key_\name
	ldr	r3, [r3]
	sub	r1, r3, #1
	movw	r3, #:lower16:key_\name
	movt	r3, #:upper16:key_\name
	ldr	r0, [r3]
	movw	r3, #:lower16:primitives
	movt	r3, #:upper16:primitives
	movw	r2, #:lower16:code_\name
	movt	r2, #:upper16:code_\name
	str	r2, [r3, r1, lsl #3]
	movw	r2, #:lower16:primitives
	movt	r2, #:upper16:primitives
	lsl	r3, r1, #3
	add	r3, r2, r3
	str	r0, [r3, #4]
        .endm

        .macro WORD_HDR code_name, forth_name, name_length, key, previous
	.global	header_\code_name
	.section	.rodata
	.align	2
.str_\code_name:
	.asciz	"\forth_name"
	.data
	.align	2
	.type	header_\code_name, %object
	.size	header_\code_name, 16
header_\code_name:
	.word	\previous
	.word	\name_length
	.word	.str_\code_name
	.word	code_\code_name
	.global	key_\code_name
	.align	2
	.type	key_\code_name, %object
	.size	key_\code_name, 4
key_\code_name:
	.word	\key
	.text
	.align	2
	.global	code_\code_name
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_\code_name, %function
code_\code_name:
        .endm

        .macro WORD_TAIL name
	.size	code_\name, .-code_\name
        .endm



	.comm	_stack_data,65536,4
	.global	spTop
	.data
	.align	2
	.type	spTop, %object
	.size	spTop, 4
spTop:
	.word	_stack_data+65536
	.comm	sp,4,4
	.comm	_stack_return,4096,4
	.global	rspTop
	.align	2
	.type	rspTop, %object
	.size	rspTop, 4
rspTop:
	.word	_stack_return+4096
	.comm	rsp,4,4
	.comm	ip,4,4
	.comm	cfa,4,4
	.comm	ca,4,4
	.global	firstQuit
	.type	firstQuit, %object
	.size	firstQuit, 1
firstQuit:
	.byte	1
	.global	quitTop
	.bss
	.align	2
	.type	quitTop, %object
	.size	quitTop, 4
quitTop:
	.space	4
	.global	quitTopPtr
	.data
	.align	2
	.type	quitTopPtr, %object
	.size	quitTopPtr, 4
quitTopPtr:
	.word	quitTop
	.comm	dsp,4,4
	.comm	state,4,4
	.comm	base,4,4
        @ A word list is a linked list of word headers.
        @ Each word list is a cell that points to that header.
        @ The indirection is needed so that a wordlist has a fixed identity,
        @ even as it grows.
        @ searchIndex is the index of the topmost wordlist in the search order.
        @ searchArray is the buffer, with room for 16 searches.
        @ compilationWordlist points to the current compilation wordlist.
        @ Both of those default to the main Forth wordlist.
        @ That main wordlist is pre-allocated as forthWordlist.
        .comm   searchArray,64,4
        .comm   searchIndex,4,4
        .comm   compilationWordlist,4,4
        .comm   forthWordlist,4,4
	.comm	lastWord,4,4
	.comm	parseBuffers,8192,4
	.comm	inputSources,512,4
	.comm	inputIndex,4,4
	.comm	c1,4,4
	.comm	c2,4,4
	.comm	c3,4,4
	.comm	ch1,1,1
	.comm	str1,4,4
	.comm	strptr1,4,4
	.comm	tempSize,4,4
	.comm	tempHeader,4,4
	.comm	tempBuf,256,4
	.comm	numBuf,8,4
	.comm	tempFile,4,4
	.comm	tempStat,88,8
	.comm	quit_inner,4,4
	.comm	timeVal,8,4
	.comm	i64,8,8
	.comm	old_tio,60,4
	.comm	new_tio,60,4
	.global	primitive_count
	.align	2
	.type	primitive_count, %object
	.size	primitive_count, 4
primitive_count:
	.word	118
	.global	queue
	.bss
	.align	2
	.type	queue, %object
	.size	queue, 4
queue:
	.space	4
	.global	queueTail
	.align	2
	.type	queueTail, %object
	.size	queueTail, 4
queueTail:
	.space	4
	.comm	tempQueue,4,4
	.comm	queueSource,80,4
	.global	next_queue_source
	.align	2
	.type	next_queue_source, %object
	.size	next_queue_source, 4
next_queue_source:
	.space	4
	.global	queue_length
	.align	2
	.type	queue_length, %object
	.size	queue_length, 4
queue_length:
	.space	4
	.comm	primitives,2048,4
	.comm	superinstructions,2048,4
	.global	nextSuperinstruction
	.align	2
	.type	nextSuperinstruction, %object
	.size	nextSuperinstruction, 4
nextSuperinstruction:
	.space	4
	.comm	key1,4,4
	.section	.rodata
	.align	2
.LC0:
	.ascii	"%s\000"
	.text
	.align	2
	.global	print
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	print, %function
print:
	str	lr, [sp, #-4]!
	sub	sp, sp, #12
	str	r0, [sp, #4]
	str	r1, [sp]
	ldr	r3, [sp]
	add	r3, r3, #1
	mov	r0, r3
	CALL	malloc
	mov	r3, r0
	mov	r2, r3
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	str	r2, [r3]
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r2, [sp]
	ldr	r1, [sp, #4]
	ldr	r0, [r3]
	CALL	strncpy
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r2, [r3]
	ldr	r3, [sp]
	add	r3, r2, r3
	mov	r2, #0
	strb	r2, [r3]
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r1, [r3]
	movw	r0, #:lower16:.LC0
	movt	r0, #:upper16:.LC0
	CALL	printf
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r0, [r3]
	CALL	free
	nop
	add	sp, sp, #12
	@ sp needed
	ldr	pc, [sp], #4
	.size	print, .-print
WORD_HDR plus, "+", 1, 1, 0
        pop     {r0, r1}
        add     r0, r0, r1
        push    {r0}
        NEXT
WORD_TAIL plus
WORD_HDR minus, "-", 1, 2, header_plus
        pop     {r0, r1}
        sub     r0, r1, r0
        push    {r0}
	NEXT
WORD_TAIL minus
WORD_HDR times, "*", 1, 3, header_minus
	pop     {r1, r3}
	mul	r3, r3, r1
        push    {r3}
	NEXT
WORD_TAIL times
WORD_HDR div, "/", 1, 4, header_times
        pop     {r1, r2}
        mov     r0, r2
	CALL	__aeabi_idiv
        push    {r0}
	NEXT
WORD_TAIL div
WORD_HDR udiv, "U/", 2, 5, header_div
        pop     {r1, r2}
        mov     r0, r2
        CALL      __aeabi_uidiv
        push    {r0}
	NEXT
WORD_TAIL udiv
WORD_HDR mod, "MOD", 3, 6, header_udiv
        pop     {r1, r2}
        mov     r0, r2
	CALL	__aeabi_idivmod
        push    {r1}
	NEXT
WORD_TAIL mod
WORD_HDR umod, "UMOD", 4, 7, header_mod
        pop     {r1, r2}
        mov     r0, r2
	CALL	__aeabi_uidivmod
        push    {r1}
	NEXT
WORD_TAIL umod

WORD_HDR and, "AND", 3, 8, header_umod
        pop     {r0, r1}
        and     r0, r0, r1
        push    {r0}
	NEXT
WORD_TAIL and
WORD_HDR or, "OR", 2, 9, header_and
        pop     {r0, r1}
        orr     r0, r0, r1
        push    {r0}
	NEXT
WORD_TAIL or

WORD_HDR xor, "XOR", 3, 10, header_or
        pop     {r0, r1}
        eor     r0, r0, r1
        push    {r0}
	NEXT
WORD_TAIL xor
WORD_HDR lshift, "LSHIFT", 6, 11, header_xor
	pop     {r0, r1}
	lsl	r1, r1, r0
        push    {r1}
	NEXT
WORD_TAIL lshift
WORD_HDR rshift, "RSHIFT", 6, 12, header_lshift
	pop     {r0, r1}
	lsr	r1, r1, r0
        push    {r1}
	NEXT
WORD_TAIL rshift
WORD_HDR base, "BASE", 4, 13, header_rshift
	movw	r3, #:lower16:base
	movt	r3, #:upper16:base
        push    {r3}
	NEXT
WORD_TAIL base
WORD_HDR less_than, "<", 1, 14, header_base
	pop     {r0, r1}
	cmp	r1, r0
	bge	.L21
	mvn	r3, #0
	b	.L22
.L21:
	mov	r3, #0
.L22:
        push    {r3}
	NEXT
WORD_TAIL less_than
WORD_HDR less_than_unsigned, "U<", 2, 15, header_less_than
        pop     {r0, r1}
	cmp	r1, r0
	bcs	.L24
	mvn	r3, #0
	b	.L25
.L24:
	mov	r3, #0
.L25:
        push    {r3}
	NEXT
WORD_TAIL less_than_unsigned
WORD_HDR equal, "=", 1, 16, header_less_than_unsigned
	pop     {r1, r3}
	cmp	r1, r3
	bne	.L27
	mvn	r3, #0
	b	.L28
.L27:
	mov	r3, #0
.L28:
        push    {r3}
	NEXT
WORD_TAIL equal
WORD_HDR dup, "DUP", 3, 17, header_equal
	ldr     r0, [sp]
        push    {r0}
	NEXT
WORD_TAIL dup
WORD_HDR swap, "SWAP", 4, 18, header_dup
        pop    {r0, r1}
        mov    r2, r0
        push   {r1, r2}
	NEXT
WORD_TAIL swap
WORD_HDR drop, "DROP", 4, 19, header_swap
        add     sp, #4
	NEXT
WORD_TAIL drop
WORD_HDR over, "OVER", 4, 20, header_drop
        ldr     r0, [sp, #4]
        push    {r0}
	NEXT
WORD_TAIL over
WORD_HDR rot, "ROT", 3, 21, header_over
        @ rot = surface, ( r3 r2 r1 -- r2 r1 r0 )
        pop     {r1, r2, r3}
        mov     r0, r3
        push    {r0, r1, r2}
	NEXT
WORD_TAIL rot
WORD_HDR neg_rot, "-ROT", 4, 22, header_rot
        @ -rot = bury, ( r2 r1 r0 -- r3 r2 r1 )
        pop     {r0, r1, r2}
        mov     r3, r0
        push    {r1, r2, r3}
	NEXT
WORD_TAIL neg_rot
WORD_HDR two_drop, "2DROP", 5, 23, header_neg_rot
	add    sp, #8
        NEXT
WORD_TAIL two_drop
WORD_HDR two_dup, "2DUP", 4, 24, header_two_drop
        ldr     r0, [sp]
        ldr     r1, [sp, #4]
        push    {r0, r1}
	NEXT
WORD_TAIL two_dup
WORD_HDR two_swap, "2SWAP", 5, 25, header_two_dup
        @ ( r6 r5 r4 r3 -- r4 r3 r2 r1 )
        pop     {r3, r4, r5, r6}
        mov     r2, r6
        mov     r1, r5
        push    {r1, r2, r3, r4}
	NEXT
WORD_TAIL two_swap
WORD_HDR two_over, "2OVER", 5, 26, header_two_swap
        ldr     r0, [sp, #8]
        ldr     r1, [sp, #12]
        push    {r0, r1}
	NEXT
WORD_TAIL two_over
WORD_HDR to_r, ">R", 2, 27, header_two_over
        pop    {r0}
        PUSHRSP r0, r1, r2
        NEXT
WORD_TAIL to_r
WORD_HDR from_r, "R>", 2, 28, header_to_r
        POPRSP  r0, r1, r2
        push {r0}
        NEXT
WORD_TAIL from_r
WORD_HDR fetch, "@", 1, 29, header_from_r
	pop     {r0}
        ldr     r0, [r0]
        push    {r0}
	NEXT
WORD_TAIL fetch
WORD_HDR store, "!", 1, 30, header_fetch
	pop     {r0, r1}
        str     r1, [r0]
	NEXT
WORD_TAIL store
WORD_HDR cfetch, "C@", 2, 31, header_store
	pop     {r0}
        ldrb    r0, [r0]
        push    {r0}
	NEXT
WORD_TAIL cfetch
WORD_HDR cstore, "C!", 2, 32, header_cfetch
	pop     {r0, r1}
        strb    r1, [r0]
        NEXT
WORD_TAIL cstore
WORD_HDR raw_alloc, "(ALLOCATE)", 10, 33, header_cstore
        pop     {r0}
	CALL	malloc
        push    {r0}
	NEXT
WORD_TAIL raw_alloc
WORD_HDR here_ptr, "(>HERE)", 7, 34, header_raw_alloc
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
        push    {r3}
	NEXT
WORD_TAIL here_ptr

.section .rodata
.align 2
.LC36: .ascii "%d \000"
.text

WORD_HDR print_internal, "(PRINT)", 7, 35, header_here_ptr
	pop    	{r1}
	movw	r0, #:lower16:.LC36
	movt	r0, #:upper16:.LC36
	CALL	printf
	NEXT
WORD_TAIL print_internal
WORD_HDR state, "STATE", 5, 36, header_print_internal
	movw	r3, #:lower16:state
	movt	r3, #:upper16:state
        push    {r3}
	NEXT
WORD_TAIL state
WORD_HDR branch, "(BRANCH)", 8, 37, header_state
        ldr     r0, [r11]
        add     r11, r11, r0
	NEXT
WORD_TAIL branch
WORD_HDR zbranch, "(0BRANCH)", 9, 38, header_branch
        pop     {r3}
	cmp	r3, #0
	bne	.L53
        ldr     r2, [r11]
	b	.L54
.L53:
	mov	r2, #4
.L54:
        add     r11, r11, r2
	NEXT
WORD_TAIL zbranch
WORD_HDR execute, "EXECUTE", 7, 39, header_zbranch
        pop     {r2}
	movw	r3, #:lower16:cfa
	movt	r3, #:upper16:cfa
	str	r2, [r3]
        ldr     r2, [r2]
	movw	r3, #:lower16:ca
	movt	r3, #:upper16:ca
	str	r2, [r3]
	bx	r2
WORD_TAIL execute
WORD_HDR evaluate, "EVALUATE", 8, 40, header_execute
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
        ldr     r2, [r3]
        add     r2, r2, #1
        str     r2, [r3]
        lsl     r2, r2, #4   @ Now r2 is an offset in bytes.
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
        add     r3, r3, r2   @ And r3 is the address of the source struct

        pop     {r0, r1}
        str     r0, [r3]
        str     r1, [r3, #12] @ parseBuffer is +12
        mov     r0, #0
        str     r0, [r3, #4]  @ inputPtr is +4
        mvn     r0, #0
        str     r0, [r3, #8]  @ type is +8

        mov     r0, r11
        PUSHRSP r0, r1, r2

	movw	r3, #:lower16:quit_inner
	movt	r3, #:upper16:quit_inner
	ldr	r3, [r3]
	mov	pc, r3	@ indirect register jump
WORD_TAIL evaluate
	.section	.rodata
	.align	2
.LC42:
	.ascii	"> \000"
	.text
	.align	2
	.global	refill_
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	refill_, %function
refill_:
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r3, [r3, #8]
	cmn	r3, #1
	bne	.L58
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r2, [r3]
	sub	r2, r2, #1
	str	r2, [r3]
        POPRSP  r11, r0, r1
	NEXT
.L58:
        push    {lr}
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r3, [r3, #8]
	cmp	r3, #0
	bne	.L59
        @ Middle case: keyboard
	movw	r0, #:lower16:.LC42
	movt	r0, #:upper16:.LC42
	CALL	readline
	mov	r2, r0
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	str	r2, [r3]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r4, [r3]
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r0, [r3]
	CALL	strlen
	mov	r3, r0
	mov	r2, r3
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	str	r2, [r3, r4, lsl #4]
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	movw	r2, #:lower16:inputIndex
	movt	r2, #:upper16:inputIndex
	ldr	r2, [r2]
	ldr	r0, [r3, r2, lsl #4]
	movw	r1, #:lower16:str1
	movt	r1, #:upper16:str1
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	mov	r2, r0
	ldr	r1, [r1]
	ldr	r0, [r3, #12]
	CALL	strncpy
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r3, #4
	add	r3, r2, r3
	mov	r2, #0
	str	r2, [r3, #4]
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r0, [r3]
	CALL	free
	mvn	r3, #0
	b	.L60
.L59:
        @ third case, external file check
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r3, [r3, #8]
	and	r3, r3, #1
	cmp	r3, #0
	beq	.L61
        @ third case is go: external file.
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r3, [r3, #8]
	bic	r3, r3, #1
        push    {r3}
	ldr	r2, [r3]
	ldr	r3, [sp]
	ldr	r3, [r3, #4]
	cmp	r2, r3
	bcc	.L62
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	movw	r2, #:lower16:inputIndex
	movt	r2, #:upper16:inputIndex
	ldr	r2, [r2]
	sub	r2, r2, #1
	str	r2, [r3]
	mov	r3, #0
        add     sp, sp, #4
	b	.L60
.L62:
	ldr	r3, [sp]
	ldr	r2, [r3]
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	str	r2, [r3]
	b	.L63
.L65:
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	movw	r2, #:lower16:str1
	movt	r2, #:upper16:str1
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
.L63:
	ldr	r3, [sp]
	ldr	r2, [r3, #4]
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r3, [r3]
	cmp	r2, r3
	bls	.L64
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r3, [r3]
	ldrb	r3, [r3]	@ zero_extendqisi2
	cmp	r3, #10
	bne	.L65
.L64:
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r2, [r3]
	ldr	r3, [sp]
	ldr	r1, [r3]
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r3, [r3]
	sub	r1, r3, r1
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	str	r1, [r3, r2, lsl #4]
	ldr	r3, [sp]
	ldr	r1, [r3]
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	movw	r2, #:lower16:inputIndex
	movt	r2, #:upper16:inputIndex
	ldr	r2, [r2]
	ldr	r0, [r3, r2, lsl #4]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	mov	r2, r0
	ldr	r0, [r3, #12]
	CALL	strncpy
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r3, #4
	add	r3, r2, r3
	mov	r2, #0
	str	r2, [r3, #4]
	ldr	r3, [sp]
	ldr	r2, [r3, #4]
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r3, [r3]
	cmp	r2, r3
	bls	.L66
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r3, [r3]
	add	r3, r3, #1
	b	.L67
.L66:
	ldr	r3, [sp]
	ldr	r3, [r3, #4]
.L67:
	ldr	r2, [sp]
	str	r3, [r2]
	mvn	r3, #0
        add     sp, sp, #4
	b	.L60
.L61:
        @ fourth case: real file
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	mov	r2, #0
	str	r2, [r3]
	movw	r3, #:lower16:tempSize
	movt	r3, #:upper16:tempSize
	mov	r2, #0
	str	r2, [r3]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r3, [r3, #8]
	mov	r2, r3
	movw	r1, #:lower16:tempSize
	movt	r1, #:upper16:tempSize
	movw	r0, #:lower16:str1
	movt	r0, #:upper16:str1
	CALL	getline
	mov	r2, r0
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	str	r2, [r3]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	cmn	r3, #1
	bne	.L68
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	movw	r2, #:lower16:inputIndex
	movt	r2, #:upper16:inputIndex
	ldr	r2, [r2]
	sub	r2, r2, #1
	str	r2, [r3]
	mov	r3, #0
	b	.L60
.L68:
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r2, [r3]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	add	r3, r2, r3
	sub	r3, r3, #1
	ldrb	r3, [r3]	@ zero_extendqisi2
	cmp	r3, #10
	bne	.L69
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	movw	r2, #:lower16:c1
	movt	r2, #:upper16:c1
	ldr	r2, [r2]
	sub	r2, r2, #1
	str	r2, [r3]
.L69:
	movw	r2, #:lower16:c1
	movt	r2, #:upper16:c1
	movw	r1, #:lower16:str1
	movt	r1, #:upper16:str1
	movw	r0, #:lower16:inputSources
	movt	r0, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r0, r3
	ldr	r2, [r2]
	ldr	r1, [r1]
	ldr	r0, [r3, #12]
	CALL	strncpy
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r0, [r3]
	CALL	free
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r1, [r3]
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	movw	r2, #:lower16:c1
	movt	r2, #:upper16:c1
	ldr	r2, [r2]
	str	r2, [r3, r1, lsl #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r3, #4
	add	r3, r2, r3
	mov	r2, #0
	str	r2, [r3, #4]
	mvn	r3, #0
.L60:
	mov	r0, r3
	@ sp needed
	pop	{pc}
	.size	refill_, .-refill_

WORD_HDR refill, "REFILL", 6, 41, header_evaluate
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r3, [r3, #8]
	cmn	r3, #1
	bne	.L73
        mov     r0, #0
        push    {r0}
	b	.L74
.L73:
	bl	refill_
        push    {r0}
.L74:
	NEXT
WORD_TAIL refill
WORD_HDR accept, "ACCEPT", 6, 42, header_refill
	mov	r0, #0
	CALL	readline
	mov	r4, r0     @ r4 holds the string
	CALL	strlen     @ r0 holds the length
        ldr     r1, [sp]
        cmp     r1, r0
        bge     .L77
        mov     r0, r1
.L77:
        @ Now arrange things for the strncpy call
        mov     r5, r0
        mov     r2, r0 @ length in r2, saved in r5
        mov     r1, r4 @ string in r1
        ldr     r0, [sp, #4] @ sp[1] in r0
	CALL	strncpy
        add     sp, sp, #8
        push    {r5}   @ push the saved length
        mov     r0, r4
        CALL    free   @ free the string
        NEXT
WORD_TAIL accept
WORD_HDR key, "KEY", 3, 43, header_accept
	movw	r1, #:lower16:old_tio
	movt	r1, #:upper16:old_tio
	mov	r0, #0
	CALL	tcgetattr
	movw	r2, #:lower16:new_tio
	movt	r2, #:upper16:new_tio
	movw	r3, #:lower16:old_tio
	movt	r3, #:upper16:old_tio
	mov	ip, r2
	mov	lr, r3
	ldmia	lr!, {r0, r1, r2, r3}
	stmia	ip!, {r0, r1, r2, r3}
	ldmia	lr!, {r0, r1, r2, r3}
	stmia	ip!, {r0, r1, r2, r3}
	ldmia	lr!, {r0, r1, r2, r3}
	stmia	ip!, {r0, r1, r2, r3}
	ldm	lr, {r0, r1, r2}
	stm	ip, {r0, r1, r2}
	movw	r3, #:lower16:new_tio
	movt	r3, #:upper16:new_tio
	movw	r2, #:lower16:new_tio
	movt	r2, #:upper16:new_tio
	ldr	r2, [r2, #12]
	bic	r2, r2, #10
	str	r2, [r3, #12]
	movw	r2, #:lower16:new_tio
	movt	r2, #:upper16:new_tio
	mov	r1, #0
	mov	r0, #0
	CALL	tcsetattr
	CALL	getchar
        push    {r0}
	movw	r2, #:lower16:old_tio
	movt	r2, #:upper16:old_tio
	mov	r1, #0
	mov	r0, #0
	CALL	tcsetattr
	NEXT
WORD_TAIL key
WORD_HDR latest, "(LATEST)", 8, 44, header_key
	movw	r3, #:lower16:compilationWordlist
	movt	r3, #:upper16:compilationWordlist
        ldr     r3, [r3]
        push    {r3}
	NEXT
WORD_TAIL latest
WORD_HDR dictionary_info, "(DICT-INFO)", 11, 117, header_latest
	movw	r3, #:lower16:compilationWordlist
	movt	r3, #:upper16:compilationWordlist
        push    {r3}
	movw	r2, #:lower16:searchIndex
	movt	r2, #:upper16:searchIndex
        push    {r2}
	movw	r2, #:lower16:searchArray
	movt	r2, #:upper16:searchArray
        push    {r2}
        NEXT
WORD_TAIL dictionary_info
WORD_HDR in_ptr, ">IN", 3, 45, header_dictionary_info
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r1, r3, #4
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	add	r3, r1, r3
	add	r3, r3, #4
        push    {r3}
	NEXT
WORD_TAIL in_ptr
WORD_HDR emit, "EMIT", 4, 46, header_in_ptr
        pop     {r0}
	movw	r3, #:lower16:stdout
	movt	r3, #:upper16:stdout
	ldr	r1, [r3]
	CALL	fputc
	NEXT
WORD_TAIL emit
WORD_HDR source, "SOURCE", 6, 47, header_emit
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	movw	r2, #:lower16:inputIndex
	movt	r2, #:upper16:inputIndex
	ldr	r2, [r2]
        lsl     r2, r2, #4
        add     r3, r3, r2
        ldr     r0, [r3]        @ Load length from +0
        ldr     r1, [r3, #12]   @ Load buffer from +12
        push    {r0, r1}
	NEXT
WORD_TAIL source
WORD_HDR source_id, "SOURCE-ID", 9, 48, header_source
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r3, [r3, #8]
        push    {r3}
	NEXT
WORD_TAIL source_id
WORD_HDR size_cell, "(/CELL)", 7, 49, header_source_id
	mov r0, #4
        push {r0}
        NEXT
WORD_TAIL size_cell
WORD_HDR size_char, "(/CHAR)", 7, 50, header_size_cell
        mov     r0, #1
        push    {r0}
        NEXT
WORD_TAIL size_char
WORD_HDR cells, "CELLS", 5, 51, header_size_char
        pop     {r0}
        lsl     r0, r0, #2
        push    {r0}
	NEXT
WORD_TAIL cells
WORD_HDR chars, "CHARS", 5, 52, header_cells
	NEXT
WORD_TAIL chars
WORD_HDR unit_bits, "(ADDRESS-UNIT-BITS)", 19, 53, header_chars
        mov     r0, #8
        push    {r0}
	NEXT
WORD_TAIL unit_bits
WORD_HDR stack_cells, "(STACK-CELLS)", 13, 54, header_unit_bits
	mov	r2, #16384
        push    {r2}
	NEXT
WORD_TAIL stack_cells
WORD_HDR return_stack_cells, "(RETURN-STACK-CELLS)", 20, 55, header_stack_cells
	mov	r2, #1024
        push    {r2}
        NEXT
WORD_TAIL return_stack_cells
WORD_HDR to_does, "(>DOES)", 7, 56, header_return_stack_cells
        pop     {r0}
        add     r0, r0, #16
        push    {r0}
        NEXT
WORD_TAIL to_does
WORD_HDR to_cfa, "(>CFA)", 6, 57, header_to_does
        pop     {r0}
        ldr     r0, [r0]
        add     r0, r0, #12
        push    {r0}
	NEXT
WORD_TAIL to_cfa
WORD_HDR to_body, ">BODY", 5, 58, header_to_cfa
        pop     {r0}
        add     r0, r0, #8
        push    {r0}
	NEXT
WORD_TAIL to_body
WORD_HDR last_word, "(LAST-WORD)", 11, 59, header_to_body
	movw	r3, #:lower16:lastWord
	movt	r3, #:upper16:lastWord
	ldr	r3, [r3]
        push    {r3}
	NEXT
WORD_TAIL last_word
WORD_HDR docol, "(DOCOL)", 7, 60, header_last_word
        PUSHRSP r11, r0, r1
	movw	r3, #:lower16:cfa
	movt	r3, #:upper16:cfa
	ldr	r3, [r3]
	add	r11, r3, #4
	NEXT
WORD_TAIL docol
WORD_HDR dolit, "(DOLIT)", 7, 61, header_docol
        ldr     r0, [r11]
        add     r11, r11, #4
        push    {r0}
        NEXT
WORD_TAIL dolit
WORD_HDR dostring, "(DOSTRING)", 10, 62, header_dolit
        ldrb    r0, [r11]
        add     r1, r11, #1
        push    {r0, r1}
        add     r0, r0, #4   @ + 1 + 3 for alignment
        add     r11, r11, r0
        and     r11, #-4       @ Aligning to a word.
	NEXT
WORD_TAIL dostring
WORD_HDR dodoes, "(DODOES)", 8, 63, header_dostring
	movw	r2, #:lower16:cfa
	movt	r2, #:upper16:cfa
	ldr	r2, [r2]

        add     r0, r2, #8   @ put cfa + 2 cells on the stack (body ptr)
        push    {r0}

        ldr     r1, [r2, #4] @ and get the does field one cell later
        cmp     r1, #0
        beq     .L102
        @ When not equal to 0, jump into the DOES> code
        PUSHRSP r11, r4, r5
        mov     r11, r1
.L102:
	NEXT
WORD_TAIL dodoes
	.align	2
	.global	parse_
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	parse_, %function
parse_:
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r1, [r3, #4]
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	movw	r2, #:lower16:inputIndex
	movt	r2, #:upper16:inputIndex
	ldr	r2, [r2]
	ldr	r3, [r3, r2, lsl #4]
	cmp	r1, r3
	blt	.L104
        mov     r0, #0
        str     r0, [sp]
        push    {r0}
	b	.L110
.L104:
	pop     {r3}
	uxtb	r2, r3
	movw	r3, #:lower16:ch1
	movt	r3, #:upper16:ch1
	strb	r2, [r3]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r1, [r3, #12]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r3, [r3, #4]
	add	r2, r1, r3
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	str	r2, [r3]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	mov	r2, #0
	str	r2, [r3]
	b	.L106
.L108:
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r1, [r3]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r1, #4
	add	r3, r2, r3
	ldr	r0, [r3, #4]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r1, #4
	add	r3, r2, r3
	add	r2, r0, #1
	str	r2, [r3, #4]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	movw	r2, #:lower16:c1
	movt	r2, #:upper16:c1
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
.L106:
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r1, [r3, #4]
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	movw	r2, #:lower16:inputIndex
	movt	r2, #:upper16:inputIndex
	ldr	r2, [r2]
	ldr	r3, [r3, r2, lsl #4]
	cmp	r1, r3
	bge	.L107
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r1, [r3, #12]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r3, [r3, #4]
	ldrb	r2, [r1, r3]	@ zero_extendqisi2
	movw	r3, #:lower16:ch1
	movt	r3, #:upper16:ch1
	ldrb	r3, [r3]	@ zero_extendqisi2
	cmp	r2, r3
	bne	.L108
.L107:
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r1, [r3, #4]
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	movw	r2, #:lower16:inputIndex
	movt	r2, #:upper16:inputIndex
	ldr	r2, [r2]
	ldr	r3, [r3, r2, lsl #4]
	cmp	r1, r3
	bge	.L109
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r1, [r3]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r1, #4
	add	r3, r2, r3
	ldr	r0, [r3, #4]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r1, #4
	add	r3, r2, r3
	add	r2, r0, #1
	str	r2, [r3, #4]
.L109:
	movw	r2, #:lower16:str1
	movt	r2, #:upper16:str1
        ldr     r2, [r2]
        push    {r2}
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
        push    {r3}
.L110:
	nop
	bx	lr
	.size	parse_, .-parse_
	.align	2
	.global	parse_name_
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	parse_name_, %function
parse_name_:
	b	.L112
.L114:
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r1, [r3]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r1, #4
	add	r3, r2, r3
	ldr	r0, [r3, #4]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r1, #4
	add	r3, r2, r3
	add	r2, r0, #1
	str	r2, [r3, #4]
.L112:
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r1, [r3, #4]
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	movw	r2, #:lower16:inputIndex
	movt	r2, #:upper16:inputIndex
	ldr	r2, [r2]
	ldr	r3, [r3, r2, lsl #4]
	cmp	r1, r3
	bge	.L113
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r1, [r3, #12]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r3, [r3, #4]
	ldrb	r3, [r1, r3]	@ zero_extendqisi2
	cmp	r3, #32
	beq	.L114
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r1, [r3, #12]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r3, [r3, #4]
	ldrb	r3, [r1, r3]	@ zero_extendqisi2
	cmp	r3, #9
	beq	.L114
.L113:
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	mov	r2, #0
	str	r2, [r3]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r1, [r3, #12]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r3, [r3, #4]
	add	r2, r1, r3
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	str	r2, [r3]
	b	.L115
.L117:
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r1, [r3]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r1, #4
	add	r3, r2, r3
	ldr	r0, [r3, #4]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r1, #4
	add	r3, r2, r3
	add	r2, r0, #1
	str	r2, [r3, #4]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	movw	r2, #:lower16:c1
	movt	r2, #:upper16:c1
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
.L115:
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r1, [r3, #4]
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	movw	r2, #:lower16:inputIndex
	movt	r2, #:upper16:inputIndex
	ldr	r2, [r2]
	ldr	r3, [r3, r2, lsl #4]
	cmp	r1, r3
	bge	.L116
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r1, [r3, #12]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r3, [r3, #4]
	ldrb	r3, [r1, r3]	@ zero_extendqisi2
	cmp	r3, #32
	bne	.L117
.L116:
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r1, [r3, #4]
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	movw	r2, #:lower16:inputIndex
	movt	r2, #:upper16:inputIndex
	ldr	r2, [r2]
	ldr	r3, [r3, r2, lsl #4]
	cmp	r1, r3
	bge	.L118
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r1, [r3]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r1, #4
	add	r3, r2, r3
	ldr	r0, [r3, #4]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r1, #4
	add	r3, r2, r3
	add	r2, r0, #1
	str	r2, [r3, #4]
.L118:
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r3, [r3]
	movw	r2, #:lower16:c1
	movt	r2, #:upper16:c1
	ldr	r2, [r2]
        push    {r2, r3}
	nop
	bx	lr
	.size	parse_name_, .-parse_name_
	.align	2
	.global	to_number_int_
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	to_number_int_, %function
to_number_int_:
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	mov	r2, #0
	str	r2, [r3]
	b	.L120
.L121:
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r2, [r3]
	ldr	r3, [sp, #12]
	mov	r1, r3
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	lsl	r3, r3, #3
	lsr	r3, r1, r3
	uxtb	r1, r3
	movw	r3, #:lower16:numBuf
	movt	r3, #:upper16:numBuf
	strb	r1, [r3, r2]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	add	r2, r3, #4
	ldr	r3, [sp, #8]
	mov	r1, r3
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	lsl	r3, r3, #3
	lsr	r3, r1, r3
	uxtb	r1, r3
	movw	r3, #:lower16:numBuf
	movt	r3, #:upper16:numBuf
	strb	r1, [r3, r2]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	movw	r2, #:lower16:c1
	movt	r2, #:upper16:c1
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
.L120:
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	cmp	r3, #3
	ble	.L121
	b	.L122
.L130:
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r3, [r3]
	ldrb	r3, [r3]	@ zero_extendqisi2
	mov	r2, r3
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	str	r2, [r3]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	cmp	r3, #47
	ble	.L123
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	cmp	r3, #57
	bgt	.L123
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	movw	r2, #:lower16:c1
	movt	r2, #:upper16:c1
	ldr	r2, [r2]
	sub	r2, r2, #48
	str	r2, [r3]
	b	.L124
.L123:
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	cmp	r3, #64
	ble	.L125
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	cmp	r3, #90
	bgt	.L125
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	sub	r2, r3, #55
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	str	r2, [r3]
	b	.L124
.L125:
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	cmp	r3, #96
	ble	.L126
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	cmp	r3, #122
	bgt	.L126
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	sub	r2, r3, #87
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	str	r2, [r3]
.L124:
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r2, [r3]
	movw	r3, #:lower16:tempSize
	movt	r3, #:upper16:tempSize
	ldr	r3, [r3]
	cmp	r2, r3
	bge	.L133
	movw	r3, #:lower16:c3
	movt	r3, #:upper16:c3
	mov	r2, #0
	str	r2, [r3]
	b	.L128
.L129:
	movw	r3, #:lower16:numBuf
	movt	r3, #:upper16:numBuf
	movw	r2, #:lower16:c3
	movt	r2, #:upper16:c3
	ldr	r2, [r2]
	add	r3, r3, r2
	ldrb	r3, [r3]	@ zero_extendqisi2
	mov	r2, r3
	movw	r3, #:lower16:tempSize
	movt	r3, #:upper16:tempSize
	ldr	r3, [r3]
	mul	r2, r3, r2
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	add	r2, r2, r3
	movw	r3, #:lower16:c2
	movt	r3, #:upper16:c2
	str	r2, [r3]
	movw	r3, #:lower16:c3
	movt	r3, #:upper16:c3
	ldr	r2, [r3]
	movw	r3, #:lower16:c2
	movt	r3, #:upper16:c2
	ldr	r3, [r3]
	uxtb	r1, r3
	movw	r3, #:lower16:numBuf
	movt	r3, #:upper16:numBuf
	strb	r1, [r3, r2]
	movw	r3, #:lower16:c2
	movt	r3, #:upper16:c2
	ldr	r3, [r3]
	asr	r3, r3, #8
	uxtb	r2, r3
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	str	r2, [r3]
	movw	r3, #:lower16:c3
	movt	r3, #:upper16:c3
	movw	r2, #:lower16:c3
	movt	r2, #:upper16:c3
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
.L128:
	movw	r3, #:lower16:c3
	movt	r3, #:upper16:c3
	ldr	r3, [r3]
	cmp	r3, #7
	ble	.L129
	ldr     r3, [sp]
        sub     r3, r3, #1
        str     r3, [sp]
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	movw	r2, #:lower16:str1
	movt	r2, #:upper16:str1
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
.L122:
        ldr     r3, [sp]
	cmp	r3, #0
	bgt	.L130
	b	.L126
.L133:
	nop
.L126:
        mov     r2, #0
        str     r2, [sp, #8]
        str     r2, [sp, #12]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	str	r2, [r3]
	b	.L131
.L132:
	movw	r3, #:lower16:numBuf
	movt	r3, #:upper16:numBuf
	movw	r2, #:lower16:c1
	movt	r2, #:upper16:c1
	ldr	r2, [r2]
	add	r3, r3, r2
	ldrb	r3, [r3]	@ zero_extendqisi2
	mov	r2, r3
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	lsl	r3, r3, #3
	lsl	r3, r2, r3
        ldr     r1, [sp, #12]
        orr     r1, r1, r3
        str     r1, [sp, #12]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	add	r2, r3, #4
	movw	r3, #:lower16:numBuf
	movt	r3, #:upper16:numBuf
	ldrb	r3, [r3, r2]	@ zero_extendqisi2
	mov	r2, r3
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	lsl	r3, r3, #3
	lsl	r3, r2, r3
        ldr     r1, [sp, #8]
        orr     r1, r1, r3
        str     r1, [sp, #8]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	movw	r2, #:lower16:c1
	movt	r2, #:upper16:c1
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
.L131:
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	cmp	r3, #3
	ble	.L132
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r3, [r3]
	str	r3, [sp, #4]
	nop
	bx	lr
	.size	to_number_int_, .-to_number_int_
	.align	2
	.global	to_number_
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	to_number_, %function
to_number_:
	movw	r3, #:lower16:tempSize
	movt	r3, #:upper16:tempSize
	movw	r2, #:lower16:base
	movt	r2, #:upper16:base
	ldr	r2, [r2]
	str	r2, [r3]
	ldr     r2, [sp, #4]
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	str	r2, [r3]
        @ Save the link register in RSP, not on sp
        PUSHRSP lr, r1, r2
	bl	to_number_int_
        POPRSP  r0, r1, r2
        mov     pc, r0
	.size	to_number_, .-to_number_
	.align	2
	.global	parse_number_
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	parse_number_, %function
parse_number_:
	ldr     r3, [sp, #4]
	mov	r2, r3
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	str	r2, [r3]
	movw	r3, #:lower16:tempSize
	movt	r3, #:upper16:tempSize
	movw	r2, #:lower16:base
	movt	r2, #:upper16:base
	ldr	r2, [r2]
	str	r2, [r3]
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r3, [r3]
	ldrb	r3, [r3]	@ zero_extendqisi2
	cmp	r3, #36
	beq	.L137
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r3, [r3]
	ldrb	r3, [r3]	@ zero_extendqisi2
	cmp	r3, #35
	beq	.L137
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r3, [r3]
	ldrb	r3, [r3]	@ zero_extendqisi2
	cmp	r3, #37
	bne	.L138
.L137:
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r3, [r3]
	ldrb	r3, [r3]	@ zero_extendqisi2
	cmp	r3, #36
	beq	.L139
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r3, [r3]
	ldrb	r3, [r3]	@ zero_extendqisi2
	cmp	r3, #35
	bne	.L140
	mov	r2, #10
	b	.L142
.L140:
	mov	r2, #2
	b	.L142
.L139:
	mov	r2, #16
.L142:
	movw	r3, #:lower16:tempSize
	movt	r3, #:upper16:tempSize
	str	r2, [r3]
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	movw	r2, #:lower16:str1
	movt	r2, #:upper16:str1
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]

        ldr     r2, [sp]
        sub     r2, r2, #1
        str     r2, [sp]
	b	.L143
.L138:
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r3, [r3]
	ldrb	r3, [r3]	@ zero_extendqisi2
	cmp	r3, #39
	bne	.L143
        ldr     r2, [sp]
        sub     r2, r2, #3
        str     r2, [sp]
        ldr     r2, [sp, #4]
        add     r2, r2, #3
        str     r2, [sp, #4]
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r3, [r3]
	add	r3, r3, #1
	ldrb	r3, [r3]	@ zero_extendqisi2
	str	r3, [sp, #12]
	b	.L147
.L143:
	movw	r3, #:lower16:ch1
	movt	r3, #:upper16:ch1
	mov	r2, #0
	strb	r2, [r3]
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r3, [r3]
	ldrb	r3, [r3]	@ zero_extendqisi2
	cmp	r3, #45
	bne	.L145
        ldr     r2, [sp]
        sub     r2, r2, #1
        str     r2, [sp]
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	movw	r2, #:lower16:str1
	movt	r2, #:upper16:str1
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
	movw	r3, #:lower16:ch1
	movt	r3, #:upper16:ch1
	mov	r2, #1
	strb	r2, [r3]
.L145:
        PUSHRSP lr, r2, r3
	bl	to_number_int_
        POPRSP  lr, r2, r3
	movw	r3, #:lower16:ch1
	movt	r3, #:upper16:ch1
	ldrb	r3, [r3]	@ zero_extendqisi2
	cmp	r3, #0
	beq	.L147
        ldr     r2, [sp, #8]
        ldr     r3, [sp, #12]
        mvn     r2, r2
        mvn     r3, r3
        add     r3, r3, #1
	cmp	r3, #0
	bne	.L136
        add     r2, r2, #1
.L136:
        str     r2, [sp, #8]
        str     r3, [sp, #12]
.L147:
	bx	lr
	.size	parse_number_, .-parse_number_
	.align	2
	.global	find_
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	find_, %function
find_:
	PUSHRSP lr, r1, r2
	movw	r6, #:lower16:searchIndex
	movt	r6, #:upper16:searchIndex
	ldr	r6, [r6]
.LF159:
	movw	r3, #:lower16:searchArray
	movt	r3, #:upper16:searchArray
        lsl     r2, r6, #2
        add     r3, r3, r2
	ldr	r2, [r3]
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	str	r2, [r3]
	b	.LF151
.LF156:
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r3, [r3]
	ldr	r3, [r3, #4]
	ubfx	r2, r3, #0, #9
	ldr	r3, [sp]
	cmp	r2, r3
	bne	.LF152
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r3, [r3]
	ldr	r0, [r3, #8]
	ldr	r1, [sp, #4]
	ldr	r2, [sp]
	bl	strncasecmp
	mov	r3, r0
	cmp	r3, #0
	bne	.LF152
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r3, [r3]
	add	r3, r3, #12
	str	r3, [sp, #4]
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r3, [r3]
	ldr	r3, [r3, #4]
	and	r3, r3, #512
	cmp	r3, #0
	bne	.LF153
	mvn	r3, #0
	b	.LF154
.LF153:
        mov     r3, #1
.LF154:
        str     r3, [sp]
        b       .LF149
.LF152:
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r2, [r3]
	ldr	r2, [r2]
	str	r2, [r3]
.LF151:
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r3, [r3]
	cmp	r3, #0
	bne	.LF156
.LF150:
        cmp     r6, #0
	beq	.LF158
        sub     r6, r6, #1
	b	.LF159
.LF160:
	nop
.LF158:
        mov     r2, #0
        str     r2, [sp, #4]
        str     r2, [sp]
.LF149:
        POPRSP  lr, r2, r3
        bx lr
	.size	find_, .-find_
WORD_HDR parse, "PARSE", 5, 64, header_dodoes
	bl	parse_
	NEXT
WORD_TAIL parse
WORD_HDR parse_name, "PARSE-NAME", 10, 65, header_parse
	bl	parse_name_
	NEXT
WORD_TAIL parse_name
WORD_HDR to_number, ">NUMBER", 7, 66, header_parse_name
	bl	to_number_
	NEXT
WORD_TAIL to_number
WORD_HDR create, "CREATE", 6, 67, header_to_number
	bl	parse_name_
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	ldr	r3, [r3]
	add	r3, r3, #3
	bic	r3, r3, #3
	mov	r2, r3
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	str	r2, [r3]
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	ldr	r2, [r3]
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	str	r2, [r3]
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	movw	r2, #:lower16:dsp
	movt	r2, #:upper16:dsp
	ldr	r2, [r2]
	add	r2, r2, #16
	str	r2, [r3]
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r2, [r3]
	movw	r3, #:lower16:compilationWordlist
	movt	r3, #:upper16:compilationWordlist
	ldr	r3, [r3]
	ldr	r3, [r3]
	str	r3, [r2]
	movw	r3, #:lower16:compilationWordlist
	movt	r3, #:upper16:compilationWordlist
        ldr     r2, [r3]
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r3, [r3]
	str	r3, [r2]
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r2, [r3]
	ldr     r3, [sp]
	str	r3, [r2, #4]
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r4, [r3]
	ldr     r0, [sp]
	CALL	malloc
	mov	r3, r0
	str	r0, [r4, #8]
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r0, [r3]
	ldr     r1, [sp, #4]
	ldr     r2, [sp]
	ldr	r0, [r0, #8]
	CALL	strncpy
        add     sp, sp, #8
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r2, [r3]
	movw	r3, #:lower16:code_dodoes
	movt	r3, #:upper16:code_dodoes
	str	r3, [r2, #12]
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	ldr	r2, [r3]
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	add	r1, r2, #4
	str	r1, [r3]
	mov	r3, #0
	str	r3, [r2]
	NEXT
WORD_TAIL create
WORD_HDR find, "(FIND)", 6, 68, header_create
	bl	find_
	NEXT
WORD_TAIL find
WORD_HDR depth, "DEPTH", 5, 69, header_find
	movw	r2, #:lower16:spTop
	movt	r2, #:upper16:spTop
	ldr	r2, [r2]
	sub	r2, r2, sp
	lsr	r2, r2, #2
	push    {r2}
        NEXT
WORD_TAIL depth
WORD_HDR sp_fetch, "SP@", 3, 70, header_depth
	mov     r0, sp
        push    {r0}
        NEXT
WORD_TAIL sp_fetch
WORD_HDR sp_store, "SP!", 3, 71, header_sp_fetch
	pop     {r0}
        mov     sp, r0
        NEXT
WORD_TAIL sp_store
WORD_HDR rp_fetch, "RP@", 3, 72, header_sp_store
	movw	r3, #:lower16:rsp
	movt	r3, #:upper16:rsp
	ldr	r3, [r3]
        push    {r3}
	NEXT
WORD_TAIL rp_fetch
WORD_HDR rp_store, "RP!", 3, 73, header_rp_fetch
	movw	r3, #:lower16:rsp
	movt	r3, #:upper16:rsp
        pop     {r2}
	str	r2, [r3]
	NEXT
WORD_TAIL rp_store
	.section	.rodata
	.align	2
.LC76:
	.ascii	"[%d] \000"
	.text
	.align	2
	.global	dot_s_
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	dot_s_, %function
dot_s_:
	PUSHRSP lr, r1, r2
	movw	r2, #:lower16:spTop
	movt	r2, #:upper16:spTop
	ldr	r2, [r2]
	mov     r3, sp
	sub	r3, r2, r3
	lsr	r3, r3, #2
	mov	r1, r3
	movw	r0, #:lower16:.LC76
	movt	r0, #:upper16:.LC76
	CALL	printf
	movw	r3, #:lower16:spTop
	movt	r3, #:upper16:spTop
	ldr	r3, [r3]
	sub	r3, r3, #4
	mov	r2, r3
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	str	r2, [r3]
	b	.L173
.L174:
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	ldr	r1, [r3]
	movw	r0, #:lower16:.LC36
	movt	r0, #:upper16:.LC36
	CALL	printf
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	movw	r2, #:lower16:c1
	movt	r2, #:upper16:c1
	ldr	r2, [r2]
	sub	r2, r2, #4
	str	r2, [r3]
.L173:
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r2, [r3]
	cmp	r2, sp
	bge	.L174
	mov	r0, #10
	CALL	putchar
	nop
	POPRSP  lr, r1, r2
        bx      lr
	.size	dot_s_, .-dot_s_
WORD_HDR dot_s, ".S", 2, 74, header_rp_store
	bl	dot_s_
	NEXT
WORD_TAIL dot_s
	.section	.rodata
	.align	2
.LC78:
	.ascii	"%x \000"
	.text
	.align	2
	.global	u_dot_s_
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	u_dot_s_, %function
u_dot_s_:
        PUSHRSP lr, r1, r2
	movw	r2, #:lower16:spTop
	movt	r2, #:upper16:spTop
	ldr	r2, [r2]
	mov     r3, sp
	sub	r3, r2, r3
	lsr	r3, r3, #2
	mov	r1, r3
	movw	r0, #:lower16:.LC76
	movt	r0, #:upper16:.LC76
	CALL	printf
	movw	r3, #:lower16:spTop
	movt	r3, #:upper16:spTop
	ldr	r3, [r3]
	sub	r3, r3, #4
	mov	r2, r3
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	str	r2, [r3]
	b	.L179
.L180:
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	ldr	r1, [r3]
	movw	r0, #:lower16:.LC78
	movt	r0, #:upper16:.LC78
	CALL	printf
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	movw	r2, #:lower16:c1
	movt	r2, #:upper16:c1
	ldr	r2, [r2]
	sub	r2, r2, #4
	str	r2, [r3]
.L179:
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r2, [r3]
	cmp	r2, sp
	bge	.L180
	mov	r0, #10
	CALL	putchar
	nop
	POPRSP  lr, r1, r2
        bx      lr
	.size	u_dot_s_, .-u_dot_s_
WORD_HDR u_dot_s, "U.S", 3, 75, header_dot_s
	bl	u_dot_s_
	NEXT
WORD_TAIL u_dot_s

       .section        .rodata
       .align  2
.LC81:
       .ascii  "wb\000"
       .align  2
.LC82:
       .ascii  "*** Failed to open file for writing: %s\012\000"
       .align  2
.LC83:
       .ascii  "(Dumped %d of %d bytes to %s)\012\000"
       .text
       .align  2

WORD_HDR dump_file, "(DUMP-FILE)", 11, 76, header_u_dot_s
	ldr     r1, [sp, #4]
	ldr	r2, [sp]
	movw	r0, #:lower16:tempBuf
	movt	r0, #:upper16:tempBuf
	CALL	strncpy
	ldr	r2, [sp]
	movw	r3, #:lower16:tempBuf
	movt	r3, #:upper16:tempBuf
	mov	r1, #0
	strb	r1, [r3, r2]
	movw	r1, #:lower16:.LC81
	movt	r1, #:upper16:.LC81
	movw	r0, #:lower16:tempBuf
	movt	r0, #:upper16:tempBuf
	CALL	fopen
	mov	r2, r0
	movw	r3, #:lower16:tempFile
	movt	r3, #:upper16:tempFile
	str	r0, [r3]
	movw	r3, #:lower16:tempFile
	movt	r3, #:upper16:tempFile
	ldr	r3, [r3]
	cmp	r3, #0
	bne	.L185
	movw	r3, #:lower16:stderr
	movt	r3, #:upper16:stderr
	movw	r2, #:lower16:tempBuf
	movt	r2, #:upper16:tempBuf
	movw	r1, #:lower16:.LC82
	movt	r1, #:upper16:.LC82
	ldr	r0, [r3]
	CALL	fprintf
	b	.L186
.L185:
	ldr     r0, [sp, #12]
	ldr     r2, [sp, #8]
	movw	r3, #:lower16:tempFile
	movt	r3, #:upper16:tempFile
	ldr	r3, [r3]
	mov	r1, #1
	CALL	fwrite
	mov	r3, r0
	mov	r2, r3
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	str	r2, [r3]
	ldr     r2, [sp, #8]
	movw	r1, #:lower16:c1
	movt	r1, #:upper16:c1
	movw	r3, #:lower16:tempBuf
	movt	r3, #:upper16:tempBuf
	ldr	r1, [r1]
	movw	r0, #:lower16:.LC83
	movt	r0, #:upper16:.LC83
	CALL	printf
	movw	r3, #:lower16:tempFile
	movt	r3, #:upper16:tempFile
	ldr	r0, [r3]
	CALL	fclose
	movw	r3, #:lower16:tempFile
	movt	r3, #:upper16:tempFile
	mov	r2, #0
	str	r2, [r3]
.L186:
	NEXT
WORD_TAIL dump_file
	.global	key_call_
	.data
	.align	2
	.type	key_call_, %object
	.size	key_call_, 4
key_call_:
	.word	100
	.text
	.align	2
	.global	code_call_
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_call_, %function
code_call_:
	ldr     r1, [r11], #4
        PUSHRSP r11, r2, r3
	movw	r3, #:lower16:ca
	movt	r3, #:upper16:ca
	str	r1, [r3]
        mov     r11, r1
	NEXT
	.size	code_call_, .-code_call_
	.align	2
	.global	lookup_primitive
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	lookup_primitive, %function
lookup_primitive:
        @ let r3 hold my target, r2 the base of primitives[], r1 the index
        movw    r3, #:lower16:c1
        movt    r3, #:upper16:c1
        ldr     r3, [r3]
        movw    r2, #:lower16:primitives
        movt    r2, #:upper16:primitives
        mov     r1, #0
	b	.L190
.L193:
        ldr     r0, [r2, r1, lsl #3]
        cmp     r0, r3
	bne	.L191
	lsl	r1, r1, #3
	add	r1, r2, r1
	ldr	r2, [r1, #4]
	movw	r3, #:lower16:key1
	movt	r3, #:upper16:key1
	str	r2, [r3]
	b	.L194
.L191:
	add	r1, r1, #1
.L190:

	movw	r0, #:lower16:primitive_count
	movt	r0, #:upper16:primitive_count
	ldr	r0, [r0]
	cmp	r1, r0
	blt	.L193
	movw    r3, #:lower16:c1
	movt    r3, #:upper16:c1
        ldr     r2, [r3]
	movw	r0, #:lower16:stderr
	movt	r0, #:upper16:stderr
	ldr	r0, [r0]
	movw	r1, #:lower16:.BSS_ERR_INVALID_KEY
	movt	r1, #:upper16:.BSS_ERR_INVALID_KEY
	CALL	fprintf
	mov	r0, #40
	CALL	exit
.L194:
	bx	lr
	.size	lookup_primitive, .-lookup_primitive
	.align	2
	.global	drain_queue_
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	drain_queue_, %function
drain_queue_:
	movw	r3, #:lower16:key1
	movt	r3, #:upper16:key1
	mov	r2, #0
	str	r2, [r3]
	movw	r3, #:lower16:tempQueue
	movt	r3, #:upper16:tempQueue
	movw	r2, #:lower16:queue
	movt	r2, #:upper16:queue
	ldr	r2, [r2]
	str	r2, [r3]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	mov	r2, #0
	str	r2, [r3]
	b	.L199
.L200:
	movw	r3, #:lower16:tempQueue
	movt	r3, #:upper16:tempQueue
	ldr	r3, [r3]
	ldr	r2, [r3, #12]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	lsl	r3, r3, #3
	lsl	r1, r2, r3
	movw	r3, #:lower16:key1
	movt	r3, #:upper16:key1
	movw	r2, #:lower16:key1
	movt	r2, #:upper16:key1
	ldr	r2, [r2]
	orr	r2, r1, r2
	str	r2, [r3]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	movw	r2, #:lower16:c1
	movt	r2, #:upper16:c1
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
	movw	r3, #:lower16:tempQueue
	movt	r3, #:upper16:tempQueue
	ldr	r3, [r3]
	ldr	r2, [r3, #16]
	movw	r3, #:lower16:tempQueue
	movt	r3, #:upper16:tempQueue
	str	r2, [r3]
.L199:
	movw	r3, #:lower16:tempQueue
	movt	r3, #:upper16:tempQueue
	ldr	r3, [r3]
	cmp	r3, #0
	bne	.L200
	b	.L201
.L210:
	movw	r3, #:lower16:c2
	movt	r3, #:upper16:c2
	mov	r2, #0
	str	r2, [r3]
	b	.L202
.L209:
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	movw	r3, #:lower16:c2
	movt	r3, #:upper16:c2
	ldr	r3, [r3]
	lsl	r3, r3, #3
	add	r3, r2, r3
	ldr	r2, [r3, #4]
	movw	r3, #:lower16:key1
	movt	r3, #:upper16:key1
	ldr	r3, [r3]
	cmp	r2, r3
	bne	.L203
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	ldr	r1, [r3]
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	add	r2, r1, #4
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:c2
	movt	r2, #:upper16:c2
	ldr	r2, [r2]
	ldr	r3, [r3, r2, lsl #3]
	str	r3, [r1]
	b	.L204
.L206:
	movw	r3, #:lower16:queue
	movt	r3, #:upper16:queue
	ldr	r3, [r3]
	ldrb	r3, [r3, #4]	@ zero_extendqisi2
	cmp	r3, #0
	beq	.L205
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	ldr	r2, [r3]
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	add	r1, r2, #4
	str	r1, [r3]
	movw	r3, #:lower16:queue
	movt	r3, #:upper16:queue
	ldr	r3, [r3]
	ldr	r3, [r3, #8]
	str	r3, [r2]
.L205:
	movw	r3, #:lower16:queue
	movt	r3, #:upper16:queue
	ldr	r3, [r3]
	ldr	r2, [r3, #16]
	movw	r3, #:lower16:queue
	movt	r3, #:upper16:queue
	str	r2, [r3]
	movw	r3, #:lower16:queue_length
	movt	r3, #:upper16:queue_length
	movw	r2, #:lower16:queue_length
	movt	r2, #:upper16:queue_length
	ldr	r2, [r2]
	sub	r2, r2, #1
	str	r2, [r3]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	movw	r2, #:lower16:c1
	movt	r2, #:upper16:c1
	ldr	r2, [r2]
	sub	r2, r2, #1
	str	r2, [r3]
.L204:
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	cmp	r3, #0
	bgt	.L206
	movw	r3, #:lower16:queue
	movt	r3, #:upper16:queue
	ldr	r3, [r3]
	cmp	r3, #0
	bne	.L213
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	mov	r2, #0
	str	r2, [r3]
	b	.L213
.L203:
	movw	r3, #:lower16:c2
	movt	r3, #:upper16:c2
	movw	r2, #:lower16:c2
	movt	r2, #:upper16:c2
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
.L202:
	movw	r3, #:lower16:c2
	movt	r3, #:upper16:c2
	ldr	r2, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r3, [r3]
	cmp	r2, r3
	blt	.L209
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	movw	r2, #:lower16:c1
	movt	r2, #:upper16:c1
	ldr	r2, [r2]
	sub	r2, r2, #1
	str	r2, [r3]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	rsb	r3, r3, #4
	lsl	r3, r3, #3
	mvn	r2, #0
	lsr	r1, r2, r3
	movw	r3, #:lower16:key1
	movt	r3, #:upper16:key1
	movw	r2, #:lower16:key1
	movt	r2, #:upper16:key1
	ldr	r2, [r2]
	and	r2, r2, r1
	str	r2, [r3]
.L201:
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	cmp	r3, #1
	bgt	.L210
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	ldr	r2, [r3]
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	add	r1, r2, #4
	str	r1, [r3]
	movw	r3, #:lower16:queue
	movt	r3, #:upper16:queue
	ldr	r3, [r3]
	ldr	r3, [r3]
	str	r3, [r2]
	movw	r3, #:lower16:queue
	movt	r3, #:upper16:queue
	ldr	r3, [r3]
	ldrb	r3, [r3, #4]	@ zero_extendqisi2
	cmp	r3, #0
	beq	.L211
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	ldr	r2, [r3]
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	add	r1, r2, #4
	str	r1, [r3]
	movw	r3, #:lower16:queue
	movt	r3, #:upper16:queue
	ldr	r3, [r3]
	ldr	r3, [r3, #8]
	str	r3, [r2]
.L211:
	movw	r3, #:lower16:queue
	movt	r3, #:upper16:queue
	ldr	r3, [r3]
	ldr	r2, [r3, #16]
	movw	r3, #:lower16:queue
	movt	r3, #:upper16:queue
	str	r2, [r3]
	movw	r3, #:lower16:queue
	movt	r3, #:upper16:queue
	ldr	r3, [r3]
	cmp	r3, #0
	bne	.L212
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	mov	r2, #0
	str	r2, [r3]
.L212:
	movw	r3, #:lower16:queue_length
	movt	r3, #:upper16:queue_length
	movw	r2, #:lower16:queue_length
	movt	r2, #:upper16:queue_length
	ldr	r2, [r2]
	sub	r2, r2, #1
	str	r2, [r3]
	b	.L198
.L213:
	nop
.L198:
	bx	lr
	.size	drain_queue_, .-drain_queue_
	.align	2
	.global	bump_queue_tail_
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	bump_queue_tail_, %function
bump_queue_tail_:
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r3, [r3]
	cmp	r3, #0
	bne	.L215
	movw	r3, #:lower16:next_queue_source
	movt	r3, #:upper16:next_queue_source
	ldr	r2, [r3]
	movw	r3, #:lower16:next_queue_source
	movt	r3, #:upper16:next_queue_source
	add	r1, r2, #1
	str	r1, [r3]
	mov	r3, #20
	mul	r2, r3, r2
	movw	r3, #:lower16:queueSource
	movt	r3, #:upper16:queueSource
	add	r2, r2, r3
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	str	r2, [r3]
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r2, [r3]
	movw	r3, #:lower16:queue
	movt	r3, #:upper16:queue
	str	r2, [r3]
	b	.L216
.L215:
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r1, [r3]
	movw	r3, #:lower16:next_queue_source
	movt	r3, #:upper16:next_queue_source
	ldr	r2, [r3]
	movw	r3, #:lower16:next_queue_source
	movt	r3, #:upper16:next_queue_source
	add	r0, r2, #1
	str	r0, [r3]
	mov	r3, #20
	mul	r2, r3, r2
	movw	r3, #:lower16:queueSource
	movt	r3, #:upper16:queueSource
	add	r3, r2, r3
	str	r3, [r1, #16]
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r3, [r3]
	ldr	r2, [r3, #16]
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	str	r2, [r3]
.L216:
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r3, [r3]
	mov	r2, #0
	str	r2, [r3, #16]
	movw	r3, #:lower16:next_queue_source
	movt	r3, #:upper16:next_queue_source
	movw	r2, #:lower16:next_queue_source
	movt	r2, #:upper16:next_queue_source
	ldr	r2, [r2]
	and	r2, r2, #3
	str	r2, [r3]
	movw	r3, #:lower16:queue_length
	movt	r3, #:upper16:queue_length
	movw	r2, #:lower16:queue_length
	movt	r2, #:upper16:queue_length
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
	nop
	bx	lr
	.size	bump_queue_tail_, .-bump_queue_tail_
	.align	2
	.global	compile_
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	compile_, %function
compile_:
        PUSHRSP lr, r1, r2
	movw	r3, #:lower16:queue_length
	movt	r3, #:upper16:queue_length
	ldr	r3, [r3]
	cmp	r3, #3
	ble	.L218
	bl	drain_queue_
.L218:
	bl	bump_queue_tail_
	ldr	r3, [sp]
	ldr	r2, [r3]
	movw	r3, #:lower16:code_docol
	movt	r3, #:upper16:code_docol
	cmp	r2, r3
	bne	.L219
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r2, [r3]
	movw	r3, #:lower16:code_call_
	movt	r3, #:upper16:code_call_
	str	r3, [r2]
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r3, [r3]
	mov	r2, #1
	strb	r2, [r3, #4]
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r1, [r3]
	ldr     r3, [sp], #4
	add	r3, r3, #4
	str	r3, [r1, #8]
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r2, [r3]
	movw	r3, #:lower16:key_call_
	movt	r3, #:upper16:key_call_
	ldr	r3, [r3]
	str	r3, [r2, #12]
	b	.L224
.L219:
	ldr     r3, [sp]
	ldr	r2, [r3]
	movw	r3, #:lower16:code_dodoes
	movt	r3, #:upper16:code_dodoes
	cmp	r2, r3
	bne	.L221
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r2, [r3]
	movw	r3, #:lower16:code_dolit
	movt	r3, #:upper16:code_dolit
	str	r3, [r2]
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r3, [r3]
	mov	r2, #1
	strb	r2, [r3, #4]
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r2, [r3]
	ldr	r3, [sp]
	add	r3, r3, #8
	str	r3, [r2, #8]
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r2, [r3]
	movw	r3, #:lower16:key_dolit
	movt	r3, #:upper16:key_dolit
	ldr	r3, [r3]
	str	r3, [r2, #12]
	ldr     r3, [sp]
	add	r3, r3, #4
	ldr	r3, [r3]
	cmp	r3, #0
	beq	.L222
	movw	r3, #:lower16:queue_length
	movt	r3, #:upper16:queue_length
	ldr	r3, [r3]
	cmp	r3, #4
	bne	.L223
	bl	drain_queue_
.L223:
	bl	bump_queue_tail_
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r2, [r3]
	movw	r3, #:lower16:code_call_
	movt	r3, #:upper16:code_call_
	str	r3, [r2]
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r3, [r3]
	mov	r2, #1
	strb	r2, [r3, #4]
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r2, [r3]
	ldr     r3, [sp]
	add	r3, r3, #4
	ldr	r3, [r3]
	str	r3, [r2, #8]
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r2, [r3]
	movw	r3, #:lower16:key_call_
	movt	r3, #:upper16:key_call_
	ldr	r3, [r3]
	str	r3, [r2, #12]
.L222:
	add     sp, sp, #4
	b	.L224
.L221:
        pop     {r2}
        ldr     r2, [r2]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	str	r2, [r3]
	bl	lookup_primitive
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r2, [r3]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	str	r3, [r2]
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r3, [r3]
	mov	r2, #0
	strb	r2, [r3, #4]
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r2, [r3]
	movw	r3, #:lower16:key1
	movt	r3, #:upper16:key1
	ldr	r3, [r3]
	str	r3, [r2, #12]
.L224:
        POPRSP  lr, r1, r2
	nop
	bx      lr
	.size	compile_, .-compile_
	.align	2
	.global	compile_lit_
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	compile_lit_, %function
compile_lit_:
        PUSHRSP lr, r1, r2
	movw	r3, #:lower16:queue_length
	movt	r3, #:upper16:queue_length
	ldr	r3, [r3]
	cmp	r3, #3
	ble	.L227
	bl	drain_queue_
.L227:
	bl	bump_queue_tail_
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r2, [r3]
	movw	r3, #:lower16:code_dolit
	movt	r3, #:upper16:code_dolit
	str	r3, [r2]
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r3, [r3]
	mov	r2, #1
	strb	r2, [r3, #4]
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r1, [r3]
	pop     {r3}
	str	r3, [r1, #8]
	movw	r3, #:lower16:queueTail
	movt	r3, #:upper16:queueTail
	ldr	r2, [r3]
	movw	r3, #:lower16:key_dolit
	movt	r3, #:upper16:key_dolit
	ldr	r3, [r3]
	str	r3, [r2, #12]
        POPRSP  lr, r1, r2
	nop
	bx      lr
	.size	compile_lit_, .-compile_lit_
	.comm	savedString,4,4
	.comm	savedLength,4,4
	.section	.rodata
	.align	2
.LC85:
	.ascii	"  ok\000"
	.align	2
.LC86:
	.ascii	"*** Unrecognized word: %s\012\000"
	.align	2
.BSS_ERR_INVALID_KEY:
	.ascii	"*** Invalid key: %d\012\000"
	.text
	.align	2
	.global	quit_
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	quit_, %function
quit_:
.L230:
	movw	r2, #:lower16:spTop
	movt	r2, #:upper16:spTop
	ldr	sp, [r2]
	movw	r3, #:lower16:rsp
	movt	r3, #:upper16:rsp
	movw	r2, #:lower16:rspTop
	movt	r2, #:upper16:rspTop
	ldr	r2, [r2]
	str	r2, [r3]
	movw	r3, #:lower16:state
	movt	r3, #:upper16:state
	mov	r2, #0
	str	r2, [r3]
	movw	r3, #:lower16:firstQuit
	movt	r3, #:upper16:firstQuit
	ldrb	r3, [r3]	@ zero_extendqisi2
	cmp	r3, #0
	bne	.L231
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	mov	r2, #0
	str	r2, [r3]
.L231:
	movw	r3, #:lower16:quit_inner
	movt	r3, #:upper16:quit_inner
	ldr	r2, .L247
	str	r2, [r3]
	bl	refill_
.L232:
	bl	parse_name_
	ldr	r3, [sp]
	cmp	r3, #0
	bne	.L245
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r3, [r3, #8]
	cmp	r3, #0
	bne	.L235
	movw	r0, #:lower16:.LC85
	movt	r0, #:upper16:.LC85
	CALL	puts
.L235:
	add	sp, sp, #8
	bl	refill_
	b	.L232
.L245:
	nop
	ldr	r3, [sp, #4]
	mov	r2, r3
	movw	r3, #:lower16:savedString
	movt	r3, #:upper16:savedString
	str	r2, [r3]
	ldr	r2, [sp]
	movw	r3, #:lower16:savedLength
	movt	r3, #:upper16:savedLength
	str	r2, [r3]
	bl	find_
	ldr	r3, [sp]
	cmp	r3, #0
	bne	.L236
	sub	sp, sp, #8
	movw	r3, #:lower16:savedLength
	movt	r3, #:upper16:savedLength
	ldr	r3, [r3]
	str	r3, [sp]
	movw	r3, #:lower16:savedString
	movt	r3, #:upper16:savedString
	ldr	r3, [r3]
	str	r3, [sp, #4]
	bl	parse_number_
	ldr	r3, [sp]
	cmp	r3, #0
	bne	.L237
	movw	r3, #:lower16:state
	movt	r3, #:upper16:state
	ldr	r3, [r3]
	cmp	r3, #1
	bne	.L238
	add	sp, sp, #12
	bl	compile_lit_
	b	.L232
.L238:
	add	sp, sp, #12
	b	.L232
.L237:
	movw	r2, #:lower16:savedLength
	movt	r2, #:upper16:savedLength
	movw	r3, #:lower16:savedString
	movt	r3, #:upper16:savedString
	ldr	r2, [r2]
	ldr	r1, [r3]
	movw	r0, #:lower16:tempBuf
	movt	r0, #:upper16:tempBuf
	CALL	strncpy
	movw	r3, #:lower16:savedLength
	movt	r3, #:upper16:savedLength
	ldr	r2, [r3]
	movw	r3, #:lower16:tempBuf
	movt	r3, #:upper16:tempBuf
	mov	r1, #0
	strb	r1, [r3, r2]
	movw	r3, #:lower16:stderr
	movt	r3, #:upper16:stderr
	movw	r2, #:lower16:tempBuf
	movt	r2, #:upper16:tempBuf
	movw	r1, #:lower16:.LC86
	movt	r1, #:upper16:.LC86
	ldr	r0, [r3]
	CALL	fprintf
	b	.L230
.L236:
	ldr	r3, [sp]
	cmp	r3, #1
	beq	.L241
	movw	r3, #:lower16:state
	movt	r3, #:upper16:state
	ldr	r3, [r3]
	cmp	r3, #0
	bne	.L242
.L241:
	ldr	r2, .L247
	movw	r3, #:lower16:quitTop
	movt	r3, #:upper16:quitTop
	str	r2, [r3]
	movw	r2, #:lower16:quitTop
	movt	r2, #:upper16:quitTop
        mov     r11, r2
	ldr	r3, [sp, #4]
	mov	r2, r3
	movw	r3, #:lower16:cfa
	movt	r3, #:upper16:cfa
	str	r2, [r3]
	add     sp, sp, #8
	movw	r3, #:lower16:cfa
	movt	r3, #:upper16:cfa
	ldr	r3, [r3]
	ldr	r3, [r3]
	bx r3
.L242:
	add	sp, sp, #4
	bl	compile_
	b	.L232
.L248:
	.align	2
.L247:
	.word	.L232
	.size	quit_, .-quit_
WORD_HDR quit, "QUIT", 4, 77, header_dump_file
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	mov	r2, #0
	str	r2, [r3]
	bl	quit_
	NEXT
WORD_TAIL quit
WORD_HDR bye, "BYE", 3, 78, header_quit
	mov	r0, #0
	CALL	exit
WORD_TAIL bye
WORD_HDR compile_comma, "COMPILE,", 8, 79, header_bye
	bl	compile_
	NEXT
WORD_TAIL compile_comma
WORD_HDR literal, "LITERAL", 519, 101, header_compile_comma
	bl	compile_lit_
	NEXT
WORD_TAIL literal
WORD_HDR compile_literal, "[LITERAL]", 9, 102, header_literal
	bl	compile_lit_
	NEXT
WORD_TAIL compile_literal
WORD_HDR compile_zbranch, "[0BRANCH]", 9, 103, header_compile_literal
	ldr	r2, .L263
        push    {r2}
	bl	compile_
	b	.L260
.L261:
	bl	drain_queue_
.L260:
	movw	r3, #:lower16:queue_length
	movt	r3, #:upper16:queue_length
	ldr	r3, [r3]
	cmp	r3, #0
	bgt	.L261
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	ldr	r2, [r3]
	push    {r2}
	add	r1, r2, #4
	str	r1, [r3]
	mov	r3, #0
	str	r3, [r2]
	NEXT
.L264:
	.align	2
.L263:
	.word	header_zbranch+12
	.size	code_compile_zbranch, .-code_compile_zbranch
WORD_HDR compile_branch, "[BRANCH]", 8, 104, header_compile_zbranch
	ldr	r2, .L269
        push    {r2}
	bl	compile_
	b	.L266
.L267:
	bl	drain_queue_
.L266:
	movw	r3, #:lower16:queue_length
	movt	r3, #:upper16:queue_length
	ldr	r3, [r3]
	cmp	r3, #0
	bgt	.L267
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	ldr	r3, [r3]
	push    {r3}
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	ldr	r2, [r3]
	add	r1, r2, #4
	str	r1, [r3]
	mov	r3, #0
	str	r3, [r2]
	NEXT
.L270:
	.align	2
.L269:
	.word	header_branch+12
	.size	code_compile_branch, .-code_compile_branch
WORD_HDR control_flush, "(CONTROL-FLUSH)", 15, 105, header_compile_branch
	b	.L272
.L273:
	bl	drain_queue_
.L272:
	movw	r3, #:lower16:queue_length
	movt	r3, #:upper16:queue_length
	ldr	r3, [r3]
	cmp	r3, #0
	bgt	.L273
	NEXT
WORD_TAIL control_flush
WORD_HDR debug_break, "(DEBUG)", 7, 80, header_control_flush
	NEXT
WORD_TAIL debug_break
WORD_HDR close_file, "CLOSE-FILE", 10, 81, header_debug_break
	ldr     r0, [sp]
	CALL	fclose
	cmp	r0, #0
	beq	.L277
	CALL	__errno_location
	mov	r3, r0
	ldr	r3, [r3]
	b	.L278
.L277:
	mov	r3, #0
.L278:
	str	r3, [sp]
	NEXT
WORD_TAIL close_file
	.global	file_modes
	.section	.rodata
	.align	2
.LC97:
	.ascii	"r\000"
	.align	2
.LC98:
	.ascii	"r+\000"
	.align	2
.LC99:
	.ascii	"rb\000"
	.align	2
.LC100:
	.ascii	"r+b\000"
	.align	2
.LC101:
	.ascii	"w+\000"
	.align	2
.LC102:
	.ascii	"w\000"
	.align	2
.LC103:
	.ascii	"w+b\000"
	.data
	.align	2
	.type	file_modes, %object
	.size	file_modes, 64
file_modes:
	.word	0
	.word	.LC97
	.word	.LC98
	.word	.LC98
	.word	0
	.word	.LC99
	.word	.LC100
	.word	.LC100
	.word	0
	.word	.LC101
	.word	.LC102
	.word	.LC101
	.word	0
	.word	.LC103
	.word	.LC81
	.word	.LC103
WORD_HDR create_file, "CREATE-FILE", 11, 82, header_close_file
	movw	r0, #:lower16:tempBuf
	movt	r0, #:upper16:tempBuf
        ldr     r1, [sp, #8]
        ldr     r2, [sp, #4]
	CALL	strncpy
	ldr     r2, [sp, #4]
	movw	r3, #:lower16:tempBuf
	movt	r3, #:upper16:tempBuf
	mov	r1, #0
	strb	r1, [r3, r2]
	add     sp, sp, #4

	ldr     r1, [sp]
        orr     r1, r1, #8   @ FA_TRUNC
	movw	r3, #:lower16:file_modes
	movt	r3, #:upper16:file_modes
	ldr	r3, [r3, r1, lsl #2]
	mov	r1, r3
	movw	r0, #:lower16:tempBuf
	movt	r0, #:upper16:tempBuf
	CALL	fopen
        str     r0, [sp, #4]
	cmp	r0, #0
	bne	.L281
	CALL	__errno_location
	mov	r3, r0
	ldr	r3, [r3]
	b	.L282
.L281:
	mov	r3, #0
.L282:
	str	r3, [sp]
	NEXT
WORD_TAIL create_file
WORD_HDR open_file, "OPEN-FILE", 9, 83, header_create_file
	ldr	r1, [sp, #8]
	ldr     r2, [sp, #4]
	movw	r0, #:lower16:tempBuf
	movt	r0, #:upper16:tempBuf
	CALL	strncpy
	ldr     r2, [sp, #4]
	movw	r3, #:lower16:tempBuf
	movt	r3, #:upper16:tempBuf
	mov	r1, #0
	strb	r1, [r3, r2]
	ldr     r2, [sp]
	movw	r3, #:lower16:file_modes
	movt	r3, #:upper16:file_modes
	ldr	r3, [r3, r2, lsl #2]
	mov	r1, r3
	movw	r0, #:lower16:tempBuf
	movt	r0, #:upper16:tempBuf
	CALL	fopen
	str	r0, [sp, #8]
	cmp	r0, #0
	bne	.L285
	ldr     r3, [sp]
	and	r3, r3, #2   @ FA_WRITE
	cmp	r3, #0
	beq	.L285
	ldr     r3, [sp]
	orr	r2, r3, #8   @ FA_TRUNC
	movw	r3, #:lower16:file_modes
	movt	r3, #:upper16:file_modes
	ldr	r3, [r3, r2, lsl #2]
	mov	r1, r3
	movw	r0, #:lower16:tempBuf
	movt	r0, #:upper16:tempBuf
	CALL	fopen
	str	r0, [sp, #8]
.L285:
        ldr     r3, [sp, #8]
	cmp	r3, #0
	bne	.L286
	CALL	__errno_location
	mov	r3, r0
	ldr	r3, [r3]
	b	.L287
.L286:
	mov	r3, #0
.L287:
	str     r3, [sp, #4]
        add     sp, sp, #4
	NEXT
WORD_TAIL open_file
WORD_HDR delete_file, "DELETE-FILE", 11, 84, header_open_file
        ldr     r2, [sp]
        ldr     r1, [sp, #4]
	movw	r0, #:lower16:tempBuf
	movt	r0, #:upper16:tempBuf
	CALL	strncpy
	ldr	r2, [sp, #4]
	movw	r3, #:lower16:tempBuf
	movt	r3, #:upper16:tempBuf
	mov	r1, #0
	strb	r1, [r3, r2]
        add     sp, sp, #4
	movw	r0, #:lower16:tempBuf
	movt	r0, #:upper16:tempBuf
	CALL	remove
	str	r0, [sp]
	cmn	r0, #1
	bne	.L290
	CALL	__errno_location
        ldr     r0, [r0]
        str     r0, [sp]
.L290:
	NEXT
WORD_TAIL delete_file
WORD_HDR file_position, "FILE-POSITION", 13, 85, header_delete_file
        sub     sp, sp, #8
        mov     r0, #0
        str     r0, [sp, #4]
        ldr     r0, [sp, #8]
	CALL	ftell
        str     r0, [sp, #8]
	cmn	r0, #1
	bne	.L293
	CALL	__errno_location
	mov	r3, r0
	ldr	r3, [r3]
	b	.L294
.L293:
	mov	r3, #0
.L294:
	str	r3, [sp]
	NEXT
WORD_TAIL file_position
WORD_HDR file_size, "FILE-SIZE", 9, 86, header_file_position
        sub     sp, sp, #8
        mov     r0, #0
        str     r0, [sp, #4]
        ldr     r7, [sp, #8]    @ r7 holds the file pointer
        mov     r0, r7
        CALL ftell
        mov     r8, r0          @ r8 holds the original position.
        cmp     r0, #0
        bge     .L297
        CALL      __errno_location
        ldr     r0, [r0]
        str     r0, [sp]
        b       .L298
.L297:
        mov     r0, r7
        mov     r1, #0
	mov	r2, #2   @ SEEK_END
        CALL    fseek
        cmp     r0, #0
        bge     .L299
        CALL      __errno_location
        ldr     r0, [r0]
        str     r0, [sp]
        mov     r0, r7
        mov     r1, r8
        mov     r2, #0   @ SEEK_SET
        CALL      fseek
	b	.L298
.L299:
        mov     r0, r7
        CALL      ftell    @ r0 is now the actual position
        str     r0, [sp, #8]
        mov     r0, #0
        str     r0, [sp]
        mov     r0, r7
        mov     r1, r8
        mov     r2, #0   @ SEEK_SET
        CALL    fseek
.L298:
        NEXT
WORD_TAIL file_size
WORD_HDR include_file, "INCLUDE-FILE", 12, 87, header_file_size
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	movw	r2, #:lower16:inputIndex
	movt	r2, #:upper16:inputIndex
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r0, [r3]
        pop     {r1}
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r0, #4
	add	r3, r2, r3
	str	r1, [r3, #8]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r3, #4
	add	r3, r2, r3
	mov	r2, #0
	str	r2, [r3, #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r2, [r3]
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	mov	r1, #0
	str	r1, [r3, r2, lsl #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r0, [r3]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:parseBuffers
	movt	r3, #:upper16:parseBuffers
	add	r1, r2, r3
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r0, #4
	add	r3, r2, r3
	str	r1, [r3, #12]
	NEXT
WORD_TAIL include_file
WORD_HDR read_file, "READ-FILE", 9, 88, header_include_file
        ldr     r3, [sp]
        ldr     r2, [sp, #4]
        mov     r1, #1
        ldr     r0, [sp, #8]
        CALL      fread
        cmp     r0, #0
        bne     .L303
        ldr     r0, [sp]
        CALL      feof
        cmp     r0, #0
        beq     .L304
        add     sp, sp, #4
        mov     r0, #0
        str     r0, [sp]
        str     r0, [sp, #4]
        b       .L306
.L304:
        ldr     r0, [sp]
        CALL      ferror
        str     r0, [sp, #4]
        mov     r0, #0
        str     r0, [sp, #8]
        add     sp, sp, #4
        b       .L306
.L303:
        @ r0 is still the length read
        add     sp, sp, #4
        str     r0, [sp, #4]
        mov     r0, #0
        str     r0, [sp]
.L306:
	NEXT
WORD_TAIL read_file
WORD_HDR read_line, "READ-LINE", 9, 89, header_read_file
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	mov	r2, #0
	str	r2, [r3]
	movw	r3, #:lower16:tempSize
	movt	r3, #:upper16:tempSize
	mov	r2, #0
	str	r2, [r3]
	ldr     r2, [sp]
	movw	r1, #:lower16:tempSize
	movt	r1, #:upper16:tempSize
	movw	r0, #:lower16:str1
	movt	r0, #:upper16:str1
	CALL	getline
	mov	r2, r0
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	str	r0, [r3]
	cmn	r2, #1
	bne	.L309
	CALL	__errno_location
	ldr	r0, [r0]
        str     r0, [sp]
        mov     r0, #0
        str     r0, [sp, #4]
        str     r0, [sp, #8]
	b	.L310
.L309:
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	cmp	r3, #0
	bne	.L311
        mov     r0, #0
        str     r0, [sp]
        str     r0, [sp, #4]
        str     r0, [sp, #8]
	b	.L310
.L311:
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	sub	r2, r3, #1
	ldr     r3, [sp, #4]
	cmp	r2, r3
	ble	.L312
        ldr     r0, [sp]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r2, [r3]
        ldr     r3, [sp, #4]
        sub     r1, r2, r3
	mov	r2, #1    @ SEEK_CUR
	CALL	fseek
	ldr     r2, [sp, #4]
	add	r2, r3, #1
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	str	r2, [r3]
	b	.L313
.L312:
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r2, [r3]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	add	r3, r2, r3
	sub	r3, r3, #1
	ldrb	r3, [r3]	@ zero_extendqisi2
	cmp	r3, #10
	beq	.L313
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	movw	r2, #:lower16:c1
	movt	r2, #:upper16:c1
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
.L313:
        ldr     r0, [sp, #8]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	sub	r2, r3, #1
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r1, [r3]
	CALL	strncpy
        mov     r0, #0
        str     r0, [sp]
        mvn     r1, #0
        str     r1, [sp, #4]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	sub	r3, r3, #1
	str	r3, [sp, #8]
.L310:
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r3, [r3]
	cmp	r3, #0
	beq	.L314
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r0, [r3]
	CALL	free
.L314:
	NEXT
WORD_TAIL read_line
WORD_HDR reposition_file, "REPOSITION-FILE", 15, 90, header_read_line
        ldr     r0, [sp]
        ldr     r1, [sp, #8]
        mov     r2, #0     @ SEEK_SET
        CALL      fseek
        add     sp, sp, #8
        cmn     r0, #1
        bne     .L317
        CALL      __errno_location
        ldr     r3, [r0]
        str     r3, [sp]
.L317:
        str     r0, [sp]
	NEXT
WORD_TAIL reposition_file
WORD_HDR resize_file, "RESIZE-FILE", 11, 91, header_reposition_file
        ldr     r0, [sp]
        CALL      fileno
        ldr     r1, [sp, #8]
        CALL      ftruncate
        str     r0, [sp, #8]
        add     sp, sp , #8
        cmn     r0, #1
	bne	.L320
	CALL	__errno_location
	ldr	r3, [r3]
	b	.L321
.L320:
	mov	r3, #0
.L321:
	str	r3, [sp]
	NEXT
WORD_TAIL resize_file
WORD_HDR write_file, "WRITE-FILE", 10, 92, header_resize_file
        pop     {r3, r4, r5}
        mov     r0, r5
        mov     r1, #1
        mov     r2, r4
        CALL      fwrite
        mov     r0, #0
        push    {r0}
        NEXT
WORD_TAIL write_file
WORD_HDR write_line, "WRITE-LINE", 10, 93, header_write_file
        ldr     r2, [sp, #4]
        ldr     r1, [sp, #8]
	movw	r0, #:lower16:tempBuf
	movt	r0, #:upper16:tempBuf
	CALL	strncpy
	ldr     r2, [sp, #4]
	movw	r3, #:lower16:tempBuf
	movt	r3, #:upper16:tempBuf
	mov	r1, #10
	strb	r1, [r3, r2]
        ldr     r3, [sp]
        ldr     r2, [sp, #4]
        add     r2, r2, #1
        mov     r1, #1
	movw	r0, #:lower16:tempBuf
	movt	r0, #:upper16:tempBuf
	CALL	fwrite
        add     sp, sp, #8
        mov     r0, #0
        str     r0, [sp]
        NEXT
WORD_TAIL write_line
WORD_HDR flush_file, "FLUSH-FILE", 10, 94, header_write_line
        pop     {r0}
        CALL      fileno
        CALL      fsync
        cmn     r0, #1
        bne     .L328
        CALL      __errno_location
        ldr     r0, [r0]
.L328:
        push    {r0}
	NEXT
WORD_TAIL flush_file

       .section        .rodata
       .align  2
.LC118:
       .ascii  "*** Colon definition with no name\012\000"
       .text

WORD_HDR colon, ":", 1, 95, header_flush_file
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	ldr	r3, [r3]
	add	r3, r3, #3
	bic	r3, r3, #3
	mov	r2, r3
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	str	r2, [r3]
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	ldr	r2, [r3]
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	str	r2, [r3]
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	movw	r2, #:lower16:dsp
	movt	r2, #:upper16:dsp
	ldr	r2, [r2]
	add	r2, r2, #16
	str	r2, [r3]
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r2, [r3]
	movw	r3, #:lower16:compilationWordlist
	movt	r3, #:upper16:compilationWordlist
	ldr	r3, [r3]
	ldr	r3, [r3] @ The actual previous head.
	str	r3, [r2] @ Gets written into the new header.
	movw	r3, #:lower16:compilationWordlist
	movt	r3, #:upper16:compilationWordlist
	ldr	r2, [r3]
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r3, [r3]
	str	r3, [r2]
	bl	parse_name_
	ldr	r3, [sp]
	cmp	r3, #0
	bne	.L331
	movw	r3, #:lower16:stderr
	movt	r3, #:upper16:stderr
	ldr	r3, [r3]
	mov	r2, #34
	mov	r1, #1
	movw	r0, #:lower16:.LC118
	movt	r0, #:upper16:.LC118
	CALL	fwrite
	bl	code_quit
.L331:
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r4, [r3]
	ldr	r0, [sp]
	CALL	malloc
	mov	r3, r0
	str	r3, [r4, #8]
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r0, [r3]
	ldr	r0, [r0, #8]
        ldr     r1, [sp, #4]
        ldr     r2, [sp]
	CALL	strncpy
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r2, [r3]
	ldr     r3, [sp]
	orr	r3, r3, #256
	str	r3, [r2, #4]
	add     sp, sp, #8
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r2, [r3]
	movw	r3, #:lower16:code_docol
	movt	r3, #:upper16:code_docol
	str	r3, [r2, #12]
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r3, [r3]
	add	r2, r3, #12
	movw	r3, #:lower16:lastWord
	movt	r3, #:upper16:lastWord
	str	r2, [r3]
	movw	r3, #:lower16:state
	movt	r3, #:upper16:state
	mov	r2, #1
	str	r2, [r3]
	NEXT
WORD_TAIL colon
WORD_HDR colon_no_name, ":NONAME", 7, 96, header_colon
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	ldr	r3, [r3]
	add	r3, r3, #3
	bic	r3, r3, #3
	mov	r2, r3
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	str	r2, [r3]
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	ldr	r2, [r3]
	movw	r3, #:lower16:lastWord
	movt	r3, #:upper16:lastWord
	str	r2, [r3]
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	ldr	r3, [r3]
	push    {r3}
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	ldr	r2, [r3]
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
	add	r1, r2, #4
	str	r1, [r3]
	movw	r3, #:lower16:code_docol
	movt	r3, #:upper16:code_docol
	str	r3, [r2]
	movw	r3, #:lower16:state
	movt	r3, #:upper16:state
	mov	r2, #1
	str	r2, [r3]
	NEXT
WORD_TAIL colon_no_name
WORD_HDR exit, "EXIT", 4, 97, header_colon_no_name
	EXIT_NEXT
WORD_TAIL exit

       .section        .rodata
       .align  2
.LC122:
       .ascii  "Decompiling \000"
       .align  2
.LC123:
       .ascii  "NOT FOUND!\000"
       .align  2
.LC124:
       .ascii  "Not compiled using DOCOL; can't SEE native words.\000"
       .align  2
.LC125:
       .ascii  "%u: (literal) %d\012\000"
       .align  2
.LC126:
       .ascii  "%u: branch by %d to: %u\012\000"
       .align  2
.LC127:
       .ascii  "\"%s\"\012\000"
       .align  2
.LC128:
       .ascii  "%u: \000"
       .text

WORD_HDR see, "SEE", 3, 98, header_exit
	bl	parse_name_
	movw	r0, #:lower16:.LC122
	movt	r0, #:upper16:.LC122
	CALL	printf
	ldr     r0, [sp, #4]
        ldr     r1, [sp]
	bl	print
	mov	r0, #10
	CALL	putchar
	bl	find_
	ldr     r3, [sp]
	cmp	r3, #0
	bne	.L336
	movw	r0, #:lower16:.LC123
	movt	r0, #:upper16:.LC123
	CALL	puts
	b	.L337
.L336:
	ldr     r2, [sp, #4]
	movw	r3, #:lower16:cfa
	movt	r3, #:upper16:cfa
	str	r2, [r3]
	movw	r3, #:lower16:cfa
	movt	r3, #:upper16:cfa
	ldr	r3, [r3]
	ldr	r2, [r3]
	movw	r3, #:lower16:code_docol
	movt	r3, #:upper16:code_docol
	cmp	r2, r3
	beq	.L338
	movw	r0, #:lower16:.LC124
	movt	r0, #:upper16:.LC124
	CALL	puts
	b	.L337
.L338:
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	mov	r2, #0
	str	r2, [r3]
.L346:
	movw	r3, #:lower16:cfa
	movt	r3, #:upper16:cfa
	movw	r2, #:lower16:cfa
	movt	r2, #:upper16:cfa
	ldr	r2, [r2]
	add	r2, r2, #4
	str	r2, [r3]
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r2, [r3]
	movw	r3, #:lower16:header_dolit
	movt	r3, #:upper16:header_dolit
	cmp	r2, r3
	bne	.L339
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	mov	r2, #0
	str	r2, [r3]
	movw	r3, #:lower16:cfa
	movt	r3, #:upper16:cfa
	ldr	r3, [r3]
	ldr	r3, [r3]
	mov	r2, r3
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	str	r2, [r3]
	movw	r2, #:lower16:c1
	movt	r2, #:upper16:c1
	movw	r3, #:lower16:cfa
	movt	r3, #:upper16:cfa
	ldr	r2, [r2]
	ldr	r1, [r3]
	movw	r0, #:lower16:.LC125
	movt	r0, #:upper16:.LC125
	CALL	printf
	b	.L340
.L339:
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r2, [r3]
	movw	r3, #:lower16:header_zbranch
	movt	r3, #:upper16:header_zbranch
	cmp	r2, r3
	beq	.L341
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r2, [r3]
	movw	r3, #:lower16:header_branch
	movt	r3, #:upper16:header_branch
	cmp	r2, r3
	bne	.L342
.L341:
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	mov	r2, #0
	str	r2, [r3]
	movw	r3, #:lower16:cfa
	movt	r3, #:upper16:cfa
	ldr	r3, [r3]
	ldr	r3, [r3]
	mov	r2, r3
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	str	r2, [r3]
	movw	r3, #:lower16:cfa
	movt	r3, #:upper16:cfa
	ldr	r2, [r3]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	add	r3, r2, r3
	mov	r2, r3
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	str	r2, [r3]
	movw	r3, #:lower16:cfa
	movt	r3, #:upper16:cfa
	ldr	r3, [r3]
	ldr	r2, [r3]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	movw	r1, #:lower16:cfa
	movt	r1, #:upper16:cfa
	ldr	r3, [r3]
	ldr	r1, [r1]
	movw	r0, #:lower16:.LC126
	movt	r0, #:upper16:.LC126
	CALL	printf
	b	.L340
.L342:
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r2, [r3]
	movw	r3, #:lower16:header_dostring
	movt	r3, #:upper16:header_dostring
	cmp	r2, r3
	bne	.L343
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	mov	r2, #0
	str	r2, [r3]
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	movw	r2, #:lower16:cfa
	movt	r2, #:upper16:cfa
	ldr	r2, [r2]
	str	r2, [r3]
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r3, [r3]
	ldrb	r3, [r3]	@ zero_extendqisi2
	mov	r2, r3
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	str	r2, [r3]
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	movw	r2, #:lower16:str1
	movt	r2, #:upper16:str1
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
	movw	r2, #:lower16:c1
	movt	r2, #:upper16:c1
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r2, [r2]
	ldr	r1, [r3]
	movw	r0, #:lower16:tempBuf
	movt	r0, #:upper16:tempBuf
	CALL	strncpy
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r2, [r3]
	movw	r3, #:lower16:tempBuf
	movt	r3, #:upper16:tempBuf
	mov	r1, #0
	strb	r1, [r3, r2]
	b	.L344
.L345:
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r3, [r3]
	ldrb	r3, [r3]	@ zero_extendqisi2
	mov	r1, r3
	movw	r0, #:lower16:.LC36
	movt	r0, #:upper16:.LC36
	CALL	printf
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	movw	r2, #:lower16:str1
	movt	r2, #:upper16:str1
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	movw	r2, #:lower16:c1
	movt	r2, #:upper16:c1
	ldr	r2, [r2]
	sub	r2, r2, #1
	str	r2, [r3]
.L344:
	movw	r3, #:lower16:c1
	movt	r3, #:upper16:c1
	ldr	r3, [r3]
	cmp	r3, #0
	bgt	.L345
	movw	r1, #:lower16:tempBuf
	movt	r1, #:upper16:tempBuf
	movw	r0, #:lower16:.LC127
	movt	r0, #:upper16:.LC127
	CALL	printf
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r3, [r3]
	add	r3, r3, #3
	bic	r3, r3, #3
	mov	r2, r3
	movw	r3, #:lower16:cfa
	movt	r3, #:upper16:cfa
	str	r2, [r3]
	b	.L340
.L343:
	movw	r3, #:lower16:cfa
	movt	r3, #:upper16:cfa
	ldr	r3, [r3]
	ldr	r2, [r3]
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	str	r2, [r3]
	movw	r3, #:lower16:str1
	movt	r3, #:upper16:str1
	ldr	r3, [r3]
	sub	r2, r3, #12
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	str	r2, [r3]
	movw	r3, #:lower16:cfa
	movt	r3, #:upper16:cfa
	ldr	r1, [r3]
	movw	r0, #:lower16:.LC128
	movt	r0, #:upper16:.LC128
	CALL	printf
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r2, [r3]
	movw	r3, #:lower16:tempHeader
	movt	r3, #:upper16:tempHeader
	ldr	r3, [r3]
	ldr	r3, [r3, #4]
	uxtb	r3, r3
	mov	r1, r3
	ldr	r0, [r2, #8]
	bl	print
	mov	r0, #10
	CALL	putchar
.L340:
	movw	r3, #:lower16:cfa
	movt	r3, #:upper16:cfa
	ldr	r3, [r3]
	ldr	r3, [r3]
	ldr	r2, .L348
	cmp	r3, r2
	beq	.L337
	b	.L346
.L337:
        add     sp, sp, #8
	NEXT
.L349:
	.align	2
.L348:
	.word	header_exit+12
	.size	code_see, .-code_see
WORD_HDR utime, "UTIME", 5, 106, header_see
	mov	r1, #0
	movw	r0, #:lower16:timeVal
	movt	r0, #:upper16:timeVal
	CALL	gettimeofday
        sub     sp, sp, #8
	movw	r3, #:lower16:timeVal
	movt	r3, #:upper16:timeVal
	ldr	r3, [r3]
	mov	r2, r3
	asr	r3, r2, #31
	movw	r1, #16960
	movt	r1, 15
	mul	r0, r1, r3
	mov	r1, #0
	mul	r1, r1, r2
	add	r0, r0, r1
	movw	r1, #16960
	movt	r1, 15
	umull	r2, r3, r2, r1
	add	r1, r0, r3
	mov	r3, r1
	movw	r1, #:lower16:timeVal
	movt	r1, #:upper16:timeVal
	ldr	r1, [r1, #4]
	mov	r0, r1
	asr	r1, r0, #31
	adds	r0, r0, r2
	adc	r1, r1, r3
	movw	r3, #:lower16:i64
	movt	r3, #:upper16:i64
	strd	r0, [r3]
	movw	r3, #:lower16:i64
	movt	r3, #:upper16:i64
	ldr	r3, [r3, #4]
	mov	r3, r3
	str	r3, [sp, #4]
	movw	r3, #:lower16:i64
	movt	r3, #:upper16:i64
	ldr	r3, [r3]
	str	r3, [sp]
	NEXT
WORD_TAIL utime
WORD_HDR loop_end, "(LOOP-END)", 10, 107, header_utime
        movw    r7, #:lower16:rsp
        movt    r7, #:upper16:rsp
        ldr     r8, [r7]     @ r8 is RSP
        ldr     r3, [r8]     @ r3 is the index
        ldr     r4, [r8, #4] @ r4 is the limit
        sub     r2, r3, r4   @ r2 is index-limit
        ldr     r5, [sp]     @ r5 is the delta
        @ Calculate delta + index-limit
        add     r0, r5, r2
        eor     r0, r0, r2
        ands    r0, #0x80000000   @ sets the Zero flag
        mov     r0, #0
        mvneq   r0, #0        @ true flag when top bit was 0
        @ Calculate delta XOR index-limit
        eor     r1, r5, r2
        ands    r1, #0x80000000   @ sets the Zero flag
        mov     r1, #0
        mvneq   r1, #0        @ true flag when top bit was 0
        orr     r1, r1, r0    @ OR those two flags together
        mvn     r0, r1        @ negate the result
        str     r0, [sp]
        add     r0, r5, r3    @ Computing the new index
        str     r0, [r8]      @ And writing it to the return stack
        NEXT
	.size	code_loop_end, .-code_loop_end


@ Now the code for making C calls.

WORD_HDR ccall_0, "CCALL0", 6, 108, header_loop_end
	pop     {r0}
        CALL_REG r0
        push    {r0}
        NEXT

WORD_HDR ccall_1, "CCALL1", 6, 109, header_ccall_0
        pop     {r1, r2}
        mov     r0, r2
        CALL_REG r1
        push    {r0}
        NEXT

WORD_HDR ccall_2, "CCALL2", 6, 110, header_ccall_1
        pop     {r8}
        pop     {r1, r2}
        mov     r0, r2
        CALL_REG r8
        push    {r0}
        NEXT

WORD_HDR ccall_3, "CCALL3", 6, 111, header_ccall_2
	pop     {r8}
        ldr     r2, [sp]
        ldr     r1, [sp, #4]
        ldr     r0, [sp, #8]
        add     sp, sp, #8 @ Leave room for the return.
        CALL_REG r8
        str     r0,  [sp]
        NEXT

WORD_HDR ccall_4, "CCALL4", 6, 112, header_ccall_3
	pop     {r8}
        ldr     r3, [sp]
        ldr     r2, [sp, #4]
        ldr     r1, [sp, #8]
        ldr     r0, [sp, #12]
        add     sp, sp, #12 @ Leave room for the return.
        CALL_REG r8
        str     r0, [sp]
        NEXT

WORD_HDR ccall_5, "CCALL5", 6, 115, header_ccall_4
	pop     {r7, r8} @ r7 = ptr, r8 = arg4
        ldr     r3, [sp]
        ldr     r2, [sp, #4]
        ldr     r1, [sp, #8]
        ldr     r0, [sp, #12]
        @ Special case: Needs to not use CALL_REG directly.
        add     r9, sp, #12 @ Final sp here (ready to receive result).
        bic     sp, sp, #7 @ 8-byte alignment
        str     r8, [sp]
        blx     r7
        mov     sp, r9
        str     r0, [sp]
        NEXT

WORD_HDR ccall_6, "CCALL6", 6, 116, header_ccall_5
	pop     {r6, r7, r8} @ r6 = ptr, r7 = arg5, r8 = arg4
        ldr     r3, [sp]
        ldr     r2, [sp, #4]
        ldr     r1, [sp, #8]
        ldr     r0, [sp, #12]
        @ Special case: Needs to not use CALL_REG directly.
        add     r9, sp, #12 @ Final sp here (ready to receive result).
        sub     sp, sp, #8
        bic     sp, sp, #7 @ 8-byte alignment
        str     r8, [sp]
        str     r7, [sp, #4]
        blx     r6
        mov     sp, r9
        str     r0, [sp]
        NEXT

WORD_HDR c_library, "C-LIBRARY", 9, 113, header_ccall_6
	@ Expects a null-terminated, C-style string on the stack, and dlopen()s
        @ it, globally, so a generic dlsym() for it will work.
        pop     {r0}
        movw     r1, #258    @ RTLD_NOW | RTLD_GLOBAL
        CALL      dlopen
        NEXT

WORD_HDR c_symbol, "C-SYMBOL", 8, 114, header_c_library
	@ Expects a C-style null-terminated string on the stack, and dlsym()s
        @ it, returning the resulting pointer on the stack.
        pop     {r1}
        mov     r0, #0    @ 0 is RTLD_DEFAULT, searching everywhere.
        CALL      dlsym
        push    {r0}
        NEXT

WORD_HDR semicolon, ";", 513, 99, header_c_symbol
	movw	r3, #:lower16:compilationWordlist
	movt	r3, #:upper16:compilationWordlist
        ldr     r3, [r3]
	ldr	r2, [r3]
	ldr	r1, [r2, #4]
        bic     r1, r1, #256
        str     r1, [r2, #4]
	ldr	r2, .L356
	push    {r2}
	bl	compile_
	b	.L353
.L354:
	bl	drain_queue_
.L353:
	movw	r3, #:lower16:queue_length
	movt	r3, #:upper16:queue_length
	ldr	r3, [r3]
	cmp	r3, #0
	bne	.L354
	movw	r3, #:lower16:state
	movt	r3, #:upper16:state
	mov	r2, #0
	str	r2, [r3]
	NEXT
.L357:
	.align	2
.L356:
	.word	header_exit+12
	.size	code_semicolon, .-code_semicolon
	.section	.rodata
	.align	2
.LC131:
	.ascii	"Could not load input file: %s\012\000"
	.text
	.align	2
	.global	main
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	main, %function
main:
	@ args = 0, pretend = 0, frame = 16
	@ frame_needed = 0, uses_anonymous_args = 0
	push	{r4, lr}
	sub	sp, sp, #16
	str	r0, [sp, #4]
	str	r1, [sp]
	movw	r3, #:lower16:forthWordlist
	movt	r3, #:upper16:forthWordlist
	movw	r2, #:lower16:header_semicolon
	movt	r2, #:upper16:header_semicolon
	str	r2, [r3]
	movw	r2, #:lower16:searchArray
	movt	r2, #:upper16:searchArray
        str     r3, [r2]
	movw	r2, #:lower16:compilationWordlist
	movt	r2, #:upper16:compilationWordlist
        str     r3, [r2]
	movw	r3, #:lower16:base
	movt	r3, #:upper16:base
	mov	r2, #10
	str	r2, [r3]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	mov	r2, #0
	str	r2, [r3]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	ip, [r3]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r1, [r3]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r0, [r3]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r0, #4
	add	r3, r2, r3
	mov	r2, #0
	str	r2, [r3, #4]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r0, #4
	add	r3, r2, r3
	ldr	r2, [r3, #4]
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	str	r2, [r3, r1, lsl #4]
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	ldr	r1, [r3, r1, lsl #4]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, ip, #4
	add	r3, r2, r3
	str	r1, [r3, #8]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r0, [r3]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:parseBuffers
	movt	r3, #:upper16:parseBuffers
	add	r1, r2, r3
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r0, #4
	add	r3, r2, r3
	str	r1, [r3, #12]
	ldr	r3, [sp, #4]
	sub	r3, r3, #1
	str	r3, [sp, #4]
	b	.L359
.L361:
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	movw	r2, #:lower16:inputIndex
	movt	r2, #:upper16:inputIndex
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r4, [r3]
	ldr	r3, [sp, #4]
	lsl	r3, r3, #2
	ldr	r2, [sp]
	add	r3, r2, r3
	movw	r1, #:lower16:.LC97
	movt	r1, #:upper16:.LC97
	ldr	r0, [r3]
	CALL	fopen
	mov	r3, r0
	mov	r1, r3
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r4, #4
	add	r3, r2, r3
	str	r1, [r3, #8]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r3, r3, #4
	add	r3, r2, r3
	ldr	r3, [r3, #8]
	cmp	r3, #0
	bne	.L360
	ldr	r3, [sp, #4]
	lsl	r3, r3, #2
	ldr	r2, [sp]
	add	r2, r2, r3
	movw	r3, #:lower16:stderr
	movt	r3, #:upper16:stderr
	ldr	r2, [r2]
	movw	r1, #:lower16:.LC131
	movt	r1, #:upper16:.LC131
	ldr	r0, [r3]
	CALL	fprintf
	mov	r0, #1
	CALL	exit
.L360:
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r3, #4
	add	r3, r2, r3
	mov	r2, #0
	str	r2, [r3, #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r2, [r3]
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	mov	r1, #0
	str	r1, [r3, r2, lsl #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r0, [r3]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:parseBuffers
	movt	r3, #:upper16:parseBuffers
	add	r1, r2, r3
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r0, #4
	add	r3, r2, r3
	str	r1, [r3, #12]
	ldr	r3, [sp, #4]
	sub	r3, r3, #1
	str	r3, [sp, #4]
.L359:
	ldr	r3, [sp, #4]
	cmp	r3, #0
	bgt	.L361
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	movw	r2, #:lower16:inputIndex
	movt	r2, #:upper16:inputIndex
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
	mov	r0, #8
	CALL	malloc
	mov	r3, r0
	str	r3, [sp, #12]
	ldr	r2, [sp, #12]
	movw	r3, #:lower16:_binary_core_file_fs_start
	movt	r3, #:upper16:_binary_core_file_fs_start
	str	r3, [r2]
	ldr	r2, [sp, #12]
	movw	r3, #:lower16:_binary_core_file_fs_end
	movt	r3, #:upper16:_binary_core_file_fs_end
	str	r3, [r2, #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	ldr	r2, [sp, #12]
	orr	r1, r2, #1
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r3, #4
	add	r3, r2, r3
	str	r1, [r3, #8]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r3, #4
	add	r3, r2, r3
	mov	r2, #0
	str	r2, [r3, #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r2, [r3]
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	mov	r1, #0
	str	r1, [r3, r2, lsl #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r0, [r3]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:parseBuffers
	movt	r3, #:upper16:parseBuffers
	add	r1, r2, r3
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r0, #4
	add	r3, r2, r3
	str	r1, [r3, #12]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	movw	r2, #:lower16:inputIndex
	movt	r2, #:upper16:inputIndex
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
	mov	r0, #8
	CALL	malloc
	mov	r3, r0
	str	r3, [sp, #12]
	ldr	r2, [sp, #12]
	movw	r3, #:lower16:_binary_core_facility_fs_start
	movt	r3, #:upper16:_binary_core_facility_fs_start
	str	r3, [r2]
	ldr	r2, [sp, #12]
	movw	r3, #:lower16:_binary_core_facility_fs_end
	movt	r3, #:upper16:_binary_core_facility_fs_end
	str	r3, [r2, #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	ldr	r2, [sp, #12]
	orr	r1, r2, #1
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r3, #4
	add	r3, r2, r3
	str	r1, [r3, #8]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r3, #4
	add	r3, r2, r3
	mov	r2, #0
	str	r2, [r3, #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r2, [r3]
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	mov	r1, #0
	str	r1, [r3, r2, lsl #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r0, [r3]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:parseBuffers
	movt	r3, #:upper16:parseBuffers
	add	r1, r2, r3
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r0, #4
	add	r3, r2, r3
	str	r1, [r3, #12]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	movw	r2, #:lower16:inputIndex
	movt	r2, #:upper16:inputIndex
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
	mov	r0, #8
	CALL	malloc
	mov	r3, r0
	str	r3, [sp, #12]
	ldr	r2, [sp, #12]
	movw	r3, #:lower16:_binary_core_tools_fs_start
	movt	r3, #:upper16:_binary_core_tools_fs_start
	str	r3, [r2]
	ldr	r2, [sp, #12]
	movw	r3, #:lower16:_binary_core_tools_fs_end
	movt	r3, #:upper16:_binary_core_tools_fs_end
	str	r3, [r2, #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	ldr	r2, [sp, #12]
	orr	r1, r2, #1
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r3, #4
	add	r3, r2, r3
	str	r1, [r3, #8]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r3, #4
	add	r3, r2, r3
	mov	r2, #0
	str	r2, [r3, #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r2, [r3]
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	mov	r1, #0
	str	r1, [r3, r2, lsl #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r0, [r3]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:parseBuffers
	movt	r3, #:upper16:parseBuffers
	add	r1, r2, r3
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r0, #4
	add	r3, r2, r3
	str	r1, [r3, #12]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	movw	r2, #:lower16:inputIndex
	movt	r2, #:upper16:inputIndex
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
	mov	r0, #8
	CALL	malloc
	mov	r3, r0
	str	r3, [sp, #12]
	ldr	r2, [sp, #12]
	movw	r3, #:lower16:_binary_core_exception_fs_start
	movt	r3, #:upper16:_binary_core_exception_fs_start
	str	r3, [r2]
	ldr	r2, [sp, #12]
	movw	r3, #:lower16:_binary_core_exception_fs_end
	movt	r3, #:upper16:_binary_core_exception_fs_end
	str	r3, [r2, #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	ldr	r2, [sp, #12]
	orr	r1, r2, #1
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r3, #4
	add	r3, r2, r3
	str	r1, [r3, #8]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r3, #4
	add	r3, r2, r3
	mov	r2, #0
	str	r2, [r3, #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r2, [r3]
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	mov	r1, #0
	str	r1, [r3, r2, lsl #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r0, [r3]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:parseBuffers
	movt	r3, #:upper16:parseBuffers
	add	r1, r2, r3
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r0, #4
	add	r3, r2, r3
	str	r1, [r3, #12]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	movw	r2, #:lower16:inputIndex
	movt	r2, #:upper16:inputIndex
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
	mov	r0, #8
	CALL	malloc
	mov	r3, r0
	str	r3, [sp, #12]
	ldr	r2, [sp, #12]
	movw	r3, #:lower16:_binary_core_ext_fs_start
	movt	r3, #:upper16:_binary_core_ext_fs_start
	str	r3, [r2]
	ldr	r2, [sp, #12]
	movw	r3, #:lower16:_binary_core_ext_fs_end
	movt	r3, #:upper16:_binary_core_ext_fs_end
	str	r3, [r2, #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	ldr	r2, [sp, #12]
	orr	r1, r2, #1
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r3, #4
	add	r3, r2, r3
	str	r1, [r3, #8]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r3, #4
	add	r3, r2, r3
	mov	r2, #0
	str	r2, [r3, #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r2, [r3]
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	mov	r1, #0
	str	r1, [r3, r2, lsl #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r0, [r3]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:parseBuffers
	movt	r3, #:upper16:parseBuffers
	add	r1, r2, r3
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r0, #4
	add	r3, r2, r3
	str	r1, [r3, #12]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	movw	r2, #:lower16:inputIndex
	movt	r2, #:upper16:inputIndex
	ldr	r2, [r2]
	add	r2, r2, #1
	str	r2, [r3]
	mov	r0, #8
	CALL	malloc
	mov	r3, r0
	str	r3, [sp, #12]
	ldr	r2, [sp, #12]
	movw	r3, #:lower16:_binary_core_core_fs_start
	movt	r3, #:upper16:_binary_core_core_fs_start
	str	r3, [r2]
	ldr	r2, [sp, #12]
	movw	r3, #:lower16:_binary_core_core_fs_end
	movt	r3, #:upper16:_binary_core_core_fs_end
	str	r3, [r2, #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	ldr	r2, [sp, #12]
	orr	r1, r2, #1
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r3, #4
	add	r3, r2, r3
	str	r1, [r3, #8]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r3, #4
	add	r3, r2, r3
	mov	r2, #0
	str	r2, [r3, #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r2, [r3]
	movw	r3, #:lower16:inputSources
	movt	r3, #:upper16:inputSources
	mov	r1, #0
	str	r1, [r3, r2, lsl #4]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r0, [r3]
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:parseBuffers
	movt	r3, #:upper16:parseBuffers
	add	r1, r2, r3
	movw	r2, #:lower16:inputSources
	movt	r2, #:upper16:inputSources
	lsl	r3, r0, #4
	add	r3, r2, r3
	str	r1, [r3, #12]
	bl	init_primitives
	bl	init_superinstructions
	bl	quit_
	mov	r3, #0
	mov	r0, r3
	add	sp, sp, #16
	@ sp needed
	pop	{r4, pc}
	.size	main, .-main
	.align	2
	.global	init_primitives
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	init_primitives, %function
init_primitives:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
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
	INIT_WORD dictionary_info
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
	INIT_WORD call_
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
	nop
	bx	lr
	.size	init_primitives, .-init_primitives
	.align	2
	.global	code_superinstruction_from_r_from_r
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_from_r_from_r, %function
code_superinstruction_from_r_from_r:
        movw    r3, #:lower16:rsp
        movt    r3, #:upper16:rsp
        ldr     r4, [r3]
	ldmia     r4!, {r1, r2}
        str     r4, [r3]
        mov     r0, r2
        push    {r0, r1}
        NEXT
	.size	code_superinstruction_from_r_from_r, .-code_superinstruction_from_r_from_r
	.align	2
	.global	code_superinstruction_fetch_exit
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_fetch_exit, %function
code_superinstruction_fetch_exit:
	ldr     r0, [sp]
        ldr     r0, [r0]
        str     r0, [sp]
        EXIT_NEXT
	.size	code_superinstruction_fetch_exit, .-code_superinstruction_fetch_exit
	.align	2
	.global	code_superinstruction_swap_to_r
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_swap_to_r, %function
code_superinstruction_swap_to_r:
        pop     {r0, r1}
        PUSHRSP r1, r2, r3
        push    {r0}
        NEXT
	.size	code_superinstruction_swap_to_r, .-code_superinstruction_swap_to_r
	.align	2
	.global	code_superinstruction_to_r_swap
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_to_r_swap, %function
code_superinstruction_to_r_swap:
        pop     {r0, r1, r2}
        PUSHRSP r0, r3, r4
        mov     r3, r1
        push    {r2, r3}
        NEXT
	.size	code_superinstruction_to_r_swap, .-code_superinstruction_to_r_swap
	.align	2
	.global	code_superinstruction_to_r_exit
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_to_r_exit, %function
code_superinstruction_to_r_exit:
	pop     {r0}
        PUSHRSP r0, r1, r2
        EXIT_NEXT
	.size	code_superinstruction_to_r_exit, .-code_superinstruction_to_r_exit
	.align	2
	.global	code_superinstruction_from_r_dup
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_from_r_dup, %function
code_superinstruction_from_r_dup:
        POPRSP  r0, r1, r2
        mov     r1, r0
        push    {r0, r1}
        NEXT
	.size	code_superinstruction_from_r_dup, .-code_superinstruction_from_r_dup
	.align	2
	.global	code_superinstruction_dolit_equal
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_dolit_equal, %function
code_superinstruction_dolit_equal:
        ldr     r0, [r11], #4
        ldr     r1, [sp]
	mov	r3, #0
        cmp     r0, r1
        subeq   r3, r3, #1
	str	r3, [sp]
	NEXT
	.size	code_superinstruction_dolit_equal, .-code_superinstruction_dolit_equal
	.align	2
	.global	code_superinstruction_dolit_fetch
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_dolit_fetch, %function
code_superinstruction_dolit_fetch:
        ldr     r0, [r11], #4
        ldr     r0, [r0]
        push    {r0}
        NEXT
	.size	code_superinstruction_dolit_fetch, .-code_superinstruction_dolit_fetch
	.align	2
	.global	code_superinstruction_dup_to_r
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_dup_to_r, %function
code_superinstruction_dup_to_r:
        ldr     r0, [sp]
        PUSHRSP r0, r1, r2
        NEXT
	.size	code_superinstruction_dup_to_r, .-code_superinstruction_dup_to_r
	.align	2
	.global	code_superinstruction_dolit_dolit
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_dolit_dolit, %function
code_superinstruction_dolit_dolit:
        ldr     r1, [r11], #4
        ldr     r0, [r11], #4
        push    {r0, r1}
	NEXT
	.size	code_superinstruction_dolit_dolit, .-code_superinstruction_dolit_dolit
	.align	2
	.global	code_superinstruction_plus_exit
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_plus_exit, %function
code_superinstruction_plus_exit:
        pop     {r0, r1}
        add     r0, r0, r1
        push    {r0}
        EXIT_NEXT
	.size	code_superinstruction_plus_exit, .-code_superinstruction_plus_exit
	.align	2
	.global	code_superinstruction_dolit_plus
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_dolit_plus, %function
code_superinstruction_dolit_plus:
        ldr     r0, [sp]
        ldr     r1, [r11], #4
        add     r0, r0, r1
        str     r0, [sp]
        NEXT
	.size	code_superinstruction_dolit_plus, .-code_superinstruction_dolit_plus
	.align	2
	.global	code_superinstruction_dolit_less_than
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_dolit_less_than, %function
code_superinstruction_dolit_less_than:
        ldr     r0, [sp]
        ldr     r1, [r11], #4
        cmp     r0, r1
	bge	.L380
	mvn	r3, #0
	b	.L381
.L380:
	mov	r3, #0
.L381:
	str	r3, [sp]
	NEXT
	.size	code_superinstruction_dolit_less_than, .-code_superinstruction_dolit_less_than
	.align	2
	.global	code_superinstruction_plus_fetch
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_plus_fetch, %function
code_superinstruction_plus_fetch:
        pop     {r0, r1}
        add     r0, r0, r1
        ldr     r0, [r0]
        push    {r0}
        NEXT
	.size	code_superinstruction_plus_fetch, .-code_superinstruction_plus_fetch
	.align	2
	.global	code_superinstruction_to_r_to_r
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_to_r_to_r, %function
code_superinstruction_to_r_to_r:
        pop     {r0, r1}
        PUSHRSP r0, r2, r3
        PUSHRSP r1, r2, r3
	NEXT
	.size	code_superinstruction_to_r_to_r, .-code_superinstruction_to_r_to_r
	.align	2
	.global	code_superinstruction_dolit_call_
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_dolit_call_, %function
code_superinstruction_dolit_call_:
        ldr     r0, [r11], #4
        push    {r0}
        CALL_NEXT
	.size	code_superinstruction_dolit_call_, .-code_superinstruction_dolit_call_
	.align	2
	.global	code_superinstruction_equal_exit
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_equal_exit, %function
code_superinstruction_equal_exit:
        pop     {r0, r1}
        mov     r3, #0
        cmp     r0, r1
        mvneq   r3, #0
        push    {r3}
        EXIT_NEXT
	.size	code_superinstruction_equal_exit, .-code_superinstruction_equal_exit
	.align	2
	.global	code_superinstruction_to_r_swap_from_r
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_to_r_swap_from_r, %function
code_superinstruction_to_r_swap_from_r:
        ldr     r0, [sp, #4]
        ldr     r1, [sp, #8]
        str     r1, [sp, #4]
        str     r0, [sp, #8]
	NEXT
	.size	code_superinstruction_to_r_swap_from_r, .-code_superinstruction_to_r_swap_from_r
	.align	2
	.global	code_superinstruction_swap_to_r_exit
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_swap_to_r_exit, %function
code_superinstruction_swap_to_r_exit:
        pop     {r0, r1}
        PUSHRSP r1, r2, r3
        push    {r0}
        EXIT_NEXT
	.size	code_superinstruction_swap_to_r_exit, .-code_superinstruction_swap_to_r_exit
	.align	2
	.global	code_superinstruction_from_r_from_r_dup
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_from_r_from_r_dup, %function
code_superinstruction_from_r_from_r_dup:
        POPRSP  r2, r4, r3
        POPRSP  r1, r4, r3
        mov     r0, r1
        push    {r0, r1, r2}
	NEXT
	.size	code_superinstruction_from_r_from_r_dup, .-code_superinstruction_from_r_from_r_dup
	.align	2
	.global	code_superinstruction_dup_to_r_swap
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_dup_to_r_swap, %function
code_superinstruction_dup_to_r_swap:
        pop     {r0, r1}
        PUSHRSP r0, r2, r3
        mov     r2, r0
        push    {r1, r2}
        NEXT
	.size	code_superinstruction_dup_to_r_swap, .-code_superinstruction_dup_to_r_swap
	.align	2
	.global	code_superinstruction_from_r_dup_to_r
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_from_r_dup_to_r, %function
code_superinstruction_from_r_dup_to_r:
	movw	r3, #:lower16:rsp
	movt	r3, #:upper16:rsp
	ldr	r3, [r3]
	ldr	r3, [r3]
        push    {r3}
	NEXT
	.size	code_superinstruction_from_r_dup_to_r, .-code_superinstruction_from_r_dup_to_r
	.align	2
	.global	code_superinstruction_dolit_fetch_exit
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_dolit_fetch_exit, %function
code_superinstruction_dolit_fetch_exit:
        ldr     r0, [r11], #4
        ldr     r0, [r0]
        push    {r0}
        EXIT_NEXT
	.size	code_superinstruction_dolit_fetch_exit, .-code_superinstruction_dolit_fetch_exit
	.align	2
	.global	code_superinstruction_dolit_plus_exit
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_dolit_plus_exit, %function
code_superinstruction_dolit_plus_exit:
        ldr     r0, [sp]
        ldr     r1, [r11], #4
        add     r1, r1, r0
        str     r1, [sp]
        EXIT_NEXT
	.size	code_superinstruction_dolit_plus_exit, .-code_superinstruction_dolit_plus_exit
	.align	2
	.global	code_superinstruction_dolit_less_than_exit
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_dolit_less_than_exit, %function
code_superinstruction_dolit_less_than_exit:
        ldr     r0, [sp]
        ldr     r1, [r11], #4
        mov     r3, #0
        cmp     r0, r1
        mvnlt   r3, #0
        str     r3, [sp]
        EXIT_NEXT
	.size	code_superinstruction_dolit_less_than_exit, .-code_superinstruction_dolit_less_than_exit
	.align	2
	.global	code_superinstruction_dolit_dolit_plus
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_dolit_dolit_plus, %function
code_superinstruction_dolit_dolit_plus:
        ldr     r0, [r11], #4
        ldr     r1, [r11], #4
        add     r0, r0, r1
        push    {r0}
	NEXT
	.size	code_superinstruction_dolit_dolit_plus, .-code_superinstruction_dolit_dolit_plus
	.align	2
	.global	code_superinstruction_cells_sp_fetch_plus
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_cells_sp_fetch_plus, %function
code_superinstruction_cells_sp_fetch_plus:
        mov     r1, sp
        pop     {r0}
        lsl     r0, r0, #2
        add     r0, r0, r1
        push    {r0}
        NEXT
	.size	code_superinstruction_cells_sp_fetch_plus, .-code_superinstruction_cells_sp_fetch_plus
	.align	2
	.global	code_superinstruction_to_r_swap_to_r
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_to_r_swap_to_r, %function
code_superinstruction_to_r_swap_to_r:
        @ ( 2 1 0 -- 1   R: -- 0 2 )
        pop     {r0, r1, r2}
        push    {r1}
        PUSHRSP r0, r3, r4
        PUSHRSP r2, r3, r4
        NEXT
	.size	code_superinstruction_to_r_swap_to_r, .-code_superinstruction_to_r_swap_to_r
	.align	2
	.global	code_superinstruction_dolit_equal_exit
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_dolit_equal_exit, %function
code_superinstruction_dolit_equal_exit:
        ldr     r0, [sp]
        ldr     r1, [r11], #4
        mov     r3, #0
        cmp r0, r1
        mvneq   r3, #0
        str     r3, [sp]
        EXIT_NEXT
	.size	code_superinstruction_dolit_equal_exit, .-code_superinstruction_dolit_equal_exit
	.align	2
	.global	code_superinstruction_sp_fetch_plus_fetch
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_sp_fetch_plus_fetch, %function
code_superinstruction_sp_fetch_plus_fetch:
        ldr     r0, [sp]
        add     r0, r0, sp
        ldr     r0, [r0]
        str     r0, [sp, #4]
        add     sp, sp, #4
        NEXT
	.size	code_superinstruction_sp_fetch_plus_fetch, .-code_superinstruction_sp_fetch_plus_fetch
	.align	2
	.global	code_superinstruction_plus_fetch_exit
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_plus_fetch_exit, %function
code_superinstruction_plus_fetch_exit:
        pop     {r0, r1}
        add     r0, r0, r1
        ldr     r0, [r0]
        push    {r0}
        EXIT_NEXT
	.size	code_superinstruction_plus_fetch_exit, .-code_superinstruction_plus_fetch_exit
	.align	2
	.global	code_superinstruction_from_r_from_r_two_dup
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_from_r_from_r_two_dup, %function
code_superinstruction_from_r_from_r_two_dup:
        POPRSP  r1, r2, r3
        POPRSP  r0, r2, r3
        mov     r2, r0
        mov     r3, r1
        push    {r0, r1, r2, r3}
        NEXT
	.size	code_superinstruction_from_r_from_r_two_dup, .-code_superinstruction_from_r_from_r_two_dup
	.align	2
	.global	code_superinstruction_neg_rot_plus_to_r
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_neg_rot_plus_to_r, %function
code_superinstruction_neg_rot_plus_to_r:
        @ ( 2 1 0 -- 0    R: -- 1+2 )
        pop     {r0, r1, r2}
        push    {r0}
        add     r1, r1, r2
        PUSHRSP r1, r2, r3
        NEXT
	.size	code_superinstruction_neg_rot_plus_to_r, .-code_superinstruction_neg_rot_plus_to_r
	.align	2
	.global	code_superinstruction_two_dup_minus_to_r
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_two_dup_minus_to_r, %function
code_superinstruction_two_dup_minus_to_r:
        ldr     r0, [sp]
        ldr     r1, [sp, #4]
        sub     r1, r1, r0
        PUSHRSP r1, r2, r3
        NEXT
	.size	code_superinstruction_two_dup_minus_to_r, .-code_superinstruction_two_dup_minus_to_r
	.align	2
	.global	code_superinstruction_to_r_swap_to_r_exit
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_to_r_swap_to_r_exit, %function
code_superinstruction_to_r_swap_to_r_exit:
        @ ( 2 1 0 -- 1     R: -- 0 2 )
        pop     {r0, r1, r2}
        push    {r1}
        PUSHRSP r0, r3, r4
        PUSHRSP r2, r3, r4
        EXIT_NEXT
	.size	code_superinstruction_to_r_swap_to_r_exit, .-code_superinstruction_to_r_swap_to_r_exit
	.align	2
	.global	code_superinstruction_dup_to_r_swap_to_r
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_dup_to_r_swap_to_r, %function
code_superinstruction_dup_to_r_swap_to_r:
        @ ( 1 0 -- 0    R: 0 1 )
        pop     {r0, r1}
        push    {r0}
        PUSHRSP r0, r2, r3
        PUSHRSP r1, r2, r3
        NEXT
	.size	code_superinstruction_dup_to_r_swap_to_r, .-code_superinstruction_dup_to_r_swap_to_r
	.align	2
	.global	code_superinstruction_from_r_dup_to_r_swap
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_from_r_dup_to_r_swap, %function
code_superinstruction_from_r_dup_to_r_swap:
        @ ( 0 -- 1 0      R: 1 -- 1 )
	movw	r3, #:lower16:rsp
	movt	r3, #:upper16:rsp
	ldr	r3, [r3]
	ldr	r3, [r3]
        pop     {r0}
        push    {r0, r3}
	NEXT
	.size	code_superinstruction_from_r_dup_to_r_swap, .-code_superinstruction_from_r_dup_to_r_swap
	.align	2
	.global	code_superinstruction_from_r_from_r_dup_to_r
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_from_r_from_r_dup_to_r, %function
code_superinstruction_from_r_from_r_dup_to_r:
        POPRSP  r3, r1, r2
	movw	r0, #:lower16:rsp
	movt	r0, #:upper16:rsp
	ldr	r0, [r0]
	ldr	r0, [r0]
        push    {r0, r3}
        NEXT
	.size	code_superinstruction_from_r_from_r_dup_to_r, .-code_superinstruction_from_r_from_r_dup_to_r
	.align	2
	.global	code_superinstruction_cells_sp_fetch_plus_fetch
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_cells_sp_fetch_plus_fetch, %function
code_superinstruction_cells_sp_fetch_plus_fetch:
        mov     r1, sp
        pop     {r0}
        lsl     r0, r0, #2
        add     r0, r0, r1
        ldr     r0, [r0]
        push    {r0}
        NEXT
	.size	code_superinstruction_cells_sp_fetch_plus_fetch, .-code_superinstruction_cells_sp_fetch_plus_fetch
	.align	2
	.global	code_superinstruction_two_dup_minus_to_r_dolit
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_two_dup_minus_to_r_dolit, %function
code_superinstruction_two_dup_minus_to_r_dolit:
        ldr     r0, [sp]
        ldr     r1, [sp, #4]
        sub     r1, r1, r0
        PUSHRSP r1, r2, r3
        ldr     r0, [r11], #4
        push    {r0}
        NEXT
	.size	code_superinstruction_two_dup_minus_to_r_dolit, .-code_superinstruction_two_dup_minus_to_r_dolit
	.align	2
	.global	code_superinstruction_from_r_two_dup_minus_to_r
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_from_r_two_dup_minus_to_r, %function
code_superinstruction_from_r_two_dup_minus_to_r:
        @ ( 2 -- 2 1   R: 1 -- 2-1 )
        ldr     r2, [sp]
        POPRSP  r1, r3, r4
        sub     r0, r2, r1
        PUSHRSP r0, r3, r4
        push    {r1}
        NEXT
	.size	code_superinstruction_from_r_two_dup_minus_to_r, .-code_superinstruction_from_r_two_dup_minus_to_r
	.align	2
	.global	code_superinstruction_from_r_from_r_two_dup_minus
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_superinstruction_from_r_from_r_two_dup_minus, %function
code_superinstruction_from_r_from_r_two_dup_minus:
        POPRSP  r2, r4, r3
        POPRSP  r1, r4, r3
        sub     r0, r2, r1
        push    {r0, r1, r2}
        NEXT
	.size	code_superinstruction_from_r_from_r_two_dup_minus, .-code_superinstruction_from_r_from_r_two_dup_minus
	.align	2
	.global	init_superinstructions
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	init_superinstructions, %function
init_superinstructions:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	mov	r2, #0
	str	r2, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_from_r
	movt	r3, #:upper16:key_from_r
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_from_r
	movt	r3, #:upper16:key_from_r
	ldr	r3, [r3]
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_from_r_from_r
	movt	r2, #:upper16:code_superinstruction_from_r_from_r
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_exit
	movt	r3, #:upper16:key_exit
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_fetch
	movt	r3, #:upper16:key_fetch
	ldr	r3, [r3]
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_fetch_exit
	movt	r2, #:upper16:code_superinstruction_fetch_exit
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_swap
	movt	r3, #:upper16:key_swap
	ldr	r3, [r3]
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_swap_to_r
	movt	r2, #:upper16:code_superinstruction_swap_to_r
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_swap
	movt	r3, #:upper16:key_swap
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_to_r_swap
	movt	r2, #:upper16:code_superinstruction_to_r_swap
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_exit
	movt	r3, #:upper16:key_exit
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_to_r_exit
	movt	r2, #:upper16:code_superinstruction_to_r_exit
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_dup
	movt	r3, #:upper16:key_dup
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_from_r
	movt	r3, #:upper16:key_from_r
	ldr	r3, [r3]
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_from_r_dup
	movt	r2, #:upper16:code_superinstruction_from_r_dup
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_equal
	movt	r3, #:upper16:key_equal
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_dolit
	movt	r3, #:upper16:key_dolit
	ldr	r3, [r3]
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_dolit_equal
	movt	r2, #:upper16:code_superinstruction_dolit_equal
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_fetch
	movt	r3, #:upper16:key_fetch
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_dolit
	movt	r3, #:upper16:key_dolit
	ldr	r3, [r3]
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_dolit_fetch
	movt	r2, #:upper16:code_superinstruction_dolit_fetch
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_dup
	movt	r3, #:upper16:key_dup
	ldr	r3, [r3]
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_dup_to_r
	movt	r2, #:upper16:code_superinstruction_dup_to_r
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_dolit
	movt	r3, #:upper16:key_dolit
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_dolit
	movt	r3, #:upper16:key_dolit
	ldr	r3, [r3]
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_dolit_dolit
	movt	r2, #:upper16:code_superinstruction_dolit_dolit
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_exit
	movt	r3, #:upper16:key_exit
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_plus
	movt	r3, #:upper16:key_plus
	ldr	r3, [r3]
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_plus_exit
	movt	r2, #:upper16:code_superinstruction_plus_exit
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_plus
	movt	r3, #:upper16:key_plus
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_dolit
	movt	r3, #:upper16:key_dolit
	ldr	r3, [r3]
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_dolit_plus
	movt	r2, #:upper16:code_superinstruction_dolit_plus
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_less_than
	movt	r3, #:upper16:key_less_than
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_dolit
	movt	r3, #:upper16:key_dolit
	ldr	r3, [r3]
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_dolit_less_than
	movt	r2, #:upper16:code_superinstruction_dolit_less_than
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_fetch
	movt	r3, #:upper16:key_fetch
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_plus
	movt	r3, #:upper16:key_plus
	ldr	r3, [r3]
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_plus_fetch
	movt	r2, #:upper16:code_superinstruction_plus_fetch
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_to_r_to_r
	movt	r2, #:upper16:code_superinstruction_to_r_to_r
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_call_
	movt	r3, #:upper16:key_call_
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_dolit
	movt	r3, #:upper16:key_dolit
	ldr	r3, [r3]
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_dolit_call_
	movt	r2, #:upper16:code_superinstruction_dolit_call_
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_exit
	movt	r3, #:upper16:key_exit
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_equal
	movt	r3, #:upper16:key_equal
	ldr	r3, [r3]
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_equal_exit
	movt	r2, #:upper16:code_superinstruction_equal_exit
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_swap
	movt	r3, #:upper16:key_swap
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_from_r
	movt	r3, #:upper16:key_from_r
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_to_r_swap_from_r
	movt	r2, #:upper16:code_superinstruction_to_r_swap_from_r
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_swap
	movt	r3, #:upper16:key_swap
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_exit
	movt	r3, #:upper16:key_exit
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_swap_to_r_exit
	movt	r2, #:upper16:code_superinstruction_swap_to_r_exit
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_from_r
	movt	r3, #:upper16:key_from_r
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_from_r
	movt	r3, #:upper16:key_from_r
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_dup
	movt	r3, #:upper16:key_dup
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_from_r_from_r_dup
	movt	r2, #:upper16:code_superinstruction_from_r_from_r_dup
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_dup
	movt	r3, #:upper16:key_dup
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_swap
	movt	r3, #:upper16:key_swap
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_dup_to_r_swap
	movt	r2, #:upper16:code_superinstruction_dup_to_r_swap
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_sp_fetch
	movt	r3, #:upper16:key_sp_fetch
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_cells
	movt	r3, #:upper16:key_cells
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_plus
	movt	r3, #:upper16:key_plus
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_cells_sp_fetch_plus
	movt	r2, #:upper16:code_superinstruction_cells_sp_fetch_plus
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_swap
	movt	r3, #:upper16:key_swap
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_to_r_swap_to_r
	movt	r2, #:upper16:code_superinstruction_to_r_swap_to_r
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_equal
	movt	r3, #:upper16:key_equal
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_dolit
	movt	r3, #:upper16:key_dolit
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_exit
	movt	r3, #:upper16:key_exit
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_dolit_equal_exit
	movt	r2, #:upper16:code_superinstruction_dolit_equal_exit
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_dup
	movt	r3, #:upper16:key_dup
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_from_r
	movt	r3, #:upper16:key_from_r
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_from_r_dup_to_r
	movt	r2, #:upper16:code_superinstruction_from_r_dup_to_r
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_plus
	movt	r3, #:upper16:key_plus
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_dolit
	movt	r3, #:upper16:key_dolit
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_exit
	movt	r3, #:upper16:key_exit
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_dolit_plus_exit
	movt	r2, #:upper16:code_superinstruction_dolit_plus_exit
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_less_than
	movt	r3, #:upper16:key_less_than
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_dolit
	movt	r3, #:upper16:key_dolit
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_exit
	movt	r3, #:upper16:key_exit
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_dolit_less_than_exit
	movt	r2, #:upper16:code_superinstruction_dolit_less_than_exit
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_plus
	movt	r3, #:upper16:key_plus
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_sp_fetch
	movt	r3, #:upper16:key_sp_fetch
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_fetch
	movt	r3, #:upper16:key_fetch
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_sp_fetch_plus_fetch
	movt	r2, #:upper16:code_superinstruction_sp_fetch_plus_fetch
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_fetch
	movt	r3, #:upper16:key_fetch
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_plus
	movt	r3, #:upper16:key_plus
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_exit
	movt	r3, #:upper16:key_exit
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_plus_fetch_exit
	movt	r2, #:upper16:code_superinstruction_plus_fetch_exit
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_from_r
	movt	r3, #:upper16:key_from_r
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_from_r
	movt	r3, #:upper16:key_from_r
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_two_dup
	movt	r3, #:upper16:key_two_dup
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_from_r_from_r_two_dup
	movt	r2, #:upper16:code_superinstruction_from_r_from_r_two_dup
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_plus
	movt	r3, #:upper16:key_plus
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_neg_rot
	movt	r3, #:upper16:key_neg_rot
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_neg_rot_plus_to_r
	movt	r2, #:upper16:code_superinstruction_neg_rot_plus_to_r
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_minus
	movt	r3, #:upper16:key_minus
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_two_dup
	movt	r3, #:upper16:key_two_dup
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_two_dup_minus_to_r
	movt	r2, #:upper16:code_superinstruction_two_dup_minus_to_r
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_swap
	movt	r3, #:upper16:key_swap
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r2, r2, r3
	movw	r3, #:lower16:key_exit
	movt	r3, #:upper16:key_exit
	ldr	r3, [r3]
	lsl	r3, r3, #24
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_to_r_swap_to_r_exit
	movt	r2, #:upper16:code_superinstruction_to_r_swap_to_r_exit
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_dup
	movt	r3, #:upper16:key_dup
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_swap
	movt	r3, #:upper16:key_swap
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r2, r2, r3
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	lsl	r3, r3, #24
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_dup_to_r_swap_to_r
	movt	r2, #:upper16:code_superinstruction_dup_to_r_swap_to_r
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_dup
	movt	r3, #:upper16:key_dup
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_from_r
	movt	r3, #:upper16:key_from_r
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r2, r2, r3
	movw	r3, #:lower16:key_swap
	movt	r3, #:upper16:key_swap
	ldr	r3, [r3]
	lsl	r3, r3, #24
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_from_r_dup_to_r_swap
	movt	r2, #:upper16:code_superinstruction_from_r_dup_to_r_swap
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_from_r
	movt	r3, #:upper16:key_from_r
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_from_r
	movt	r3, #:upper16:key_from_r
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_dup
	movt	r3, #:upper16:key_dup
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r2, r2, r3
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	lsl	r3, r3, #24
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_from_r_from_r_dup_to_r
	movt	r2, #:upper16:code_superinstruction_from_r_from_r_dup_to_r
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_sp_fetch
	movt	r3, #:upper16:key_sp_fetch
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_cells
	movt	r3, #:upper16:key_cells
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_plus
	movt	r3, #:upper16:key_plus
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r2, r2, r3
	movw	r3, #:lower16:key_fetch
	movt	r3, #:upper16:key_fetch
	ldr	r3, [r3]
	lsl	r3, r3, #24
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_cells_sp_fetch_plus_fetch
	movt	r2, #:upper16:code_superinstruction_cells_sp_fetch_plus_fetch
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_minus
	movt	r3, #:upper16:key_minus
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_two_dup
	movt	r3, #:upper16:key_two_dup
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r2, r2, r3
	movw	r3, #:lower16:key_dolit
	movt	r3, #:upper16:key_dolit
	ldr	r3, [r3]
	lsl	r3, r3, #24
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_two_dup_minus_to_r_dolit
	movt	r2, #:upper16:code_superinstruction_two_dup_minus_to_r_dolit
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_two_dup
	movt	r3, #:upper16:key_two_dup
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_from_r
	movt	r3, #:upper16:key_from_r
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_minus
	movt	r3, #:upper16:key_minus
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r2, r2, r3
	movw	r3, #:lower16:key_to_r
	movt	r3, #:upper16:key_to_r
	ldr	r3, [r3]
	lsl	r3, r3, #24
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_from_r_two_dup_minus_to_r
	movt	r2, #:upper16:code_superinstruction_from_r_two_dup_minus_to_r
	str	r2, [r3, r1, lsl #3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r0, [r3]
	movw	r3, #:lower16:key_from_r
	movt	r3, #:upper16:key_from_r
	ldr	r3, [r3]
	lsl	r2, r3, #8
	movw	r3, #:lower16:key_from_r
	movt	r3, #:upper16:key_from_r
	ldr	r3, [r3]
	orr	r2, r2, r3
	movw	r3, #:lower16:key_two_dup
	movt	r3, #:upper16:key_two_dup
	ldr	r3, [r3]
	lsl	r3, r3, #16
	orr	r2, r2, r3
	movw	r3, #:lower16:key_minus
	movt	r3, #:upper16:key_minus
	ldr	r3, [r3]
	lsl	r3, r3, #24
	orr	r1, r2, r3
	movw	r2, #:lower16:superinstructions
	movt	r2, #:upper16:superinstructions
	lsl	r3, r0, #3
	add	r3, r2, r3
	str	r1, [r3, #4]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	ldr	r1, [r3]
	movw	r3, #:lower16:nextSuperinstruction
	movt	r3, #:upper16:nextSuperinstruction
	add	r2, r1, #1
	str	r2, [r3]
	movw	r3, #:lower16:superinstructions
	movt	r3, #:upper16:superinstructions
	movw	r2, #:lower16:code_superinstruction_from_r_from_r_two_dup_minus
	movt	r2, #:upper16:code_superinstruction_from_r_from_r_two_dup_minus
	str	r2, [r3, r1, lsl #3]
	nop
	bx	lr
	.size	init_superinstructions, .-init_superinstructions
	.ident	"GCC: (GNU) 6.1.1 20160602"
	.section	.note.GNU-stack,"",%progbits
