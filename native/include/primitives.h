#ifndef PRIMITIVES_H
#define PRIMITIVES_H

#include <compiler.h>
#include <core.h>

// Note that primitives are responsible for maintaining the "output" values in
// the compiler state. On init it should set output_start and output correctly,
// and on finish it should update whatever internal bookkeeping it's doing to
// keep track of the code.

// Called during compiler setup to initialize a fresh compiler run.
void primitive_compiler_init(state *s);
// Called when compilation is completely done (including finalizers and all).
void primitive_compiler_finish(state *s);

void primitive_emit_literal_pool(state *s, cell value);

// Actual primitive compilers.
void prim_call_nonprimitive(state *s, nonprimitive *np);

#endif
