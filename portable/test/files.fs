\ FILE ACCESS word tests

DECIMAL
\ CREATE
: fn1 S" fatest1.txt" ;
VARIABLE fid1
T{ fn1 R/W CREATE-FILE SWAP fid1 ! -> 0 }T
T{ fid1 @ CLOSE-FILE -> 0 }T

\ WRITE-LINE
: line1 S" Line 1" ;
T{ fn1 W/O OPEN-FILE SWAP fid1 ! -> 0 }T
T{ line1 fid1 @ WRITE-LINE -> 0 }T
T{ fid1 @ CLOSE-FILE -> 0 }T

\ READ-LINE
200 CONSTANT bsize
CREATE buf bsize ALLOT
VARIABLE #chars
T{ fn1 R/O OPEN-FILE SWAP fid1 ! -> 0 }T
T{ fid1 @ FILE-POSITION -> 0 0 0 }T
T{ buf 100 fid1 @ READ-LINE ROT DUP #chars ! ->
    <TRUE> 0 line1 SWAP DROP }T
T{ buf #chars @ line1 COMPARE -> 0 }T
T{ fid1 @ CLOSE-FILE -> 0 }T


\ REPOSITION-FILE
: line2 S" Line 2 blah blah blah" ;
: rl1 buf 100 fid1 @ READ-LINE ;
2VARIABLE fp
T{ fn1 R/W OPEN-FILE SWAP fid1 ! -> 0 }T
T{ fid1 @ FILE-SIZE DROP fid1 @ REPOSITION-FILE -> 0 }T
T{ fid1 @ FILE-SIZE -> fid1 @ FILE-POSITION }T

T{ line2 fid1 @ WRITE-FILE -> 0 }T
T{ 10 0 fid1 @ REPOSITION-FILE -> 0 }T
T{ fid1 @ FILE-POSITION -> 10 0 0 }T

T{ 0 0 fid1 @ REPOSITION-FILE -> 0 }T
T{ rl1 -> line1 SWAP DROP <TRUE> 0 }T
T{ rl1 ROT DUP #chars ! -> <TRUE> 0 line2 SWAP DROP }T
T{ buf #chars @ line2 COMPARE -> 0 }T
T{ rl1 -> 0 <FALSE> 0 }T

T{ fid1 @ FILE-POSITION ROT ROT fp 2! -> 0 }T
T{ fp 2@ fid1 @ FILE-SIZE DROP D= -> <TRUE> }T
T{ S" " fid1 @ WRITE-LINE -> 0 }T
T{ S" " fid1 @ WRITE-LINE -> 0 }T
T{ fp 2@ fid1 @ REPOSITION-FILE -> 0 }T
T{ rl1 -> 0 <TRUE>  0 }T
T{ rl1 -> 0 <TRUE>  0 }T
T{ rl1 -> 0 <FALSE> 0 }T
T{ fid1 @ CLOSE-FILE -> 0 }T

\ FILE-SIZE
: cbuf buf bsize 0 FILL ;
: fn2 S" fatest2.txt" ;
VARIABLE fid2
: setpad PAD 50 0 DO I OVER C! CHAR+ LOOP DROP ;
setpad

\ Note: If anything else is defined setpad must be called again as the pad may move

T{ fn2 R/W BIN CREATE-FILE SWAP fid2 ! -> 0 }T
T{ PAD 50 fid2 @ WRITE-FILE fid2 @ FLUSH-FILE -> 0 0 }T
T{ fid2 @ FILE-SIZE -> 50 0 0 }T
T{ 0 0 fid2 @ REPOSITION-FILE -> 0 }T
T{ cbuf buf 29 fid2 @ READ-FILE -> 29 0 }T
T{ PAD 29 buf 29 COMPARE -> 0 }T
T{ PAD 30 buf 30 COMPARE -> 1 }T
T{ cbuf buf 29 fid2 @ READ-FILE -> 21 0 }T
T{ PAD 29 + 21 buf 21 COMPARE -> 0 }T
T{ fid2 @ FILE-SIZE DROP fid2 @ FILE-POSITION DROP D= -> <TRUE> }T
T{ buf 10 fid2 @ READ-FILE -> 0 0 }T
T{ fid2 @ CLOSE-FILE -> 0 }T


\ RESIZE-FILE
setpad
T{ fn2 R/W BIN OPEN-FILE SWAP fid2 ! -> 0 }T
T{ 37 0 fid2 @ RESIZE-FILE -> 0 }T
T{ fid2 @ FILE-SIZE -> 37 0 0 }T
T{ 0 0 fid2 @ REPOSITION-FILE -> 0 }T
T{ cbuf buf 100 fid2 @ READ-FILE -> 37 0 }T
T{ PAD 37 buf 37 COMPARE -> 0 }T
T{ PAD 38 buf 38 COMPARE -> 1 }T
T{ 500 0 fid2 @ RESIZE-FILE -> 0 }T
T{ fid2 @ FILE-SIZE -> 500 0 0 }T
T{ 0 0 fid2 @ REPOSITION-FILE -> 0 }T
T{ cbuf buf 100 fid2 @ READ-FILE -> 100 0 }T
T{ PAD 37 buf 37 COMPARE -> 0 }T
T{ fid2 @ CLOSE-FILE -> 0 }T

\ DELETE-FILE
T{ fn2 DELETE-FILE -> 0 }T
T{ fn2 R/W BIN OPEN-FILE SWAP DROP -> 0 }T
T{ fn2 DELETE-FILE -> 0 }T

\ ( extended for multiple lines
T{ ( 1 2 3
      4 5 6
      7 8 9 ) 11 22 33 -> 11 22 33 }T

\ SOURCE-ID extended for files
T{ SOURCE-ID DUP -1 = SWAP 0= OR -> <FALSE> }T

