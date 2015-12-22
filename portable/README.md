# FCC - Portable C engine

This C code implements a modest set of library functions for Forth. This enables
the resulting Forth system to run on more or less any machine we have a decent C
compiler for. It should be fairly straightforward to write a compatible
implementation in assembly code on other systems.

There is of course an associated library written in Forth itself. It is intended
that this library use words hiding the system details (eg. `>CODE`, `CELLS`) so
that it is portable across machines.

## Engine Design

The engine's execution model is indirect threading. Execution tokens (`xt`s) and
threaded code have the same form: a "code field address".

That is, a pointer to a pointer to the machine code to execute a definition.
The code field is part of the header for each word.

With this indirect threading, the code and data can be completely separated;
this is good for cache performance on most machines. It's harmless on machines
without caches, and only a slight cost on machines with fully unified caches.

The header of a word looks like this:

```
link word - pointer to the previous definition in the dictionary
metadata word - see below, includes length, immediate bit, hidden bit, etc.
name pointer - pointer to a raw (non-terminated) string
code field - pointer to where its code lives
```

and what gets compiled into definitions is the **address** of the code field.
The contents of the code field is what should be loaded into the PC.

### `NEXT` behavior

`NEXT` is the fundamental operation of the engine (called the "inner
interpreter" in Gforth parlance). It reads the next CFA from the
next-instruction pointer (probably pinned to a register, but that's the engine
implementer's problem), reads the value stored there, and loads the value stored
*there* into the `PC`.


## Engine words

Here are all the words defined natively by the engine, which must be implemented
by any compatible runtimes.

It is not a minimal set; some more operations could be extracted. All operations
in `(...)` are internal, nonstandard words.

- Math: `+`, `-`, `*`, `/`, `MOD`
- Bitwise: `AND`, `OR`, `XOR`
- Shifts: `LSHIFT`, `RSHIFT`
- Comparison: `<`, `U<`, `=`
- Stack: `DUP`, `SWAP`, `DROP`, `>R`, `R>`, `DEPTH`
- Variables: `BASE`, `STATE`
- Memory: `@`, `!`, `C@`, `C!`, `(ALLOCATE)`, `(>HERE)`, `EXECUTE`
- Control flow: `(BRANCH)`, `(0BRANCH)`, `QUIT`, `EXIT`
- Input: `REFILL`, `>IN`
- Output: `EMIT`
- Words: `(LATEST)`, `(>CODE)`, `>BODY`
- Doers: `(DOCOL)`, `(DOLIT)`, `(DOSTRING)`, `(DODOES)`
- Parsing: `PARSE`, `PARSE-NAME`, `>NUMBER`, `CREATE`, `(FIND)`
- Defining: `:`, `;`
- Debugging: `SEE` (optional)

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
