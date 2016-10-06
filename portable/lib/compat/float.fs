\ Compatibility with the FLOAT library.
\ Only supports a few basic words to keep the structure alignment stuff happy.
: dfaligned ( addr -- df-addr ) 7 + 7 invert and ;
: sfaligned ( addr -- sf-addr ) 3 + 3 invert and ;
: faligned dfaligned ;

: dfloats ( n1 -- n2 ) 3 lshift ;
: sfloats ( n1 -- n2 ) 2 lshift ;
:  floats ( n1 -- n2 ) dfloats ;

