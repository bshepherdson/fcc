# Forth Compiler-compiler

FCC is a Forth compiler compiler. That is, it's an interpreter and compiler for
Forth systems that can compile itself from scratch, and compile Forth programs
likewise.

## Current state

Barely even started.

More specifically, `stage0` (see [DESIGN.md](./DESIGN.md) for details) has an
wildly untested C implementation of the core, and work on the Forth parts is
underway. Long road ahead.

## How does it work?

See [DESIGN.md](./DESIGN.md) for the gory details.

## Future Work

- Allow deploying the stage 3 compiler along with user code, and generating
  efficient Forth code at runtime in deployments.
- Using the above for FOAM-style metaprogramming.
