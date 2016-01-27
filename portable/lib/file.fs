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
