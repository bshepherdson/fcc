\ Uses the machine-dependent macros (already loaded) to assemble a binary for
\ the target platform.

1 WORD: plus +
  0 1 pop2
  S"   addq   " ,asm   0 reg,  S" , " ,asm   1 reg,  asm-nl
  1 push
;WORD

2 WORD: minus -
  0 1 pop2
  S"   subq   " ,asm   1 reg,  S" , " ,asm   0 reg,  asm-nl
  0 push
;WORD

3 WORD: times *
  0 1 pop2
  S"   imulq  " ,asm   0 reg,  S" , " ,asm   1 reg,  asm-nl
  1 push
;WORD

\ Div and Udiv are special, because division varies wildly across architectures.
\ They basically get their own primitives to implement them.
4 WORD: div /
  div
;WORD

5 WORD: udiv U/
  udiv
;WORD
