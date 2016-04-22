# Superinstructions Design

Following Ertl01, the plan is to create an interpreter that uses a hybrid
technique of direct and indirect threading.

As of this writing the engine in `portable/` is functional and
Standard-compliant, but not very fast. It's a fairly naive indirect-threaded
interpreter.

I want to rebuild the engine to support much faster execution at the expense of
some memory and complexity, using an approach of primitive-centric direct
threading, with superinstructions.

## Execution Model

There will be a small set of perhaps 60 "primitives". These are the basic,
irreducible instructions. Math, comparisons, memory access, basic I/O, control
flow, literals, etc.

From those, a larger set of "superinstructions" will be constructed that combine
several primitives into 1 jump, further accelerating performance.

A compiled definition will be a direct-threaded series of code addresses.

### Pros

- Much faster execution: the `NEXT` at the end of each superinstruction will
  jump straight to the address found at `ip`.
- Combining primitives into superinstructions further reduces the number of
  jumps and amount of memory traffic.
- The superinstructions can be further optimized (eg. peephole optimization) to
  reduce memory traffic and keep values in registers.
- Easy to separate word headers from implementations.

### Cons

- Debuggability: This is why `gforth` and `gforth-fast` are separate binaries.
  When the definitions are hacked up into superinstructions and inlined, there's
  no easy way to reconstruct them anymore, or even tell which definition it is.
- Implementation complexity, of course.
- Memory use - the total amount of machine code to implement the
  superinstructions goes up. Also, the primitive-centric threaded code also
  includes a lot more inline operands, esp. for `call`.

## Choosing Superinstructions

There are a few obvious ones (`+ @`, `lit + @`, `lit @`) but it's not clear what
the total set should look like, how many there should be, etc.

There's some empirical evidence in Ertl's various papers that suggest that
returns begin to diminish after a few hundred superinstructions.

It seems convenient from an implementation POV to make each superinstruction's
equivalent list of primitives reducible to a 32-bit value.

Also, if the superinstructions are being hand-written or hand-optimized (see
below) then the maximum number is obviously limited.

### Dynamic Superinstructions

One clever possibility is generating new superinstructions dynamically, almost
like a JIT. That's quite a bit more complex, especially if we also want to be
able to optimize the resulting combinations more than just by `cat`ing them
together.

On the whole, I think I'll punt on this one.

### Gradual Refinement of Static Superinstructions

I'll add a flag to the binary that makes it run an accounting rig dynamically at
runtime. It'll record the number of times particular 2-, 3- and 4-primitive
sequences appear, and how many times particular superinstructions are run.

By running whatever Forth applications I want (the test suite, the Gameboy, the
Z-machine, the DCPU interpreter) and eyeballing the accounting results, I can
determine what sequences of primitives are most profitably turned into
superinstructions.

Eventually, the hope is that existing superinstructions will dominate the flow,
and there will be no standouts for conversion, just a long tail of rare or
application-specific sequences.

## C Functions and Superinstructions

Some of the functions are rare and complex (`:`, `compile,`, `(find)`) and I'll
just leave them as C functions and ignore them in the accounting output.

However most of the basic primitives (math, logic, memory access, etc.) are
nicely convertible to assembly and thence into superinstructions.



# Original Design Notes

**The below is the original design notes for FCC. Almost no part of them ended
up being accurate.**

FCC is a Forth compiler compiler. That is, it's an interpreter and compiler for
Forth systems that can compile itself from scratch, and compile Forth programs
liekwise.

## Compilation process

There are several stages to compiling FCC, and compiling software with FCC.

It is not necessary to start from Stage 0; indeed FCC ships with Stage 1
(UPDATE) already compiled for a given platform.

### Stage 0 - Standalone interpreter

FCC includes a basic Forth interpreter, which is written by hand in portable C.
This interpreter is minimal, and not very efficient, but it's sufficient to load
the library (see below) and the rest of the compiler.

### Stage 1.0 - Platform-specific Forth assemblers

The directory `asm/$platform/asm.fs` defines a set of assembler commands in
Forth, that output their text into an assembly file for compiliation by a third
party tool like GNU `asm`.

### Stage 1.1 - Cross-platform Forth "VM"

Part of Stage 1.0 is that each assembler defines, in terms of its own
primitives, a universal set of words for various Forth primitives, like basic
math, reading and writing variously-sized values, and stack operations.

### Stage 1.2 - Cross-platform Forth core

A basic Forth system, written in the above cross-platform operations, also
sufficient to load the library, or to perform all of Stage 1. Equivalent in
power, but different in source, than Stage 0.

### Stage 1 - Overall

All of Stage 1 together results in an equivalent to Stage 0 - a basic Forth
system.

### Stage 2 - Forth compiler

A more sophisticated Forth tool capable of inlining and otherwise optimizing
Forth code. It is used to compile the core used in Stage 1.2 and the library,
resulting in an optimized Forth core.

### Stage 3 - Forth compiler, compiled

The compiler compiles itself, resulting in an optimized and fast compiler, which
can be deployed if Forth loading and compilation is desired at deployment-time.

This is also the fast compiler you might build, and then run over your code.

### Stage 4 - Compiling your code

The Stage 3 optimized compiler is used to compile the core, library and user
code to produce a fast binary.

## Current state

Haven't even started. This doc is a pipe dream.

## Future Work

- Allow deploying the stage 3 compiler along with user code, and generating
  efficient Forth code at runtime in deployments.
- Using the above for FOAM-style metaprogramming.
