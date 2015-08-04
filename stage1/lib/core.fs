1024 1024 4 * * (allocate) (>here) !

: IMMEDIATE (LATEST) (/CELL) +   dup @ 512 or   swap ! ;

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

: 2! ( x1 x2 a-addr -- ) dup >r   !   r> cell+ ! ;
: 2@ ( a-addr -- x1 x2 ) dup cell+ @ swap @ ;
: 2* ( x -- x ) 1 LSHIFT ;
: 2/ ( x -- x ) 2 / ;

: > ( a b -- ? ) swap < ;
: <= ( a b -- ? ) 2dup = -rot   < or ;
: >= ( a b -- ? ) swap <= ;

: 0> 0 > ;
: 0<= 0 <= ;
: 0>= 0 >= ;

: NEGATE ( n -- n ) 0 swap - ;

: INVERT -1 xor ;
: NOT invert ;

: +! ( delta a-addr -- )
  dup @ ( delta a-addr value )
  rot + ( a-addr value' )
  swap !
;
: -! >r negate r> +! ;


: COUNT ( c-addr -- c-addr u ) dup c@ swap 1+ swap ;

: /MOD ( a b -- r q ) 2dup mod -rot / ;

\ TODO These are lame, non-double-cell versions.
: */ ( n1 n2 n3 -- quotient ) >r * r> / ;
: */MOD ( n1 n2 n3 -- remainder quotient ) >r * r> /MOD ;


: HERE (>HERE) @ ;

: , HERE !   1 cells (>HERE) +! ;
: COMPILE, , ;

\ Unsafe ['], to be replaced below with a version using IF.
: ['] parse-name (find) drop compile, ; IMMEDIATE


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
: [CHAR] char ['] (lit) compile, , ; IMMEDIATE


: SPACE bl emit ;
: SPACES ( n -- ) BEGIN space 1- dup 0= UNTIL drop ;

: TYPE ( c-addr u -- )
  BEGIN dup 0> WHILE
    1- swap
    dup c@ emit
    char+ swap
  REPEAT
  2drop
;

: ." postpone S" ['] type compile, ; IMMEDIATE


\ Runs during the execution of eg. CONSTANT. The CREATEd word is newly made, and
\ I've got the here-value from DOES> below on the stack.
\ I need to compile a jump to that address into eg. CONSTANT.
: (DOES>) ( target -- )
  (latest) >body 2 cells + ( target addr )
  ['] (branch) over !      ( target addr )
  cell+ 2dup -             ( target addr' delta )
  swap !   drop ( )
;

\ DOES> itself. compiles a literal, a call to (does>), and EXIT into the
\ defining word (eg. CONSTANT). The literal is the address after the EXIT, ie.
\ where the code after DOES> is about to go.
: DOES> here 4 cells +   ['] (lit) compile, , ['] (does>) compile, [']
exit compile, ; IMMEDIATE

: VARIABLE CREATE 0 , ;
: CONSTANT CREATE , DOES> @ ;
: ARRAY ( length --   exec: index -- a-addr ) create cells allot DOES> cells + ;


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
  ['] (lit) compile, 1 , ['] (0branch) compile,
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

: +LOOP ( step --    C: old-jump-addr )
  \ Compute the point where the end of the loop will be.
  \ 9 cells after this point.
  ['] R> compile,  ['] + compile, ( index' ) ['] R> compile, ( index' limit )
  ['] 2dup compile, ['] >R dup compile, compile,
  ['] = compile, ['] (0branch) compile,
  (loop-top) @ cell+   here - ,

  \ End of the loop, start of the postlude ( C: -- )
  here ( C: old-jump-addr end-addr )
  (loop-top) @ ( C: old-jump-addr end-addr target )
  2dup -       ( C: old-jump-addr end-addr target delta )
  swap !       ( C: old-jump-addr end-addr )
  drop (loop-top) ! ( C: -- )
  ['] R> dup compile, compile, ['] 2drop compile,  ( )
; IMMEDIATE

: LOOP ( --   C: jump-addr ) ['] (lit) compile, 1 , POSTPONE +LOOP ; IMMEDIATE

: LEAVE ( -- ) ( R: loop-details -- ) ( C: -- )
  (loop-top) @ 1 cells -
  ['] (lit) compile, 0 , \ Force a branch.
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


: MOVE> ( a1 a2 u -- ) 0 DO over i + c@   over i + c! LOOP 2drop ;
: MOVE< ( a1 a2 u -- ) 1- -1 swap DO over i + c@   over i + c! -1 +LOOP 2drop ;
: MOVE ( a1 a2 u -- ) >R 2dup <   R> swap   IF MOVE< ELSE MOVE> THEN ;

: ABORT" postpone IF postpone ." ['] ABORT compile, postpone THEN ; IMMEDIATE


\ Unimplemented pictured output: # #> #S <# HOLD SIGN
\ Unimplemented: ACCEPT ENVIRONMENT? KEY
\ Unimplemented: FM/MOD UM/MOD SM/REM
\ Unimplemented: M* UM* S>D

