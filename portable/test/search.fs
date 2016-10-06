
only forth definitions

VARIABLE wid1
VARIABLE wid2

: save-orderlist ( widn .. wid1 n -- ) dup , 0 ?DO , LOOP ;

CREATE order-list
T{ get-order save-orderlist -> }T

: get-orderlist ( -- widn .. wid1 n)
  order-list dup @ cells   ( -- ad n )
  over +                   ( -- ad ad' )
  ?DO i @ -1 cells +LOOP   ( -- )
;


T{ forth-wordlist wid1 ! -> }T

T{ get-order over      -> get-order wid1 @ }T
T{ get-order set-order -> }T
T{ get-order           -> get-orderlist }T
T{ get-orderlist drop get-orderlist 2* set-order -> }T

T{ get-order -> get-orderlist drop get-orderlist 2* }T
T{ get-orderlist set-order get-order -> get-orderlist }T
: so2a get-order get-orderlist set-order ;
: so2 0 set-order so2a ;

T{ so2 -> 0 }T \ 0 set-order leaves the search order empty.
: so3 -1 set-order so2a ;
: so4 only so2a ;

T{ so3 -> so4 }T \ -1 set-order is the same as only.


T{ also get-order only -> get-orderlist over swap 1+ }T

T{ only forth get-order -> get-orderlist }T
: so1 set-order ; \ In case its not in the main wordlist.

T{ only forth-wordlist 1 set-order get-orderlist so1 -> }T
T{ get-order -> get-orderlist }T

T{ get-current -> wid1 @ }T
T{ wordlist wid2 ! -> }T
T{ wid2 @ set-current -> }T
T{ get-current -> wid2 @ }T
T{ wid1 @ set-current -> }T


T{ only forth definitions -> }T
T{ get-current -> forth-wordlist }T
T{ get-order wid2 @ swap 1+ set-order get-order (discard) definitions get-current -> wid2 @ }T
T{ get-order -> get-orderlist wid2 @ swap 1+ }T
T{ previous get-order -> get-orderlist }T
T{ definitions get-current -> forth-wordlist }T



: alsowid2 also get-order wid2 @ rot drop swap set-order ;
alsowid2
: w1 1234 ;
definitions : w1 -9876 ; immediate

only forth
T{ w1 -> 1234 }T
definitions
T{ w1 -> 1234 }T
alsowid2
T{ w1 -> -9876 }T
definitions T{ w1 -> -9876 }T

only forth definitions
: so5 dup if swap execute then ;

T{ S" w1" wid1 @ search-wordlist so5 -> -1  1234 }T
T{ S" w1" wid2 @ search-wordlist so5 ->  1 -9876 }T

: c"w1" C" w1" ;
T{ alsowid2 c"w1" find so5 ->  1 -9876 }T
T{ previous c"w1" find so5 -> -1  1234 }T


only forth definitions
variable xt ' dup xt !
variable xti ' .( xti ! \ immediate word
T{ S" DUP" wid1 @ search-wordlist -> xt  @ -1 }T
T{ S" .("  wid1 @ search-wordlist -> xti @  1 }T
T{ S" DUP" wid2 @ search-wordlist ->        0 }T

: c"dup" C" DUP" ;
: c".(" C" .(" ;
: c"x" C" unknown word" ;
T{ c"dup" find -> xt  @ -1 }T
T{ c".("  find -> xti @  1 }T
T{ c"x"   find -> c"x"   0 }T

\ Disabled these tests, since ORDER prints to the console.
\ That makes the gold-master tests unacceptably fragile.
\ I have observed that they work correctly.

\ cr .( only forth definitions search order and compilation list) cr
\ T{ only forth definitions order -> }T
\ cr .( Plus another unnamed wordlist at head of search order) cr
\ T{ alsowid2 definitions order -> }T

