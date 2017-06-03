\ Uses the machine-dependent macros (already loaded) to assemble a binary for
\ the target platform.

: eng-binop ( xt -- ) >r   0 1 pop2   0 1 r> execute   0 push ;

1 WORD: plus +
  ' plus   eng-binop
;WORD

2 WORD: minus -
  ' minus   eng-binop
;WORD

3 WORD: times *
  ' times   eng-binop
;WORD

\ Div and Udiv are special, because division varies wildly across architectures.
\ They basically get their own primitives to implement them.
4 WORD: div /
  div
;WORD

5 WORD: udiv U/
  udiv
;WORD

6 WORD: mod MOD
  mod
;WORD

7 WORD: umod UMOD
  umod
;WORD

8 WORD: and AND
  ' op-and   eng-binop
;WORD

9 WORD: or OR
  ' op-or   eng-binop
;WORD

10 WORD: xor XOR
  ' op-xor   eng-binop
;WORD

\ x86_64 is dumb and can't handle wide operands for shifts.
\ So we let the machine-dependent engine handle shifts, like division.
11 WORD: lshift LSHIFT
  op-lshift
;WORD
12 WORD: rshift RSHIFT
  op-rshift
;WORD


13 WORD: base BASE
  0 S" base" ,*var
  0 push
;WORD

: conditional ( xt -- )
  >R
  0 1 pop2 \ Checking if r0 < r1.
  0 1 mklabel dup R> swap >R execute R> ( label-true )
  0 zero
  mklabel dup jmp ( label-true label-false )
  swap resolve   ( label-false )
  -1 0 -lit
  resolve ( )
  0 push
;

14 WORD: less_than <
  ' jlt   conditional
;WORD
15 WORD: less_than_unsigned U<
  ' jlt-unsigned   conditional
;WORD
16 WORD: equal =
  ' jeq   conditional
;WORD
