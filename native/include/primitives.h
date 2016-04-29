#ifndef PRIMITIVES_H
#define PRIMITIVES_H

#include <core.h>

// Defines the fundamental structures and API for primitive definitions.
// There are machine-specific implementations of these in `machine/`.

// Regardless of architecture, registers are always stored as numbers starting
// from 0. Converting those to the internal representation is a
// machine-dependent problem.

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






#endif
