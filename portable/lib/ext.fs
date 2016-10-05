\ CORE EXT words, selectively.

: cr 10 emit ;

: .(   [char] ) parse type ; IMMEDIATE

: <> = NOT ;
: 0<> 0 <> ;

\ : :NONAME ( -- xt ) here dup (last-word) !   ['] (docol) @ ,   ] ;

: ?DO ( limit index --   C: old-jump-addr )
  ['] 2dup compile, ['] swap compile, ['] >r dup compile, compile,
  ['] <> compile, ['] (0branch) compile,
  (loop-top) @    here (loop-top) ! ( C: old-jump-addr )
  0 , \ Placeholder for the jump offset to go.
; IMMEDIATE

\ DEFER and friends
\ A DEFERred word is a cell whose value contains an xt. When the word is
\ called, its xt will be executed.
: DEFER create 0 , DOES> @ execute ;

: ACTION-OF
  BL word find ( xt ? )
  0= ABORT" *** Unknown word in ACTION-OF"
  state @ IF
    [LITERAL] ['] >body compile, ['] @ compile,
  ELSE
    >body @
  THEN
; IMMEDIATE

: DEFER! ( xt2 xt1 -- ) >body ! ;
: DEFER@ ( xt1 -- xt2 ) >body @ ;

: IS ( xt "<spaces>name" -- )
  bl word find ( xt ? )
  0= IF ." Could not find word: " count type cr EXIT THEN
  state @ IF [LITERAL] ['] defer! compile, ELSE defer! THEN
; IMMEDIATE


: AGAIN ( C: dest -- ) ['] (branch) compile, here - , ; IMMEDIATE

: BUFFER: ( u "<spaces>name" -- ) align create allot ;

: ERASE ( addr u -- ) 0 FILL ;

: FALSE 0 ;
: TRUE -1 ;

: NIP ( a b -- b ) swap drop ;
: TUCK ( a b -- b a b ) swap over ;

1024 BUFFER: PAD

\ Implementation taken from the Forth 2012 appendix.
: WITHIN ( test lo hi -- ? ) over - >R   - R> U< ;

: ROLL ( xn ... x1 x0 u -- xn-1 .. x1 x0 xn )
  dup 0= IF drop EXIT THEN
  1- swap >R recurse ( ... ret )
  r> swap
;

\ TODO Could make this real data eventually. Fake for now.
: UNUSED ( -- u ) 100000000 ;

: U> ( a b -- ? ) 2dup U< >R   =   R> or ;

: VALUE constant ;
: TO ( i*x "<spaces>name" -- )
  bl word find ( xt ? )
  0= IF ." Could not find word: " count type cr EXIT THEN
  >body ( body-addr ) \ Convert the xt to the actual data pointer.
  state @ IF [LITERAL] ['] ! compile, ELSE ! THEN
; IMMEDIATE


\ Displays n1 in a field n2 characters wide.
: (PAD-FIELD) ( c-addr1 real-length intended-width -- c-addr2 len )
  2dup >= IF \ Overflowed the space.
    drop
  ELSE
    dup >R
    swap ( c-addr width len   R: width )
    DO
      1 chars - 32 over C!
    LOOP ( c-addr'    R: width )
    R> ( c-addr' width )
  THEN
;

: .R  ( n1 n2 -- )
  swap (#HOLD) rot ( c-addr len width )
  (pad-field) type
;
: U.R ( u n -- )
  swap (#UHOLD) rot ( c-addr len width )
  (pad-field) type
;

: HOLDS ( c-addr u -- ) BEGIN dup WHILE 1- 2dup + c@ hold repeat 2drop ;

: 2>R ( x1 x2 -- ) ( R: -- x1 x2 ) swap >R >R ;
: 2R> ( -- x1 x2 ) ( R: x1 x2 -- ) R> R> swap ;
: 2R@ ( -- x1 x2 ) ( R: x1 x2 -- x1 x2 ) R> R>   2dup   >R >R   swap ;

\ A linked list of (link ptr, length cell, string content....) entries giving
\ the previously required files. Defined here for MARKER's use, and set when new
\ files get REQUIRED.
VARIABLE (included-file-list)
0 (included-file-list) !

: MARKER ( "<spaces>name" -- ) ( exec: -- )
  HERE CREATE ,   (included-file-list) @ ,
  DOES>
    dup cell+ @   (included-file-list) !
    @ dup   (LATEST) !   (>HERE) ! ;


\ TODO Expand to support blocks and files when those word sets are added.
: SAVE-INPUT ( -- x1 ... xn n ) >IN @ 1 ;
: RESTORE-INPUT ( x1 ... xn n -- error? ) drop >IN !   false ;


: CASE ( -- ) ( C: -- depth ) 0 ; IMMEDIATE
: OF ( x1 x2 -- | x1 ) ( C: -- of-sys )
  ['] over compile,
  ['] = compile,
  postpone IF
  ['] drop compile,
; IMMEDIATE
: ENDOF ( -- ) ( C: of-sys ) postpone ELSE ; IMMEDIATE
: ENDCASE ( x -- ) ( C: jump-loc1 ... jump-locn n -- )
  ['] drop compile,
  BEGIN ?dup WHILE postpone THEN REPEAT
; IMMEDIATE


: C" ( "ccc<quote>" -- )
  postpone S"
  ['] drop compile,
  ['] 1- compile,
; IMMEDIATE


\ These are actually from the DOUBLE word set; but the test suite uses them
: 2VARIABLE CREATE 0 , 0 , ;
: D= ( xd1 xd2 -- flag ) rot = >R = R> and ;

\ These are from the MEMORY word set, but I'm lazy and don't want to add a new
\ file for these few words.
: ALLOCATE ( u -- a-addr ior ) (allocate) dup 0= ;

S" free" c-call-named (free)
: FREE ( a-addr -- ior ) (free) ccall1-nr   0 ;

S" realloc" c-call-named (realloc)
: RESIZE ( a-addr1 u -- a-addr2 ior )
  over >r
  (realloc) ccall2 ( a-addr2    R: a-addr1 )
  dup 0= IF drop r> 1 ELSE rdrop 0 THEN
;

\ Unimplemented strings: S\"
\ Unimplemented obsolete words: [COMPILE]

