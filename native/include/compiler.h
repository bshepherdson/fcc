#ifndef COMPILER_H
#define COMPILER_H

#include <core.h>

// A stacked value.
typedef struct {
  bool isLiteral;
  cell value; // Either a register number, or a literal value.
} stacked;

struct state_;

typedef struct operation_ {
  ucell (*resolve)(struct state_ *s, void* data, ucell offset, void* target);
  ucell (*emit)(struct state_ *s, void* data, ucell offset, void* target);
  void* data;
} operation;


// Labels go through three phases:
// 0. When initially created, they are set to -1, to mean unresolved.
// 1. When resolved, they are set to the offset relative to the start of the
//    function.
// 2. When consumed, they are read and incorporated into the output, in whatever
//    form makes sense for the architecture.
typedef ucell label;

#define MAX_LABELS (64)
#define MAX_STACK (32)
#define MAX_REGS (16)
#define MAX_LITERAL_POOL (32)

typedef struct state_ {
  stacked stack[MAX_STACK];
  int depth;

  label labels[MAX_LABELS];
  int label_count;

  bool free_registers[MAX_REGS];

  cell literal_pool[MAX_LITERAL_POOL];
  int literal_count;
  ucell literal_pool_offset;


  operation output[1024];
  operation *op;
} state;


typedef void *primitive(void);

typedef struct {
  void (*codeword)(void);
  void (*code)(void);
  cell data; // Optional; omitted for eg. docol, but present for eg. dodoes.
} nonprimitive;


// Interface for the compiler and its runtime.

// Returns a clean compiler state. Called when we enter compilation state at the
// start of a new Forth definition, like on : or :NONAME.
void compile_init(void);

// TODO: What are the arguments here? Some means of identifying which primitive,
// at least. Haven't figured out how that's going to work, yet.
void compile_primitive(primitive *p);

// TODO: Likewise, how do I determine the nonprimitive? Its xt or something,
// probably, but I'm not even sure what form those take right now.
void compile_nonprimitive(nonprimitive *np);

void compile_literal(cell value);

// Called to actually emit the compiled buffer to emit machine code.
ucell compile_emit(void *target);


// Labels and control flow are the tricky bit. The [0branch-fwd] et al
// primitives actually get compiled into IF and friends, but their real work is
// done when IF and friends run IMMEDIATEly, during the compilation of some
// other word.
//
// At runtime, they should access the compile_state global and modify its label
// set and so on. That'll mean some tricky assembly code, but it should be
// workable.

// Miscellaneous helper functions for the compiler state.

// Releases the given register.
void free_reg(state *s, cell reg);
cell alloc_reg(state *s);

#endif
