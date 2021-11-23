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


\ Given a string naming a file, works backwards to the last / in the path.
\ Does NOT include the /
\ UNIX-ONLY
: (dirname) ( c-addr u -- c-addr u )
  BEGIN dup WHILE
    2dup + c@ '/' = IF EXIT THEN \ Found it, so bail.
    1-
  REPEAT
;

\ Given two strings, a directory and a ./ relative path, combines them into a
\ newly allocated string.
: (combine-paths) ( c-addr1 u1 c-addr2 u2 -- c-addr u )
  1- >R 1+ R>        \ Drop the leading .
  2 pick over + dup allocate ABORT" Failed to allocate string"
  ( ca1 u1 ca2 u2 u1+u2 caNew )
  2dup >R >R          ( ca1 u1 ca2 u2 u1+u2 caNew    R: caNew u1+u2 )
  nip -rot >R >R      ( ca1 u1 caNew   R: caNew u1+u2 u2 ca2 )

  \ Copy the first string to it.
  2dup + >R           ( ca1 u1 caNew   R: caNew u1+u2 u2 ca2 caNew+u1 )
  swap move           ( R: caNew u1+u2 u2 ca2 caNew+u1 )

  R> R> swap R>       ( ca2 caNew+u1 u2   R: caNew u1+u2 )
  move
  R> R> swap          ( caNew u1+u2 )
;


\ Given a relative path, looks up the current SOURCE-ID in the included file
\ list and then appends the given path to that file's containing directory.
: (relative-include) ( c-addr u -- c-addr u )
    (included-file-list) @ BEGIN ?dup WHILE
      \ Each included file is [link, FILE*, length, str...] so we compare the
      \ FILE* against the current source-id until we find a match.
      dup cell+ @   source-id   = IF  ( file-list )
        2 cells +   dup cell+   swap @ ( c-addr1 u1 c-addr2 u2 )
        (dirname) 2swap (combine-paths)
        0 \ Loop ender
      ELSE
        @
      THEN
    REPEAT
;

: INCLUDED ( i*x c-addr u -- j*x )
  over dup c@ '.' = swap 1+ c@ '/' = and IF \ Relative path handling
    (relative-include)
  THEN
  2dup r/o open-file ABORT" Could not open file" >R
  \ Record this file in the inclusion names list.
  (included-file-list) @   here (included-file-list) !
  ( c-addr u list-head    R: fd )
  ,   r@ ,   dup ,   here swap    dup allot    move align ( R: fd )
  R> include-file
;

: INCLUDE ( i*x "name" -- j*x ) parse-name included ;

\ NB: REQUIRE(D) files should have no net stack impact; INCLUDE(D) ones can.
: REQUIRED ( i*x c-addr u -- i*x )
  \ Check if this file has been loaded before.
  (included-file-list) @
  BEGIN ?dup WHILE
    >R 2dup ( c-addr u c-addr u   R: *entry )
    R@ 2 cells + dup cell+ swap @ ( c-addr1 u1 c-addr1 u1 c-addr2 u2   R: *entry )
    compare 0= IF R> drop 2drop ( ) EXIT THEN \ Already done, bail.
    R> @ ( c-addr u *entry' )
  REPEAT
  ( c-addr u )
  included
;

: REQUIRE ( i*x "name" -- i*x ) parse-name required ;

