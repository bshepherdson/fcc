# Design Notes

FCC is intended to be an eminently portable, and ideally also performant, Forth
system.

The original plan, which gave fcc its name ("Forth Compiler Compiler"), called
for much more metaprogramming than goes on in this version.

## Model

Here's the layers of the FCC system:

- Layer 0: Virtual machine, written by hand for the host computer.
    - `portable/` contains a portable C implementation of this VM.
- Layer 1: Low-level Forth library
    - Uses the Forth VM library in `assembler/` to build the heart of the Forth
      system in Forth. Defines machine-independent parts of the engine, enough
      to support `:` and other basic words.
- Layer 2: ANS Forth 2012 library
    - Uses Layer 1's core Forth pieces to build a full Forth system.
- Layer 3 and up: User code on top of the above.

The portability comes from the fact that only Layer 0 needs to be ported for
different platforms.

## Organization

`portable/` contains a C version of layer 0.

`assembler/` contains an assembler for VM code written in Forth. The assembler is
capable of cross-compilation, meaning that you can use a build of FCC on one
machine (say, any platform supported by Gforth or having a binary of FCC) to
target another (including self-hosting FCC). `assembler/scripts/` contains
scripts that load the assembler and configure it for various platforms.

`layer1/` contains code that uses the above assembler to define Layer 1's
low-level operations.

`layer2/` contains the Forth files for the main ANS Forth 2012 system.

## Compilation

To start from a fresh checkout of this repository, you'll need two things:

- A C compiler, like gcc or Clang.
- A standard-ish Forth system, that can run the assembler.
    - Since this project previously resulted in a portable C system roughly
      equivalent to Layers 0 and 1, it can be used to bootstrap FCC.

`./bootstrap.sh` will use the included portable C Forth core in `bootstrap/` to
build FCC for the current machine.

### Building by hand

If you like doing things by hand, can't execute that script, or are
cross-compiling, here are the manual steps:

1. Acquire a standard-ish Forth system.
    1. Run `make` in `bootstrap/` to use that one, if you like.
1. Run `make` in `portable/` to get Layer 0.
1. Switch to `layer1/`. Run it with your standard-ish Forth system.
    1. Configure its parameters for your target machine.
    1. Execute `assemble` to build the output.


## Current state

Haven't even started. This doc is a pipe dream.

