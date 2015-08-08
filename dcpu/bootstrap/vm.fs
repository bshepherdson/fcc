\ Uses the assembler from dcpu/bootstrap/asm.fs to build a DCPU-16 Forth.
\ Overall design: Indirect threading, with literals inline.
\ Registers:
\ - J holds the return-stack pointer.
\ - I holds the next-codeword pointer.
\ - SP holds the data stack pointer.
\ Both stacks are full-descending. Return stack lives at the top of memory,
\ data stack below it. 1K reserved for the return stack.

\ Main routine right at the top:
\ Initialize the stack pointers,


\ START HERE: Figure out forward references, and then use one here for main.


: NEXT,
  [ri] ra set, \ A now points at the codeword. That should be loaded into PC.
  [ra] pc set,
;

\ Holds the DCPU address of the most-recently-compiled word.
VARIABLE last-word
0 last-word !

\ Assembles the header for a word with the given name.
\ Word headers look like this:
\ - Link pointer.
\ - Name length/metadata
\ - Name.... (Unpacked, one character per word. No terminator.)
\ - Codeword (PC should be set to this value.)
\ - code....
: :WORD
  DH   last-word @ h,   last-word ! ( )
  parse-name ( c-addr u )
  dup h,
  BEGIN dup WHILE 1- swap dup c@ h, char+ swap REPEAT ( 0 0 )
  2drop ( )
  DH 1+ h, \ Write the address of the next word into this word.
  \ Now we're ready for the assembly code to be added.
  \ Note that we don't actually enter compiling mode here.
;

\ Does nothing, just there for symmetry.
: ;WORD ;

