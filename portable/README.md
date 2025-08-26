# FCC - Fast Forth written in portable C

The C code implements a robust (not at all minimal) set of primitive functions
for Forth. This enables the resulting Forth system to run on more or less any
machine where we have GCC (see Portability below).

There is of course an associated library written in Forth itself. It is intended
that this library use words hiding the system details (eg. `>CODE`, `CELLS`) so
that it is portable across machines.

## Generated primitive code

The actual primitive implementations are built by a Javascript helper. They are
defined in `primitives.js`, and the generated code is `#include`d in the
`engine.c` code.

There are three reasons why code generation is useful:

- It makes abstracting over stack details (eg. TOS in register or not) easy.
- It makes adding and adjusting "superinstructions" easier.
- It can generate a lot of the stack accessing code for you based on a JSON data
  description of the stack effect, handling casts and so on.

The `-O2` assembly output is very nicely optimized and generally all temporary
values live in registers.

## Portability

The C code is mostly portable C17, and in particular the size of a pointer/cell
is abstracted, but there are a few caveats.

- There is some inline assembly for eg. pinning values to registers, that need
  a version for each supported platform.
- GCC extensions (`&&labels_as_values` and `goto *computed_goto`) are used
  crucially.
    - It's known not to work under Clang. I'm not sure it can be fixed with
      the right flags.

There are C preprocessor defines for the right registers on x86_64, 32-bit
ARMv7, and arm64. 32-bit ARM and x86_64 work on Linux; arm64 works on
M1 Macs. (The other combinations, eg. x86_64 on Intel Macs, are likely to
work, maybe with adjustment of flags, but I don't have machines to test on.)

**Windows support** is a non-goal. The POSIX file access routines are used
directly. Porting to Windows would require fixing the file access and the C
interop of eg. `(C-LIBRARY)`, which use `libdl` for dynamic linking at runtime.

### Mac instructions

```bash
$ brew install gcc lld binutils
$ make test
```

If the GCC that installs is not 15.x, then the Makefile must be tweaked.
(Homebrew GCC does not have a symlink or binary for plain `gcc`.)

## Engine Design

This is "primitive-centric" direct threading. That means the code pointers in a
thread are always pointers right to machine code we can execute. There's no
indirection through a DOCOL and similar words; instead `call_forth` and `dodoes`
are put in the thread with the next cell giving the Forth word to call.

### Superinstructions

In order to support inlined "superinstructions" that combine 2, 3 or 4 Forth
words into one call, we buffer compilation when words are `compile,`'d. When the
queue is full, or we reach a control flow checkpoint like a branch or semicolon,
then the queue is really compiled as 1 or more superinstructions and vanilla
primitives.

Superinstructions yield a substantial performance boost by capturing some common
patterns and greatly reducing the memory traffic they cause. Eg. `R> DUP >R`,
`(dolit) + @`, `cells (dolit) + @`, `DUP >R`, `R> R> 2drop` etc.

## Performance

The performance is good on `x86_64` and `arm64`, between 1x and 1.8x slower than
the faster of `gforth` and `gforth-fast`. (For obscure reasons `gforth-fast` is
significantly slower than `gforth` on `arm64`.)

On 32-bit ARM it's somewhat slower, generally 1.2x to 2x on my RasPi 4.

On 64-bit ARM it's similarly slower, on my M1 Mac roughly 1.1x to 1.9x.

### Improving Performance

I'm not sure why the relative performance is so different on x86_64. In
particular it's not clear whether Gforth is unusually slow there, or FCC
unusually fast, or both. Given the importance of x86_64, it seems unlikely
Gforth would be unusually slow there!

I speculate that something about how FCC works is making it slower on ARM.
Perhaps GCC's own optimizations are lacking; I should examine some of the
hotter assembly code (eg. `(LOOP-END)`) to see if it's doing anything
obviously dumb.

Failing that, cache friendliness seems a likely spot to look next. Can we align
primitives or nonprimitives to some kind of page boundaries that would make it
faster?

## Nonstandard words:

All words without surrounding parens are as defined in the Forth 2012 standard
(barring bugs).

All nonstandard, paren-wrapped words are defined in more detail here, in
alphabetical order:

- `(0BRANCH)`: `( ? -- )` Accepts a flag and conditionally branches, when the
  flag is 0 (false). See `(BRANCH)` below for branching spec. When the flag is
  true, it branches to immediately after the unused branch offset.
- `(>CFA)`: `( a-addr -- a-addr )` Takes the address of a word header (eg. from
  `(LATEST)`) and converts it to the CFA (the `xt`).
- `(>DOES)`: `( a-addr -- a-addr )` Takes the address of a word header (eg. from
  `(LATEST)`) and converts it to the address for the `DOES>` code. (See
  `(DODOES)` below.)
- `(>HERE)`: `( -- a-addr )` Address of a cell containing the current `HERE`
  pointer. Allows the library to define `ALLOT`, `HERE`, `,`, etc.
- `(ALLOCATE)`: `( u -- addr )` Given a size in bytes, allocates that many and
  returns a pointer to them. The C version uses malloc; an embedded one might
  simply move an internal pointer.
- `(BRANCH)`: `( -- )` Unconditional, relative branch. The next cell that should
  contain a code-field address is actually a branch offset in address units
  (bytes, usually). The offset is relative the cell the offset is stored in.
  Since the next-word pointer (`ip` in the C version) is running ahead, it can
  be combined with a straight addition (but beware of the pointer size when
  doing pointer math!).
- `(DOCOL)`: The "doer" for ordinary colon definitions: this is the value that
  should go in the code field of colon definitions. In the C version (and
  probably others), it pushes the current next-word pointer onto the return
  stack and then sets the next-word pointer to the first word of its definition.
  (In the C version, that's the word immediately after itself.)
- `(DODOES)`: The "doer" for `CREATE`d definitions. Expects either `0` or an
  `xt` in the first cell after its code field. After this slot is the user data
  area. `(DODOES)` pushes the address of that data area, then if the `(>DOES)`
  slot is empty it sets the next-word pointer as per `EXECUTE`.
- `(DOLIT)`: The "doer" for literal numbers. It pushes the number stored in the
  next cell, and advances the next-word pointer past it. **NB**: This is one of
  the least portable, implementation-revealing things about this design.
    - In particular, it prevents the use of a data field alongside the code
      field, for branches, literals, does> words and so on.
    - Alternative designs welcome! Only `LITERAL` and `DOES>` use `(DOLIT)`
      directly; everything else uses `LITERAL`.
- `(DOSTRING)`: The "doer" for literal strings. Reads a one-address-unit length
  from the next address unit, and then that many chars worth of string. Pushes
  them onto the stack as `( c-addr u )`, and moves the next-word pointer past
  the string. The pointer is cell-aligned after the operation.
- `(FIND)` `( c-addr u -- xt 1 | xt -1 | 0 0 )` More convenient, modern version
  of `FIND`, which uses counted strings. In other words, `: FIND count (find) ;`
- `(LATEST)`: `( -- a-addr )` The address of the header for the
  most-recently-defined word. That word might have been defined by `CREATE`,
  `:`, or `:NONAME`, or any other similar defining word.
