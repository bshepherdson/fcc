# FCC - Portable C engine

This C code implements a modest set of library functions for Forth. This enables
the resulting Forth system to run on more or less any machine we have a decent C
compiler for. It should be fairly straightforward to write a compatible
implementation in assembly code on other systems.

There is of course an associated library written in Forth itself. It is intended
that this library use words hiding the system details (eg. `>CODE`, `CELLS`) so
that it is portable across machines.

## Problems with the C stack

In using the portable C engine, it was discovered that certain words, especially
those calling other library functions, were allocating space on the C stack
(either to save registers, or apparently without need). Since the words don't
return normally, the C stack was never getting cleaned up.

### Portably Fixing this Problem

I tried to find GCC flags or function attributes that would fix this problem, or
a way to force GCC to include the usual function epilogue code at the start of
`NEXT`.

I could not find such a way that works cross-platform. On ARM, GCC supports the
`naked` attribute, which would probably work. No prologue or epilogue is
necessary, and `naked` tells GCC not to include it.

Clang supports `naked` on all platforms, so I tried that. Clang is too much of a
nanny, and I would need to find a way to override two of its unsuppressable
errors:
- Computed GOTOs leaving the function inside `NEXT`. (Whether `naked` or not.)
- Only inline `asm` statements are "safe" inside a `naked` function. I know
  that, and I'm prepared to take the risk since this isn't normal C code.

Neither of those errors can be disabled in current Clang, so it's off the table
too.

### Solution: Hand-optimized Assembly Code

Instead, I took the generated assembly output (on `x86_64` only so far) and
optimized it by hand, removing the code that allocates C stack space
incorrectly.

In doing so, I also noticed that the generated code was often much less
efficient than it could have been. In particular, I was armed with the extra
information that the `c1`, `str1` and other global variables are actually
scratch space, and writing them can be optimized away most of the time.

### Problems with That

Of course, now the engine is only portable-ish. The pure C version should work
passably, but eventually it will leak enough C stack space to overflow and
crash.

`make` (defaults to `make forth`) uses the assembly code from
`asm/$PLATFORM/vm.s` and ignores `vm.c`.

To port to a new platform:

```
$ make asm    # Creates vm_raw.s
$ mkdir asm/`uname -m`
$ mv vm_raw.s asm/`uname -m`
$ make
```

That will work, but it's got the memory leaks and inefficiencies discussed
above. I recommend hand-optimizing the assembly to

1. Remove the needless stack allocations. There's no caller to return to, so no
   registers need to be saved. And there's usually no need for scratch space or
   using the stack for calls to other functions, but if there is, clean it up
   before the `NEXT` part begins.
2. Optimize generally. Writing to the global scratch variables can be avoided,
   and there's often just useless write-then-read fiddling that can be removed.

## Engine Design

The engine was originally indirect threaded, but that is long gone.

The current model is direct threading, where some primitives have a following
value and some do not. Branches, literals and others have data following, as do
`dodoes` words, but primitive invocations don't.

As words are `compile,`'d (usually inside a colon definition), they're actually
enqueued with their data, and only when the queue is full (or we reach a control
flow checkpoint like a branch or semicolon) do real operations get emitted.

The purpose of this complexity is to allow matching against "superinstructions".
These are essentially 2, 3 or 4 primitives commonly executed in sequence, which
have been inlined into a single primitive. (A few examples help: `R> DUP >R`,
`+ @`, `DUP >R`.)

### Performance

The move to direct threading brought a roughly 2x speedup over the indirect
threading version.

Adding a solid set of superinstructions brought another 2x speedup, and the
hand-optimization of the assembly has so far brought a further 10% or so.

However, for most workloads FCC is still 8-12 times slower than Gforth (on
`x86_64` Linux; haven't tried elsewhere).


## Engine words

Here are all the words defined natively by the engine, which must be implemented
by any compatible runtimes.

It is not a minimal set; some more operations could be extracted. All operations
in `(...)` are internal, nonstandard words.

- Math: `+`, `-`, `*`, `U/`, `/`, `MOD`, `UMOD`
- Bitwise: `AND`, `OR`, `XOR`
- Shifts: `LSHIFT`, `RSHIFT`
- Comparison: `<`, `U<`, `=`
- Stack: `DUP`, `SWAP`, `DROP`, `OVER`, `ROT`, `-ROT`, `2DROP`, `2DUP`, `2SWAP`,
  `2OVER`, `>R`, `R>`, `DEPTH`, `SP@`, `SP!`, `RP@`, `RP!`
- Variables: `BASE`, `STATE`
- Memory: `@`, `!`, `C@`, `C!`, `(ALLOCATE)`, `(>HERE)`, `EXECUTE`
- Control flow: `(BRANCH)`, `(0BRANCH)`, `QUIT`, `EXIT`, `BYE`
- Input: `REFILL`, `>IN`, `ACCEPT`, `KEY`, `SOURCE`, `SOURCE-ID`
- Output: `EMIT`, `.S`, `U.S`
- Words: `(LATEST)`, `(>CODE)`, `>BODY`, `(LAST-WORD)`
- Doers: `(DOCOL)`, `(DOLIT)`, `(DOSTRING)`, `(DODOES)`
- Parsing: `PARSE`, `PARSE-NAME`, `>NUMBER`, `CREATE`, `(FIND)`, `EVALUATE`
- Defining: `:`, `:NONAME`, `;`, `COMPILE,`, `LITERAL`, `[LITERAL]`,
  `[0BRANCH]`, `[BRANCH]`, `(CONTROL-FLUSH)`, `(DEBUG)`
- Portability: `CELLS`, `CHARS`
- Internals: `(/CELL)`, `(/CHAR)`, `(ADDRESS-UNIT-BITS)`, `(STACK-CELLS)`,
  `(RETURN-STACK-CELLS)`, `(>DOES)`, `(>CFA)`

### Nonstandard words:

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


### Possible future ops

- Something to capture carrying, to enable a double-cell math library. Hard to
  make portable?
- Floating-point math
- A base word usable by `:` and `:NONAME` for creating a new header.
- Is it possible to write `:` in Forth by hand-assembling its own definition,
  using the above new-header word? Probably.
