\ File word set

: BIN 4 or ;
: R/O 1 ;
: W/O 2 ;
: R/W 3 ;

\ Possible cases:
\ - If we parsed some content:
\   - Check the last value parsed. If it was ), done.
\   - If not, we're at EOL so refill and loop.
\ - Parse length of 0:
\   - If the source length is 0, blank line; refill and loop.
\   - Source length non-zero, check previous. if ), done. If not, refill.
: (
  \ Fall back to the original if this isn't a file.
  source-id 0 <= IF 41 parse 2drop EXIT THEN
  BEGIN
    41 parse nip ( len )
    IF \ Parsed something. Check if last character was ')'
      >IN @ 1- source drop + c@   41 = IF EXIT THEN
    ELSE \ Empty parse. Check if this line is empty.
      source 0=   >IN @ 0=   or IF ( c-addr )
        drop refill 0= IF EXIT THEN \ Refill, bail if EOF.
      ELSE
        \ Nonempty line, so check last character parsed.
        >IN @ 1- + c@   41 = IF EXIT THEN
        refill 0= IF EXIT THEN
      THEN
    THEN
  AGAIN
; IMMEDIATE


: INCLUDED ( i*x c-addr u -- j*x )
  2dup r/o open-file ABORT" Could not open file" >R
  \ Record this file in the inclusion names list.
  (included-file-list) @   here (included-file-list) !
  ( c-addr u list-head    R: fd )
  ,   dup ,   here swap move align ( R: fd )
  R> include-file
;

: INCLUDE ( i*x "name" -- j*x ) parse-name included ;

\ NB: REQUIRE(D) files should have no net stack impact; INCLUDE(D) ones can.
: REQUIRED ( i*x c-addr u -- i*x )
  \ Check if this file has been loaded before.
  (included-file-list) @
  BEGIN ?dup WHILE
    >R 2dup ( c-addr u c-addr u   R: *entry )
    R@ cell+ dup cell+ swap @ ( c-addr1 u1 c-addr1 u1 c-addr2 u2   R: *entry )
    compare 0= IF R> drop 2drop ( ) EXIT THEN \ Already done, bail.
    R> @ ( c-addr u *entry' )
  REPEAT
  ( c-addr u )
  included
;

: REQUIRE ( i*x "name" -- i*x ) parse-name required ;

