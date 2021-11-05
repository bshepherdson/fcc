# High-Level Assembler

The goal of the HLA is to unify FCC's several targets as much as possible.

The idea is to replace the three parts of FCC (broken "portable" C, hand-edited
ARMv7 32-bit, hand-edited AMD64) with mostly a singular JSON structure and a
tool to generate binaries for a target machine based on it.

The idea is a FOAM-style JSONish data format for all machine words. Most words
should be implementable with the HLA code, but a fallback to
architecture-specific assembly code is allowed.

## Programming Model

There are four important registers: `sp`, `rsp`, `tos`, `ip`. There are an
arbitrary number of temporary registers `t1`, `t2`, etc.

TOS is treated like a register. Pushing and popping on `sp` is needed for
working with NOS.

### C Calls

Calling C library functions outside FCC is supported. The calling convention is
abstracted; the C call pseudoinstructions take arguments and work out how to
save/restore.


### Programmability

The assembly code sequences support arbitrary nesting of arrays, which makes it
easy to write eg. `next` as "macros" that are JS functions that return lists of
literal instructions, etc.



## Primitive operations

| Op     | Meaning |
| :--    | :-- |
| `set r, imm`  | Set register to immediate|
| `add d, s`  | Add registers|
| `addi d, imm` |  Add literal to register|
| `sub d, s`  | Subtract registers|
| `mul d, s`  | Multiply registers|
| `muli d, imm` |  Multiply by literal - shifts where possible|
| `div d, s`  | Divide registers|
| `mod d, s`  | Modulus by registers|
| `jz r, label`   | Jump if `r` is zero|
| `jnz r, label`   | Jump if `r` is not zero|
| `jeq r, s, label`   | Jump if `r == s`|
| `jne r, s, label`  | Jump if `r != s`|
| `jgt r, s, label`  | Jump if `r > s`|
| `jlt r, s, label`  | Jump if `r < s`|
| `jgu r, s, label`  | Jump if `r > s` unsigned|
| `jlu r, s, label`  | Jump if `r < s` unsigned|
| `push r`  | Push register onto stack |
| `push imm`  | Push immediate onto stack |
| `pop r`   | Pop one value into `r`|
| `pop imm`   | Pop `imm` cells off the stack, discarding them|
| `jmp label`   | Jump to label|
| `jr  r`   | Jump to register|

## Words

Each word has a Forth name, label name (assembler safe), and key number (used
for superinstructions).

## Platforms

Each platform will need a bunch of its own code, in addition to the inlining.

