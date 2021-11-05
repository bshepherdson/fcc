// Usage: nodejs core.js $ARCH $OUTFILE
const [arch, outfile] = process.argv.slice(2);

global.md = require(`./md_${arch}.js`);
const primitives = require('./primitives.js');
const superinstructions = require('./superinstructions.js');

const output = [
  // The preamble
  md.preamble(),

  // All the primitives.
  Object.values(primitives).map(prim => md.nativeWord(prim)),

  // All the superinstructions.
  superinstructions.map(sup => md.superinstruction(sup)),

  // And init the superinstructions.
  md.initSuperinstructions(superinstructions),

  '', // gas wants a newline at EOF
];

// A function so it can be recursed into.
const combined = [];
function outputArray(arr) {
  for (const x of arr) {
    if (Array.isArray(x)) {
      outputArray(x);
    } else {
      combined.push(x);
    }
  }
}

outputArray(output);
require('fs').writeFileSync(outfile, combined.join('\n'), 'utf-8');

