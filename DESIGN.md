# Design Notes

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
