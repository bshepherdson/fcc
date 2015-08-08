\ CORE EXT words, selectively.

: cr 10 emit ;

: .(   [char] ) parse type ; IMMEDIATE

: <> = INVERT ;
: 0<> 0 <> ;
: 0> 0 > ;


: ?DO ( limit index --   C: old-jump-addr )
  ['] 2dup , ['] swap , ['] >r dup , ,
  ['] <> , ['] (0branch) ,
  (loop-top) @    here (loop-top) ! ( C: old-jump-addr )
  0 , \ Placeholder for the jump offset to go.
; IMMEDIATE

\ Internal helper for use by DEFER@, DEFER!, and other things that
\ deal with the internals of CREATEd definitions.
: (>DATA) ( xt -- addr-data ) >body 4 cells + ;

\ DEFER and friends
\ A DEFERred word is a cell whose value contains an xt. When the word is
\ called, its xt will be executed.
: DEFER create 0 , DOES> @ execute ;

: ACTION-OF
  BL word find ( xt ? )
  drop
  state @ IF ['] (lit) , , ( ) THEN
; IMMEDIATE

: DEFER! ( xt2 xt1 -- ) (>data) ! ;
: DEFER@ ( xt1 -- xt2 ) (>data) @ ;

: IS ( xt "<spaces>name" -- )
  bl word find ( xt ? )
  0= IF ." Could not find word: " count type cr EXIT THEN
  state @ IF ['] (lit) , ,  ['] defer! , ELSE defer! THEN
; IMMEDIATE


: AGAIN ( C: dest -- ) ['] (branch) , here - , ; IMMEDIATE

: BUFFER: ( u "<spaces>name" -- ) align create allot ;

: COMPILE, , ; IMMEDIATE

: ERASE ( addr u -- ) 0 FILL ;

: FALSE 0 ;
: TRUE -1 ;

: NIP ( a b -- b ) swap drop ;
: TUCK ( a b -- b a b ) swap over ;

: PAD ( -- c-addr ) here ;

: PICK ( xn ... x1 x0 u -- xn ... x1 x0 xn )
  dup 0= IF drop dup EXIT THEN
  1- SWAP >R recurse ( ... ret )
  r> swap
;
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
  (>data) ( body-addr ) \ Convert the xt to the actual data pointer.
  state @ IF ['] (lit) , , ['] ! , ELSE ! THEN
; IMMEDIATE


\ Implementation taken from the Forth 2012 appendix.
: WITHIN ( test lo hi -- ? ) over - >R   - R> U< ;

\ Unimplemented output: .R HOLDS U.R
\ Unimplemented double-cell: 2>R 2R> 2R@
\ Unimplemented strings: C" S\"
\ Unimplemented control structures: CASE ENDCASE OF ENDOF
\ Unimplemented dictionary mangler: MARKER
\ Unimplemented input source manglers: RESTORE-INPUT SAVE-INPUT
\ Unimplemented obsolete words: [COMPILE]

