T{ <TRUE>  [IF] 111 [ELSE] 222 [THEN] -> 111 }T
T{ <FALSE> [IF] 111 [ELSE] 222 [THEN] -> 222 }T

\ Check words are immediate
: tfind bl word find ;
T{ tfind [IF]      nip -> 1 }T
T{ tfind [ELSE]    nip -> 1 }T
T{ tfind [THEN]    nip -> 1 }T

T{ : pt2 [  0 ] [IF] 1111 [ELSE] 2222 [THEN] ; pt2 -> 2222 }T
T{ : pt3 [ -1 ] [IF] 3333 [ELSE] 4444 [THEN] ; pt3 -> 3333 }T

\ Code spread over more than 1 line.
T{ <TRUE>  [IF] 1
    2
  [ELSE]
    3
    4
  [THEN] -> 1 2 }T
T{ <FALSE> [IF]
      1 2
      [ELSE]
        3 4
  [THEN] -> 3 4 }T

\ Nested
: <T> <TRUE>  ;
: <F> <FALSE> ;
T{ <T> [IF] 1 <T> [IF] 2 [ELSE] 3 [THEN] [ELSE] 4 [THEN] -> 1 2 }T
T{ <F> [IF] 1 <T> [IF] 2 [ELSE] 3 [THEN] [ELSE] 4 [THEN] -> 4 }T
T{ <T> [IF] 1 <F> [IF] 2 [ELSE] 3 [THEN] [ELSE] 4 [THEN] -> 1 3 }T
T{ <F> [IF] 1 <F> [IF] 2 [ELSE] 3 [THEN] [ELSE] 4 [THEN] -> 4 }T

