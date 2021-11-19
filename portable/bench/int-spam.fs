32000 constant intMax
variable intResult

: DoInt
  1 dup intResult dup >R !
  begin
    dup intMax <
  while
    dup negate r@ +! 1+
    dup r@ +! 1+
    r@ @ over * r@ ! 1+
    r@ @ over / r@ ! 1+
  repeat
  r> 2drop
;

: int-bench 1000 0 do doint loop ;

int-bench bye

