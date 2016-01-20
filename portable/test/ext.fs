\ CORE EXT tests

\ :NONAME
VARIABLE nn1
VARIABLE nn2
T{ :NONAME 1234 ; nn1 ! -> }T
T{ :NONAME 9876 ; nn2 ! -> }T
T{ nn1 @ EXECUTE -> 1234 }T
T{ nn2 @ EXECUTE -> 9876 }T


\ ?DUP
DECIMAL
: qd ?DO I LOOP ;
T{   789   789 qd -> }T
T{ -9876 -9876 qd -> }T
T{     5     0 qd -> 0 1 2 3 4 }T

: qd1 ?DO I 10 +LOOP ;
T{ 50 1 qd1 -> 1 11 21 31 41 }T
T{ 50 0 qd1 -> 0 10 20 30 40 }T

: qd2 ?DO I 3 > IF LEAVE ELSE I THEN LOOP ;
T{ 5 -1 qd2 -> -1 0 1 2 3 }T

: qd3 ?DO I 1 +LOOP ;
T{ 4  4 qd3 -> }T
T{ 4  1 qd3 ->  1 2 3 }T
T{ 2 -1 qd3 -> -1 0 1 }T

: qd4 ?DO I -1 +LOOP ;
T{  4 4 qd4 -> }T
T{  1 4 qd4 -> 4 3 2  1 }T
T{ -1 2 qd4 -> 2 1 0 -1 }T

: qd5 ?DO I -10 +LOOP ;
T{   1 50 qd5 -> 50 40 30 20 10   }T
T{   0 50 qd5 -> 50 40 30 20 10 0 }T
T{ -25 10 qd5 -> 10 0 -10 -20     }T

VARIABLE qditerations
VARIABLE qdincrement

: qd6 ( limit start increment -- )    qdincrement !
   0 qditerations !
   ?DO
     1 qditerations +!
     I
     qditerations @ 6 = IF LEAVE THEN
     qdincrement @
   +LOOP qditerations @
;

T{  4  4 -1 qd6 ->                   0  }T
T{  1  4 -1 qd6 ->  4  3  2  1       4  }T
T{  4  1 -1 qd6 ->  1  0 -1 -2 -3 -4 6  }T
T{  4  1  0 qd6 ->  1  1  1  1  1  1 6  }T
T{  0  0  0 qd6 ->                   0  }T
T{  1  4  0 qd6 ->  4  4  4  4  4  4 6  }T
T{  1  4  1 qd6 ->  4  5  6  7  8  9 6  }T
T{  4  1  1 qd6 ->  1  2  3          3  }T
T{  4  4  1 qd6 ->                   0  }T
T{  2 -1 -1 qd6 -> -1 -2 -3 -4 -5 -6 6  }T
T{ -1  2 -1 qd6 ->  2  1  0 -1       4  }T
T{  2 -1  0 qd6 -> -1 -1 -1 -1 -1 -1 6  }T
T{ -1  2  0 qd6 ->  2  2  2  2  2  2 6  }T
T{ -1  2  1 qd6 ->  2  3  4  5  6  7 6  }T
T{  2 -1  1 qd6 -> -1  0  1          3  }T
HEX

\ ACTION-OF
T{ DEFER defer1 -> }T
T{ : action-defer1 ACTION-OF defer1 ; -> }T
T{ ' * ' defer1 DEFER! ->   }T
T{          2 3 defer1 -> 6 }T
T{ ACTION-OF defer1 -> ' * }T
T{    action-defer1 -> ' * }T

T{ ' + IS defer1 ->   }T
T{    1 2 defer1 -> 3 }T
T{ ACTION-OF defer1 -> ' + }T
T{    action-defer1 -> ' + }T


\ BUFFER:
DECIMAL
T{ 127 CHARS BUFFER: TBUF1 -> }T
T{ 127 CHARS BUFFER: TBUF2 -> }T
\ Buffer is aligned
T{ TBUF1 ALIGNED -> TBUF1 }T

\ Buffers do not overlap
T{ TBUF2 TBUF1 - ABS 127 CHARS < -> <FALSE> }T

\ Buffer can be written to
1 CHARS CONSTANT /CHAR
: TFULL? ( c-addr n char -- flag )
   TRUE 2SWAP CHARS OVER + SWAP ?DO
     OVER I C@ = AND
   /CHAR +LOOP NIP
;

T{ TBUF1 127 CHAR * FILL   ->        }T
T{ TBUF1 127 CHAR * TFULL? -> <TRUE> }T

T{ TBUF1 127 0 FILL   ->        }T
T{ TBUF1 127 0 TFULL? -> <TRUE> }T
HEX

\ C"
T{ : cq1 C" 123" ; -> }T
T{ : cq2 C" " ;    -> }T
T{ cq1 COUNT EVALUATE -> 123 }T
T{ cq2 COUNT EVALUATE ->     }T


\ CASE OF ENDOF ENDCASE
: cs1 CASE 1 OF 111 ENDOF
   2 OF 222 ENDOF
   3 OF 333 ENDOF
   >R 999 R>
   ENDCASE
;
T{ 1 cs1 -> 111 }T
T{ 2 cs1 -> 222 }T
T{ 3 cs1 -> 333 }T
T{ 4 cs1 -> 999 }T
: cs2 >R CASE
   -1 OF CASE R@ 1 OF 100 ENDOF
                2 OF 200 ENDOF
                >R -300 R>
        ENDCASE
     ENDOF
   -2 OF CASE R@ 1 OF -99 ENDOF
                >R -199 R>
        ENDCASE
     ENDOF
     >R 299 R>
   ENDCASE R> DROP ;

T{ -1 1 cs2 ->  100 }T
T{ -1 2 cs2 ->  200 }T
T{ -1 3 cs2 -> -300 }T
T{ -2 1 cs2 ->  -99 }T
T{ -2 2 cs2 -> -199 }T
T{  0 2 cs2 ->  299 }T

\ COMPILE,
:NONAME DUP + ; CONSTANT dup+
T{ : q dup+ COMPILE, ; -> }T
T{ : as [ q ] ; -> }T
T{ 123 as -> 246 }T


\ DEFER
T{ DEFER defer2 ->   }T
T{ ' * ' defer2 DEFER! -> }T
T{   2 3 defer2 -> 6 }T
T{ ' + IS defer2 ->   }T
T{    1 2 defer2 -> 3 }T

\ DEFER!
T{ DEFER defer3 -> }T
T{ ' * ' defer3 DEFER! -> }T
T{ 2 3 defer3 -> 6 }T

T{ ' + ' defer3 DEFER! -> }T
T{ 1 2 defer3 -> 3 }T

\ DEFER@
T{ DEFER defer4 -> }T
T{ ' * ' defer4 DEFER! -> }T
T{ 2 3 defer4 -> 6 }T
T{ ' defer4 DEFER@ -> ' * }T

T{ ' + IS defer4 -> }T
T{ 1 2 defer4 -> 3 }T
T{ ' defer4 DEFER@ -> ' + }T

\ FALSE
T{ FALSE -> 0 }T
T{ FALSE -> <FALSE> }T

\ HOLDS
T{ 0 0 <# S" Test" HOLDS #> S" Test" COMPARE -> 0 }T

\ IS
T{ DEFER defer5 -> }T
T{ : is-defer5 IS defer5 ; -> }T
T{ ' * IS defer5 -> }T
T{ 2 3 defer5 -> 6 }T

T{ ' + is-defer5 -> }T
T{ 1 2 defer5 -> 3 }T

\ PARSE-NAME
T{ PARSE-NAME abcd S" abcd" S= -> <TRUE> }T
T{ PARSE-NAME   abcde   S" abcde" S= -> <TRUE> }T
\ test empty parse area
T{ PARSE-NAME
   NIP -> 0 }T    \ empty line
T{ PARSE-NAME
   NIP -> 0 }T    \ line with white space

T{ : parse-name-test ( "name1" "name2" -- n )
   PARSE-NAME PARSE-NAME S= ; -> }T

T{ parse-name-test abcd abcd -> <TRUE> }T
T{ parse-name-test  abcd   abcd   -> <TRUE> }T
T{ parse-name-test abcde abcdf -> <FALSE> }T
T{ parse-name-test abcdf abcde -> <FALSE> }T
T{ parse-name-test abcde abcde
    -> <TRUE> }T
T{ parse-name-test abcde abcde
    -> <TRUE> }T    \ line with white space

\ TRUE
T{ TRUE -> <TRUE> }T
T{ TRUE -> 0 INVERT }T

\ VALUE
T{  111 VALUE v1 -> }T
T{ -999 VALUE v2 -> }T
T{ v1 ->  111 }T
T{ v2 -> -999 }T
T{ 222 TO v1 -> }T
T{ v1 -> 222 }T
T{ : vd1 v1 ; -> }T
T{ vd1 -> 222 }T

T{ : vd2 TO v2 ; -> }T
T{ v2 -> -999 }T
T{ -333 vd2 -> }T
T{ v2 -> -333 }T
T{ v1 ->  222 }T

