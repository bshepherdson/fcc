// NodeJS-powered C code generation.
//
// This script writes a handful of .in files which get #included by engine.c
// - primitives.in is the code for implementing the primitives
// - primitive_init.in holds the initial setup of primitives, defining their
//   dictionary entries and so on.

const primitives = require('./primitives.js');
const fs = require('fs');

fs.writeFileSync('primitives.in', [
  primitives.map(x => `void prim_${x.header.ident}(void);`).join('\n'),
  primitives.map(x => x.implementation.join('\n')).join('\n\n'),
].join('\n\n'), 'utf-8');


