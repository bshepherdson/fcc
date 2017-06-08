\ Uses the machine-dependent macros (already loaded) to assemble a binary for
\ the target platform.

: eng-binop ( xt -- ) >r   1 0 pop2   1 0 r> execute   0 push ;

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


\ Stack manopulation.
17 WORD: dup DUP    0 peek   0 push   ;WORD
\ TODO Make these more efficient.
18 WORD: swap SWAP  0 1 pop2   1 push   0 push ;WORD
19 WORD: drop DROP  1 sp+ ;WORD
20 WORD: over OVER  0 1 peek-at   0 push ;WORD

21 WORD: rot ROT
  0 pop  1 pop   2 pop   ( 2 1 0 -- 1 0 2 )
  1 push   0 push   2 push
;WORD

22 WORD: neg_rot -ROT
  0 pop  1 pop   2 pop   ( 2 1 0 -- 0 2 1 )
  0 push 2 push  1 push
;WORD

23 WORD: two_drop 2DROP   2 sp+ ;WORD

24 WORD: two_dup 2DUP
  0 1 peek-at   1 peek
  0 push   1 push
;WORD


\ Skipped: 2SWAP 25
\ Skipped: 2OVER 26

27 WORD: to_r >R   0 pop   0 pushrsp ;WORD
28 WORD: from_r R>   0 poprsp   0 push ;WORD


\ Memory
29 WORD: fetch @   0 peek   0 0 read   0 peek! ;WORD
30 WORD: store !   0 1 pop2   0 1 write ;WORD

31 WORD: cfetch C@  0 peek  0 0 cread  0 peek! ;WORD
32 WORD: cstore C!  0 1 pop2  0 1 cwrite ;WORD

118 WORD: two_fetch 2@
  0 pop
  1 0 1 read-indexed
  2 0   read
  2 push
  1 push
;WORD

119 WORD: two_store 2!
  2 pop   \ Pointer
  0 1 pop2
  1 2 write
  0 2 1 write-indexed
;WORD

33 WORD: raw_alloc (ALLOCATE)
  1 args
  0 pop-arg
  S" malloc" call
  0 push
;WORD

34 WORD: here_ptr (>HERE)   0 S" dsp" ,*var   0 push ;WORD
\ Skipped (PRINT) 35

36 WORD: state STATE   0 S" state" ,*var   0 push ;WORD

37 WORD: branch  (BRANCH)    op-branch  ;WORD
38 WORD: zbranch (0BRANCH)   op-zbranch ;WORD

39 WORD: execute EXECUTE
  0 pop
  1 S" cfa" ,*var
  0 1 write
  0 0 read
  1 S" ca" ,*var
  0 1 write
;WORD-RAW


40 WORD: evaluate EVALUATE
  0 input-index++
  0 pop   \ Length
  2 input-source
  0  2   src-length write-indexed
  0  pop  \ String
  0  2   src-buffer write-indexed
  -1 0   -lit   \ Type = EVALUATE
  0  2   src-type write-indexed
  0  0   lit    \ Index into buffer
  0  2   src-index write-indexed
  pushrsp-ip
  eval-jmp  \ This is a unique instruction, so it's directly written.
;WORD-RAW


\ START HERE: refill_
S" refill_:" ,asm-l
2 input-source
0 2 src-type   read-indexed
src-type

\ START HERE. Keep wrangling refill.

