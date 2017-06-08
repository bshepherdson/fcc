\ Fundamental Ops for FCC's portable engine: Linux x86_64.
\ This targets GCC's flavour of assembly.

\ This is a portable Forth file that declares the macros needed by the portable
\ FCC engine. These are called while the engine generator is running. The emit
\ assembly instructions as strings into a buffer, and consume and return
\ generation-time values such as which scratch register to pop into.

\ There are four flavours of x86 chips that we care about: 32- and 64-bit, with
\ assembly instructions having their in both directions.
\ In GCC on Linux, the movq %rax, %rbx moves rax to rbx.
\ On Mac, it's rbx into rax.

\ Aside from these obvious wrinkles, the instructions are nearly all the same.
\ So we abstract them with an x86-family helper file, which we load after
\ configuring the basics.

\ With GCC's gas assembler syntax, sources are on the left and destinations on
\ the right, so we swap the arguments before emitting them.
: prep-binop-args ( src dst -- rhs lhs ) swap ;

\ For x86_64, the standard opcode suffix is 'q', for quad-word.
: width-suffix ( -- ch ) [char] q ;
\ Likewise, the standard register prefix is 'r'.
: register-prefix ( -- ch ) [char] r ;

\ Declares a cell-sized block in the assembler.
: cell-directive ( -- c-addr u ) S" .quad" ;

\ The size of a cell on the target.
: /target-cell ( -- u ) 8 ;

\ How to spell the PC reference used for indexing globals.
: (pc) ( -- c-addr u ) S" (%rip)" ;

\ The sign-extension operand for cell to double-cell.
\ This is cqto on 64-bit and cltq on 32-bit, I think.
: sign-extend ( -- c-addr u ) S" cqto" ;


\ BEGIN SHARED X86 PORTIONS
\ TODO Extract this into an actual helper file.

\ Registers are given by these helpers, which are structures.
begin-structure operand
  field: op.type   \ xt that handles expanding this operand.
  field: op.base   \ "base" data. For registers, the index into the table.
                   \ For literals, the literal itself.
  field: op.extra  \ "extra" data. For indexing memory, the offset in cells.
end-structure

CREATE regs 16 cells allot

: reg> ( reg -- c-addr u ) 2 * cells regs + 2@ ;
: reg, ( reg -- ) reg> ,asm ;

\ This order is important; several things (division, sign-extension, etc.)
\ rely on the registers being in this order.
: (prep-regs)
  S" ax" regs            2!
  S" cx" regs  2 cells + 2!
  S" dx" regs  4 cells + 2!
  S" si" regs  6 cells + 2!
  S" di" regs  8 cells + 2!
  S" sp" regs 10 cells + 2!
  S" bx" regs 12 cells + 2!
  S" bp" regs 14 cells + 2!
;
(prep-regs)


\ Indices for the stack and instruction pointers, which are kept in registers.
: sp ( -- reg ) 6 ;
: ip ( -- reg ) 7 ;


: +lit>  (  u -- c-addr u ) s>d <# #s #> ;
: -lit> ( -n -- c-addr u ) negate   s>d <# #s   [char] - hold #> ;
: lit>  ( n -- c-addr u ) dup 0 < IF -lit> ELSE +lit> THEN ;


\ Operand emitters.
: ,operand ( operand -- )  dup op.type @ execute ;

\ Emits a simple register operand.
: emit-reg ( operand -- )
  [char] %        asm-emit
  register-prefix asm-emit
  op.base @       reg,
;

\ Emits a memory access at a register.
: emit-mem ( operand -- )
  [char] ( asm-emit   emit-reg   [char] ) asm-emit ;

\ Emits an indexed memory access at a register.
: emit-mem-indexed ( operand -- )
  dup op.extra @   lit> ,asm   emit-mem ;


: emit-literal ( operand -- )
  [char] $ asm-emit   op.base @ lit> ,asm ;

\ Raw emitter - base is the length, extra is the string.
: emit-raw ( operand -- )
  dup op.extra @   swap op.base @   ( c-addr u )
  ,asm
;


: emit-chain ( operand -- ) dup op.base @ ,operand   op.extra @ ,operand ;



\ Constructors for operands.
: mkop ( xt -- operand )
  operand allocate abort" Failed to allocate"
  swap over op.type !
;

: mkop-base ( base xt -- operand ) mkop   swap over op.base ! ;

: $lit  (   x -- operand ) ['] emit-literal mkop-base ;
: reg   ( reg -- operand ) ['] emit-reg     mkop-base ;
: (reg) ( reg -- operand ) ['] emit-mem     mkop-base ;

: mkop-extra ( base extra xt -- operand )
  >r swap r>   mkop-base   tuck op.extra ! ;

: x(reg) ( offset reg -- operand ) ['] emit-mem-indexed mkop-extra ;
: raw    ( c-addr u -- operand )   ['] emit-raw         mkop-extra ;

\ Chains two operands into one.
\ This works by using base of the new operand to point to the first/bottom and
\ extra to point to the second/top.
: chain ( operand operand -- operand ) ['] emit-chain   mkop-extra ;



: binop-raw ( src dst c-addr u -- )
  ,asm
  width-suffix asm-emit
  S"   " ,asm
  prep-binop-args
  ,operand
  S" ,  " ,asm
  ,operand
  asm-nl
;

: op   ( src dst "op" -- ) parse-name binop-raw ;
: [op] ( src dst "op" -- )
  parse-name
  ['] (dostring) compile,  dup c, ( c-addr u )
  here swap ( c-addr here u )
  dup >R
  move ( )
  R> allot
  align
  ['] binop-raw compile,
; IMMEDIATE

\ Fundamental Definitions
\ ===================================

\ Data stack: rbx
\ Return stack: memory
\ Instruction pointer: rbp

: #scratch ( -- u ) 4 ; \ TODO Figure out scratch registers.

: target-cells ( u -- u ) /target-cells * ;

: sp-delta ( u -- src dst ) target-cells $lit   sp reg ;
: sp+ ( u -- ) sp-delta [op] add ;
: sp- ( u -- ) sp-delta [op] sub ;

\ Since these are part of the visible engine, they expect register numbers, not
\ fully-formed operands.
: peek-at ( rd index -- ) sp swap x(reg)   swap reg   [op] mov ;
: peek    ( rd -- )       sp  (reg)   swap reg   [op] mov ;
: peek!   ( rd -- )       reg         sp (reg)   [op] mov ;

: pop  ( rd -- )
  sp (reg)   swap reg     [op] mov
  /target-cell $lit       sp reg   [op] add
;
: push ( src -- )
  /target-cell $lit       sp reg   [op] sub
  reg   sp (reg)             [op] mov
;

: pop2 ( rd2 rd1 -- )
  sp (reg)   swap  reg   [op] mov
  /target-cell sp x(reg)   swap reg   [op] mov
  2 target-cells $lit   sp reg   [op] add
;


: rsp ( -- operand )  S" rsp" raw   (pc) raw   chain ;

\ Dealing with RSP.
: poprsp ( rd rtmp -- )
  rsp
  over reg ( rd rtmp src dst ) [op] mov
  (reg) swap reg ( tmp dst )   [op] mov
  /target-cell $lit    rsp    [op] add
;

\ Register numbers, not operands.
: pushrsp ( rs rtmp -- )
  rsp   over reg   [op] mov
  /target-cell $lit    over reg   [op] sub
  dup reg   rsp   [op] mov
  >r reg r>   (reg) [op] mov   \ Actually saves the value.
;

: pushrsp-ip ( -- ) ip   0   pushrsp ;


\ Dereferences a pointer into a register.
: read  ( rd ptr -- ) (reg)   swap reg [op] mov ;

\ Stores a value into a pointer held in a register.
: write ( rs ptr -- ) >r reg r> (reg)  [op] mov ;

: read-indexed ( rd ptr i -- )  swap x(reg)   swap reg   [op] mov ;
: write-indexed ( rs ptr i -- ) swap x(reg)   >r reg r>  [op] mov ;

: cread ( rd ptr -- ) (reg) swap reg [op] movzb ;
: cwrite ( rs ptr -- )
  swap ABORT" x86_64 can only cwrite with rs = 0"
  >r   S" %al" raw   r> (reg)  S" movb" binop-raw
;


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

  S" header_" ,asm   ,word-label   S" :" ,asm-l

  cell-directive ,asm
      last-word-len @ IF \ Last word is defined, put header_last_word in.
          S" header_" ,asm   last-word-buffer last-word-len @ ,asm-l
      ELSE S" 0" ,asm-l THEN

  cell-directive ,asm   word-name 2@ lit> ,asm-l drop
  cell-directive ,asm S"  .str_"  ,asm   ,word-label-l
  cell-directive ,asm S"  .code_" ,asm   ,word-label-l
  \ TODO Keys would go here, if we were declaring those.

  S"   .text" ,asm-l
  S"   .globl  code_" ,asm  ,word-label-l
  S" code_" ,asm   ,word-label S" :" ,asm-l

  \ Copy the label into the last-word buffer.
  word-label 2@   last-word-buffer swap move
  word-label 2@   last-word-len ! drop
;


\ Writes the NEXT macro.
: ,next ( -- )
  ip (reg)           0 reg   [op] mov
  /target-cell $lit   ip reg  [op] add
  S"   jmp    *" ,asm   0 reg ,operand  asm-nl
;

\ Called at the end of each primitive definition.
: ;WORD ( -- ) ,next ;

\ Just jumps to reg 0.
: ;WORD-RAW ( -- ) S"   jmp    *" ,asm   0 reg reg> ,operand asm-nl ;




\ Handles a two-register binary operation whose name is given.
: binop-rr ( rs rd c-addr u ) >r >r >r reg r> reg r> r> binop-raw ;

: plus   ( rs rd -- ) S" add"  binop-rr ;
: minus  ( rs rd -- ) S" sub"  binop-rr ;
: times  ( rs rd -- ) S" imul" binop-rr ;

: op-and ( rs rd -- ) S" and"  binop-rr ;
: op-or  ( rs rd -- ) S" or"   binop-rr ;
: op-xor ( rs rd -- ) S" xor"  binop-rr ;


: (shift) ( c-addr u -- )
  sp (reg)           1  reg    [op] mov
  /target-cell $lit   sp reg    [op] add
  sp (reg)           3  reg    [op] mov
  S" %cl" raw        3  reg    2swap binop-raw
  3 reg              sp (reg)  [op] mov
;
: op-lshift ( -- ) S" salq" (shift) ;
: op-rshift ( -- ) S" shrq" (shift) ;


\ Loads the *address* of the global variable whose name is given into the given
\ register.
: ,*var ( dst c-addr u -- )
  raw   (pc) raw   chain    swap    [op] mov ;


\ Specialized funops for division, since those vary wildly.
: (div-signed) ( required -- )
  sp (reg)   3 reg   [op] mov
  /target-cell $lit   sp reg   [op] add
  sp (reg)   0 reg   [op] mov
  sign-extend   ,asm-l
  S" idiv" ,asm   width-suffix asm-emit   32 asm-emit   3 reg ,operand asm-nl
  ( required )   sp (reg)   [op] mov   \ Grab the quotient or remainder.
;
: div ( -- ) 0 reg (div-signed) ; \ %rax/eax is the quotient.
: mod ( -- ) 2 reg (div-signed) ; \ %rdx/edx is the remainder.

: (div-unsigned) ( required -- )
  sp (reg)   3 reg   [op] mov
  /target-cell $lit   sp reg   [op] add
  sp (reg)   0 reg   [op] mov
  0 $lit   2 reg   [op] mov
  S" div" ,asm   width-suffix asm-emit   32 asm-emit   3 reg ,operand asm-nl
  ( required )   sp (reg)   [op] mov   \ Grab the quotient or remainder.
;
: udiv ( -- ) 0 reg (div-unsigned) ;
: umod ( -- ) 2 reg (div-unsigned) ;



\ Branches and conditionals.
\ Labels are represented as numbers, and rendered in the code with ".Lnnn".

VARIABLE next-label    1 next-label !

: label ( label -- operand )  S" .L" raw   lit> raw   chain ;
: mklabel ( -- label ) next-label @    1 next-label +! ;
: resolve ( label -- ) S" .L" ,asm   lit> ,asm   S" :" ,asm-l ;

\ Renders a cmpq and a conditional jump.
: (op-branch) ( r0 r1 label c-addr u -- )
  >r >r >r >r reg r> reg ( lhs rhs ) [op] cmp
  r> label   r> r>   unop-raw ( )
;

: jlt ( r0 r1 label -- ) S" jl" (op-branch) ;
: jlt-unsigned ( r0 r1 label -- ) S" jb" (op-branch) ;
: jeq ( r0 r1 label -- ) S" je" (op-branch) ;
: jne ( r0 r1 label -- ) S" jne" (op-branch) ;

\ Jump when zero, since that's a common operation.
: jz  ( r0 label -- )
  >r   reg dup [op] test
  S" je" ,asm r> label ,operand asm-nl
;

\ Unconditional jump.
: jmp ( label -- ) S"   jmp    " ,asm   label ,operand   asm-nl ;


\ Forth's own branch operations. These are common and tricky, so they're
\ standalone funops.
: op-branch ( -- )
  ip (reg)   0 reg   [op] mov
  0  (reg)   ip reg  [op] add
;

\ This one is the tricky one. The basic pattern is:
\ pop, test if 0. Jump if nonzero. When 0, put the offset (at ip) into rax.
\ If nonzero, put the cell size into rax.
\ Then add rax to ip.
: op-zbranch ( -- )
  sp (reg)   0 reg   [op] mov
  /table-cell $lit    sp reg   [op] add
  0 reg   0 reg   [op] test
  mklabel dup label ( false false-op )
  S" jne" unop-raw  ( false )
  ip (reg)   0 reg   [op] mov
  mklabel ( false true )
  dup jmp   ( false true )
  swap resolve ( true )
  /table-cell $lit   0 reg   [op] mov
  resolve ( )
  0 reg   ip reg   [op] add
;


\ Loads the literal into the register.
: lit  ( lit reg -- ) >r $lit r> reg [op] mov ;
: -lit ( lit reg -- ) lit ;


\ Zeroes the register. Often more efficient with alternative instructions.
\ x86_64 it just XORs with itself.
: zero ( reg -- ) reg dup [op] xor ;

\ Inverts all the bits in the given register.
: op-invert ( reg -- )  -1 -lit   swap reg   [op] xor ;



\ Function calls to C functions.
\ Prepares for a function with N arguments.
: args ( n -- ) drop ;

\ Indirected, these point to registers by index.
CREATE (args)    4 , 3 , 2 , 1 ,  \ rdi, rsi, rdx and rcx

\ Returns the reg number for the nth arg.
: arg ( arg -- reg ) cells (args) + @ ;
: >arg ( reg arg -- ) >r reg r>   arg reg   [op] mov ;
: pop-arg ( arg -- ) arg pop ;

: call ( c-addr u -- ) S"   call   " ,asm ,asm-l ;

: return-void ( -- ) [op] ret ;

\ Sets the return value to that held in reg.
: return ( reg -- )
  ?dup IF reg   0 reg   [op] mov THEN
  return-void
;



\ Input buffer handling
\ Register is a temporary for platforms that need it; x86_64 discards it.
: (input-index-args) ( -- src dst )
  1 $lit
  S" inputIndex" raw   (pc) raw   chain
;
: input-index++ ( reg -- ) drop (input-index-args)   [op] add ;
: input-index-- ( reg -- ) drop (input-index-args)   [op] sub ;

\ Puts the pointer to the current input source structure into the register.
: input-source ( rd -- )
  reg
  S" inputIndex" raw   (pc) raw   chain   over   [op] mov
  5 $lit   over   [op] sal
  S" $inputSources" raw    swap   [op] add
;

\ Offsets into the structure. These are the same across platforms, just adjusted
\ for the cell size.
: src-length ( -- offset )  0 ;
: src-index  ( -- offset )  1 target-cells ;
: src-type   ( -- offset )  2 target-cells ;
: src-buffer ( -- offset )  3 target-cells ;


\ Unique instruction only found at the end of EVALUATE.
: eval-jmp ( -- ) S"   jmp    quit_inner" ,asm-l ;

