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

: lit> ( u -- c-addr u ) s>d <# #s #> ;


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
: pop2 ( r1 r2 -- ) >r reg> r> reg>   .s cr pop2-raw ;


: push-raw ( c-addr u -- )
  S"   subq   $8, %rbx" ,asm-l
  S"   movq   " ,asm   ,asm   S" , (%rbx)" ,asm-l
;
: push ( reg -- ) reg> push-raw ;



\ Declares a new primitive word, with its label and Forth name.
\ Expects a unique number, which is defined in the engine so that they can be
\ universal and shared. These are currently dropped, but they can be used for
\ superinstruction processing.
2VARIABLE last-word   0 0 last-word 2!
2VARIABLE word-label
2VARIABLE word-name

: ,label   ( -- ) word-label 2@ ,asm ;
: ,label-l ( -- ) word-label 2@ ,asm-l ;

: WORD: ( number "label name" -- )
  parse-name   word-label 2!
  parse-name   word-name  2!
  drop \ TODO Use the key numbers properly.

  S"   .globl  header_" ,asm   ,label-l
  S"   .section    .rodata" ,asm-l
  S" .str_" ,asm   ,label   S" :" ,asm-l
  S"   .string " ,asm
      [char] " asm-emit
      word-name 2@ ,asm
      [char] " asm-emit
      0 0 ,asm-l
  S"   .data" ,asm-l
  S"   .align 32" ,asm-l
  S"   .type   header_" ,asm   ,label   S" , @object" ,asm-l
  S"   .size   header_" ,asm   ,label   S" , 32" ,asm-l

  S" header_" ,asm   ,label   S" :" ,asm-l
  S"   .quad " ,asm
      last-word 2@ dup IF \ Last word is defined, put header_last_word in.
          S" header_" ,asm  ,asm-l
      ELSE 2drop S" 0" ,asm-l THEN

  S"   .quad " ,asm   word-name 2@ lit> ,asm-l drop
  S"   .quad .str_" ,asm  ,label-l
  S"   .quad .code_" ,asm  ,label-l
  \ TODO Keys would go here, if we were declaring those.

  S"   .text" ,asm-l
  S"   .globl  code_" ,asm  ,label-l
  S"   .type  code_" ,asm  ,label   S" , @function" ,asm-l
  S" code_" ,asm   ,label S" :" ,asm-l

  word-label 2@   last-word 2!
;


\ Writes the NEXT macro.
: ,next ( -- )
  S"   movq   (%rbp), %rax" ,asm-l
  S"   addq   $8, %rbp" ,asm-l
  S"   jmp    *%rax" ,asm-l
;

\ Called at the end of each primitive definition.
: ;WORD ( -- ) ,next ;


