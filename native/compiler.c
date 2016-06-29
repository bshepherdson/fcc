#include <stdlib.h>
#include <core.h>
#include <compiler.h>
#include <primitives.h>


state _global_compiler_state;
state *compiler_state = &_global_compiler_state;


void compile_init(void) {
  compiler_state->depth = 0;
  compiler_state->label_count = 0;

  compiler_state->literal_count = 0;

  compiler_state->finalizer_count = 0;

  // Call through to the machine-specific primitive initializer.
  primitive_compiler_init(compiler_state);
}

// TODO: How to identify the primitives? They're functions that I call, so I
// guess with their pointers?
void compile_primitive(primitive *p) {
  (*p)(compiler_state);
}

void compile_literal(cell value) {
  stacked *s = &(compiler_state->stack[compiler_state->depth++]);
  s->is_literal = 1;
  s->value = value;
}

void compile_nonprimitive(nonprimitive *np) {
  // Actually compiles a primitive for a call to this nonprimitive, essentially
  // an execute.
  prim_call_nonprimitive(compiler_state, np);
}

// Returns the completed nonprimitive object, which will be useful to the
// codebase later on.
nonprimitive* compile_finish(void) {
  // We're done, but still need to:
  // - Output the literal pool.
  // - Set the literal_pool_offset.
  // - Run any finalizers, in order.

  compiler_state->literal_pool_offset = compiler_state->output -
      compiler_state->output_start;

  // Output the necessary literals into the literal pool.
  for (int i = 0; i < compiler_state->literal_count; i++) {
    primitive_emit_literal_pool(compiler_state, compiler_state->literal_pool[i]);
  }

  // Now call any finalizers.
  for (int i = 0; i < compiler_state->finalizer_count; i++) {
    finalizer *f = &(compiler_state->finalizers[i]);
    f->code(compiler_state, f->target, f->data);
  }

  nonprimitive *np = malloc(sizeof *np);
  np->codeword = CODEWORD_DOCOL;
  np->code = (void (*)(void)) compiler_state->output_start;

  primitive_compiler_finish(compiler_state);
  return np;
}



void free_reg(state *s, cell reg) {
  s->free_registers[reg] = 1;
}

cell alloc_reg(state *s) {
  for (cell i = 0; i < MAX_REGS; i++) {
    if (s->free_registers[i]) {
      s->free_registers[i] = 0;
      return i;
    }
  }
  return -1;
}

