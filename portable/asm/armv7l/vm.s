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
	.comm	searchOrder,64,4 @ An array of 16 pointers to word entries
	.comm	currentDictionary,4,4 @ Pointer to the current one
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
	.global	header_plus
	.section	.rodata
	.align	2
.LC1:
	.ascii	"+\000"
	.data
	.align	2
	.type	header_plus, %object
	.size	header_plus, 16
header_plus:
	.word	0
	.word	1
	.word	.LC1
	.word	code_plus
	.global	key_plus
	.align	2
	.type	key_plus, %object
	.size	key_plus, 4
key_plus:
	.word	1
	.text
	.align	2
	.global	code_plus
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_plus, %function
code_plus:
        pop     {r0, r1}
        add     r0, r0, r1
        push    {r0}
        NEXT
	.size	code_plus, .-code_plus
	.global	header_minus
	.section	.rodata
	.align	2
.LC2:
	.ascii	"-\000"
	.data
	.align	2
	.type	header_minus, %object
	.size	header_minus, 16
header_minus:
	.word	header_plus
	.word	1
	.word	.LC2
	.word	code_minus
	.global	key_minus
	.align	2
	.type	key_minus, %object
	.size	key_minus, 4
key_minus:
	.word	2
	.text
	.align	2
	.global	code_minus
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_minus, %function
code_minus:
        pop     {r0, r1}
        sub     r0, r1, r0
        push    {r0}
	NEXT
	.size	code_minus, .-code_minus
WORD_HDR times, "*", 1, 3, header_minus
	pop     {r1, r3}
	mul	r3, r3, r1
        push    {r3}
	NEXT
WORD_TAIL times
	.global	header_div
	.section	.rodata
	.align	2
.LC4:
	.ascii	"/\000"
	.data
	.align	2
	.type	header_div, %object
	.size	header_div, 16
header_div:
	.word	header_times
	.word	1
	.word	.LC4
	.word	code_div
	.global	key_div
	.align	2
	.type	key_div, %object
	.size	key_div, 4
key_div:
	.word	4
	.global	__aeabi_idiv
	.text
	.align	2
	.global	code_div
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_div, %function
code_div:
        pop     {r1, r2}
        mov     r0, r2
	CALL	__aeabi_idiv
        push    {r0}
	NEXT
	.size	code_div, .-code_div
	.global	header_udiv
	.section	.rodata
	.align	2
.LC5:
	.ascii	"U/\000"
	.data
	.align	2
	.type	header_udiv, %object
	.size	header_udiv, 16
header_udiv:
	.word	header_div
	.word	2
	.word	.LC5
	.word	code_udiv
	.global	key_udiv
	.align	2
	.type	key_udiv, %object
	.size	key_udiv, 4
key_udiv:
	.word	5
	.global	__aeabi_uidiv
	.text
	.align	2
	.global	code_udiv
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_udiv, %function
code_udiv:
        pop     {r1, r2}
        mov     r0, r2
        CALL      __aeabi_uidiv
        push    {r0}
	NEXT
	.size	code_udiv, .-code_udiv
	.global	header_mod
	.section	.rodata
	.align	2
.LC6:
	.ascii	"MOD\000"
	.data
	.align	2
	.type	header_mod, %object
	.size	header_mod, 16
header_mod:
	.word	header_udiv
	.word	3
	.word	.LC6
	.word	code_mod
	.global	key_mod
	.align	2
	.type	key_mod, %object
	.size	key_mod, 4
key_mod:
	.word	6
	.global	__aeabi_idivmod
	.text
	.align	2
	.global	code_mod
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_mod, %function
code_mod:
        pop     {r1, r2}
        mov     r0, r2
	CALL	__aeabi_idivmod
        push    {r1}
	NEXT
	.size	code_mod, .-code_mod
	.global	header_umod
	.section	.rodata
	.align	2
.LC7:
	.ascii	"UMOD\000"
	.data
	.align	2
	.type	header_umod, %object
	.size	header_umod, 16
header_umod:
	.word	header_mod
	.word	4
	.word	.LC7
	.word	code_umod
	.global	key_umod
	.align	2
	.type	key_umod, %object
	.size	key_umod, 4
key_umod:
	.word	7
	.global	__aeabi_uidivmod
	.text
	.align	2
	.global	code_umod
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_umod, %function
code_umod:
        pop     {r1, r2}
        mov     r0, r2
	CALL	__aeabi_uidivmod
        push    {r1}
	NEXT
	.size	code_umod, .-code_umod
	.global	header_and
	.section	.rodata
	.align	2
.LC8:
	.ascii	"AND\000"
	.data
	.align	2
	.type	header_and, %object
	.size	header_and, 16
header_and:
	.word	header_umod
	.word	3
	.word	.LC8
	.word	code_and
	.global	key_and
	.align	2
	.type	key_and, %object
	.size	key_and, 4
key_and:
	.word	8
	.text
	.align	2
	.global	code_and
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_and, %function
code_and:
        pop     {r0, r1}
        and     r0, r0, r1
        push    {r0}
	NEXT
	.size	code_and, .-code_and
	.global	header_or
	.section	.rodata
	.align	2
.LC9:
	.ascii	"OR\000"
	.data
	.align	2
	.type	header_or, %object
	.size	header_or, 16
header_or:
	.word	header_and
	.word	2
	.word	.LC9
	.word	code_or
	.global	key_or
	.align	2
	.type	key_or, %object
	.size	key_or, 4
key_or:
	.word	9
	.text
	.align	2
	.global	code_or
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_or, %function
code_or:
        pop     {r0, r1}
        orr     r0, r0, r1
        push    {r0}
	NEXT
	.size	code_or, .-code_or
	.global	header_xor
	.section	.rodata
	.align	2
.LC10:
	.ascii	"XOR\000"
	.data
	.align	2
	.type	header_xor, %object
	.size	header_xor, 16
header_xor:
	.word	header_or
	.word	3
	.word	.LC10
	.word	code_xor
	.global	key_xor
	.align	2
	.type	key_xor, %object
	.size	key_xor, 4
key_xor:
	.word	10
	.text
	.align	2
	.global	code_xor
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_xor, %function
code_xor:
        pop     {r0, r1}
        eor     r0, r0, r1
        push    {r0}
	NEXT
	.size	code_xor, .-code_xor
	.global	header_lshift
	.section	.rodata
	.align	2
.LC11:
	.ascii	"LSHIFT\000"
	.data
	.align	2
	.type	header_lshift, %object
	.size	header_lshift, 16
header_lshift:
	.word	header_xor
	.word	6
	.word	.LC11
	.word	code_lshift
	.global	key_lshift
	.align	2
	.type	key_lshift, %object
	.size	key_lshift, 4
key_lshift:
	.word	11
	.text
	.align	2
	.global	code_lshift
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_lshift, %function
code_lshift:
	pop     {r0, r1}
	lsl	r1, r1, r0
        push    {r1}
	NEXT
	.size	code_lshift, .-code_lshift
	.global	header_rshift
	.section	.rodata
	.align	2
.LC12:
	.ascii	"RSHIFT\000"
	.data
	.align	2
	.type	header_rshift, %object
	.size	header_rshift, 16
header_rshift:
	.word	header_lshift
	.word	6
	.word	.LC12
	.word	code_rshift
	.global	key_rshift
	.align	2
	.type	key_rshift, %object
	.size	key_rshift, 4
key_rshift:
	.word	12
	.text
	.align	2
	.global	code_rshift
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_rshift, %function
code_rshift:
	pop     {r0, r1}
	lsr	r1, r1, r0
        push    {r1}
	NEXT
	.size	code_rshift, .-code_rshift
	.global	header_base
	.section	.rodata
	.align	2
.LC13:
	.ascii	"BASE\000"
	.data
	.align	2
	.type	header_base, %object
	.size	header_base, 16
header_base:
	.word	header_rshift
	.word	4
	.word	.LC13
	.word	code_base
	.global	key_base
	.align	2
	.type	key_base, %object
	.size	key_base, 4
key_base:
	.word	13
	.text
	.align	2
	.global	code_base
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_base, %function
code_base:
	movw	r3, #:lower16:base
	movt	r3, #:upper16:base
        push    {r3}
	NEXT
	.size	code_base, .-code_base
	.global	header_less_than
	.section	.rodata
	.align	2
.LC14:
	.ascii	"<\000"
	.data
	.align	2
	.type	header_less_than, %object
	.size	header_less_than, 16
header_less_than:
	.word	header_base
	.word	1
	.word	.LC14
	.word	code_less_than
	.global	key_less_than
	.align	2
	.type	key_less_than, %object
	.size	key_less_than, 4
key_less_than:
	.word	14
	.text
	.align	2
	.global	code_less_than
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_less_than, %function
code_less_than:
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
	.size	code_less_than, .-code_less_than
	.global	header_less_than_unsigned
	.section	.rodata
	.align	2
.LC15:
	.ascii	"U<\000"
	.data
	.align	2
	.type	header_less_than_unsigned, %object
	.size	header_less_than_unsigned, 16
header_less_than_unsigned:
	.word	header_less_than
	.word	2
	.word	.LC15
	.word	code_less_than_unsigned
	.global	key_less_than_unsigned
	.align	2
	.type	key_less_than_unsigned, %object
	.size	key_less_than_unsigned, 4
key_less_than_unsigned:
	.word	15
	.text
	.align	2
	.global	code_less_than_unsigned
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_less_than_unsigned, %function
code_less_than_unsigned:
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
	.size	code_less_than_unsigned, .-code_less_than_unsigned
	.global	header_equal
	.section	.rodata
	.align	2
.LC16:
	.ascii	"=\000"
	.data
	.align	2
	.type	header_equal, %object
	.size	header_equal, 16
header_equal:
	.word	header_less_than_unsigned
	.word	1
	.word	.LC16
	.word	code_equal
	.global	key_equal
	.align	2
	.type	key_equal, %object
	.size	key_equal, 4
key_equal:
	.word	16
	.text
	.align	2
	.global	code_equal
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_equal, %function
code_equal:
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
	.size	code_equal, .-code_equal
	.global	header_dup
	.section	.rodata
	.align	2
.LC17:
	.ascii	"DUP\000"
	.data
	.align	2
	.type	header_dup, %object
	.size	header_dup, 16
header_dup:
	.word	header_equal
	.word	3
	.word	.LC17
	.word	code_dup
	.global	key_dup
	.align	2
	.type	key_dup, %object
	.size	key_dup, 4
key_dup:
	.word	17
	.text
	.align	2
	.global	code_dup
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_dup, %function
code_dup:
	ldr     r0, [sp]
        push    {r0}
	NEXT
	.size	code_dup, .-code_dup
	.global	header_swap
	.section	.rodata
	.align	2
.LC18:
	.ascii	"SWAP\000"
	.data
	.align	2
	.type	header_swap, %object
	.size	header_swap, 16
header_swap:
	.word	header_dup
	.word	4
	.word	.LC18
	.word	code_swap
	.global	key_swap
	.align	2
	.type	key_swap, %object
	.size	key_swap, 4
key_swap:
	.word	18
	.text
	.align	2
	.global	code_swap
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_swap, %function
code_swap:
        pop    {r0, r1}
        mov    r2, r0
        push   {r1, r2}
	NEXT
	.size	code_swap, .-code_swap
	.global	header_drop
	.section	.rodata
	.align	2
.LC19:
	.ascii	"DROP\000"
	.data
	.align	2
	.type	header_drop, %object
	.size	header_drop, 16
header_drop:
	.word	header_swap
	.word	4
	.word	.LC19
	.word	code_drop
	.global	key_drop
	.align	2
	.type	key_drop, %object
	.size	key_drop, 4
key_drop:
	.word	19
	.text
	.align	2
	.global	code_drop
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_drop, %function
code_drop:
        add     sp, #4
	NEXT
	.size	code_drop, .-code_drop
	.global	header_over
	.section	.rodata
	.align	2
.LC20:
	.ascii	"OVER\000"
	.data
	.align	2
	.type	header_over, %object
	.size	header_over, 16
header_over:
	.word	header_drop
	.word	4
	.word	.LC20
	.word	code_over
	.global	key_over
	.align	2
	.type	key_over, %object
	.size	key_over, 4
key_over:
	.word	20
	.text
	.align	2
	.global	code_over
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_over, %function
code_over:
        ldr     r0, [sp, #4]
        push    {r0}
	NEXT
	.size	code_over, .-code_over
	.global	header_rot
	.section	.rodata
	.align	2
.LC21:
	.ascii	"ROT\000"
	.data
	.align	2
	.type	header_rot, %object
	.size	header_rot, 16
header_rot:
	.word	header_over
	.word	3
	.word	.LC21
	.word	code_rot
	.global	key_rot
	.align	2
	.type	key_rot, %object
	.size	key_rot, 4
key_rot:
	.word	21
	.text
	.align	2
	.global	code_rot
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_rot, %function
code_rot:
        @ rot = surface, ( r3 r2 r1 -- r2 r1 r0 )
        pop     {r1, r2, r3}
        mov     r0, r3
        push    {r0, r1, r2}
	NEXT
	.size	code_rot, .-code_rot
	.global	header_neg_rot
	.section	.rodata
	.align	2
.LC22:
	.ascii	"-ROT\000"
	.data
	.align	2
	.type	header_neg_rot, %object
	.size	header_neg_rot, 16
header_neg_rot:
	.word	header_rot
	.word	4
	.word	.LC22
	.word	code_neg_rot
	.global	key_neg_rot
	.align	2
	.type	key_neg_rot, %object
	.size	key_neg_rot, 4
key_neg_rot:
	.word	22
	.text
	.align	2
	.global	code_neg_rot
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_neg_rot, %function
code_neg_rot:
        @ -rot = bury, ( r2 r1 r0 -- r3 r2 r1 )
        pop     {r0, r1, r2}
        mov     r3, r0
        push    {r1, r2, r3}
	NEXT
	.size	code_neg_rot, .-code_neg_rot
	.global	header_two_drop
	.section	.rodata
	.align	2
.LC23:
	.ascii	"2DROP\000"
	.data
	.align	2
	.type	header_two_drop, %object
	.size	header_two_drop, 16
header_two_drop:
	.word	header_neg_rot
	.word	5
	.word	.LC23
	.word	code_two_drop
	.global	key_two_drop
	.align	2
	.type	key_two_drop, %object
	.size	key_two_drop, 4
key_two_drop:
	.word	23
	.text
	.align	2
	.global	code_two_drop
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_two_drop, %function
code_two_drop:
	add    sp, #8
        NEXT
	.size	code_two_drop, .-code_two_drop
	.global	header_two_dup
	.section	.rodata
	.align	2
.LC24:
	.ascii	"2DUP\000"
	.data
	.align	2
	.type	header_two_dup, %object
	.size	header_two_dup, 16
header_two_dup:
	.word	header_two_drop
	.word	4
	.word	.LC24
	.word	code_two_dup
	.global	key_two_dup
	.align	2
	.type	key_two_dup, %object
	.size	key_two_dup, 4
key_two_dup:
	.word	24
	.text
	.align	2
	.global	code_two_dup
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_two_dup, %function
code_two_dup:
        ldr     r0, [sp]
        ldr     r1, [sp, #4]
        push    {r0, r1}
	NEXT
	.size	code_two_dup, .-code_two_dup
	.global	header_two_swap
	.section	.rodata
	.align	2
.LC25:
	.ascii	"2SWAP\000"
	.data
	.align	2
	.type	header_two_swap, %object
	.size	header_two_swap, 16
header_two_swap:
	.word	header_two_dup
	.word	5
	.word	.LC25
	.word	code_two_swap
	.global	key_two_swap
	.align	2
	.type	key_two_swap, %object
	.size	key_two_swap, 4
key_two_swap:
	.word	25
	.text
	.align	2
	.global	code_two_swap
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_two_swap, %function
code_two_swap:
        @ ( r6 r5 r4 r3 -- r4 r3 r2 r1 )
        pop     {r3, r4, r5, r6}
        mov     r2, r6
        mov     r1, r5
        push    {r1, r2, r3, r4}
	NEXT
	.size	code_two_swap, .-code_two_swap
	.global	header_two_over
	.section	.rodata
	.align	2
.LC26:
	.ascii	"2OVER\000"
	.data
	.align	2
	.type	header_two_over, %object
	.size	header_two_over, 16
header_two_over:
	.word	header_two_swap
	.word	5
	.word	.LC26
	.word	code_two_over
	.global	key_two_over
	.align	2
	.type	key_two_over, %object
	.size	key_two_over, 4
key_two_over:
	.word	26
	.text
	.align	2
	.global	code_two_over
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_two_over, %function
code_two_over:
        ldr     r0, [sp, #8]
        ldr     r1, [sp, #12]
        push    {r0, r1}
	NEXT
	.size	code_two_over, .-code_two_over
	.global	header_to_r
	.section	.rodata
	.align	2
.LC27:
	.ascii	">R\000"
	.data
	.align	2
	.type	header_to_r, %object
	.size	header_to_r, 16
header_to_r:
	.word	header_two_over
	.word	2
	.word	.LC27
	.word	code_to_r
	.global	key_to_r
	.align	2
	.type	key_to_r, %object
	.size	key_to_r, 4
key_to_r:
	.word	27
	.text
	.align	2
	.global	code_to_r
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_to_r, %function
code_to_r:
        pop    {r0}
        PUSHRSP r0, r1, r2
        NEXT
	.size	code_to_r, .-code_to_r
	.global	header_from_r
	.section	.rodata
	.align	2
.LC28:
	.ascii	"R>\000"
	.data
	.align	2
	.type	header_from_r, %object
	.size	header_from_r, 16
header_from_r:
	.word	header_to_r
	.word	2
	.word	.LC28
	.word	code_from_r
	.global	key_from_r
	.align	2
	.type	key_from_r, %object
	.size	key_from_r, 4
key_from_r:
	.word	28
	.text
	.align	2
	.global	code_from_r
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_from_r, %function
code_from_r:
        POPRSP  r0, r1, r2
        push {r0}
        NEXT
	.size	code_from_r, .-code_from_r
	.global	header_fetch
	.section	.rodata
	.align	2
.LC29:
	.ascii	"@\000"
	.data
	.align	2
	.type	header_fetch, %object
	.size	header_fetch, 16
header_fetch:
	.word	header_from_r
	.word	1
	.word	.LC29
	.word	code_fetch
	.global	key_fetch
	.align	2
	.type	key_fetch, %object
	.size	key_fetch, 4
key_fetch:
	.word	29
	.text
	.align	2
	.global	code_fetch
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_fetch, %function
code_fetch:
	pop     {r0}
        ldr     r0, [r0]
        push    {r0}
	NEXT
	.size	code_fetch, .-code_fetch
	.global	header_store
	.section	.rodata
	.align	2
.LC30:
	.ascii	"!\000"
	.data
	.align	2
	.type	header_store, %object
	.size	header_store, 16
header_store:
	.word	header_fetch
	.word	1
	.word	.LC30
	.word	code_store
	.global	key_store
	.align	2
	.type	key_store, %object
	.size	key_store, 4
key_store:
	.word	30
	.text
	.align	2
	.global	code_store
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_store, %function
code_store:
	pop     {r0, r1}
        str     r1, [r0]
	NEXT
	.size	code_store, .-code_store
	.global	header_cfetch
	.section	.rodata
	.align	2
.LC31:
	.ascii	"C@\000"
	.data
	.align	2
	.type	header_cfetch, %object
	.size	header_cfetch, 16
header_cfetch:
	.word	header_store
	.word	2
	.word	.LC31
	.word	code_cfetch
	.global	key_cfetch
	.align	2
	.type	key_cfetch, %object
	.size	key_cfetch, 4
key_cfetch:
	.word	31
	.text
	.align	2
	.global	code_cfetch
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_cfetch, %function
code_cfetch:
	pop     {r0}
        ldrb    r0, [r0]
        push    {r0}
	NEXT
	.size	code_cfetch, .-code_cfetch
	.global	header_cstore
	.section	.rodata
	.align	2
.LC32:
	.ascii	"C!\000"
	.data
	.align	2
	.type	header_cstore, %object
	.size	header_cstore, 16
header_cstore:
	.word	header_cfetch
	.word	2
	.word	.LC32
	.word	code_cstore
	.global	key_cstore
	.align	2
	.type	key_cstore, %object
	.size	key_cstore, 4
key_cstore:
	.word	32
	.text
	.align	2
	.global	code_cstore
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_cstore, %function
code_cstore:
	pop     {r0, r1}
        strb    r1, [r0]
        NEXT
	.size	code_cstore, .-code_cstore
	.global	header_raw_alloc
	.section	.rodata
	.align	2
.LC33:
	.ascii	"(ALLOCATE)\000"
	.data
	.align	2
	.type	header_raw_alloc, %object
	.size	header_raw_alloc, 16
header_raw_alloc:
	.word	header_cstore
	.word	10
	.word	.LC33
	.word	code_raw_alloc
	.global	key_raw_alloc
	.align	2
	.type	key_raw_alloc, %object
	.size	key_raw_alloc, 4
key_raw_alloc:
	.word	33
	.text
	.align	2
	.global	code_raw_alloc
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_raw_alloc, %function
code_raw_alloc:
        pop     {r0}
	CALL	malloc
        push    {r0}
	NEXT
	.size	code_raw_alloc, .-code_raw_alloc
	.global	header_here_ptr
	.section	.rodata
	.align	2
.LC34:
	.ascii	"(>HERE)\000"
	.data
	.align	2
	.type	header_here_ptr, %object
	.size	header_here_ptr, 16
header_here_ptr:
	.word	header_raw_alloc
	.word	7
	.word	.LC34
	.word	code_here_ptr
	.global	key_here_ptr
	.align	2
	.type	key_here_ptr, %object
	.size	key_here_ptr, 4
key_here_ptr:
	.word	34
	.text
	.align	2
	.global	code_here_ptr
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_here_ptr, %function
code_here_ptr:
	movw	r3, #:lower16:dsp
	movt	r3, #:upper16:dsp
        push    {r3}
	NEXT
	.size	code_here_ptr, .-code_here_ptr
	.global	header_print_internal
	.section	.rodata
	.align	2
.LC35:
	.ascii	"(PRINT)\000"
	.data
	.align	2
	.type	header_print_internal, %object
	.size	header_print_internal, 16
header_print_internal:
	.word	header_here_ptr
	.word	7
	.word	.LC35
	.word	code_print_internal
	.global	key_print_internal
	.align	2
	.type	key_print_internal, %object
	.size	key_print_internal, 4
key_print_internal:
	.word	35
	.section	.rodata
	.align	2
.LC36:
	.ascii	"%d \000"
	.text
	.align	2
	.global	code_print_internal
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_print_internal, %function
code_print_internal:
	pop    	{r1}
	movw	r0, #:lower16:.LC36
	movt	r0, #:upper16:.LC36
	CALL	printf
	NEXT
	.size	code_print_internal, .-code_print_internal
	.global	header_state
	.section	.rodata
	.align	2
.LC37:
	.ascii	"STATE\000"
	.data
	.align	2
	.type	header_state, %object
	.size	header_state, 16
header_state:
	.word	header_print_internal
	.word	5
	.word	.LC37
	.word	code_state
	.global	key_state
	.align	2
	.type	key_state, %object
	.size	key_state, 4
key_state:
	.word	36
	.text
	.align	2
	.global	code_state
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_state, %function
code_state:
	movw	r3, #:lower16:state
	movt	r3, #:upper16:state
        push    {r3}
	NEXT
	.size	code_state, .-code_state
	.global	header_branch
	.section	.rodata
	.align	2
.LC38:
	.ascii	"(BRANCH)\000"
	.data
	.align	2
	.type	header_branch, %object
	.size	header_branch, 16
header_branch:
	.word	header_state
	.word	8
	.word	.LC38
	.word	code_branch
	.global	key_branch
	.align	2
	.type	key_branch, %object
	.size	key_branch, 4
key_branch:
	.word	37
	.text
	.align	2
	.global	code_branch
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_branch, %function
code_branch:
        ldr     r0, [r11]
        add     r11, r11, r0
	NEXT
	.size	code_branch, .-code_branch
	.global	header_zbranch
	.section	.rodata
	.align	2
.LC39:
	.ascii	"(0BRANCH)\000"
	.data
	.align	2
	.type	header_zbranch, %object
	.size	header_zbranch, 16
header_zbranch:
	.word	header_branch
	.word	9
	.word	.LC39
	.word	code_zbranch
	.global	key_zbranch
	.align	2
	.type	key_zbranch, %object
	.size	key_zbranch, 4
key_zbranch:
	.word	38
	.text
	.align	2
	.global	code_zbranch
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_zbranch, %function
code_zbranch:
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
	.size	code_zbranch, .-code_zbranch
	.global	header_execute
	.section	.rodata
	.align	2
.LC40:
	.ascii	"EXECUTE\000"
	.data
	.align	2
	.type	header_execute, %object
	.size	header_execute, 16
header_execute:
	.word	header_zbranch
	.word	7
	.word	.LC40
	.word	code_execute
	.global	key_execute
	.align	2
	.type	key_execute, %object
	.size	key_execute, 4
key_execute:
	.word	39
	.text
	.align	2
	.global	code_execute
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_execute, %function
code_execute:
        pop     {r2}
	movw	r3, #:lower16:cfa
	movt	r3, #:upper16:cfa
	str	r2, [r3]
        ldr     r2, [r2]
	movw	r3, #:lower16:ca
	movt	r3, #:upper16:ca
	str	r2, [r3]
	bx	r2
	.size	code_execute, .-code_execute
	.global	header_evaluate
	.section	.rodata
	.align	2
.LC41:
	.ascii	"EVALUATE\000"
	.data
	.align	2
	.type	header_evaluate, %object
	.size	header_evaluate, 16
header_evaluate:
	.word	header_execute
	.word	8
	.word	.LC41
	.word	code_evaluate
	.global	key_evaluate
	.align	2
	.type	key_evaluate, %object
	.size	key_evaluate, 4
key_evaluate:
	.word	40
	.text
	.align	2
	.global	code_evaluate
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_evaluate, %function
code_evaluate:
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
	.size	code_evaluate, .-code_evaluate
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
	.global	header_refill
	.section	.rodata
	.align	2
.LC43:
	.ascii	"REFILL\000"
	.data
	.align	2
	.type	header_refill, %object
	.size	header_refill, 16
header_refill:
	.word	header_evaluate
	.word	6
	.word	.LC43
	.word	code_refill
	.global	key_refill
	.align	2
	.type	key_refill, %object
	.size	key_refill, 4
key_refill:
	.word	41
	.text
	.align	2
	.global	code_refill
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_refill, %function
code_refill:
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
	.size	code_refill, .-code_refill
	.global	header_accept
	.section	.rodata
	.align	2
.LC44:
	.ascii	"ACCEPT\000"
	.data
	.align	2
	.type	header_accept, %object
	.size	header_accept, 16
header_accept:
	.word	header_refill
	.word	6
	.word	.LC44
	.word	code_accept
	.global	key_accept
	.align	2
	.type	key_accept, %object
	.size	key_accept, 4
key_accept:
	.word	42
	.text
	.align	2
	.global	code_accept
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_accept, %function
code_accept:
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
	.size	code_accept, .-code_accept
	.global	header_key
	.section	.rodata
	.align	2
.LC45:
	.ascii	"KEY\000"
	.data
	.align	2
	.type	header_key, %object
	.size	header_key, 16
header_key:
	.word	header_accept
	.word	3
	.word	.LC45
	.word	code_key
	.global	key_key
	.align	2
	.type	key_key, %object
	.size	key_key, 4
key_key:
	.word	43
	.text
	.align	2
	.global	code_key
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_key, %function
code_key:
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
	.size	code_key, .-code_key
	.global	header_latest
	.section	.rodata
	.align	2
.LC46:
	.ascii	"(LATEST)\000"
	.data
	.align	2
	.type	header_latest, %object
	.size	header_latest, 16
header_latest:
	.word	header_key
	.word	8
	.word	.LC46
	.word	code_latest
	.global	key_latest
	.align	2
	.type	key_latest, %object
	.size	key_latest, 4
key_latest:
	.word	44
	.text
	.align	2
	.global	code_latest
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_latest, %function
code_latest:
	movw	r3, #:lower16:currentDictionary
	movt	r3, #:upper16:currentDictionary
        ldr     r3, [r3]
        push    {r3}
	NEXT
	.size	code_latest, .-code_latest
WORD_HDR dictionary_info, "(DICT-INFO)", 11, 117, header_latest
	movw	r3, #:lower16:currentDictionary
	movt	r3, #:upper16:currentDictionary
	movw	r2, #:lower16:searchOrder
	movt	r2, #:upper16:searchOrder
        push    {r2, r3}
        NEXT
WORD_TAIL dictionary_info
	.global	header_in_ptr
	.section	.rodata
	.align	2
.LC47:
	.ascii	">IN\000"
	.data
	.align	2
	.type	header_in_ptr, %object
	.size	header_in_ptr, 16
header_in_ptr:
	.word	header_dictionary_info
	.word	3
	.word	.LC47
	.word	code_in_ptr
	.global	key_in_ptr
	.align	2
	.type	key_in_ptr, %object
	.size	key_in_ptr, 4
key_in_ptr:
	.word	45
	.text
	.align	2
	.global	code_in_ptr
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_in_ptr, %function
code_in_ptr:
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
	.size	code_in_ptr, .-code_in_ptr
	.global	header_emit
	.section	.rodata
	.align	2
.LC48:
	.ascii	"EMIT\000"
	.data
	.align	2
	.type	header_emit, %object
	.size	header_emit, 16
header_emit:
	.word	header_in_ptr
	.word	4
	.word	.LC48
	.word	code_emit
	.global	key_emit
	.align	2
	.type	key_emit, %object
	.size	key_emit, 4
key_emit:
	.word	46
	.text
	.align	2
	.global	code_emit
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_emit, %function
code_emit:
        pop     {r0}
	movw	r3, #:lower16:stdout
	movt	r3, #:upper16:stdout
	ldr	r1, [r3]
	CALL	fputc
	NEXT
	.size	code_emit, .-code_emit
	.global	header_source
	.section	.rodata
	.align	2
.LC49:
	.ascii	"SOURCE\000"
	.data
	.align	2
	.type	header_source, %object
	.size	header_source, 16
header_source:
	.word	header_emit
	.word	6
	.word	.LC49
	.word	code_source
	.global	key_source
	.align	2
	.type	key_source, %object
	.size	key_source, 4
key_source:
	.word	47
	.text
	.align	2
	.global	code_source
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_source, %function
code_source:
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
	.size	code_source, .-code_source
	.global	header_source_id
	.section	.rodata
	.align	2
.LC50:
	.ascii	"SOURCE-ID\000"
	.data
	.align	2
	.type	header_source_id, %object
	.size	header_source_id, 16
header_source_id:
	.word	header_source
	.word	9
	.word	.LC50
	.word	code_source_id
	.global	key_source_id
	.align	2
	.type	key_source_id, %object
	.size	key_source_id, 4
key_source_id:
	.word	48
	.text
	.align	2
	.global	code_source_id
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_source_id, %function
code_source_id:
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
	.size	code_source_id, .-code_source_id
	.global	header_size_cell
	.section	.rodata
	.align	2
.LC51:
	.ascii	"(/CELL)\000"
	.data
	.align	2
	.type	header_size_cell, %object
	.size	header_size_cell, 16
header_size_cell:
	.word	header_source_id
	.word	7
	.word	.LC51
	.word	code_size_cell
	.global	key_size_cell
	.align	2
	.type	key_size_cell, %object
	.size	key_size_cell, 4
key_size_cell:
	.word	49
	.text
	.align	2
	.global	code_size_cell
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_size_cell, %function
code_size_cell:
	mov r0, #4
        push {r0}
        NEXT
	.size	code_size_cell, .-code_size_cell
	.global	header_size_char
	.section	.rodata
	.align	2
.LC52:
	.ascii	"(/CHAR)\000"
	.data
	.align	2
	.type	header_size_char, %object
	.size	header_size_char, 16
header_size_char:
	.word	header_size_cell
	.word	7
	.word	.LC52
	.word	code_size_char
	.global	key_size_char
	.align	2
	.type	key_size_char, %object
	.size	key_size_char, 4
key_size_char:
	.word	50
	.text
	.align	2
	.global	code_size_char
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_size_char, %function
code_size_char:
        mov     r0, #1
        push    {r0}
        NEXT
	.size	code_size_char, .-code_size_char
	.global	header_cells
	.section	.rodata
	.align	2
.LC53:
	.ascii	"CELLS\000"
	.data
	.align	2
	.type	header_cells, %object
	.size	header_cells, 16
header_cells:
	.word	header_size_char
	.word	5
	.word	.LC53
	.word	code_cells
	.global	key_cells
	.align	2
	.type	key_cells, %object
	.size	key_cells, 4
key_cells:
	.word	51
	.text
	.align	2
	.global	code_cells
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_cells, %function
code_cells:
        pop     {r0}
        lsl     r0, r0, #2
        push    {r0}
	NEXT
	.size	code_cells, .-code_cells
	.global	header_chars
	.section	.rodata
	.align	2
.LC54:
	.ascii	"CHARS\000"
	.data
	.align	2
	.type	header_chars, %object
	.size	header_chars, 16
header_chars:
	.word	header_cells
	.word	5
	.word	.LC54
	.word	code_chars
	.global	key_chars
	.align	2
	.type	key_chars, %object
	.size	key_chars, 4
key_chars:
	.word	52
	.text
	.align	2
	.global	code_chars
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_chars, %function
code_chars:
	NEXT
	.size	code_chars, .-code_chars
	.global	header_unit_bits
	.section	.rodata
	.align	2
.LC55:
	.ascii	"(ADDRESS-UNIT-BITS)\000"
	.data
	.align	2
	.type	header_unit_bits, %object
	.size	header_unit_bits, 16
header_unit_bits:
	.word	header_chars
	.word	19
	.word	.LC55
	.word	code_unit_bits
	.global	key_unit_bits
	.align	2
	.type	key_unit_bits, %object
	.size	key_unit_bits, 4
key_unit_bits:
	.word	53
	.text
	.align	2
	.global	code_unit_bits
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_unit_bits, %function
code_unit_bits:
        mov     r0, #8
        push    {r0}
	NEXT
	.size	code_unit_bits, .-code_unit_bits
	.global	header_stack_cells
	.section	.rodata
	.align	2
.LC56:
	.ascii	"(STACK-CELLS)\000"
	.data
	.align	2
	.type	header_stack_cells, %object
	.size	header_stack_cells, 16
header_stack_cells:
	.word	header_unit_bits
	.word	13
	.word	.LC56
	.word	code_stack_cells
	.global	key_stack_cells
	.align	2
	.type	key_stack_cells, %object
	.size	key_stack_cells, 4
key_stack_cells:
	.word	54
	.text
	.align	2
	.global	code_stack_cells
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_stack_cells, %function
code_stack_cells:
	mov	r2, #16384
        push    {r2}
	NEXT
	.size	code_stack_cells, .-code_stack_cells
	.global	header_return_stack_cells
	.section	.rodata
	.align	2
.LC57:
	.ascii	"(RETURN-STACK-CELLS)\000"
	.data
	.align	2
	.type	header_return_stack_cells, %object
	.size	header_return_stack_cells, 16
header_return_stack_cells:
	.word	header_stack_cells
	.word	20
	.word	.LC57
	.word	code_return_stack_cells
	.global	key_return_stack_cells
	.align	2
	.type	key_return_stack_cells, %object
	.size	key_return_stack_cells, 4
key_return_stack_cells:
	.word	55
	.text
	.align	2
	.global	code_return_stack_cells
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_return_stack_cells, %function
code_return_stack_cells:
	mov	r2, #1024
        push    {r2}
        NEXT
	.size	code_return_stack_cells, .-code_return_stack_cells
	.global	header_to_does
	.section	.rodata
	.align	2
.LC58:
	.ascii	"(>DOES)\000"
	.data
	.align	2
	.type	header_to_does, %object
	.size	header_to_does, 16
header_to_does:
	.word	header_return_stack_cells
	.word	7
	.word	.LC58
	.word	code_to_does
	.global	key_to_does
	.align	2
	.type	key_to_does, %object
	.size	key_to_does, 4
key_to_does:
	.word	56
	.text
	.align	2
	.global	code_to_does
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_to_does, %function
code_to_does:
        pop     {r0}
        add     r0, r0, #16
        push    {r0}
        NEXT
	.size	code_to_does, .-code_to_does
	.global	header_to_cfa
	.section	.rodata
	.align	2
.LC59:
	.ascii	"(>CFA)\000"
	.data
	.align	2
	.type	header_to_cfa, %object
	.size	header_to_cfa, 16
header_to_cfa:
	.word	header_to_does
	.word	6
	.word	.LC59
	.word	code_to_cfa
	.global	key_to_cfa
	.align	2
	.type	key_to_cfa, %object
	.size	key_to_cfa, 4
key_to_cfa:
	.word	57
	.text
	.align	2
	.global	code_to_cfa
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_to_cfa, %function
code_to_cfa:
        pop     {r0}
        ldr     r0, [r0]
        add     r0, r0, #12
        push    {r0}
	NEXT
	.size	code_to_cfa, .-code_to_cfa
	.global	header_to_body
	.section	.rodata
	.align	2
.LC60:
	.ascii	">BODY\000"
	.data
	.align	2
	.type	header_to_body, %object
	.size	header_to_body, 16
header_to_body:
	.word	header_to_cfa
	.word	5
	.word	.LC60
	.word	code_to_body
	.global	key_to_body
	.align	2
	.type	key_to_body, %object
	.size	key_to_body, 4
key_to_body:
	.word	58
	.text
	.align	2
	.global	code_to_body
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_to_body, %function
code_to_body:
        pop     {r0}
        add     r0, r0, #8
        push    {r0}
	NEXT
	.size	code_to_body, .-code_to_body
	.global	header_last_word
	.section	.rodata
	.align	2
.LC61:
	.ascii	"(LAST-WORD)\000"
	.data
	.align	2
	.type	header_last_word, %object
	.size	header_last_word, 16
header_last_word:
	.word	header_to_body
	.word	11
	.word	.LC61
	.word	code_last_word
	.global	key_last_word
	.align	2
	.type	key_last_word, %object
	.size	key_last_word, 4
key_last_word:
	.word	59
	.text
	.align	2
	.global	code_last_word
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_last_word, %function
code_last_word:
	movw	r3, #:lower16:lastWord
	movt	r3, #:upper16:lastWord
	ldr	r3, [r3]
        push    {r3}
	NEXT
	.size	code_last_word, .-code_last_word
	.global	header_docol
	.section	.rodata
	.align	2
.LC62:
	.ascii	"(DOCOL)\000"
	.data
	.align	2
	.type	header_docol, %object
	.size	header_docol, 16
header_docol:
	.word	header_last_word
	.word	7
	.word	.LC62
	.word	code_docol
	.global	key_docol
	.align	2
	.type	key_docol, %object
	.size	key_docol, 4
key_docol:
	.word	60
	.text
	.align	2
	.global	code_docol
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_docol, %function
code_docol:
        PUSHRSP r11, r0, r1
	movw	r3, #:lower16:cfa
	movt	r3, #:upper16:cfa
	ldr	r3, [r3]
	add	r11, r3, #4
	NEXT
	.size	code_docol, .-code_docol
	.global	header_dolit
	.section	.rodata
	.align	2
.LC63:
	.ascii	"(DOLIT)\000"
	.data
	.align	2
	.type	header_dolit, %object
	.size	header_dolit, 16
header_dolit:
	.word	header_docol
	.word	7
	.word	.LC63
	.word	code_dolit
	.global	key_dolit
	.align	2
	.type	key_dolit, %object
	.size	key_dolit, 4
key_dolit:
	.word	61
	.text
	.align	2
	.global	code_dolit
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_dolit, %function
code_dolit:
        ldr     r0, [r11]
        add     r11, r11, #4
        push    {r0}
        NEXT
	.size	code_dolit, .-code_dolit
	.global	header_dostring
	.section	.rodata
	.align	2
.LC64:
	.ascii	"(DOSTRING)\000"
	.data
	.align	2
	.type	header_dostring, %object
	.size	header_dostring, 16
header_dostring:
	.word	header_dolit
	.word	10
	.word	.LC64
	.word	code_dostring
	.global	key_dostring
	.align	2
	.type	key_dostring, %object
	.size	key_dostring, 4
key_dostring:
	.word	62
	.text
	.align	2
	.global	code_dostring
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_dostring, %function
code_dostring:
        ldrb    r0, [r11]
        add     r1, r11, #1
        push    {r0, r1}
        add     r0, r0, #4   @ + 1 + 3 for alignment
        add     r11, r11, r0
        and     r11, #-4       @ Aligning to a word.
	NEXT
	.size	code_dostring, .-code_dostring
	.global	header_dodoes
	.section	.rodata
	.align	2
.LC65:
	.ascii	"(DODOES)\000"
	.data
	.align	2
	.type	header_dodoes, %object
	.size	header_dodoes, 16
header_dodoes:
	.word	header_dostring
	.word	8
	.word	.LC65
	.word	code_dodoes
	.global	key_dodoes
	.align	2
	.type	key_dodoes, %object
	.size	key_dodoes, 4
key_dodoes:
	.word	63
	.text
	.align	2
	.global	code_dodoes
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_dodoes, %function
code_dodoes:
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
	.size	code_dodoes, .-code_dodoes
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
	movw	r6, #:lower16:currentDictionary
	movt	r6, #:upper16:currentDictionary
	ldr	r6, [r6]
	b	.LF150
.LF159:
	ldr	r2, [r6]
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
	movw	r3, #:lower16:searchOrder
	movt	r3, #:upper16:searchOrder
	cmp	r6, r3
	beq	.LF160
        sub     r6, r6, #4
.LF150:
	cmp	r6, #0
	bne	.LF159
	b	.LF158
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
	.global	header_parse
	.section	.rodata
	.align	2
.LC66:
	.ascii	"PARSE\000"
	.data
	.align	2
	.type	header_parse, %object
	.size	header_parse, 16
header_parse:
	.word	header_dodoes
	.word	5
	.word	.LC66
	.word	code_parse
	.global	key_parse
	.align	2
	.type	key_parse, %object
	.size	key_parse, 4
key_parse:
	.word	64
	.text
	.align	2
	.global	code_parse
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_parse, %function
code_parse:
	bl	parse_
	NEXT
	.size	code_parse, .-code_parse
	.global	header_parse_name
	.section	.rodata
	.align	2
.LC67:
	.ascii	"PARSE-NAME\000"
	.data
	.align	2
	.type	header_parse_name, %object
	.size	header_parse_name, 16
header_parse_name:
	.word	header_parse
	.word	10
	.word	.LC67
	.word	code_parse_name
	.global	key_parse_name
	.align	2
	.type	key_parse_name, %object
	.size	key_parse_name, 4
key_parse_name:
	.word	65
	.text
	.align	2
	.global	code_parse_name
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_parse_name, %function
code_parse_name:
	bl	parse_name_
	NEXT
	.size	code_parse_name, .-code_parse_name
	.global	header_to_number
	.section	.rodata
	.align	2
.LC68:
	.ascii	">NUMBER\000"
	.data
	.align	2
	.type	header_to_number, %object
	.size	header_to_number, 16
header_to_number:
	.word	header_parse_name
	.word	7
	.word	.LC68
	.word	code_to_number
	.global	key_to_number
	.align	2
	.type	key_to_number, %object
	.size	key_to_number, 4
key_to_number:
	.word	66
	.text
	.align	2
	.global	code_to_number
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_to_number, %function
code_to_number:
	bl	to_number_
	NEXT
	.size	code_to_number, .-code_to_number
	.global	header_create
	.section	.rodata
	.align	2
.LC69:
	.ascii	"CREATE\000"
	.data
	.align	2
	.type	header_create, %object
	.size	header_create, 16
header_create:
	.word	header_to_number
	.word	6
	.word	.LC69
	.word	code_create
	.global	key_create
	.align	2
	.type	key_create, %object
	.size	key_create, 4
key_create:
	.word	67
	.text
	.align	2
	.global	code_create
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_create, %function
code_create:
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
	movw	r3, #:lower16:currentDictionary
	movt	r3, #:upper16:currentDictionary
	ldr	r3, [r3]
	ldr	r3, [r3]
	str	r3, [r2]
	movw	r3, #:lower16:currentDictionary
	movt	r3, #:upper16:currentDictionary
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
	.size	code_create, .-code_create
	.global	header_find
	.section	.rodata
	.align	2
.LC70:
	.ascii	"(FIND)\000"
	.data
	.align	2
	.type	header_find, %object
	.size	header_find, 16
header_find:
	.word	header_create
	.word	6
	.word	.LC70
	.word	code_find
	.global	key_find
	.align	2
	.type	key_find, %object
	.size	key_find, 4
key_find:
	.word	68
	.text
	.align	2
	.global	code_find
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_find, %function
code_find:
	bl	find_
	NEXT
	.size	code_find, .-code_find
	.global	header_depth
	.section	.rodata
	.align	2
.LC71:
	.ascii	"DEPTH\000"
	.data
	.align	2
	.type	header_depth, %object
	.size	header_depth, 16
header_depth:
	.word	header_find
	.word	5
	.word	.LC71
	.word	code_depth
	.global	key_depth
	.align	2
	.type	key_depth, %object
	.size	key_depth, 4
key_depth:
	.word	69
	.text
	.align	2
	.global	code_depth
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_depth, %function
code_depth:
	movw	r2, #:lower16:spTop
	movt	r2, #:upper16:spTop
	ldr	r2, [r2]
	sub	r2, r2, sp
	lsr	r2, r2, #2
	push    {r2}
        NEXT
	.size	code_depth, .-code_depth
	.global	header_sp_fetch
	.section	.rodata
	.align	2
.LC72:
	.ascii	"SP@\000"
	.data
	.align	2
	.type	header_sp_fetch, %object
	.size	header_sp_fetch, 16
header_sp_fetch:
	.word	header_depth
	.word	3
	.word	.LC72
	.word	code_sp_fetch
	.global	key_sp_fetch
	.align	2
	.type	key_sp_fetch, %object
	.size	key_sp_fetch, 4
key_sp_fetch:
	.word	70
	.text
	.align	2
	.global	code_sp_fetch
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_sp_fetch, %function
code_sp_fetch:
	mov     r0, sp
        push    {r0}
        NEXT
	.size	code_sp_fetch, .-code_sp_fetch
	.global	header_sp_store
	.section	.rodata
	.align	2
.LC73:
	.ascii	"SP!\000"
	.data
	.align	2
	.type	header_sp_store, %object
	.size	header_sp_store, 16
header_sp_store:
	.word	header_sp_fetch
	.word	3
	.word	.LC73
	.word	code_sp_store
	.global	key_sp_store
	.align	2
	.type	key_sp_store, %object
	.size	key_sp_store, 4
key_sp_store:
	.word	71
	.text
	.align	2
	.global	code_sp_store
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_sp_store, %function
code_sp_store:
	pop     {r0}
        mov     sp, r0
        NEXT
	.size	code_sp_store, .-code_sp_store
	.global	header_rp_fetch
	.section	.rodata
	.align	2
.LC74:
	.ascii	"RP@\000"
	.data
	.align	2
	.type	header_rp_fetch, %object
	.size	header_rp_fetch, 16
header_rp_fetch:
	.word	header_sp_store
	.word	3
	.word	.LC74
	.word	code_rp_fetch
	.global	key_rp_fetch
	.align	2
	.type	key_rp_fetch, %object
	.size	key_rp_fetch, 4
key_rp_fetch:
	.word	72
	.text
	.align	2
	.global	code_rp_fetch
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_rp_fetch, %function
code_rp_fetch:
	movw	r3, #:lower16:rsp
	movt	r3, #:upper16:rsp
	ldr	r3, [r3]
        push    {r3}
	NEXT
	.size	code_rp_fetch, .-code_rp_fetch
	.global	header_rp_store
	.section	.rodata
	.align	2
.LC75:
	.ascii	"RP!\000"
	.data
	.align	2
	.type	header_rp_store, %object
	.size	header_rp_store, 16
header_rp_store:
	.word	header_rp_fetch
	.word	3
	.word	.LC75
	.word	code_rp_store
	.global	key_rp_store
	.align	2
	.type	key_rp_store, %object
	.size	key_rp_store, 4
key_rp_store:
	.word	73
	.text
	.align	2
	.global	code_rp_store
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_rp_store, %function
code_rp_store:
	movw	r3, #:lower16:rsp
	movt	r3, #:upper16:rsp
        pop     {r2}
	str	r2, [r3]
	NEXT
	.size	code_rp_store, .-code_rp_store
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
	.global	header_dot_s
	.section	.rodata
	.align	2
.LC77:
	.ascii	".S\000"
	.data
	.align	2
	.type	header_dot_s, %object
	.size	header_dot_s, 16
header_dot_s:
	.word	header_rp_store
	.word	2
	.word	.LC77
	.word	code_dot_s
	.global	key_dot_s
	.align	2
	.type	key_dot_s, %object
	.size	key_dot_s, 4
key_dot_s:
	.word	74
	.text
	.align	2
	.global	code_dot_s
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_dot_s, %function
code_dot_s:
	bl	dot_s_
	NEXT
	.size	code_dot_s, .-code_dot_s
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
	.global	header_u_dot_s
	.section	.rodata
	.align	2
.LC79:
	.ascii	"U.S\000"
	.data
	.align	2
	.type	header_u_dot_s, %object
	.size	header_u_dot_s, 16
header_u_dot_s:
	.word	header_dot_s
	.word	3
	.word	.LC79
	.word	code_u_dot_s
	.global	key_u_dot_s
	.align	2
	.type	key_u_dot_s, %object
	.size	key_u_dot_s, 4
key_u_dot_s:
	.word	75
	.text
	.align	2
	.global	code_u_dot_s
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_u_dot_s, %function
code_u_dot_s:
	bl	u_dot_s_
	NEXT
	.size	code_u_dot_s, .-code_u_dot_s
	.global	header_dump_file
	.section	.rodata
	.align	2
.LC80:
	.ascii	"(DUMP-FILE)\000"
	.data
	.align	2
	.type	header_dump_file, %object
	.size	header_dump_file, 16
header_dump_file:
	.word	header_u_dot_s
	.word	11
	.word	.LC80
	.word	code_dump_file
	.global	key_dump_file
	.align	2
	.type	key_dump_file, %object
	.size	key_dump_file, 4
key_dump_file:
	.word	76
	.section	.rodata
	.align	2
.LC81:
	.ascii	"wb\000"
	.align	2
.LC82:
	.ascii	"*** Failed to open file for writing: %s\012\000"
	.align	2
.LC83:
	.ascii	"(Dumped %d of %d bytes to %s)\012\000"
	.text
	.align	2
	.global	code_dump_file
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_dump_file, %function
code_dump_file:
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
	.size	code_dump_file, .-code_dump_file
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
	.global	header_quit
	.section	.rodata
	.align	2
.LC87:
	.ascii	"QUIT\000"
	.data
	.align	2
	.type	header_quit, %object
	.size	header_quit, 16
header_quit:
	.word	header_dump_file
	.word	4
	.word	.LC87
	.word	code_quit
	.global	key_quit
	.align	2
	.type	key_quit, %object
	.size	key_quit, 4
key_quit:
	.word	77
	.text
	.align	2
	.global	code_quit
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_quit, %function
code_quit:
	movw	r3, #:lower16:inputIndex
	movt	r3, #:upper16:inputIndex
	mov	r2, #0
	str	r2, [r3]
	bl	quit_
	NEXT
	.size	code_quit, .-code_quit
	.global	header_bye
	.section	.rodata
	.align	2
.LC88:
	.ascii	"BYE\000"
	.data
	.align	2
	.type	header_bye, %object
	.size	header_bye, 16
header_bye:
	.word	header_quit
	.word	3
	.word	.LC88
	.word	code_bye
	.global	key_bye
	.align	2
	.type	key_bye, %object
	.size	key_bye, 4
key_bye:
	.word	78
	.text
	.align	2
	.global	code_bye
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_bye, %function
code_bye:
	mov	r0, #0
	CALL	exit
	.size	code_bye, .-code_bye
	.global	header_compile_comma
	.section	.rodata
	.align	2
.LC89:
	.ascii	"COMPILE,\000"
	.data
	.align	2
	.type	header_compile_comma, %object
	.size	header_compile_comma, 16
header_compile_comma:
	.word	header_bye
	.word	8
	.word	.LC89
	.word	code_compile_comma
	.global	key_compile_comma
	.align	2
	.type	key_compile_comma, %object
	.size	key_compile_comma, 4
key_compile_comma:
	.word	79
	.text
	.align	2
	.global	code_compile_comma
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_compile_comma, %function
code_compile_comma:
	bl	compile_
	NEXT
	.size	code_compile_comma, .-code_compile_comma
	.global	header_literal
	.section	.rodata
	.align	2
.LC90:
	.ascii	"LITERAL\000"
	.data
	.align	2
	.type	header_literal, %object
	.size	header_literal, 16
header_literal:
	.word	header_compile_comma
	.word	519
	.word	.LC90
	.word	code_literal
	.global	key_literal
	.align	2
	.type	key_literal, %object
	.size	key_literal, 4
key_literal:
	.word	101
	.text
	.align	2
	.global	code_literal
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_literal, %function
code_literal:
	bl	compile_lit_
	NEXT
	.size	code_literal, .-code_literal
	.global	header_compile_literal
	.section	.rodata
	.align	2
.LC91:
	.ascii	"[LITERAL]\000"
	.data
	.align	2
	.type	header_compile_literal, %object
	.size	header_compile_literal, 16
header_compile_literal:
	.word	header_literal
	.word	9
	.word	.LC91
	.word	code_compile_literal
	.global	key_compile_literal
	.align	2
	.type	key_compile_literal, %object
	.size	key_compile_literal, 4
key_compile_literal:
	.word	102
	.text
	.align	2
	.global	code_compile_literal
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_compile_literal, %function
code_compile_literal:
	bl	compile_lit_
	NEXT
	.size	code_compile_literal, .-code_compile_literal
	.global	header_compile_zbranch
	.section	.rodata
	.align	2
.LC92:
	.ascii	"[0BRANCH]\000"
	.data
	.align	2
	.type	header_compile_zbranch, %object
	.size	header_compile_zbranch, 16
header_compile_zbranch:
	.word	header_compile_literal
	.word	9
	.word	.LC92
	.word	code_compile_zbranch
	.global	key_compile_zbranch
	.align	2
	.type	key_compile_zbranch, %object
	.size	key_compile_zbranch, 4
key_compile_zbranch:
	.word	103
	.text
	.align	2
	.global	code_compile_zbranch
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_compile_zbranch, %function
code_compile_zbranch:
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
	.global	header_compile_branch
	.section	.rodata
	.align	2
.LC93:
	.ascii	"[BRANCH]\000"
	.data
	.align	2
	.type	header_compile_branch, %object
	.size	header_compile_branch, 16
header_compile_branch:
	.word	header_compile_zbranch
	.word	8
	.word	.LC93
	.word	code_compile_branch
	.global	key_compile_branch
	.align	2
	.type	key_compile_branch, %object
	.size	key_compile_branch, 4
key_compile_branch:
	.word	104
	.text
	.align	2
	.global	code_compile_branch
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_compile_branch, %function
code_compile_branch:
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
	.global	header_control_flush
	.section	.rodata
	.align	2
.LC94:
	.ascii	"(CONTROL-FLUSH)\000"
	.data
	.align	2
	.type	header_control_flush, %object
	.size	header_control_flush, 16
header_control_flush:
	.word	header_compile_branch
	.word	15
	.word	.LC94
	.word	code_control_flush
	.global	key_control_flush
	.align	2
	.type	key_control_flush, %object
	.size	key_control_flush, 4
key_control_flush:
	.word	105
	.text
	.align	2
	.global	code_control_flush
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_control_flush, %function
code_control_flush:
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
	.size	code_control_flush, .-code_control_flush
	.global	header_debug_break
	.section	.rodata
	.align	2
.LC95:
	.ascii	"(DEBUG)\000"
	.data
	.align	2
	.type	header_debug_break, %object
	.size	header_debug_break, 16
header_debug_break:
	.word	header_control_flush
	.word	7
	.word	.LC95
	.word	code_debug_break
	.global	key_debug_break
	.align	2
	.type	key_debug_break, %object
	.size	key_debug_break, 4
key_debug_break:
	.word	80
	.text
	.align	2
	.global	code_debug_break
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_debug_break, %function
code_debug_break:
	NEXT
	.size	code_debug_break, .-code_debug_break
	.global	header_close_file
	.section	.rodata
	.align	2
.LC96:
	.ascii	"CLOSE-FILE\000"
	.data
	.align	2
	.type	header_close_file, %object
	.size	header_close_file, 16
header_close_file:
	.word	header_debug_break
	.word	10
	.word	.LC96
	.word	code_close_file
	.global	key_close_file
	.align	2
	.type	key_close_file, %object
	.size	key_close_file, 4
key_close_file:
	.word	81
	.text
	.align	2
	.global	code_close_file
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_close_file, %function
code_close_file:
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
	.size	code_close_file, .-code_close_file
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
	.global	header_create_file
	.section	.rodata
	.align	2
.LC104:
	.ascii	"CREATE-FILE\000"
	.data
	.align	2
	.type	header_create_file, %object
	.size	header_create_file, 16
header_create_file:
	.word	header_close_file
	.word	11
	.word	.LC104
	.word	code_create_file
	.global	key_create_file
	.align	2
	.type	key_create_file, %object
	.size	key_create_file, 4
key_create_file:
	.word	82
	.text
	.align	2
	.global	code_create_file
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_create_file, %function
code_create_file:
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
	.size	code_create_file, .-code_create_file
	.global	header_open_file
	.section	.rodata
	.align	2
.LC105:
	.ascii	"OPEN-FILE\000"
	.data
	.align	2
	.type	header_open_file, %object
	.size	header_open_file, 16
header_open_file:
	.word	header_create_file
	.word	9
	.word	.LC105
	.word	code_open_file
	.global	key_open_file
	.align	2
	.type	key_open_file, %object
	.size	key_open_file, 4
key_open_file:
	.word	83
	.text
	.align	2
	.global	code_open_file
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_open_file, %function
code_open_file:
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
	.size	code_open_file, .-code_open_file
	.global	header_delete_file
	.section	.rodata
	.align	2
.LC106:
	.ascii	"DELETE-FILE\000"
	.data
	.align	2
	.type	header_delete_file, %object
	.size	header_delete_file, 16
header_delete_file:
	.word	header_open_file
	.word	11
	.word	.LC106
	.word	code_delete_file
	.global	key_delete_file
	.align	2
	.type	key_delete_file, %object
	.size	key_delete_file, 4
key_delete_file:
	.word	84
	.text
	.align	2
	.global	code_delete_file
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_delete_file, %function
code_delete_file:
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
	.size	code_delete_file, .-code_delete_file
	.global	header_file_position
	.section	.rodata
	.align	2
.LC107:
	.ascii	"FILE-POSITION\000"
	.data
	.align	2
	.type	header_file_position, %object
	.size	header_file_position, 16
header_file_position:
	.word	header_delete_file
	.word	13
	.word	.LC107
	.word	code_file_position
	.global	key_file_position
	.align	2
	.type	key_file_position, %object
	.size	key_file_position, 4
key_file_position:
	.word	85
	.text
	.align	2
	.global	code_file_position
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_file_position, %function
code_file_position:
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
	.size	code_file_position, .-code_file_position
	.global	header_file_size
	.section	.rodata
	.align	2
.LC108:
	.ascii	"FILE-SIZE\000"
	.data
	.align	2
	.type	header_file_size, %object
	.size	header_file_size, 16
header_file_size:
	.word	header_file_position
	.word	9
	.word	.LC108
	.word	code_file_size
	.global	key_file_size
	.align	2
	.type	key_file_size, %object
	.size	key_file_size, 4
key_file_size:
	.word	86
	.text
	.align	2
	.global	code_file_size
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_file_size, %function
code_file_size:
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
	.size	code_file_size, .-code_file_size
	.global	header_include_file
	.section	.rodata
	.align	2
.LC109:
	.ascii	"INCLUDE-FILE\000"
	.data
	.align	2
	.type	header_include_file, %object
	.size	header_include_file, 16
header_include_file:
	.word	header_file_size
	.word	12
	.word	.LC109
	.word	code_include_file
	.global	key_include_file
	.align	2
	.type	key_include_file, %object
	.size	key_include_file, 4
key_include_file:
	.word	87
	.text
	.align	2
	.global	code_include_file
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_include_file, %function
code_include_file:
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
	.size	code_include_file, .-code_include_file
	.global	header_read_file
	.section	.rodata
	.align	2
.LC110:
	.ascii	"READ-FILE\000"
	.data
	.align	2
	.type	header_read_file, %object
	.size	header_read_file, 16
header_read_file:
	.word	header_include_file
	.word	9
	.word	.LC110
	.word	code_read_file
	.global	key_read_file
	.align	2
	.type	key_read_file, %object
	.size	key_read_file, 4
key_read_file:
	.word	88
	.text
	.align	2
	.global	code_read_file
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_read_file, %function
code_read_file:
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
	.size	code_read_file, .-code_read_file
	.global	header_read_line
	.section	.rodata
	.align	2
.LC111:
	.ascii	"READ-LINE\000"
	.data
	.align	2
	.type	header_read_line, %object
	.size	header_read_line, 16
header_read_line:
	.word	header_read_file
	.word	9
	.word	.LC111
	.word	code_read_line
	.global	key_read_line
	.align	2
	.type	key_read_line, %object
	.size	key_read_line, 4
key_read_line:
	.word	89
	.text
	.align	2
	.global	code_read_line
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_read_line, %function
code_read_line:
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
	.size	code_read_line, .-code_read_line
	.global	header_reposition_file
	.section	.rodata
	.align	2
.LC112:
	.ascii	"REPOSITION-FILE\000"
	.data
	.align	2
	.type	header_reposition_file, %object
	.size	header_reposition_file, 16
header_reposition_file:
	.word	header_read_line
	.word	15
	.word	.LC112
	.word	code_reposition_file
	.global	key_reposition_file
	.align	2
	.type	key_reposition_file, %object
	.size	key_reposition_file, 4
key_reposition_file:
	.word	90
	.text
	.align	2
	.global	code_reposition_file
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_reposition_file, %function
code_reposition_file:
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
	.size	code_reposition_file, .-code_reposition_file
	.global	header_resize_file
	.section	.rodata
	.align	2
.LC113:
	.ascii	"RESIZE-FILE\000"
	.data
	.align	2
	.type	header_resize_file, %object
	.size	header_resize_file, 16
header_resize_file:
	.word	header_reposition_file
	.word	11
	.word	.LC113
	.word	code_resize_file
	.global	key_resize_file
	.align	2
	.type	key_resize_file, %object
	.size	key_resize_file, 4
key_resize_file:
	.word	91
	.text
	.align	2
	.global	code_resize_file
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_resize_file, %function
code_resize_file:
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
	.size	code_resize_file, .-code_resize_file
	.global	header_write_file
	.section	.rodata
	.align	2
.LC114:
	.ascii	"WRITE-FILE\000"
	.data
	.align	2
	.type	header_write_file, %object
	.size	header_write_file, 16
header_write_file:
	.word	header_resize_file
	.word	10
	.word	.LC114
	.word	code_write_file
	.global	key_write_file
	.align	2
	.type	key_write_file, %object
	.size	key_write_file, 4
key_write_file:
	.word	92
	.text
	.align	2
	.global	code_write_file
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_write_file, %function
code_write_file:
        pop     {r3, r4, r5}
        mov     r0, r5
        mov     r1, #1
        mov     r2, r4
        CALL      fwrite
        mov     r0, #0
        push    {r0}
        NEXT
	.size	code_write_file, .-code_write_file
	.global	header_write_line
	.section	.rodata
	.align	2
.LC115:
	.ascii	"WRITE-LINE\000"
	.data
	.align	2
	.type	header_write_line, %object
	.size	header_write_line, 16
header_write_line:
	.word	header_write_file
	.word	10
	.word	.LC115
	.word	code_write_line
	.global	key_write_line
	.align	2
	.type	key_write_line, %object
	.size	key_write_line, 4
key_write_line:
	.word	93
	.text
	.align	2
	.global	code_write_line
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_write_line, %function
code_write_line:
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
	.size	code_write_line, .-code_write_line
	.global	header_flush_file
	.section	.rodata
	.align	2
.LC116:
	.ascii	"FLUSH-FILE\000"
	.data
	.align	2
	.type	header_flush_file, %object
	.size	header_flush_file, 16
header_flush_file:
	.word	header_write_line
	.word	10
	.word	.LC116
	.word	code_flush_file
	.global	key_flush_file
	.align	2
	.type	key_flush_file, %object
	.size	key_flush_file, 4
key_flush_file:
	.word	94
	.text
	.align	2
	.global	code_flush_file
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_flush_file, %function
code_flush_file:
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
	.size	code_flush_file, .-code_flush_file
	.global	header_colon
	.section	.rodata
	.align	2
.LC117:
	.ascii	":\000"
	.data
	.align	2
	.type	header_colon, %object
	.size	header_colon, 16
header_colon:
	.word	header_flush_file
	.word	1
	.word	.LC117
	.word	code_colon
	.global	key_colon
	.align	2
	.type	key_colon, %object
	.size	key_colon, 4
key_colon:
	.word	95
	.section	.rodata
	.align	2
.LC118:
	.ascii	"*** Colon definition with no name\012\000"
	.text
	.align	2
	.global	code_colon
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_colon, %function
code_colon:
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
	movw	r3, #:lower16:currentDictionary
	movt	r3, #:upper16:currentDictionary
	ldr	r3, [r3]
	ldr	r3, [r3] @ The actual previous head.
	str	r3, [r2] @ Gets written into the new header.
	movw	r3, #:lower16:currentDictionary
	movt	r3, #:upper16:currentDictionary
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
	.size	code_colon, .-code_colon
	.global	header_colon_no_name
	.section	.rodata
	.align	2
.LC119:
	.ascii	":NONAME\000"
	.data
	.align	2
	.type	header_colon_no_name, %object
	.size	header_colon_no_name, 16
header_colon_no_name:
	.word	header_colon
	.word	7
	.word	.LC119
	.word	code_colon_no_name
	.global	key_colon_no_name
	.align	2
	.type	key_colon_no_name, %object
	.size	key_colon_no_name, 4
key_colon_no_name:
	.word	96
	.text
	.align	2
	.global	code_colon_no_name
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_colon_no_name, %function
code_colon_no_name:
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
	.size	code_colon_no_name, .-code_colon_no_name
	.global	header_exit
	.section	.rodata
	.align	2
.LC120:
	.ascii	"EXIT\000"
	.data
	.align	2
	.type	header_exit, %object
	.size	header_exit, 16
header_exit:
	.word	header_colon_no_name
	.word	4
	.word	.LC120
	.word	code_exit
	.global	key_exit
	.align	2
	.type	key_exit, %object
	.size	key_exit, 4
key_exit:
	.word	97
	.text
	.align	2
	.global	code_exit
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_exit, %function
code_exit:
	EXIT_NEXT
	.size	code_exit, .-code_exit
	.global	header_see
	.section	.rodata
	.align	2
.LC121:
	.ascii	"SEE\000"
	.data
	.align	2
	.type	header_see, %object
	.size	header_see, 16
header_see:
	.word	header_exit
	.word	3
	.word	.LC121
	.word	code_see
	.global	key_see
	.align	2
	.type	key_see, %object
	.size	key_see, 4
key_see:
	.word	98
	.section	.rodata
	.align	2
.LC122:
	.ascii	"Decompiling \000"
	.align	2
.LC123:
	.ascii	"NOT FOUND!\000"
	.align	2
.LC124:
	.ascii	"Not compiled using DOCOL; can't SEE native words.\000"
	.align	2
.LC125:
	.ascii	"%u: (literal) %d\012\000"
	.align	2
.LC126:
	.ascii	"%u: branch by %d to: %u\012\000"
	.align	2
.LC127:
	.ascii	"\"%s\"\012\000"
	.align	2
.LC128:
	.ascii	"%u: \000"
	.text
	.align	2
	.global	code_see
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_see, %function
code_see:
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
	.global	header_utime
	.section	.rodata
	.align	2
.LC129:
	.ascii	"UTIME\000"
	.data
	.align	2
	.type	header_utime, %object
	.size	header_utime, 16
header_utime:
	.word	header_see
	.word	5
	.word	.LC129
	.word	code_utime
	.global	key_utime
	.align	2
	.type	key_utime, %object
	.size	key_utime, 4
key_utime:
	.word	106
	.text
	.align	2
	.global	code_utime
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_utime, %function
code_utime:
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
	.size	code_utime, .-code_utime
        .global header_loop_end
        .section        .rodata
        .align 2
.BSS002:
        .ascii  "(LOOP-END)\000"
        .data
        .align  2
        .type   header_loop_end, %object
        .size   header_loop_end, 16
header_loop_end:
        .word   header_utime
        .word   10
        .word   .BSS002
        .word   code_loop_end
        .global key_loop_end
        .align  2
        .type   key_loop_end, %object
        .size   key_loop_end, 4
key_loop_end:
        .word 107
        .text
        .global code_loop_end
        .type   code_loop_end, %function
code_loop_end:
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

	.global	header_ccall_0
	.section	.rodata
	.align	2
.BSS_CC0:
	.ascii	"CCALL0\000"
	.data
	.align	2
	.type	header_ccall_0, %object
	.size	header_ccall_0, 16
header_ccall_0:
	.word	header_loop_end
	.word	6
	.word	.BSS_CC0
	.word	code_ccall_0
	.global	key_ccall_0
	.align	2
	.type	key_ccall_0, %object
	.size	key_ccall_0, 4
key_ccall_0:
	.word	108
	.text
	.align	2
	.global	code_ccall_0
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_ccall_0, %function
code_ccall_0:
	pop     {r0}
        CALL_REG r0
        push    {r0}
        NEXT

	.global	header_ccall_1
	.section	.rodata
	.align	2
.BSS_CC1:
	.ascii	"CCALL1\000"
	.data
	.align	2
	.type	header_ccall_1, %object
	.size	header_ccall_1, 16
header_ccall_1:
	.word	header_ccall_0
	.word	6
	.word	.BSS_CC1
	.word	code_ccall_1
	.global	key_ccall_1
	.align	2
	.type	key_ccall_1, %object
	.size	key_ccall_1, 4
key_ccall_1:
	.word	109
	.text
	.align	2
	.global	code_ccall_1
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_ccall_1, %function
code_ccall_1:
        pop     {r1, r2}
        mov     r0, r2
        CALL_REG r1
        push    {r0}
        NEXT

	.global	header_ccall_2
	.section	.rodata
	.align	2
.BSS_CC2:
	.ascii	"CCALL2\000"
	.data
	.align	2
	.type	header_ccall_2, %object
	.size	header_ccall_2, 16
header_ccall_2:
	.word	header_ccall_1
	.word	6
	.word	.BSS_CC2
	.word	code_ccall_2
	.global	key_ccall_2
	.align	2
	.type	key_ccall_2, %object
	.size	key_ccall_2, 4
key_ccall_2:
	.word	110
	.text
	.align	2
	.global	code_ccall_2
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_ccall_2, %function
code_ccall_2:
        pop     {r8}
        pop     {r1, r2}
        mov     r0, r2
        CALL_REG r8
        push    {r0}
        NEXT

	.global	header_ccall_3
	.section	.rodata
	.align	2
.BSS_CC3:
	.ascii	"CCALL3\000"
	.data
	.align	2
	.type	header_ccall_3, %object
	.size	header_ccall_3, 16
header_ccall_3:
	.word	header_ccall_2
	.word	6
	.word	.BSS_CC3
	.word	code_ccall_3
	.global	key_ccall_3
	.align	2
	.type	key_ccall_3, %object
	.size	key_ccall_3, 4
key_ccall_3:
	.word	111
	.text
	.align	2
	.global	code_ccall_3
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_ccall_3, %function
code_ccall_3:
	pop     {r8}
        ldr     r2, [sp]
        ldr     r1, [sp, #4]
        ldr     r0, [sp, #8]
        add     sp, sp, #8 @ Leave room for the return.
        CALL_REG r8
        str     r0,  [sp]
        NEXT

	.global	header_ccall_4
	.section	.rodata
	.align	2
.BSS_CC4:
	.ascii	"CCALL4\000"
	.data
	.align	2
	.type	header_ccall_4, %object
	.size	header_ccall_4, 16
header_ccall_4:
	.word	header_ccall_3
	.word	6
	.word	.BSS_CC4
	.word	code_ccall_4
	.global	key_ccall_4
	.align	2
	.type	key_ccall_4, %object
	.size	key_ccall_4, 4
key_ccall_4:
	.word	112
	.text
	.align	2
	.global	code_ccall_4
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_ccall_4, %function
code_ccall_4:
	pop     {r8}
        ldr     r3, [sp]
        ldr     r2, [sp, #4]
        ldr     r1, [sp, #8]
        ldr     r0, [sp, #12]
        add     sp, sp, #12 @ Leave room for the return.
        CALL_REG r8
        str     r0, [sp]
        NEXT

	.global	header_ccall_5
	.section	.rodata
	.align	2
.BSS_CC5:
	.ascii	"CCALL5\000"
	.data
	.align	2
	.type	header_ccall_5, %object
	.size	header_ccall_5, 16
header_ccall_5:
	.word	header_ccall_4
	.word	6
	.word	.BSS_CC5
	.word	code_ccall_5
	.global	key_ccall_5
	.align	2
	.type	key_ccall_5, %object
	.size	key_ccall_5, 4
key_ccall_5:
	.word	115
	.text
	.align	2
	.global	code_ccall_5
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_ccall_5, %function
code_ccall_5:
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

	.global	header_ccall_6
	.section	.rodata
	.align	2
.BSS_CC6:
	.ascii	"CCALL6\000"
	.data
	.align	2
	.type	header_ccall_6, %object
	.size	header_ccall_6, 16
header_ccall_6:
	.word	header_ccall_5
	.word	6
	.word	.BSS_CC6
	.word	code_ccall_6
	.global	key_ccall_6
	.align	2
	.type	key_ccall_6, %object
	.size	key_ccall_6, 4
key_ccall_6:
	.word	116
	.text
	.align	2
	.global	code_ccall_6
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_ccall_6, %function
code_ccall_6:
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

	.global	header_c_library
	.section	.rodata
	.align	2
.BSS_CL:
	.ascii	"C-LIBRARY\000"
	.data
	.align	2
	.type	header_c_library, %object
	.size	header_c_library, 16
header_c_library:
	.word	header_ccall_6
	.word	9
	.word	.BSS_CL
	.word	code_c_library
	.global	key_c_library
	.align	2
	.type	key_c_library, %object
	.size	key_c_library, 4
key_c_library:
	.word	113
	.text
	.align	2
	.global	code_c_library
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_c_library, %function
code_c_library:
	@ Expects a null-terminated, C-style string on the stack, and dlopen()s
        @ it, globally, so a generic dlsym() for it will work.
        pop     {r0}
        movw     r1, #258    @ RTLD_NOW | RTLD_GLOBAL
        CALL      dlopen
        NEXT

	.global	header_c_symbol
	.section	.rodata
	.align	2
.BSS_CS:
	.ascii	"C-SYMBOL\000"
	.data
	.align	2
	.type	header_c_symbol, %object
	.size	header_c_symbol, 16
header_c_symbol:
	.word	header_c_library
	.word	8
	.word	.BSS_CS
	.word	code_c_symbol
	.global	key_c_symbol
	.align	2
	.type	key_c_symbol, %object
	.size	key_c_symbol, 4
key_c_symbol:
	.word	114
	.text
	.align	2
	.global	code_c_symbol
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_c_symbol, %function
code_c_symbol:
	@ Expects a C-style null-terminated string on the stack, and dlsym()s
        @ it, returning the resulting pointer on the stack.
        pop     {r1}
        mov     r0, #0    @ 0 is RTLD_DEFAULT, searching everywhere.
        CALL      dlsym
        push    {r0}
        NEXT

	.global	header_semicolon
	.section	.rodata
	.align	2
.LC130:
	.ascii	";\000"
	.data
	.align	2
	.type	header_semicolon, %object
	.size	header_semicolon, 16
header_semicolon:
	.word	header_c_symbol
	.word	513
	.word	.LC130
	.word	code_semicolon
	.global	key_semicolon
	.align	2
	.type	key_semicolon, %object
	.size	key_semicolon, 4
key_semicolon:
	.word	99
	.text
	.align	2
	.global	code_semicolon
	.syntax unified
	.arm
	.fpu vfpv3-d16
	.type	code_semicolon, %function
code_semicolon:
	movw	r3, #:lower16:currentDictionary
	movt	r3, #:upper16:currentDictionary
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
	movw	r3, #:lower16:searchOrder
	movt	r3, #:upper16:searchOrder
	movw	r2, #:lower16:header_semicolon
	movt	r2, #:upper16:header_semicolon
	str	r2, [r3]
	movw	r2, #:lower16:currentDictionary
	movt	r2, #:upper16:currentDictionary
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
	movw	r3, #:lower16:_binary_lib_file_fs_start
	movt	r3, #:upper16:_binary_lib_file_fs_start
	str	r3, [r2]
	ldr	r2, [sp, #12]
	movw	r3, #:lower16:_binary_lib_file_fs_end
	movt	r3, #:upper16:_binary_lib_file_fs_end
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
	movw	r3, #:lower16:_binary_lib_facility_fs_start
	movt	r3, #:upper16:_binary_lib_facility_fs_start
	str	r3, [r2]
	ldr	r2, [sp, #12]
	movw	r3, #:lower16:_binary_lib_facility_fs_end
	movt	r3, #:upper16:_binary_lib_facility_fs_end
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
	movw	r3, #:lower16:_binary_lib_tools_fs_start
	movt	r3, #:upper16:_binary_lib_tools_fs_start
	str	r3, [r2]
	ldr	r2, [sp, #12]
	movw	r3, #:lower16:_binary_lib_tools_fs_end
	movt	r3, #:upper16:_binary_lib_tools_fs_end
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
	movw	r3, #:lower16:_binary_lib_exception_fs_start
	movt	r3, #:upper16:_binary_lib_exception_fs_start
	str	r3, [r2]
	ldr	r2, [sp, #12]
	movw	r3, #:lower16:_binary_lib_exception_fs_end
	movt	r3, #:upper16:_binary_lib_exception_fs_end
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
	movw	r3, #:lower16:_binary_lib_ext_fs_start
	movt	r3, #:upper16:_binary_lib_ext_fs_start
	str	r3, [r2]
	ldr	r2, [sp, #12]
	movw	r3, #:lower16:_binary_lib_ext_fs_end
	movt	r3, #:upper16:_binary_lib_ext_fs_end
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
	movw	r3, #:lower16:_binary_lib_core_fs_start
	movt	r3, #:upper16:_binary_lib_core_fs_start
	str	r3, [r2]
	ldr	r2, [sp, #12]
	movw	r3, #:lower16:_binary_lib_core_fs_end
	movt	r3, #:upper16:_binary_lib_core_fs_end
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
