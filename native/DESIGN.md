# Native Code Generation Design

The scheme here is that `:` should compile non-primitives directly into
machine-code functions, written into executable memory.

## Implications of the Design

That basic plan has many facets of fallout that I will articulate below, along
with the intended approach to each.

### Separate Data and Code Space

Since most architectures have nasty cache implications for writing data and code
near each other, we will not do that.

Dictionary information and user data will go in a data space (`HERE` and `,`).

Word implementations will be written into a totally different segment with its
own, hidden pointer. `COMPILE,` and a few branching internals are I think the
only way to interact with the code space.

### Buffered Compilation

Compiling each word therefore requires that all its primitives be buffered in
some internal representation, and only fully finally written out when `;` is
reached.

There may be a middle ground, where it can write as it goes, and not do so much
bookkeeping, but I don't think that's really practical.

The buffering is useful for register allocation and turning labels into actual
instructions.

### Native Code Generation

Primitives will be written as, effectively, assembly instructions with
placeholders for registers and so on.

These primitives are things like math and logic operations, comparisons,
branching primitives, stack operations and system calls.

#### "Big" Primitives

It's fine to write `+` or `AND` as a (small set of) assembly instructions. But
how and where are fundamental but not-quite-primitive operations, like parsing
and handling input sources, be written?

Some possible approaches:

- Write them as C functions, and have a primitive for calling a C function with,
  probably, the top N values on the stack as its arguments.
- Write them in the same way as the primitives - as assembly instructions.
- As (pseudo-)Forth code using more basic primitives, but in such a way as to
  not need parsing.

That last is the most attractive approach, since it's neatly self-hosting and
much more pleasant than writing complex assembly code.

However, what does it look like? Probably a good idea to make the lower levels
of the compiler callable themselves. See below on the workflow for the compiler.


## Compiler Process

There are several steps in the process that turns an input string into an
executable Forth definition.

- Parsing: Find the next word in the input stream, if any.
    - Needs to handle `REFILL` to get the next line from this source, or the
      next source.
- Lookup: Try to match the string against the dictionary.
    - Number parsing: If the lookup fails, try to parse as a number.
        - To meet the Standard this needs to include `$10 == 16` and so on.
- Dispatch: There are at least three types of things that need compiling.
    - Primitives: A list of assembly ops, which should be compiled directly.
    - Non-primitives: (other compiled Forth words) which should be compiled as a
      save-state-and-jump-in operation (which is probably itself a primitive).
    - Literals: Which are compiled as a load into some register.
- Compilation: Entry points for each of the above types, which eventually result
  in appending 0 or more instructions to the output.
- Output: Emitting the buffered, compiled output into a final form that will
  actually be executable.

As noted above under "Big Primitives", it would be useful in bootstrapping to
have the Compilation layer above have a well-defined interface that can be
called sanely from C code. That allows hand-constructed definitions without
needing the parser and input sources to be defined yet.

### Primitives

The following is an attempt at a complete list of all the required primitives:

- Math: `+` `-` `*` `/` `MOD` `U/` `UMOD`
- Bitwise: `AND` `OR` `XOR` `LSHIFT` `RSHIFT`
- Comparison: `<` `=` `U<`
- Stack: `DUP` `SWAP` `DROP` `SP@` `SP!` (Minimally. `OVER` `ROT` `-ROT` and
  `2foo` might be useful/fast as well)
- Return Stack: `>R` `R>` `R@` `RP@` `RP!`
- Memory: `@` `!` `C@` `C!` `(>HERE)` (or some similar scheme for the data space
  pointer?)
- Branching: See below.
- Sizing: `CELLS` `CHARS` (or similar)
- Defining: `:` `;` `CREATE` `DOES>` `:NONAME`
- Misc: `EXECUTE` `>BODY`
- Literals: `(DOLIT)` `(DOSTRING)` or similar.
- Calls: `(CALL)` (for calling other non-primitives) and maybe `(C-CALL)` for
  calling C functions?

That's a pretty long list, and it's not quite minimal.

Ideas for making it smaller, simpler:

- Implement most of the larger words, like the defining words, in bootstrapped
  pseudo-Forth. There are no real primitive operations there.


#### Primitive Representation

As compilation proceeds, the compiler will do bookkeeping to determine which
stack values are in which registers. Because of the nature of the stack, even on
machines that support `a + b -> c` style, it's fine to have only `a + b -> a`
style.

Actually, arguments to a primitive can be either registers or literals. Trying
to do `add 4 3` as a primitive actually differs importantly from `add sp[0]
sp[1]` - the stack effect of a primitive is not fixed.

(If that would be a useful property, then there are actually 3 adds, for two
stack values, one of each, and two literals.)

Each primitive should actually be implemented as a C function that emits the
correct code, I guess? Then the compiler will just call these and expect them to
do the right thing. They can also modify the compilation state - in particular
which stack values are in which registers.

That lends itself to "online" compilation, that emits as it goes. I'm not sure
that's possible in all cases, especially with forward-referencing labels.

#### Labels and Branching

See photos of whiteboards.

Basic plan is for 6 primitives:

- `(MAKE-LABEL) ( -- label )` introduces a new label without compiling anything.
- `[0branch-fwd] ( -- label )` conditionally branches forward. introduces a new
  label for its target.
- `[branch-fwd] ( -- label )` unconditionally branches forward. new label.
- `(RESOLVE-LABEL) ( label -- )` resolves a previous label to point to here
- `[0branch-bwd] ( label -- )` conditionally branches backward to an
  already-defined label
- `[branch-bwd] ( label -- )` unconditionally branches backward to an
  already-defined label

With those (actually all 6 might not be needed in practice) any Forth control
structure can be implemented.

#### Cross-Platform

In order to support multiple platforms and processor architectures, the
interface to the primitives is decoupled from their implementations.

We effectively have a different `primitives.c` file for each platform, that
wraps its whole contents with an `#ifdef`.

The three platforms I care to support are 32-bit little-endian ARM (probably
v6+?), `x86` and `x86_64`, probably in that order. The x86 variants are nearly
identical, I think?

#### Optimization vs. Specialization

Pushing and then consuming literals is a key pattern in Forth. Lots of the time
those literals are small values like 1 and 0, that can be combined into a
single instruction as an immediate operand.

The representation of the stack should support values in registers and literals
that have not yet actually been constructed.

Then the compilers for each primitive, eg. `+`, will examine the top two stack
entries, and do the right thing based on whether it's receiving two literals,
an inline-able literal, a full-load-needed literal, etc.

#### Mechanics of Primitives

The primitives need access to several pieces of bookkeeping, which should
probably all be encoded into a `compilation_state` structure.

- Stack information: The compile-time sense of where stack values exist. This is
  an ordered list, to which we need quick access to the "top".
    - There are two types of stack entries: allocations to registers, and
      literals that have been sent to the compiler but may not yet exist
      anywhere.
- Register information: Pushing and popping values onto the stack frees and
  requires registers. These should be converted into helper functions.
    - Occasionally those helper functions will themselves have to output
      something, in order to save or load stack values, or push literals.


In order to support that sort of nesting and still be able to write literals,
the things that actually get pushed into the buffer are not literal
instructions. Instead, they're another internal representation, including a
pointer to an "emit" function that will actually write the instruction out.

The compiler then proceeds thus:
- Set up a clean state when we start compiling a definition.
- 0 or more interleaved calls to the "middleware" compiler functions, which
  compile a primitive, non-primitive or literal.
    - Those calls will call the primitive handler functions, which push things
      onto the buffer.
- The master "emit" call comes in when the `;` is reached. The compiler makes a
  final(?) pass over the buffer, calling the `emit` functions of each entry with
  the entry as its argument.
    - When the last of the buffer has been `emit`ed, the compilation is done.

A single, global compiler state is sufficient, but I think I'll still pass it as
an argument for simplicity and sanity.

### C vs. Forth

This is slightly troublesome, since the compiler (written in C) and Forth code
are running interleaved. The Forth code is expecting to have complete control of
the register space and in particular to manhandle the system's stack pointer.

In particular, if the Forth stack lives at the system sp, what are the C
functions of `quit_` and the compiler going to use for their stack? Especially
when Forth `IMMEDIATE` words are running mid-compilation.

I need, I think, machine-specific code for jumping in and out of Forth and C.
Then that code can save and restore the Forth stack pointers, and whatever else
needs to happen.

Since that only happens at the top-level interpreter interface, the speed of
that save/restore logic is not important.

To that end, I'll define `CALL_FORTH` and `RETURN_FROM_FORTH` macros that will
run either side of `quit_`'s jump in.

Actually, that opens the door for things like `refill_` and other internals to
be written in C rather than assembly. Jumping into and out of C is relatively
expensive, though, so probably better to keep that isolated only at the top
level, and write those functions in bootstrapped pseudo-Forth.

