: ( 41 parse drop drop ; IMMEDIATE
: \ refill ; IMMEDIATE

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

\ Unimplemented: # #> #S
\ Unimplemented: ( */ */MOD
\ Unimplemented: +! +LOOP
\ Unimplemented: ." /MOD
\ Unimplemented: 0< 0= 1+ 1- 2! 2* 2/ 2@ 2DROP 2DUP 2OVER 2SWAP
\ Unimplemented: <# >
\ Unimplemented: ACCEPT
\ Unimplemented: ALLOT
\ Unimplemented: BEGIN, BL
\ Unimplemented: CELL+ CHAR CHAR+ CHARS CONSTANT COUNT
\ Unimplemented: CREATE DECIMAL DO DOES>
\ Unimplemented: ELSE ENVIRONMENT?
\ Unimplemented: FILL
\ Unimplemented: FM/MOD HOLD I IF
\ Unimplemented: J KEY LEAVE
\ Unimplemented: LOOP M* MAX MIN
\ Unimplemented: MOVE NEGATE
\ Unimplemented: REPEAT
\ Unimplemented: S>D SIGN SM/REM
\ Unimplemented: SPACE SPACES
\ Unimplemented: THEN TYPE
\ Unimplemented: UM* UM/MOD UNLOOP UNTIL VARIABLE WHILE
\ Unimplemented: ['] [CHAR]
