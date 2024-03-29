\ A simple 6502 emulattion benchmark
\ only 11 opcodes are implemented. The memory layout is:
\  2kB RAM at 0000-07FF, mirrored throughout 0800-7FFF
\ 16kB ROM at 8000-BFFF, mirrored at C000
decimal
create ram 2048 allot   : >ram $7FF  and ram + ;
create rom 16384 allot  : >rom $3FFF and rom + ;
\ 6502 registers
variable reg-a   variable reg-x  variable reg-y
variable reg-s   variable reg-pc  : reg-pc+ reg-pc +! ;
\ 6502 flags
variable flag-c  variable flag-n   variable cycle
variable flag-z  variable flag-v  : cycle+ cycle +! ;
hex
: w@ dup c@ swap 1+ c@ 100 * or ;
: cs@ c@ dup 80 and if 100 - then ;

: read-byte ( address -- )
  dup 8000 < if >ram c@ else >rom c@ then ;
: read-word ( address -- )
  dup 8000 < if >ram w@ else >rom w@ then ;
: dojmp ( JMP aaaa )
  reg-pc @ >rom w@ reg-pc ! 3 cycle+ ;
: dolda ( LDA aa )
  reg-pc @ >rom c@ ram + c@ dup dup reg-a !
  flag-z ! 80 and flag-n ! 1 reg-pc+ 3 cycle+ ;
: dosta ( STA aa )
  reg-a @ reg-pc @ >rom c@ ram + c! 1 reg-pc+ 3 cycle+ ;
: dobeq ( BEQ <aa )
  flag-z @ 0= if reg-pc @ >rom cs@ 1+ reg-pc+ else 1 reg-pc+ then 3 cycle+ ;
: doldai ( LDA #aa )
  reg-pc @ >rom c@ dup dup reg-a ! flag-z ! 80 and flag-n !
  1 reg-pc+ 2 cycle+ ;
: dodex ( DEX )
  reg-x @ 1- FF and dup dup reg-x ! flag-z ! 80 and flag-n !
  2 cycle+ ;
: dodey ( DEY )
  reg-y @ 1- ff and dup dup reg-y ! flag-z ! 80 and flag-n !
  2 cycle+ ;
: doinc ( INC aa )
  reg-pc @ >rom c@ ram + dup c@ 1+ FF and dup -rot swap c! dup
  flag-z ! 80 and flag-n !  1 reg-pc+ 3 cycle+ ;
: doldy ( LDY aa )
  reg-pc @ >rom c@ dup dup reg-y ! flag-z ! 80 and flag-n !
  1 reg-pc+ 2 cycle+ ;
: doldx ( LDX #aa )
  reg-pc @ >rom c@ dup dup reg-x ! flag-z ! 80 and flag-n !
  1 reg-pc+ 2 cycle+ ;
: dobne ( BNE <aa )
  flag-z @ if reg-pc @ >rom cs@ 1+ reg-pc+ else 1 reg-pc+ then
  3 cycle+ ;
: 6502emu ( cycles -- )
  begin cycle @ over  < while
    reg-pc @ >rom c@ 1 reg-pc+
    dup 4C = if dojmp then      dup A5 = if dolda then
    dup 85 = if dosta then      dup F0 = if dobeq then
    dup D0 = if dobne then      dup A9 = if doldai then
    dup CA = if dodex then      dup 88 = if dodey then
    dup E6 = if doinc then      dup A0 = if doldy then
        A2 = if doldx then      repeat drop ;

create testcode
  A9 c, 00 c,  \ start: LDA #0
  85 c, 08 c,  \        STA 08
  A2 c, 0A c,  \        LDX #10
  A0 c, 0A c,  \ loop1: LDY #10
  E6 c, 08 c,  \ loop2: INC 08
  88 c,        \        DEY
  D0 c, FB c,  \        BNE loop2
  CA c,        \        DEX
  D0 c, F6 c,  \        BNE loop1
  4C c, 00 c, 80 C, \   JMP start

: init-vm 13 0 do i testcode + c@ i rom + c! loop
          0 cycle ! 8000 reg-pc ! ;

: bench6502 1000 0 do init-vm #6502 6502emu loop ;
bench6502 bye
