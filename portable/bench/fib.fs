: fib ( n1 -- n2 )
    dup 2 < if
drop 1
    else
dup
1- recurse
swap 2 - recurse
+
    then ;

: main 20 0 DO 34 fib . LOOP ;

main bye
