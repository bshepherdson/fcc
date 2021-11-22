// NodeJS-powered C code generation.
//
// This script writes a handful of .in files which get #included by engine.c
// - primitives.in is the code for implementing the primitives
// - primitive_init.in holds the initial setup of primitives, defining their
//   dictionary entries and so on.

const primitives = require('./primitives.js');
const superinstructions = require('./superinstructions.js');
const fs = require('fs');

//function forwardDecls() {
//  return primitives.map(x => `void prim_${x.header.ident}(void);`).join('\n');
//}

function implementations() {
  return primitives.map(x => x.implementation.join('\n')).join('\n\n');
}

function superImplementations() {
  return superinstructions.map(x => x.implementation.join('\n')).join('\n\n');
}

function initPrimitives() {
  const ret = [];
  //ret.push(`void init_primitives(void) {`);

  for (let i = 0; i < primitives.length; i++) {
    const h = primitives[i].header;
    const link = lastHeader;
    lastHeader = `header_${h.ident}`;
    ret.push(`  code *ca_${h.ident}_ = &&prim_${h.ident};`);
    ret.push(`  header *header_${h.ident} = (header*) malloc(sizeof(header));`);
    ret.push(`  header_${h.ident}->link = ${link};`);
    ret.push(`  header_${h.ident}->metadata = ${h.name.length + (h.immediate ? 512 : 0)};`);
    ret.push(`  header_${h.ident}->name = "${h.name}";`);
    ret.push(`  header_${h.ident}->code_field = ca_${h.ident}_;`);
    ret.push(`  super_key_t key_${h.ident} = ${h.key};`);
    ret.push(`  primitives[${i}].implementation = &&prim_${h.ident};`);
    ret.push(`  primitives[${i}].key = key_${h.ident};`);
    ret.push(`  byKey[key_${h.ident}] = header_${h.ident};`);
    ret.push('');
  }

  ret.push(`  last_header = ${lastHeader};`);
  ret.push(`  primitive_count = ${primitives.length};`);
  return ret.join('\n');
}

function initSuperinstructions() {
  const ret = [];
  for (let i = 0; i < superinstructions.length; i++) {
    const sup = superinstructions[i];
    ret.push(`  superinstructions[${i}].key = ${sup.header.key};`);
    ret.push(`  superinstructions[${i}].implementation = &&prim_${sup.header.ident};`);
  }
  ret.push(`  superinstruction_count = ${superinstructions.length};`);
  return ret.join('\n');
}

let lastHeader = '0';
fs.writeFileSync('primitives.in', implementations(), 'utf-8');
fs.writeFileSync('superinstructions.in', superImplementations(), 'utf-8');
fs.writeFileSync('init.in',
    initPrimitives() + '\n\n' + initSuperinstructions(), 'utf-8');

