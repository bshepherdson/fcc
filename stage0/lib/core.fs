: ( 41 parse drop drop ; IMMEDIATE
: \ refill drop ; IMMEDIATE

: BL 32 ;

: 0< 0 < ;
: 0= 0 = ;
: 1+ 1 + ;
: 1- 1 - ;

: -ROT ( a b c -- c a b ) rot rot ;
: 2DROP drop drop ;
: 2DUP over over ;
: 2SWAP ( a b c d -- c d a b )
  >R -rot ( c a b   R: d )
  R>      ( c a b d )
  -rot    ( c d a b )
;
: 2OVER ( a b c d -- a b c d a b ) >r >r 2dup r> r> ( a b a b c d ) 2swap ;

: CELL+ ( a-addr -- a-addr ) 1 CELLS + ;

: 2! ( x1 x2 a-addr -- ) dup >r   !   r> cell+ ! ;
: 2@ ( a-addr -- x1 x2 ) dup cell+ @ swap @ ;
: 2* ( x -- x ) 1 LSHIFT ;
: 2/ ( x -- x ) 2 / ;

: > ( a b -- ? ) swap < ;
: <= ( a b -- ? ) 2dup = -rot   < and ;
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


: CHARS ( n -- n ) ;
: CHAR+ 1 chars + ;

: COUNT ( c-addr -- c-addr u ) dup c@ swap 1+ swap ;

: /MOD ( a b -- r q ) 2dup mod -rot / ;

\ TODO These are lame, non-double-cell versions.
: */ ( n1 n2 n3 -- quotient ) >r * r> / ;
: */MOD ( n1 n2 n3 -- remainder quotient ) >r * r> /MOD ;


\ Control structures.
: IF ( ? --   C: -- jumploc ) ['] (0branch) ,  HERE   0 , ; IMMEDIATE
: THEN ( C: jumploc -- ) here over - swap ! ; IMMEDIATE
: ELSE ( C: jumploc1 -- jumploc2 )
  ['] (branch) ,
  here
  0 ,     ( ifloc endifloc )
  here    ( ifloc endifloc elseloc )
  rot     ( endifloc elseloc ifloc )
  dup >r - ( endifloc delta  R: ifloc )
  r> !     ( endifloc )
; IMMEDIATE

: BEGIN ( C: -- beginloc ) here ; IMMEDIATE
: WHILE ( ? -- C: -- whileloc ) ['] (0branch) , here 0 , ; IMMEDIATE
: REPEAT ( C: beginloc whileloc -- )
  \ First, write the unconditional jump to the begin.
  ['] (branch) , swap ( whileloc beginloc )
  here - , ( whileloc )
  \ Then fill in the end location for the whileloc
  here over - swap ! ( )
; IMMEDIATE
: UNTIL ( ? --   C: beginloc -- ) ['] (0branch) , here - , ; IMMEDIATE


: CHAR ( "<spaces>name" -- char ) parse-name drop c@ ;
: [CHAR] char ['] (lit) , , ; IMMEDIATE


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

: ." postpone S" ['] type , ; IMMEDIATE

\ When DOES> is called, there are three layers of nested compilation.
\ DOES> is immediate, running during compilation of a word like CONSTANT.
\ It compiles things into the definition of eg. CONSTANT, which will themselves
\ compile interesting things into the words created by eg. CONSTANT.
\ : DOES>
\   here 16 cells + ( target )
\   ['] (latest) ,
\   ['] >body ,
\   ['] cell+ ,
\   ['] cell+ ,
\   ['] (lit) ,
\   ['] (branch) ,
\   ['] over ,
\   ['] ! ,
\   ['] (lit) ,
\   , \ Compile the HERE value computed at the beginning
\   ['] here ,
\   ['] - ,
\   ['] swap ,
\   ['] cell+ ,
\   ['] ! ,
\   ['] exit ,
\ 
\   \ Now we're aimed after the above exit, after the real end of eg. CONSTANT.
\   \ This is where the code after the DOES> will be compiled, and where we just
\   \ added a branch to the CREATEd word to jump to. It has no more EXIT.
\ ; IMMEDIATE

\ Runs during the execution of eg. CONSTANT. The CREATEd word is newly made, and
\ I've got the here-value from DOES> below on the stack.
\ I need to compile a jump to that address into eg. CONSTANT.
: (DOES>) ( target -- )
  (latest) >body 2 cells + ( target addr )
  ['] (branch) over !      ( target addr )
  cell+                    ( target addr' )
  here rot - ( addr delta )
  swap !
;
: DOES> here 4 cells +   ['] (lit) , , ['] (does>) , ['] exit , ; IMMEDIATE

: VARIABLE CREATE 0 , ;
: CONSTANT CREATE 0 , DOES> @ ;

\ Unimplemented: # #> #S <#
\ Unimplemented: +LOOP
\ Unimplemented: ACCEPT
\ Unimplemented: CONSTANT
\ Unimplemented: CREATE DECIMAL DO DOES>
\ Unimplemented: ENVIRONMENT?
\ Unimplemented: FILL
\ Unimplemented: FM/MOD HOLD I
\ Unimplemented: J KEY LEAVE
\ Unimplemented: LOOP M* MAX MIN
\ Unimplemented: MOVE
\ Unimplemented: S>D SIGN SM/REM
\ Unimplemented: TYPE
\ Unimplemented: UM* UM/MOD UNLOOP VARIABLE
