
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
      if (i !== 0) throw new Error('Only ipTOS is really accessible easily');
      return `ip[0]`;
    },
    type: 'cell',
  },
};

const stackPrefixes = {
  'i': {type: 'cell'},
  'u': {type: 'ucell'},
  'a': {type: 'cell*'},
  'c': {type: 'unsigned char'},
  's': {type: 'char*'},
};

// effects is a map of stack effects by stack:
// {
//   'sp': [inputs, outputs],
//   'rsp': [inputs, outputs],
//   'ip': [inputs, outputs],
// }

const primitives = [];
let nextKey = 1;

function primitive(ident, name, effects, code, opt_immediate, opt_skipNext) {
  const immediate = opt_immediate || false;
  const next = !opt_skipNext;
  const inputCode = [];
  const outputCode = [];
  for (const stack of ['sp', 'rsp', 'ip']) {
    if (!effects[stack]) continue;

    const [inputs, outputs] = effects[stack];
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

    if (inputs.length !== outputs.length) {
      // Stacks are generally full-descending, so if there's say 2 more inputs
      // than outputs, we want to increment by 2. If there's an extra output,
      // decrement by 1.
      inputCode.push(`  INC_${stack}(${inputs.length - outputs.length});`);
    }
  }

  const prim = {
    implementation: [
      `void code_${ident}(void) {`,
      `  NAME("${name}")`,
      `LABEL("${ident}");`,
    ].concat(inputCode)
      .concat(code.map(x => '  ' + x))
      .concat(outputCode)
      .concat([
        (next ? `  NEXT;` : ''),
        '}',
      ]),

    header: {
      ident,
      name,
      key: nextKey++,
      immediate,
    },
  };
  primitives.push(prim);
  return prim;
}

// Some standard stack effects, widely used.
const ii_i = {sp: [['i1', 'i2'], ['i3']]};
const uu_u = {sp: [['u1', 'u2'], ['u3']]};

// Arithmetic
primitive('plus',  '+',   ii_i, [`i3 = i1 + i2;`]);
primitive('minus', '-',   ii_i, [`i3 = i1 - i2;`]);
primitive('times', '*',   ii_i, [`i3 = i1 * i2;`]);
primitive('div',   '/',   ii_i, [`i3 = i1 / i2;`]);
primitive('mod',   'MOD', ii_i, [`i3 = i1 % i2;`]);

primitive('udiv', 'U/', {sp: [['u1', 'u2'], ['u3']]}, [
  `u3 = u1 / u2;`,
]);
primitive('umod', 'UMOD', {sp: [['u1', 'u2'], ['u3']]}, [
  `u3 = u1 % u2;`,
]);

// Bitwise
primitive('and', 'AND', ii_i, [`i3 = i1 & i2;`]);
primitive('or',  'OR',  ii_i, [`i3 = i1 | i2;`]);
primitive('xor', 'XOR', ii_i, [`i3 = i1 ^ i2;`]);
primitive('lshift', 'LSHIFT', uu_u, [`u3 = u1 << u2;`]);
primitive('rshift', 'RSHIFT', uu_u, [`u3 = u1 >> u2;`]);

// Comparisons
primitive('less_than', '<', ii_i, [`i3 = i1 < i2 ? -1 : 0;`]);
primitive('equal',     '=', ii_i, [`i3 = i1 == i2 ? -1 : 0;`]);
primitive('less_than_unsigned', 'U<', {sp: [['u1', 'u2'], ['i3']]}, [
  `i3 = u1 < u2 ? -1 : 0;`,
]);

// Stack operations
primitive('dup', 'DUP', {sp: [['i1'], ['i2', 'i3']]}, [
  // Despite how dumb this looks, the optimizer gets the job done.
  `i3 = i2 = i1;`,
]);

primitive('drop', 'DROP', {}, [`INC_sp(1);`]);
primitive('swap', 'SWAP', {sp: [['ii1', 'ii2'], ['io1', 'io2']]}, [
  `io1 = ii2;`,
  `io2 = ii1;`,
]);

primitive('over', 'OVER', {sp: [['ii1', 'ii2'], ['io1', 'io2', 'io3']]}, [
  `io1 = ii1;`,
  `io2 = ii2;`,
  `io3 = ii1;`,
]);

primitive('rot', 'ROT', {sp: [['ii1', 'ii2', 'ii3'], ['io1', 'io2', 'io3']]}, [
  // ROT is "summon".
  `io1 = ii2;`,
  `io2 = ii3;`,
  `io3 = ii1;`,
]);

primitive('neg_rot', '-ROT',
    {sp: [['ii1', 'ii2', 'ii3'], ['io1', 'io2', 'io3']]}, [
  // -ROT is "bury".
  `io1 = ii3;`,
  `io2 = ii1;`,
  `io3 = ii2;`,
]);

primitive('two_drop', '2DROP', {}, [`INC_sp(2);`]);
primitive('two_dup',  '2DUP',  {
  sp: [['ii1', 'ii2'], ['io1', 'io2', 'io3', 'io4']],
}, [
  `io1 = io3 = ii1;`,
  `io2 = io4 = ii2;`,
]);

primitive('two_swap', '2SWAP', {
  sp: [['ii1', 'ii2', 'ii3', 'ii4'], ['io1', 'io2', 'io3', 'io4']],
}, [
  `io1 = ii3;`,
  `io2 = ii4;`,
  `io3 = ii1;`,
  `io4 = ii2;`,
]);

primitive('two_over', '2OVER', {
  sp: [
    ['ii1', 'ii2', 'ii3', 'ii4'],
    ['io1', 'io2', 'io3', 'io4', 'io5', 'io6'],
  ],
}, [
  `io1 = ii1;`,
  `io2 = ii2;`,
  `io3 = ii3;`,
  `io4 = ii4;`,
  `io5 = ii1;`,
  `io6 = ii2;`,
]);

// Return stack
primitive('to_r', '>R', {sp: [['i1'], []], rsp: [[], ['i2']]}, [
  `i2 = i1;`,
]);
primitive('from_r', 'R>', {sp: [[], ['i1']], rsp: [['i2'], []]}, [
  `i1 = i2;`,
]);


// Variables
primitive('base',  'BASE',  {sp: [[], ['a1']]}, [`a1 = &base;`]);
primitive('state', 'STATE', {sp: [[], ['a1']]}, [`a1 = &state;`]);


// Memory access
primitive('fetch',  '@',  {sp: [['a1'], ['i1']]}, [`i1 = *a1;`]);
primitive('store',  '!',  {sp: [['i1', 'a1'], []]}, [`*a1 = i1;`]);
primitive('cfetch', 'C@', {sp: [['a1'], ['c1']]}, [
  `c1 = *((unsigned char*) a1);`,
]);
primitive('cstore', 'C!', {sp: [['c1', 'a1'], []]}, [
  `*((unsigned char*) a1) = c1;`,
]);

// HERE and memory values
primitive('raw_alloc', '(ALLOCATE)', {sp: [['i1'], ['a1']]}, [
  `a1 = (cell*) malloc(i1);`,
]);
primitive('here_ptr', '(>HERE)', {sp: [[], ['a1']]}, [
  `a1 = dsp.cells;`,
]);


// Control flow - note that the offsets are in *bytes*.
primitive('branch', '(BRANCH)', {ip: [['i1'], []]}, [
  `INC_ip_bytes(i1);`
]);
primitive('zbranch', '(0BRANCH)', {
  sp: [['iCond'], []],
  ip: [['iDelta'], []],
}, [
  `INC_ip_bytes(iCond == 0 ? iDelta : ((cell) sizeof(cell)));`,
]);

primitive('execute', 'EXECUTE', {sp: [['a1'], []]}, [
  `cfa = (cell**) a1;`,
  `ca = *cfa;`,
  `NEXT1;`,
], /* immediate */ false, /* skipNext */ true);


// I/O routines
primitive('evaluate', 'EVALUATE', {
  sp: [['s1', 'u1'], []],
  rsp: [[], ['i2']],
}, [
  `inputIndex++;`,
  `SRC.parseLength = u1;`,
  `SRC.parseBuffer = s1;`,
  `SRC.type = -1;`, // EVALUATE
  `SRC.inputPtr = 0;`,

  // Set up the return stack to aim at whatever we were doing when EVALUATE was
  // called, and then jump back into interpreting.
  // TODO: This might be slowly leaking RSP frames?
  // That might be solved by moving this hack to be a special case where quit_
  // calls refill_. That's actually how my ARM assembler Forth system works.
  `i2 = ipTOS;`,
  `goto *quit_inner;`,
], /* immediate */ false, /* skipNext */ true);

primitive('refill', 'REFILL', {sp: [[], ['i1']]}, [
  `i1 = SRC.type == -1 ? 0 : refill_();`,
]);

primitive('accept', 'ACCEPT', {sp: [['s1', 'i1'], ['i2']]}, [
  `char* temp = readline(NULL);`, // No prompt for accept.
  `i2 = strlen(temp);`,
  `if (i2 > i1) i2 = i1;`,
  `strncpy(s1, temp, i2);`,
  `free(temp);`,
]);

primitive('key', 'KEY', {sp: [[], ['c1']]}, [
  `struct termios old_tio, new_tio;`,
  // Grab the current terminal settings.
  `tcgetattr(STDIN_FILENO, &old_tio);`,
  // Copy to preserve the original.
  `new_tio = old_tio;`,
  // Disable the canonical mode (buffered I/O) flag and local echo.
  `new_tio.c_lflag &= (~ICANON & ~ECHO);`,
  // And write it back.
  `tcsetattr(STDIN_FILENO, TCSANOW, &new_tio);`,

  // Read a single character.
  `c1 = getchar();`,

  // And put things back like we found them.
  `tcsetattr(STDIN_FILENO, TCSANOW, &old_tio);`,
]);

primitive('latest', '(LATEST)', {sp: [[], ['a1']]}, [
  `a1 = (cell*) *compilationWordlist;`,
]);

primitive('in_ptr', '>IN', {sp: [[], ['i1']]}, [
  `i1 = (cell) (&SRC.inputPtr);`,
]);

primitive('emit', 'EMIT', {sp: [['c1'], []]}, [
  `fputc(c1, stdout);`,
]);

primitive('source', 'SOURCE', {sp: [[], ['s1', 'u1']]}, [
  `s1 = SRC.parseBuffer;`,
  `u1 = SRC.parseLength;`,
]);

primitive('source_id', 'SOURCE-ID', {sp: [[], ['i1']]}, [
  `i1 = SRC.type;`,
]);


// Sizes and metadata
primitive('size_cell', '(/CELL)', {sp: [[], ['i1']]}, [
  `i1 = (cell) sizeof(cell);`,
]);
primitive('size_char', '(/CHAR)', {sp: [[], ['i1']]}, [
  `i1 = (cell) sizeof(char);`,
]);
primitive('cells', 'CELLS', {sp: [['i1'], ['i2']]}, [
  `i2 = i1 * sizeof(cell);`,
]);
primitive('chars', 'CHARS', {sp: [['i1'], ['i2']]}, [
  `i2 = i1 * sizeof(char);`,
]);
primitive('unit_bits', '(ADDRESS-UNIT-BITS)', {sp: [[], ['i1']]}, [
  `i1 = (cell) (CHAR_BIT);`,
]);
primitive('stack_cells', '(STACK-CELLS)', {sp: [[], ['i1']]}, [
  `i1 = (cell) DATA_STACK_SIZE;`,
]);
primitive('return_stack_cells', '(RETURN-STACK-CELLS)', {sp: [[], ['i1']]}, [
  `i1 = (cell) RETURN_STACK_SIZE;`,
]);

// Converts a header* eg. from (latest) into the DOES> address, which is the
// cell after the CFA.
primitive('to_does', '(>DOES)', {sp: [['i1'], ['i2']]}, [
  `header* h = (header*) i1;`,
  `i2 = ((cell) &(h->code_field)) + sizeof(cell);`,
]);

// Converts a header* eg. from (latest) into the code field address.
primitive('to_cfa', '(>CFA)', {sp: [['i1'], ['i2']]}, [
  `header* h = (header*) i1;`,
  `i2 = (cell) &(h->code_field);`,
]);

// Advances a CFA to be the data-space pointer, which is for a CREATEd
// definition two cells after the xt.
primitive('to_body', '>BODY', {sp: [['i1'], ['i2']]}, [
  `i2 = i1 + ((cell) (2 * sizeof(cell)));`,
]);

// Pushes the last word that was defined, whether with : or :NONAME.
primitive('last_word', '(LAST-WORD)', {sp: [[], ['i1']]}, [
  `i1 = (cell) lastWord;`,
]);


// Compilation helpers
primitive('docol', '(DOCOL)', {rsp: [[], ['a1']]}, [
  // TODO How does this even work? CFA isn't set most of the time by NEXT, only
  // by the heavy calls like EXECUTE and QUIT.
  `a1 = ip;`,
  `SET_ip((cell*) &(cfa[1]));`,
]);

primitive('dolit', '(DOLIT)', {
  ip: [['i1'], []],
  sp: [[], ['i2']],
}, [
  `i2 = i1;`,
]);

primitive('dostring', '(DOSTRING)', {
  ip: [['s1'], []],
  sp: [[], ['s2', 'i1']],
}, [
  `s2 = s1 + 1;`,
  `i1 = (cell) *s2;`,

  // The stack is ready but we need to skip the IP over it.
  `char *s = s2 + i1 + (sizeof(cell) - 1);`,
  `s = (char*) (((cell) s) & ~(sizeof(cell) - 1));`,
  `SET_ip((cell*) s);`,
]);


// CREATE compiles 0 and then the user's code into the data space.
// It usues (dodoes) as the doer word, not docol! That will push the address of
// the user's data space area, as intended (cfa + 2 cells) and then crack that
// 0 at cfa + 1 cell. If it's 0, do nothing. Otherwise, jump to that point.
primitive('dodoes', '(DODOES)', {
  sp:  [[], ['i1']], // The data space value.
  // rsp might get a push, or might not.
}, [
  `char *code = (char*) cfa;`,
  `i1 = (cell) (code + 2 * sizeof(cell));`,
  `cell* does = *((cell**) (code + sizeof(cell)));`,

  // Similar to docol, push onto the return stack and jump.
  `if (does != 0) {`,
  `  INC_rsp(-1);`,
  `  rspTOS = (cell) ip;`,
  `  SET_ip(does);`,
  `}`,
]);


// Parsing and input
primitive('parse', 'PARSE', {sp: [['c1'], ['s1', 'i1']]}, [
  `parse_(c1, &s1, &i1);`,
]);

primitive('parse_name', 'PARSE-NAME', {sp: [[], ['s1', 'i1']]}, [
  `parse_name_(&s1, &i1);`,
]);

// Stack effect is ( lo hi c-addr u -- lo' hi' c-addr' u' ) but to_number_
// works with them in place.
primitive('to_number', '>NUMBER', {}, [`to_number_();`]);

// Parses a name, and constructs a header for it.
// When finished, HERE is the data space properly set up for compilation.
primitive('create', 'CREATE', {}, [
  `char *s;`,
  `cell len;`,
  `parse_name_(&s, &len);`,
  `dsp.chars = (char*) ((((cell) dsp.chars) + sizeof(cell) - 1) & ~(sizeof(cell) - 1));`,
  `header *h = (header*) dsp.chars;`,
  `dsp.chars += sizeof(header);`,
  `h->link = *compilationWordlist;`,
  `*compilationWordlist = h;`,
  `h->metadata = len;`,
  `h->name = (char*) malloc(len * sizeof(char));`,
  `strncpy(h->name, s, len);`,
  `h->code_field = &code_dodoes;`,
  `*(dsp.cells++) = 0;`,
]);

primitive('find', '(FIND)', {sp: [['sName', 'iLen'], ['aXT', 'iFlag']]}, [
  `find_(&sName, &iLen);`,
  `aXT = (cell*) sName;`,
  `iFlag = iLen;`,
]);


// Tricky stack junk
// Doesn't use the stack functionality; it makes it hard to reckon the depth.
primitive('depth', 'DEPTH', {}, [
  `cell c = (cell) (((char*) spTop) - ((char*) sp)) / sizeof(cell);`,
  `INC_sp(-1);`,
  `spTOS = c;`,
]);

primitive('quit', 'QUIT', {}, [
  `inputIndex = 0;`,
  `quit_();`,
]);

primitive('bye', 'BYE', {}, [`exit(0);`]);

primitive('compile_comma', 'COMPILE,', {sp: [['i1'], []]}, [
  `compile_((void*) i1);`,
]);

primitive('literal', 'LITERAL', {sp: [['i1'], []]}, [
  `compile_lit_(i1);`,
], /* immediate */ true);

primitive('compile_literal', '[LITERAL]', {sp: [['i1'], []]}, [
  `compile_lit_(i1);`,
]);

module.exports = primitives;

