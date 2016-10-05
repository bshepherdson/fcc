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
: C-LIBRARY ( addr u -- err? ) >CSTRING c-library not ;
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
: CCALL5-NR ccall5 drop ;
: CCALL6-NR ccall6 drop ;


\ These are from the MEMORY word set, but I'm lazy and don't want to add a new
\ file for these few words.
: ALLOCATE ( u -- a-addr ior ) (allocate) dup 0= ;

S" free" c-call-named (free)
: FREE ( a-addr -- ior ) (free) ccall1-nr   0 ;

S" realloc" c-call-named (realloc)
: RESIZE ( a-addr1 u -- a-addr2 ior )
  over >r
  (realloc) ccall2 ( a-addr2    R: a-addr1 )
  dup 0= IF drop r> 1 ELSE r> drop 0 THEN
;

