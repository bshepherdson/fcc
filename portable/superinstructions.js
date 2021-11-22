const helpers = require('./helpers');
const primitives = require('./primitives');

function keyOf(ident) {
  for (let i = 0; i < primitives.length; i++) {
    if (primitives[i].header.ident === ident) {
      return primitives[i].header.key;
    }
  }
}

const superinstructions = [];

// Key chains go in 32-bit integers.
// Little endian, so the first element goes in the low/first byte.
function superinstruction(parts, effects, code) {
  const ident = parts.join('_');
  let key = 0;
  for (let i = 0; i < parts.length; i++) {
    key = key | (keyOf(parts[i]) << (8 * i));
  }

  const sup = helpers.builder(ident, ident, effects, code);
  sup.header.key = key;
  superinstructions.push(sup);
  return sup;
}

superinstruction(['from_r', 'from_r', 'two_drop', 'exit'], {
  rsp: [['C1', 'i1', 'i2'], []],
}, [
  `(void)(i1);`,
  `(void)(i2);`,
  `SET_ip(C1);`,
]);

superinstruction(['from_r', 'from_r', 'two_drop'], {
  rsp: [['i1', 'i2'], []],
}, [
  `(void)(i1);`,
  `(void)(i2);`,
]);

// Probable candidates:
// R> R> 2DROP EXIT
// R> R> 2DROP                    -- unless R> R> 2drop exit gets them all
// SWAP >R >R
// (dolit) compile,
// (dolit) (loop-end) (0branch)   -- maybe?
// swap !                         -- maybe?
// (dolit) = (0branch)
// state @ (0branch)
// (dolit) ! exit
// (dolit) @
// (dolit) !
// (dolit) < (0branch)
// (dolit) cells
// (dolit) cells +
// swap drop
// cells +

module.exports = superinstructions;

