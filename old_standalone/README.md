# Stage 0 - Standalone Forth interpreter in portable C

This is a standalone C Forth interpreter capable of interpreting the library
(`./lib/*`) and the Stage 1 assemblers and core (`../stage1/**`). See
[../DESIGN.md](../DESIGN.md) for the details on the compilation process.

## Design of Stage 0

Single file of portable C that defines a basic Forth interpreter. It's only used
for bootstrapping the rest of this system at build time.

The interpreter uses indirect threading (if I understand the Forth execution
models correctly). A Forth word is represented by a pointer to a structure that
describes it, including a pointer to its implementation.

Speed is not a concern for this interpreter, so its design and implementation is
quite basic.
