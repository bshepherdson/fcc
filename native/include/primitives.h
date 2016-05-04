#ifndef PRIMITIVES_H
#define PRIMITIVES_H

#include <compiler.h>
#include <core.h>

// Called during compiler setup to initialize a fresh compiler run.
void primitive_compiler_init(state *s);

ucell primitive_emit_literal_pool(state *s, cell value, ucell offset, void *target);

// Actual primitive compilers.
void prim_call_nonprimitive(state *s, nonprimitive *np);

#endif
