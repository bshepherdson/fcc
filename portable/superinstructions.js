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

superinstruction(['swap', 'to_r', 'to_r'], {
  sp:  [['is1', 'is2'], []],
  rsp: [[], ['id1', 'id2']],
}, [
  `id1 = is1;`,
  `id2 = is2;`,
]);

superinstruction(['dolit', 'compile_comma'], {ip: [['C1'], []]}, [
  `compile_(C1);`,
]);

// This is the phrase that implements LOOP.
superinstruction(['dolit', 'loop_end', 'zbranch'], {
  // IP is a reversed stack! So these look like they're swapped.
  ip: [['iBranchDelta', 'iDelta'], []],
}, [
  `cell iExit;`,
  // Happens to use the same name for iDelta.
  ...primitives.find(p => p.header.ident === 'loop_end').rawCode,
  helpers.zbrancher('iExit', 'iBranchDelta'),
]);

superinstruction(['swap', 'store'], {sp: [['a1', 'i1'], []]}, [
  `*a1 = i1;`,
]);

superinstruction(['dolit', 'equals', 'zbranch'], {
  // IP is a reversed stack! So these look like they're swapped.
  ip: [['iBranchDelta', 'iLit'], []],
  sp: [['i1'], []],
}, [
  `cell cond = iLit == i1;`,
  helpers.zbrancher('cond', 'iBranchDelta'),
]);

superinstruction(['dolit', 'less_than', 'zbranch'], {
  // IP is a reversed stack! So these look like they're swapped.
  ip: [['iBranchDelta', 'iLit'], []],
  sp: [['i1'], []],
}, [
  `cell cond = i1 < iLit;`,
  helpers.zbrancher('cond', 'iBranchDelta'),
]);

superinstruction(['state', 'fetch', 'zbranch'], {ip: [['iBranchDelta'], []]}, [
  helpers.zbrancher('state', 'iBranchDelta'),
]);

superinstruction(['dolit', 'store', 'exit'], {
  sp: [['iValue'], []],
  rsp: [['CExit'], []],
  ip: [['aLit'], []],
}, [
  `*aLit = iValue;`,
  `SET_ip(CExit);`,
]);

superinstruction(['dolit', 'fetch'], {
  ip: [['aLit'], []],
  sp: [[], ['iValue']],
}, [
  `iValue = *aLit;`,
]);

superinstruction(['dolit', 'store'], {
  ip: [['aLit'], []],
  sp: [['iValue'], []],
}, [
  `*aLit = iValue;`,
]);

superinstruction(['dolit', 'cells', 'plus'], {
  ip: [['iLit'], []],
  sp: [['iBase'], ['iResult']],
}, [
  `iResult = iBase + (iLit * sizeof(cell));`,
]);

superinstruction(['dolit', 'cells'], {
  ip: [['iLit'], []],
  sp: [[], ['iResult']],
}, [
  `iResult = iLit * sizeof(cell);`,
]);

superinstruction(['cells', 'plus'], {
  sp: [['iBase', 'iCells'], ['iResult']],
}, [
  `iResult = iBase + (iCells * sizeof(cell));`,
]);


module.exports = superinstructions;

