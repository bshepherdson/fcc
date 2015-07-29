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

\ Unimplemented: # #> #S <#
\ Unimplemented: */ */MOD
\ Unimplemented: +LOOP
\ Unimplemented: ." /MOD
\ Unimplemented: ACCEPT
\ Unimplemented: BEGIN
\ Unimplemented: CHAR CONSTANT
\ Unimplemented: CREATE DECIMAL DO DOES>
\ Unimplemented: ELSE ENVIRONMENT?
\ Unimplemented: FILL
\ Unimplemented: FM/MOD HOLD I IF
\ Unimplemented: J KEY LEAVE
\ Unimplemented: LOOP M* MAX MIN
\ Unimplemented: MOVE
\ Unimplemented: REPEAT
\ Unimplemented: S>D SIGN SM/REM
\ Unimplemented: SPACE SPACES
\ Unimplemented: THEN TYPE
\ Unimplemented: UM* UM/MOD UNLOOP UNTIL VARIABLE WHILE
\ Unimplemented: ['] [CHAR]
