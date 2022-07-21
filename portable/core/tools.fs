\ TOOLS word set.
\ .S is provided in the VM.
\ Also BYE and STATE.

: ? ( a-addr -- ) @ U. ;

\ Dumps a hexdump-style listing of memory contents.
HEX
: DUMP ( addr u -- )
  base @ >R
  HEX
  0 DO
    i 10 mod 0= IF cr dup i + 1 u.r [char] : emit THEN
    i  2 mod 0= IF space THEN
    dup i + c@ dup 10 < IF [char] 0 emit THEN 1 .R
  LOOP
  cr
  R> base !
;
DECIMAL

\ Given a nt returns the string of the name.
: NAME>STRING ( nt -- c-addr u )
  \ nt points at the link pointer, next is the metadata+length cell, then the
  \ string address. 2@ reads TOS, NOS.
  cell+ 2@    ( c-addr metadata )
  255 and     ( c-addr len )
;

: (name>link) ( nt -- nt' )
  @ \ nt already points at the link.
;

\ Given an xt, tries to recover the nt for it.
\ This is expensive, since it walks all words, comparing their xts with this.
: >NAME ( xt -- nt|0 )
  (LATEST) @
  BEGIN ?dup WHILE ( xt nt )
    2dup (>cfa) = IF nip EXIT THEN
    (name>link)
  REPEAT
  drop 0
;

\ This is married to the structure of a dictionary header, and the dictionary
\ table in the portable VM. If either of those change, this needs to change too.
\ TODO Should this be hiding the hidden words? Internal words?
: WORDS ( -- )
  (LATEST) @
  BEGIN ?dup WHILE
    dup name>string type cr
    (name>link)
  REPEAT
;

\ TOOLS EXT word set

: AHEAD ( -- ) ( C: -- orig ) ['] (branch) compile, HERE 0 , ; IMMEDIATE

: SYNONYM ( "<spaces>newname" "<spaces> oldname" -- )
  CREATE IMMEDIATE
  (latest) @ cell+ dup @ 256 or swap ! \ hide the new word
  ' \ grabs the next string in the input
  , \ compile oldname into the body
  (latest) @ cell+ dup @ 256 invert and swap ! \ reveal the new word again
  DOES>
    @ state @ 0= over cell+ @ 512 and or
    IF execute ELSE compile, THEN
;

\ N>R and NR> just put the elements on the return stack in reverse order,
\ which is the most convenient.
\ Remember that the return address for N>R and NR> is on top and needs to be
\ preserved.
VARIABLE (saved-return-address)
: N>R ( i*n +n -- ) ( R: -- j*n +n )
  R> (saved-return-address) !
  dup ( +n +n )
  BEGIN ?dup WHILE rot >R 1- REPEAT ( +n )
  >R
  (saved-return-address) @ >R
;

: NR> ( -- i*n +n ) ( R: j*n +n -- )
  R> (saved-return-address) !
  R> dup ( +n i )
  BEGIN ?dup WHILE 1- R> -rot ( val +n i ) REPEAT
  ( ... +n )
  (saved-return-address) @ >R
;


: [DEFINED] ( "<spaces>name" -- defined? ) bl word find nip 0<> ; IMMEDIATE
: [UNDEFINED] ( "<spaces>name" -- undefined? ) bl word find nip 0= ; IMMEDIATE

VARIABLE ([if]-depth)

: [ELSE] ( -- )
  1 BEGIN
    BEGIN bl word count dup WHILE
      2dup S" [IF]" compare 0= IF
        2drop 1+
      ELSE
        2dup S" [ELSE]" compare 0= IF
          2drop 1- dup IF 1+ THEN
        ELSE
          S" [THEN]" compare 0= IF
            1-
          THEN
        THEN
      THEN ?dup 0= IF EXIT THEN
    REPEAT 2drop
  REFILL 0= UNTIL
  drop
; IMMEDIATE

: [THEN] ; IMMEDIATE

: [IF] ( ? -- )
  0= IF POSTPONE [ELSE] THEN
  ; IMMEDIATE


: FIND-NAME ( c-addr u -- nt|0 )
  (LATEST) @ BEGIN dup WHILE ( c-addr u nt )
    >R 2dup R@ name>string compare-ic 0= IF
      2drop R> EXIT THEN
    R> (name>link)
  REPEAT
  >R 2drop R> ( 0 )
;

: .S ( -- )
  \ First bit: _<D>_
  space [char] < emit   depth S>D <# #S #> type  [char] > emit space
  depth 0= IF EXIT THEN
  0 depth 2 - DO i pick . -1 +LOOP
;

