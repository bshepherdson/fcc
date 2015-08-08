\ Forth assembler for the DCPU-16, big-endian format.
\ Postfix format, using Rx for register words, eg. RA RB RX RI RJ.
\ eg. RA RB SET, sets B to A.
\ There are no macros etc.; instead, use Forth words to compile more cleverly.
\ LABEL is essentially a CONSTANT for the current location.
\ For compiling data, use ALLOT, and DAT,
\ The current address can be acquired with DH.

65536 2 * BUFFER: mem

VARIABLE out
0 out !

\ Gives the DCPU address about to be written.
: DH ( -- addr ) out @ 1 rshift ;

\ Creates a constant with the given name, whose value is the current DCPU
\ address.
: LABEL ( "<spaces>name" -- ) DH CONSTANT ;

\ Big-endian format
: H, ( h -- ) dup 8 rshift 255 and out @ mem + !   255 and out @ 1+ mem + !   2 out +! ;

\ Masks values to 16 bits.
: H# ( x -- h ) 65535 and ;

: ALLOT, ( u -- addr ) out @   swap out +! ;
: DAT, ( h -- ) H, ;

VARIABLE #extras
0 #extras !
2 ARRAY extras

\ Queues up an extra for assembly.
: +EXTRA ( h -- ) #extras @ extras !   1 #extras +! ;

\ Assembles the extra words needed by instructions.
: DRAIN-EXTRAS #extras @ 0 ?DO i extras @ h, LOOP   0 #extras ! ;

\ Fixes attempts to compile b (dst) as an immediate value by converting them
\ to long literal form.
: FIX-IMMED ( dst -- dst' ) dup 31 > IF 33 - +EXTRA 31 THEN ;

\ Binary ops are spelled aaaaaabb bbbooooo
: BINOP, ( src dst op -- )
  31 and swap
  FIX-IMMED
  31 and 5 lshift or swap
  63 and 10 lshift or
  h,
;

: SET,  1 binop, ;
: ADD,  2 binop, ;
: SUB,  3 binop, ;
: MUL,  4 binop, ;
: MLI,  5 binop, ;
: DIV,  6 binop, ;
: DVI,  7 binop, ;
: MOD,  8 binop, ;
: MDI,  9 binop, ;
: AND, 10 binop, ;
: BOR, 11 binop, ;
: XOR, 12 binop, ;
: SHR, 13 binop, ;
: ASR, 14 binop, ;
: SHL, 15 binop, ;

: IFB, 16 binop, ;
: IFC, 17 binop, ;
: IFE, 18 binop, ;
: IFN, 19 binop, ;
: IFG, 20 binop, ;
: IFA, 21 binop, ;
: IFL, 22 binop, ;
: IFU, 23 binop, ;
: ADX, 26 binop, ;
: SBX, 27 binop, ;
: STI, 30 binop, ;
: STD, 31 binop, ;


\ Special ops are spelled aaaaaaoo ooo00000
: SPECOP, ( arg op -- )
  31 and 5 lshift swap
  63 and 10 lshift or
  h,
;

: JSR,  1 specop, ;
: INT,  8 specop, ;
: IAG,  9 specop, ;
: IAS, 10 specop, ;
: RFI, 11 specop, ;
: IAQ, 12 specop, ;
: HWN, 16 specop, ;
: HWQ, 17 specop, ;
: HWI, 18 specop, ;



\ Arguments
\ There are several addressing modes, and several registers etc.
\ General register: RA RB RC RX RY RZ RI RJ
\ Register dereference: [RA] etc.
\ Register deref+index: [RA+] etc.,
\   eg. 4 [RA+] 8 [RB+] SET, results in SET [B+8], [A+4]
\ PUSH, POP, PEEK, PICK n
\ [next word]: [lit] as [RA+] above
\ next word literally: lit as above
\ immediate: imm
\ RSP REX RPC

: RA 0 ;
: RB 1 ;
: RC 2 ;
: RX 3 ;
: RY 4 ;
: RZ 5 ;
: RI 6 ;
: RJ 7 ;

: [RA]  8 ;
: [RB]  9 ;
: [RC] 10 ;
: [RX] 11 ;
: [RY] 12 ;
: [RZ] 13 ;
: [RI] 14 ;
: [RJ] 15 ;

: [RA+] +EXTRA 16 ;
: [RB+] +EXTRA 17 ;
: [RC+] +EXTRA 18 ;
: [RX+] +EXTRA 19 ;
: [RY+] +EXTRA 20 ;
: [RZ+] +EXTRA 21 ;
: [RI+] +EXTRA 22 ;
: [RJ+] +EXTRA 23 ;

\ These two are actually the same; it's context-aware.
: PUSH 24 ;
: POP  24 ;

: PEEK 25 ;
: PICK ( h -- ) +EXTRA 26 ;
: RSP 27 ;
: RPC 28 ;
: REX 29 ;

: [+] +EXTRA 30 ;

\ Smart literals based on the value. The immediate range is -1..30.
\ Also, since there's only room for immediate values on the a arg, not b,
\ the assembler functions above check and convert would-be immediate b's to a
\ long LIT.
: LIT ( h -- arg )
  dup 1+ h# 32 < IF
    \ Can be assembled as an immediate, if this is argument a.
    \ FIX-IMMED will convert an immediate b to a next-word as needed.
    33 + h#
  ELSE
    \ Assemble as a next-word literal.
    +EXTRA 31
  THEN
;

