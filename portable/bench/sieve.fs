\ #! /usr/stud/paysan/bin/forth

DECIMAL
\ : SECS TIME&DATE  SWAP 60 * + SWAP 3600 * +  NIP NIP NIP ;
CREATE FLAGS 8190 ALLOT
variable eflag
\ FLAGS 8190 + CONSTANT EFLAG

: PRIMES  ( -- n )  FLAGS 8190 1 FILL  0 3  EFLAG @ FLAGS
  DO   I C@
       IF  DUP I + DUP EFLAG @ <
           IF    EFLAG @ SWAP
                 DO  0 I C! DUP  +LOOP
           ELSE  DROP  THEN  SWAP 1+ SWAP
           THEN  2 +
       LOOP  DROP ;

: BENCHMARK  0 1000 0 DO  PRIMES NIP  LOOP ;
\ SECS BENCHMARK . SECS SWAP - CR . .( secs)
: main
40 0 DO
  flags 8190 + eflag !
  benchmark .
LOOP
;

\ HPPA/720, 50 MHz: user 3.90s
main bye
