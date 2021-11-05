module.exports = [];

function superinstruction(spec) {
  module.exports.push(spec);
}

superinstruction({
  parts: ['from_r', 'from_r'],
  x86_64: [
    `subq	$16, %rbx`,
    `movq	rsp(%rip), %rcx`,
    `movq	(%rcx), %rax`,
    `movq	%rax, 8(%rbx)`,
    `movq	8(%rcx), %rax`,
    `movq	%rax, (%rbx)`,
    `addq	$16, rsp(%rip)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['fetch', 'EXIT'],
  x86_64: [
    `movq	(%rbx), %rax`,
    `movq	(%rax), %rax`,
    `movq	%rax, (%rbx)`,
    md.exitNext(),
  ],
});

superinstruction({
  parts: ['SWAP', 'to_r'],
  x86_64: [
    `movq    8(%rbx), %rax`,
    md.pushrsp('%rax', '%rcx'),
    `movq    (%rbx), %rax`,
    `movq    %rax, 8(%rbx)`,
    `addq    $8, %rbx`,
    md.next(),
  ],
});

superinstruction({
  parts: ['to_r', 'SWAP'],
  x86_64: [
    `movq	rsp(%rip), %rax`,
    `subq	$8, %rax`,
    `movq	%rax, rsp(%rip)`,
    `movq	(%rbx), %rdx`,
    `movq	%rdx, (%rax)`,
    `addq    $8, %rbx`,
    `movq    (%rbx), %rax`,
    `movq    8(%rbx), %rdx`,
    `movq    %rax, 8(%rbx)`,
    `movq    %rdx, (%rbx)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['to_r', 'EXIT'],
  x86_64: [
    `movq	(%rbx), %rax`,
    `addq    $8, %rbx`,
    `movq	%rax, %rbp`,
    md.next(),
  ],
});

superinstruction({
  parts: ['from_r', 'DUP'],
  x86_64: [
    md.poprsp('%rax'),
    `subq	$16, %rbx`,
    `movq    %rax, (%rbx)`,
    `movq    %rax, 8(%rbx)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['dolit', 'equal'],
  x86_64: [
    `movq    (%rbp), %rax`,
    `addq    $8, %rbp`,
    `movq    (%rbx), %rcx`,
    `cmpq	%rcx, %rax`,
    `jne	.L347`,
    `movq	$-1, %rdx`,
    `jmp	.L348`,
    `.L347:`,
    `movl	$0, %edx`,
    `.L348:`,
    `movq	%rdx, (%rbx)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['dolit', 'fetch'],
  x86_64: [
    `movq    (%rbp), %rax`,
    `addq    $8, %rbp`,
    `movq	(%rax), %rax`,
    `subq    $8, %rbx`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['DUP', 'to_r'],
  x86_64: [
    `movq    (%rbx), %rax`,
    md.pushrsp('%rax', '%rcx'),
    md.next(),
  ],
});

superinstruction({
  parts: ['dolit', 'dolit'],
  x86_64: [
    `subq	$16, %rbx`,
    `movq    (%rbp), %rax`,
    `movq    %rax, 8(%rbx)`,
    `movq    8(%rbp), %rax`,
    `movq    %rax, (%rbx)`,
    `addq    $16, %rbp`,
    md.next(),
  ],
});

superinstruction({
  parts: ['plus', 'EXIT'],
  x86_64: [
    `movq    (%rbx), %rax`,
    `addq    $8, %rbx`,
    `addq    %rax, (%rbx)`,
    md.exitNext(),
  ],
});

superinstruction({
  parts: ['dolit', 'plus'],
  x86_64: [
    `movq    (%rbp), %rax`,
    `addq    $8, %rbp`,
    `addq	%rax, (%rbx)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['dolit', 'less_than'],
  x86_64: [
    `movq    (%rbx), %rsi`,
    `movq    (%rbp), %rax`,
    `addq    $8, %rbp`,
    `cmpq	%rax, %rsi  # TOS -> %rsi, lit -> %rax`,
    `jge	.L355`,
    `movq	$-1, %rax`,
    `jmp	.L356`,
    `.L355:`,
    `movl	$0, %eax`,
    `.L356:`,
    `movq	%rax, (%rbx)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['plus', 'fetch'],
  x86_64: [
    `movq    (%rbx), %rax`,
    `addq    $8, %rbx`,
    `addq    (%rbx), %rax`,
    `movq    (%rax), %rax`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['to_r', 'to_r'],
  x86_64: [
    `movq    (%rbx), %rax`,
    md.pushrsp('%rax', '%rcx'),
    `movq    8(%rbx), %rax`,
    md.pushrsp('%rax', '%rcx'),
    `addq    $16, %rbx`,
    md.next(),
  ],
});

superinstruction({
  parts: ['dolit', 'call_'],
  x86_64: [
    `subq	$8, %rbx`,
    `movq    (%rbp), %rax`,
    `movq    %rax, (%rbx)`,
    `movq    8(%rbp), %rax`,
    `movq    %rax, ca(%rip)`,
    `addq    $16, %rbp`,
    md.pushrsp('%rbp', '%rcx'),
    `movq    %rax, %rbp`,
    md.next(),
  ],
});

superinstruction({
  parts: ['equal', 'EXIT'],
  x86_64: [
    `movq    (%rbx), %rax`,
    `addq    $8, %rbx`,
    `movq    (%rbx), %rcx`,
    `cmpq	%rax, %rcx`,
    `jne	.L361`,
    `movq	$-1, %rax`,
    `jmp	.L362`,
    `.L361:`,
    `movl	$0, %eax`,
    `.L362:`,
    `movq	%rax, (%rbx)`,
    md.exitNext(),
  ],
});

superinstruction({
  parts: ['to_r', 'SWAP', 'from_r'],
  x86_64: [
    // Swapping 8 and 16 slots
    `movq    8(%rbx), %rax`,
    `movq    16(%rbx), %rcx`,
    `movq    %rcx, 8(%rbx)`,
    `movq    %rax, 16(%rbx)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['SWAP', 'to_r', 'EXIT'],
  x86_64: [
    `movq    (%rbx), %rax`,
    `movq    8(%rbx), %rcx`,
    `movq    %rax, 8(%rbx)`,
    md.pushrsp('%rcx', '%rax'),
    `addq    $8, %rbx`,
    md.exitNext(),
  ],
});

superinstruction({
  parts: ['from_r', 'from_r', 'DUP'],
  x86_64: [
    `subq    $24, %rbx`,
    md.poprsp('%rax'),
    `movq    %rax, 16(%rbx)`,
    md.poprsp('%rax'),
    `movq    %rax, 8(%rbx)`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['DUP', 'to_r', 'SWAP'],
  x86_64: [
    `movq    (%rbx), %rax`,
    md.pushrsp('%rax', '%rcx'),
    `movq    (%rbx), %rax`,
    `movq    8(%rbx), %rcx`,
    `movq    %rax, 8(%rbx)`,
    `movq    %rcx, (%rbx)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['from_r', 'DUP', 'to_r'],
  x86_64: [
    `movq	rsp(%rip), %rax`,
    `movq	(%rax), %rax`,
    `subq    $8, %rbx`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['dolit', 'fetch', 'EXIT'],
  x86_64: [
    `movq    (%rbp), %rax`,
    `movq    (%rax), %rax`,
    `subq    $8, %rbx`,
    `movq    %rax, (%rbx)`,
    `addq    $8, %rbp`,
    md.exitNext(),
  ],
});

superinstruction({
  parts: ['dolit', 'plus', 'EXIT'],
  x86_64: [
    `movq    (%rbp), %rax`,
    `addq    $8, %rbp`,
    `addq	%rax, (%rbx)`,
    md.exitNext(),
  ],
});

superinstruction({
  parts: ['dolit', 'less_than', 'EXIT'],
  x86_64: [
    `movq    (%rbp), %rax`,
    `movq	(%rbx), %rdx`,
    `cmpq	%rax, %rdx`,
    `jge	.L371`,
    `movq	$-1, %rax`,
    `jmp	.L372`,
    `.L371:`,
    `movl	$0, %eax`,
    `.L372:`,
    `movq	%rax, (%rbx)`,
    `addq    $8, %rbp`,
    md.exitNext(),
  ],
});

superinstruction({
  parts: ['dolit', 'dolit', 'plus'],
  x86_64: [
    `movq    (%rbp), %rax`,
    `addq    8(%rbp), %rax`,
    `subq    $8, %rbx`,
    `movq    %rax, (%rbx)`,
    `addq    $16, %rbp`,
    md.next(),
  ],
});

superinstruction({
  parts: ['CELLS', 'sp_fetch', 'plus'],
  x86_64: [
    `movq    (%rbx), %rax`,
    `leaq    0(,%rax,8), %rax`,
    `addq    %rbx, %rax`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['to_r', 'SWAP', 'to_r'],
  x86_64: [
    `movq    (%rbx), %rax`,
    md.pushrsp('%rax', '%rcx'),
    `movq    16(%rbx), %rax`,
    md.pushrsp('%rax', '%rcx'),
    `movq    8(%rbx), %rax`,
    `movq    %rax, 16(%rbx)`,
    `addq    $16, %rbx`,
    md.next(),
  ],
});

superinstruction({
  parts: ['dolit', 'equal', 'EXIT'],
  x86_64: [
    `movq    (%rbx), %rax`,
    `movq    (%rbp), %rcx`,
    `addq    $8, %rbp`,
    `cmpq	%rax, %rcx`,
    `jne	.L377`,
    `movq	$-1, %rax`,
    `jmp	.L378`,
    `.L377:`,
    `movl	$0, %eax`,
    `.L378:`,
    `movq	%rax, (%rbx)`,
    md.exitNext(),
  ],
});

superinstruction({
  parts: ['sp_fetch', 'plus', 'fetch'],
  x86_64: [
    `movq    (%rbx), %rax`,
    `addq    %rbx, %rax`,
    `movq    (%rax), %rax`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['plus', 'fetch', 'EXIT'],
  x86_64: [
    `movq    (%rbx), %rax`,
    `addq    8(%rbx), %rax`,
    `movq    (%rax), %rax`,
    `addq    $8, %rbx`,
    `movq    %rax, (%rbx)`,
    md.exitNext(),
  ],
});

superinstruction({
  parts: ['from_r', 'from_r', 'two_dup'],
  x86_64: [
    `subq	$32, %rbx`,
    md.poprsp('%rax'),
    `movq    %rax, 24(%rbx)`,
    `movq    %rax, 8(%rbx)`,
    md.poprsp('%rax'),
    `movq    %rax, 16(%rbx)`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['neg_rot', 'plus', 'to_r'],
  x86_64: [
    // Bury, add the other two, and send to rsp.
    `movq    8(%rbx), %rax`,
    `addq    16(%rbx), %rax`,
    md.pushrsp('%rax', '%rcx'),
    `movq    (%rbx), %rax`,
    `addq    $16, %rbx`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['two_dup', 'minus', 'to_r'],
  x86_64: [
    `movq    (%rbx), %rax`,
    `movq    8(%rbx), %rcx`,
    `subq    %rax, %rcx    # Subtracting TOS from second`,
    md.pushrsp('%rcx', '%rax'),
    md.next(),
  ],
});

superinstruction({
  parts: ['to_r', 'SWAP', 'to_r', 'EXIT'],
  x86_64: [
    // This moves TOS to RSP, then third on stack to RSP, and then puts
    // second to third and pops two.
    `movq    (%rbx), %rax`,
    md.pushrsp('%rax', '%rcx'),
    `movq    16(%rbx), %rax`,
    md.pushrsp('%rax', '%rcx'),
    `movq    8(%rbx), %rax`,
    `addq    $16, %rbx`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['DUP', 'to_r', 'SWAP', 'to_r'],
  x86_64: [
    `movq    (%rbx), %rax`,
    md.pushrsp('%rax', '%rcx'),
    `movq    8(%rbx), %rdx`,
    md.pushrsp('%rdx', '%rcx'),
    `addq    $8, %rbx`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['from_r', 'DUP', 'to_r', 'SWAP'],
  x86_64: [
    // Actually reads TORS to NOS.
    `movq    (%rbx), %rax`,
    `subq    $8, %rbx`,
    `movq    %rax, (%rbx)`,
    `movq    rsp(%rip), %rax`,
    `movq    (%rax), %rax`,
    `movq    %rax, 8(%rbx)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['from_r', 'from_r', 'DUP', 'to_r'],
  x86_64: [
    `subq    $16, %rbx`,
    md.poprsp('%rax'),
    `movq    %rax, 8(%rbx)`,
    `movq    rsp(%rip), %rax`,
    `movq    (%rax), %rax`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['CELLS', 'sp_fetch', 'plus', 'fetch'],
  x86_64: [
    `movq    (%rbx), %rax`,
    `leaq    (,%rax,8), %rax`,
    `addq    %rbx, %rax`,
    `movq    (%rax), %rax`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['two_dup', 'minus', 'to_r', 'dolit'],
  x86_64: [
    `movq    (%rbx), %rax`,
    `movq    8(%rbx), %rcx`,
    `subq    %rax, %rcx`,
    md.pushrsp('%rcx', '%rax'),
    `subq    $8, %rbx`,
    `movq    (%rbp), %rax`,
    `movq    %rax, (%rbx)`,
    `addq    $8, %rbp`,
    md.next(),
  ],
});

superinstruction({
  parts: ['from_r', 'two_dup', 'minus', 'to_r'],
  x86_64: [
    `movq    (%rbx), %rax`,
    `movq    rsp(%rip), %rcx`,
    `subq    (%rcx), %rax`,
    `movq    %rax, (%rcx)`,
    md.next(),
  ],
});

superinstruction({
  parts: ['from_r', 'from_r', 'two_dup', 'minus'],
  x86_64: [
    `subq    $24, %rbx`,
    md.poprsp('%rax'),
    md.poprsp('%rcx'),
    `movq    %rax, 16(%rbx)`,
    `movq    %rcx, 8(%rbx)`,
    `subq    %rcx, %rax`,
    `movq    %rax, (%rbx)`,
    md.next(),
  ],
});


