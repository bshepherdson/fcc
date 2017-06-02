\ Sets up to run the platform-specific output.

: (prep) 1024 1024 * allocate ABORT" Failed to allocate asm output buffer." ;
(prep) CONSTANT asm-buffer
VARIABLE asm-ptr
asm-buffer asm-ptr !

\ Writes to the assembly without adding a newline.
: ,asm ( c-addr u -- )  dup >R   asm-ptr @ swap move   r> asm-ptr +! ;

\ Writes a single character.
: asm-emit ( ch -- ) asm-ptr @ c!   1 asm-ptr +! ;

\ Writes a newline.
: asm-nl ( -- ) 10 asm-emit ;

\ Writes a full line of assembly, adding a newline after it.
: ,asm-l ( c-addr u -- ) ,asm   asm-nl ;


