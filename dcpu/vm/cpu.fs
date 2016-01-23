\ Virtual machine for the DCPU-16, written in FCC's portable Forth system.
\ Should run on anything with at least 32-bit cells, any endianness.
\ DCPU binaries are treated as big-endian, which is standard.

\ Core system
$10000 ARRAY (mem)

$ffff CONSTANT dword-mask
: lo ( u -- dw ) dword-mask and ;
: hi ( u -- dw ) 16 rshift lo ;


: d@ ( d-addr -- dw ) (mem) @ ;
: d! ( dw d-addr -- ) swap 65535 and swap   (mem) ! ;

VARIABLE PC

: PC++ ( -- ) 1 PC +! ;
: PC@ ( -- dw ) pc @ d@ ;
: PC@+ ( -- dw ) pc@ pc++ ;

\ General-purpose registers
8 ARRAY (regs)

: r@ ( reg -- dw ) (regs) @ ;
: r! ( dw reg -- ) swap 65535 and swap   (regs) ! ;

\ Special-purpose registers
VARIABLE EX
VARIABLE IA
VARIABLE SP

: ex@ ( -- dw ) ex @ ;
: ex! ( dw -- ) lo ex ! ;

: sp@ ( -- dw ) sp @ ;
: sp! ( dw -- ) 65535 and sp ! ;

\ The stack is full-descending.
: peek ( -- dw ) sp@ d@ ;
: pop ( -- dw ) sp@ dup d@  >R 1+ sp! R> ;
: push ( dw -- ) sp@ 1- dup sp! d! ;


\ Hardware
20 ARRAY hw-devices
VARIABLE hw-device-count
0 hw-device-count !

: hw-add-device ( dev -- )
  hw-device-count @ hw-devices !
  1 hw-device-count +!
;

VARIABLE int-queuing
false int-queuing ! \ TODO This should be put in the reset logic.

\ Hardware devices are structures.
BEGIN-STRUCTURE device
  field: dev-id
  field: dev-version
  field: dev-manufacturer
  field: dev-int-handler
  field: dev-check-int
END-STRUCTURE

\ Interrupt handlers don't receive any messages. They have type ( -- ).
\ Interrupt checker is called on each clock tick.
\ It has type ( -- 0 | msg -1 )


\ The only hardware device I'm adding for now is the serial port one I'm making
\ up right now.
\ It's full-duplex, meaning it can read and write intermingled.
\ The A register is used as the operation code, as normal.
\ 0: Blocks until a character is received. Puts the character in C.
\ 1: Emits the character in B.

VALUE dev-serial here IS dev-serial
device allot

dev-serial
\ Interrupt handler
:noname ( -- )
  0 r@ ( a )
  CASE
    0 OF key 2 r! ENDOF
    1 OF 1 r@ emit ENDOF
    drop
  ENDCASE
; over dev-int-handler !

\ Interrupt checker
:noname ( -- ) false ; over dev-check-int !

$12345678 over dev-id !
1         over dev-version !
$9abcdef0 over dev-manufacturer !

hw-add-device \ serial is device 0


\ Instruction evaluation

\ Evaluating the various argument types.
: read-a ( a -- val )
  dup $08 < IF r@ EXIT THEN
  dup $10 < IF $8  - r@ d@ EXIT THEN
  dup $18 < IF $10 - r@ pc@+ + d@ EXIT THEN
  dup $20 >= IF $21 - EXIT THEN
  CASE
    $18 OF pop ENDOF
    $19 OF peek ENDOF
    $1a OF sp@ pc@+ + d@ ENDOF \ [SP + next word]
    $1b OF sp@  ENDOF \ SP
    $1c OF pc @ ENDOF \ PC
    $1d OF ex @ ENDOF \ EX
    $1e OF pc@+ d@ ENDOF \ [next word]
    $1f OF pc@+ ENDOF \ next word (literal)
    drop
  ENDCASE
;

: write-arg ( val a -- )
  dup $08 < IF r! EXIT THEN
  dup $10 < IF $08 - r@ d! EXIT THEN
  dup $18 < IF $10 - r@ pc@+ + d! EXIT THEN
  CASE
    $18 OF push ENDOF
    $19 OF sp@ d! ENDOF
    $1a OF sp@ pc@+ + d! ENDOF
    $1b OF sp! ENDOF
    $1c OF pc ! ENDOF
    $1d OF ex ! ENDOF
    $1e OF pc@+ d! ENDOF
    $1f OF pc++ drop ENDOF
    drop
  ENDCASE
;

: (read-b) ( b consume? -- val )
  >R
  dup $08 < IF r!   R> drop EXIT THEN
  dup $10 < IF $08 - r@ d!   R> drop EXIT THEN
  dup $18 < IF
    $10 - r@ pc@ +
    R> IF pc++ THEN
    d! EXIT THEN
  R> swap ( consume? b )
  CASE ( consume? )
    $18 OF drop pop ENDOF
    $19 OF drop peek ENDOF
    $1a OF sp@ pc@   swap IF pc++ THEN   d@ ENDOF
    $1b OF drop sp@ ENDOF
    $1c OF drop pc @ ENDOF
    $1d OF drop ex @ ENDOF
    $1e OF pc@ d@   swap IF pc++ THEN ENDOF
    $1f OF pc@      swap IF pc++ THEN ENDOF
    drop
  ENDCASE
;

: read-b ( b -- val ) true  (read-b) ;
: peek-b ( b -- val ) false (read-b) ;


\ Instruction implementations

\ Basic ops are ( b a -- ), and their xts go in here.
$20 ARRAY basic-ops

\ SET
:noname read-a swap write-arg ; $01 basic-ops !

( ADD ) :noname read-a over peek-b
  + dup hi ex!
  swap write-arg
; $02 basic-ops !

( SUB ) :noname read-a over peek-b
  swap -   dup hi ex!
  swap write-arg
; $03 basic-ops !

( MUL ) :noname read-a over peek-b
  *   dup hi ex!
  swap write-arg
; $04 basic-ops !

( MLI ) :noname read-a signed over peek-b signed
  *   dup hi ex!
  lo swap write-arg
; $05 basic-ops !

: (div) ( b av bv )
  over 0= IF ( b av bv ) 2drop 0 ex! 0 swap write-arg EXIT THEN
  ( b av bv )
  2dup 16 lshift swap sm/rem ( b av bv r q )
  ex! drop
  swap sm/rem ( b r q )
  -rot write-arg ( r ) drop
;

( DIV ) :noname read-a        over peek-b        (div) ; $06 basic-ops !
( DVI ) :noname read-a signed over peek-b signed (div) ; $07 basic-ops !

: (mod) ( b av bv )
  over 0= IF ( b av bv ) 2drop 0 swap write-arg EXIT THEN
  ( b av bv )
  swap sm/rem drop swap write-arg
;

( MOD ) :noname read-a        over peek-b        (mod) ; $08 basic-ops !
( MDI ) :noname read-a signed over peek-b signed (mod) ; $09 basic-ops !


( AND ) :noname read-a over peek-b   and swap write-arg ; $0a basic-ops !
( BOR ) :noname read-a over peek-b    or swap write-arg ; $0b basic-ops !
( XOR ) :noname read-a over peek-b   xor swap write-arg ; $0c basic-ops !

( SHR ) :noname read-a over peek-b
  2dup 16 lshift swap rshift lo ex!
  swap rshift lo swap write-arg
; $0d basic-ops !

( ASR ) :noname read-a over peek-b signed
  2dup 16 lshift swap rshift lo ex!
  swap rshift lo swap write-arg
; $0e basic-ops !

( SHL ) :noname read-a over peek-b
  swap lshift dup hi ex! swap write-arg
; $0f basic-ops !



\ Branch instructions
: br-start read-a swap read-b swap ;
: br-end   0= skipping ! ;

( IFB ) :noname br-start and    br-end ; $10 basic-ops !
( IFC ) :noname br-start and 0= br-end ; $11 basic-ops !
( IFE ) :noname br-start =  br-end ; $12 basic-ops !
( IFN ) :noname br-start <> br-end ; $13 basic-ops !
( IFG ) :noname br-start >  br-end ; $14 basic-ops !
( IFA ) :noname br-start signed swap signed >  br-end ; $15 basic-ops !
( IFL ) :noname br-start <  br-end ; $16 basic-ops !
( IFU ) :noname br-start signed swap signed <  br-end ; $17 basic-ops !


( ADX ) :noname read-a over peek-b
  + ex@ + dup hi ex! lo swap write-arg ; $1a basic-ops !
( SBX ) :noname read-a over peek-b
  swap - ex@ + dup hi ex! lo swap write-arg ; $1b basic-ops !

: (bump-indexes) ( delta -- ) 6 r@ over + 6 r!   7 r@ + 7 r! ;
( STI ) :noname read-a swap write-arg   1 (bump-indexes) ;
( STD ) :noname read-a swap write-arg  -1 (bump-indexes) ;



\ Special opcodes
$20 ARRAY spec-ops

( JSR ) :noname read-a   pc @ push   pc ! ; $01 spec-ops !

( INT ) :noname read-a drop S" Unimplemented: INT" type ; $08 spec-ops !
( IAG ) :noname ia @ swap write-arg ; $09 spec-ops !
( IAS ) :noname read-a ia ! ; $0a spec-ops !
( RFI ) :noname read-a drop
  false int-queuing !
  pop 0 r! pop pc ! ; $0b spec-ops !
( IAQ ) :noname read-a int-queuing ! ; $0c spec-ops !

( HWN ) :noname hw-device-count @ swap write-arg ; $10 spec-ops !
( HWQ ) :noname
  read-a hw-devices @ ( dev )
  dup dev-id @ ( dev id )
  dup hi 1 r! \ hi id to B
  lo 0 r!     \ lo id to A
  dup dev-version @ 2 r! \ version to C
  dev-manufacturer @ ( man )
  dup hi 4 r! \ hi manufacturer to Y
  lo 3 r!     \ lo manufacturer to X
; $11 spec-ops !
( HWI ) :noname read-a hw-devices @   dev-int-handler @ execute ; $12 spec-ops !

\ Actual instruction decoding

: op>opcode ( op -- opcode ) 31 and ;
: op>a ( op -- a ) 10 rshift 63 and ;
: op>b ( op -- b )  5 rshift 31 and ;

\ Reads b as the opcode and a as the argument.
: run-spec-op ( op -- ) dup op>a   swap op>b spec-ops @ ( a xt ) execute ;

: run-basic-op ( op -- )
  dup op>opcode ?dup 0= IF run-spec-op EXIT THEN ( op opcode )
  >R dup op>b swap op>a R> ( b a op )
  basic-ops @ ( b a xt ) execute
;

VARIABLE int-q-head
VARIABLE int-q-tail
256 ARRAY int-q

\ Adds an interrupt to the queue.
: push-int ( msg -- )
  int-q-tail @ int-q !
  int-q-tail @ 1 + 255 and int-q-tail !
;

\ Assumes there are interrupts queued. CHECK THAT FIRST.
: pop-int ( -- msg )
  int-q-head @ dup int-q @ swap 1 + 255 and int-q-head !
;

: int-queued? ( -- queued? ) int-q-head @ int-q-tail @ <> ;

\ If a hardware interrupt is detected, this will queue it up.
\ (Interrupts are popped and executed after this.)
: check-hw-int ( -- )
  hw-device-count @ 0 DO
    i hw-devices @ dev-check-int @ execute ( msg true | false )
    IF push-int THEN ( )
  LOOP
;

\ Main interrupt handler, called during the main loop.
\ Does nothing when interrupt queuing is turned on.
\ Always pops an interrupt when queuing is off, but if IA = 0 it will just
\ drop the interrupt.
\ TODO Somehow I need to handle the fact that only one interrupt is supposed to
\ run between each actual instruction. Not even sure that restriction is
\ well-defined.
: handle-int ( -- )
  int-queuing @ IF EXIT THEN
  pop-int ( msg )
  ia @ 0= IF drop EXIT THEN
  \ If we're down here, then ( msg ) and we should execute it.
  true int-queuing ! \ Turn on queuing
  pc @ push          \ Push PC
  0 r@ push          \ Push A
  ia @ pc !          \ Set PC to IA
  0 r!               \ Set A to message
  ( )
;

\ Runs one tick of the CPU - this is the main interpreter.
: tick ( -- )
  \ Tick the hardware, checking for interrupts.
  check-hw-int
  \ Handle interrupts, if any.
  handle-int
  \ Execute the next instruction.
  pc@+ run-basic-op \ Will hand off to run-spec-op where necessary.
  \ TODO Handle timing and cycles for full simulation. This code effectively
  \ runs in turbo mode, as fast as the interpreter can go.
;

\ Runs tick repeatedly until ordered to stop. There's actually no end condition.
: interp ( -- ) BEGIN tick AGAIN ;


256 buffer: file-name-counted

\ Loads an assembled DCPU binary from real disk into memory.
\ Expects the DCPU binaries to be in big-endian format.
: load-binary ( )
  \ Get the file name from the counted string.
  file-name-counted
  dup c@ swap char+   r/o bin open-file   ABORT" Failed to open binary file"
  >R

  R@ file-size   ABORT" Could not check size of binary file"
  swap $20000 >= or ABORT" Binary file larger than 64K words" ( )

  \ Begin reading in the file 512 bytes at a time.
  0 BEGIN
    here 512 R@ read-file   ABORT" Failed reading from binary file"
  dup WHILE
    ( mem-index size ) 0 DO
      here i +   dup c@ 8 lshift   swap 1+ c@   or ( mem-index word )
      over d!   1+ ( mem-index' )
    2 +LOOP
  REPEAT ( mem-index 0 )
  2drop
;


\ Configures the DCPU to startup state and sets it running.
: reset ( -- )
  0 pc !
  0 sp !
  0 ia !
  0 ex !
  false int-queuing !
  8 0 DO 0 i r! LOOP
  load-binary
;


\ Expects the file name of a binary, and executes it.
: run ( c-addr u -- )
  dup file-name-counted c!
  file-name=counted + swap move ( )
  reset
  interp
;

