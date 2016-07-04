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



\ Extra extension: C FFI

\ NB: This string is *temporary*. It's using HERE as scratch space.
: >CSTRING ( addr u -- c-str )
  here swap   ( addr here u )
  2dup + 0 swap c!
  move here
;

\ Converts a null-terminated C string on the stack into a Forth string.
: CSTRING> ( c-str -- addr u )
  dup
  BEGIN dup c@ WHILE 1+ REPEAT
  over -
;


\ Helpers that wraps the internal calls in a more Forth-friendly form.
: C-LIBRARY ( addr u -- ) >CSTRING c-library ;
: C-SYMBOL ( addr u -- sym ) >CSTRING c-symbol ;

\ Now the real user-friendly constant creator:
: C-CALL-NAMED ( addr1 u1 "forth name" -- )
  C-SYMBOL CONSTANT
;

: C-CALL ( "forth-and-C name" -- )
  >IN @
  parse-name C-SYMBOL
  swap >IN !
  CONSTANT
;

\ Non-returning versions of each ccallN
: CCALL0-NR ccall0 drop ;
: CCALL1-NR ccall1 drop ;
: CCALL2-NR ccall2 drop ;
: CCALL3-NR ccall3 drop ;
: CCALL4-NR ccall4 drop ;

