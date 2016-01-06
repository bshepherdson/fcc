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

Providing `.(`, `.R`, `0<>`, `0>`, `2>R`, `2R>`, `2R@`, `:NONAME`, `<>`, `?DO`,
`ACTION-OF`, `AGAIN`, `BUFFER:`, `C"`, `CASE`, `COMPILE,`, `DEFER`, `DEFER!`,
`DEFER@`, `ENDCASE`, `ENDOF`, `ERASE`, `FALSE`, `HEX`, `HOLDS`, `IS`, `MARKER`,
`NIP`, `OF`, `PAD`, `PARSE`, `PARSE-NAME`, `PICK`, `REFILL`, `RESTORE-INPUT`,
`ROLL`, `SAVE-INPUT`, `SOURCE-ID`, `TO`, `TRUE`, `TUCK`, `U.R`, `U>`, `UNUSED`,
`VALUE`, `WITHIN`, `\` from the Core Extensions word set.

(Everything but `S\"` and `[COMPILE]`.)

### Tools

Providing the Tools word set.

Providing `AHEAD`, `SYNONYM`, `N>R`, `NR>`, `[DEFINED]`, and `[UNDEFINED]` from
the Tools Extensions word set.
`
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

- A *name* is neither a valid definition name nor a valid number during text
  interpretation (3.4)
    - The error message `*** Unrecognized word: xyz` is written to the standard
      error stream.
- A definition name exceeded the maximum length allowed (3.3.1.2)
    - When a definition name is too long (more than 255 bytes) it might be
      considered immediate or hidden wrongly. Results will be unpredictable.
    - TODO: This error case could be checked and reported nicely.
- Addressing a region not listed in 3.3.3 Data space
    - Addressing outside the data space might work normally, might segfault
      (or similar) or might do something else (bus errors, maybe).
    - In other words, memory accesses are native system memory accesses, and
      trigger system errors.
- Argument type incompatible with the specified input parameter (3.1)
    - Types are not checked, and most types (eg. flags) are cell-sized
      integers.
    - Passing wrong types therefore might result in odd behavior, but not in a
      checked type error.
- Attempting to obtain the execution token of a definition with undefined
  interpretation semantics
    - Asking for the `xt` of a word without interpretation semantics generally
      will return an `xt`, but executing it will be an ambiguous condition
      (probably a segfault).
- Dividing by zero
    - Dividing by zero will cause a system exception and exit FCC.
    - TODO: Catch and handle that more gracefully, probably by `QUIT`ting.
- Insufficient data-stack space or return-stack space (stack overflow)
    - Stack overflows might cause a segfault (or similar) but might also
      overwrite other memory.
- Insufficient space for loop-control parameters
    - Loop-control parameters are on the return stack, so see above.
- Insufficient space in the dictionary
    - The dictionary headers and data space are the same block. The portable C
      version `malloc()`s 4 megabytes by default; overflowing it will probably
      cause a segfault or similar.
    - TODO: Make `ALLOT` check this condition and allocate more space when
      possible.
- Interpreting a word with undefined interpretation semantics
    - Interpreting a word with undefined interpretation semantics (like `IF` or
      `WHILE`) will usually consume and/or add junk on the stack, and may read
      or write memory unpredictably, and therefore may cause a segfault.
- Modifying the contents of the input buffer or a string literal (3.3.3.4,
  3.3.3.5)
    - Modifying the input buffer is not formally supported, but it will work
      as one would expect: the edited text is what gets parsed. Likewise,
      editing string literals should work sanely, though it's not formally
      supported.
- Overflow of a pictured numeric output string
    - Pictured numeric output uses data space after `HERE`, so overflow is
      unlikely (and described above).
- Parsed string overflow
    - Parsed strings are dynamically allocated by `readline`, so overflow there
      is usually impossible (other than exhausting the system RAM). A maximum
      of 256 bytes of each input line are copied to the Forth parse buffer, so
      no overflow is possible there.
- Producing a result out of range
    - Out-of-range results are treated like any arithmetic overflow. Usually
      that means the result is truncated to fit in a cell.
- Reading from an empty data stack or return stack (stack underflow)
    - Not checked. Might return nonsense results, or might cause a segfault.


- `:` checks that the definition name has nonzero length, and outputs `*** Colon
  definition with no name` to standard error if a 0 length is found. `CREATE`
  and others do not check, and will compile a word with a 0-length name, which
  can never be executed.
    - TODO: `CREATE` should check that properly.

Conditions specific to particular words, in the same order as Section 4.1.2.

- `>IN` greater than size of input buffer (3.4.1)
    - Should be handled as though it were equal to the parse length, ie. as an
      empty parse area.
- `RECURSE` appears after `DOES>`
    - Unknown. Probably a segfault or infinite loop.
- argument input source different than current input source for `RESTORE-INPUT`
    - `RESTORE-INPUT` is not implemented.
- Data space containing definition is de-allocated (3.3.3.2)
    - De-allocating space containing definitions will do nothing in the near
      term - the latest-definition pointer is unchanged, and the definitions
      still exist.
      However, when anything is written to data space, including a new
      definition, the dictionary's linked list will be broken, with
      unpredictable results (probably an infinite loop, but maybe not).
- Data space read/write with incorrect alignment (3.3.3.1)
    - Reading and writing from unaligned addresses might work normally, but
      might also cause a bus error or other system error. It depends on the
      operating system and architecture.
- Data-space pointer not properly aligned for `C,` or `,`
    - A misaligned data pointer in `,`, `C,` etc. is the same as above. This
      condition is not checked.
    - TODO: `,` could check this and give a good error message.
- Less than u+2 stack items with `PICK` and `ROLL`
    - `PICK` and `ROLL` with too few stack items is likely to cause a
      segmentation fault (see stack underflow), but might read/write other
      memory at random.
- Loop-control parameters not available (`+LOOP`, `I`, `J`, `LEAVE`, `LOOP`,
  `UNLOOP`)
    - Loop-control parameters go on the return stack at runtime. If that stack
      has changed, then both the loop and returning will be broken
      unpredictably.
- Most recent definition does not have a *name* (`IMMEDIATE`)
    - `IMMEDIATE` works whether the previous definition has a name or not.
- `TO` not followed directly by a *name* defined by a word with "`TO` *name*
  runtime" semantics (`VALUE`, `(LOCAL)`)
    - `TO` without a following name will emit an error message, do nothing, and
      continue.
- *name* not found (`'`, `POSTPONE`, `[']`, `[COMPILE]`)
    - An `xt` of `0` is silently returned. That will segfault if passed to
      `EXECUTE` or compiled into a definition which is later executed.
    - (`[COMPILE]` is obsolete and not implemented.)
    - TODO: This condition is easily checked.
- Parameters are not of the same type (`DO`, `?DO`, `WITHIN`)
    - Parameter mismatch to `DO`, `DO?`, and `WITHIN` is ambiguous. It's
      unchecked, and unknown what might happen.
- `POSTPONE`, `'` or `[']` is applied to `TO`
    - Attempting to get the `xt` of `TO` (with `'`, `POSTPONE` or `[']`) should
      succeed silently. Executing that `xt` is ambiguous (probably segfault).
- String longer than a counted string returned by `WORD`
    - Lengths longer than 255 will be reduced modulo 256.
- *u* greater than or equal to the number of bits in a cell (`LSHIFT`, `RSHIFT`)
    - Shifting by more than the width of a word will probably result in 0,
      harmlessly.
    - That might not be true on architectures that handle arithmetic overflows
      with errors rather than truncating to fit in a cell.
- word not defined via `CREATE` in `>BODY`, `>DOES`
    - `>BODY` for words not defined by `CREATE` will return the address of the
      second cell after their code field. Harmless, but not useful in general.
    - `DOES>` for words not defined by `CREATE` will overwrite the cell 2 cells
      after the code field, which might be any other data, like the start of the
      next word.
- Pictured numeric output words improperly used outside `<#` and `#>`
    - Unpredicable in general. Usually, this will mangle the top few cells on
      the stack, and write into data space after `HERE`.
- Access to a deferrred word which has yet to be assigned to an *xt*
    - Attempts to deference `0`, causing a segfault.
- Accessing a non-deferred word like it was deferred
    - Generally will treat the word like a variable. That is, the first cell
      after its code field will be read and written.
    - TODO This could be checked, probably.
- `POSTPONE`, `'` or `[']` to `ACTION-OF` or `IS`
    - Will probably work normally. `ACTION-OF` and `IS` are pretty ordinary
      (immediate) words.
- `\x` is not followed by two hexadecimal characters (`S\"`)
    - `S\"` is not supported.
- a `\` is placed before any character other than those defined in `S\"`
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
