\ Very simple benchmark of stack and NEXT performance.

: INNER  1000 0 DO  34 DROP  LOOP ;
: BENCH*100 1000000 0 DO INNER LOOP ;

BENCH*100 bye

