1024 1024 4 * * (allocate) (>here) !

: IMMEDIATE (LATEST) @ (/CELL) +   dup @ 512 or   swap ! ;

: ( 41 parse drop drop ; IMMEDIATE
: \ refill drop ; IMMEDIATE

: BL 32 ;

: 0< 0 < ;
: 0= 0 = ;
: 1+ 1 + ;
: 1- 1 - ;

: OVER ( a b -- a b a ) >R dup R> swap ;
: ROT ( a b c -- b c a ) >R swap R> swap ;
: -ROT ( a b c -- c a b ) swap >R swap R> ;

: 2DROP drop drop ;
: 2DUP over over ;
: 2SWAP ( a b c d -- c d a b )
  >R -rot ( c a b   R: d )
  R>      ( c a b d )
  -rot    ( c d a b )
;
: 2OVER ( a b c d -- a b c d a b ) >r >r 2dup r> r> ( a b a b c d ) 2swap ;

: CELLS (/CELL) * ;
: CELL+ ( a-addr -- a-addr ) 1 CELLS + ;
: CHARS (/CHAR) * ;
: CHAR+ 1 CHARS + ;

: INVERT -1 xor ;
: NOT 0= ;

: 2! ( x1 x2 a-addr -- ) dup >r   !   r> cell+ ! ;
: 2@ ( a-addr -- x1 x2 ) dup cell+ @ swap @ ;
: 2* ( x -- x ) 1 LSHIFT ;
: 2/ ( x -- x ) -1 1 rshift invert ( x msb ) over and   swap 1 rshift  or ;

: > ( a b -- ? ) swap < ;
: <= ( a b -- ? ) 2dup = -rot   < or ;
: >= ( a b -- ? ) swap <= ;

: 0> 0 > ;
: 0<= 0 <= ;
: 0>= 0 >= ;

: NEGATE ( n -- n ) 0 swap - ;

: +! ( delta a-addr -- )
  dup @ ( delta a-addr value )
  rot + ( a-addr value' )
  swap !
;
: -! >r negate r> +! ;


: COUNT ( c-addr -- c-addr u ) dup c@ swap 1+ swap ;

: /MOD ( a b -- r q ) 2dup mod -rot / ;

: ALLOT ( n -- ) (>HERE) +! ;
: HERE (>HERE) @ ;

: , ( x -- ) HERE !   1 cells (>HERE) +! ;
: COMPILE, ( xt -- ) , ;
: C, ( c -- ) here c!   1 chars (>HERE) +! ;

: ALIGNED ( addr - a-addr ) (/cell) 1-   dup >R   + R>   invert and ;
: ALIGN (>here) @ aligned (>here) ! ;

: [ 0 state ! ; IMMEDIATE
: ] 1 state ! ;

: R@ ( -- x ) ( R: x -- x ) R> R> dup >R swap >R ;

\ Unsafe ['], to be replaced below with a version using IF.
: ' ( "name" -- xt ) parse-name (find) drop ;
\ Compiles a literal into the current definition.
: LITERAL ( x -- ) ( RT: -- x ) [ ' (dolit) dup compile, , ] compile, , ;
: ['] ( "<spaces>name<space>" -- xt ) parse-name (find) drop literal ; IMMEDIATE


\ Control structures.
: IF ( ? --   C: -- jumploc ) ['] (0branch) compile,  HERE   0 , ; IMMEDIATE
: THEN ( C: jumploc -- ) here over - swap ! ; IMMEDIATE
: ELSE ( C: jumploc1 -- jumploc2 )
  ['] (branch) compile,
  here
  0 ,     ( ifloc endifloc )
  here    ( ifloc endifloc elseloc )
  rot     ( endifloc elseloc ifloc )
  dup >r - ( endifloc delta  R: ifloc )
  r> !     ( endifloc )
; IMMEDIATE

: BEGIN ( C: -- beginloc ) here ; IMMEDIATE
: WHILE ( ? -- C: -- whileloc ) ['] (0branch) compile, here 0 , ; IMMEDIATE
: REPEAT ( C: beginloc whileloc -- )
  \ First, write the unconditional jump to the begin.
  ['] (branch) compile, swap ( whileloc beginloc )
  here - , ( whileloc )
  \ Then fill in the end location for the whileloc
  here over - swap ! ( )
; IMMEDIATE
: UNTIL ( ? --   C: beginloc -- ) ['] (0branch) compile, here - , ; IMMEDIATE


: CHAR ( "<spaces>name" -- char ) parse-name drop c@ ;
: [CHAR] char LITERAL ; IMMEDIATE


: SPACE bl emit ;
: SPACES ( n -- ) dup 0<= IF EXIT THEN BEGIN space 1- dup 0= UNTIL drop ;

: TYPE ( c-addr u -- )
  BEGIN dup 0> WHILE
    1- swap
    dup c@ emit
    char+ swap
  REPEAT
  2drop
;

: POSTPONE ( "<spaces>name" -- ) parse-name (find) drop compile, ; IMMEDIATE

\ DOES> is tricky. It runs during compilation of a word like CONSTANT.
\ It compiles code into CONSTANT, which will write the HERE address of the
\ post-DOES> code into the first cell of the freshly CREATEd definition.
: DOES>
  ['] (dolit) compile, here 0 , ( xt-here )
  \ Now CONSTANT will have the do-address on the stack.
  \ It should store that in the first body cell of the CREATEd word.
  ['] (latest) compile,
  ['] @ compile,
  ['] (>does) compile,
  ['] ! ,
  ['] EXIT compile,
  here swap !
; IMMEDIATE

: VARIABLE CREATE 0 , ;
: CONSTANT CREATE , DOES> @ ;

: ARRAY ( length --   exec: index -- a-addr )
  create cells allot
  DOES> swap cells +
;


: HEX 16 base ! ;
: DECIMAL 10 base ! ;

\ DO ... LOOP design:
\ old value of (loop-top) is pushed onto the compile-time stack.
\ new value of the top of the loop is placed in (loop-top).
\ LEAVE can use that address.
\ DO compiles code to push the index and limit onto the runtime return stack.
\ It also compiles a 0branch and code to push a 1 before it, so it doesn't
\ branch on initial entry. LEAVE pushes a 0 before jumping, so it will branch.
\ +LOOP jumps to the location after that in (loop-top), and restores the old
\ value into (loop-top).

VARIABLE (loop-top)

: DO ( limit index --   C: old-jump-addr )
  ['] swap compile, ['] >r dup compile, compile,
  1 LITERAL   ['] (0branch) compile,
  (loop-top) @    here (loop-top) ! ( C: old-jump-addr )
  0 , \ Placeholder for the jump offset to go.
; IMMEDIATE

: I ( -- index ) ['] R@ compile, ; IMMEDIATE
: J ( -- index )
  R> R> R> R@ ( exit index1 limit1 index2 )
  -rot ( exit index2 index1 limit1 )
  >R >R ( exit index2 )
  swap >R ( index2 )
;

\ Implementation taken from the Forth 2012 appendix.
\ WITHIN is actually from CORE EXT, but it's useful here.
: WITHIN ( test lo hi -- ? ) over - >R   - R> U< ;

\ Called at the end of a +loop, with the delta.
\ Remember that the real return address is on the return stack.
: (LOOP-END) ( delta -- ?   R: limit index ret -- limit index' ret )
  R> SWAP ( ret delta )
  R> ( ret delta index )
  swap over + ( ret index index' )
  R> ( ret index index' limit )
  2dup >R >R ( ret index index' limit   R: limit index' )
  rot ( ret index' limit index   R: limit index' )
  2dup = >R  ( ret index' limit index   R: limit index' equal? )
  2dup < IF swap THEN
  within
  R> or
  swap >R ( ?   R: limit index' ret )
;


: +LOOP ( step --    C: old-jump-addr )
  \ Compute the point where the end of the loop will be.
  \ 9 cells after this point.
  ['] (LOOP-END) compile, ['] (0branch) compile,
  (loop-top) @ cell+   here - ,

  \ End of the loop, start of the postlude ( C: -- )
  here ( C: old-jump-addr end-addr )
  (loop-top) @ ( C: old-jump-addr end-addr target )
  2dup -       ( C: old-jump-addr end-addr target delta )
  swap !       ( C: old-jump-addr end-addr )
  drop (loop-top) ! ( C: -- )
  ['] R> dup compile, compile, ['] 2drop compile,  ( )
; IMMEDIATE

: LOOP ( --   C: jump-addr ) 1 LITERAL POSTPONE +LOOP ; IMMEDIATE

: LEAVE ( -- ) ( R: loop-details -- ) ( C: -- )
  (loop-top) @ 1 cells -
  0 LITERAL \ Force a branch
  ['] (branch) compile,
  here - ,
; IMMEDIATE

: UNLOOP ( -- ) ( R: limit index exit -- exit )
  R> ( exit )
  R> R> 2drop ( exit   R: -- )
  >R
;


: MIN ( a b -- min ) 2dup > IF swap THEN drop ;
: MAX ( a b -- max ) 2dup < IF swap THEN drop ;

: FILL ( c-addr u char -- )
  -rot ( char c-addr u )
  dup 0<= IF drop 2drop EXIT THEN
  0 DO ( char c-addr )
    2dup i + c! ( char c-addr )
  LOOP
  2drop
;


: MOVE> ( src dst u -- ) 0 DO over i + c@   over i + c! LOOP 2drop ;
: MOVE< ( src dst u -- ) 1- 0 swap DO over i + c@   over i + c! -1 +LOOP 2drop ;
: MOVE ( src dst u -- ) >R 2dup <   R> swap   IF MOVE< ELSE MOVE> THEN ;

: ABORT quit ;

: ['] ( "<spaces>name<space>" -- xt )
  parse-name (find)
  IF literal ELSE ABORT THEN
; IMMEDIATE

: S"
  [CHAR] " parse
  ['] (dostring) compile, dup c, ( c-addr u )
  here swap ( c-addr here u )
  dup >R
  move ( )
  R> allot
  align
; IMMEDIATE

: ." postpone S" ['] type compile, ; IMMEDIATE

: ABORT" postpone IF postpone ." ['] ABORT compile, postpone THEN ; IMMEDIATE

\ Turns a two-cell string into a counted string.
\ The new string is in a transient region!
: UNCOUNT ( c-addr u -- c-addr ) dup here c!   here 1+ swap move   here ;

: WORD ( char "<chars>ccc<char>" -- c-addr )
  BEGIN dup parse ( char c-addr u ) dup 0= WHILE 2drop REPEAT ( char c-addr u )
  uncount swap drop ( c-addr )
;

: FIND ( c-addr -- c-addr 0 | xt 1 | xt -1 )
  dup count (find) ( c-addr xt flag )
  dup 0= IF 2drop 0 ELSE rot drop THEN
;

: RECURSE (latest) @ (>CFA) compile, ; IMMEDIATE

: ABS ( n -- u ) dup 0< IF negate THEN ;

: ?DUP ( x -- 0 | x x ) dup IF dup THEN ;


\ Awkward double-cell calculations.
: (C+!) ( char c-addr -- )
  swap over ( a c a )
  C@ + ( a c')
  2dup 255 and swap c! ( a c' )
  8 rshift dup IF swap 1+ recurse ELSE 2drop THEN
;

HERE 3 cells allot CONSTANT (M*RES)
: UM* ( u1 u2 -- ud )
  \ First, write all 0s into the result buffer.
  2 cells 0 DO 0 (m*res) i + c! LOOP
  \ Then go through each input a byte at a time.
  1 cells 0 DO
    over i 8 * rshift 255 and ( n1 n2 b1 )
    0 ( n1 n2 b1 carry )
    1 cells 0 DO
      rot dup >r -rot r> ( n1 n2 b1 carry n2 )
      i 8 * rshift 255 and ( n1 n2 b1 carry b2 )
      rot dup >R ( n1 n2 carry b2 b1   R: b1 )
      * + ( n1 n2 res ) \ res is 16 bits. Need to write it in two parts.
      dup 255 and ( n1 n2 res lo   R: b1 )
      \ Can't have anything on the return stack and use I and J.
      R> -rot ( n1 n2 b1 res lo )
      i j + (m*res) + ( n1 n2 b1 res lo c-addr )
      (C+!) ( n1 n2 b1 res )
      8 rshift ( n1 n2 b1 carry )
    LOOP
    1 cells i + (m*res) + (C+!) ( n1 n2 b1 )
    drop ( n1 n2 )
  LOOP

  2drop \ Discard the inputs.

  \ Don't assume endianness of the host; load those values a byte at a time.
  0 1 cells 0 DO i (m*res) + c@   i 8 * lshift   + LOOP
  0 1 cells 0 DO i 1 cells +   (m*res) + c@   i 8 * lshift   + LOOP
;

\ Some helpers for working with halfsize integers.
1 cells 2 / (address-unit-bits) * CONSTANT (HALF-WIDTH)
0 invert (half-width) rshift CONSTANT (HALF-MASK)
: (HI) ( u -- uh ) (half-width) rshift   (half-mask) and ;
: (LO) ( u -- uh ) (half-mask) and ;

\ Hi on top, like a double-cell value.
: (half-split) ( u -- uh1 uh2 ) dup (lo) swap (hi) ;
: (half-join) ( uh1 uh2 -- u ) (half-width) lshift   or ;

VARIABLE (UM-A)
VARIABLE (UM-B)
VARIABLE (UM-L) \ Answer, low part.
\ High part is not needed to be stored.

\ Second attempt: Long multiplication on four half-cells.
: UM* ( u1 u2 -- ud )
  over (UM-A) !
  dup  (UM-B) ! ( u1 u2 )
  (lo) swap (lo) ( 2l 1l )
  * dup (lo) (UM-L) ! (hi) ( carry )

  (UM-A) @ (lo)
  (UM-B) @ (hi)
  * + ( full )
  (UM-A) @ (hi)
  (UM-B) @ (lo)
  * + ( full )
  dup (lo) (half-width) lshift (UM-L) @ + ( carry lo )
  swap (hi) ( lo carry )

  (UM-A) @ (hi)
  (UM-B) @ (hi)
  * + ( ans )
;


\ Invert and add 1, but in a double-cell way.
: DNEGATE ( d1 -- d2 )
  invert swap invert ( hi' lo' )
  1+ \ Now if that made the lo part 0, we need to carry.
  swap ( lo' hi' )
  over 0= IF 1+ THEN
;

: M* ( n1 n2 -- d )
  over 0< over 0< xor >R
  abs swap abs swap UM*
  R> IF dnegate THEN
;

\ Works in half-size parts.
: UM/MOD ( ud u1 -- u2-r u3-q )
  \ Chop up the dividend into 16-bit pieces.
  >R >R ( lo )
  (half-split) R> (half-split) ( ll lh hl hh   R: d )
  R@ /mod ( ll lh hl r q  R: d )
  \ This is the high part of the high part of the quotient; discard it.
  drop
  (half-join) R@ /mod ( ll lh r q ) \ Still high quotient, discard.
  drop
  (half-join) R@ /mod ( ll r qh  R: d )
  \ Juggle the high quotient part onto the return stack.
  R> swap >R ( ll r d   R: qh )
  >R (half-join) R> ( temp d   R: qh )
  /mod ( r ql  R: qh )
  R> (half-join) ( r q )
;

: (DIV-CORE) ( d n -- u u dividend-neg? divisor-neg? differ? )
  dup 0< ( d n divisor-neg? )
  dup >R IF negate THEN ( d u    R: divisor-neg? )
  >R ( d   R: divisor-neg? u )
  dup 0< ( d dividend-neg?   R: divisor-neg? u )
  dup >R IF dnegate THEN ( ud   R: divisor-neg? u dividend-neg? )
  R> R> swap >R ( ud u    R: divisor-neg? dividend-neg? )
  um/mod ( u u   R: divisor-neg? dividend-neg? )
  R> R>
  2dup xor
;

\ Symmetric division is the simpler one: the remainder carries the sign of the
\ dividend or is zero, and the quotient carries the main sign.
: SM/REM ( d n -- n n )
  (div-core) ( u u dividend-neg? divisor-neg? differ? )
  >R drop ( u u dividend-neg?    R: differ? )
  IF swap negate swap THEN ( n u   R: differ? )
  R> IF negate THEN ( n n )
;

\ Floored division is the weirder one, where the remainder has the sign of the
\ divisor (or is zero), while the quotient has the combined sign.
\ When the signs do differ, add 1 to the unsigned results before doing the
\ negation.
: FM/MOD ( d n -- n n )
  (div-core) ( u u dividend-neg? divisor-neg? differ? )
  -rot >R >R >R ( u u    R: divisor-neg? dividend-neg? differ? )
  R@ IF 1+ swap 1+ swap THEN ( u' u' R: divisor-neg? dividend-neg? differ? )
  R> IF negate THEN \ Negate the quotient when the signs differ.
  R> drop
  R> IF swap negate swap THEN \ Negate the remainder when the divisor is neg.
  ( n n )
;

\ These use symmetric division, SM/REM.
: */MOD ( n1 n2 n3 -- remainder quotient ) >r M* r> SM/REM ;
: */ ( n1 n2 n3 -- quotient ) */mod swap drop ;


\ Pictured numeric output. Uses HERE (which is not PAD).
VARIABLE (picout)
: (picout-top) here 256 chars + ;
: <# (picout-top) (picout) ! ;
: HOLD ( c -- ) (picout) @ 1- dup >R c!   R> (picout) ! ;
: SIGN ( n -- ) 0< IF [CHAR] - hold THEN ;
: # ( ud1 -- ud2 )
  base @ 2dup / >R ( ud1 base   R: hi-q )
  um/mod ( r lo-q   R: hi-q )
  swap dup 10 < IF [char] 0 ELSE 10 - [char] A THEN + HOLD ( lo-q   R: hi-q )
  R> ( dq )
;
: #S
  2dup or 0= IF [char] 0 emit EXIT THEN \ Special case for 0.
  BEGIN 2dup or WHILE # REPEAT
;
: #> 2drop (picout) @ (picout-top) over - ( c-addr len ) ;

: S>D ( n -- d ) dup 0< IF -1 ELSE 0 THEN ;

: (#UHOLD) <# 0 #S #> ;
: U. (#UHOLD) type space ;

\ Helper for picturing signed numbers.
: (#HOLD) ( n -- c-addr len ) <# dup abs S>D #S rot sign #> ;
: .  (#HOLD) type space ;

\ Helper that compares strings. From the STRING word list.
: COMPARE ( c-addr1 u1 c-addr2 u2 -- n )
  rot 2dup = >R 2dup > >R    min   ( c1 c2 min   R: same? 1smaller? )
  0 DO ( c1 c2 )
    over i + c@   over i + c@ ( c1 c2 b1 b2 )
    2dup = not IF
      > >R 2drop R>
      IF 1 ELSE -1 THEN
      UNLOOP R> R> 2drop EXIT
    THEN
    2drop
  LOOP
  2drop ( R: same? 1smaller? )
  R> R> ( 1smaller? same? )
  IF drop 0 ELSE IF -1 ELSE 1 THEN THEN
;

: ENVIRONMENT? ( c-addr u -- i*x true | false )
  2dup S" /COUNTED-STRING" compare 0= IF 2drop 255 -1 EXIT THEN
  2dup S" /HOLD"           compare 0= IF 2drop 256 -1 EXIT THEN
  2dup S" /PAD"            compare 0= IF 2drop 1024 -1 EXIT THEN
  2dup S" ADDRESS-UNIT-BITS" compare 0= IF
      2drop (address-unit-bits) -1 EXIT THEN
  2dup S" FLOORED" compare 0= IF 2drop 0 -1 EXIT THEN
  2dup S" MAX-CHAR" compare 0= IF 2drop 255 -1 EXIT THEN
  2dup S" MAX-D" compare 0= IF 2drop -1 -1 1 rshift  -1 EXIT THEN
  2dup S" MAX-N" compare 0= IF 2drop -1 1 rshift   -1 EXIT THEN
  2dup S" MAX-U" compare 0= IF 2drop -1 -1 EXIT THEN
  2dup S" MAX-UD" compare 0= IF 2drop -1 -1 -1 EXIT THEN
  2dup S" RETURN-STACK-CELLS" compare 0= IF
      2drop (return-stack-cells) -1 EXIT THEN
  2dup S" STACK-CELLS" compare 0= IF 2drop (stack-cells) -1 EXIT THEN
  2drop 0
;

