#ifndef COMPILER_H
#define COMPILER_H

// A stacked value.
typedef struct {
  bool isLiteral;
  cell value; // Either a register number, or a literal value.
} stacked;

struct state_;

typedef struct operation_ {
  ucell (*resolve)(struct state_ *s, void* data, ucell offset);
  void (*emit)(struct state_ *s, void* data);
  void* data;
};


// Labels go through three phases:
// 0. When initially created, they are set to -1, to mean unresolved.
// 1. When resolved, they are set to the offset relative to the start of the
//    function.
// 2. When consumed, they are read and incorporated into the output, in whatever
//    form makes sense for the architecture.
typedef ucell label;

typedef struct state_ {
  stacked stack[32];
  int depth;

  label labels[64];
  int label_count;

  operation *output[1024];
  operation *op;
} state;
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
void compile_emit(void);


// START HERE: How to handle creating labels while executing code at runtime?
// Ah, actually: remember that, while IF, THEN and friends are IMMEDIATE, the
// [branch-fwd] and so on are primitives that will be compiled normally into
// those functions.
//
// They run during the definition of some other primitive. I need to rethink
// this, because I was thinking of it as too simple.

/*

: IF [0branch-fwd] ( -- label ) ; IMMEDIATE
: ELSE ( -- end-label ) [branch-fwd] swap (resolve-label) ; IMMEDIATE
: THEN ( if-label ) (resolve-label) ; IMMEDIATE

[0branch-fwd] and (resolve-label) are going to get compiled right into IF et al.
Then when IF et al are used in compiling someone else's definition.

That means that when ... hmm.

*/

#endif
