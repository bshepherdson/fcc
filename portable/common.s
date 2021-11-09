.include "common/support.s"
.section	.rodata
.align 16
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
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
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
# readline uses xmm0 kinds of instructions, which requires the
# target (the stack in this case) be 16-byte aligned.
# So I move the stack here and save its value in %r14, which is
# callee-saved.
movq    %rsp, %r14
movq    $15, %rax
notq    %rax
andq    %rax, %rsp
call	readline@PLT
movq    %rax, str1(%rip)
# Restore %rsp
movq    %r14, %rsp
movq	inputIndex(%rip), %r12
movq	str1(%rip), %rdi
call	strlen@PLT
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
call	strncpy@PLT
movq	inputIndex(%rip), %rax
salq	$5, %rax
addq	$inputSources+8, %rax
movq	$0, (%rax)
movq	str1(%rip), %rdi
call	free@PLT
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
call	strncpy@PLT
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
call	getline@PLT
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
call	strncpy@PLT
movq	str1(%rip), %rdi
call	free@PLT
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
.globl parse_name_stacked
.type	parse_name_stacked, @function
.cfi_startproc
parse_name_stacked:
call parse_name_@PLT
subq $16, %rbx
movq str1(%rip), %rax
movq %rax, 8(%rbx)
movq c1(%rip), %rax
movq %rax, (%rbx)
nop
ret
.cfi_endproc
.size	parse_name_stacked, .-parse_name_stacked
.globl	to_number_int_
.type	to_number_int_, @function
to_number_int_:
.LmdFB69:
.cfi_startproc
movq	$0, c1(%rip)
jmp	.Lmd116
.Lmd117:
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
.Lmd116:
movq	c1(%rip), %rax
cmpq	$7, %rax
jle	.Lmd117
jmp	.Lmd118
.Lmd126:
movq	str1(%rip), %rax
movzbl	(%rax), %eax
movsbq	%al, %rax
movq	%rax, c1(%rip)
movq	c1(%rip), %rax
cmpq	$47, %rax
jle	.Lmd119
movq	c1(%rip), %rax
cmpq	$57, %rax
jg	.Lmd119
subq	$48, c1(%rip)
jmp	.Lmd120
.Lmd119:
movq	c1(%rip), %rax
cmpq	$64, %rax
jle	.Lmd121
movq	c1(%rip), %rax
cmpq	$90, %rax
jg	.Lmd121
movq	c1(%rip), %rax
subq	$55, %rax
movq	%rax, c1(%rip)
jmp	.Lmd120
.Lmd121:
movq	c1(%rip), %rax
cmpq	$96, %rax
jle	.Lmd122
movq	c1(%rip), %rax
cmpq	$122, %rax
jg	.Lmd122
movq	c1(%rip), %rax
subq	$87, %rax
movq	%rax, c1(%rip)
.Lmd120:
movq	c1(%rip), %rdx
movq	tempSize(%rip), %rax
cmpq	%rax, %rdx
jge	.Lmd129
movq	$0, c3(%rip)
jmp	.Lmd124
.Lmd125:
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
.Lmd124:
movq	c3(%rip), %rax
cmpq	$15, %rax
jle	.Lmd125
movq	(%rbx), %rax
subq	$1, %rax
movq	%rax, (%rbx)
addq	$1, str1(%rip)
.Lmd118:
movq	(%rbx), %rax
testq	%rax, %rax
jg	.Lmd126
jmp	.Lmd122
.Lmd129:
nop
.Lmd122:
movq	$0, 16(%rbx)
movq	$0, 24(%rbx)
movq	$0, c1(%rip)
jmp	.Lmd127
.Lmd128:
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
.Lmd127:
movq	c1(%rip), %rax
cmpq	$7, %rax
jle	.Lmd128
movq	str1(%rip), %rax
movq	%rax, 8(%rbx)
nop
ret
.cfi_endproc
.LmdFE69:
.size	to_number_int_, .-to_number_int_
.globl	to_number_
.type	to_number_, @function
to_number_:
.LmdFB70:
.cfi_startproc
movq	base(%rip), %rax
movq	%rax, tempSize(%rip)
movq	8(%rbx), %rax
movq	%rax, str1(%rip)
call	to_number_int_@PLT
nop
ret
.cfi_endproc
.LmdFE70:
.size	to_number_, .-to_number_
.globl	parse_number_
.type	parse_number_, @function
parse_number_:
.LmdFB71:
.cfi_startproc
movq	8(%rbx), %rax
movq	%rax, str1(%rip)
movq	base(%rip), %rax
movq	%rax, tempSize(%rip)
movq	str1(%rip), %rax
movzbl	(%rax), %eax
cmpb	$36, %al
je	.Lmd132
movq	str1(%rip), %rax
movzbl	(%rax), %eax
cmpb	$35, %al
je	.Lmd132
movq	str1(%rip), %rax
movzbl	(%rax), %eax
cmpb	$37, %al
jne	.Lmd133
.Lmd132:
movq	str1(%rip), %rax
movzbl	(%rax), %eax
cmpb	$36, %al
je	.Lmd134
movq	str1(%rip), %rax
movzbl	(%rax), %eax
cmpb	$35, %al
jne	.Lmd135
movl	$10, %eax
jmp	.Lmd137
.Lmd135:
movl	$2, %eax
jmp	.Lmd137
.Lmd134:
movl	$16, %eax
.Lmd137:
movq	%rax, tempSize(%rip)
addq	$1, str1(%rip)
subq	$1, (%rbx)
jmp	.Lmd138
.Lmd133:
movq	str1(%rip), %rax
movzbl	(%rax), %eax
cmpb	$39, %al
jne	.Lmd138
subq    $3, (%rbx)
addq    $3, 8(%rbx)
movq	str1(%rip), %rax
addq	$1, %rax
movsbq	(%rax), %rax
movq	%rax, 24(%rbx)
jmp	.Lmd131
.Lmd138:
movb	$0, ch1(%rip)
movq	str1(%rip), %rax
movzbl	(%rax), %eax
cmpb	$45, %al
jne	.Lmd140
subq    $1, (%rbx)
addq	$1, str1(%rip)
movb	$1, ch1(%rip)
.Lmd140:
call	to_number_int_@PLT
movzbl	ch1(%rip), %eax
testb	%al, %al
je	.Lmd131
notq    16(%rbx)
movq    24(%rbx), %rax
notq    %rax
addq    $1, %rax
movq    %rax, 24(%rbx)
testq	%rax, %rax
jne	.Lmd131
addq	$1, 16(%rbx)
.Lmd131:
ret
.cfi_endproc
.LmdFE71:
.size	parse_number_, .-parse_number_
.globl	find_
.type	find_, @function
find_:
movq    searchIndex(%rip), %r12    # r12 is reserved for the index.
.LmdF159:
leaq    searchArray(%rip), %rax
movq    (%rax,%r12,8), %rax
movq    (%rax), %rax
movq    %rax, tempHeader(%rip)   # Store it in tempHeader.
jmp     .LmdF151
.LmdF156:
movq    tempHeader(%rip), %rax
movq    8(%rax), %rax  # The length word.
andl	$511, %eax     # The length/hidden mask
movq    (%rbx), %rcx
cmpq    %rcx, %rax
jne     .LmdF152
# If we're still here, they're the same length and not hidden.
find_debug:
movq    tempHeader(%rip), %rax
movq    16(%rax), %rdi  # 1st arg: pointer to this word's name.
movq    8(%rbx), %rsi   # 2nd arg: pointer to target name.
movq    (%rbx), %rdx    # 3rd arg: length.
# %rsp needs to be aligned to 16 bytes for C calls, but it already is,
# because find_ is a C call itself.
call strncasecmp@PLT
testl   %eax, %eax  # ZF=1 when the response was 0, meaning equal.
jne  .LmdF152  # If it's not equal, we didn't find it.
# If they are equal, we found it.
find_found:
movq    tempHeader(%rip), %rax
addq    $24, %rax
movq    %rax, 8(%rbx)   # CFA in next-but-top.
movq    tempHeader(%rip), %rax
movq    8(%rax), %rax   # Length
andl    $512, %eax      # Immediate flag
testl   %eax, %eax      # ZF=1 when not immediate
jne     .LmdF153          # Set 1 when immediate
movq    $-1, %rax
jmp     .LmdF154
.LmdF153:
movq    $1, %rax
.LmdF154:
movq    %rax, (%rbx)
jmp     .LmdF149
.LmdF152: # Mismatch, keep searching this linked list.
movq    tempHeader(%rip), %rax
movq    (%rax), %rax
movq    %rax, tempHeader(%rip)
.LmdF151:
movq    tempHeader(%rip), %rax
testq   %rax, %rax
jne     .LmdF156  # Nonzero, so loop back.
.LmdF150: # Reached the end of a wordlist. Try the next one, if any.
testq   %r12, %r12
je      .LmdF158  # Index = 0, bail.
subq    $1, %r12 # If nonzero, subtract and loop.
jmp     .LmdF159
.LmdF160:
nop
.LmdF158: # Run out of wordlists too.
movq $0, %rax
movq %rax, 8(%rbx) # 0 underneath
movq %rax, (%rbx)  # 0 on top
.LmdF149: # Returning
ret
.size	find_, .-find_
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
.LmdFB88:
.cfi_startproc
movq	(%rbp), %rax
addq    $8, %rbp
movq	rsp(%rip), %r12
subq	$8, %r12
movq	%r12, rsp(%rip)
movq	%rbp, (%r12)
movq	%rax, %rbp
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.LmdFE88:
.size	call_, .-call_
.globl	lookup_primitive
.type	lookup_primitive, @function
lookup_primitive:
.LmdFB89:
.cfi_startproc
movq	$0, c2(%rip)
jmp	.Lmd179
.Lmd182:
movq	c2(%rip), %rax
salq	$4, %rax
addq	$primitives, %rax
movq	(%rax), %rdx
movq	c1(%rip), %rax
cmpq	%rax, %rdx
jne	.Lmd180
movq	c2(%rip), %rax
salq	$4, %rax
addq	$primitives+8, %rax
movl	(%rax), %eax
movl	%eax, key1(%rip)
jmp	.Lmd183
.Lmd180:
addq	$1, c2(%rip)
.Lmd179:
movl	primitive_count(%rip), %eax
movslq	%eax, %rdx
movq	c2(%rip), %rax
cmpq	%rax, %rdx
jg	.Lmd182
subq	$8, %rsp
.cfi_def_cfa_offset 16
movl	$40, %edi
call	exit@PLT
.Lmd183:
.cfi_def_cfa_offset 8
ret
.cfi_endproc
.LmdFE89:
.size	lookup_primitive, .-lookup_primitive
.globl	drain_queue_
.type	drain_queue_, @function
drain_queue_:
.LmdFB90:
.cfi_startproc
movl	$0, key1(%rip)
movq	queue(%rip), %rax
movq	%rax, tempQueue(%rip)
movq	$0, c1(%rip)
jmp	.Lmd188
.Lmd189:
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
.Lmd188:
movq	tempQueue(%rip), %rax
testq	%rax, %rax
jne	.Lmd189
jmp	.Lmd190
.Lmd199:
movq	$0, c2(%rip)
jmp	.Lmd191
.Lmd198:
movq	c2(%rip), %rax
salq	$4, %rax
addq	$superinstructions+8, %rax
movl	(%rax), %edx
movl	key1(%rip), %eax
cmpl	%eax, %edx
jne	.Lmd192
movq	dsp(%rip), %rax
leaq	8(%rax), %rdx
movq	%rdx, dsp(%rip)
movq	c2(%rip), %rdx
salq	$4, %rdx
addq	$superinstructions, %rdx
movq	(%rdx), %rdx
movq	%rdx, (%rax)
jmp	.Lmd193
.Lmd195:
movq	queue(%rip), %rax
movzbl	8(%rax), %eax
testb	%al, %al
je	.Lmd194
movq	dsp(%rip), %rax
leaq	8(%rax), %rdx
movq	%rdx, dsp(%rip)
movq	queue(%rip), %rdx
movq	16(%rdx), %rdx
movq	%rdx, (%rax)
.Lmd194:
movq	queue(%rip), %rax
movq	32(%rax), %rax
movq	%rax, queue(%rip)
subl	$1, queue_length(%rip)
subq	$1, c1(%rip)
.Lmd193:
movq	c1(%rip), %rax
testq	%rax, %rax
jg	.Lmd195
movq	queue(%rip), %rax
testq	%rax, %rax
jne	.Lmd202
movq	$0, queueTail(%rip)
jmp	.Lmd202
.Lmd192:
addq	$1, c2(%rip)
.Lmd191:
movl	nextSuperinstruction(%rip), %eax
movslq	%eax, %rdx
movq	c2(%rip), %rax
cmpq	%rax, %rdx
jg	.Lmd198
subq	$1, c1(%rip)
movl	$4, %eax
subq	c1(%rip), %rax
sall	$3, %eax
movl	$-1, %edx
movl	%eax, %ecx
shrl	%cl, %edx
movl	%edx, %eax
andl	%eax, key1(%rip)
.Lmd190:
movq	c1(%rip), %rax
cmpq	$1, %rax
jg	.Lmd199
movq	dsp(%rip), %rax
leaq	8(%rax), %rdx
movq	%rdx, dsp(%rip)
movq	queue(%rip), %rdx
movq	(%rdx), %rdx
movq	%rdx, (%rax)
movq	queue(%rip), %rax
movzbl	8(%rax), %eax
testb	%al, %al
je	.Lmd200
movq	dsp(%rip), %rax
leaq	8(%rax), %rdx
movq	%rdx, dsp(%rip)
movq	queue(%rip), %rdx
movq	16(%rdx), %rdx
movq	%rdx, (%rax)
.Lmd200:
movq	queue(%rip), %rax
movq	32(%rax), %rax
movq	%rax, queue(%rip)
movq	queue(%rip), %rax
testq	%rax, %rax
jne	.Lmd201
movq	$0, queueTail(%rip)
.Lmd201:
subl	$1, queue_length(%rip)
jmp	.Lmd187
.Lmd202:
nop
.Lmd187:
ret
.cfi_endproc
.LmdFE90:
.size	drain_queue_, .-drain_queue_
.globl	bump_queue_tail_
.type	bump_queue_tail_, @function
bump_queue_tail_:
.LmdFB91:
.cfi_startproc
movq	queueTail(%rip), %rax
testq	%rax, %rax
jne	.Lmd204
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
jmp	.Lmd205
.Lmd204:
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
.Lmd205:
movq	queueTail(%rip), %rax
movq	$0, 32(%rax)
andl	$3, next_queue_source(%rip)
addl	$1, queue_length(%rip)
nop
ret
.cfi_endproc
.LmdFE91:
.size	bump_queue_tail_, .-bump_queue_tail_
.globl	compile_
.type	compile_, @function
compile_:
.LmdFB92:
.cfi_startproc
subq	$8, %rsp
.cfi_def_cfa_offset 16
movl	queue_length(%rip), %eax
cmpl	$3, %eax
jle	.Lmd207
call	drain_queue_@PLT
.Lmd207:
movl	$0, %eax
call	bump_queue_tail_@PLT
movq	(%rbx), %rax
movq	(%rax), %rax
cmpq	$code_docol, %rax
jne	.Lmd208
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
jmp	.Lmd213
.Lmd208:
movq	(%rbx), %rax
movq	(%rax), %rax
cmpq	$code_dodoes, %rax
jne	.Lmd210
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
je	.Lmd211
movl	queue_length(%rip), %eax
cmpl	$4, %eax
jne	.Lmd212
call	drain_queue_@PLT
.Lmd212:
movl	$0, %eax
call	bump_queue_tail_@PLT
movq	queueTail(%rip), %rax
movq	$call_, (%rax)
movb	$1, 8(%rax)
movq	(%rbx), %rdx
addq	$8, %rdx
movq	(%rdx), %rdx
movq	%rdx, 16(%rax)
movl	key_call_(%rip), %edx
movl	%edx, 24(%rax)
.Lmd211:
addq	$8, %rbx
jmp	.Lmd213
.Lmd210:
movq    (%rbx), %rax
addq    $8, %rbx
movq	(%rax), %rax
movq	%rax, c1(%rip)
movl	$0, %eax
call	lookup_primitive@PLT
movq	queueTail(%rip), %rax
movq	c1(%rip), %rdx
movq	%rdx, (%rax)
movq	queueTail(%rip), %rax
movb	$0, 8(%rax)
movq	queueTail(%rip), %rax
movl	key1(%rip), %edx
movl	%edx, 24(%rax)
.Lmd213:
nop
addq	$8, %rsp
.cfi_def_cfa_offset 8
ret
.cfi_endproc
.LmdFE92:
.size	compile_, .-compile_
.globl	compile_lit_
.type	compile_lit_, @function
compile_lit_:
.LmdFB93:
.cfi_startproc
movl	queue_length(%rip), %eax
cmpl	$3, %eax
jle	.Lmd216
call	drain_queue_@PLT
.Lmd216:
movl	$0, %eax
call	bump_queue_tail_@PLT
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
.LmdFE93:
.size	compile_lit_, .-compile_lit_
.comm	savedString,8,8
.comm	savedLength,8,8
.section	.rodata
.LmdC84:
.string	"  ok"
.LmdC85:
.string	"*** Unrecognized word: %s\n"
.text
.globl	quit_
.type	quit_, @function
quit_:
.LmdFB94:
.cfi_startproc
subq	$8, %rsp
.cfi_def_cfa_offset 16
.Lmd218:
movq	spTop(%rip), %rbx
movq	rspTop(%rip), %rax
movq	%rax, rsp(%rip)
movq	$0, state(%rip)
movzbl	firstQuit(%rip), %eax
testb	%al, %al
jne	.Lmd219
movq	$0, inputIndex(%rip)
.Lmd219:
movq	$.Lmd220, quit_inner(%rip)
call	refill_@PLT
.Lmd220:
call	parse_name_stacked@PLT
movq	(%rbx), %rax
testq	%rax, %rax
jne	.Lmd233
movq	inputIndex(%rip), %rax
salq	$5, %rax
addq	$inputSources+16, %rax
movq	(%rax), %rax
testq	%rax, %rax
jne	.Lmd223
movl	$.LmdC84, %edi
call	puts@PLT
.Lmd223:
addq	$16, %rbx
call	refill_@PLT
jmp	.Lmd220
.Lmd233:
nop
movq	8(%rbx), %rax
movq	%rax, savedString(%rip)
movq	(%rbx), %rax
movq	%rax, savedLength(%rip)
call	find_@PLT
movq	(%rbx), %rax
testq	%rax, %rax
jne	.Lmd224
subq	$16, %rbx
movq	savedLength(%rip), %rax
movq	%rax, (%rbx)
movq	savedString(%rip), %rax
movq	%rax, 8(%rbx)
call	parse_number_@PLT
movq	(%rbx), %rax
testq	%rax, %rax
jne	.Lmd225
movq	state(%rip), %rax
cmpq	$1, %rax
jne	.Lmd226
addq	$24, %rbx
movl	$0, %eax
call	compile_lit_@PLT
jmp	.Lmd220
.Lmd226:
addq	$24, %rbx
jmp	.Lmd220
.Lmd225:
movq	savedLength(%rip), %rdx
movq	savedString(%rip), %rsi
movl	$tempBuf, %edi
call	strncpy@PLT
movq	savedLength(%rip), %rax
movb	$0, tempBuf(%rax)
movl	$tempBuf, %edx
movl	$.LmdC85, %esi
movq	stderr(%rip), %rdi
movl	$0, %eax
call	fprintf@PLT
jmp	.Lmd218
.Lmd224:
movq	(%rbx), %rax
cmpq	$1, %rax
je	.Lmd229
movq	state(%rip), %rax
testq	%rax, %rax
jne	.Lmd230
.Lmd229:
movl	$.Lmd220, %eax
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
.Lmd230:
addq	$8, %rbx
movl	$0, %eax
call	compile_@PLT
jmp	.Lmd220
.cfi_endproc
.LmdFE94:
.size	quit_, .-quit_
.globl	file_modes
.section	.rodata
.LmdC96:
.string	"r"
.LmdC97:
.string	"r+"
.LmdC98:
.string	"rb"
.LmdC99:
.string	"r+b"
.LmdC100:
.string	"w+"
.LmdC101:
.string	"w"
.LmdC102:
.string	"w+b"
.data
.align 32
.type	file_modes, @object
.size	file_modes, 128
file_modes:
.quad	0
.quad	.LmdC96
.quad	.LmdC97
.quad	.LmdC97
.quad	0
.quad	.LmdC98
.quad	.LmdC99
.quad	.LmdC99
.quad	0
.quad	.LmdC100
.quad	.LmdC101
.quad	.LmdC100
.quad	0
.quad	.LmdC102
.quad	.LmdC81
.quad	.LmdC102
.section	.rodata
.align 8
.LmdC117:
.string	"*** Colon definition with no name\n"
.LmdFE123:
.section	.rodata
.align 8
.LmdC131:
.string	"Could not load input file: %s\n"
.LmdC81:
.string	"wb"
.align 8
.LmdC82:
.string	"*** Failed to open file for writing: %s\n"
.text
.globl	main
.type	main, @function
main:
.LmdFB124:
.cfi_startproc
movl	%edi, 12(%rsp)
movq	%rsi, (%rsp)
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
jmp	.Lmd334
.Lmd336:
addq	$1, inputIndex(%rip)
movq	inputIndex(%rip), %rbx
movl	12(%rsp), %eax
cltq
leaq	0(,%rax,8), %rdx
movq	(%rsp), %rax
addq	%rdx, %rax
movl	$.LmdC96, %esi
movq	(%rax), %rdi
call	fopen@PLT
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
jne	.Lmd335
movl	12(%rsp), %eax
cltq
leaq	0(,%rax,8), %rdx
movq	(%rsp), %rax
addq	%rdx, %rax
movq	(%rax), %rdx
movl	$.LmdC131, %esi
movq	stderr(%rip), %rdi
movl	$0, %eax
call	fprintf@PLT
movl	$1, %edi
call	exit@PLT
.Lmd335:
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
.Lmd334:
cmpl	$0, 12(%rsp)
jg	.Lmd336
addq	$1, inputIndex(%rip)
movl	$16, %edi
call	malloc@PLT
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
call	malloc@PLT
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
call	malloc@PLT
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
call	malloc@PLT
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
call	malloc@PLT
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
call	malloc@PLT
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
call	init_primitives@PLT
call	init_superinstructions@PLT
call	quit_@PLT
movl	$0, %eax
addq	$32, %rsp
.cfi_def_cfa_offset 16
popq	%rbx
.cfi_def_cfa_offset 8
ret
.cfi_endproc
.LmdFE124:
.size	main, .-main
.globl	init_primitives
.type	init_primitives, @function
init_primitives:
.LmdFB125:
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
movl	key_MOD(%rip), %eax
leal	-1(%rax), %edx
movl	key_MOD(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_MOD, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_UMOD(%rip), %eax
leal	-1(%rax), %edx
movl	key_UMOD(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_UMOD, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_AND(%rip), %eax
leal	-1(%rax), %edx
movl	key_AND(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_AND, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_OR(%rip), %eax
leal	-1(%rax), %edx
movl	key_OR(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_OR, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_XOR(%rip), %eax
leal	-1(%rax), %edx
movl	key_XOR(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_XOR, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_LSHIFT(%rip), %eax
leal	-1(%rax), %edx
movl	key_LSHIFT(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_LSHIFT, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_RSHIFT(%rip), %eax
leal	-1(%rax), %edx
movl	key_RSHIFT(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_RSHIFT, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_BASE(%rip), %eax
leal	-1(%rax), %edx
movl	key_BASE(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_BASE, (%rcx)
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
movl	key_DUP(%rip), %eax
leal	-1(%rax), %edx
movl	key_DUP(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_DUP, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_SWAP(%rip), %eax
leal	-1(%rax), %edx
movl	key_SWAP(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_SWAP, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_DROP(%rip), %eax
leal	-1(%rax), %edx
movl	key_DROP(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_DROP, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_OVER(%rip), %eax
leal	-1(%rax), %edx
movl	key_OVER(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_OVER, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_ROT(%rip), %eax
leal	-1(%rax), %edx
movl	key_ROT(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_ROT, (%rcx)
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
movl	key_STATE(%rip), %eax
leal	-1(%rax), %edx
movl	key_STATE(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_STATE, (%rcx)
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
movl	key_EXECUTE(%rip), %eax
leal	-1(%rax), %edx
movl	key_EXECUTE(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_EXECUTE, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_EVALUATE(%rip), %eax
leal	-1(%rax), %edx
movl	key_EVALUATE(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_EVALUATE, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_REFILL(%rip), %eax
leal	-1(%rax), %edx
movl	key_REFILL(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_REFILL, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_ACCEPT(%rip), %eax
leal	-1(%rax), %edx
movl	key_ACCEPT(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_ACCEPT, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_KEY(%rip), %eax
leal	-1(%rax), %edx
movl	key_KEY(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_KEY, (%rcx)
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
movl	key_EMIT(%rip), %eax
leal	-1(%rax), %edx
movl	key_EMIT(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_EMIT, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_SOURCE(%rip), %eax
leal	-1(%rax), %edx
movl	key_SOURCE(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_SOURCE, (%rcx)
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
movl	key_CELLS(%rip), %eax
leal	-1(%rax), %edx
movl	key_CELLS(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_CELLS, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_CHARS(%rip), %eax
leal	-1(%rax), %edx
movl	key_CHARS(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_CHARS, (%rcx)
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
movl	key_PARSE(%rip), %eax
leal	-1(%rax), %edx
movl	key_PARSE(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_PARSE, (%rcx)
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
movl	key_CREATE(%rip), %eax
leal	-1(%rax), %edx
movl	key_CREATE(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_CREATE, (%rcx)
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
movl	key_DEPTH(%rip), %eax
leal	-1(%rax), %edx
movl	key_DEPTH(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_DEPTH, (%rcx)
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
movl	key_QUIT(%rip), %eax
leal	-1(%rax), %edx
movl	key_QUIT(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_QUIT, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_BYE(%rip), %eax
leal	-1(%rax), %edx
movl	key_BYE(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_BYE, (%rcx)
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
movl	key_EXIT(%rip), %eax
leal	-1(%rax), %edx
movl	key_EXIT(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_EXIT, (%rcx)
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
movl	key_LITERAL(%rip), %eax
leal	-1(%rax), %edx
movl	key_LITERAL(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_LITERAL, (%rcx)
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
movl	key_UTIME(%rip), %eax
leal	-1(%rax), %edx
movl	key_UTIME(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_UTIME, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_loop_end(%rip), %eax
leal	-1(%rax), %edx
movl	key_loop_end(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_loop_end, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_CCALL0(%rip), %eax
leal	-1(%rax), %edx
movl	key_CCALL0(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_CCALL0, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_CCALL1(%rip), %eax
leal	-1(%rax), %edx
movl	key_CCALL1(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_CCALL1, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_CCALL2(%rip), %eax
leal	-1(%rax), %edx
movl	key_CCALL2(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_CCALL2, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_CCALL3(%rip), %eax
leal	-1(%rax), %edx
movl	key_CCALL3(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_CCALL3, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_CCALL4(%rip), %eax
leal	-1(%rax), %edx
movl	key_CCALL4(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_CCALL4, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_CCALL5(%rip), %eax
leal	-1(%rax), %edx
movl	key_CCALL5(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_CCALL5, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_CCALL6(%rip), %eax
leal	-1(%rax), %edx
movl	key_CCALL6(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_CCALL6, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_c_lib_loader(%rip), %eax
leal	-1(%rax), %edx
movl	key_c_lib_loader(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_c_lib_loader, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_c_symbol(%rip), %eax
leal	-1(%rax), %edx
movl	key_c_symbol(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_c_symbol, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_dictionary_info(%rip), %eax
leal	-1(%rax), %edx
movl	key_dictionary_info(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_dictionary_info, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_two_fetch(%rip), %eax
leal	-1(%rax), %edx
movl	key_two_fetch(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_two_fetch, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
movl	key_two_store(%rip), %eax
leal	-1(%rax), %edx
movl	key_two_store(%rip), %eax
movl	%edx, %ecx
salq	$4, %rcx
addq	$primitives, %rcx
movq	$code_two_store, (%rcx)
movl	%edx, %edx
salq	$4, %rdx
addq	$primitives+8, %rdx
movl	%eax, (%rdx)
nop
ret
.cfi_endproc
.LmdFE125:
.size	init_primitives, .-init_primitives
.globl header_plus
.section .rodata
.str_plus:
.string "+"
.data
.align 32
.type header_plus, @object
.size header_plus, 32
header_plus:
.quad 0
.quad 1
.quad .str_plus
.quad code_plus
.globl key_plus
.align 4
.type key_plus, @object
.size key_plus, 4
key_plus:
.long 1
.text
.globl code_plus
.type code_plus, @function
code_plus:
movq    (%rbx), %rax
addq    $8, %rbx
addq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_plus, .-code_plus
.globl header_minus
.section .rodata
.str_minus:
.string "-"
.data
.align 32
.type header_minus, @object
.size header_minus, 32
header_minus:
.quad header_plus
.quad 1
.quad .str_minus
.quad code_minus
.globl key_minus
.align 4
.type key_minus, @object
.size key_minus, 4
key_minus:
.long 2
.text
.globl code_minus
.type code_minus, @function
code_minus:
movq	(%rbx), %rcx
movq	8(%rbx), %rax
subq	%rcx, %rax
addq    $8, %rbx
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_minus, .-code_minus
.globl header_times
.section .rodata
.str_times:
.string "*"
.data
.align 32
.type header_times, @object
.size header_times, 32
header_times:
.quad header_minus
.quad 1
.quad .str_times
.quad code_times
.globl key_times
.align 4
.type key_times, @object
.size key_times, 4
key_times:
.long 3
.text
.globl code_times
.type code_times, @function
code_times:
movq    (%rbx), %rdx
addq	$8, %rbx
movq	(%rbx), %rcx
imulq	%rcx, %rdx
movq	%rdx, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_times, .-code_times
.globl header_div
.section .rodata
.str_div:
.string "/"
.data
.align 32
.type header_div, @object
.size header_div, 32
header_div:
.quad header_times
.quad 1
.quad .str_div
.quad code_div
.globl key_div
.align 4
.type key_div, @object
.size key_div, 4
key_div:
.long 4
.text
.globl code_div
.type code_div, @function
code_div:
movq    (%rbx), %rsi
addq    $8, %rbx
movq    (%rbx), %rax
cqto
idivq	%rsi
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_div, .-code_div
.globl header_udiv
.section .rodata
.str_udiv:
.string "U/"
.data
.align 32
.type header_udiv, @object
.size header_udiv, 32
header_udiv:
.quad header_div
.quad 2
.quad .str_udiv
.quad code_udiv
.globl key_udiv
.align 4
.type key_udiv, @object
.size key_udiv, 4
key_udiv:
.long 5
.text
.globl code_udiv
.type code_udiv, @function
code_udiv:
movq    (%rbx), %rsi
addq    $8, %rbx
movq    (%rbx), %rax
movl    $0, %edx
divq	%rsi
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_udiv, .-code_udiv
.globl header_MOD
.section .rodata
.str_MOD:
.string "MOD"
.data
.align 32
.type header_MOD, @object
.size header_MOD, 32
header_MOD:
.quad header_udiv
.quad 3
.quad .str_MOD
.quad code_MOD
.globl key_MOD
.align 4
.type key_MOD, @object
.size key_MOD, 4
key_MOD:
.long 6
.text
.globl code_MOD
.type code_MOD, @function
code_MOD:
movq    (%rbx), %rsi
addq    $8, %rbx
movq    (%rbx), %rax
cqto
idivq	%rsi
movq	%rdx, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_MOD, .-code_MOD
.globl header_UMOD
.section .rodata
.str_UMOD:
.string "UMOD"
.data
.align 32
.type header_UMOD, @object
.size header_UMOD, 32
header_UMOD:
.quad header_MOD
.quad 4
.quad .str_UMOD
.quad code_UMOD
.globl key_UMOD
.align 4
.type key_UMOD, @object
.size key_UMOD, 4
key_UMOD:
.long 7
.text
.globl code_UMOD
.type code_UMOD, @function
code_UMOD:
movq    (%rbx), %rsi
addq    $8, %rbx
movq    (%rbx), %rax
movl    $0, %edx
divq	%rsi      # modulus in %rdx
movq    %rdx, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_UMOD, .-code_UMOD
.globl header_AND
.section .rodata
.str_AND:
.string "AND"
.data
.align 32
.type header_AND, @object
.size header_AND, 32
header_AND:
.quad header_UMOD
.quad 3
.quad .str_AND
.quad code_AND
.globl key_AND
.align 4
.type key_AND, @object
.size key_AND, 4
key_AND:
.long 8
.text
.globl code_AND
.type code_AND, @function
code_AND:
movq    (%rbx), %rdx
addq    $8, %rbx
movq    (%rbx), %rax
andq	%rdx, %rax
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_AND, .-code_AND
.globl header_OR
.section .rodata
.str_OR:
.string "OR"
.data
.align 32
.type header_OR, @object
.size header_OR, 32
header_OR:
.quad header_AND
.quad 2
.quad .str_OR
.quad code_OR
.globl key_OR
.align 4
.type key_OR, @object
.size key_OR, 4
key_OR:
.long 9
.text
.globl code_OR
.type code_OR, @function
code_OR:
movq    (%rbx), %rdx
addq    $8, %rbx
movq    (%rbx), %rax
orq	 %rdx, %rax
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_OR, .-code_OR
.globl header_XOR
.section .rodata
.str_XOR:
.string "XOR"
.data
.align 32
.type header_XOR, @object
.size header_XOR, 32
header_XOR:
.quad header_OR
.quad 3
.quad .str_XOR
.quad code_XOR
.globl key_XOR
.align 4
.type key_XOR, @object
.size key_XOR, 4
key_XOR:
.long 10
.text
.globl code_XOR
.type code_XOR, @function
code_XOR:
movq    (%rbx), %rax
addq    $8, %rbx
xorq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_XOR, .-code_XOR
.globl header_LSHIFT
.section .rodata
.str_LSHIFT:
.string "LSHIFT"
.data
.align 32
.type header_LSHIFT, @object
.size header_LSHIFT, 32
header_LSHIFT:
.quad header_XOR
.quad 6
.quad .str_LSHIFT
.quad code_LSHIFT
.globl key_LSHIFT
.align 4
.type key_LSHIFT, @object
.size key_LSHIFT, 4
key_LSHIFT:
.long 11
.text
.globl code_LSHIFT
.type code_LSHIFT, @function
code_LSHIFT:
movq	(%rbx), %rcx     # sp[0] -> %rcx
addq    $8, %rbx
movq    (%rbx), %rsi     # sp[1] -> %rsi
salq	%cl, %rsi        # result in %rsi
movq	%rsi, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_LSHIFT, .-code_LSHIFT
.globl header_RSHIFT
.section .rodata
.str_RSHIFT:
.string "RSHIFT"
.data
.align 32
.type header_RSHIFT, @object
.size header_RSHIFT, 32
header_RSHIFT:
.quad header_LSHIFT
.quad 6
.quad .str_RSHIFT
.quad code_RSHIFT
.globl key_RSHIFT
.align 4
.type key_RSHIFT, @object
.size key_RSHIFT, 4
key_RSHIFT:
.long 12
.text
.globl code_RSHIFT
.type code_RSHIFT, @function
code_RSHIFT:
movq    (%rbx), %rax
movl    %eax, %ecx
addq    $8, %rbx
movq    (%rbx), %rsi
shrq	%cl, %rsi
movq	%rsi, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_RSHIFT, .-code_RSHIFT
.globl header_BASE
.section .rodata
.str_BASE:
.string "BASE"
.data
.align 32
.type header_BASE, @object
.size header_BASE, 32
header_BASE:
.quad header_RSHIFT
.quad 4
.quad .str_BASE
.quad code_BASE
.globl key_BASE
.align 4
.type key_BASE, @object
.size key_BASE, 4
key_BASE:
.long 13
.text
.globl code_BASE
.type code_BASE, @function
code_BASE:
subq    $8, %rbx
movl    $base, %eax
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_BASE, .-code_BASE
.globl header_less_than
.section .rodata
.str_less_than:
.string "<"
.data
.align 32
.type header_less_than, @object
.size header_less_than, 32
header_less_than:
.quad header_BASE
.quad 1
.quad .str_less_than
.quad code_less_than
.globl key_less_than
.align 4
.type key_less_than, @object
.size key_less_than, 4
key_less_than:
.long 14
.text
.globl code_less_than
.type code_less_than, @function
code_less_than:
movq    (%rbx), %rax
addq    $8, %rbx
movq    (%rbx), %rcx
cmpq	%rax, %rcx
jge	.Lprim17
movq	$-1, %rax
jmp	.Lprim18
.Lprim17:
movl	$0, %eax
.Lprim18:
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_less_than, .-code_less_than
.globl header_less_than_unsigned
.section .rodata
.str_less_than_unsigned:
.string "U<"
.data
.align 32
.type header_less_than_unsigned, @object
.size header_less_than_unsigned, 32
header_less_than_unsigned:
.quad header_less_than
.quad 2
.quad .str_less_than_unsigned
.quad code_less_than_unsigned
.globl key_less_than_unsigned
.align 4
.type key_less_than_unsigned, @object
.size key_less_than_unsigned, 4
key_less_than_unsigned:
.long 15
.text
.globl code_less_than_unsigned
.type code_less_than_unsigned, @function
code_less_than_unsigned:
movq    (%rbx), %rax
addq    $8, %rbx
movq    (%rbx), %rcx
cmpq	%rax, %rcx
jnb	.Lprim20
movq	$-1, %rax
jmp	.Lprim821
.Lprim20:
movl	$0, %eax
.Lprim821:
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_less_than_unsigned, .-code_less_than_unsigned
.globl header_equal
.section .rodata
.str_equal:
.string "="
.data
.align 32
.type header_equal, @object
.size header_equal, 32
header_equal:
.quad header_less_than_unsigned
.quad 1
.quad .str_equal
.quad code_equal
.globl key_equal
.align 4
.type key_equal, @object
.size key_equal, 4
key_equal:
.long 16
.text
.globl code_equal
.type code_equal, @function
code_equal:
movq    (%rbx), %rcx
addq    $8, %rbx
movq    (%rbx), %rax
cmpq	%rax, %rcx
jne	.Lprim823
movq	$-1, %rax
jmp	.Lprim824
.Lprim823:
movl	$0, %eax
.Lprim824:
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_equal, .-code_equal
.globl header_DUP
.section .rodata
.str_DUP:
.string "DUP"
.data
.align 32
.type header_DUP, @object
.size header_DUP, 32
header_DUP:
.quad header_equal
.quad 3
.quad .str_DUP
.quad code_DUP
.globl key_DUP
.align 4
.type key_DUP, @object
.size key_DUP, 4
key_DUP:
.long 17
.text
.globl code_DUP
.type code_DUP, @function
code_DUP:
movq    (%rbx), %rax
subq	$8, %rbx
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_DUP, .-code_DUP
.globl header_SWAP
.section .rodata
.str_SWAP:
.string "SWAP"
.data
.align 32
.type header_SWAP, @object
.size header_SWAP, 32
header_SWAP:
.quad header_DUP
.quad 4
.quad .str_SWAP
.quad code_SWAP
.globl key_SWAP
.align 4
.type key_SWAP, @object
.size key_SWAP, 4
key_SWAP:
.long 18
.text
.globl code_SWAP
.type code_SWAP, @function
code_SWAP:
movq    (%rbx), %rcx
movq    8(%rbx), %rax
movq    %rax, (%rbx)
movq    %rcx, 8(%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_SWAP, .-code_SWAP
.globl header_DROP
.section .rodata
.str_DROP:
.string "DROP"
.data
.align 32
.type header_DROP, @object
.size header_DROP, 32
header_DROP:
.quad header_SWAP
.quad 4
.quad .str_DROP
.quad code_DROP
.globl key_DROP
.align 4
.type key_DROP, @object
.size key_DROP, 4
key_DROP:
.long 19
.text
.globl code_DROP
.type code_DROP, @function
code_DROP:
addq	$8, %rbx
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_DROP, .-code_DROP
.globl header_OVER
.section .rodata
.str_OVER:
.string "OVER"
.data
.align 32
.type header_OVER, @object
.size header_OVER, 32
header_OVER:
.quad header_DROP
.quad 4
.quad .str_OVER
.quad code_OVER
.globl key_OVER
.align 4
.type key_OVER, @object
.size key_OVER, 4
key_OVER:
.long 20
.text
.globl code_OVER
.type code_OVER, @function
code_OVER:
movq    8(%rbx), %rax
subq	$8, %rbx
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_OVER, .-code_OVER
.globl header_ROT
.section .rodata
.str_ROT:
.string "ROT"
.data
.align 32
.type header_ROT, @object
.size header_ROT, 32
header_ROT:
.quad header_OVER
.quad 3
.quad .str_ROT
.quad code_ROT
.globl key_ROT
.align 4
.type key_ROT, @object
.size key_ROT, 4
key_ROT:
.long 21
.text
.globl code_ROT
.type code_ROT, @function
code_ROT:
movq	(%rbx), %rdx # ( a c d -- c d a )
movq	8(%rbx), %rcx
movq	16(%rbx), %rax
movq    %rcx, 16(%rbx)
movq    %rdx, 8(%rbx)
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_ROT, .-code_ROT
.globl header_neg_rot
.section .rodata
.str_neg_rot:
.string "-ROT"
.data
.align 32
.type header_neg_rot, @object
.size header_neg_rot, 32
header_neg_rot:
.quad header_ROT
.quad 4
.quad .str_neg_rot
.quad code_neg_rot
.globl key_neg_rot
.align 4
.type key_neg_rot, @object
.size key_neg_rot, 4
key_neg_rot:
.long 22
.text
.globl code_neg_rot
.type code_neg_rot, @function
code_neg_rot:
movq	(%rbx), %rdx # ( a c d -- d a c )
movq	8(%rbx), %rcx
movq	16(%rbx), %rax
movq	%rdx, 16(%rbx)
movq	%rax, 8(%rbx)
movq	%rcx, 0(%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_neg_rot, .-code_neg_rot
.globl header_two_drop
.section .rodata
.str_two_drop:
.string "2DROP"
.data
.align 32
.type header_two_drop, @object
.size header_two_drop, 32
header_two_drop:
.quad header_neg_rot
.quad 5
.quad .str_two_drop
.quad code_two_drop
.globl key_two_drop
.align 4
.type key_two_drop, @object
.size key_two_drop, 4
key_two_drop:
.long 23
.text
.globl code_two_drop
.type code_two_drop, @function
code_two_drop:
addq	$16, %rbx
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_two_drop, .-code_two_drop
.globl header_two_dup
.section .rodata
.str_two_dup:
.string "2DUP"
.data
.align 32
.type header_two_dup, @object
.size header_two_dup, 32
header_two_dup:
.quad header_two_drop
.quad 4
.quad .str_two_dup
.quad code_two_dup
.globl key_two_dup
.align 4
.type key_two_dup, @object
.size key_two_dup, 4
key_two_dup:
.long 24
.text
.globl code_two_dup
.type code_two_dup, @function
code_two_dup:
subq	$16, %rbx
movq    16(%rbx), %rax
movq    %rax, (%rbx)
movq    24(%rbx), %rax
movq    %rax, 8(%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_two_dup, .-code_two_dup
.globl header_two_swap
.section .rodata
.str_two_swap:
.string "2SWAP"
.data
.align 32
.type header_two_swap, @object
.size header_two_swap, 32
header_two_swap:
.quad header_two_dup
.quad 5
.quad .str_two_swap
.quad code_two_swap
.globl key_two_swap
.align 4
.type key_two_swap, @object
.size key_two_swap, 4
key_two_swap:
.long 25
.text
.globl code_two_swap
.type code_two_swap, @function
code_two_swap:
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
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_two_swap, .-code_two_swap
.globl header_two_over
.section .rodata
.str_two_over:
.string "2OVER"
.data
.align 32
.type header_two_over, @object
.size header_two_over, 32
header_two_over:
.quad header_two_swap
.quad 5
.quad .str_two_over
.quad code_two_over
.globl key_two_over
.align 4
.type key_two_over, @object
.size key_two_over, 4
key_two_over:
.long 26
.text
.globl code_two_over
.type code_two_over, @function
code_two_over:
subq	$16, %rbx
movq	32(%rbx), %rax
movq    %rax, (%rbx)
movq	40(%rbx), %rax
movq    %rax, 8(%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_two_over, .-code_two_over
.globl header_to_r
.section .rodata
.str_to_r:
.string ">R"
.data
.align 32
.type header_to_r, @object
.size header_to_r, 32
header_to_r:
.quad header_two_over
.quad 2
.quad .str_to_r
.quad code_to_r
.globl key_to_r
.align 4
.type key_to_r, @object
.size key_to_r, 4
key_to_r:
.long 27
.text
.globl code_to_r
.type code_to_r, @function
code_to_r:
movq    (%rbx), %rax
addq    $8, %rbx
movq   rsp(%rip), %rcx
subq   $8, %rcx
movq   %rcx, rsp(%rip)
movq   %rax, (%rcx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_to_r, .-code_to_r
.globl header_from_r
.section .rodata
.str_from_r:
.string "R>"
.data
.align 32
.type header_from_r, @object
.size header_from_r, 32
header_from_r:
.quad header_to_r
.quad 2
.quad .str_from_r
.quad code_from_r
.globl key_from_r
.align 4
.type key_from_r, @object
.size key_from_r, 4
key_from_r:
.long 28
.text
.globl code_from_r
.type code_from_r, @function
code_from_r:
movq   rsp(%rip), %rax
movq   (%rax), %rax
addq   $8, rsp(%rip)
subq    $8, %rbx
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_from_r, .-code_from_r
.globl header_fetch
.section .rodata
.str_fetch:
.string "@"
.data
.align 32
.type header_fetch, @object
.size header_fetch, 32
header_fetch:
.quad header_from_r
.quad 1
.quad .str_fetch
.quad code_fetch
.globl key_fetch
.align 4
.type key_fetch, @object
.size key_fetch, 4
key_fetch:
.long 29
.text
.globl code_fetch
.type code_fetch, @function
code_fetch:
movq    (%rbx), %rax
movq    (%rax), %rax
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_fetch, .-code_fetch
.globl header_store
.section .rodata
.str_store:
.string "!"
.data
.align 32
.type header_store, @object
.size header_store, 32
header_store:
.quad header_fetch
.quad 1
.quad .str_store
.quad code_store
.globl key_store
.align 4
.type key_store, @object
.size key_store, 4
key_store:
.long 30
.text
.globl code_store
.type code_store, @function
code_store:
movq	(%rbx), %rdx
movq	8(%rbx), %rax
movq	%rax, (%rdx)
addq	$16, %rbx
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_store, .-code_store
.globl header_cfetch
.section .rodata
.str_cfetch:
.string "C@"
.data
.align 32
.type header_cfetch, @object
.size header_cfetch, 32
header_cfetch:
.quad header_store
.quad 2
.quad .str_cfetch
.quad code_cfetch
.globl key_cfetch
.align 4
.type key_cfetch, @object
.size key_cfetch, 4
key_cfetch:
.long 31
.text
.globl code_cfetch
.type code_cfetch, @function
code_cfetch:
movq	(%rbx), %rax
movzbl	(%rax), %eax
movzbl	%al, %eax
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_cfetch, .-code_cfetch
.globl header_cstore
.section .rodata
.str_cstore:
.string "C!"
.data
.align 32
.type header_cstore, @object
.size header_cstore, 32
header_cstore:
.quad header_cfetch
.quad 2
.quad .str_cstore
.quad code_cstore
.globl key_cstore
.align 4
.type key_cstore, @object
.size key_cstore, 4
key_cstore:
.long 32
.text
.globl code_cstore
.type code_cstore, @function
code_cstore:
movq	(%rbx), %rax
movq	8(%rbx), %rcx
movb	%cl, (%rax)
addq	$16, %rbx
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_cstore, .-code_cstore
.globl header_two_fetch
.section .rodata
.str_two_fetch:
.string "2@"
.data
.align 32
.type header_two_fetch, @object
.size header_two_fetch, 32
header_two_fetch:
.quad header_cstore
.quad 2
.quad .str_two_fetch
.quad code_two_fetch
.globl key_two_fetch
.align 4
.type key_two_fetch, @object
.size key_two_fetch, 4
key_two_fetch:
.long 33
.text
.globl code_two_fetch
.type code_two_fetch, @function
code_two_fetch:
movq    (%rbx), %rdx
subq    $8, %rbx
movq    (%rdx), %rax
movq    %rax, (%rbx)
movq    8(%rdx), %rax
movq    %rax, 8(%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_two_fetch, .-code_two_fetch
.globl header_two_store
.section .rodata
.str_two_store:
.string "2!"
.data
.align 32
.type header_two_store, @object
.size header_two_store, 32
header_two_store:
.quad header_two_fetch
.quad 2
.quad .str_two_store
.quad code_two_store
.globl key_two_store
.align 4
.type key_two_store, @object
.size key_two_store, 4
key_two_store:
.long 34
.text
.globl code_two_store
.type code_two_store, @function
code_two_store:
movq    (%rbx), %rdx   # %rdx is the target address
movq    8(%rbx), %rax
movq    %rax, (%rdx)
movq    16(%rbx), %rax
movq    %rax, 8(%rdx)
addq    $24, %rbx
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_two_store, .-code_two_store
.globl header_raw_alloc
.section .rodata
.str_raw_alloc:
.string "(ALLOCATE)"
.data
.align 32
.type header_raw_alloc, @object
.size header_raw_alloc, 32
header_raw_alloc:
.quad header_two_store
.quad 10
.quad .str_raw_alloc
.quad code_raw_alloc
.globl key_raw_alloc
.align 4
.type key_raw_alloc, @object
.size key_raw_alloc, 4
key_raw_alloc:
.long 35
.text
.globl code_raw_alloc
.type code_raw_alloc, @function
code_raw_alloc:
movq	(%rbx), %rax
movq	%rax, %rdi
call	malloc@PLT
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_raw_alloc, .-code_raw_alloc
.globl header_here_ptr
.section .rodata
.str_here_ptr:
.string "(>HERE)"
.data
.align 32
.type header_here_ptr, @object
.size header_here_ptr, 32
header_here_ptr:
.quad header_raw_alloc
.quad 7
.quad .str_here_ptr
.quad code_here_ptr
.globl key_here_ptr
.align 4
.type key_here_ptr, @object
.size key_here_ptr, 4
key_here_ptr:
.long 36
.text
.globl code_here_ptr
.type code_here_ptr, @function
code_here_ptr:
subq	$8, %rbx
movl	$dsp, %eax
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_here_ptr, .-code_here_ptr
.globl header_STATE
.section .rodata
.str_STATE:
.string "STATE"
.data
.align 32
.type header_STATE, @object
.size header_STATE, 32
header_STATE:
.quad header_here_ptr
.quad 5
.quad .str_STATE
.quad code_STATE
.globl key_STATE
.align 4
.type key_STATE, @object
.size key_STATE, 4
key_STATE:
.long 37
.text
.globl code_STATE
.type code_STATE, @function
code_STATE:
movl	$state, %eax
subq	$8, %rbx
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_STATE, .-code_STATE
.globl header_branch
.section .rodata
.str_branch:
.string "(BRANCH)"
.data
.align 32
.type header_branch, @object
.size header_branch, 32
header_branch:
.quad header_STATE
.quad 8
.quad .str_branch
.quad code_branch
.globl key_branch
.align 4
.type key_branch, @object
.size key_branch, 4
key_branch:
.long 38
.text
.globl code_branch
.type code_branch, @function
code_branch:
movq    (%rbp), %rax   # The branch offset.
addq    %rax, %rbp
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_branch, .-code_branch
.globl header_zbranch
.section .rodata
.str_zbranch:
.string "(0BRANCH)"
.data
.align 32
.type header_zbranch, @object
.size header_zbranch, 32
header_zbranch:
.quad header_branch
.quad 9
.quad .str_zbranch
.quad code_zbranch
.globl key_zbranch
.align 4
.type key_zbranch, @object
.size key_zbranch, 4
key_zbranch:
.long 39
.text
.globl code_zbranch
.type code_zbranch, @function
code_zbranch:
movq    (%rbx), %rax
addq    $8, %rbx
testq	%rax, %rax
jne	.Lprim49
movq    (%rbp), %rax
jmp	.Lprim50
.Lprim49:
movl	$8, %eax
.Lprim50:
# Either way when we get down here, rax contains the delta.
addq    %rax, %rbp
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_zbranch, .-code_zbranch
.globl header_EXECUTE
.section .rodata
.str_EXECUTE:
.string "EXECUTE"
.data
.align 32
.type header_EXECUTE, @object
.size header_EXECUTE, 32
header_EXECUTE:
.quad header_zbranch
.quad 7
.quad .str_EXECUTE
.quad code_EXECUTE
.globl key_EXECUTE
.align 4
.type key_EXECUTE, @object
.size key_EXECUTE, 4
key_EXECUTE:
.long 40
.text
.globl code_EXECUTE
.type code_EXECUTE, @function
code_EXECUTE:
movq    (%rbx), %rax
addq    $8, %rbx
movq	%rax, cfa(%rip)
movq	(%rax), %rax
movq	%rax, ca(%rip)
jmp	*%rax
.size code_EXECUTE, .-code_EXECUTE
.globl header_EVALUATE
.section .rodata
.str_EVALUATE:
.string "EVALUATE"
.data
.align 32
.type header_EVALUATE, @object
.size header_EVALUATE, 32
header_EVALUATE:
.quad header_EXECUTE
.quad 8
.quad .str_EVALUATE
.quad code_EVALUATE
.globl key_EVALUATE
.align 4
.type key_EVALUATE, @object
.size key_EVALUATE, 4
key_EVALUATE:
.long 41
.text
.globl code_EVALUATE
.type code_EVALUATE, @function
code_EVALUATE:
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
.size code_EVALUATE, .-code_EVALUATE
.globl header_REFILL
.section .rodata
.str_REFILL:
.string "REFILL"
.data
.align 32
.type header_REFILL, @object
.size header_REFILL, 32
header_REFILL:
.quad header_EVALUATE
.quad 6
.quad .str_REFILL
.quad code_REFILL
.globl key_REFILL
.align 4
.type key_REFILL, @object
.size key_REFILL, 4
key_REFILL:
.long 42
.text
.globl code_REFILL
.type code_REFILL, @function
code_REFILL:
movq	inputIndex(%rip), %rax
salq	$5, %rax
addq	$inputSources+16, %rax
movq	(%rax), %rax
cmpq	$-1, %rax
jne	.Lprim69
subq	$8, %rbx
movq	(%rbx), %rax
movq	$0, (%rax)
jmp	.Lprim70
.Lprim69:
subq	$8, %rbx
call	refill_@PLT
movq	%rax, (%rbx)
.Lprim70:
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_REFILL, .-code_REFILL
.globl header_ACCEPT
.section .rodata
.str_ACCEPT:
.string "ACCEPT"
.data
.align 32
.type header_ACCEPT, @object
.size header_ACCEPT, 32
header_ACCEPT:
.quad header_REFILL
.quad 6
.quad .str_ACCEPT
.quad code_ACCEPT
.globl key_ACCEPT
.align 4
.type key_ACCEPT, @object
.size key_ACCEPT, 4
key_ACCEPT:
.long 43
.text
.globl code_ACCEPT
.type code_ACCEPT, @function
code_ACCEPT:
movl	$0, %edi
call	readline@PLT
movq	%rax, str1(%rip)
movq	str1(%rip), %rdi
call	strlen@PLT
movq	%rax, c1(%rip)
movq	(%rbx), %rdx
movq	c1(%rip), %rax
cmpq	%rax, %rdx
jge	.Lprim73
movq	(%rbx), %rax
movq	%rax, c1(%rip)
.Lprim73:
movq	8(%rbx), %rax
movq	c1(%rip), %rdx
movq	str1(%rip), %rsi
movq	%rax, %rdi
call	strncpy@PLT
movq	c1(%rip), %rax
addq	$8, %rbx
movq	%rax, (%rbx)
movq	str1(%rip), %rdi
call	free@PLT
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_ACCEPT, .-code_ACCEPT
.globl header_KEY
.section .rodata
.str_KEY:
.string "KEY"
.data
.align 32
.type header_KEY, @object
.size header_KEY, 32
header_KEY:
.quad header_ACCEPT
.quad 3
.quad .str_KEY
.quad code_KEY
.globl key_KEY
.align 4
.type key_KEY, @object
.size key_KEY, 4
key_KEY:
.long 44
.text
.globl code_KEY
.type code_KEY, @function
code_KEY:
call key_@PLT
movq c1(%rip), %rax
subq $8, %rbx
movq %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_KEY, .-code_KEY
.globl header_latest
.section .rodata
.str_latest:
.string "(LATEST)"
.data
.align 32
.type header_latest, @object
.size header_latest, 32
header_latest:
.quad header_KEY
.quad 8
.quad .str_latest
.quad code_latest
.globl key_latest
.align 4
.type key_latest, @object
.size key_latest, 4
key_latest:
.long 45
.text
.globl code_latest
.type code_latest, @function
code_latest:
subq	$8, %rbx
movq    compilationWordlist(%rip), %rax
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_latest, .-code_latest
.globl header_dictionary_info
.section .rodata
.str_dictionary_info:
.string "(DICT-INFO)"
.data
.align 32
.type header_dictionary_info, @object
.size header_dictionary_info, 32
header_dictionary_info:
.quad header_latest
.quad 11
.quad .str_dictionary_info
.quad code_dictionary_info
.globl key_dictionary_info
.align 4
.type key_dictionary_info, @object
.size key_dictionary_info, 4
key_dictionary_info:
.long 46
.text
.globl code_dictionary_info
.type code_dictionary_info, @function
code_dictionary_info:
subq    $24, %rbx
movl	$compilationWordlist, %eax
movq	%rax, 16(%rbx)
movl	$searchIndex, %eax
movq	%rax, 8(%rbx)
movl    $searchArray, %eax
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_dictionary_info, .-code_dictionary_info
.globl header_in_ptr
.section .rodata
.str_in_ptr:
.string ">IN"
.data
.align 32
.type header_in_ptr, @object
.size header_in_ptr, 32
header_in_ptr:
.quad header_dictionary_info
.quad 3
.quad .str_in_ptr
.quad code_in_ptr
.globl key_in_ptr
.align 4
.type key_in_ptr, @object
.size key_in_ptr, 4
key_in_ptr:
.long 47
.text
.globl code_in_ptr
.type code_in_ptr, @function
code_in_ptr:
subq	$8, %rbx
movq	inputIndex(%rip), %rdx
salq	$5, %rdx
addq	$inputSources, %rdx
addq	$8, %rdx
movq	%rdx, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_in_ptr, .-code_in_ptr
.globl header_EMIT
.section .rodata
.str_EMIT:
.string "EMIT"
.data
.align 32
.type header_EMIT, @object
.size header_EMIT, 32
header_EMIT:
.quad header_in_ptr
.quad 4
.quad .str_EMIT
.quad code_EMIT
.globl key_EMIT
.align 4
.type key_EMIT, @object
.size key_EMIT, 4
key_EMIT:
.long 48
.text
.globl code_EMIT
.type code_EMIT, @function
code_EMIT:
movq	stdout(%rip), %rdx
movq    (%rbx), %rax
addq    $8, %rbx
movq	%rdx, %rsi
movl	%eax, %edi
call	fputc@PLT
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_EMIT, .-code_EMIT
.globl header_SOURCE
.section .rodata
.str_SOURCE:
.string "SOURCE"
.data
.align 32
.type header_SOURCE, @object
.size header_SOURCE, 32
header_SOURCE:
.quad header_EMIT
.quad 6
.quad .str_SOURCE
.quad code_SOURCE
.globl key_SOURCE
.align 4
.type key_SOURCE, @object
.size key_SOURCE, 4
key_SOURCE:
.long 49
.text
.globl code_SOURCE
.type code_SOURCE, @function
code_SOURCE:
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
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_SOURCE, .-code_SOURCE
.globl header_source_id
.section .rodata
.str_source_id:
.string "SOURCE-ID"
.data
.align 32
.type header_source_id, @object
.size header_source_id, 32
header_source_id:
.quad header_SOURCE
.quad 9
.quad .str_source_id
.quad code_source_id
.globl key_source_id
.align 4
.type key_source_id, @object
.size key_source_id, 4
key_source_id:
.long 50
.text
.globl code_source_id
.type code_source_id, @function
code_source_id:
subq	$8, %rbx
movq	inputIndex(%rip), %rax
salq	$5, %rax
addq	$inputSources+16, %rax
movq	(%rax), %rax
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_source_id, .-code_source_id
.globl header_size_cell
.section .rodata
.str_size_cell:
.string "(/CELL)"
.data
.align 32
.type header_size_cell, @object
.size header_size_cell, 32
header_size_cell:
.quad header_source_id
.quad 7
.quad .str_size_cell
.quad code_size_cell
.globl key_size_cell
.align 4
.type key_size_cell, @object
.size key_size_cell, 4
key_size_cell:
.long 51
.text
.globl code_size_cell
.type code_size_cell, @function
code_size_cell:
subq	$8, %rbx
movq	$8, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_size_cell, .-code_size_cell
.globl header_size_char
.section .rodata
.str_size_char:
.string "(/CHAR)"
.data
.align 32
.type header_size_char, @object
.size header_size_char, 32
header_size_char:
.quad header_size_cell
.quad 7
.quad .str_size_char
.quad code_size_char
.globl key_size_char
.align 4
.type key_size_char, @object
.size key_size_char, 4
key_size_char:
.long 52
.text
.globl code_size_char
.type code_size_char, @function
code_size_char:
subq	$8, %rbx
movq	$1, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_size_char, .-code_size_char
.globl header_CELLS
.section .rodata
.str_CELLS:
.string "CELLS"
.data
.align 32
.type header_CELLS, @object
.size header_CELLS, 32
header_CELLS:
.quad header_size_char
.quad 5
.quad .str_CELLS
.quad code_CELLS
.globl key_CELLS
.align 4
.type key_CELLS, @object
.size key_CELLS, 4
key_CELLS:
.long 53
.text
.globl code_CELLS
.type code_CELLS, @function
code_CELLS:
movq	(%rbx), %rax
salq	$3, %rax
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_CELLS, .-code_CELLS
.globl header_CHARS
.section .rodata
.str_CHARS:
.string "CHARS"
.data
.align 32
.type header_CHARS, @object
.size header_CHARS, 32
header_CHARS:
.quad header_CELLS
.quad 5
.quad .str_CHARS
.quad code_CHARS
.globl key_CHARS
.align 4
.type key_CHARS, @object
.size key_CHARS, 4
key_CHARS:
.long 54
.text
.globl code_CHARS
.type code_CHARS, @function
code_CHARS:
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_CHARS, .-code_CHARS
.globl header_unit_bits
.section .rodata
.str_unit_bits:
.string "(ADDRESS-UNIT-BITS)"
.data
.align 32
.type header_unit_bits, @object
.size header_unit_bits, 32
header_unit_bits:
.quad header_CHARS
.quad 19
.quad .str_unit_bits
.quad code_unit_bits
.globl key_unit_bits
.align 4
.type key_unit_bits, @object
.size key_unit_bits, 4
key_unit_bits:
.long 55
.text
.globl code_unit_bits
.type code_unit_bits, @function
code_unit_bits:
subq	$8, %rbx
movq	$8, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_unit_bits, .-code_unit_bits
.globl header_stack_cells
.section .rodata
.str_stack_cells:
.string "(STACK-CELLS)"
.data
.align 32
.type header_stack_cells, @object
.size header_stack_cells, 32
header_stack_cells:
.quad header_unit_bits
.quad 13
.quad .str_stack_cells
.quad code_stack_cells
.globl key_stack_cells
.align 4
.type key_stack_cells, @object
.size key_stack_cells, 4
key_stack_cells:
.long 56
.text
.globl code_stack_cells
.type code_stack_cells, @function
code_stack_cells:
subq	$8, %rbx
movq	$16384, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_stack_cells, .-code_stack_cells
.globl header_return_stack_cells
.section .rodata
.str_return_stack_cells:
.string "(RETURN-STACK-CELLS)"
.data
.align 32
.type header_return_stack_cells, @object
.size header_return_stack_cells, 32
header_return_stack_cells:
.quad header_stack_cells
.quad 20
.quad .str_return_stack_cells
.quad code_return_stack_cells
.globl key_return_stack_cells
.align 4
.type key_return_stack_cells, @object
.size key_return_stack_cells, 4
key_return_stack_cells:
.long 57
.text
.globl code_return_stack_cells
.type code_return_stack_cells, @function
code_return_stack_cells:
subq	$8, %rbx
movq	$1024, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_return_stack_cells, .-code_return_stack_cells
.globl header_to_does
.section .rodata
.str_to_does:
.string "(>DOES)"
.data
.align 32
.type header_to_does, @object
.size header_to_does, 32
header_to_does:
.quad header_return_stack_cells
.quad 7
.quad .str_to_does
.quad code_to_does
.globl key_to_does
.align 4
.type key_to_does, @object
.size key_to_does, 4
key_to_does:
.long 58
.text
.globl code_to_does
.type code_to_does, @function
code_to_does:
movq	(%rbx), %rax
addq	$32, %rax
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_to_does, .-code_to_does
.globl header_to_cfa
.section .rodata
.str_to_cfa:
.string "(>CFA)"
.data
.align 32
.type header_to_cfa, @object
.size header_to_cfa, 32
header_to_cfa:
.quad header_to_does
.quad 6
.quad .str_to_cfa
.quad code_to_cfa
.globl key_to_cfa
.align 4
.type key_to_cfa, @object
.size key_to_cfa, 4
key_to_cfa:
.long 59
.text
.globl code_to_cfa
.type code_to_cfa, @function
code_to_cfa:
movq	(%rbx), %rax
addq	$24, %rax
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_to_cfa, .-code_to_cfa
.globl header_to_body
.section .rodata
.str_to_body:
.string ">BODY"
.data
.align 32
.type header_to_body, @object
.size header_to_body, 32
header_to_body:
.quad header_to_cfa
.quad 5
.quad .str_to_body
.quad code_to_body
.globl key_to_body
.align 4
.type key_to_body, @object
.size key_to_body, 4
key_to_body:
.long 60
.text
.globl code_to_body
.type code_to_body, @function
code_to_body:
movq	(%rbx), %rax
addq	$16, %rax
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_to_body, .-code_to_body
.globl header_last_word
.section .rodata
.str_last_word:
.string "(LAST-WORD)"
.data
.align 32
.type header_last_word, @object
.size header_last_word, 32
header_last_word:
.quad header_to_body
.quad 11
.quad .str_last_word
.quad code_last_word
.globl key_last_word
.align 4
.type key_last_word, @object
.size key_last_word, 4
key_last_word:
.long 61
.text
.globl code_last_word
.type code_last_word, @function
code_last_word:
subq	$8, %rbx
movq	lastWord(%rip), %rax
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_last_word, .-code_last_word
.globl header_docol
.section .rodata
.str_docol:
.string "(DOCOL)"
.data
.align 32
.type header_docol, @object
.size header_docol, 32
header_docol:
.quad header_last_word
.quad 7
.quad .str_docol
.quad code_docol
.globl key_docol
.align 4
.type key_docol, @object
.size key_docol, 4
key_docol:
.long 62
.text
.globl code_docol
.type code_docol, @function
code_docol:
movq	rsp(%rip), %rax
subq	$8, %rax
movq	%rax, rsp(%rip)
movq	%rbp, (%rax)
movq	cfa(%rip), %rax
addq	$8, %rax
movq	%rax, %rbp
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_docol, .-code_docol
.globl header_dolit
.section .rodata
.str_dolit:
.string "(DOLIT)"
.data
.align 32
.type header_dolit, @object
.size header_dolit, 32
header_dolit:
.quad header_docol
.quad 7
.quad .str_dolit
.quad code_dolit
.globl key_dolit
.align 4
.type key_dolit, @object
.size key_dolit, 4
key_dolit:
.long 63
.text
.globl code_dolit
.type code_dolit, @function
code_dolit:
subq	$8, %rbx
movq    (%rbp), %rax
movq    %rax, (%rbx)
addq    $8, %rbp
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_dolit, .-code_dolit
.globl header_dostring
.section .rodata
.str_dostring:
.string "(DOSTRING)"
.data
.align 32
.type header_dostring, @object
.size header_dostring, 32
header_dostring:
.quad header_dolit
.quad 10
.quad .str_dostring
.quad code_dostring
.globl key_dostring
.align 4
.type key_dostring, @object
.size key_dostring, 4
key_dostring:
.long 64
.text
.globl code_dostring
.type code_dostring, @function
code_dostring:
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
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_dostring, .-code_dostring
.globl header_dodoes
.section .rodata
.str_dodoes:
.string "(DODOES)"
.data
.align 32
.type header_dodoes, @object
.size header_dodoes, 32
header_dodoes:
.quad header_dostring
.quad 8
.quad .str_dodoes
.quad code_dodoes
.globl key_dodoes
.align 4
.type key_dodoes, @object
.size key_dodoes, 4
key_dodoes:
.long 65
.text
.globl code_dodoes
.type code_dodoes, @function
code_dodoes:
movq	cfa(%rip), %rax    # CFA in %rax
movq    %rax, %rcx
addq    $16, %rcx
subq    $8, %rbx
movq    %rcx, (%rbx)       # Push the data space address.
addq    $8, %rax
movq    (%rax), %rax       # Now %rax holds the does> address
movq    %rax, %rcx         # Which I'll set aside.
testq	%rax, %rax
je	.Lprim98
movq	rsp(%rip), %rax
subq	$8, %rax
movq	%rax, rsp(%rip)
movq	%rbp, (%rax)
movq	%rcx, %rbp
.Lprim98:
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_dodoes, .-code_dodoes
.globl header_PARSE
.section .rodata
.str_PARSE:
.string "PARSE"
.data
.align 32
.type header_PARSE, @object
.size header_PARSE, 32
header_PARSE:
.quad header_dodoes
.quad 5
.quad .str_PARSE
.quad code_PARSE
.globl key_PARSE
.align 4
.type key_PARSE, @object
.size key_PARSE, 4
key_PARSE:
.long 66
.text
.globl code_PARSE
.type code_PARSE, @function
code_PARSE:
movq (%rbx), %rax
movb %al, ch1(%rip)
call	parse_@PLT
subq $8, %rbx
movq str1(%rip), %rax
movq %rax, 8(%rbx)
movq c1(%rip), %rax
movq %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_PARSE, .-code_PARSE
.globl header_parse_name
.section .rodata
.str_parse_name:
.string "PARSE-NAME"
.data
.align 32
.type header_parse_name, @object
.size header_parse_name, 32
header_parse_name:
.quad header_PARSE
.quad 10
.quad .str_parse_name
.quad code_parse_name
.globl key_parse_name
.align 4
.type key_parse_name, @object
.size key_parse_name, 4
key_parse_name:
.long 67
.text
.globl code_parse_name
.type code_parse_name, @function
code_parse_name:
call	parse_name_stacked@PLT
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_parse_name, .-code_parse_name
.globl header_to_number
.section .rodata
.str_to_number:
.string ">NUMBER"
.data
.align 32
.type header_to_number, @object
.size header_to_number, 32
header_to_number:
.quad header_parse_name
.quad 7
.quad .str_to_number
.quad code_to_number
.globl key_to_number
.align 4
.type key_to_number, @object
.size key_to_number, 4
key_to_number:
.long 68
.text
.globl code_to_number
.type code_to_number, @function
code_to_number:
call	to_number_@PLT
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_to_number, .-code_to_number
.globl header_CREATE
.section .rodata
.str_CREATE:
.string "CREATE"
.data
.align 32
.type header_CREATE, @object
.size header_CREATE, 32
header_CREATE:
.quad header_to_number
.quad 6
.quad .str_CREATE
.quad code_CREATE
.globl key_CREATE
.align 4
.type key_CREATE, @object
.size key_CREATE, 4
key_CREATE:
.long 69
.text
.globl code_CREATE
.type code_CREATE, @function
code_CREATE:
call	parse_name_stacked@PLT
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
call	malloc@PLT
movq	%rax, 16(%r12)
movq	(%rbx), %rdx
movq	8(%rbx), %rsi
movq	16(%r12), %rax
movq	%rax, %rdi
call	strncpy@PLT
addq	$16, %rbx
movq	tempHeader(%rip), %rax
movq	$code_dodoes, 24(%rax)
movq	dsp(%rip), %rax
leaq	8(%rax), %rdx
movq	%rdx, dsp(%rip)
movq	$0, (%rax)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_CREATE, .-code_CREATE
.globl header_find
.section .rodata
.str_find:
.string "(FIND)"
.data
.align 32
.type header_find, @object
.size header_find, 32
header_find:
.quad header_CREATE
.quad 6
.quad .str_find
.quad code_find
.globl key_find
.align 4
.type key_find, @object
.size key_find, 4
key_find:
.long 70
.text
.globl code_find
.type code_find, @function
code_find:
call	find_@PLT
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_find, .-code_find
.globl header_DEPTH
.section .rodata
.str_DEPTH:
.string "DEPTH"
.data
.align 32
.type header_DEPTH, @object
.size header_DEPTH, 32
header_DEPTH:
.quad header_find
.quad 5
.quad .str_DEPTH
.quad code_DEPTH
.globl key_DEPTH
.align 4
.type key_DEPTH, @object
.size key_DEPTH, 4
key_DEPTH:
.long 71
.text
.globl code_DEPTH
.type code_DEPTH, @function
code_DEPTH:
movq	spTop(%rip), %rax
subq	%rbx, %rax
shrq	$3, %rax
subq    $8, %rbx
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_DEPTH, .-code_DEPTH
.globl header_sp_fetch
.section .rodata
.str_sp_fetch:
.string "SP@"
.data
.align 32
.type header_sp_fetch, @object
.size header_sp_fetch, 32
header_sp_fetch:
.quad header_DEPTH
.quad 3
.quad .str_sp_fetch
.quad code_sp_fetch
.globl key_sp_fetch
.align 4
.type key_sp_fetch, @object
.size key_sp_fetch, 4
key_sp_fetch:
.long 72
.text
.globl code_sp_fetch
.type code_sp_fetch, @function
code_sp_fetch:
movq    %rbx, %rax
subq    $8, %rbx
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_sp_fetch, .-code_sp_fetch
.globl header_sp_store
.section .rodata
.str_sp_store:
.string "SP!"
.data
.align 32
.type header_sp_store, @object
.size header_sp_store, 32
header_sp_store:
.quad header_sp_fetch
.quad 3
.quad .str_sp_store
.quad code_sp_store
.globl key_sp_store
.align 4
.type key_sp_store, @object
.size key_sp_store, 4
key_sp_store:
.long 73
.text
.globl code_sp_store
.type code_sp_store, @function
code_sp_store:
movq	(%rbx), %rbx
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_sp_store, .-code_sp_store
.globl header_rp_fetch
.section .rodata
.str_rp_fetch:
.string "RP@"
.data
.align 32
.type header_rp_fetch, @object
.size header_rp_fetch, 32
header_rp_fetch:
.quad header_sp_store
.quad 3
.quad .str_rp_fetch
.quad code_rp_fetch
.globl key_rp_fetch
.align 4
.type key_rp_fetch, @object
.size key_rp_fetch, 4
key_rp_fetch:
.long 74
.text
.globl code_rp_fetch
.type code_rp_fetch, @function
code_rp_fetch:
subq	$8, %rbx
movq	rsp(%rip), %rax
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_rp_fetch, .-code_rp_fetch
.globl header_rp_store
.section .rodata
.str_rp_store:
.string "RP!"
.data
.align 32
.type header_rp_store, @object
.size header_rp_store, 32
header_rp_store:
.quad header_rp_fetch
.quad 3
.quad .str_rp_store
.quad code_rp_store
.globl key_rp_store
.align 4
.type key_rp_store, @object
.size key_rp_store, 4
key_rp_store:
.long 75
.text
.globl code_rp_store
.type code_rp_store, @function
code_rp_store:
movq	(%rbx), %rax
addq    $8, %rbx
movq	%rax, rsp(%rip)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_rp_store, .-code_rp_store
.globl header_QUIT
.section .rodata
.str_QUIT:
.string "QUIT"
.data
.align 32
.type header_QUIT, @object
.size header_QUIT, 32
header_QUIT:
.quad header_rp_store
.quad 4
.quad .str_QUIT
.quad code_QUIT
.globl key_QUIT
.align 4
.type key_QUIT, @object
.size key_QUIT, 4
key_QUIT:
.long 76
.text
.globl code_QUIT
.type code_QUIT, @function
code_QUIT:
movq	$0, inputIndex(%rip)
call	quit_@PLT
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_QUIT, .-code_QUIT
.globl header_BYE
.section .rodata
.str_BYE:
.string "BYE"
.data
.align 32
.type header_BYE, @object
.size header_BYE, 32
header_BYE:
.quad header_QUIT
.quad 3
.quad .str_BYE
.quad code_BYE
.globl key_BYE
.align 4
.type key_BYE, @object
.size key_BYE, 4
key_BYE:
.long 77
.text
.globl code_BYE
.type code_BYE, @function
code_BYE:
movl	$0, %edi
call	exit@PLT
.size code_BYE, .-code_BYE
.globl header_compile_comma
.section .rodata
.str_compile_comma:
.string "COMPILE,"
.data
.align 32
.type header_compile_comma, @object
.size header_compile_comma, 32
header_compile_comma:
.quad header_BYE
.quad 8
.quad .str_compile_comma
.quad code_compile_comma
.globl key_compile_comma
.align 4
.type key_compile_comma, @object
.size key_compile_comma, 4
key_compile_comma:
.long 78
.text
.globl code_compile_comma
.type code_compile_comma, @function
code_compile_comma:
movl	$0, %eax
call	compile_@PLT
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_compile_comma, .-code_compile_comma
.globl header_LITERAL
.section .rodata
.str_LITERAL:
.string "LITERAL"
.data
.align 32
.type header_LITERAL, @object
.size header_LITERAL, 32
header_LITERAL:
.quad header_compile_comma
.quad 519
.quad .str_LITERAL
.quad code_LITERAL
.globl key_LITERAL
.align 4
.type key_LITERAL, @object
.size key_LITERAL, 4
key_LITERAL:
.long 79
.text
.globl code_LITERAL
.type code_LITERAL, @function
code_LITERAL:
movl	$0, %eax
call	compile_lit_@PLT
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_LITERAL, .-code_LITERAL
.globl header_compile_literal
.section .rodata
.str_compile_literal:
.string "[LITERAL]"
.data
.align 32
.type header_compile_literal, @object
.size header_compile_literal, 32
header_compile_literal:
.quad header_LITERAL
.quad 9
.quad .str_compile_literal
.quad code_compile_literal
.globl key_compile_literal
.align 4
.type key_compile_literal, @object
.size key_compile_literal, 4
key_compile_literal:
.long 80
.text
.globl code_compile_literal
.type code_compile_literal, @function
code_compile_literal:
movl	$0, %eax
call	compile_lit_@PLT
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_compile_literal, .-code_compile_literal
.globl header_compile_zbranch
.section .rodata
.str_compile_zbranch:
.string "[0BRANCH]"
.data
.align 32
.type header_compile_zbranch, @object
.size header_compile_zbranch, 32
header_compile_zbranch:
.quad header_compile_literal
.quad 9
.quad .str_compile_zbranch
.quad code_compile_zbranch
.globl key_compile_zbranch
.align 4
.type key_compile_zbranch, @object
.size key_compile_zbranch, 4
key_compile_zbranch:
.long 81
.text
.globl code_compile_zbranch
.type code_compile_zbranch, @function
code_compile_zbranch:
subq	$8, %rbx
movl	$header_zbranch+24, %eax
movq	%rax, (%rbx)
movl	$0, %eax
call	compile_@PLT
jmp	.Lprim244
.Lprim245:
call	drain_queue_@PLT
.Lprim244:
movl	queue_length(%rip), %eax
testl	%eax, %eax
jg	.Lprim245
subq	$8, %rbx
movq	dsp(%rip), %rax
movq	%rax, (%rbx)
movq    $0, (%rax)
addq    $8, %rax
movq    %rax, dsp(%rip)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_compile_zbranch, .-code_compile_zbranch
.globl header_compile_branch
.section .rodata
.str_compile_branch:
.string "[BRANCH]"
.data
.align 32
.type header_compile_branch, @object
.size header_compile_branch, 32
header_compile_branch:
.quad header_compile_zbranch
.quad 8
.quad .str_compile_branch
.quad code_compile_branch
.globl key_compile_branch
.align 4
.type key_compile_branch, @object
.size key_compile_branch, 4
key_compile_branch:
.long 82
.text
.globl code_compile_branch
.type code_compile_branch, @function
code_compile_branch:
subq	$8, %rbx
movl	$header_branch+24, %edx
movq	%rdx, (%rbx)
movl	$0, %eax
call	compile_@PLT
jmp	.Lprim248
.Lprim249:
call	drain_queue_@PLT
.Lprim248:
movl	queue_length(%rip), %eax
testl	%eax, %eax
jg	.Lprim249
subq	$8, %rbx
movq	dsp(%rip), %rax
movq	%rax, (%rbx)
movq	dsp(%rip), %rax
leaq	8(%rax), %rdx
movq	%rdx, dsp(%rip)
movq	$0, (%rax)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_compile_branch, .-code_compile_branch
.globl header_control_flush
.section .rodata
.str_control_flush:
.string "(CONTROL-FLUSH)"
.data
.align 32
.type header_control_flush, @object
.size header_control_flush, 32
header_control_flush:
.quad header_compile_branch
.quad 15
.quad .str_control_flush
.quad code_control_flush
.globl key_control_flush
.align 4
.type key_control_flush, @object
.size key_control_flush, 4
key_control_flush:
.long 83
.text
.globl code_control_flush
.type code_control_flush, @function
code_control_flush:
jmp	.Lprim252
.Lprim253:
call	drain_queue_@PLT
.Lprim252:
movl	queue_length(%rip), %eax
testl	%eax, %eax
jg	.Lprim253
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_control_flush, .-code_control_flush
.globl header_debug_break
.section .rodata
.str_debug_break:
.string "(DEBUG)"
.data
.align 32
.type header_debug_break, @object
.size header_debug_break, 32
header_debug_break:
.quad header_control_flush
.quad 7
.quad .str_debug_break
.quad code_debug_break
.globl key_debug_break
.align 4
.type key_debug_break, @object
.size key_debug_break, 4
key_debug_break:
.long 84
.text
.globl code_debug_break
.type code_debug_break, @function
code_debug_break:
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_debug_break, .-code_debug_break
.globl header_close_file
.section .rodata
.str_close_file:
.string "CLOSE-FILE"
.data
.align 32
.type header_close_file, @object
.size header_close_file, 32
header_close_file:
.quad header_debug_break
.quad 10
.quad .str_close_file
.quad code_close_file
.globl key_close_file
.align 4
.type key_close_file, @object
.size key_close_file, 4
key_close_file:
.long 85
.text
.globl code_close_file
.type code_close_file, @function
code_close_file:
movq	(%rbx), %rdi
call	fclose@PLT
cltq
testq	%rax, %rax
je	.Lprim256
call	__errno_location@PLT
movl	(%rax), %eax
cltq
jmp	.Lprim257
.Lprim256:
movl	$0, %eax
.Lprim257:
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_close_file, .-code_close_file
.globl header_create_file
.section .rodata
.str_create_file:
.string "CREATE-FILE"
.data
.align 32
.type header_create_file, @object
.size header_create_file, 32
header_create_file:
.quad header_close_file
.quad 11
.quad .str_create_file
.quad code_create_file
.globl key_create_file
.align 4
.type key_create_file, @object
.size key_create_file, 4
key_create_file:
.long 86
.text
.globl code_create_file
.type code_create_file, @function
code_create_file:
movq    8(%rbx), %rdx
movq    16(%rbx), %rsi
movl	$tempBuf, %edi
call	strncpy@PLT
movq	8(%rbx), %rax
movb	$0, tempBuf(%rax)
addq	$8, %rbx
movq    (%rbx), %rax
orq     $8, %rax
movq	file_modes(,%rax,8), %rax
movq	%rax, %rsi
movl	$tempBuf, %edi
call	fopen@PLT
movq	%rax, 8(%rbx)
testq	%rax, %rax
jne	.Lprim260
call	__errno_location@PLT
movl	(%rax), %eax
cltq
jmp	.Lprim261
.Lprim260:
movl	$0, %eax
.Lprim261:
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_create_file, .-code_create_file
.globl header_open_file
.section .rodata
.str_open_file:
.string "OPEN-FILE"
.data
.align 32
.type header_open_file, @object
.size header_open_file, 32
header_open_file:
.quad header_create_file
.quad 9
.quad .str_open_file
.quad code_open_file
.globl key_open_file
.align 4
.type key_open_file, @object
.size key_open_file, 4
key_open_file:
.long 87
.text
.globl code_open_file
.type code_open_file, @function
code_open_file:
movq    8(%rbx), %rdx
movq    16(%rbx), %rsi
movl	$tempBuf, %edi
call	strncpy@PLT
movq	8(%rbx), %rax
movb	$0, tempBuf(%rax)
movq	(%rbx), %rax
movq	file_modes(,%rax,8), %rax
movq	%rax, %rsi
movl	$tempBuf, %edi
call	fopen@PLT
movq	%rax, 16(%rbx)
testq	%rax, %rax
jne	.Lprim264
movq	(%rbx), %rax
andl	$2, %eax
testq	%rax, %rax
je	.Lprim264
movq	(%rbx), %rax
orq	$8, %rax
movq	file_modes(,%rax,8), %rax
movq	%rax, %rsi
movl	$tempBuf, %edi
call	fopen@PLT
movq	%rax, 16(%rbx)
.Lprim264:
movq	16(%rbx), %rax
testq	%rax, %rax
jne	.Lprim265
call	__errno_location@PLT
movl	(%rax), %eax
cltq
jmp	.Lprim266
.Lprim265:
movl	$0, %eax
.Lprim266:
addq	$8, %rbx
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_open_file, .-code_open_file
.globl header_delete_file
.section .rodata
.str_delete_file:
.string "DELETE-FILE"
.data
.align 32
.type header_delete_file, @object
.size header_delete_file, 32
header_delete_file:
.quad header_open_file
.quad 11
.quad .str_delete_file
.quad code_delete_file
.globl key_delete_file
.align 4
.type key_delete_file, @object
.size key_delete_file, 4
key_delete_file:
.long 88
.text
.globl code_delete_file
.type code_delete_file, @function
code_delete_file:
movq    (%rbx), %rdx
movq    8(%rbx), %rsi
movl	$tempBuf, %edi
call	strncpy@PLT
movq	(%rbx), %rax
movb	$0, tempBuf(%rax)
addq	$8, %rbx
movl	$tempBuf, %edi
call	remove@PLT
cltq
movq	%rax, (%rbx)
cmpq	$-1, %rax
jne	.Lprim269
call	__errno_location@PLT
movl	(%rax), %eax
cltq
movq	%rax, (%rbx)
.Lprim269:
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_delete_file, .-code_delete_file
.globl header_file_position
.section .rodata
.str_file_position:
.string "FILE-POSITION"
.data
.align 32
.type header_file_position, @object
.size header_file_position, 32
header_file_position:
.quad header_delete_file
.quad 13
.quad .str_file_position
.quad code_file_position
.globl key_file_position
.align 4
.type key_file_position, @object
.size key_file_position, 4
key_file_position:
.long 89
.text
.globl code_file_position
.type code_file_position, @function
code_file_position:
subq	$16, %rbx
movq    $0, 8(%rbx)
movq    16(%rbx), %rdi
call	ftell@PLT
movq	%rax, 16(%rbx)
cmpq	$-1, %rax
jne	.Lprim272
call	__errno_location@PLT
movl	(%rax), %eax
cltq
jmp	.Lprim273
.Lprim272:
movl	$0, %eax
.Lprim273:
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_file_position, .-code_file_position
.globl header_file_size
.section .rodata
.str_file_size:
.string "FILE-SIZE"
.data
.align 32
.type header_file_size, @object
.size header_file_size, 32
header_file_size:
.quad header_file_position
.quad 9
.quad .str_file_size
.quad code_file_size
.globl key_file_size
.align 4
.type key_file_size, @object
.size key_file_size, 4
key_file_size:
.long 90
.text
.globl code_file_size
.type code_file_size, @function
code_file_size:
subq	$16, %rbx
movq    $0, 8(%rbx)
movq    16(%rbx), %rdi
call	ftell@PLT
movq	%rax, c1(%rip)
testq	%rax, %rax
jns	.Lprim276
call	__errno_location@PLT
movl	(%rax), %eax
cltq
movq	%rax, (%rbx)
jmp	.Lprim277
.Lprim276:
movl	$2, %edx
movl	$0, %esi
movq	16(%rbx), %rdi
call	fseek@PLT
cltq
movq	%rax, c2(%rip)
testq	%rax, %rax
jns	.Lprim278
call	__errno_location@PLT
movl	(%rax), %eax
cltq
movq	%rax, (%rbx)
movq	16(%rbx), %rdi
movl	$0, %edx
movq	c1(%rip), %rsi
call	fseek@PLT
jmp	.Lprim277
.Lprim278:
movq	16(%rbx), %rdi
call	ftell@PLT
movq	%rax, c2(%rip)
movq	16(%rbx), %rdi
movl	$0, %edx
movq	c1(%rip), %rsi
call	fseek@PLT
movq	c2(%rip), %rax
movq	%rax, 16(%rbx)
movq	$0, (%rbx)
.Lprim277:
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_file_size, .-code_file_size
.globl header_include_file
.section .rodata
.str_include_file:
.string "INCLUDE-FILE"
.data
.align 32
.type header_include_file, @object
.size header_include_file, 32
header_include_file:
.quad header_file_size
.quad 12
.quad .str_include_file
.quad code_include_file
.globl key_include_file
.align 4
.type key_include_file, @object
.size key_include_file, 4
key_include_file:
.long 91
.text
.globl code_include_file
.type code_include_file, @function
code_include_file:
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
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_include_file, .-code_include_file
.globl header_read_file
.section .rodata
.str_read_file:
.string "READ-FILE"
.data
.align 32
.type header_read_file, @object
.size header_read_file, 32
header_read_file:
.quad header_include_file
.quad 9
.quad .str_read_file
.quad code_read_file
.globl key_read_file
.align 4
.type key_read_file, @object
.size key_read_file, 4
key_read_file:
.long 92
.text
.globl code_read_file
.type code_read_file, @function
code_read_file:
movq    (%rbx), %rcx
movq    8(%rbx), %rdx
movl	$1, %esi
movq	16(%rbx), %rdi
call	fread@PLT
movq	%rax, c1(%rip)
testq	%rax, %rax
jne	.Lprim282
movq	(%rbx), %rdi
call	feof@PLT
testl	%eax, %eax
je	.Lprim283
addq	$8, %rbx
movq	$0, (%rbx)
movq	$0, 8(%rbx)
jmp	.Lprim285
.Lprim283:
movq	(%rbx), %rdi
call	ferror@PLT
cltq
movq	%rax, 8(%rbx)
movq	$0, 16(%rbx)
jmp	.Lprim285
.Lprim282:
addq	$8, %rbx
movq	c1(%rip), %rax
movq	%rax, 8(%rbx)
movq	$0, (%rbx)
.Lprim285:
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_read_file, .-code_read_file
.globl header_read_line
.section .rodata
.str_read_line:
.string "READ-LINE"
.data
.align 32
.type header_read_line, @object
.size header_read_line, 32
header_read_line:
.quad header_read_file
.quad 9
.quad .str_read_line
.quad code_read_line
.globl key_read_line
.align 4
.type key_read_line, @object
.size key_read_line, 4
key_read_line:
.long 93
.text
.globl code_read_line
.type code_read_line, @function
code_read_line:
movq	$0, str1(%rip)
movq	$0, tempSize(%rip)
movq	(%rbx), %rdx
movl	$tempSize, %esi
movl	$str1, %edi
call	getline@PLT
movq	%rax, c1(%rip)
cmpq	$-1, %rax
jne	.Lprim288
call	__errno_location@PLT
movl	(%rax), %eax
cltq
movq	%rax, (%rbx)
movq	$0, 8(%rbx)
movq	$0, 16(%rbx)
jmp	.Lprim289
.Lprim288:
movq	c1(%rip), %rax
testq	%rax, %rax
jne	.Lprim290
movq	$0, (%rbx)
movq	$0, 8(%rbx)
movq	$0, 16(%rbx)
jmp	.Lprim289
.Lprim290:
movq	c1(%rip), %rax
leaq	-1(%rax), %rdx
movq	8(%rbx), %rax
cmpq	%rax, %rdx
jle	.Lprim291
movq	8(%rbx), %rdx
movq	(%rbx), %rax
movq	c1(%rip), %rcx
subq	%rdx, %rcx
movl	$1, %edx
movq	%rcx, %rsi
movq	%rax, %rdi
call	fseek@PLT
movq	8(%rbx), %rax
addq	$1, %rax
movq	%rax, c1(%rip)
jmp	.Lprim292
.Lprim291:
movq	str1(%rip), %rdx
movq	c1(%rip), %rax
addq	%rdx, %rax
subq	$1, %rax
movzbl	(%rax), %eax
cmpb	$10, %al
je	.Lprim292
addq	$1, c1(%rip)
.Lprim292:
movq	c1(%rip), %rax
leaq	-1(%rax), %rdx
movq	16(%rbx), %rax
movq	str1(%rip), %rsi
movq	%rax, %rdi
call	strncpy@PLT
movq	$0, (%rbx)
movq	$-1, 8(%rbx)
movq	c1(%rip), %rax
subq	$1, %rax
movq	%rax, 16(%rbx)
.Lprim289:
movq	str1(%rip), %rax
testq	%rax, %rax
je	.Lprim293
movq	str1(%rip), %rdi
call	free@PLT
.Lprim293:
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_read_line, .-code_read_line
.globl header_reposition_file
.section .rodata
.str_reposition_file:
.string "REPOSITION-FILE"
.data
.align 32
.type header_reposition_file, @object
.size header_reposition_file, 32
header_reposition_file:
.quad header_read_line
.quad 15
.quad .str_reposition_file
.quad code_reposition_file
.globl key_reposition_file
.align 4
.type key_reposition_file, @object
.size key_reposition_file, 4
key_reposition_file:
.long 94
.text
.globl code_reposition_file
.type code_reposition_file, @function
code_reposition_file:
movq	16(%rbx), %rsi
movq	(%rbx), %rdi
movl	$0, %edx
call	fseek@PLT
cltq
movq	%rax, 16(%rbx)
addq	$16, %rbx
movq	(%rbx), %rax
cmpq	$-1, %rax
jne	.Lprim296
call	__errno_location@PLT
movl	(%rax), %eax
cltq
movq	%rax, (%rbx)
.Lprim296:
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_reposition_file, .-code_reposition_file
.globl header_resize_file
.section .rodata
.str_resize_file:
.string "RESIZE-FILE"
.data
.align 32
.type header_resize_file, @object
.size header_resize_file, 32
header_resize_file:
.quad header_reposition_file
.quad 11
.quad .str_resize_file
.quad code_resize_file
.globl key_resize_file
.align 4
.type key_resize_file, @object
.size key_resize_file, 4
key_resize_file:
.long 95
.text
.globl code_resize_file
.type code_resize_file, @function
code_resize_file:
movq    (%rbx), %rdi
call    fileno@PLT
movl    %eax, %edi
movq    16(%rbx), %rsi
call	ftruncate@PLT
cltq
movq	%rax, 16(%rbx)
addq	$16, %rbx
movq	(%rbx), %rax
cmpq	$-1, %rax
jne	.Lprim299
call	__errno_location@PLT
movl	(%rax), %eax
cltq
jmp	.Lprim300
.Lprim299:
movl	$0, %eax
.Lprim300:
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_resize_file, .-code_resize_file
.globl header_write_file
.section .rodata
.str_write_file:
.string "WRITE-FILE"
.data
.align 32
.type header_write_file, @object
.size header_write_file, 32
header_write_file:
.quad header_resize_file
.quad 10
.quad .str_write_file
.quad code_write_file
.globl key_write_file
.align 4
.type key_write_file, @object
.size key_write_file, 4
key_write_file:
.long 96
.text
.globl code_write_file
.type code_write_file, @function
code_write_file:
movq	(%rbx), %rcx
movq	8(%rbx), %rdx
movl	$1, %esi
movq	16(%rbx), %rdi
call	fwrite@PLT
movq	%rax, c1(%rip)
addq	$16, %rbx
movq	$0, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_write_file, .-code_write_file
.globl header_write_line
.section .rodata
.str_write_line:
.string "WRITE-LINE"
.data
.align 32
.type header_write_line, @object
.size header_write_line, 32
header_write_line:
.quad header_write_file
.quad 10
.quad .str_write_line
.quad code_write_line
.globl key_write_line
.align 4
.type key_write_line, @object
.size key_write_line, 4
key_write_line:
.long 97
.text
.globl code_write_line
.type code_write_line, @function
code_write_line:
movq	8(%rbx), %rdx
movq	16(%rbx), %rsi
movl	$tempBuf, %edi
call	strncpy@PLT
movq	8(%rbx), %rax
movb	$10, tempBuf(%rax)
movq	(%rbx), %rcx
movq	8(%rbx), %rdx
addq    $1, %rdx
movl    $1, %esi
movl	$tempBuf, %edi
call	fwrite@PLT
addq	$16, %rbx
movq	$0, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_write_line, .-code_write_line
.globl header_flush_file
.section .rodata
.str_flush_file:
.string "FLUSH-FILE"
.data
.align 32
.type header_flush_file, @object
.size header_flush_file, 32
header_flush_file:
.quad header_write_line
.quad 10
.quad .str_flush_file
.quad code_flush_file
.globl key_flush_file
.align 4
.type key_flush_file, @object
.size key_flush_file, 4
key_flush_file:
.long 98
.text
.globl code_flush_file
.type code_flush_file, @function
code_flush_file:
movq	(%rbx), %rdi
call	fileno@PLT
movl	%eax, %edi
call	fsync@PLT
cltq
movq	%rax, (%rbx)
cmpq	$-1, %rax
jne	.Lprim307
call	__errno_location@PLT
movl	(%rax), %eax
cltq
movq	%rax, (%rbx)
.Lprim307:
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_flush_file, .-code_flush_file
.globl header_colon
.section .rodata
.str_colon:
.string ":"
.data
.align 32
.type header_colon, @object
.size header_colon, 32
header_colon:
.quad header_flush_file
.quad 1
.quad .str_colon
.quad code_colon
.globl key_colon
.align 4
.type key_colon, @object
.size key_colon, 4
key_colon:
.long 99
.text
.globl code_colon
.type code_colon, @function
code_colon:
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
call	parse_name_stacked@PLT
movq	(%rbx), %rax
testq	%rax, %rax
jne	.Lprim310
movq	stderr(%rip), %rcx
movl	$34, %edx
movl	$1, %esi
movl	$.LmdC117, %edi
call	fwrite@PLT
call	code_QUIT@PLT
.Lprim310:
movq	tempHeader(%rip), %r12
movq	(%rbx), %rdi
call	malloc@PLT
movq	%rax, 16(%r12)
movq	(%rbx), %rdx
movq	8(%rbx), %rsi
movq	%rax, %rdi
call	strncpy@PLT
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
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_colon, .-code_colon
.globl header_colon_no_name
.section .rodata
.str_colon_no_name:
.string ":NONAME"
.data
.align 32
.type header_colon_no_name, @object
.size header_colon_no_name, 32
header_colon_no_name:
.quad header_colon
.quad 7
.quad .str_colon_no_name
.quad code_colon_no_name
.globl key_colon_no_name
.align 4
.type key_colon_no_name, @object
.size key_colon_no_name, 4
key_colon_no_name:
.long 100
.text
.globl code_colon_no_name
.type code_colon_no_name, @function
code_colon_no_name:
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
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_colon_no_name, .-code_colon_no_name
.globl header_EXIT
.section .rodata
.str_EXIT:
.string "EXIT"
.data
.align 32
.type header_EXIT, @object
.size header_EXIT, 32
header_EXIT:
.quad header_colon_no_name
.quad 4
.quad .str_EXIT
.quad code_EXIT
.globl key_EXIT
.align 4
.type key_EXIT, @object
.size key_EXIT, 4
key_EXIT:
.long 101
.text
.globl code_EXIT
.type code_EXIT, @function
code_EXIT:
movq rsp(%rip), %rax
leaq 8(%rax), %rdx
movq %rdx, rsp(%rip)
movq (%rax), %rbp
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_EXIT, .-code_EXIT
.globl header_UTIME
.section .rodata
.str_UTIME:
.string "UTIME"
.data
.align 32
.type header_UTIME, @object
.size header_UTIME, 32
header_UTIME:
.quad header_EXIT
.quad 5
.quad .str_UTIME
.quad code_UTIME
.globl key_UTIME
.align 4
.type key_UTIME, @object
.size key_UTIME, 4
key_UTIME:
.long 102
.text
.globl code_UTIME
.type code_UTIME, @function
code_UTIME:
movl	$0, %esi
movl	$timeVal, %edi
call	gettimeofday@PLT
subq	$16, %rbx
movq	timeVal(%rip), %rdx
imulq	$1000000, %rdx, %rdx
movq	timeVal+8(%rip), %rcx
addq	%rcx, %rdx
movq	%rdx, 8(%rbx)
movq	$0, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_UTIME, .-code_UTIME
.globl header_semicolon
.section .rodata
.str_semicolon:
.string ";"
.data
.align 32
.type header_semicolon, @object
.size header_semicolon, 32
header_semicolon:
.quad header_UTIME
.quad 513
.quad .str_semicolon
.quad code_semicolon
.globl key_semicolon
.align 4
.type key_semicolon, @object
.size key_semicolon, 4
key_semicolon:
.long 103
.text
.globl code_semicolon
.type code_semicolon, @function
code_semicolon:
movq	compilationWordlist(%rip), %rax  # Pointer to the header
movq    (%rax), %rax  # The header itself.
movq	8(%rax), %rdx # The length word.
andb	$254, %dh
movq	%rdx, 8(%rax)
subq    $8, %rbx
movq	$header_EXIT+24, %rdx
movq	%rdx, (%rbx)
movl	$0, %eax
call	compile_@PLT
jmp	.Lprim330
.Lprim331:
call	drain_queue_@PLT
.Lprim330:
movl	queue_length(%rip), %eax
testl	%eax, %eax
jne	.Lprim331
movq	$0, state(%rip)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_semicolon, .-code_semicolon
.globl header_loop_end
.section .rodata
.str_loop_end:
.string "(LOOP-END)"
.data
.align 32
.type header_loop_end, @object
.size header_loop_end, 32
header_loop_end:
.quad header_semicolon
.quad 10
.quad .str_loop_end
.quad code_loop_end
.globl key_loop_end
.align 4
.type key_loop_end, @object
.size key_loop_end, 4
key_loop_end:
.long 104
.text
.globl code_loop_end
.type code_loop_end, @function
code_loop_end:
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
js      .Lprim9901         # Jumps when the top bit is 1.
movq    $-1, %r11      # Sets flag true when top bit is 0.
jmp     .Lprim9902
.Lprim9901:
movq    $0, %r11       # Or false when top bit is 1.
.Lprim9902:
movq    %rdx, %rax     # rdx is the index-limit, remember.
xorq    %r10, %rax     # now rax is delta XOR index-limit
# Same flow as above: true flag when top bit is 0.
# We OR the new result with the old one, in r11.
testq   %rax, %rax
js      .Lprim9903         # Jumps when the top bit is 1.
orq     $-1, %r11      # Sets flag true when top bit is 0.
jmp     .Lprim9904
.Lprim9903:
orq     $0, %r11       # Or false when top bit is 1.
.Lprim9904:
# Finally, negate the returned flag.
xorq    $-1, %r11
# Now r11 holds the flag we want to return, write it onto the stack.
movq    %r11, (%rbx)
# And write the delta + index onto the return stack.
addq    %r10, %rcx
movq    %rcx, (%r9)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_loop_end, .-code_loop_end
.globl header_CCALL0
.section .rodata
.str_CCALL0:
.string "CCALL0"
.data
.align 32
.type header_CCALL0, @object
.size header_CCALL0, 32
header_CCALL0:
.quad header_loop_end
.quad 6
.quad .str_CCALL0
.quad code_CCALL0
.globl key_CCALL0
.align 4
.type key_CCALL0, @object
.size key_CCALL0, 4
key_CCALL0:
.long 105
.text
.globl code_CCALL0
.type code_CCALL0, @function
code_CCALL0:
movq    (%rbx), %rax  # Only argument is the C function address.
call    *%rax
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_CCALL0, .-code_CCALL0
.globl header_CCALL1
.section .rodata
.str_CCALL1:
.string "CCALL1"
.data
.align 32
.type header_CCALL1, @object
.size header_CCALL1, 32
header_CCALL1:
.quad header_CCALL0
.quad 6
.quad .str_CCALL1
.quad code_CCALL1
.globl key_CCALL1
.align 4
.type key_CCALL1, @object
.size key_CCALL1, 4
key_CCALL1:
.long 106
.text
.globl code_CCALL1
.type code_CCALL1, @function
code_CCALL1:
movq    8(%rbx), %rdi # TOS = first argument
movq    (%rbx), %rax
subq    $8, %rsp
call    *%rax
addq    $8, %rsp
addq    $8, %rbx
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_CCALL1, .-code_CCALL1
.globl header_CCALL2
.section .rodata
.str_CCALL2:
.string "CCALL2"
.data
.align 32
.type header_CCALL2, @object
.size header_CCALL2, 32
header_CCALL2:
.quad header_CCALL1
.quad 6
.quad .str_CCALL2
.quad code_CCALL2
.globl key_CCALL2
.align 4
.type key_CCALL2, @object
.size key_CCALL2, 4
key_CCALL2:
.long 107
.text
.globl code_CCALL2
.type code_CCALL2, @function
code_CCALL2:
movq    16(%rbx), %rdi # sp[2] = first argument
movq    8(%rbx), %rsi # TOS = second argument
movq    (%rbx), %rax
subq    $8, %rsp # Align rsp to 16 bytes
call    *%rax
addq    $8, %rsp
addq    $16, %rbx
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_CCALL2, .-code_CCALL2
.globl header_CCALL3
.section .rodata
.str_CCALL3:
.string "CCALL3"
.data
.align 32
.type header_CCALL3, @object
.size header_CCALL3, 32
header_CCALL3:
.quad header_CCALL2
.quad 6
.quad .str_CCALL3
.quad code_CCALL3
.globl key_CCALL3
.align 4
.type key_CCALL3, @object
.size key_CCALL3, 4
key_CCALL3:
.long 108
.text
.globl code_CCALL3
.type code_CCALL3, @function
code_CCALL3:
movq    24(%rbx), %rdi # sp[3] = first argument
movq    16(%rbx), %rsi # sp[2] = second argument
movq    8(%rbx), %rdx # TOS = third argument
movq    (%rbx), %rax
subq    $8, %rsp # Align rsp to 16 bytes
call    *%rax
addq    $8, %rsp
addq    $24, %rbx
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_CCALL3, .-code_CCALL3
.globl header_CCALL4
.section .rodata
.str_CCALL4:
.string "CCALL4"
.data
.align 32
.type header_CCALL4, @object
.size header_CCALL4, 32
header_CCALL4:
.quad header_CCALL3
.quad 6
.quad .str_CCALL4
.quad code_CCALL4
.globl key_CCALL4
.align 4
.type key_CCALL4, @object
.size key_CCALL4, 4
key_CCALL4:
.long 109
.text
.globl code_CCALL4
.type code_CCALL4, @function
code_CCALL4:
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
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_CCALL4, .-code_CCALL4
.globl header_CCALL5
.section .rodata
.str_CCALL5:
.string "CCALL5"
.data
.align 32
.type header_CCALL5, @object
.size header_CCALL5, 32
header_CCALL5:
.quad header_CCALL4
.quad 6
.quad .str_CCALL5
.quad code_CCALL5
.globl key_CCALL5
.align 4
.type key_CCALL5, @object
.size key_CCALL5, 4
key_CCALL5:
.long 110
.text
.globl code_CCALL5
.type code_CCALL5, @function
code_CCALL5:
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
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_CCALL5, .-code_CCALL5
.globl header_CCALL6
.section .rodata
.str_CCALL6:
.string "CCALL6"
.data
.align 32
.type header_CCALL6, @object
.size header_CCALL6, 32
header_CCALL6:
.quad header_CCALL5
.quad 6
.quad .str_CCALL6
.quad code_CCALL6
.globl key_CCALL6
.align 4
.type key_CCALL6, @object
.size key_CCALL6, 4
key_CCALL6:
.long 111
.text
.globl code_CCALL6
.type code_CCALL6, @function
code_CCALL6:
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
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_CCALL6, .-code_CCALL6
.globl header_c_lib_loader
.section .rodata
.str_c_lib_loader:
.string "(C-LIBRARY)"
.data
.align 32
.type header_c_lib_loader, @object
.size header_c_lib_loader, 32
header_c_lib_loader:
.quad header_CCALL6
.quad 11
.quad .str_c_lib_loader
.quad code_c_lib_loader
.globl key_c_lib_loader
.align 4
.type key_c_lib_loader, @object
.size key_c_lib_loader, 4
key_c_lib_loader:
.long 112
.text
.globl code_c_lib_loader
.type code_c_lib_loader, @function
code_c_lib_loader:
movq    (%rbx), %rdi
movq    $258, %rsi
subq    $8, %rsp
call    dlopen@PLT
addq    $8, %rsp
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_c_lib_loader, .-code_c_lib_loader
.globl header_c_symbol
.section .rodata
.str_c_symbol:
.string "(C-SYMBOL)"
.data
.align 32
.type header_c_symbol, @object
.size header_c_symbol, 32
header_c_symbol:
.quad header_c_lib_loader
.quad 10
.quad .str_c_symbol
.quad code_c_symbol
.globl key_c_symbol
.align 4
.type key_c_symbol, @object
.size key_c_symbol, 4
key_c_symbol:
.long 113
.text
.globl code_c_symbol
.type code_c_symbol, @function
code_c_symbol:
movq   (%rbx), %rsi
movq   $0, %rdi      # 0 = RTLD_DEFAULT, searching everywhere.
subq   $8, %rsp # Align rsp to 16 bytes
call   dlsym@PLT
addq   $8, %rsp
movq   %rax, (%rbx)  # Put the void* result onto the stack.
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.size code_c_symbol, .-code_c_symbol
.globl	code_superinstruction_from_r_from_r
.type	code_superinstruction_from_r_from_r, @function
code_superinstruction_from_r_from_r:
.cfi_startproc
subq	$16, %rbx
movq	rsp(%rip), %rcx
movq	(%rcx), %rax
movq	%rax, 8(%rbx)
movq	8(%rcx), %rax
movq	%rax, (%rbx)
addq	$16, rsp(%rip)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_from_r_from_r, .-code_superinstruction_from_r_from_r
.globl	code_superinstruction_fetch_EXIT
.type	code_superinstruction_fetch_EXIT, @function
code_superinstruction_fetch_EXIT:
.cfi_startproc
movq	(%rbx), %rax
movq	(%rax), %rax
movq	%rax, (%rbx)
movq rsp(%rip), %rax
leaq 8(%rax), %rdx
movq %rdx, rsp(%rip)
movq (%rax), %rbp
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_fetch_EXIT, .-code_superinstruction_fetch_EXIT
.globl	code_superinstruction_SWAP_to_r
.type	code_superinstruction_SWAP_to_r, @function
code_superinstruction_SWAP_to_r:
.cfi_startproc
movq    8(%rbx), %rax
movq   rsp(%rip), %rcx
subq   $8, %rcx
movq   %rcx, rsp(%rip)
movq   %rax, (%rcx)
movq    (%rbx), %rax
movq    %rax, 8(%rbx)
addq    $8, %rbx
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_SWAP_to_r, .-code_superinstruction_SWAP_to_r
.globl	code_superinstruction_to_r_SWAP
.type	code_superinstruction_to_r_SWAP, @function
code_superinstruction_to_r_SWAP:
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
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_to_r_SWAP, .-code_superinstruction_to_r_SWAP
.globl	code_superinstruction_to_r_EXIT
.type	code_superinstruction_to_r_EXIT, @function
code_superinstruction_to_r_EXIT:
.cfi_startproc
movq	(%rbx), %rax
addq    $8, %rbx
movq	%rax, %rbp
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_to_r_EXIT, .-code_superinstruction_to_r_EXIT
.globl	code_superinstruction_from_r_DUP
.type	code_superinstruction_from_r_DUP, @function
code_superinstruction_from_r_DUP:
.cfi_startproc
movq   rsp(%rip), %rax
movq   (%rax), %rax
addq   $8, rsp(%rip)
subq	$16, %rbx
movq    %rax, (%rbx)
movq    %rax, 8(%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_from_r_DUP, .-code_superinstruction_from_r_DUP
.globl	code_superinstruction_dolit_equal
.type	code_superinstruction_dolit_equal, @function
code_superinstruction_dolit_equal:
.cfi_startproc
movq    (%rbp), %rax
addq    $8, %rbp
movq    (%rbx), %rcx
cmpq	%rcx, %rax
jne	.Lsup347
movq	$-1, %rdx
jmp	.Lsup348
.Lsup347:
movl	$0, %edx
.Lsup348:
movq	%rdx, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_dolit_equal, .-code_superinstruction_dolit_equal
.globl	code_superinstruction_dolit_fetch
.type	code_superinstruction_dolit_fetch, @function
code_superinstruction_dolit_fetch:
.cfi_startproc
movq    (%rbp), %rax
addq    $8, %rbp
movq	(%rax), %rax
subq    $8, %rbx
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_dolit_fetch, .-code_superinstruction_dolit_fetch
.globl	code_superinstruction_DUP_to_r
.type	code_superinstruction_DUP_to_r, @function
code_superinstruction_DUP_to_r:
.cfi_startproc
movq    (%rbx), %rax
movq   rsp(%rip), %rcx
subq   $8, %rcx
movq   %rcx, rsp(%rip)
movq   %rax, (%rcx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_DUP_to_r, .-code_superinstruction_DUP_to_r
.globl	code_superinstruction_dolit_dolit
.type	code_superinstruction_dolit_dolit, @function
code_superinstruction_dolit_dolit:
.cfi_startproc
subq	$16, %rbx
movq    (%rbp), %rax
movq    %rax, 8(%rbx)
movq    8(%rbp), %rax
movq    %rax, (%rbx)
addq    $16, %rbp
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_dolit_dolit, .-code_superinstruction_dolit_dolit
.globl	code_superinstruction_plus_EXIT
.type	code_superinstruction_plus_EXIT, @function
code_superinstruction_plus_EXIT:
.cfi_startproc
movq    (%rbx), %rax
addq    $8, %rbx
addq    %rax, (%rbx)
movq rsp(%rip), %rax
leaq 8(%rax), %rdx
movq %rdx, rsp(%rip)
movq (%rax), %rbp
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_plus_EXIT, .-code_superinstruction_plus_EXIT
.globl	code_superinstruction_dolit_plus
.type	code_superinstruction_dolit_plus, @function
code_superinstruction_dolit_plus:
.cfi_startproc
movq    (%rbp), %rax
addq    $8, %rbp
addq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_dolit_plus, .-code_superinstruction_dolit_plus
.globl	code_superinstruction_dolit_less_than
.type	code_superinstruction_dolit_less_than, @function
code_superinstruction_dolit_less_than:
.cfi_startproc
movq    (%rbx), %rsi
movq    (%rbp), %rax
addq    $8, %rbp
cmpq	%rax, %rsi  # TOS -> %rsi, lit -> %rax
jge	.Lsup355
movq	$-1, %rax
jmp	.Lsup356
.Lsup355:
movl	$0, %eax
.Lsup356:
movq	%rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_dolit_less_than, .-code_superinstruction_dolit_less_than
.globl	code_superinstruction_plus_fetch
.type	code_superinstruction_plus_fetch, @function
code_superinstruction_plus_fetch:
.cfi_startproc
movq    (%rbx), %rax
addq    $8, %rbx
addq    (%rbx), %rax
movq    (%rax), %rax
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_plus_fetch, .-code_superinstruction_plus_fetch
.globl	code_superinstruction_to_r_to_r
.type	code_superinstruction_to_r_to_r, @function
code_superinstruction_to_r_to_r:
.cfi_startproc
movq    (%rbx), %rax
movq   rsp(%rip), %rcx
subq   $8, %rcx
movq   %rcx, rsp(%rip)
movq   %rax, (%rcx)
movq    8(%rbx), %rax
movq   rsp(%rip), %rcx
subq   $8, %rcx
movq   %rcx, rsp(%rip)
movq   %rax, (%rcx)
addq    $16, %rbx
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_to_r_to_r, .-code_superinstruction_to_r_to_r
.globl	code_superinstruction_dolit_call_
.type	code_superinstruction_dolit_call_, @function
code_superinstruction_dolit_call_:
.cfi_startproc
subq	$8, %rbx
movq    (%rbp), %rax
movq    %rax, (%rbx)
movq    8(%rbp), %rax
movq    %rax, ca(%rip)
addq    $16, %rbp
movq   rsp(%rip), %rcx
subq   $8, %rcx
movq   %rcx, rsp(%rip)
movq   %rbp, (%rcx)
movq    %rax, %rbp
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_dolit_call_, .-code_superinstruction_dolit_call_
.globl	code_superinstruction_equal_EXIT
.type	code_superinstruction_equal_EXIT, @function
code_superinstruction_equal_EXIT:
.cfi_startproc
movq    (%rbx), %rax
addq    $8, %rbx
movq    (%rbx), %rcx
cmpq	%rax, %rcx
jne	.Lsup361
movq	$-1, %rax
jmp	.Lsup362
.Lsup361:
movl	$0, %eax
.Lsup362:
movq	%rax, (%rbx)
movq rsp(%rip), %rax
leaq 8(%rax), %rdx
movq %rdx, rsp(%rip)
movq (%rax), %rbp
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_equal_EXIT, .-code_superinstruction_equal_EXIT
.globl	code_superinstruction_to_r_SWAP_from_r
.type	code_superinstruction_to_r_SWAP_from_r, @function
code_superinstruction_to_r_SWAP_from_r:
.cfi_startproc
movq    8(%rbx), %rax
movq    16(%rbx), %rcx
movq    %rcx, 8(%rbx)
movq    %rax, 16(%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_to_r_SWAP_from_r, .-code_superinstruction_to_r_SWAP_from_r
.globl	code_superinstruction_SWAP_to_r_EXIT
.type	code_superinstruction_SWAP_to_r_EXIT, @function
code_superinstruction_SWAP_to_r_EXIT:
.cfi_startproc
movq    (%rbx), %rax
movq    8(%rbx), %rcx
movq    %rax, 8(%rbx)
movq   rsp(%rip), %rax
subq   $8, %rax
movq   %rax, rsp(%rip)
movq   %rcx, (%rax)
addq    $8, %rbx
movq rsp(%rip), %rax
leaq 8(%rax), %rdx
movq %rdx, rsp(%rip)
movq (%rax), %rbp
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_SWAP_to_r_EXIT, .-code_superinstruction_SWAP_to_r_EXIT
.globl	code_superinstruction_from_r_from_r_DUP
.type	code_superinstruction_from_r_from_r_DUP, @function
code_superinstruction_from_r_from_r_DUP:
.cfi_startproc
subq    $24, %rbx
movq   rsp(%rip), %rax
movq   (%rax), %rax
addq   $8, rsp(%rip)
movq    %rax, 16(%rbx)
movq   rsp(%rip), %rax
movq   (%rax), %rax
addq   $8, rsp(%rip)
movq    %rax, 8(%rbx)
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_from_r_from_r_DUP, .-code_superinstruction_from_r_from_r_DUP
.globl	code_superinstruction_DUP_to_r_SWAP
.type	code_superinstruction_DUP_to_r_SWAP, @function
code_superinstruction_DUP_to_r_SWAP:
.cfi_startproc
movq    (%rbx), %rax
movq   rsp(%rip), %rcx
subq   $8, %rcx
movq   %rcx, rsp(%rip)
movq   %rax, (%rcx)
movq    (%rbx), %rax
movq    8(%rbx), %rcx
movq    %rax, 8(%rbx)
movq    %rcx, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_DUP_to_r_SWAP, .-code_superinstruction_DUP_to_r_SWAP
.globl	code_superinstruction_from_r_DUP_to_r
.type	code_superinstruction_from_r_DUP_to_r, @function
code_superinstruction_from_r_DUP_to_r:
.cfi_startproc
movq	rsp(%rip), %rax
movq	(%rax), %rax
subq    $8, %rbx
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_from_r_DUP_to_r, .-code_superinstruction_from_r_DUP_to_r
.globl	code_superinstruction_dolit_fetch_EXIT
.type	code_superinstruction_dolit_fetch_EXIT, @function
code_superinstruction_dolit_fetch_EXIT:
.cfi_startproc
movq    (%rbp), %rax
movq    (%rax), %rax
subq    $8, %rbx
movq    %rax, (%rbx)
addq    $8, %rbp
movq rsp(%rip), %rax
leaq 8(%rax), %rdx
movq %rdx, rsp(%rip)
movq (%rax), %rbp
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_dolit_fetch_EXIT, .-code_superinstruction_dolit_fetch_EXIT
.globl	code_superinstruction_dolit_plus_EXIT
.type	code_superinstruction_dolit_plus_EXIT, @function
code_superinstruction_dolit_plus_EXIT:
.cfi_startproc
movq    (%rbp), %rax
addq    $8, %rbp
addq	%rax, (%rbx)
movq rsp(%rip), %rax
leaq 8(%rax), %rdx
movq %rdx, rsp(%rip)
movq (%rax), %rbp
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_dolit_plus_EXIT, .-code_superinstruction_dolit_plus_EXIT
.globl	code_superinstruction_dolit_less_than_EXIT
.type	code_superinstruction_dolit_less_than_EXIT, @function
code_superinstruction_dolit_less_than_EXIT:
.cfi_startproc
movq    (%rbp), %rax
movq	(%rbx), %rdx
cmpq	%rax, %rdx
jge	.Lsup371
movq	$-1, %rax
jmp	.Lsup372
.Lsup371:
movl	$0, %eax
.Lsup372:
movq	%rax, (%rbx)
addq    $8, %rbp
movq rsp(%rip), %rax
leaq 8(%rax), %rdx
movq %rdx, rsp(%rip)
movq (%rax), %rbp
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_dolit_less_than_EXIT, .-code_superinstruction_dolit_less_than_EXIT
.globl	code_superinstruction_dolit_dolit_plus
.type	code_superinstruction_dolit_dolit_plus, @function
code_superinstruction_dolit_dolit_plus:
.cfi_startproc
movq    (%rbp), %rax
addq    8(%rbp), %rax
subq    $8, %rbx
movq    %rax, (%rbx)
addq    $16, %rbp
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_dolit_dolit_plus, .-code_superinstruction_dolit_dolit_plus
.globl	code_superinstruction_CELLS_sp_fetch_plus
.type	code_superinstruction_CELLS_sp_fetch_plus, @function
code_superinstruction_CELLS_sp_fetch_plus:
.cfi_startproc
movq    (%rbx), %rax
leaq    0(,%rax,8), %rax
addq    %rbx, %rax
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_CELLS_sp_fetch_plus, .-code_superinstruction_CELLS_sp_fetch_plus
.globl	code_superinstruction_to_r_SWAP_to_r
.type	code_superinstruction_to_r_SWAP_to_r, @function
code_superinstruction_to_r_SWAP_to_r:
.cfi_startproc
movq    (%rbx), %rax
movq   rsp(%rip), %rcx
subq   $8, %rcx
movq   %rcx, rsp(%rip)
movq   %rax, (%rcx)
movq    16(%rbx), %rax
movq   rsp(%rip), %rcx
subq   $8, %rcx
movq   %rcx, rsp(%rip)
movq   %rax, (%rcx)
movq    8(%rbx), %rax
movq    %rax, 16(%rbx)
addq    $16, %rbx
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_to_r_SWAP_to_r, .-code_superinstruction_to_r_SWAP_to_r
.globl	code_superinstruction_dolit_equal_EXIT
.type	code_superinstruction_dolit_equal_EXIT, @function
code_superinstruction_dolit_equal_EXIT:
.cfi_startproc
movq    (%rbx), %rax
movq    (%rbp), %rcx
addq    $8, %rbp
cmpq	%rax, %rcx
jne	.Lsup377
movq	$-1, %rax
jmp	.Lsup378
.Lsup377:
movl	$0, %eax
.Lsup378:
movq	%rax, (%rbx)
movq rsp(%rip), %rax
leaq 8(%rax), %rdx
movq %rdx, rsp(%rip)
movq (%rax), %rbp
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_dolit_equal_EXIT, .-code_superinstruction_dolit_equal_EXIT
.globl	code_superinstruction_sp_fetch_plus_fetch
.type	code_superinstruction_sp_fetch_plus_fetch, @function
code_superinstruction_sp_fetch_plus_fetch:
.cfi_startproc
movq    (%rbx), %rax
addq    %rbx, %rax
movq    (%rax), %rax
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_sp_fetch_plus_fetch, .-code_superinstruction_sp_fetch_plus_fetch
.globl	code_superinstruction_plus_fetch_EXIT
.type	code_superinstruction_plus_fetch_EXIT, @function
code_superinstruction_plus_fetch_EXIT:
.cfi_startproc
movq    (%rbx), %rax
addq    8(%rbx), %rax
movq    (%rax), %rax
addq    $8, %rbx
movq    %rax, (%rbx)
movq rsp(%rip), %rax
leaq 8(%rax), %rdx
movq %rdx, rsp(%rip)
movq (%rax), %rbp
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_plus_fetch_EXIT, .-code_superinstruction_plus_fetch_EXIT
.globl	code_superinstruction_from_r_from_r_two_dup
.type	code_superinstruction_from_r_from_r_two_dup, @function
code_superinstruction_from_r_from_r_two_dup:
.cfi_startproc
subq	$32, %rbx
movq   rsp(%rip), %rax
movq   (%rax), %rax
addq   $8, rsp(%rip)
movq    %rax, 24(%rbx)
movq    %rax, 8(%rbx)
movq   rsp(%rip), %rax
movq   (%rax), %rax
addq   $8, rsp(%rip)
movq    %rax, 16(%rbx)
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_from_r_from_r_two_dup, .-code_superinstruction_from_r_from_r_two_dup
.globl	code_superinstruction_neg_rot_plus_to_r
.type	code_superinstruction_neg_rot_plus_to_r, @function
code_superinstruction_neg_rot_plus_to_r:
.cfi_startproc
movq    8(%rbx), %rax
addq    16(%rbx), %rax
movq   rsp(%rip), %rcx
subq   $8, %rcx
movq   %rcx, rsp(%rip)
movq   %rax, (%rcx)
movq    (%rbx), %rax
addq    $16, %rbx
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_neg_rot_plus_to_r, .-code_superinstruction_neg_rot_plus_to_r
.globl	code_superinstruction_two_dup_minus_to_r
.type	code_superinstruction_two_dup_minus_to_r, @function
code_superinstruction_two_dup_minus_to_r:
.cfi_startproc
movq    (%rbx), %rax
movq    8(%rbx), %rcx
subq    %rax, %rcx    # Subtracting TOS from second
movq   rsp(%rip), %rax
subq   $8, %rax
movq   %rax, rsp(%rip)
movq   %rcx, (%rax)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_two_dup_minus_to_r, .-code_superinstruction_two_dup_minus_to_r
.globl	code_superinstruction_to_r_SWAP_to_r_EXIT
.type	code_superinstruction_to_r_SWAP_to_r_EXIT, @function
code_superinstruction_to_r_SWAP_to_r_EXIT:
.cfi_startproc
movq    (%rbx), %rax
movq   rsp(%rip), %rcx
subq   $8, %rcx
movq   %rcx, rsp(%rip)
movq   %rax, (%rcx)
movq    16(%rbx), %rax
movq   rsp(%rip), %rcx
subq   $8, %rcx
movq   %rcx, rsp(%rip)
movq   %rax, (%rcx)
movq    8(%rbx), %rax
addq    $16, %rbx
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_to_r_SWAP_to_r_EXIT, .-code_superinstruction_to_r_SWAP_to_r_EXIT
.globl	code_superinstruction_DUP_to_r_SWAP_to_r
.type	code_superinstruction_DUP_to_r_SWAP_to_r, @function
code_superinstruction_DUP_to_r_SWAP_to_r:
.cfi_startproc
movq    (%rbx), %rax
movq   rsp(%rip), %rcx
subq   $8, %rcx
movq   %rcx, rsp(%rip)
movq   %rax, (%rcx)
movq    8(%rbx), %rdx
movq   rsp(%rip), %rcx
subq   $8, %rcx
movq   %rcx, rsp(%rip)
movq   %rdx, (%rcx)
addq    $8, %rbx
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_DUP_to_r_SWAP_to_r, .-code_superinstruction_DUP_to_r_SWAP_to_r
.globl	code_superinstruction_from_r_DUP_to_r_SWAP
.type	code_superinstruction_from_r_DUP_to_r_SWAP, @function
code_superinstruction_from_r_DUP_to_r_SWAP:
.cfi_startproc
movq    (%rbx), %rax
subq    $8, %rbx
movq    %rax, (%rbx)
movq    rsp(%rip), %rax
movq    (%rax), %rax
movq    %rax, 8(%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_from_r_DUP_to_r_SWAP, .-code_superinstruction_from_r_DUP_to_r_SWAP
.globl	code_superinstruction_from_r_from_r_DUP_to_r
.type	code_superinstruction_from_r_from_r_DUP_to_r, @function
code_superinstruction_from_r_from_r_DUP_to_r:
.cfi_startproc
subq    $16, %rbx
movq   rsp(%rip), %rax
movq   (%rax), %rax
addq   $8, rsp(%rip)
movq    %rax, 8(%rbx)
movq    rsp(%rip), %rax
movq    (%rax), %rax
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_from_r_from_r_DUP_to_r, .-code_superinstruction_from_r_from_r_DUP_to_r
.globl	code_superinstruction_CELLS_sp_fetch_plus_fetch
.type	code_superinstruction_CELLS_sp_fetch_plus_fetch, @function
code_superinstruction_CELLS_sp_fetch_plus_fetch:
.cfi_startproc
movq    (%rbx), %rax
leaq    (,%rax,8), %rax
addq    %rbx, %rax
movq    (%rax), %rax
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_CELLS_sp_fetch_plus_fetch, .-code_superinstruction_CELLS_sp_fetch_plus_fetch
.globl	code_superinstruction_two_dup_minus_to_r_dolit
.type	code_superinstruction_two_dup_minus_to_r_dolit, @function
code_superinstruction_two_dup_minus_to_r_dolit:
.cfi_startproc
movq    (%rbx), %rax
movq    8(%rbx), %rcx
subq    %rax, %rcx
movq   rsp(%rip), %rax
subq   $8, %rax
movq   %rax, rsp(%rip)
movq   %rcx, (%rax)
subq    $8, %rbx
movq    (%rbp), %rax
movq    %rax, (%rbx)
addq    $8, %rbp
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_two_dup_minus_to_r_dolit, .-code_superinstruction_two_dup_minus_to_r_dolit
.globl	code_superinstruction_from_r_two_dup_minus_to_r
.type	code_superinstruction_from_r_two_dup_minus_to_r, @function
code_superinstruction_from_r_two_dup_minus_to_r:
.cfi_startproc
movq    (%rbx), %rax
movq    rsp(%rip), %rcx
subq    (%rcx), %rax
movq    %rax, (%rcx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_from_r_two_dup_minus_to_r, .-code_superinstruction_from_r_two_dup_minus_to_r
.globl	code_superinstruction_from_r_from_r_two_dup_minus
.type	code_superinstruction_from_r_from_r_two_dup_minus, @function
code_superinstruction_from_r_from_r_two_dup_minus:
.cfi_startproc
subq    $24, %rbx
movq   rsp(%rip), %rax
movq   (%rax), %rax
addq   $8, rsp(%rip)
movq   rsp(%rip), %rcx
movq   (%rcx), %rcx
addq   $8, rsp(%rip)
movq    %rax, 16(%rbx)
movq    %rcx, 8(%rbx)
subq    %rcx, %rax
movq    %rax, (%rbx)
movq (%rbp), %rax
addq $8, %rbp
jmp *%rax
.cfi_endproc
.size	code_superinstruction_from_r_from_r_two_dup_minus, .-code_superinstruction_from_r_from_r_two_dup_minus
.globl	init_superinstructions
.type	init_superinstructions, @function
init_superinstructions:
.LmdFB168:
.cfi_startproc
movl	$0, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_from_r(%rip), %eax
orl	%eax, %edx
movl	key_from_r(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_from_r_from_r, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_fetch(%rip), %eax
orl	%eax, %edx
movl	key_EXIT(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_fetch_EXIT, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_SWAP(%rip), %eax
orl	%eax, %edx
movl	key_to_r(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_SWAP_to_r, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_to_r(%rip), %eax
orl	%eax, %edx
movl	key_SWAP(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_to_r_SWAP, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_to_r(%rip), %eax
orl	%eax, %edx
movl	key_EXIT(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_to_r_EXIT, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_from_r(%rip), %eax
orl	%eax, %edx
movl	key_DUP(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_from_r_DUP, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_dolit(%rip), %eax
orl	%eax, %edx
movl	key_equal(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_dolit_equal, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_dolit(%rip), %eax
orl	%eax, %edx
movl	key_fetch(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_dolit_fetch, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_DUP(%rip), %eax
orl	%eax, %edx
movl	key_to_r(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_DUP_to_r, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_dolit(%rip), %eax
orl	%eax, %edx
movl	key_dolit(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_dolit_dolit, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_plus(%rip), %eax
orl	%eax, %edx
movl	key_EXIT(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_plus_EXIT, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_dolit(%rip), %eax
orl	%eax, %edx
movl	key_plus(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_dolit_plus, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_dolit(%rip), %eax
orl	%eax, %edx
movl	key_less_than(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_dolit_less_than, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_plus(%rip), %eax
orl	%eax, %edx
movl	key_fetch(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_plus_fetch, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_to_r(%rip), %eax
orl	%eax, %edx
movl	key_to_r(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_to_r_to_r, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_dolit(%rip), %eax
orl	%eax, %edx
movl	key_call_(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_dolit_call_, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_equal(%rip), %eax
orl	%eax, %edx
movl	key_EXIT(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_equal_EXIT, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_to_r(%rip), %eax
orl	%eax, %edx
movl	key_SWAP(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_from_r(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_to_r_SWAP_from_r, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_SWAP(%rip), %eax
orl	%eax, %edx
movl	key_to_r(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_EXIT(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_SWAP_to_r_EXIT, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_from_r(%rip), %eax
orl	%eax, %edx
movl	key_from_r(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_DUP(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_from_r_from_r_DUP, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_DUP(%rip), %eax
orl	%eax, %edx
movl	key_to_r(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_SWAP(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_DUP_to_r_SWAP, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_from_r(%rip), %eax
orl	%eax, %edx
movl	key_DUP(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_to_r(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_from_r_DUP_to_r, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_dolit(%rip), %eax
orl	%eax, %edx
movl	key_fetch(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_EXIT(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_dolit_fetch_EXIT, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_dolit(%rip), %eax
orl	%eax, %edx
movl	key_plus(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_EXIT(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_dolit_plus_EXIT, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_dolit(%rip), %eax
orl	%eax, %edx
movl	key_less_than(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_EXIT(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_dolit_less_than_EXIT, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_dolit(%rip), %eax
orl	%eax, %edx
movl	key_dolit(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_plus(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_dolit_dolit_plus, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_CELLS(%rip), %eax
orl	%eax, %edx
movl	key_sp_fetch(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_plus(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_CELLS_sp_fetch_plus, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_to_r(%rip), %eax
orl	%eax, %edx
movl	key_SWAP(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_to_r(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_to_r_SWAP_to_r, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_dolit(%rip), %eax
orl	%eax, %edx
movl	key_equal(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_EXIT(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_dolit_equal_EXIT, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_sp_fetch(%rip), %eax
orl	%eax, %edx
movl	key_plus(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_fetch(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_sp_fetch_plus_fetch, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_plus(%rip), %eax
orl	%eax, %edx
movl	key_fetch(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_EXIT(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_plus_fetch_EXIT, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_from_r(%rip), %eax
orl	%eax, %edx
movl	key_from_r(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_two_dup(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_from_r_from_r_two_dup, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_neg_rot(%rip), %eax
orl	%eax, %edx
movl	key_plus(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_to_r(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_neg_rot_plus_to_r, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_two_dup(%rip), %eax
orl	%eax, %edx
movl	key_minus(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_to_r(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_two_dup_minus_to_r, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_to_r(%rip), %eax
orl	%eax, %edx
movl	key_SWAP(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_to_r(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	key_EXIT(%rip), %eax
sall	$24, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_to_r_SWAP_to_r_EXIT, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_DUP(%rip), %eax
orl	%eax, %edx
movl	key_to_r(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_SWAP(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	key_to_r(%rip), %eax
sall	$24, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_DUP_to_r_SWAP_to_r, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_from_r(%rip), %eax
orl	%eax, %edx
movl	key_DUP(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_to_r(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	key_SWAP(%rip), %eax
sall	$24, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_from_r_DUP_to_r_SWAP, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_from_r(%rip), %eax
orl	%eax, %edx
movl	key_from_r(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_DUP(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	key_to_r(%rip), %eax
sall	$24, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_from_r_from_r_DUP_to_r, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_CELLS(%rip), %eax
orl	%eax, %edx
movl	key_sp_fetch(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_plus(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	key_fetch(%rip), %eax
sall	$24, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_CELLS_sp_fetch_plus_fetch, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_two_dup(%rip), %eax
orl	%eax, %edx
movl	key_minus(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_to_r(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	key_dolit(%rip), %eax
sall	$24, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_two_dup_minus_to_r_dolit, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_from_r(%rip), %eax
orl	%eax, %edx
movl	key_two_dup(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_minus(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	key_to_r(%rip), %eax
sall	$24, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_from_r_two_dup_minus_to_r, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
xorl %edx, %edx
movl	key_from_r(%rip), %eax
orl	%eax, %edx
movl	key_from_r(%rip), %eax
sall	$8, %eax
orl	%eax, %edx
movl	key_two_dup(%rip), %eax
sall	$16, %eax
orl	%eax, %edx
movl	key_minus(%rip), %eax
sall	$24, %eax
orl	%eax, %edx
movl	nextSuperinstruction(%rip), %eax
cltq
salq	$4, %rax
addq	$superinstructions, %rax
movq	$code_superinstruction_from_r_from_r_two_dup_minus, (%rax)
movl	%edx, 8(%rax)
movl	nextSuperinstruction(%rip), %eax
leal	1(%rax), %edx
movl	%edx, nextSuperinstruction(%rip)
nop
ret
.cfi_endproc
.LmdFE168:
.size	init_superinstructions, .-init_superinstructions
