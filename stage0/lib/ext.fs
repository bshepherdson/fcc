\ CORE EXT words, selectively.

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


\ Unimplemented output: .R
\ Unimplemented double-cell: 2>R 2R> 2R@

