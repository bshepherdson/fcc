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


\ DEFER and friends
\ A DEFERred word is a cell whose value contains an xt. When the word is
\ called, its xt will be executed.
: DEFER create 0 , DOES> @ execute ;

: ACTION-OF
  BL word find ( xt ? )
  drop
  state @ IF ['] (lit) , , ( ) THEN
; IMMEDIATE

: DEFER! ( xt2 xt1 -- ) >body 4 cells + ! ;
: DEFER@ ( xt1 -- xt2 ) >body 4 cells + @ ;

: IS ( xt "<spaces>name" -- )
  bl word find ( xt ? )
  0= IF ." Could not find word: " count type cr EXIT THEN
  state @ IF ['] (lit) , ,  ['] defer! , ELSE defer! THEN
; IMMEDIATE


: AGAIN ( C: dest -- ) ['] (branch) , here - , ; IMMEDIATE

\ Unimplemented output: .R
\ Unimplemented double-cell: 2>R 2R> 2R@

