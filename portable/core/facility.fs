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


\ These are from the SEARCH ORDER word set, but I'm lazy and don't want to add a
\ new file.

\ Returns the address of the cell holding the compilation wordlist.
: (compilation-wordlist) ( -- *compilation-wordlist ) (dict-info) 2drop ;
\ Returns the address of the cell holding the search index.
: (search-index) ( -- *search-index ) (dict-info) drop swap drop ;
\ Returns the address of the search order array.
: (search-order) ( -- *search-order ) (dict-info) >r 2drop r> ;

\ Capture the current compilation wordlist, which is the main Forth one.
(compilation-wordlist) @ CONSTANT FORTH-WORDLIST

: (discard) ( xn ... x1 n -- ) 0 ?DO drop LOOP ;

\ Replaces the top of the search order with the Forth wordlist.
: FORTH ( -- )
  (search-order) (search-index) cells +
  forth-wordlist swap !
;

\ These manipulate the current compilation wordlist.
: GET-CURRENT ( -- wid ) (compilation-wordlist) @ ;
: SET-CURRENT ( wid -- ) (compilation-wordlist) ! ;

\ These read and write the search order in the format given.
\ The topmost on the stack are the first in the order.
: GET-ORDER ( -- wid_n ... wid_1 n )
  (search-index) @ 1+ 0 ?DO
    i cells (search-order) + @
  LOOP
  (search-index) @ 1+
;

: SET-ORDER ( wid_n ... wid_1 n -- )
  dup -1 = IF
    drop forth-wordlist (search-order) !
    0 (search-index) !
    EXIT
  THEN

  dup >r
  0 ?DO
    i cells (search-order) + !
  LOOP
  r> 1- (search-index) !
;

\ Reduces to the minimum: the core Forth wordlist.
: ONLY ( -- ) -1 set-order ;

\ Dumps a single wordlist, space-separated.
\ NB: This depends on the structure of the header!
: DUMP-WORDLIST ( wid -- )
  BEGIN @ dup WHILE ( *header )
    dup cell+ dup cell+ @ swap @ 255 and ( *header c-addr len )
    type space
  REPEAT
  drop
;

\ Outputs the current search order.
\ The format is implementation-defined.
\ Here it's all the words in each list space-separated, one list per line.
: ORDER ( -- )
  get-order ( ... n )
  0 ?DO dump-wordlist cr LOOP
;

: PREVIOUS ( -- ) -1 (search-index) +! ;

\ This duplicates the code for FIND but this is easier since that's in core.
: SEARCH-WORDLIST ( c-addr u wid -- 0 | xt 1 | xt -1 )
  \ Uppercase the incoming word first.
  >r 2dup 0 DO dup i + dup c@ dup 'a' 'z' IF 32 - THEN swap c! LOOP
  \ Then scan the wordlist.
  BEGIN @ dup WHILE ( c-addr u *header)
    >r 2dup ( c-addr u c-addr u    R: *header )
    r@ 2 cells + @
    r@ cell+ @ 255 and ( c-addr u c-addr u word-addr word-len   R: *header )
    compare 0= IF \ matched
      \ The xt is the header + 3 cells
      2drop r@ 3 cells +
      \ And the immediate bit is header[1] & 512
      r> cell+ @ 512 and IF 1 ELSE -1 THEN
      ( xt 1/-1 )
      EXIT
    THEN
    r>
  REPEAT
  drop
;

\ Creates a new wordlist (but doesn't but it into either the search order or
\ compilation wordlist).
: WORDLIST ( -- wid ) here 1 cells allot   0 over ! ;

\ Makes the current top of the search order into the compilation wordlist.
: DEFINITIONS ( -- ) get-order swap set-current (discard) ;

: ALSO ( -- ) get-order over swap 1+ set-order ;

