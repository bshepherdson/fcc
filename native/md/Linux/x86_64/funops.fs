\ Fundamental Ops for FCC's portable engine: Linux x86_64.
\ This targets GCC's flavour of assembly.

\ This is a portable Forth file that declares the macros needed by the portable
\ FCC engine. These are called while the engine generator is running. The emit
\ assembly instructions as strings into a buffer, and consume and return
\ generation-time values such as which scratch register to pop into.



\ Fundamental Definitions
\ ===================================

\ Data stack: rbx
\ Return stack: memory
\ Instruction pointer: rbp

\ Regs holds address-name pairs for the registers.
CREATE regs 8 cells allot

: reg> ( reg -- c-addr u ) 2 * cells regs + 2@ ;
: reg, ( reg -- ) reg> ,asm ;

: (prep-regs)
  S" %rax" regs           2!
  S" %rcx" regs 2 cells + 2!
  S" %rdx" regs 4 cells + 2!
  S" %r12" regs 6 cells + 2!
;
(prep-regs)

: #scratch ( -- u ) 4 ; \ TODO Figure out scratch registers.

: lit>  (  u -- c-addr u ) s>d <# #s #> ;
: -lit> ( -n -- c-addr u ) negate   s>d <# #s   [char] - hold #> ;


: sp+ ( u -- ) 8 * S"   addq   $" ,asm   lit> ,asm  S" , %rbx" ,asm-l ;
: sp- ( u -- ) 8 * S"   subq   $" ,asm   lit> ,asm  S" , %rbx" ,asm-l ;

: peek-at-raw ( c-addr u index -- )
  S"   movq   " ,asm   8 * lit> ,asm   S" (%rbx), " ,asm   ,asm-l
;
: peek-raw ( c-addr u -- ) S"   movq   (%rbx), " ,asm   ,asm-l ;
: peek ( reg -- ) reg> peek-raw ;

: pop-raw ( c-addr u -- )
  peek-raw
  S"   addq   $8, %rbx" ,asm-l
;
: pop ( reg -- ) reg> pop-raw ;


\ The registers are given in the same order as they appear in stack diagrams:
\ Lower in the stack is lower in the stack.
: pop2-raw ( c-addr u c-addr u -- ) peek-raw   1 peek-at-raw   2 sp+ ;
: pop2 ( r1 r2 -- ) >r reg> r> reg>   pop2-raw ;


: push-raw ( c-addr u -- )
  S"   subq   $8, %rbx" ,asm-l
  S"   movq   " ,asm   ,asm   S" , (%rbx)" ,asm-l
;
: push ( reg -- ) reg> push-raw ;



\ Declares a new primitive word, with its label and Forth name.
\ Expects a unique number, which is defined in the engine so that they can be
\ universal and shared. These are currently dropped, but they can be used for
\ superinstruction processing.
CREATE last-word-buffer 64 allot
VARIABLE last-word-len   0 last-word-len !

2VARIABLE word-label
2VARIABLE word-name

: ,word-label   ( -- ) word-label 2@ ,asm ;
: ,word-label-l ( -- ) word-label 2@ ,asm-l ;

: WORD: ( number "label name" -- )
  parse-name   word-label 2!
  parse-name   word-name  2!
  drop \ TODO Use the key numbers properly.

  S"   .globl  header_" ,asm   ,word-label-l
  S"   .section    .rodata" ,asm-l
  S" .str_" ,asm   ,word-label   S" :" ,asm-l
  S"   .string " ,asm
      [char] " asm-emit
      word-name 2@ ,asm
      [char] " asm-emit
      asm-nl

  S"   .data" ,asm-l
  S"   .align 32" ,asm-l
  S"   .type   header_" ,asm   ,word-label   S" , @object" ,asm-l
  S"   .size   header_" ,asm   ,word-label   S" , 32" ,asm-l

  S" header_" ,asm   ,word-label   S" :" ,asm-l
  S"   .quad " ,asm
      last-word-len @ IF \ Last word is defined, put header_last_word in.
          S" header_" ,asm   last-word-buffer last-word-len @ ,asm-l
      ELSE S" 0" ,asm-l THEN

  S"   .quad " ,asm   word-name 2@ lit> ,asm-l drop
  S"   .quad .str_" ,asm  ,word-label-l
  S"   .quad .code_" ,asm  ,word-label-l
  \ TODO Keys would go here, if we were declaring those.

  S"   .text" ,asm-l
  S"   .globl  code_" ,asm  ,word-label-l
  S"   .type  code_" ,asm  ,word-label   S" , @function" ,asm-l
  S" code_" ,asm   ,word-label S" :" ,asm-l

  \ Copy the label into the last-word buffer.
  word-label 2@   last-word-buffer swap move
  word-label 2@   last-word-len ! drop
;


\ Writes the NEXT macro.
: ,next ( -- )
  S"   movq   (%rbp), %rax" ,asm-l
  S"   addq   $8, %rbp" ,asm-l
  S"   jmp    *%rax" ,asm-l
;

\ Called at the end of each primitive definition.
: ;WORD ( -- ) ,next ;





: binop-rr ( rd rs c-addr u -- )
  >r >r   >r reg> r>   reg> r> r>
  S"   " ,asm ,asm   S"   " ,asm ,asm S" , " ,asm ,asm-l
;

: plus   ( rd rs -- ) S" addq"  binop-rr ;
: minus  ( rd rs -- ) S" subq"  binop-rr ;
: times  ( rd rs -- ) S" imulq" binop-rr ;

: op-and ( rd rs -- ) S" andq"  binop-rr ;
: op-or  ( rd rs -- ) S" orq"   binop-rr ;
: op-xor ( rd rs -- ) S" xorq"  binop-rr ;


: (shift) ( c-addr u -- )
  S"   movq   (%rbx), %rcx" ,asm-l
  S"   addq   $8, %rbx" ,asm-l
  S"   movq   (%rbx), %rsi" ,asm-l
  S"   " ,asm ,asm S"    %cl, %rsi" ,asm-l
  S"   movq   %rsi, (%rbx)" ,asm-l
;
: op-lshift ( -- ) S" salq" (shift) ;
: op-rshift ( -- ) S" shrq" (shift) ;



\ Loads the *address* of the global variable whose name is given into the given
\ register.
: ,*var ( reg c-addr u -- )
  S"   movq   $" ,asm ,asm   reg> S" , " ,asm ,asm-l
;


\ Specialized funops for division, since those vary wildly.
: (div-signed) ( c-addr u -- )
  S"   movq   (%rbx), %rsi" ,asm-l
  S"   addq   $8, %rbx" ,asm-l
  S"   movq   (%rbx), %rax" ,asm-l
  S"   cqto" ,asm-l
  S"   idivq  %rsi" ,asm-l
  S"   movq   " ,asm   ,asm  S" , (%rbx)" ,asm-l
;
: div ( -- ) S" %rax" (div-signed) ;
: mod ( -- ) S" %rdx" (div-signed) ;

: (div-unsigned) ( -- )
  S"   movq   (%rbx), %rsi" ,asm-l
  S"   addq   $8, %rbx" ,asm-l
  S"   movq   (%rbx), %rax" ,asm-l
  S"   movl   $0, %edx" ,asm-l
  S"   divq   %rsi" ,asm-l
  S"   movq   " ,asm  ,asm  S" , (%rbx)" ,asm-l
;
: udiv ( -- ) S" %rax" (div-unsigned) ;
: umod ( -- ) S" %rdx" (div-unsigned) ;



\ Branches and conditionals.
\ Labels are represented as numbers, and rendered in the code with ".Lnnn".

VARIABLE next-label    1 next-label !

: ,label ( label -- )  S" .L" ,asm   lit> ,asm ;
: mklabel ( -- label ) next-label @    1 next-label +! ;
: resolve ( label -- ) ,label   S" :" ,asm-l ;

\ Renders a cmpq and a conditional jump.
: (branch) ( r0 r1 label c-addr u -- )
  >r >r >r swap
  S"   cmpq " ,asm reg> ,asm S" , " ,asm reg> ,asm-l
  r> r> r> S"   " ,asm ,asm   S"    " ,asm ,label asm-nl
;

: jlt ( r0 r1 label -- ) S" jl" (branch) ;
: jlt-unsigned ( r0 r1 label -- ) S" jb" (branch) ;
: jeq ( r0 r1 label -- ) S" je" (branch) ;

\ Unconditional jump.
: jmp ( label -- ) S"   jmp    " ,asm ,label asm-nl ;



\ Loads the literal into the register.
: lit ( lit reg -- )
  swap S"   movq   $" ,asm lit> ,asm S" , " ,asm reg> ,asm-l ;
: -lit ( lit reg -- )
  swap S"   movq   $" ,asm -lit> ,asm S" , " ,asm reg> ,asm-l ;

\ Zeroes the register. Often more efficient with alternative instructions.
\ x86_64 it just XORs with itself.
: zero ( reg -- )
  reg> 2dup
  S"   xorq   " ,asm ,asm S" , " ,asm ,asm-l
;

\ Inverts all the bits in the given register.
: op-invert ( reg -- )  S" xorq   $-1, " ,asm reg> ,asm-l ;


