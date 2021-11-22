const stacks = {
  sp: {
    lv(i) {
      return i === 0 ? `spTOS` : `sp[${i}]`;
    },
    type: 'cell',
  },
  rsp: {
    lv(i) {
      return `rsp[${i}]`;
    },
    type: 'cell',
  },
  ip: {
    lv(i) {
      return `ip[${i}]`;
    },
    type: 'code*',
  },
};

const stackPrefixes = {
  'i': {type: 'cell'},
  'u': {type: 'ucell'},
  'a': {type: 'cell*'},
  'c': {type: 'unsigned char'},
  's': {type: 'char*'},
  'F': {type: 'FILE*'},
  // Code field address, eg. for EXECUTE.
  'C': {type: 'code**'},
};

// effects is a map of stack effects by stack:
// {
//   'sp': [inputs, outputs],
//   'rsp': [inputs, outputs],
//   'ip': [inputs, outputs],
// }

function builder(ident, name, effects, code, opt_immediate, opt_skipNext) {
  const immediate = opt_immediate || false;
  const next = !opt_skipNext;
  const inputCode = [];
  const outputCode = [];
  for (const stack of ['sp', 'rsp', 'ip']) {
    if (!effects[stack]) continue;

    const [inputs, outputs] = effects[stack];

    if (outputs.length > 0 && stack === 'ip') {
      throw new Error('IP cannot have outputs');
    }

    let depth = inputs.length - 1;
    for (const input of inputs) {
      const prefix = stackPrefixes[input[0]];
      const converter = `conv_${stack}_to_${input[0]}`;
      const rhs = stacks[stack].lv(depth);
      inputCode.push(`  ${prefix.type} ${input} = ${converter}(${rhs});`);
      depth--;
    }

    depth = outputs.length - 1;
    for (const output of outputs) {
      const prefix = stackPrefixes[output[0]];
      // Push a local with no initial value into the input side.
      inputCode.push(`  ${prefix.type} ${output};`);

      const converter = `conv_${stack}_from_${output[0]}`;
      const lhs = stacks[stack].lv(depth);
      outputCode.push(`  ${lhs} = ${converter}(${output});`);
      depth--;
    }

    // If there's at least one of both inputs and outputs, there's no need to
    // save/load TOS (since the primitive will update it).
    // If there are only outputs, we need to store the old one first.
    if (stack === 'sp' && inputs.length === 0) {
      inputCode.push(`  STORE_SP_TOS;`);
    }

    // Either way we need to adjust SP.
    if (inputs.length !== outputs.length) {
      // Stacks are generally full-descending, so if there's say 2 more inputs
      // than outputs, we want to increment by 2. If there's an extra output,
      // decrement by 1.
      inputCode.push(`  INC_${stack}(${inputs.length - outputs.length});`);
    }

    // If there's only inputs, we need to load the new spTOS.
    if (stack === 'sp' && outputs.length === 0) {
      inputCode.push(`  FETCH_SP_TOS;`);
    }
  }

  return {
    implementation: [
      //`void code_${ident}(void) {`,
      `{`,
      `LABEL(${ident});`,
      `  NAME("${name}")`,
    ].concat(inputCode)
      .concat(code.map(x => '  ' + x))
      .concat(outputCode)
      .concat([
        (next ? `  NEXT;` : ''),
        '}',
      ]),

    rawCode: code,

    header: {
      ident,
      name,
      immediate,
    },
  };
}

exports.builder = builder;

// delta is an offset from where the offset is stored, but IP has already
// been incremented by fetching the itself. So we need to increment by 0
// or by delta - sizeof(cell).
function zbrancher(flag, delta) {
  return `INC_ip_bytes(${flag} == 0 ? ${delta} - sizeof(cell) : 0);`;
}

exports.zbrancher = zbrancher;

