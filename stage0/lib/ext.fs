\ CORE EXT words, selectively.

: .(   [char] ) parse type ; IMMEDIATE

: 0<> 0= INVERT ;
: 0> 0 > ;

\ Unimplemented output: .R
\ Unimplemented double-cell: 2>R 2R> 2R@

