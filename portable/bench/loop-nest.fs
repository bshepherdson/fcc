\ Generic benchmarks of nesting and loops.
\ Adapted from Forth Dimensions March/April '92.

\ Empty loop  Empty = XX
: X   30000 0 DO   LOOP ;
: XX      5 0 DO X LOOP ;

\ Nesting1  Nest1 = ZZ - XX

: N:  ;
: Z    30000 0 DO  N: N: N:  N: N: N:  LOOP ;
: ZZ       5 0 DO  Z  LOOP ;

\ Nesting2  Nest2 = WW - XX

: W1      ;
: W2   W1 ;
: W3   W2 ;
: W4   W3 ;
: W5   W4 ;
: W6   W5 ;

: W    30000 0 DO  W6  LOOP ;
: WW       5 0 DO  W   LOOP ;


\ Primitives   Prims = QQ - XX
\ Exercise: variable constant @ ! + DUP SWAP OVER DROP

   VARIABLE LOC
10 CONSTANT TEN

: NULL    TEN DUP  LOC SWAP  OVER !  @ +  DROP ;
: Q    30000 0 DO  NULL  LOOP ;
: QQ       5 0 DO  Q     LOOP ;


\ Standard Sieve =  10 0 do  do-prime  loop

8190 CONSTANT size
     CREATE   flags    size ALLOT

: DO-PRIME  flags size 1 FILL
    0  size 0 DO flags I +
           C@ IF I DUP +  3 +
           DUP  I +
              BEGIN  DUP size <
            WHILE  0 OVER flags + C!
             OVER +
            REPEAT
            2DROP 1+
           THEN
      LOOP  ( count) DROP ;

: RR    10 0 DO DO-PRIME LOOP ;


: bench 100 0 DO XX ZZ WW QQ RR LOOP ;
bench bye
