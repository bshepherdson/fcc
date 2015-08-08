\ CORE EXT words, selectively.

: cr 10 emit ;

: .(   [char] ) parse type ; IMMEDIATE

: <> = INVERT ;
: 0<> 0 <> ;


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
  <> ABORT" *** Unknown word in ACTION-OF"
  state @ IF LITERAL THEN
; IMMEDIATE

: DEFER! ( xt2 xt1 -- ) >body ! ;
: DEFER@ ( xt1 -- xt2 ) >body @ ;

: IS ( xt "<spaces>name" -- )
  bl word find ( xt ? )
  0= IF ." Could not find word: " count type cr EXIT THEN
  state @ IF LITERAL ['] defer! compile, ELSE defer! THEN
; IMMEDIATE


: AGAIN ( C: dest -- ) ['] (branch) compile, here - , ; IMMEDIATE

: BUFFER: ( u "<spaces>name" -- ) align create allot ;

: ERASE ( addr u -- ) 0 FILL ;

: FALSE 0 ;
: TRUE -1 ;

: NIP ( a b -- b ) swap drop ;
: TUCK ( a b -- b a b ) swap over ;

1024 BUFFER: PAD

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
  >body ( body-addr ) \ Convert the xt to the actual data pointer.
  state @ IF LITERAL ['] ! compile, ELSE ! THEN
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

