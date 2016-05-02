
#include <core.h>
#include <compiler.h>
#include <primitives.h>


state _global_compiler_state;
state *compiler_state = &_global_compiler_state;

void compile_init(void) {
  compiler_state->depth = 0;
  compiler_state->label_count = 0;
  compiler_state->op = &(compiler_state->output[0]);

  compiler_state->literal_count = 0;

  // Call through to the machine-specific primitive initializer.
  primitive_compiler_init();
}

// TODO: How to identify the primitives? They're functions that I call, so I
// guess with their pointers?
void compile_primitive(primitive *p) {
  (*p)();
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

// Takes in the target location, and returns the total size in bytes of the
// compiled code.
ucell compile_emit(void *target) {
  operation *op = &(compiler_state->output[0]);
  ucell offset = 0;
  // First pass: resolve labels.
  while (op != compiler_state->op) {
    offset += op->resolve(compiler_state, op->data, offset, target + offset);
    op++;
  }

  // Now that we know where the end of the function is, we know where to put the
  // literal pool, if any.
  compiler_state->literal_pool_offset = offset;

  // Second pass: emit code.
  op = &(compiler_state->output[0]);
  offset = 0;
  while (op != compiler_state->op) {
    offset += op->emit(compiler_state, op->data, offset, target + offset);
    op++;
  }

  // Emit the literal pool as well.
  for (int i = 0; i < compiler_state->literal_count; i++) {
    offset += primitive_emit_literal_pool(compiler_state, compiler_state->literal_pool[i], offset, target + offset);
  }

  return offset;
}


void free_reg(cell reg) {
  compiler_state->free_registers[reg] = 1;
}

cell alloc_reg() {
  for (cell i = 0; i < MAX_REGS; i++) {
    if (compiler_state->free_registers[i]) {
      compiler_state->free_registers[i] = 0;
      return i;
    }
  }
  return -1;
}

