\ This code runs in a Standard Forth on a host system.
\ It is configured to generate code for a target system.
\ The configuration defaults to targeting the host system, but you can override
\ those variables before calling GENERATE.

\ The generated code begins with code for the following:
\ - Fetch the address where this block lives, using vm-PC.
\ - Load the address and length of the relocation table.
\ - Loop over those relocating addresses, relocating each.
\ - Jump to QUIT.

\ Then it contains a set of non-Forth code blocks, like the doer words.
\ Next come the core word definitions (see dictionary format below).
\ Finally, the relocation table. That consists of a cell giving the number of
\ entries, and N cells giving their relative addresses.

\ Word definitions look like this:
\ cell: link address - pointer to the previous word in the dictionary.
\ char: length + flags. 0x80 indicates immediate, 0x40 hidden. 0x3f for length.
\   (That means maximum length is 63 characters.)
\ N chars: the string name. no terminator.
\ (alignment)
\ cell: doer address
\ cell: value address

\ There are several well-documented execution or "threading" models for Forth.
\ The one I'm going with here is a hybrid of direct and indirect threading.
\ Execution tokens (or xts) need to be a single cell that identifies a word.
\ xts here are implemented as a pointer to the doer address in the dictionary
\ block described above.

\ The code for a colon definition uses 2 cells per operation.
\ The first cell gives a primitive routine, usually a doer. The second cell
\ gives a parameter to it.
\ The engine pushes the parameter and calls the primitive.
\ - docol expects the address of the definition to follow.
\ - dovm expects the address of a bytecode routine.
\ - dolit expects the literal value, which will be pushed onto the stack.
\ - dovar is essentially dolit (and might not actually need to exist? TODO)
\ - dodoes works somehow, I don't know yet.


\ Configuration variables.
\ These variables are intended to make this file capable of generating code on
\ any host, for any target.
\ It defaults to this machine as both host and target.
\ There are currently some limitations to the flexibility:
\ - Hosts are assumed to have 1 address unit = 8 bits. Targets can vary.

\ TODO These configuration values are currently assumed, rather than checked:
\ - host-address-unit-bits (TODO: This is an environment? query.)
\ - host-big-endian?
\ - target-big-endian?

VARIABLE host-address-unit-bits
8 host-address-unit-bits !
VARIABLE target-address-unit-bits
host-address-unit-bits @ target-address-unit-bits !

VARIABLE host-char-size
1 chars host-char-size !
VARIABLE target-char-size
host-char-size @ target-char-size !


VARIABLE host-cell-size
1 cells host-cell-size !
VARIABLE target-cell-size
host-cell-size @ target-cell-size !


VARIABLE host-big-endian?
0 host-big-endian? !
VARIABLE target-big-endian?
0 target-big-endian? !

VARIABLE out
HERE @ CONSTANT out-start
10000 chars allot
out-top out !

VARIABLE reloc
HERE @ CONSTANT reloc-start
1000 cells allot
reloc-start reloc !

\ Records the current position as needing relocation.
: vm-relocate ( -- ) out @ reloc @ !   1 cells reloc +! ;

\ Various flavours of compilation.
\ Raw compiler, which adds a single byte (see the limitations above) to the
\ output.
: vm-raw-c, ( c -- ) out @ c!   1 chars out +! ;

\ Helpers for little-endian and big-endian writes.
: vm-raw-le-, ( val width -- )
  0 DO dup 255 and vm-raw-c,   8 rshift LOOP
;
: vm-raw-be-, ( val width -- )
  BEGIN dup 0> WHILE ( val width-left )
    2dup  ( val width-left val width-left )
    1- 8 * ( val width-left val shift )
    rshift 255 and ( val width-left val')
    vm-raw-c, ( val width-left )
    1-
  REPEAT 2drop
;

\ Clever base compiler: Expects a value and a size in target address units.
\ Handles endianness and varying target sizes.
\ NB: Does NOT check for overflow, so writing a big value to a 2-byte target
\ value will end up truncating it to the low 2 bytes for little-endian, and high
\ 2 bytes for big-endian.
: vm-raw, ( val width -- )
  target-big-endian? @ IF vm-raw-be-, ELSE vm-raw-le-, THEN ;

\ Compiles a char-sized value for the target.
: vmc, target-char-size @ vm-raw, ;
\ Compiles a cell-sized NON-RELOCATED value for the target.
: vm, target-cell-size @ vm-raw, ;

\ Compiles a cell-sized RELOCATED value for the target.
: vm,R vm-relocate vm, ;


\ Mnemonics for compiling the VM bytecodes.
HEX
: vm-NOP, 0  vmc, ;
: vm-LIT, 1  vmc, ;
: vm-LIT-BUMP; 2  vmc, ;
: vm-PC, 4  vmc, ;
: vm-JMP, 5  vmc, ;
: vm-JMP-LINK, 6  vmc, ;
: vm-JMP-ZERO, 7  vmc, ;
: vm-IP, 8  vmc, ;
: vm-IP-READ, 9  vmc, ;
: vm-IP-SET, a  vmc, ;
: vm-BYE, f  vmc, ;
: vm-PLUS, 10 vmc, ;
: vm-MINUS, 11 vmc, ;
: vm-TIMES, 12 vmc, ;
: vm-DIV, 13 vmc, ;
: vm-MOD, 14 vmc, ;
: vm-AND, 15 vmc, ;
: vm-OR, 16 vmc, ;
: vm-XOR, 17 vmc, ;
: vm-LSHIFT, 18 vmc, ;
: vm-RSHIFT, 19 vmc, ;
: vm-LT, 1a vmc, ;
: vm-ULT, 1b vmc, ;
: vm-EQ, 1c vmc, ;
: vm-DUP, 20 vmc, ;
: vm-SWAP, 21 vmc, ;
: vm-DROP, 22 vmc, ;
: vm-TO-R, 23 vmc, ;
: vm-FROM-R, 24 vmc, ;
: vm-DEPTH, 25 vmc, ;
: vm-FETCH, 28 vmc, ;
: vm-STORE, 29 vmc, ;
: vm-CFETCH, 2a vmc, ;
: vm-CSTORE, 2b vmc, ;
: vm-ALLOCATE, 2c vmc, ;
: vm-SIZE-CELL, 30 vmc, ;
: vm-SIZE-CHAR, 31 vmc, ;
: vm-VAR-READ, 38 vmc, ;
: vm-VAR-WRITE, 39 vmc, ;
: vm-VAR-ADDR, 3a vmc, ;
: vm-REFILL, 40 vmc, ;
: vm-CLEAR-INPUT, 41 vmc, ;
: vm-IN, 44 vmc, ;
: vm-PARSE-BUFFER, 45 vmc, ;
: vm-PARSE-LENGTH, 46 vmc, ;
: vm-EMIT, 48 vmc, ;
DECIMAL

\ Compiles a literal with as many LIT-BUMP operations as necessary.
: vm-literal, ( value -- )
  \ First we need to work out how big this value is in bytes.
  0 host-cell-size @ 0 DO
    over i 8 * rshift 255 and ( value max byte )
    if drop i then
  LOOP
  ( value max )
  vm-lit,
  BEGIN dup 0 >= WHILE
    2dup 8 * rshift 255 and ( val max val' )
    vmc,
    dup 0> IF vm-lit-bump, THEN
    1-
  REPEAT
;


\ Central code-generation components.
: generate-header ( -- )
  vm-PC,
  1 vm-literal,
  vm-minus, ( VM: relocation-base )
  vm-dup,   ( VM: relocation-base relocation-base )
  \ Two bytes should be enough to load the relocation table code address.
  vm-lit, 0 vm-lit-bump, 0
  vm-plus, ( VM: reloc-base reloc-table-code )
  vm-jmp,
;

\ Constants for the usage of the VM's global variables.
0 CONSTANT vm-var-HERE
1 CONSTANT vm-var-STATE
2 CONSTANT vm-var-BASE

\ Variables holding the addresses into the output for the varies doer routines.
VARIABLE vm-doer-dovm
VARIABLE vm-doer-docol
VARIABLE vm-doer-dolit
VARIABLE vm-doer-dobranch
VARIABLE vm-doer-docond


\ Helper function that compiles the code for NEXT into the VM.
\ This is the inner interpreter. It gets written into each of the various doers.
: next, ( -- )
  vm-ip-read, vm-ip-read,
  vm-swap, vm-jmp,
;

\ dovm's parameter is the real, absolute address of the VM code to run.
\ dovm gets the current PC (inside dovm), pushes it onto the return stack, and
\ jumps into the given code.
\ NB: The target code is responsible for calling NEXT.
: generate-doer-dovm ( -- )
  out @ vm-doer-dovm !
  vm-jmp,
;

\ docol's parameter is what IP should be set to.
\ docol pushes the current IP to the return stack, sets IP to the parameter,
\ and continues.
\ A definition for docol should end with EXIT, which will pop the old IP from
\ the return stack and continue the previous definition.
: generate-doer-docol ( -- )
  out @ vm-doer-docol !
  vm-ip, vm-to-r,
  vm-ip-set,
  next,
;

\ dolit is really easy - the value we're supposed to push on the stack is
\ already there.
: generate-doer-dolit ( -- )
  out @ vm-doer-dolit !
  next,
;

\ dobranch is the unconditional jump by the parameter.
: generate-doer-dobranch ( -- )
  out @ vm-doer-dobranch !
  vm-ip, vm-plus, vm-ip-set,
  next,
;

: generate-doer-docond ( -- )
  out @ vm-doer-docond !
  \ ( VM: cond delta )
  vm-swap, ( VM: delta cond )
  4 vm-literal, vm-pc, vm-plus,
  vm-jmp-zero, ( VM: delta )
  \ Parameter is not 0 - set the delta to 0.
  vm-drop, 0 vm-literal,
  \ Rejoin here.
  vm-ip, vm-plus, vm-ip-set,
  next,
;

: generate-doers ( -- )
  generate-doer-dovm
  generate-doer-docol
  generate-doer-dolit
  generate-doer-dobranch
  generate-doer-docond
;


\ Helpers for compiling VM words into the output.
VARIABLE vm-var-LATEST
0 vm-var-LATEST !

\ Advances out until it's a cell address.
: vm-align ( -- )
  out @ target-cell-size @ 2dup mod ( out size extra )
  dup IF
    - + ( out' )
    out !
  ELSE
    drop 2drop
  THEN
;

\ This constructs a header for the given word, which uses the given doer and
\ points to the following code.
: doer-vm: ( doer-var "word" -- )
  out @
  vm-var-LATEST @
  dup IF vm,R ELSE vm, THEN \ Only make it relocatable if it's not 0.
  vm-var-LATEST ! \ And write the old out value into LATEST.

  parse-name ( c-addr u )
  dup vmc,
  0 DO
    dup i + c@ vmc,
  LOOP
  vm-align
  @ vm,R \ Write (relocatable) address of dovm routine.
  out @ target-cell-size + vm,R \ And (reloc) address of the next cell.
;

\ Shorthand for the common case (dovm).
: vm: ( "word" -- ) vm-doer-dovm doer-vm: ;

\ Writes the closing bits of any VM definition.
\ That is, the code for NEXT.
: ;vm ( -- ) next, vm-align ;

\ Core system words, that need direct VM access.
\ Most of these are thin wrappers around a VM bytecode, but not all.
vm: + vm-plus, ;vm
vm: - vm-minus, ;vm
vm: * vm-times, ;vm
vm: / vm-div, ;vm
vm: mod vm-mod, ;vm
vm: and vm-and, ;vm
vm: or  vm-or, ;vm
vm: xor vm-xor, ;vm
vm: lshift vm-lshift, ;vm
vm: rshift vm-rshift, ;vm

vm: < vm-lt, ;vm
vm: U< vm-ult, ;vm
vm: = vm-eq, ;vm

vm: dup vm-dup, ;vm
vm: swap vm-swap, ;vm
vm: drop vm-drop, ;vm
vm: >R vm-to-r, ;vm
vm: R> vm-from-r, ;vm

vm: @ vm-fetch, ;vm
vm: ! vm-store, ;vm
vm: C@ vm-cfetch, ;vm
vm: C! vm-cstore, ;vm

vm: HERE vm-var-read, vm-var-HERE vmc, ;vm
vm: (>HERE) vm-var-write, vm-var-HERE vmc, ;vm

vm: STATE vm-var-addr, vm-var-STATE vmc, ;vm
vm: BASE vm-var-addr, vm-var-BASE vmc, ;vm

vm: (ALLOCATE) vm-allocate, ;vm

\ Constants that return each of the doer addresses.
\ Creates words whose doer is dolit and whose value is the relocated doer.
vm-doer-dolit doer-vm: (dovm)
  target-cell-size @ out -!
  vm-doer-dovm @ vm,
\ No vm; here, we don't want to compile NEXT.
vm-doer-dolit doer-vm: (docol)
  target-cell-size @ out -!
  vm-doer-docol @ vm,
\ No vm; here, we don't want to compile NEXT.
vm-doer-dolit doer-vm: (dolit)
  target-cell-size @ out -!
  vm-doer-dolit @ vm,
\ No vm; here, we don't want to compile NEXT.
vm-doer-dolit doer-vm: (dobranch)
  target-cell-size @ out -!
  vm-doer-dobranch @ vm,
\ No vm; here, we don't want to compile NEXT.
vm-doer-dolit doer-vm: (docond)
  target-cell-size @ out -!
  vm-doer-docond @ vm,
\ No vm; here, we don't want to compile NEXT.


\ Old library (BRANCH) and (0BRANCH) are replaced by the new words (dobranch)
\ and (docond).
\ Those constants return the addresses of the raw dobranch and docond doers.
\ TODO Write new library functions (branch) and (0branch) that do:
\ - Compile a literal (dobranch) or (docond) and a 0.
\ - Return ( addr base ) where the address is that of the 0, and the base is the
\   address after it, the one from which the delta is computed.


\ An xt is the address of the doer address. xt[0] is the doer address, xt[1]
\ is the parameter.
vm: EXECUTE ( ... xt -- ... )
  vm-dup, vm-size-cell, vm-plus, vm-fetch, vm-swap, vm-fetch, vm-jmp,
\ No vm; here, the target word will do it.


\ TODO Maybe (LATEST)?

vm: REFILL vm-refill, ;vm
vm: >IN vm-in, ;vm
vm: (CLEAR-INPUT) vm-clear-input, ;vm
vm: SOURCE vm-parse-buffer, vm-parse-length, ;vm
vm: EMIT vm-emit, ;vm

vm: (/CELL) vm-size-cell, ;vm
vm: (/CHAR) vm-size-char, ;vm
vm: BYE vm-bye, ;vm

\ Converts an xt for a CREATEd word into its data space.
\ The xt is pointing at the [docol, addr] part of the header.
\ CREATEd words begin with dolit(data space).
\ TODO This could be written in Forth.
vm: >BODY vm-size-cell, vm-plus, vm-fetch, vm-size-cell, vm-plus, ;vm

\ VM control structures
\ Note that these are limited to one-byte offsets! Be careful to keep blocks
\ short.

\ Unless rather than if because it works out nicer.
: vm-unless, ( cond -- ) ( Meta: -- offset-addr )
  vm-pc, vm-lit, out @ 0 vmc,  vm-plus,
  vm-jmp-zero,
;

: vm-then, ( -- ) ( Meta: offset-addr )
  out @ over - ( Meta: offset-addr delta )
  \ The delta is off by 4.
  4 + swap c! ( Meta: )
;

: vm-begin, ( Meta: -- top-addr ) out @ ;
: vm-while, ( cond --    Meta: -- offset-addr ) vm-unless, ;
: vm-repeat, ( Meta: top-addr while-addr -- )
  swap out @ over ( while-addr top-addr here top-addr )
  - ( while top delta )
  4 + swap c! ( while )
  out @ over - 4 + swap c!
;


\ The real heavyweights: parsing.
vm: PARSE ( delim -- 0 0 | c-addr u )
  vm-in, vm-fetch, vm-parse-length, vm-ult, ( delim full? )
  vm-unless, \ Unless full, ie. empty.
    vm-drop, ( )
    0 vm-literal, 0 vm-literal,
    next,
  vm-then,

  \ Still something left to parse.
  ( delim )
  vm-in, vm-fetch, ( delim index )
  vm-begin,
    \ First check if we've run out of space.
    vm-dup, vm-parse-length, vm-ult, ( delim index full? )
    vm-to-r, ( delim index   R: full? )
    vm-dup, vm-to-r, ( delim index R: full? index )
    vm-parse-buffer, vm-plus, vm-cfetch, ( delim char  R: full? index )
    ( over ) vm-swap, vm-dup, vm-to-r, vm-swap, vm-from-r, ( delim char delim R: full? index )
    vm-ult, vm-unless, ( delim &char )
      \ Unless space available, ie. empty.
      \ Submit the size and update >in.
      vm-parse-buffer, vm-in, vm-fetch, vm-plus, ( delim &char start )
      vm-dup, vm-to-r, ( delim &char start   R: start )
      vm-minus, ( delim size  R: start )
      vm-dup, vm-in, vm-fetch, vm-plus, vm-in, vm-store, ( delim size  R: start )
      vm-swap, vm-drop, ( size R : start )
      vm-from-r, vm-swap, ( start size )
      next,
    vm-then, ( delim &char)

    \ Now check if the character matches the delimeter.
    vm-swap, vm-dup, vm-to-r,  ( &char delim  R: delim )


  vm-dup, vm-to-r, ( delim   R: delim )
  vm-parse-buffer, vm-in, vm-plus, ( delim &char   R: delim )
  vm-cfetch, ( delim char   R: delim )
  vm-eq, ( match?  R: delim )

  vm-in, vm-parse-length, vm-ult, ( match? not-end?  R: delim )
  0 vm-literal, vm-eq, ( match? end? 
  vm-and, 







\ Returns the location and size of the compiled block.
: generate ( -- c-addr u )
  generate-header
  generate-doers
  generate-words
  generate-reloc
;

\ Notes for editing the library.
\ TODO (>HERE) has changed to write into the system HERE variable.
\ TODO HERE is now a core op defined here.
