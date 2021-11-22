const helpers = require('./helpers');
const primitives = [];
let nextKey = 1;

function primitive(ident, name, effects, code, opt_immediate, opt_skipNext) {
  const prim = helpers.builder(ident, name, effects, code,
      opt_immediate, opt_skipNext);
  prim.header.key = nextKey++;
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

primitive('drop', 'DROP', {sp: [['i1'], []]}, [`(void)(i1);`]);
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

primitive('two_drop', '2DROP', {sp: [['i1', 'i2'], []]}, [
  `(void)(i1);`,
  `(void)(i2);`,
]);
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

// i2 is at a1, i1 the next cell.
primitive('two_fetch', '2@', {sp: [['a1'], ['i1', 'i2']]}, [
  `i2 = a1[0];`,
  `i1 = a1[1];`,
]);
primitive('two_store', '2!', {sp: [['i1', 'i2', 'a1'], []]}, [
  `a1[0] = i2;`,
  `a1[1] = i1;`,
]);

// HERE and memory values
primitive('raw_alloc', '(ALLOCATE)', {sp: [['i1'], ['a1']]}, [
  `a1 = (cell*) malloc(i1);`,
]);
primitive('here_ptr', '(>HERE)', {sp: [[], ['a1']]}, [
  `a1 = (cell*) &(dsp.cells);`,
]);


// Control flow - note that the offsets are in *bytes*.
primitive('branch', '(BRANCH)', {ip: [['iDelta'], []]}, [
  // IP points *after* iDelta, since fetching iDelta has itself moved IP.
  `INC_ip_bytes(iDelta - sizeof(cell));`,
]);
primitive('zbranch', '(0BRANCH)', {
  sp: [['iCond'], []],
  ip: [['iDelta'], []],
}, [
  helpers.zbrancher('iCond', 'iDelta'),
]);

primitive('loop_end', '(LOOP-END)', {
  sp: [['iDelta'], ['iExit']],
  // Limit is the next value up on the stack, rsp[1].
  rsp: [['iIndex1'], ['iIndex2']],
}, [
  `cell limit = rspREF(1);`,
  `cell il = iIndex1 - limit;`,
  `cell idl = iDelta + il;`,
  `iIndex2 = iIndex1 + iDelta;`,
  `bool sameSigns = (idl ^ il) >= 0;`,
  `bool wantSameSigns = (iDelta ^ il) >= 0;`,
  `iExit = (sameSigns || wantSameSigns) ? false : true;`,
]);

primitive('execute', 'EXECUTE', {sp: [['C1'], []]}, [
  `cfa = C1;`,
  `ca = *cfa;`,
  `NEXT1;`,
], /* immediate */ false, /* skipNext */ true);


// I/O routines
primitive('evaluate', 'EVALUATE', {
  sp: [['s1', 'u1'], []],
}, [
  `inputIndex++;`,
  `SRC.parseLength = u1;`,
  `SRC.parseBuffer = s1;`,
  `SRC.type = -1;`, // EVALUATE
  `SRC.inputPtr = 0;`,

  // Set up the return stack to aim at whatever we were doing when EVALUATE was
  // called, and then jump back into interpreting.
  `code **oldIP = ip;`,
  `interpret_();`, // This doesn't return until the nested code is done.
  `ip = oldIP;`,
  // Then we're back to our normal state and can NEXT.
]);

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
  `a1 = (cell*) compilationWordlist;`,
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
  `i2 = i1 + sizeof(header);`,
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
primitive('docol', '(DOCOL)', {rsp: [[], ['C1']]}, [
  // NB This is only actually executed by QUIT or EXECUTE.
  // When the compiler sees a call of a nonprimitive, it compiles it as a
  // call_ primitive with the target address in the next cell.
  //
  // This is "primitive-centric" direct threaded code, and it avoids a double
  // indirection in compiled code.
  //
  // Nonprimitives are laid out in memory thus:
  // prev header link     <-- header*
  // metadata/length
  // name string
  // code_field           <-- cfa
  // body thread
  // ...
  // tag_exit
  //
  // So we want to set IP to cfa + 1 cell, since that's where the thread begins.
  // We push the old IP onto the return stack.
  `#if VERBOSE`,
  `fprintf(stderr, "  %.*s\\n", (int) ((cell) cfa[-2]) & LEN_MASK, (char*) cfa[-1]);`,
  `#endif`,
  `C1 = ip;`,
  `SET_ip(((void*)cfa) + sizeof(cell));`,
]);

primitive('dolit', '(DOLIT)', {
  ip: [['i1'], []],
  sp: [[], ['i2']],
}, [
  `i2 = i1;`,
]);

primitive('dostring', '(DOSTRING)', {
  sp: [[], ['s2', 'i1']],
}, [
  `char *s = (char*) ip;`,
  `i1 = (cell) *s;`,
  `s2 = s + 1;`,

  // The stack is ready. Skip the IP forward over the string, and align it.
  `s = s2 + i1 + (sizeof(cell) - 1);`,
  `s = (char*) (((cell) s) & ~(sizeof(cell) - 1));`,
  `SET_ip((code**) s);`,
]);


// CREATE compiles 0 and then the user's code into the data space.
// It usues (dodoes) as the doer word, not docol! That will push the address of
// the user's data space area, as intended (cfa + 2 cells) and then crack that
// 0 at cfa + 1 cell. If it's 0, do nothing. Otherwise, jump to that point.
primitive('dodoes', '(DODOES)', {
  sp:  [[], ['C1']], // The data space value.
  // rsp might get a push, or might not.
}, [
  `code **target = cfa;`,
  `C1 = &target[2];`,
  `code* does = target[1];`,

  // Similar to docol, push onto the return stack and jump.
  `if (does != 0) {`,
  `  INC_rsp(-1);`,
  `  rspTOS = (cell) ip;`,
  `  SET_ip((code**) does);`,
  `}`,
]);


// Primitive for calling a (DOCOL) word.
// Expects the next cell in ip-space to be the address of the code.
// Otherwise it resembles a (DOCOL).
primitive('call_forth', '(call-forth)', {
  ip: [['iTarget'], []],
  rsp: [[], ['iRet']],
}, [
  `#if VERBOSE`,
  `header *h = (header*) (iTarget - 4 * sizeof(cell));`,
  `fprintf(stderr, "Call: %.*s\\n", (int) h->metadata & LEN_MASK, h->name);`,
  `#endif`,
  `ca = (code*) iTarget;`,
  `iRet = (cell) ip;`,
  `ip = (code**) ca;`,
]);



// Parsing and input
primitive('parse', 'PARSE', {sp: [['c1'], ['s1', 'i1']]}, [
  `parse_(c1, &s1, &i1);`,
]);

primitive('parse_name', 'PARSE-NAME', {sp: [[], ['s1', 'i1']]}, [
  `string s = parse_name_();`,
  `s1 = s.text;`,
  `i1 = s.length;`,
]);

// Stack effect is ( lo hi c-addr u -- lo' hi' c-addr' u' ) but to_number_
// works with them in place.
primitive('to_number', '>NUMBER', {}, [`to_number_();`]);

// Parses a name, and constructs a header for it.
// When finished, HERE is the data space properly set up for compilation.
primitive('create', 'CREATE', {}, [
  `string s = parse_name_();`,
  `ALIGN_DSP(cell);`,
  `header *h = (header*) dsp.chars;`,
  `dsp.chars += sizeof(header);`,
  `h->link = *compilationWordlist;`,
  `*compilationWordlist = h;`,
  `h->metadata = s.length;`,
  `h->name = (char*) malloc(s.length * sizeof(char));`,
  `strncpy(h->name, s.text, s.length);`,
  `h->code_field = ca_dodoes;`,
  `*(dsp.cells++) = 0;`,
]);

primitive('find', '(FIND)', {sp: [['sName', 'iLen'], ['CXT', 'iFlag']]}, [
  `header *h = find_(sName, iLen);`,
  `if (h == NULL) {`,
  `  CXT = (code**) 0;`,
  `  iFlag = 0;`,
  `} else {`,
  `  CXT = &h->code_field;`,
  `  iFlag = (h->metadata & IMMEDIATE) != 0 ? 1 : -1;`,
  `}`,
]);

primitive('dict_info', '(DICT-INFO)', {
  sp: [[], ['iComp', 'iSearchIndex', 'iSearchArray']],
}, [
  `iComp = (cell) compilationWordlist;`,
  `iSearchIndex = (cell) searchIndex;`,
  `iSearchArray = (cell) searchOrder;`,
]);

// Tricky stack junk
primitive('depth', 'DEPTH', {sp: [[], ['iDepth']]}, [
  `iDepth = (cell) ((((char*) spTop) - ((char*) sp)) / sizeof(cell)) - 1;`,
]);

primitive('sp_fetch',  'SP@', {sp: [[], ['iSP']]}, [`iSP = (cell) sp;`]);
primitive('sp_store',  'SP!', {sp: [['iSP'], []]}, [`sp = (cell*) iSP;`]);
primitive('rsp_fetch', 'RP@', {sp: [[], ['iRP']]}, [`iRP = (cell) rsp;`]);
primitive('rsp_store', 'RP!', {sp: [['iRP'], []]}, [`rsp = (cell*) iRP;`]);


primitive('quit', 'QUIT', {}, [
  `reset_interpreter_();`,
  `return;`, // Jump out of interpret, and it will resume from the keyboard.
]);

primitive('bye', 'BYE', {}, [
  `fprintf(stderr, "bye\\n");`,
  `#ifdef ACCOUNTING`,
  `fclose(account);`,
  `#endif`,
  `exit(0);`,
]);

primitive('compile_comma', 'COMPILE,', {sp: [['C1'], []]}, [
  `compile_(C1);`,
]);

primitive('literal', 'LITERAL', {sp: [['i1'], []]}, [
  `compile_lit_(i1);`,
], /* immediate */ true);

primitive('compile_literal', '[LITERAL]', {sp: [['i1'], []]}, [
  `compile_lit_(i1);`,
]);

// Compiles a 0branch and a 0 (placeholder delta) into the current definition.
// Pushes the address of the 0 onto the stack.
primitive('compile_zbranch', '[0BRANCH]', {sp: [[], ['a1']]}, [
  `compile_(&ca_zbranch);`,
  `while (queue_length > 0) drain_queue_();`,
  `a1 = dsp.cells;`,
  `*(dsp.cells++) = 0;`,
]);
primitive('compile_branch', '[BRANCH]', {sp: [[], ['a1']]}, [
  `compile_(&ca_branch);`,
  `while (queue_length > 0) drain_queue_();`,
  `a1 = dsp.cells;`,
  `*(dsp.cells++) = 0;`,
]);

// Called before Forth-defined control structures like IF and WHILE to make sure
// the superinstruction queue is drained. Superinstructions cannot span control
// flow points in this scheme (though they can end with one!)
primitive('control_flush', '(CONTROL-FLUSH)', {}, [
  `while (queue_length > 0) drain_queue_();`,
]);

// Does nothing; this only exists to be a breakpoint.
primitive('debug_break', '(DEBUG)', {}, []);
primitive('debug_print', '(PRINT)', {sp: [['i1'], []]}, [
  `printf("%" PRIdPTR " %" PRIxPTR "\\n", i1, i1);`,
]);
primitive('debug_star_print', '(*PRINT)', {sp: [['a1'], []]}, [
  `printf("%" PRIxPTR ": %" PRIdPTR " %" PRIxPTR "\\n", (ucell) a1, *a1, *a1);`,
]);
primitive('debug_words', '(WORDS)', {}, [
  `debug_words_();`,
]);


// C foreign calls
// These are the versions with return values. The no-return forms are written in
// Forth and just drop the nonce return values.
primitive('ccall_0', 'CCALL0', {sp: [['iFn'], ['iRet']]}, [
  `iRet = ((cell (*)(void)) iFn)();`,
]);
primitive('ccall_1', 'CCALL1', {sp: [['iFn', 'i1'], ['iRet']]}, [
  `iRet = ((cell (*)(cell)) iFn)(i1);`,
]);
primitive('ccall_2', 'CCALL2', {sp: [['iFn', 'i1', 'i2'], ['iRet']]}, [
  `iRet = ((cell (*)(cell, cell)) iFn)(i1, i2);`,
]);
primitive('ccall_3', 'CCALL3', {sp: [['iFn', 'i1', 'i2', 'i3'], ['iRet']]}, [
  `iRet = ((cell (*)(cell, cell, cell)) iFn)(i1, i2, i3);`,
]);
primitive('ccall_4', 'CCALL4', {
  sp: [['iFn', 'i1', 'i2', 'i3', 'i4'], ['iRet']],
}, [
  `iRet = ((cell (*)(cell, cell, cell, cell)) iFn)(i1, i2, i3, i4);`,
]);
primitive('ccall_5', 'CCALL5', {
  sp: [['iFn', 'i1', 'i2', 'i3', 'i4', 'i5'], ['iRet']],
}, [
  `iRet = ((cell (*)(cell, cell, cell, cell, cell)) iFn)(i1, i2, i3, i4, i5);`,
]);
primitive('ccall_6', 'CCALL6', {
  sp: [['iFn', 'i1', 'i2', 'i3', 'i4', 'i5', 'i6'], ['iRet']],
}, [
  `iRet = ((cell (*)(cell, cell, cell, cell, cell, cell)) iFn)(i1, i2, i3, i4, i5, i6);`,
]);

// Expects a NUL-terminated, C-style string on the stack, and dlopen()s it,
// globally, so a generic dlsym() for it will work.
// NULL = 0 indicates an error on return.
primitive('c_library', '(C-LIBRARY)', {sp: [['s1'], ['iResult']]}, [
  `iResult = (cell) dlopen(s1, RTLD_NOW | RTLD_GLOBAL);`,
]);

// Expects a NUL-terminated, C-style string on the stack, and dlsym()s it,
// in the default mode that searches everything.
primitive('c_symbol', '(C-SYMBOL)', {sp: [['s1'], ['iResult']]}, [
  `iResult = (cell) dlsym(RTLD_DEFAULT, s1);`,
]);


// File access
primitive('close_file', 'CLOSE-FILE', {sp: [['File'], ['iErr']]}, [
  `int err = fclose(File);`,
  `iErr = err ? errno : 0;`,
]);

primitive('create_file', 'CREATE-FILE', {
  sp: [['s1', 'uLen', 'iMode'], ['File', 'ior']],
}, [
  `strncpy(tempBuf, s1, uLen);`,
  `tempBuf[uLen] = 0;`,
  `File = fopen(tempBuf, file_modes[iMode | FA_TRUNC]);`,
  `ior = File == 0 ? errno : 0;`,
]);

// Don't truncate files that exists. Opening a file for R/O that doesn't exist
// is a failure, but opening a file that doesn't exist for W/O or R/W should
// create it.
// Therefore if we try a normal open and it fails, we should try again with
// TRUNC enabled, IFF the FA_WRITE bit is set in the user's mode.
primitive('open_file', 'OPEN-FILE', {
  sp: [['s1', 'uLen', 'iMode'], ['File', 'ior']],
}, [
  `strncpy(tempBuf, s1, uLen);`,
  `tempBuf[uLen] = 0;`,
  `File = fopen(tempBuf, file_modes[iMode]);`,
  `if (File == NULL && (iMode & FA_WRITE) != 0) {`,
  `  File = fopen(tempBuf, file_modes[iMode | FA_TRUNC]);`,
  `}`,
  `ior = File == 0 ? errno : 0;`,
]);

primitive('delete_file', 'DELETE-FILE', {sp: [['s1', 'u1'], ['ior']]}, [
  `strncpy(tempBuf, s1, u1);`,
  `tempBuf[u1] = 0;`,
  `ior = remove(tempBuf);`,
  `if (ior == -1) ior = errno;`,
]);

primitive('file_position', 'FILE-POSITION', {
  sp: [['File'], ['iLo', 'iHi', 'ior']],
}, [
  // TODO This isn't 32-bit safe. It's fine on x86_64; we can safely assume the
  // file is not 9.2 exabytes.
  `iHi = 0;`,
  `iLo = (cell) ftell(File);`,
  `ior = iLo == -1 ? errno : 0;`,
]);

primitive('file_size', 'FILE-SIZE', {
  sp: [['File'], ['iLo', 'iHi', 'ior']],
}, [
  `iHi = 0;`,
  `iLo = 0;`,
  `cell c = ftell(File);`, // Save the position.
  `if (c < 0) {`,
  `  ior = errno;`,
  `} else {`,
  `  iLo = fseek(File, 0L, SEEK_END);`,
  `  if (iLo < 0) {`,
  `    ior = errno;`,
  `    fseek(File, (long) c, SEEK_SET);`,
  `  } else {`,
  `    iLo = ftell(File);`,
  `    fseek(File, (long) c, SEEK_SET);`,
  `    ior = 0;`,
  `  }`,
  `}`,
]);

primitive('include_file', 'INCLUDE-FILE', {sp: [['File'], []]}, [
  `inputIndex++;`,
  `SRC.type = (cell) File;`,
  `SRC.inputPtr = 0;`,
  `SRC.parseLength = 0;`,
  `SRC.parseBuffer = parseBuffers[inputIndex];`,
]);

primitive('read_file', 'READ-FILE', {
  sp: [['s1', 'u1', 'File'], ['u2', 'ior']],
}, [
  `u2 = (cell) fread(s1, 1, u1, File);`,
  `if (u2 == 0) {`,
  `  if (feof(File)) {`,
  `    ior = u2 = 0;`,
  `  } else {`,
  `    ior = ferror(File);`,
  `    u2 = 0;`,
  `  }`,
  `} else {`,
  `  ior = 0;`,
  `}`,
]);

// Expects a buffer and size. Reads at most that many characters, plus the
// delimiter. Should return a size that EXCLUDES the terminator.
// Uses getline, and if the line turns out to be longer than our buffer, the
// file is repositioned accordingly.
primitive('read_line', 'READ-LINE', {
  sp: [['s1', 'u1', 'File'], ['i2', 'iFlag', 'ior']],
}, [
  `char *s = NULL;`,
  `size_t size = 0;`,
  `i2 = getline(&s, &size, File);`,
  `if (i2 == -1) {`,
  `  ior = errno;`,
  `  i2 = iFlag = 0;`,
  `} else if (i2 == 0) {`,
  `  ior = i2 = iFlag = 0;`,
  `} else {`,
  `  if (((ucell) i2 - 1) > u1) {`,
  `    fseek(File, i2 - u1, SEEK_CUR);`,
  `    i2 = u1 + 1;`,
  `  } else if (s[i2 - 1] != '\\n') {`, // Found EOF, not newline.
  `    i2++;`,
  `  }`,
  `  strncpy(s1, s, i2-1);`,
  `  ior = 0;`,
  `  iFlag = true;`,
  `  i2--;`,
  `}`,

  `if (s != NULL) free(s);`,
]);

primitive('reposition_file', 'REPOSITION-FILE', {
  sp: [['iLo', 'iHi', 'File'], ['ior']],
}, [
  `ior = fseek(File, iLo, SEEK_SET);`,
  `if (ior == -1) ior = errno;`,
  `else if (iHi != 0) ior = 99999;`,
]);

primitive('resize_file', 'RESIZE-FILE', {
  sp: [['iLo', 'iHi', 'File'], ['ior']],
}, [
  `ior = ftruncate(fileno(File), iLo);`,
  `if (ior == -1) ior = errno;`,
  `else if (iHi != 0) ior = 99999;`,
]);

primitive('write_file', 'WRITE-FILE', {
  sp: [['s1', 'u1', 'File'], ['ior']],
}, [
  `fwrite(s1, 1, u1, File);`,
  `ior = 0;`,
]);

primitive('write_line', 'WRITE-LINE', {
  sp: [['s1', 'u1', 'File'], ['ior']],
}, [
  `strncpy(tempBuf, s1, u1);`,
  `tempBuf[u1] = '\\n';`,
  `fwrite(tempBuf, 1, u1 + 1, File);`,
  `ior = 0;`,
]);

primitive('flush_file', 'FLUSH-FILE', {sp: [['File'], ['ior']]}, [
  `ior = (cell) fsync(fileno(File));`,
  `if (ior == -1) ior = errno;`,
]);



// Back to the core: creating words.
primitive('colon', ':', {}, [
  `ALIGN_DSP(cell);`,
  `header *h = (header*) dsp.chars;`,
  `dsp.chars += sizeof(header);`,
  `h->link = *compilationWordlist;`,
  `*compilationWordlist = h;`,
  `string s = parse_name_();`,
  `if (s.length == 0) {`,
  `  fprintf(stderr, "*** Colon definition with no name\\n");`,
  `  reset_interpreter_();`, // Clears stacks, pops to keyboard.
  `  return;`, // Returns from INTERPRET to QUIT.
  `}`,

  //`fprintf(stderr, "Compiling : %.*s\\n", (int) s.length, s.text);`,
  `h->name = (char*) malloc(s.length);`,
  `strncpy(h->name, s.text, s.length);`,
  `h->metadata = s.length | HIDDEN;`,
  `h->code_field = ca_docol;`,
  `lastWord = &h->code_field;`,
  `state = COMPILING;`,
]);

primitive('colon_no_name', ':NONAME', {sp: [[], ['a1']]}, [
  `ALIGN_DSP(cell);`,
  `lastWord = (code**) dsp.cells;`,
  `a1 = (cell*) dsp.cells;`,
  `*(dsp.cells++) = (cell) ca_docol;`,
  `state = COMPILING;`,
]);

primitive('exit', 'EXIT', {rsp: [['C1'], []]}, [
  `SET_ip(C1);`,
]);

primitive('semicolon', ';', {}, [
  `(*compilationWordlist)->metadata &= (~HIDDEN);`, // Clear the hidden bit.
  // Compile an EXIT
  `compile_(&ca_exit);`,
  // And drain the queue completely - this definition is over.
  `while (queue_length) drain_queue_();`,
  // And stop compiling.
  `state = INTERPRETING;`,
], /* immediate */ true);

// Misc
// Pushes microseconds since the epoch as a double-cell integer.
// On 64-bit machines, the low word is big enough; on 32-bit it's not.
primitive('utime', 'UTIME', {sp: [[], ['uLo', 'uHi']]}, [
  `struct timeval timeVal;`,
  `gettimeofday(&timeVal, NULL);`,
  `uint64_t i64 = ((uint64_t) timeVal.tv_sec) * 1000000 + ((uint64_t) timeVal.tv_usec);`,
  `if (sizeof(cell) > 4) {`,
  `  uLo = (ucell) i64;`,
  `  uHi = 0;`,
  `} else {`,
  `  uLo = (i64 >> 32);`,
  `  uHi = i64 & 0xffffffff;`,
  `}`,
]);


primitive('see', 'SEE', {}, [
  `see_();`,
]);

module.exports = primitives;

