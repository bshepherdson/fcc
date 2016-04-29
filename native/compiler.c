
#include <core.h>
#include <compiler.h>


state _global_compiler_state;
state *compiler_state = &_global_compiler_state

void compile_init(void) {
  compiler_state->depth = 0;
  compiler_state->label_count = 0;
  compiler_state->op = &(output[0]);
}

// TODO: How to identify the primitives? They're functions that I call, so I
// guess with their pointers?
void compile_primitive(primitive *p) {
  (*p)(compiler_state);
}

void compile_literal(cell value) {
  stacked *s = &(compiler_state->stack[compiler_state->depth++]);
  s->isLiteral = 1;
  s->value = value;
}

void compile_nonprimitive(nonprimitive *np) {
  // Actually compiles a primitive for a call to this nonprimitive, essentially
  // an execute.
  prim_call_nonprimitive(np);
}

void compile_emit(void) {
  operation *op = &(compiler_state->output[0]);
  ucell offset = 0;
  // First pass: resolve labels.
  while (op != compiler_state->op) {
    ucell width = op->resolve(compiler_state, op->data, offset);
    offset += width;
    op++;
  }

  // Second pass: emit code.
  op = &(compiler_state->output[0]);
  offset = 0;
  while (op != compiler_state->op) {
    op->emit(compiler_state, op->data, offset);
    op++;
  }
}

