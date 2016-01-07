\ Facility word set

\ Facility Extensions word set

\ Structures

: BEGIN-STRUCTURE ( "<spaces>name" -- struct-sys 0 )
  CREATE
    HERE 0 0 , ( loc 0 ) \ put the dummy size of 0 down.
  DOES> @ \ read the length
;

: +FIELD ( n1 n2 "<spaces>name" -- n3 )
  \ n1 is the struct size before, n3 is the size after. n2 is the size of this
  \ field.
  CREATE over , +
  DOES> @ +
;

: CFIELD: ( n1 "<spaces>name" -- n2 ) 1 chars +field ;
: FIELD:  ( n1 "<spaces>name" -- n2 ) aligned 1 cells +field ;

\ struct-sys is the address of the struct size
: END-STRUCTURE ( struct-sys +n -- ) swap ! ;

