// Expects global.md to be the appropriate machine-dependent value.
const primitives = {};

//const next_arm = () => [
//  `ldr ${md.t1}, [${md.ip}]`,
//  `add ${md.ip}, ${md.ip}, #4`,
//  `bx  ${md.t1}`,
//];
//
//const pushrsp_arm = (reg, thru_addr, thru_val) => [
//  `movw ${thru_addr}, #:lower16:rsp`,
//  `movt ${thru_addr}, #:upper16:rsp`,
//  `ldr  ${thru_val}, [${thru_addr}]`,
//  `sub  ${thru_val}, ${thru_val}, #4`,
//  `str  ${reg}, [${thru_val}]`,
//  `str  ${thru_val}, [${thru_addr}]`,
//];
//
//const poprsp_arm = (reg, thru_addr, thru_val) => [
//  `movw ${thru_addr}, #:lower16:rsp`,
//  `movt ${thru_addr}, #:upper16:rsp`,
//  `ldr  ${thru_val}, [${thru_addr}]`,
//  `ldr  ${reg}, [${thru_val}]`,
//  `add  ${thru_val}, ${thru_val}, #4`,
//  `str  ${thru_val}, [${thru_addr}]`,
//];

primitives.plus = {
  name: 'plus',
  forthName: '+',
  x86_64: [
    `movq    (%rbx), %rax`,
    `addq    $8, %rbx`,
    `addq    %rax, (%rbx)`,
    md.next(),
  ],
};

primitives.minus = {
  name: 'minus',
  forthName: '-',
  x86_64: [
    `movq	(%rbx), %rcx`,
    `movq	8(%rbx), %rax`,
    `subq	%rcx, %rax`,
    `addq    $8, %rbx`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.times = {
  name: 'times',
  forthName: '*',
  x86_64: [
    `movq    (%rbx), %rdx`,
    `addq	$8, %rbx`,
    `movq	(%rbx), %rcx`,
    `imulq	%rcx, %rdx`,
    `movq	%rdx, (%rbx)`,
    md.next(),
  ],
};

primitives.div = {
  name: 'div',
  forthName: '/',
  x86_64: [
    `movq    (%rbx), %rsi`,
    `addq    $8, %rbx`,
    `movq    (%rbx), %rax`,
    `cqto`,
    `idivq	%rsi`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.udiv = {
  name: 'udiv',
  forthName: 'U/',
  x86_64: [
    `movq    (%rbx), %rsi`,
    `addq    $8, %rbx`,
    `movq    (%rbx), %rax`,
    `movl    $0, %edx`,
    `divq	%rsi`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.mod = {
  name: 'MOD',
  x86_64: [
    `movq    (%rbx), %rsi`,
    `addq    $8, %rbx`,
    `movq    (%rbx), %rax`,
    `cqto`,
    `idivq	%rsi`,
    `movq	%rdx, (%rbx)`,
    md.next(),
  ],
};

primitives.umod = {
  name: 'UMOD',
  x86_64: [
    `movq    (%rbx), %rsi`,
    `addq    $8, %rbx`,
    `movq    (%rbx), %rax`,
    `movl    $0, %edx`,
    `divq	%rsi      # modulus in %rdx`,
    `movq    %rdx, (%rbx)`,
    md.next(),
  ],
};

primitives.and = {
  name: 'AND',
  x86_64: [
    `movq    (%rbx), %rdx`,
    `addq    $8, %rbx`,
    `movq    (%rbx), %rax`,
    `andq	%rdx, %rax`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.or = {
  name: 'OR',
  x86_64: [
    `movq    (%rbx), %rdx`,
    `addq    $8, %rbx`,
    `movq    (%rbx), %rax`,
    `orq	 %rdx, %rax`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.xor = {
  name: 'XOR',
  x86_64: [
    `movq    (%rbx), %rax`,
    `addq    $8, %rbx`,
    `xorq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.lshift = {
  name: 'LSHIFT',
  x86_64: [
    `movq	(%rbx), %rcx     # sp[0] -> %rcx`,
    `addq    $8, %rbx`,
    `movq    (%rbx), %rsi     # sp[1] -> %rsi`,
    `salq	%cl, %rsi        # result in %rsi`,
    `movq	%rsi, (%rbx)`,
    md.next(),
  ],
};

primitives.rshift = {
  name: 'RSHIFT',
  x86_64: [
    `movq    (%rbx), %rax`,
    `movl    %eax, %ecx`,
    `addq    $8, %rbx`,
    `movq    (%rbx), %rsi`,
    `shrq	%cl, %rsi`,
    `movq	%rsi, (%rbx)`,
    md.next(),
  ],
};

primitives.base = {
  name: 'BASE',
  x86_64: [
    `subq    $8, %rbx`,
    `movl    $base, %eax`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
};

primitives.less_than = {
  name: 'less_than',
  forthName: '<',
  x86_64: [
    `movq    (%rbx), %rax`,
    `addq    $8, %rbx`,
    `movq    (%rbx), %rcx`,
    `cmpq	%rax, %rcx`,
    `jge	.Lprim17`,
    `movq	$-1, %rax`,
    `jmp	.Lprim18`,
    `.Lprim17:`,
    `movl	$0, %eax`,
    `.Lprim18:`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.less_than_unsigned = {
  name: 'less_than_unsigned',
  forthName: 'U<',
  x86_64: [
    `movq    (%rbx), %rax`,
    `addq    $8, %rbx`,
    `movq    (%rbx), %rcx`,
    `cmpq	%rax, %rcx`,
    `jnb	.Lprim20`,
    `movq	$-1, %rax`,
    `jmp	.Lprim821`,
    `.Lprim20:`,
    `movl	$0, %eax`,
    `.Lprim821:`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.equal = {
  name: 'equal',
  forthName: '=',
  x86_64: [
    `movq    (%rbx), %rcx`,
    `addq    $8, %rbx`,
    `movq    (%rbx), %rax`,
    `cmpq	%rax, %rcx`,
    `jne	.Lprim823`,
    `movq	$-1, %rax`,
    `jmp	.Lprim824`,
    `.Lprim823:`,
    `movl	$0, %eax`,
    `.Lprim824:`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.dup = {
  name: 'DUP',
  x86_64: [
    `movq    (%rbx), %rax`,
    `subq	$8, %rbx`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
};

primitives.swap = {
  name: 'SWAP',
  x86_64: [
    `movq    (%rbx), %rcx`,
    `movq    8(%rbx), %rax`,
    `movq    %rax, (%rbx)`,
    `movq    %rcx, 8(%rbx)`,
    md.next(),
  ],
};

primitives.drop = {
  name: 'DROP',
  x86_64: [
    `addq	$8, %rbx`,
    md.next(),
  ],
};

primitives.over = {
  name: 'OVER',
  x86_64: [
    `movq    8(%rbx), %rax`,
    `subq	$8, %rbx`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
};

primitives.rot = {
  name: 'ROT',
  x86_64: [
    `movq	(%rbx), %rdx # ( a c d -- c d a )`,
    `movq	8(%rbx), %rcx`,
    `movq	16(%rbx), %rax`,
    `movq    %rcx, 16(%rbx)`,
    `movq    %rdx, 8(%rbx)`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
};

primitives.neg_rot = {
  name: 'neg_rot',
  forthName: '-ROT',
  x86_64: [
    `movq	(%rbx), %rdx # ( a c d -- d a c )`,
    `movq	8(%rbx), %rcx`,
    `movq	16(%rbx), %rax`,
    `movq	%rdx, 16(%rbx)`,
    `movq	%rax, 8(%rbx)`,
    `movq	%rcx, 0(%rbx)`,
    md.next(),
  ],
};

primitives.two_drop = {
  name: 'two_drop',
  forthName: '2DROP',
  x86_64: [
    `addq	$16, %rbx`,
    md.next(),
  ],
};

primitives.two_dup = {
  name: 'two_dup',
  forthName: '2DUP',
  x86_64: [
    `subq	$16, %rbx`,
    `movq    16(%rbx), %rax`,
    `movq    %rax, (%rbx)`,
    `movq    24(%rbx), %rax`,
    `movq    %rax, 8(%rbx)`,
    md.next(),
  ],
};

primitives.two_swap = {
  name: 'two_swap',
  forthName: '2SWAP',
  x86_64: [
    `# Swap in pairs: 0/16, 8/24`,
    `# First pair, 0/16`,
    `movq	16(%rbx), %rax`,
    `movq	(%rbx), %rcx`,
    `movq    %rcx, 16(%rbx)`,
    `movq    %rax, (%rbx)`,
    `# Second pair, 8/24`,
    `movq	24(%rbx), %rax`,
    `movq	8(%rbx), %rcx`,
    `movq    %rcx, 24(%rbx)`,
    `movq    %rax, 8(%rbx)`,
    md.next(),
  ],
};

primitives.two_over = {
  name: 'two_over',
  forthName: '2OVER',
  x86_64: [
    `subq	$16, %rbx`,
    `movq	32(%rbx), %rax`,
    `movq    %rax, (%rbx)`,
    `movq	40(%rbx), %rax`,
    `movq    %rax, 8(%rbx)`,
    md.next(),
  ],
};

primitives.to_r = {
  name: 'to_r',
  forthName: '>R',
  x86_64: [
    `movq    (%rbx), %rax`,
    `addq    $8, %rbx`,
    md.pushrsp('%rax', '%rcx'),
    md.next(),
  ],
};

primitives.from_r = {
  name: 'from_r',
  forthName: 'R>',
  x86_64: [
    md.poprsp('%rax'),
    `subq    $8, %rbx`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.fetch = {
  name: 'fetch',
  forthName: '@',
  x86_64: [
    `movq    (%rbx), %rax`,
    `movq    (%rax), %rax`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
};

primitives.store = {
  name: 'store',
  forthName: '!',
  x86_64: [
    `movq	(%rbx), %rdx`,
    `movq	8(%rbx), %rax`,
    `movq	%rax, (%rdx)`,
    `addq	$16, %rbx`,
    md.next(),
  ],
};

primitives.cfetch = {
  name: 'cfetch',
  forthName: 'C@',
  x86_64: [
    `movq	(%rbx), %rax`,
    `movzbl	(%rax), %eax`,
    `movzbl	%al, %eax`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.cstore = {
  name: 'cstore',
  forthName: 'C!',
  x86_64: [
    `movq	(%rbx), %rax`,
    `movq	8(%rbx), %rcx`,
    `movb	%cl, (%rax)`,
    `addq	$16, %rbx`,
    md.next(),
  ],
};

primitives.two_fetch = {
  name: 'two_fetch',
  forthName: '2@',
  x86_64: [
    `movq    (%rbx), %rdx`,
    `subq    $8, %rbx`,
    `movq    (%rdx), %rax`,
    `movq    %rax, (%rbx)`,
    `movq    8(%rdx), %rax`,
    `movq    %rax, 8(%rbx)`,
    md.next(),
  ],
};

primitives.two_store = {
  name: 'two_store',
  forthName: '2!',
  x86_64: [
    `movq    (%rbx), %rdx   # %rdx is the target address`,
    `movq    8(%rbx), %rax`,
    `movq    %rax, (%rdx)`,
    `movq    16(%rbx), %rax`,
    `movq    %rax, 8(%rdx)`,
    `addq    $24, %rbx`,
    md.next(),
  ],
};

primitives.raw_alloc = {
  name: 'raw_alloc',
  forthName: '(ALLOCATE)',
  x86_64: [
    `movq	(%rbx), %rax`,
    `movq	%rax, %rdi`,
    `call	malloc@PLT`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.here_ptr = {
  name: 'here_ptr',
  forthName: '(>HERE)',
  x86_64: [
    `subq	$8, %rbx`,
    `movl	$dsp, %eax`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.state = {
  name: 'STATE',
  x86_64: [
    `movl	$state, %eax`,
    `subq	$8, %rbx`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.branch = {
  name: 'branch',
  forthName: '(BRANCH)',
  x86_64: [
    `movq    (%rbp), %rax   # The branch offset.`,
    `addq    %rax, %rbp`,
    md.next(),
  ],
};

primitives.zbranch = {
  name: 'zbranch',
  forthName: '(0BRANCH)',
  x86_64: [
    `movq    (%rbx), %rax`,
    `addq    $8, %rbx`,
    `testq	%rax, %rax`,
    `jne	.Lprim49`,
    `movq    (%rbp), %rax`,
    `jmp	.Lprim50`,
    `.Lprim49:`,
    `movl	$8, %eax`,
    `.Lprim50:`,
    `# Either way when we get down here, rax contains the delta.`,
    `addq    %rax, %rbp`,
    md.next(),
  ],
};

primitives.execute = {
  name: 'EXECUTE',
  x86_64: [
    `movq    (%rbx), %rax`,
    `addq    $8, %rbx`,
    `movq	%rax, cfa(%rip)`,
    `movq	(%rax), %rax`,
    `movq	%rax, ca(%rip)`,
    `jmp	*%rax`,
    // Deliberately no NEXT
  ],
};

primitives.evaluate = {
  name: 'EVALUATE',
  x86_64: [
    `addq	$1, inputIndex(%rip)`,
    `movq	inputIndex(%rip), %rdx`,
    `movq	(%rbx), %rax`,
    `salq	$5, %rdx`,
    `addq	$inputSources, %rdx`,
    `movq	%rax, (%rdx)`,
    `movq	inputIndex(%rip), %rax`,
    `movq	8(%rbx), %rdx`,
    `salq	$5, %rax`,
    `addq	$inputSources+24, %rax`,
    `movq	%rdx, (%rax)`,
    `movq	inputIndex(%rip), %rax`,
    `salq	$5, %rax`,
    `addq	$inputSources+16, %rax`,
    `movq	$-1, (%rax)`,
    `movq	inputIndex(%rip), %rax`,
    `salq	$5, %rax`,
    `addq	$inputSources+8, %rax`,
    `movq	$0, (%rax)`,
    `addq	$16, %rbx`,
    `movq	rsp(%rip), %rax`,
    `subq	$8, %rax`,
    `movq	%rax, rsp(%rip)`,
    `movq	rsp(%rip), %rax`,
    `movq	%rbp, (%rax)`,
    `jmp	*quit_inner(%rip)`,
    // Deliberately no NEXT
  ],
};

primitives.refill = {
  name: 'REFILL',
  x86_64: [
    `movq	inputIndex(%rip), %rax`,
    `salq	$5, %rax`,
    `addq	$inputSources+16, %rax`,
    `movq	(%rax), %rax`,
    `cmpq	$-1, %rax`,
    `jne	.Lprim69`,
    `subq	$8, %rbx`,
    `movq	(%rbx), %rax`,
    `movq	$0, (%rax)`,
    `jmp	.Lprim70`,
    `.Lprim69:`,
    `subq	$8, %rbx`,
    `call	refill_@PLT`,
    `movq	%rax, (%rbx)`,
    `.Lprim70:`,
    md.next(),
  ],
};

primitives.accept = {
  name: 'ACCEPT',
  x86_64: [
    `movl	$0, %edi`,
    `call	readline@PLT`,
    `movq	%rax, str1(%rip)`,
    `movq	str1(%rip), %rdi`,
    `call	strlen@PLT`,
    `movq	%rax, c1(%rip)`,
    `movq	(%rbx), %rdx`,
    `movq	c1(%rip), %rax`,
    `cmpq	%rax, %rdx`,
    `jge	.Lprim73`,
    `movq	(%rbx), %rax`,
    `movq	%rax, c1(%rip)`,
    `.Lprim73:`,
    `movq	8(%rbx), %rax`,
    `movq	c1(%rip), %rdx`,
    `movq	str1(%rip), %rsi`,
    `movq	%rax, %rdi`,
    `call	strncpy@PLT`,
    `movq	c1(%rip), %rax`,
    `addq	$8, %rbx`,
    `movq	%rax, (%rbx)`,
    `movq	str1(%rip), %rdi`,
    `call	free@PLT`,
    md.next(),
  ],
};

primitives.key = {
  name: 'KEY',
  x86_64: [
    //`movl	$old_tio, %esi`,
    //`movl	$0, %edi`,
    //`call	tcgetattr@PLT`,
    //`movq	old_tio(%rip), %rax`,
    //`movq	%rax, new_tio(%rip)`,
    //`movq	old_tio+8(%rip), %rax`,
    //`movq	%rax, new_tio+8(%rip)`,
    //`movq	old_tio+16(%rip), %rax`,
    //`movq	%rax, new_tio+16(%rip)`,
    //`movq	old_tio+24(%rip), %rax`,
    //`movq	%rax, new_tio+24(%rip)`,
    //`movq	old_tio+32(%rip), %rax`,
    //`movq	%rax, new_tio+32(%rip)`,
    //`movq	old_tio+40(%rip), %rax`,
    //`movq	%rax, new_tio+40(%rip)`,
    //`movq	old_tio+48(%rip), %rax`,
    //`movq	%rax, new_tio+48(%rip)`,
    //`movl	old_tio+56(%rip), %eax`,
    //`movl	%eax, new_tio+56(%rip)`,
    //`andl	$-11, new_tio+12(%rip)`,
    //`movl	$new_tio, %edx`,
    //`movl	$0, %esi`,
    //`movl	$0, %edi`,
    //`call	tcsetattr@PLT`,
    //`subq	$8, %rbx`,
    //`call	getchar@PLT`,
    //`cltq`,
    //`movq	%rax, (%rbx)`,
    //`movl	$old_tio, %edx`,
    //`movl	$0, %esi`,
    //`movl	$0, %edi`,
    //`call	tcsetattr@PLT`,

    `call key_@PLT`, // Leaves ch1 with the key value.
    `movq c1(%rip), %rax`,
    `subq $8, %rbx`,
    `movq %rax, (%rbx)`, // Pushed the key code to the stack.
    md.next(),
  ],
};

primitives.latest = {
  name: 'latest',
  forthName: '(LATEST)',
  x86_64: [
    `subq	$8, %rbx`,
    `movq    compilationWordlist(%rip), %rax`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.dictionary_info = {
  name: 'dictionary_info',
  forthName: '(DICT-INFO)',
  x86_64: [
    `subq    $24, %rbx`,
    `movl	$compilationWordlist, %eax`,
    `movq	%rax, 16(%rbx)`,
    `movl	$searchIndex, %eax`,
    `movq	%rax, 8(%rbx)`,
    `movl    $searchArray, %eax`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
};

primitives.in_ptr = {
  name: 'in_ptr',
  forthName: '>IN',
  x86_64: [
    `subq	$8, %rbx`,
    `movq	inputIndex(%rip), %rdx`,
    `salq	$5, %rdx`,
    `addq	$inputSources, %rdx`,
    `addq	$8, %rdx`,
    `movq	%rdx, (%rbx)`,
    md.next(),
  ],
};

primitives.emit = {
  name: 'EMIT',
  x86_64: [
    `movq	stdout(%rip), %rdx`,
    `movq    (%rbx), %rax`,
    `addq    $8, %rbx`,
    `movq	%rdx, %rsi`,
    `movl	%eax, %edi`,
    `call	fputc@PLT`,
    md.next(),
  ],
};

primitives.source = {
  name: 'SOURCE',
  x86_64: [
    `subq	$16, %rbx`,
    `movq	inputIndex(%rip), %rax`,
    `salq	$5, %rax`,
    `addq	$inputSources, %rax`,
    `movq	(%rax), %rax`,
    `movq	%rax, (%rbx)`,
    `movq	inputIndex(%rip), %rax`,
    `salq	$5, %rax`,
    `addq	$inputSources+24, %rax`,
    `movq	(%rax), %rax`,
    `movq	%rax, 8(%rbx)`,
    md.next(),
  ],
};

primitives.source_id = {
  name: 'source_id',
  forthName: 'SOURCE-ID',
  x86_64: [
    `subq	$8, %rbx`,
    `movq	inputIndex(%rip), %rax`,
    `salq	$5, %rax`,
    `addq	$inputSources+16, %rax`,
    `movq	(%rax), %rax`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.size_cell = {
  name: 'size_cell',
  forthName: '(/CELL)',
  x86_64: [
    `subq	$8, %rbx`,
    `movq	$8, (%rbx)`,
    md.next(),
  ],
};

primitives.size_char = {
  name: 'size_char',
  forthName: '(/CHAR)',
  x86_64: [
    `subq	$8, %rbx`,
    `movq	$1, (%rbx)`,
    md.next(),
  ],
};

primitives.cells = {
  name: 'CELLS',
  x86_64: [
    `movq	(%rbx), %rax`,
    `salq	$3, %rax`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.chars = {
  name: 'CHARS',
  x86_64: [
    md.next(),
  ],
};

primitives.unit_bits = {
  name: 'unit_bits',
  forthName: '(ADDRESS-UNIT-BITS)',
  x86_64: [
    `subq	$8, %rbx`,
    `movq	$8, (%rbx)`,
    md.next(),
  ],
};

primitives.stack_cells = {
  name: 'stack_cells',
  forthName: '(STACK-CELLS)',
  x86_64: [
    `subq	$8, %rbx`,
    `movq	$16384, (%rbx)`,
    md.next(),
  ],
};

primitives.return_stack_cells = {
  name: 'return_stack_cells',
  forthName: '(RETURN-STACK-CELLS)',
  x86_64: [
    `subq	$8, %rbx`,
    `movq	$1024, (%rbx)`,
    md.next(),
  ],
};

primitives.to_does = {
  name: 'to_does',
  forthName: '(>DOES)',
  x86_64: [
    `movq	(%rbx), %rax`,
    `addq	$32, %rax`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.to_cfa = {
  name: 'to_cfa',
  forthName: '(>CFA)',
  x86_64: [
    `movq	(%rbx), %rax`,
    `addq	$24, %rax`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.to_body = {
  name: 'to_body',
  forthName: '>BODY',
  x86_64: [
    `movq	(%rbx), %rax`,
    `addq	$16, %rax`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.last_word = {
  name: 'last_word',
  forthName: '(LAST-WORD)',
  x86_64: [
    `subq	$8, %rbx`,
    `movq	lastWord(%rip), %rax`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.docol = {
  name: 'docol',
  forthName: '(DOCOL)',
  x86_64: [
    `movq	rsp(%rip), %rax`,
    `subq	$8, %rax`,
    `movq	%rax, rsp(%rip)`,
    `movq	%rbp, (%rax)`,
    `movq	cfa(%rip), %rax`,
    `addq	$8, %rax`,
    `movq	%rax, %rbp`,
    md.next(),
  ],
};

primitives.dolit = {
  name: 'dolit',
  forthName: '(DOLIT)',
  x86_64: [
    `subq	$8, %rbx`,
    `movq    (%rbp), %rax`,
    `movq    %rax, (%rbx)`,
    `addq    $8, %rbp`,
    md.next(),
  ],
};

primitives.dostring = {
  name: 'dostring',
  forthName: '(DOSTRING)',
  x86_64: [
    // Flow: next byte on TOS, address after it below.
    // Advance the IP (%rbp) by that byte, + 1, and then align it.
    `subq    $16, %rbx`,
    `movzbl  (%rbp), %eax`,
    `movsbq  %al, %rax    # Single byte length now in %rax`,
    `movq    %rax, (%rbx) # And on TOS`,

    `movq    %rbp, %rcx`,
    `addq    $1, %rcx      # %rcx now holds the string address`,
    `movq    %rcx, 8(%rbx) # which is next on the stack`,

    `addq    %rcx, %rax    # %rax is now the point after the string.`,
    `addq    $7, %rax`,
    `andq    $-8, %rax     # which is now rounded up so as to be aligned.`,
    `movq    %rax, %rbp    # and moved back to IP`,
    md.next(),
  ],
};

primitives.dodoes = {
  name: 'dodoes',
  forthName: '(DODOES)',
  x86_64: [
    // Push the address of the data area (cfa + 2 cells).
    // Then check cfa + 1 cell: if nonzero, call into it.
    `movq	cfa(%rip), %rax    # CFA in %rax`,
    `movq    %rax, %rcx`,
    `addq    $16, %rcx`,
    `subq    $8, %rbx`,
    `movq    %rcx, (%rbx)       # Push the data space address.`,
    `addq    $8, %rax`,
    `movq    (%rax), %rax       # Now %rax holds the does> address`,
    `movq    %rax, %rcx         # Which I'll set aside.`,
    `testq	%rax, %rax`,
    `je	.Lprim98`,
    `movq	rsp(%rip), %rax`,
    `subq	$8, %rax`,
    `movq	%rax, rsp(%rip)`,
    `movq	%rbp, (%rax)`,
    `movq	%rcx, %rbp`,
    `.Lprim98:`,
    md.next(),
  ],
};

primitives.parse = {
  name: 'PARSE',
  x86_64: [
    // parse_() in C expects ch1 as the separator (TOS), and puts
    // length in c1, string in str1 as the output.
    // The stack effect desired is ( sep -- c-addr u )
    `movq (%rbx), %rax`,
    `movb %al, ch1(%rip)`,
    `call	parse_@PLT`,
    `subq $8, %rbx`,
    `movq str1(%rip), %rax`,
    `movq %rax, 8(%rbx)`,
    `movq c1(%rip), %rax`,
    `movq %rax, (%rbx)`,
    md.next(),
  ],
};

primitives.parse_name = {
  name: 'parse_name',
  forthName: 'PARSE-NAME',
  x86_64: [
    `call	parse_name_stacked@PLT`,
    md.next(),
  ],
};

primitives.to_number = {
  name: 'to_number',
  forthName: '>NUMBER',
  x86_64: [
    `call	to_number_@PLT`,
    md.next(),
  ],
};

primitives.create = {
  name: 'CREATE',
  x86_64: [
    // TODO: Optimize. Low priority, CREATE is not very hot.
    `call	parse_name_stacked@PLT`,
    `movq	dsp(%rip), %rax`,
    `addq	$7, %rax`,
    `andq	$-8, %rax`,
    `movq	%rax, dsp(%rip)`,
    `movq	%rax, tempHeader(%rip)`,
    `addq	$32, dsp(%rip)`,
    `movq	tempHeader(%rip), %rax`,
    `movq	compilationWordlist(%rip), %rdx`,
    `movq    (%rdx), %rdx`,
    `movq	%rdx, (%rax)`,

    `movq	tempHeader(%rip), %rax`,
    `movq    compilationWordlist(%rip), %rdx`,
    `movq    %rax, (%rdx)`,

    `movq	tempHeader(%rip), %rax`,
    `movq	(%rbx), %rdx`,
    `movq	%rdx, 8(%rax)`,

    `movq	tempHeader(%rip), %r12`,
    `movq	(%rbx), %rdi`,
    `call	malloc@PLT`,
    `movq	%rax, 16(%r12)`,
    `movq	(%rbx), %rdx`,
    `movq	8(%rbx), %rsi`,
    `movq	16(%r12), %rax`,
    `movq	%rax, %rdi`,
    `call	strncpy@PLT`,
    `addq	$16, %rbx`,

    `movq	tempHeader(%rip), %rax`,
    `movq	$code_dodoes, 24(%rax)`,
    `movq	dsp(%rip), %rax`,
    `leaq	8(%rax), %rdx`,
    `movq	%rdx, dsp(%rip)`,
    `movq	$0, (%rax)`,
    md.next(),
  ],
};

primitives.find = {
  name: 'find',
  forthName: '(FIND)',
  x86_64: [
    `call	find_@PLT`,
    md.next(),
  ],
};

primitives.depth = {
  name: 'DEPTH',
  x86_64: [
    `movq	spTop(%rip), %rax`,
    `subq	%rbx, %rax`,
    `shrq	$3, %rax`,
    `subq    $8, %rbx`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
};

primitives.sp_fetch = {
  name: 'sp_fetch',
  forthName: 'SP@',
  x86_64: [
    `movq    %rbx, %rax`,
    `subq    $8, %rbx`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
};

primitives.sp_store = {
  name: 'sp_store',
  forthName: 'SP!',
  x86_64: [
    `movq	(%rbx), %rbx`,
    md.next(),
  ],
};

primitives.rp_fetch = {
  name: 'rp_fetch',
  forthName: 'RP@',
  x86_64: [
    `subq	$8, %rbx`,
    `movq	rsp(%rip), %rax`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.rp_store = {
  name: 'rp_store',
  forthName: 'RP!',
  x86_64: [
    `movq	(%rbx), %rax`,
    `addq    $8, %rbx`,
    `movq	%rax, rsp(%rip)`,
    md.next(),
  ],
};

primitives.quit = {
  name: 'QUIT',
  x86_64: [
    `movq	$0, inputIndex(%rip)`,
    `call	quit_@PLT`,
    md.next(),
  ],
};

primitives.bye = {
  name: 'BYE',
  x86_64: [
    `movl	$0, %edi`,
    `call	exit@PLT`,
    // No next needed.
  ],
};

primitives.compile_comma = {
  name: 'compile_comma',
  forthName: 'COMPILE,',
  x86_64: [
    `movl	$0, %eax`,
    `call	compile_@PLT`,
    md.next(),
  ],
};

primitives.literal = {
  name: 'LITERAL',
  immediate: true,
  x86_64: [
    `movl	$0, %eax`,
    `call	compile_lit_@PLT`,
    md.next(),
  ],
};

primitives.compile_literal = {
  name: 'compile_literal',
  forthName: '[LITERAL]',
  x86_64: [
    `movl	$0, %eax`,
    `call	compile_lit_@PLT`,
    md.next(),
  ],
};

primitives.compile_zbranch = {
  name: 'compile_zbranch',
  forthName: '[0BRANCH]',
  x86_64: [
    `subq	$8, %rbx`,
    `movl	$header_zbranch+24, %eax`,
    `movq	%rax, (%rbx)`,
    `movl	$0, %eax`,
    `call	compile_@PLT`,
    `jmp	.Lprim244`,
    `.Lprim245:`,
    `call	drain_queue_@PLT`,
    `.Lprim244:`,
    `movl	queue_length(%rip), %eax`,
    `testl	%eax, %eax`,
    `jg	.Lprim245`,
    `subq	$8, %rbx`,
    `movq	dsp(%rip), %rax`,
    `movq	%rax, (%rbx)`,
    `movq    $0, (%rax)`,
    `addq    $8, %rax`,
    `movq    %rax, dsp(%rip)`,
    md.next(),
  ],
};

primitives.compile_branch = {
  name: 'compile_branch',
  forthName: '[BRANCH]',
  x86_64: [
    `subq	$8, %rbx`,
    `movl	$header_branch+24, %edx`,
    `movq	%rdx, (%rbx)`,
    `movl	$0, %eax`,
    `call	compile_@PLT`,
    `jmp	.Lprim248`,
    `.Lprim249:`,
    `call	drain_queue_@PLT`,
    `.Lprim248:`,
    `movl	queue_length(%rip), %eax`,
    `testl	%eax, %eax`,
    `jg	.Lprim249`,
    `subq	$8, %rbx`,
    `movq	dsp(%rip), %rax`,
    `movq	%rax, (%rbx)`,
    `movq	dsp(%rip), %rax`,
    `leaq	8(%rax), %rdx`,
    `movq	%rdx, dsp(%rip)`,
    `movq	$0, (%rax)`,
    md.next(),
  ],
};

primitives.control_flush = {
  name: 'control_flush',
  forthName: '(CONTROL-FLUSH)',
  x86_64: [
    `jmp	.Lprim252`,
    `.Lprim253:`,
    `call	drain_queue_@PLT`,
    `.Lprim252:`,
    `movl	queue_length(%rip), %eax`,
    `testl	%eax, %eax`,
    `jg	.Lprim253`,
    md.next(),
  ],
};

primitives.debug_break = {
  name: 'debug_break',
  forthName: '(DEBUG)',
  x86_64: [
    md.next(),
  ],
};

primitives.close_file = {
  name: 'close_file',
  forthName: 'CLOSE-FILE',
  x86_64: [
    `movq	(%rbx), %rdi`,
    `call	fclose@PLT`,
    `cltq`,
    `testq	%rax, %rax`,
    `je	.Lprim256`,
    `call	__errno_location@PLT`,
    `movl	(%rax), %eax`,
    `cltq`,
    `jmp	.Lprim257`,
    `.Lprim256:`,
    `movl	$0, %eax`,
    `.Lprim257:`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.create_file = {
  name: 'create_file',
  forthName: 'CREATE-FILE',
  x86_64: [
    `movq    8(%rbx), %rdx`,
    `movq    16(%rbx), %rsi`,
    `movl	$tempBuf, %edi`,
    `call	strncpy@PLT`,
    `movq	8(%rbx), %rax`,
    `movb	$0, tempBuf(%rax)`,
    `addq	$8, %rbx`,

    `movq    (%rbx), %rax`,
    `orq     $8, %rax`,
    `movq	file_modes(,%rax,8), %rax`,
    `movq	%rax, %rsi`,
    `movl	$tempBuf, %edi`,
    `call	fopen@PLT`,
    `movq	%rax, 8(%rbx)`,
    `testq	%rax, %rax`,
    `jne	.Lprim260`,
    `call	__errno_location@PLT`,
    `movl	(%rax), %eax`,
    `cltq`,
    `jmp	.Lprim261`,
    `.Lprim260:`,
    `movl	$0, %eax`,
    `.Lprim261:`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.open_file = {
  name: 'open_file',
  forthName: 'OPEN-FILE',
  x86_64: [
    `movq    8(%rbx), %rdx`,
    `movq    16(%rbx), %rsi`,
    `movl	$tempBuf, %edi`,
    `call	strncpy@PLT`,
    `movq	8(%rbx), %rax`,
    `movb	$0, tempBuf(%rax)`,
    `movq	(%rbx), %rax`,
    `movq	file_modes(,%rax,8), %rax`,
    `movq	%rax, %rsi`,
    `movl	$tempBuf, %edi`,
    `call	fopen@PLT`,
    `movq	%rax, 16(%rbx)`,
    `testq	%rax, %rax`,
    `jne	.Lprim264`,
    `movq	(%rbx), %rax`,
    `andl	$2, %eax`,
    `testq	%rax, %rax`,
    `je	.Lprim264`,
    `movq	(%rbx), %rax`,
    `orq	$8, %rax`,
    `movq	file_modes(,%rax,8), %rax`,
    `movq	%rax, %rsi`,
    `movl	$tempBuf, %edi`,
    `call	fopen@PLT`,
    `movq	%rax, 16(%rbx)`,
    `.Lprim264:`,
    `movq	16(%rbx), %rax`,
    `testq	%rax, %rax`,
    `jne	.Lprim265`,
    `call	__errno_location@PLT`,
    `movl	(%rax), %eax`,
    `cltq`,
    `jmp	.Lprim266`,
    `.Lprim265:`,
    `movl	$0, %eax`,
    `.Lprim266:`,
    `addq	$8, %rbx`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.delete_file = {
  name: 'delete_file',
  forthName: 'DELETE-FILE',
  x86_64: [
    `movq    (%rbx), %rdx`,
    `movq    8(%rbx), %rsi`,
    `movl	$tempBuf, %edi`,
    `call	strncpy@PLT`,
    `movq	(%rbx), %rax`,
    `movb	$0, tempBuf(%rax)`,
    `addq	$8, %rbx`,
    `movl	$tempBuf, %edi`,
    `call	remove@PLT`,
    `cltq`,
    `movq	%rax, (%rbx)`,
    `cmpq	$-1, %rax`,
    `jne	.Lprim269`,
    `call	__errno_location@PLT`,
    `movl	(%rax), %eax`,
    `cltq`,
    `movq	%rax, (%rbx)`,
    `.Lprim269:`,
    md.next(),
  ],
};

primitives.file_position = {
  name: 'file_position',
  forthName: 'FILE-POSITION',
  x86_64: [
    `subq	$16, %rbx`,
    `movq    $0, 8(%rbx)`,
    `movq    16(%rbx), %rdi`,
    `call	ftell@PLT`,
    `movq	%rax, 16(%rbx)`,
    `cmpq	$-1, %rax`,
    `jne	.Lprim272`,
    `call	__errno_location@PLT`,
    `movl	(%rax), %eax`,
    `cltq`,
    `jmp	.Lprim273`,
    `.Lprim272:`,
    `movl	$0, %eax`,
    `.Lprim273:`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.file_size = {
  name: 'file_size',
  forthName: 'FILE-SIZE',
  x86_64: [
    `subq	$16, %rbx`,
    `movq    $0, 8(%rbx)`,
    `movq    16(%rbx), %rdi`,
    `call	ftell@PLT`,
    `movq	%rax, c1(%rip)`,
    `testq	%rax, %rax`,
    `jns	.Lprim276`,
    `call	__errno_location@PLT`,
    `movl	(%rax), %eax`,
    `cltq`,
    `movq	%rax, (%rbx)`,
    `jmp	.Lprim277`,
    `.Lprim276:`,
    `movl	$2, %edx`,
    `movl	$0, %esi`,
    `movq	16(%rbx), %rdi`,
    `call	fseek@PLT`,
    `cltq`,
    `movq	%rax, c2(%rip)`,
    `testq	%rax, %rax`,
    `jns	.Lprim278`,
    `call	__errno_location@PLT`,
    `movl	(%rax), %eax`,
    `cltq`,
    `movq	%rax, (%rbx)`,
    `movq	16(%rbx), %rdi`,
    `movl	$0, %edx`,
    `movq	c1(%rip), %rsi`,
    `call	fseek@PLT`,
    `jmp	.Lprim277`,
    `.Lprim278:`,
    `movq	16(%rbx), %rdi`,
    `call	ftell@PLT`,
    `movq	%rax, c2(%rip)`,
    `movq	16(%rbx), %rdi`,
    `movl	$0, %edx`,
    `movq	c1(%rip), %rsi`,
    `call	fseek@PLT`,
    `movq	c2(%rip), %rax`,
    `movq	%rax, 16(%rbx)`,
    `movq	$0, (%rbx)`,
    `.Lprim277:`,
    md.next(),
  ],
};

primitives.include_file = {
  name: 'include_file',
  forthName: 'INCLUDE-FILE',
  x86_64: [
    `addq	$1, inputIndex(%rip)`,
    `movq	inputIndex(%rip), %rcx`,
    `movq	(%rbx), %rax`,
    `addq	$8, %rbx`,
    `salq	$5, %rcx`,
    `movq	%rcx, %rdx`,
    `addq	$inputSources+16, %rdx`,
    `movq	%rax, (%rdx)`,
    `movq	inputIndex(%rip), %rax`,
    `salq	$5, %rax`,
    `addq	$inputSources+8, %rax`,
    `movq	$0, (%rax)`,
    `movq	inputIndex(%rip), %rax`,
    `salq	$5, %rax`,
    `addq	$inputSources, %rax`,
    `movq	$0, (%rax)`,
    `movq	inputIndex(%rip), %rax`,
    `movq	inputIndex(%rip), %rdx`,
    `salq	$8, %rdx`,
    `addq	$parseBuffers, %rdx`,
    `salq	$5, %rax`,
    `addq	$inputSources+24, %rax`,
    `movq	%rdx, (%rax)`,
    md.next(),
  ],
};

primitives.read_file = {
  name: 'read_file',
  forthName: 'READ-FILE',
  x86_64: [
    `movq    (%rbx), %rcx`,
    `movq    8(%rbx), %rdx`,
    `movl	$1, %esi`,
    `movq	16(%rbx), %rdi`,
    `call	fread@PLT`,
    `movq	%rax, c1(%rip)`,
    `testq	%rax, %rax`,
    `jne	.Lprim282`,
    `movq	(%rbx), %rdi`,
    `call	feof@PLT`,
    `testl	%eax, %eax`,
    `je	.Lprim283`,
    `addq	$8, %rbx`,
    `movq	$0, (%rbx)`,
    `movq	$0, 8(%rbx)`,
    `jmp	.Lprim285`,
    `.Lprim283:`,
    `movq	(%rbx), %rdi`,
    `call	ferror@PLT`,
    `cltq`,
    `movq	%rax, 8(%rbx)`,
    `movq	$0, 16(%rbx)`,
    `jmp	.Lprim285`,
    `.Lprim282:`,
    `addq	$8, %rbx`,
    `movq	c1(%rip), %rax`,
    `movq	%rax, 8(%rbx)`,
    `movq	$0, (%rbx)`,
    `.Lprim285:`,
    md.next(),
  ],
};

primitives.read_line = {
  name: 'read_line',
  forthName: 'READ-LINE',
  x86_64: [
    `movq	$0, str1(%rip)`,
    `movq	$0, tempSize(%rip)`,
    `movq	(%rbx), %rdx`,
    `movl	$tempSize, %esi`,
    `movl	$str1, %edi`,
    `call	getline@PLT`,
    `movq	%rax, c1(%rip)`,
    `cmpq	$-1, %rax`,
    `jne	.Lprim288`,
    `call	__errno_location@PLT`,
    `movl	(%rax), %eax`,
    `cltq`,
    `movq	%rax, (%rbx)`,
    `movq	$0, 8(%rbx)`,
    `movq	$0, 16(%rbx)`,
    `jmp	.Lprim289`,
    `.Lprim288:`,
    `movq	c1(%rip), %rax`,
    `testq	%rax, %rax`,
    `jne	.Lprim290`,
    `movq	$0, (%rbx)`,
    `movq	$0, 8(%rbx)`,
    `movq	$0, 16(%rbx)`,
    `jmp	.Lprim289`,
    `.Lprim290:`,
    `movq	c1(%rip), %rax`,
    `leaq	-1(%rax), %rdx`,
    `movq	8(%rbx), %rax`,
    `cmpq	%rax, %rdx`,
    `jle	.Lprim291`,
    `movq	8(%rbx), %rdx`,
    `movq	(%rbx), %rax`,
    `movq	c1(%rip), %rcx`,
    `subq	%rdx, %rcx`,
    `movl	$1, %edx`,
    `movq	%rcx, %rsi`,
    `movq	%rax, %rdi`,
    `call	fseek@PLT`,
    `movq	8(%rbx), %rax`,
    `addq	$1, %rax`,
    `movq	%rax, c1(%rip)`,
    `jmp	.Lprim292`,
    `.Lprim291:`,
    `movq	str1(%rip), %rdx`,
    `movq	c1(%rip), %rax`,
    `addq	%rdx, %rax`,
    `subq	$1, %rax`,
    `movzbl	(%rax), %eax`,
    `cmpb	$10, %al`,
    `je	.Lprim292`,
    `addq	$1, c1(%rip)`,
    `.Lprim292:`,
    `movq	c1(%rip), %rax`,
    `leaq	-1(%rax), %rdx`,
    `movq	16(%rbx), %rax`,
    `movq	str1(%rip), %rsi`,
    `movq	%rax, %rdi`,
    `call	strncpy@PLT`,
    `movq	$0, (%rbx)`,
    `movq	$-1, 8(%rbx)`,
    `movq	c1(%rip), %rax`,
    `subq	$1, %rax`,
    `movq	%rax, 16(%rbx)`,
    `.Lprim289:`,
    `movq	str1(%rip), %rax`,
    `testq	%rax, %rax`,
    `je	.Lprim293`,
    `movq	str1(%rip), %rdi`,
    `call	free@PLT`,
    `.Lprim293:`,
    md.next(),
  ],
};

primitives.reposition_file = {
  name: 'reposition_file',
  forthName: 'REPOSITION-FILE',
  x86_64: [
    `movq	16(%rbx), %rsi`,
    `movq	(%rbx), %rdi`,
    `movl	$0, %edx`,
    `call	fseek@PLT`,
    `cltq`,
    `movq	%rax, 16(%rbx)`,
    `addq	$16, %rbx`,
    `movq	(%rbx), %rax`,
    `cmpq	$-1, %rax`,
    `jne	.Lprim296`,
    `call	__errno_location@PLT`,
    `movl	(%rax), %eax`,
    `cltq`,
    `movq	%rax, (%rbx)`,
    `.Lprim296:`,
    md.next(),
  ],
};

primitives.resize_file = {
  name: 'resize_file',
  forthName: 'RESIZE-FILE',
  x86_64: [
    `movq    (%rbx), %rdi`,
    `call    fileno@PLT`,
    `movl    %eax, %edi`,
    `movq    16(%rbx), %rsi`,
    `call	ftruncate@PLT`,
    `cltq`,
    `movq	%rax, 16(%rbx)`,
    `addq	$16, %rbx`,
    `movq	(%rbx), %rax`,
    `cmpq	$-1, %rax`,
    `jne	.Lprim299`,
    `call	__errno_location@PLT`,
    `movl	(%rax), %eax`,
    `cltq`,
    `jmp	.Lprim300`,
    `.Lprim299:`,
    `movl	$0, %eax`,
    `.Lprim300:`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
};

primitives.write_file = {
  name: 'write_file',
  forthName: 'WRITE-FILE',
  x86_64: [
    `movq	(%rbx), %rcx`,
    `movq	8(%rbx), %rdx`,
    `movl	$1, %esi`,
    `movq	16(%rbx), %rdi`,
    `call	fwrite@PLT`,
    `movq	%rax, c1(%rip)`,
    `addq	$16, %rbx`,
    `movq	$0, (%rbx)`,
    md.next(),
  ],
};

primitives.write_line = {
  name: 'write_line',
  forthName: 'WRITE-LINE',
  x86_64: [
    `movq	8(%rbx), %rdx`,
    `movq	16(%rbx), %rsi`,
    `movl	$tempBuf, %edi`,
    `call	strncpy@PLT`,
    `movq	8(%rbx), %rax`,
    `movb	$10, tempBuf(%rax)`,
    `movq	(%rbx), %rcx`,
    `movq	8(%rbx), %rdx`,
    `addq    $1, %rdx`,
    `movl    $1, %esi`,
    `movl	$tempBuf, %edi`,
    `call	fwrite@PLT`,
    `addq	$16, %rbx`,
    `movq	$0, (%rbx)`,
    md.next(),
  ],
};

primitives.flush_file = {
  name: 'flush_file',
  forthName: 'FLUSH-FILE',
  x86_64: [
    `movq	(%rbx), %rdi`,
    `call	fileno@PLT`,
    `movl	%eax, %edi`,
    `call	fsync@PLT`,
    `cltq`,
    `movq	%rax, (%rbx)`,
    `cmpq	$-1, %rax`,
    `jne	.Lprim307`,
    `call	__errno_location@PLT`,
    `movl	(%rax), %eax`,
    `cltq`,
    `movq	%rax, (%rbx)`,
    `.Lprim307:`,
    md.next(),
  ],
};

primitives.colon = {
  name: 'colon',
  forthName: ':',
  x86_64: [
    `movq	dsp(%rip), %rax`,
    `addq	$7, %rax`,
    `andq	$-8, %rax`,
    `movq	%rax, dsp(%rip)`,
    `movq	%rax, tempHeader(%rip)`,
    `addq	$32, dsp(%rip)`,
    `movq	tempHeader(%rip), %rax`,
    `movq	compilationWordlist(%rip), %rdx`,
    `movq    (%rdx), %rcx   # The actual previous head.`,
    `movq	%rcx, (%rax)   # Written to the new header.`,
    `movq    %rax, (%rdx)   # And the new one into the compilation list`,
    `call	parse_name_stacked@PLT`,
    `movq	(%rbx), %rax`,
    `testq	%rax, %rax`,
    `jne	.Lprim310`,
    `movq	stderr(%rip), %rcx`,
    `movl	$34, %edx`,
    `movl	$1, %esi`,
    `movl	$.LmdC117, %edi`,
    `call	fwrite@PLT`,
    `call	code_QUIT@PLT`,
    `.Lprim310:`,
    `movq	tempHeader(%rip), %r12`,
    `movq	(%rbx), %rdi`,
    `call	malloc@PLT`,
    `movq	%rax, 16(%r12)`,
    `movq	(%rbx), %rdx`,
    `movq	8(%rbx), %rsi`,
    `movq	%rax, %rdi`,
    `call	strncpy@PLT`,
    `movq	tempHeader(%rip), %rax`,
    `movq	(%rbx), %rdx`,
    `orb	$1, %dh`,
    `movq	%rdx, 8(%rax)`,
    `addq	$16, %rbx`,
    `movq	tempHeader(%rip), %rax`,
    `movq	$code_docol, 24(%rax)`,
    `movq	tempHeader(%rip), %rax`,
    `addq	$24, %rax`,
    `movq	%rax, lastWord(%rip)`,
    `movq	$1, state(%rip)`,
    md.next(),
  ],
};

primitives.colon_no_name = {
  name: 'colon_no_name',
  forthName: ':NONAME',
  x86_64: [
    `movq	dsp(%rip), %rax`,
    `addq	$7, %rax`,
    `andq	$-8, %rax`,
    `movq	%rax, dsp(%rip)`,
    `movq	dsp(%rip), %rax`,
    `movq	%rax, lastWord(%rip)`,
    `subq	$8, %rbx`,
    `movq	dsp(%rip), %rdx`,
    `movq	%rdx, (%rbx)`,
    `movq	dsp(%rip), %rax`,
    `leaq	8(%rax), %rdx`,
    `movq	%rdx, dsp(%rip)`,
    `movl	$code_docol, %edx`,
    `movq	%rdx, (%rax)`,
    `movq	$1, state(%rip)`,
    md.next(),
  ],
};

primitives.exit = {
  name: 'EXIT',
  x86_64: [
    md.exitNext(),
  ],
};

primitives.utime = {
  name: 'UTIME',
  x86_64: [
    `movl	$0, %esi`,
    `movl	$timeVal, %edi`,
    `call	gettimeofday@PLT`,
    `subq	$16, %rbx`,
    `movq	timeVal(%rip), %rdx`,
    `imulq	$1000000, %rdx, %rdx`,
    `movq	timeVal+8(%rip), %rcx`,
    `addq	%rcx, %rdx`,
    `movq	%rdx, 8(%rbx)`,
    `movq	$0, (%rbx)`,
    md.next(),
  ],
};

primitives.semicolon = {
  name: 'semicolon',
  forthName: ';',
  immediate: true,
  x86_64: [
    `movq	compilationWordlist(%rip), %rax  # Pointer to the header`,
    `movq    (%rax), %rax  # The header itself.`,
    `movq	8(%rax), %rdx # The length word.`,
    `andb	$254, %dh`,
    `movq	%rdx, 8(%rax)`,
    `subq    $8, %rbx`,
    `movq	$header_EXIT+24, %rdx`,
    `movq	%rdx, (%rbx)`,
    `movl	$0, %eax`,
    `call	compile_@PLT`,
    `jmp	.Lprim330`,
    `.Lprim331:`,
    `call	drain_queue_@PLT`,
    `.Lprim330:`,
    `movl	queue_length(%rip), %eax`,
    `testl	%eax, %eax`,
    `jne	.Lprim331`,
    `movq	$0, state(%rip)`,
    md.next(),
  ],
};

primitives.loop_end = {
  name: 'loop_end',
  forthName: '(LOOP-END)',
  x86_64: [
    `movq    rsp(%rip), %r9    # r9 holds the RSP`,
    `movq    (%r9), %rcx       # rcx holds the index`,
    `movq    %rcx, %rdx`,
    `subq    8(%r9), %rdx      # rdx holds the index-limit`,
    `movq    (%rbx), %r10      # r10 caches the delta`,

    `# Calculate delta + limit-index`,
    `movq    %r10, %rax`,
    `addq    %rdx, %rax`,
    `xorq    %rdx, %rax     # rax is now d+i-l XOR i-l`,
    `# We want a truth flag that's true when the top bit is 0.`,
    `testq   %rax, %rax`,
    `js      .Lprim9901         # Jumps when the top bit is 1.`,
    `movq    $-1, %r11      # Sets flag true when top bit is 0.`,
    `jmp     .Lprim9902`,

    `.Lprim9901:`,
    `movq    $0, %r11       # Or false when top bit is 1.`,
    `.Lprim9902:`,
    `movq    %rdx, %rax     # rdx is the index-limit, remember.`,
    `xorq    %r10, %rax     # now rax is delta XOR index-limit`,
    `# Same flow as above: true flag when top bit is 0.`,
    `# We OR the new result with the old one, in r11.`,
    `testq   %rax, %rax`,
    `js      .Lprim9903         # Jumps when the top bit is 1.`,
    `orq     $-1, %r11      # Sets flag true when top bit is 0.`,
    `jmp     .Lprim9904`,

    `.Lprim9903:`,
    `orq     $0, %r11       # Or false when top bit is 1.`,
    `.Lprim9904:`,
    `# Finally, negate the returned flag.`,
    `xorq    $-1, %r11`,
    `# Now r11 holds the flag we want to return, write it onto the stack.`,
    `movq    %r11, (%rbx)`,
    `# And write the delta + index onto the return stack.`,
    `addq    %r10, %rcx`,
    `movq    %rcx, (%r9)`,
    md.next(),
  ],
};

primitives.ccall0 = {
  name: 'CCALL0',
  x86_64: [
    `movq    (%rbx), %rax  # Only argument is the C function address.`,
    `call    *%rax`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
};

primitives.ccall1 = {
  name: 'CCALL1',
  x86_64: [
    `movq    8(%rbx), %rdi # TOS = first argument`,
    `movq    (%rbx), %rax`,
    `subq    $8, %rsp`,
    `call    *%rax`,
    `addq    $8, %rsp`,
    `addq    $8, %rbx`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
};

primitives.ccall2 = {
  name: 'CCALL2',
  x86_64: [
    `movq    16(%rbx), %rdi # sp[2] = first argument`,
    `movq    8(%rbx), %rsi # TOS = second argument`,
    `movq    (%rbx), %rax`,
    `subq    $8, %rsp # Align rsp to 16 bytes`,
    `call    *%rax`,
    `addq    $8, %rsp`,
    `addq    $16, %rbx`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
};

primitives.ccall3 = {
  name: 'CCALL3',
  x86_64: [
    `movq    24(%rbx), %rdi # sp[3] = first argument`,
    `movq    16(%rbx), %rsi # sp[2] = second argument`,
    `movq    8(%rbx), %rdx # TOS = third argument`,
    `movq    (%rbx), %rax`,
    `subq    $8, %rsp # Align rsp to 16 bytes`,
    `call    *%rax`,
    `addq    $8, %rsp`,
    `addq    $24, %rbx`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
};

primitives.ccall4 = {
  name: 'CCALL4',
  x86_64: [
    `movq    32(%rbx), %rdi # sp[4] = first argument`,
    `movq    24(%rbx), %rsi # sp[3] = second argument`,
    `movq    16(%rbx), %rdx # sp[2] = third argument`,
    `movq    8(%rbx), %rcx # TOS = fourth argument`,
    `movq    (%rbx), %rax`,
    `subq    $8, %rsp # Align rsp to 16 bytes`,
    `call    *%rax`,
    `addq    $8, %rsp`,
    `addq    $32, %rbx`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
};

primitives.ccall5 = {
  name: 'CCALL5',
  x86_64: [
    `movq    40(%rbx), %rdi # sp[5] = first argument`,
    `movq    32(%rbx), %rsi # sp[4] = second argument`,
    `movq    24(%rbx), %rdx # sp[3] = third argument`,
    `movq    16(%rbx), %rcx # sp[2] = fourth argument`,
    `movq    8(%rbx), %r8 # sp[1] = fifth argument`,
    `movq    (%rbx), %rax`,
    `subq    $8, %rsp # Align rsp to 16 bytes`,
    `call    *%rax`,
    `addq    $8, %rsp`,
    `addq    $40, %rbx`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
};

primitives.ccall6 = {
  name: 'CCALL6',
  x86_64: [
    `movq    48(%rbx), %rdi # sp[6] = first argument`,
    `movq    40(%rbx), %rsi # sp[5] = second argument`,
    `movq    32(%rbx), %rdx # sp[4] = third argument`,
    `movq    24(%rbx), %rcx # sp[3] = fourth argument`,
    `movq    16(%rbx), %r8  # sp[2] = fifth argument`,
    `movq    8(%rbx),  %r9  # sp[1] = sixth argument`,
    `movq    (%rbx), %rax`,
    `subq    $8, %rsp # Align rsp to 16 bytes`,
    `call    *%rax`,
    `addq    $8, %rsp`,
    `addq    $48, %rbx`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
};

primitives.c_lib_loader = {
  name: 'c_lib_loader',
  forthName: '(C-LIBRARY)',
  x86_64: [
    // Expects a null-terminated C-style string on the stack, and dlopen()s
    // it, globally, so a generic dlsym() for it will work.
    `movq    (%rbx), %rdi`,
    `movq    $258, %rsi`, // That's RTLD_NOW | RTLD_GLOBAL.
    `subq    $8, %rsp`, // Align rsp to 16 bytes
    `call    dlopen@PLT`,
    `addq    $8, %rsp`,
    `movq    %rax, (%rbx)`, // Push the result. NULL = 0 indicates an error.
    // That's a negated Forth flag.
    md.next(),
  ],
};

primitives.c_symbol = {
  name: 'c_symbol',
  forthName: '(C-SYMBOL)',
  x86_64: [
    // Expects the C-style null-terminated string on the stack, and dlsym()s
    // it, returning the resulting pointer on the stack.
    `movq   (%rbx), %rsi`,
    `movq   $0, %rdi      # 0 = RTLD_DEFAULT, searching everywhere.`,
    `subq   $8, %rsp # Align rsp to 16 bytes`,
    `call   dlsym@PLT`,
    `addq   $8, %rsp`,
    `movq   %rax, (%rbx)  # Put the void* result onto the stack.`,
    md.next(),
  ],
};

module.exports = primitives;

