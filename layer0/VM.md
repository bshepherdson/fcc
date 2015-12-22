# FCC Virtual Machine

This file specs out a virtual machine for Forth systems. It's designed to be
easy to implement, and therefore is as small as possible. Most of its operations
correspond pretty closely to CPU instructions - arithmetic, bitwise operations,
comparisons, memory manipulation.

There is an expansion space intended to support native operations on various
platforms. It could be used for interrupt handling on an embedded system, or for
foreign function calls on a full OS.

Correspondingly, there is a small extension to the Forth system in `layer2/`
that allows high-level code to trigger these low-level operations directly when
required (see `vm_exec` opcode, below).


## Format

Each instruction in the VM is a single byte indexing into the bytecode table.
Operands live on the stack, naturally. Literals are defined using `lit` and
`lit_bump`.

The size of an address unit (usually a byte) and a cell (usually 4 or 8 bytes)
are platform-dependent, and there are a few bytecodes that return this system
information.

## System Variables

The virtual machine needs at a minimum the following state:

- A data stack, and pointer to it.
- A return stack, and pointer to it.
- An input buffer, with some fixed size.
- A pointer into the input buffer, aimed at the current character.
- A pointer to the next bytecode to execute.

## Bytecode

Most of these definitions are roughly identical to a Forth word, so they're not
documented here in detail.

### Core

- `0x00 NOP`: does nothing.
- `0x01 lit`: Pushes the following byte onto the stack.
- `0x02 lit_bump`: Shifts the top value left by 8 bits and adds the following
  byte to it.
    - This allows loading arbitrary constants, though care is needed since
      platforms may not support numbers as big as some size.
- `0x04 pc` Pushes the current value of PC.
- `0x05 jmp` Sets PC to the value on top of the stack.
- `0x06 jmp_link` Sets PC to the value on top of the stack, and pushes the old
  PC value.
- `0x07 jmp_zero` Sets PC to the top of the stack, if the second-from-top value
  is 0.
- `0x08 ip` Pushes the current value of IP, the Forth word pointer.
- `0x09 ip_read` Pushes the value pointed to by IP, and bumps IP.
- `0x0a ip_set` Stores the value on top of the stack into IP.
- `0x0f bye` exits the engine (might be equivalent to a shutdown, on an embedded
  system)

### Arithmetic

- `0x10 +`
- `0x11 -`
- `0x12 *`
- `0x13 /`
- `0x14 MOD`

### Bitwise

- `0x15 AND`
- `0x16 OR`
- `0x17 XOR`
- `0x18 LSHIFT`
- `0x19 RSHIFT`

### Comparison

- `0x1a <`
- `0x1b U<`
- `0x1c =`


### Stack

- `0x20 DUP`
- `0x21 SWAP`
- `0x22 DROP`
- `0x23 >R`
- `0x24 R>`
- `0x25 DEPTH`


### Memory

- `0x28 @`
- `0x29 !`
- `0x2a C@`
- `0x2b C!`
- `0x2c (ALLOCATE)` Has type `( size-in-address-units -- c-addr )`
    - This might call a system `malloc()` but it might also allocate from a
      global pointer in an embedded system.
    - No guarantees are made about whether multiple calls to this yield adjacent
      regions.

### System Details

Address units are the resolution of a pointer. Generally a byte, sometimes a
larger word. Characters and cells are each 1 or more address units wide.

Characters are generally 1 byte/address unit, cells are generally 4 or 8
bytes/address units.

- `0x30 (/CELL)` Pushes the size of a cell in address units.
- `0x31 (/CHAR)` Pushes the size of a character in address units.

### Conveniences

These are extra VM features to help support the low-level code.

VMs should provide at least 16 "global variables", accessible by the below two
opcodes.

- `0x38 VAR_READ` Reads the next byte, and pushes the value of that global
  variable.
- `0x39 VAR_READ` Reads the next byte, and sets the value of that global
  variable to the value popped off the stack.

### Input/Output

- `0x40 REFILL` Reloads the input buffer. Discards the current contents, if any
  were present.
- `0x41 clear_input` Empties all input sources from the stack, reading from the
  keyboard.
- `0x44 >IN` Pushes the address of a cell that holds the index into the parse
  buffer.
- `0x45 parse_buffer` Pushes the address of the start of the parse area.
- `0x46 parse_length` Pushes the length of the parsed text.
- `0x48 EMIT` Outputs the character whose code is on the stack. Unicode support
  is system-defined.

