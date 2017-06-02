\ Uses the machine-dependent macros (already loaded) to assemble a binary for
\ the target platform.

1 S" plus" WORD: emit
  0 1 pop2
  S" addq   " ,asm   0 reg,  S" , " ,asm   1 reg,  asm-nl
  1 push
;WORD


