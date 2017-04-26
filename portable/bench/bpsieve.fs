8190 CONSTANT size

CREATE flags size ALLOT
flags size + CONSTANT eflags

: PRIMES  ( -- n )
  flags size 1 FILL
  0 3  eflags flags
         DO   I C@ IF
          DUP I + DUP eflags U<
                      IF  eflags SWAP DO  0 I C!  DUP +LOOP
                 ELSE  DROP
          THEN SWAP 1+ SWAP
                THEN 2 +
       LOOP   DROP ;

: benchmark   0 100 0 DO primes nip LOOP . ." primes found." cr ;
benchmark bye
