# Forth Compiler

FCC is an interpreter and compiler for ANS Forth. It has a portable C
implementation, and a bootstrapping Forth library that runs on top of it.

## Goals

- **Fast** - ideally competitive with Gforth.
  - Currently the performance is respectable, but it doesn't rival `gforth-fast`.
- **Portable** to many platforms both rich and embedded.
  - It should be portable to most things with a C compiler, and translating the C
    to assembly by hand is tractable. Most of the heavy lifting is in Forth.
  - The library is (barring bugs) flexible regarding the sizes of cells, chars
    and address units. It does assume cells are big enough for a pointer, so it
    probably won't work on 8-bit machines.
- **Standard** - follow the ANS Forth standard.
  - Currently the Forth 2012 version, see below for compliance details.
- **Interoperable** with C libraries, similar to Gforth's technique.
  - One of my projects is a [Gameboy emulator](https://github.com/shepheb/forthboy);
    that requires SDL.
  - No progress on this front so far.
- **Unencumbered** by the GPL. Gforth being licensed under the GPL and the
  bootstrapping nature of Forth conspire to make it tricky, and sometimes
  impossible, to release a Forth binary built with Gforth without including its
  full source.
  - For some of my projects, that is an unacceptable restriction.
  - FCC is released under the Apache license 2.0, and therefore does not limit
    your ability to release FCC, or binaries built with it.

## Current state

The portable C version is fairly complete. (Standards compliance details below.)

It has been tested in Linux on `arm32` and `x86_64`, built using `gcc`. Your
mileage may vary on other platforms, processors or compilers.

### DCPU

One of my side projects is writing a Forth OS for the
[DCPU-16](https://raw.githubusercontent.com/gatesphere/demi-16/master/docs/dcpu-specs/dcpu-1-7.txt),
the fake 16-bit CPU invented by Notch for the now-defunct game `0x10c`. A
partial attempt to assemble this Forth for it is in `dcpu/`.

## Standards Compliance

This section details the compliance of FCC with the [Forth 2012 standard](http://forth-standard.org/)

FCC is a **Forth-2012 System**.

All standard CORE words are implemented.

### Core Extensions

Providing `.(`, `0<>`, `<>`, `?DO`, `ACTION-OF`, `AGAIN`, `BUFFER:`, `CR`,
`DEFER`, `DEFER!`, `DEFER@`, `ERASE`, `FALSE`, `IS`, `NIP`, `PAD`, `PICK`,
`ROLL`, `TO`, `TRUE`, `TUCK`, `U>`, `UNUSED`, and `VALUE` from the Core
Extensions word set.


Providing `.(`, `.R`, `0<>`, `0>`, `2>R`, `2R>`, `2R@`, `:NONAME`, `<>`, `?DO`,
`ACTION-OF`, `AGAIN`, `BUFFER:`, `C"`, `CASE`, `COMPILE,`, `DEFER`, `DEFER!`,
`DEFER@`, `ENDCASE`, `ENDOF`, `ERASE`, `FALSE`, `HEX`, `HOLDS`, `IS`, `MARKER`,
`NIP`, `OF`, `PAD`, `PARSE`, `PARSE-NAME`, `PICK`, `REFILL`, `RESTORE-INPUT`,
`ROLL`, `SAVE-INPUT`, `SOURCE-ID`, `TO`, `TRUE`, `TUCK`, `U.R`, `U>`, `UNUSED`,
`VALUE`, `WITHIN`, `\`.

(Everything but `S\"` and `[COMPILE]`.)

### Implementation-defined Options

As required in Section 4.1.1, and appearing in the same order.

- Cell-aligned addresses are aligned to the pointer size of the host machine
  (eg. 32 bits on 32-bit machines, 64 bits on 64-bit machines).
- `EMIT` will try to print whatever you give it; the result depends on the
  output device, generally the terminal.
- `ACCEPT` uses GNU readline to support editing.
- The character set for `EMIT` and `KEY` is standard ASCII.
- All addresses are character-aligned, since characters and address units are
  the same size (bytes, 8 bits).
- Spaces (`0x20`, `' '`) and tabs (`0x09`, `'\t'`) are treated as spaces.
- The control-flow stack is the data stack during compilation of a definition.
- Digits larger than 35 are not converted and will be treated as the end of the
  number being parsed.
- `ACCEPT` echoes the entered text. It does not put the newline character into
  the input, but it does display a newline.
- `ABORT` is equivalent to `QUIT`: it clears the stacks, sets the input source
  to the user input device, and continues interpreting.
- Uses the GNU `readline` library for reading input, so line endings are
  abstracted. Whatever your terminal accepts, essentially.
- Counted strings have a maximum length of 255 characters.
- Parsed strings have a maximum length of 255 characters.
- Definition names have a maximum length of 255 characters.
- No limit on the length of `ENVIRONMENT?` queries.
- File names can be given on the command line; they will be loaded in order.
  Then the input device will remain the user's terminal.
- The only supported output device is the user's terminal. (It can be redirected
  to a file or other process, if the shell supports that.)
- Dictionary definitions take this form:
    - link pointer (points to the previous definition, forming a linked list)
    - metadata cell. The name is in the low byte. `0x100` indicates hidden,
      `0x200` indicates an "immediate" word.
    - pointer to the name
    - code field
- An address unit is that of the host machine, generally an 8-bit byte.
- Number representation is that of the host machine, generally 2s complement.
- Ranges of numeric types, where **m** is the number of bits in a pointer/cell
  on the host machine:
    - `n`: -(2^(m-1)) to 2^(m-1) - 1
    - `+n`: 0 to 2^(m-1) - 1
    - `u`: 0 to 2^m - 1
    - `d`: -(2^(2m-1)) to 2^(2m-1) - 1
    - `+d`: 0 to 2^(2m-1) - 1
    - `ud`: 0 to 2^(2m) - 1
- Writing to any part of data space is permitted. (Though changing eg. the
  dictionary's link pointers might result in ambiguous conditions.)
- `WORD` uses `HERE` as its buffer; therefore it is large (and very transient).
- A cell is the same size as a pointer on the host machine. Generally, an
  address unit is a byte, so a cell is 4 units on a 32-bit machine and 8 on a
  64-bit machine.
- A character is a single address unit (generally a byte).
- The keyboard input buffer is dynamically allocated by `readline`, and is
  limited only by system RAM. (The parse buffer will truncate the input to 256
  characters, however.)
- The pictured numeric string area is `HERE`, therefore very large (and very
  transient).
- `PAD` returns an area of 1024 address units (bytes, usually).
- FCC is case-insensitive.
- The prompt looks like `"   ok\n> "`.
- Uses the host system's division routines. (Usually libc, which is symmetric.)
- `STATE` is either `0` (interpreting) or `1` (compiling).
- Arithmetic overflow is that of the host system. Generally, wrapping around and
  not throwing exceptions.
- After a `DOES>`, the current definition is *hidden*.


### Ambiguous Conditions

General conditions, in the same order as Section 4.1.2.

- When a name is neither a valid definition name nor a valid number, the error
  message `*** Unrecognized word: xyz` is written to the standard error stream.
- When a definition name is too long (more than 255 bytes) it might be
  considered immediate or hidden wrongly. Results will be unpredictable.
    - TODO: That could be checked.
- Addressing outside the data space might work normally, might segfault (or
  similar) or might do something else (bus errors, maybe).
- Types are not checked, and most types (eg. flags) are cell-sized integers.
  Passing wrong types therefore might result in odd behavior, but not in a
  checked type error.
- Asking for the `xt` of a word without interpretation semantics generally
  will return an `xt`, but executing it will be ambiguous.
- Dividing by zero will cause a system exception and exit FCC.
    - TODO: Catch and handle that more gracefully, probably by `QUIT`ting.
- Stack overflows might cause a segfault (or similar) but might also overwrite
  other memory.
- Loop-control parameters are on the return stack, so see above.
- The dictionary headers and data space are the same block. The portable C
  version `malloc()`s 4 megabytes by default; overflowing it will probably cause
  a segfault or similar.
- Interpreting a word with undefined interpretation semantics (like `IF` or
  `WHILE`) will usually consume and/or add junk on the stack, may read or write
  memory unpredictably, and therefore may cause a segfault.
- Modifying the input buffer is not formally supported, but it will work
  as one would expect: the edited text is what gets parsed. Likewise, editing
  string literals should work sanely, though it's not formally supported.
- Pictured numeric output uses data space after `HERE`, so overflow is unlikely
  (and described above).
- Parsed strings are dynamically allocated by `readline`, so overflow there is
  usually impossible (other than exhausting the system RAM). A maximum of 256
  bytes of each input line are copied to the parse buffer, so no overflow is
  possible there.
- Out-of-range results are treated like any arithmetic overflow.
- `:` checks that the definition name has nonzero length, and outputs `*** Colon
  definition with no name` to standard error if a 0 length is found. `CREATE`
  and others do not check, and will compile a word with a 0-length name, which
  can never be executed.
    - TODO: `CREATE` should check that properly.

Conditions specific to particular words, in the same order as Section 4.1.2.

- `>IN` being greater than the parse length should be handled as though it were
  equal to the parse length, ie. as an empty parse area.
- `RECURSE` after `DOES>` is unknown.
- `RESTORE-INPUT` is not implemented.
- De-allocating space containing definitions will do nothing in the near term -
  the latest-definition pointer is unchanged, and the definitions still exist.
  However, when anything is written to data space, including a new definition,
  the dictionary's linked list will be broken, with unpredictable results
  (probably an infinite loop, but maybe not).
- Reading and writing from unaligned addresses might work normally, but might
  also cause a bus error or other system error. It depends on the platform and
  machine.
- A misaligned data pointer in `,`, `C,` etc. is the same as above. This
  condition is not checked.
- `PICK` and `ROLL` with too few stack items is likely to cause a segmentation
  fault, but might read/write other memory at random.
- Loop-control parameters go on the return stack at runtime. If that stack has
  changed, then both the loop and returning will be broken unpredictably.
- `IMMEDIATE` works whether the previous definition has a name or not.
- `TO` without a following name will emit an error message, and continue.
- `'`, `POSTPONE`, and `[']` all return/compile an `xt` of `0` if the word is
  not found. `[COMPILE]` is obsolete, and not implemented.
    - TODO: They should check that, probably.
- Parameter mismatch to `DO`, `DO?`, and `WITHIN` is ambiguous. It's unchecked,
  and unknown what might happen.
- Attempting to get the `xt` of `TO` (with `'`, `POSTPONE` or `[']`) should
  succeed silently. Executing that `xt` is ambiguous.
- If `WORD` returns a string too long for a counted string (255 characters), the
  length will be reduced modulo 256.
- Shifting by more than the width of a word will probably result in 0,
  harmlessly.
- `>BODY` for words not defined by `CREATE` will return the address of the
  second cell after their code field. Harmless, but not useful in general.
  `DOES>` for words not defined by `CREATE` will overwrite the cell 2 cells
  after the code field, which might be any other data.
- Using the pictured numeric output words outside `<#` `#>` will cause
  unpredictable results, and usually mangle parts of the stack and write into
  data space after `HERE`.
- Words defined with `DEFER` which are accessed before being assigned an `xt`
  will attempt to `EXECUTE` with `0` as the CFA, which is a segfault.
- Accessing a non-deferred word like a deferred word will treat it like a
  variable; that is, the first cell after its code field will be read and
  written.
    - TODO This could be checked, I guess?
- Applying `'`, `[']` or `POSTPONE` to `ACTION-OF` or `IS` will probably work
  normally. Those words are pretty ordinary (immediate) words.
- `S\"` is not supported.


### Other Documentation

- There are no nonstandard words that use `PAD`. It belongs to the user.
- The terminal input is read with `readline`, so line editing it supported
  nicely.
    - History is not supported, however.
    - TODO: History would be handy.
- Data/dictionary space is allocated as 2^12 address units (usually 4 megabytes)
  by default.
    - (That's roughly 1 million cells on a 32-bit machine, or half a
      million cells on a 64-bit machine.)
    - More can be allocated with the nonstandard phrase
      `nnn (ALLOCATE) (>HERE) !` if desired (where `nnn` is some number of
      address units).
- The return stack holds 1024 cells.
- The data stack holds 16,384 (16K) cells.
- The system uses less than 2000 cells of data space currently.
