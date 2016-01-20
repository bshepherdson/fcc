\ File word set

: BIN 4 or ;
: R/O 1 ;
: W/O 2 ;
: R/W 3 ;

: (
  \ Fall back to the original if this isn't a file.
  source-id 0 <= IF 41 parse 2drop EXIT THEN
  BEGIN
    41 parse ( c-addr u )
    \ Returns 0 0 if there's nothing to read - so refill.
    nip 0= IF
      \ Nothing found, so refill.
      refill 0= IF EXIT THEN
    ELSE
      \ Found something; check if it ended with the terminator.
      >IN @ 1- source drop + c@
      41 = IF EXIT THEN
    THEN
  AGAIN
; IMMEDIATE


