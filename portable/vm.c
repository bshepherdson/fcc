#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <limits.h>
#include <unistd.h>
#include <errno.h>
#include <termios.h>
#include <sys/stat.h>
#include <sys/time.h>

#include <readline/readline.h>
//#include <readline/history.h>

#include <md.h>

// Meta-macro that takes another macro and runs it for each external library.
// To add a new external file, it should be sufficient to add it here.
// NB: THESE ARE IN REVERSE ORDER. The bottom-most is loaded first!
#define EXTERNAL_FILES(F) \
  F(file) \
  F(facility) \
  F(tools) \
  F(exception) \
  F(ext) \
  F(core)

// How external files are imported.
// The linker includes them as symbols like _binary_lib_exception_fs.
// The "extern char" references here are not pointers, they're the actual
// character at position 0. Therefore we take &_binary_lib_exception_fs and use
// that as the input pointer.
// In order to distinguish these pointers from the FILE* inputs used by
// command-line arguments or INCLUDE and friends, I add EXTERN_SYMBOL_FLAG to
// them, and use EXTERN_SYMBOL_MASK to strip it off.

#define EXTERNAL_SYMBOL_FLAG (1)
#define EXTERNAL_SYMBOL_MASK (~1)

#define EXTERNAL_START(name) _binary_lib_ ## name ## _fs_start
#define EXTERNAL_END(name) _binary_lib_ ## name ## _fs_end
#define FORTH_EXTERN(name) \
  extern char EXTERNAL_START(name);\
  extern char EXTERNAL_END(name);


#define EXTERNAL_INPUT_SOURCES(name) \
  inputIndex++;\
  ext = (external_source*) malloc(sizeof(external_source));\
  ext->current = &EXTERNAL_START(name);\
  ext->end = &EXTERNAL_END(name);\
  SRC.type = ((cell) ext) | EXTERNAL_SYMBOL_FLAG;\
  SRC.inputPtr = 0;\
  SRC.parseLength = 0;\
  SRC.parseBuffer = parseBuffers[inputIndex];

EXTERNAL_FILES(FORTH_EXTERN);

typedef struct {
  char *current;
  char *end;
} external_source;

// Sizes in address units.
#define COMPILING (1)
#define INTERPRETING (0)

typedef intptr_t cell;
typedef uintptr_t ucell;
typedef unsigned char bool;
#define true (-1)
#define false (0)
#define CHAR_SIZE 1
#define CELL_SIZE sizeof(cell)

typedef void code(void);

// Remember to update WORDS in the tools word set if the format of the
// dictionary or individual headers within it changes.
typedef struct header_ {
  struct header_ *link;
  cell metadata; // See below.
  char *name;
  code *code_field;
} header;


// Globals that drive the Forth engine: SP, RSP, IP, CFA.
// These should generally be pinned to registers.
// Stacks are full-descending, and can therefore be used like arrays.

#define DATA_STACK_SIZE 16384
cell _stack_data[DATA_STACK_SIZE];
cell *spTop = &(_stack_data[DATA_STACK_SIZE]);
cell *sp;

#define RETURN_STACK_SIZE 1024
cell _stack_return[RETURN_STACK_SIZE];
cell *rspTop = &(_stack_return[RETURN_STACK_SIZE]);
cell *rsp;

code **ip;

// Only used for "heavy" calls - EXECUTE, etc.
// Most calls are direct threaded and don't need this pointer,
// or they use the (call) primitive rather than (docol).
code **cfa;
code *ca;

bool firstQuit = 1;
code *quitTop = NULL;
code **quitTopPtr = &quitTop;

union {
  cell* cells;
  char* chars;
} dsp;


#define INPUT_SOURCE_COUNT (32)

// A few more core globals.
cell state;
cell base;
header *searchOrder[16];
header **currentDictionary;
code **lastWord;

char parseBuffers[INPUT_SOURCE_COUNT][256];

typedef struct {
  cell parseLength;
  cell inputPtr; // Indexes into parseBuffer.
  cell type;     // 0 = KEYBOARD, -1 = EVALUATE, 0> fileid or extern symbol
  char *parseBuffer;
} source;

source inputSources[INPUT_SOURCE_COUNT];
cell inputIndex;
#define SRC (inputSources[inputIndex])


// And some miscellaneous helpers. These exist because I can't use locals in
// these C implementations without leaking stack space.
cell c1, c2, c3;
char ch1;
char* str1;
char** strptr1;
size_t tempSize;
header* tempHeader;
header** tempHeaderPtr;
char tempBuf[256];
unsigned char numBuf[sizeof(cell) * 2];
FILE* tempFile;
struct stat tempStat;
void *quit_inner;
struct timeval timeVal;
uint64_t i64;

struct termios old_tio, new_tio;


// These definitions and variables are for the primitive system, for the queue
// of operations and the map of implemented superinstructions.
typedef uint32_t super_key_t;


// Next key to use:
int primitive_count = 107;


typedef struct queued_primitive_ {
  code *target;
  bool hasValue;
  cell value;
  super_key_t key;
  struct queued_primitive_ *next;
} queued_primitive;

queued_primitive *queue = NULL;
queued_primitive *queueTail = NULL;
queued_primitive *tempQueue;
queued_primitive queueSource[4];
int next_queue_source = 0;
int queue_length = 0;

typedef struct {
  code *implementation;
  super_key_t key;
} superinstruction;

superinstruction primitives[256];
superinstruction superinstructions[256];
int nextSuperinstruction = 0;

super_key_t key1;

#define DEF_SI2(a, b) void code_superinstruction_ ## a ## _ ## b(void)
#define ADD_SI2(a, b) superinstructions[nextSuperinstruction].key = key_ ## a | (key_ ## b << 8);\
superinstructions[nextSuperinstruction++].implementation = &code_superinstruction_ ## a ## _ ## b;

#define DEF_SI3(a, b, c) void code_superinstruction_ ## a ## _ ## b ## _ ## c (void)
#define ADD_SI3(a, b, c) superinstructions[nextSuperinstruction].key = key_ ## a | (key_ ## b << 8) | (key_ ## c << 16);\
superinstructions[nextSuperinstruction++].implementation = &code_superinstruction_ ## a ## _ ## b ## _ ## c;

#define DEF_SI4(a, b, c, d) void code_superinstruction_ ## a ## _ ## b ## _ ## c ## _ ## d(void)
#define ADD_SI4(a, b, c, d) superinstructions[nextSuperinstruction].key = key_ ## a | (key_ ## b << 8) | (key_ ## c << 16) | (key_ ## d << 24);\
superinstructions[nextSuperinstruction++].implementation = &code_superinstruction_ ## a ## _ ## b ## _ ## c ## _ ## d;


// NB: If NEXT changes, EXECUTE might need to change too (it uses NEXT1)
// This flag is set in my YCM compile flags, which prevents errors.
// Clang (used by YCM) whines about computed GOTOs when the function defines no
// labels.
#ifdef __YCM__
#define NEXT1 __junk: do { goto __junk; } while(0)
#define NEXT __junk: do { goto __junk; } while(0)
#else
#define NEXT1 do { goto *ca; } while(0)
#define NEXT do { goto **ip++; } while(0)
#endif

// Implementations of the VM primitives.
// These functions MUST NOT USE locals, since that will use the stack.
// They should probably be one-liners, or nearly so, in C.
// They should generally finish with the NEXT or NEXT1 macros.

#define LEN_MASK        (0xff)
#define LEN_HIDDEN_MASK (0x1ff)
#define HIDDEN          (0x100)
#define IMMEDIATE       (0x200)

#define WORD(id, count, name, metadata, link) __attribute__((__noreturn__, __used__)) void code_ ## id (void);\
header header_ ## id = { link, metadata, name, &code_ ## id };\
super_key_t key_ ## id = (super_key_t) count;\
__attribute__((__noreturn__, __used__)) void code_ ## id (void)


// Run with -DTRACE to enable this.
#ifdef TRACE
// This expression is huge, but simplified, it reads:
// depth >= 3 ? print : depth == 2 ? print : depth == 1 ? print : print
// Printing the top 3, or as much as there is on the stack.
#define PRINT_TRACE(str) ((cell) (((char*) spTop) - ((char*) sp)) / sizeof(cell)) >= 3 ? printf(str "\t (%" PRIdPTR ") %" PRIdPTR " %" PRIdPTR " %" PRIdPTR "\n", ((cell) (((char*) spTop) - ((char*) sp)) / sizeof(cell)), sp[2], sp[1], sp[0]) : ((cell) (((char*) spTop) - ((char*) sp)) / sizeof(cell)) == 2 ? printf(str "\t (%" PRIdPTR ") %" PRIdPTR " %" PRIdPTR "\n", ((cell) (((char*) spTop) - ((char*) sp)) / sizeof(cell)), sp[1], sp[0]) : ((cell) (((char*) spTop) - ((char*) sp)) / sizeof(cell)) == 1 ? printf(str "\t (%" PRIdPTR ") %" PRIdPTR "\n", ((cell) (((char*) spTop) - ((char*) sp)) / sizeof(cell)), sp[0]) : printf(str "\t (%" PRIdPTR ")\n", ((cell) (((char*) spTop) - ((char*) sp)) / sizeof(cell)))
#else
#define PRINT_TRACE(str)
#endif

#ifdef ACCOUNTING
unsigned char accounts[100000000];
int accountIndex = 0;
#define ACCOUNT(me) accounts[accountIndex++] = key_ ## me;
#else
#define ACCOUNT(me)
#endif

#ifdef DEBUG
#define PRINT_DEBUG(...) printf(__VA_ARGS__)
#else
#define PRINT_DEBUG(...)
#endif

void print(char *str, cell len) {
  str1 = (char*) malloc(len + 1);
  strncpy(str1, str, len);
  str1[len] = '\0';
  printf("%s", str1);
  free(str1);
}


// Math operations
WORD(plus, 1, "+", 1, NULL) {
  ACCOUNT(plus);
  PRINT_TRACE("+");
  sp[1] = sp[0] + sp[1];
  sp++;
  NEXT;
}

WORD(minus, 2, "-", 1, &header_plus) {
  ACCOUNT(minus);
  PRINT_TRACE("-");
  sp[1] = sp[1] - sp[0];
  sp++;
  NEXT;
}

WORD(times, 3, "*", 1, &header_minus) {
  ACCOUNT(times);
  PRINT_TRACE("*");
  sp[1] = sp[1] * sp[0];
  sp++;
  NEXT;
}

WORD(div, 4, "/", 1, &header_times) {
  ACCOUNT(div);
  PRINT_TRACE("/");
  sp[1] = sp[1] / sp[0];
  sp++;
  NEXT;
}

WORD(udiv, 5, "U/", 2, &header_div) {
  ACCOUNT(udiv);
  PRINT_TRACE("U/");
  sp[1] = (cell) (((ucell) sp[1]) / ((ucell) sp[0]));
  sp++;
  NEXT;
}

WORD(mod, 6, "MOD", 3, &header_udiv) {
  ACCOUNT(mod);
  PRINT_TRACE("MOD");
  sp[1] = sp[1] % sp[0];
  sp++;
  NEXT;
}

WORD(umod, 7, "UMOD", 4, &header_mod) {
  ACCOUNT(umod);
  PRINT_TRACE("UMOD");
  sp[1] = (cell) (((ucell) sp[1]) % ((ucell) sp[0]));
  sp++;
  NEXT;
}

// Bitwise ops
WORD(and, 8, "AND", 3, &header_umod) {
  ACCOUNT(and);
  PRINT_TRACE("AND");
  sp[1] = sp[1] & sp[0];
  sp++;
  NEXT;
}
WORD(or, 9, "OR", 2, &header_and) {
  ACCOUNT(or);
  PRINT_TRACE("OR");
  sp[1] = sp[1] | sp[0];
  sp++;
  NEXT;
}
WORD(xor, 10, "XOR", 3, &header_or) {
  ACCOUNT(xor);
  PRINT_TRACE("XOR");
  sp[1] = sp[1] ^ sp[0];
  sp++;
  NEXT;
}

// Shifts
WORD(lshift, 11, "LSHIFT", 6, &header_xor) {
  ACCOUNT(lshift);
  PRINT_TRACE("LSHIFT");
  sp[1] = ((ucell) sp[1]) << sp[0];
  sp++;
  NEXT;
}

WORD(rshift, 12, "RSHIFT", 6, &header_lshift) {
  ACCOUNT(rshift);
  PRINT_TRACE("RSHIFT");
  sp[1] = ((ucell) sp[1]) >> sp[0];
  sp++;
  NEXT;
}

WORD(base, 13, "BASE", 4, &header_rshift) {
  ACCOUNT(base);
  PRINT_TRACE("BASE");
  *(--sp) = (cell) &base;
  NEXT;
}

// Comparison
WORD(less_than, 14, "<", 1, &header_base) {
  ACCOUNT(less_than);
  PRINT_TRACE("<");
  sp[1] = (sp[1] < sp[0]) ? -1 : 0;
  sp++;
  NEXT;
}

WORD(less_than_unsigned, 15, "U<", 2, &header_less_than) {
  ACCOUNT(less_than_unsigned);
  PRINT_TRACE("U<");
  sp[1] = ((ucell) sp[1]) < ((ucell) sp[0]) ? -1 : 0;
  sp++;
  NEXT;
}

WORD(equal, 16, "=", 1, &header_less_than_unsigned) {
  ACCOUNT(equal);
  PRINT_TRACE("=");
  sp[1] = sp[0] == sp[1] ? -1 : 0;
  sp++;
  NEXT;
}

// Stack manipulation
WORD(dup, 17, "DUP", 3, &header_equal) {
  ACCOUNT(dup);
  PRINT_TRACE("DUP");
  sp--;
  sp[0] = sp[1];
  NEXT;
}

WORD(swap, 18, "SWAP", 4, &header_dup) {
  ACCOUNT(swap);
  PRINT_TRACE("SWAP");
  c1 = sp[0];
  sp[0] = sp[1];
  sp[1] = c1;
  NEXT;
}

WORD(drop, 19, "DROP", 4, &header_swap) {
  ACCOUNT(drop);
  PRINT_TRACE("DROP");
  sp++;
  NEXT;
}

WORD(over, 20, "OVER", 4, &header_drop) {
  ACCOUNT(over);
  PRINT_TRACE("OVER");
  c1 = sp[1];
  *(--sp) = c1;
  NEXT;
}

WORD(rot, 21, "ROT", 3, &header_over) {
  ACCOUNT(rot);
  PRINT_TRACE("ROT");
  // ( c b a -- b a c )
  c1 = sp[2];
  sp[2] = sp[1];
  sp[1] = sp[0];
  sp[0] = c1;
  NEXT;
}

WORD(neg_rot, 22, "-ROT", 4, &header_rot) {
  ACCOUNT(neg_rot);
  PRINT_TRACE("-ROT");
  // ( c b a -- a c b )
  c1 = sp[2];
  sp[2] = sp[0];
  sp[0] = sp[1];
  sp[1] = c1;
  NEXT;
}

WORD(two_drop, 23, "2DROP", 5, &header_neg_rot) {
  ACCOUNT(two_drop);
  PRINT_TRACE("2DROP");
  sp += 2;
  NEXT;
}

WORD(two_dup, 24, "2DUP", 4, &header_two_drop) {
  ACCOUNT(two_dup);
  PRINT_TRACE("2DUP");
  sp -= 2;
  sp[1] = sp[3];
  sp[0] = sp[2];
  NEXT;
}

WORD(two_swap, 25, "2SWAP", 5, &header_two_dup) {
  ACCOUNT(two_swap);
  PRINT_TRACE("2SWAP");
  c1 = sp[2];
  sp[2] = sp[0];
  sp[0] = c1;

  c1 = sp[3];
  sp[3] = sp[1];
  sp[1] = c1;
  NEXT;
}

WORD(two_over, 26, "2OVER", 5, &header_two_swap) {
  ACCOUNT(two_over);
  PRINT_TRACE("2OVER");
  sp -= 2;
  sp[0] = sp[4];
  sp[1] = sp[5];
  NEXT;
}

WORD(to_r, 27, ">R", 2, &header_two_over) {
  ACCOUNT(to_r);
  PRINT_TRACE(">R");
  *(--rsp) = *(sp++);
  NEXT;
}

WORD(from_r, 28, "R>", 2, &header_to_r) {
  ACCOUNT(from_r);
  PRINT_TRACE("R>");
  *(--sp) = *(rsp++);
  NEXT;
}

// Memory access
WORD(fetch, 29, "@", 1, &header_from_r) {
  ACCOUNT(fetch);
  PRINT_TRACE("@");
  sp[0] = *((cell*) sp[0]);
  NEXT;
}
WORD(store, 30, "!", 1, &header_fetch) {
  ACCOUNT(store);
  PRINT_TRACE("!");
  *((cell*) sp[0]) = sp[1];
  sp += 2;
  NEXT;
}
WORD(cfetch, 31, "C@", 2, &header_store) {
  ACCOUNT(cfetch);
  PRINT_TRACE("C@");
  sp[0] = (cell) *((unsigned char*) sp[0]);
  NEXT;
}
WORD(cstore, 32, "C!", 2, &header_cfetch) {
  ACCOUNT(cstore);
  PRINT_TRACE("C!");
  *((unsigned char*) sp[0]) = (unsigned char) sp[1];
  sp += 2;
  NEXT;
}

// Allocates new regions. Might use malloc, or just an advancing pointer.
// The library calls this to acquire somewhere to put HERE.
// ( size-in-address-units -- a-addr )
WORD(raw_alloc, 33, "(ALLOCATE)", 10, &header_cstore) {
  ACCOUNT(raw_alloc);
  PRINT_TRACE("(ALLOCATE)");
  sp[0] = (cell) malloc(sp[0]);
  NEXT;
}

WORD(here_ptr, 34, "(>HERE)", 7, &header_raw_alloc) {
  ACCOUNT(here_ptr);
  PRINT_TRACE("(>HERE)");
  *(--sp) = (cell) (&dsp);
  NEXT;
}

WORD(print_internal, 35, "(PRINT)", 7, &header_here_ptr) {
  ACCOUNT(print_internal);
  PRINT_TRACE("(PRINT)");
  printf("%" PRIdPTR " ", sp[0]);
  sp++;
  NEXT;
}

WORD(state, 36, "STATE", 5, &header_print_internal) {
  ACCOUNT(state);
  PRINT_TRACE("STATE");
  *(--sp) = (cell) &state;
  NEXT;
}

// Branches
// Jumps unconditionally by the delta (in bytes) of the next CFA.
WORD(branch, 37, "(BRANCH)", 8, &header_state) {
  ACCOUNT(branch);
  PRINT_TRACE("(BRANCH)");
  str1 = (char*) ip;
  str1 += (cell) *ip;
  ip = (code**) str1;
  NEXT;
}

// Consumes the top argument on the stack. If it's 0, jumps over the branch
// address. Otherwise, identical to branch above.
WORD(zbranch, 38, "(0BRANCH)", 9, &header_branch) {
  ACCOUNT(zbranch);
  PRINT_TRACE("(0BRANCH)");
  str1 = (char*) ip;
  c1 = *(sp++) == 0 ? (cell) *ip : (cell) sizeof(cell);
  PRINT_DEBUG("0BRANCH delta: %" PRIdPTR "\n", c1);
  str1 += c1;
  ip = (code**) str1;
  NEXT;
}

// In the direct-threading style, xt's are still a codeword pointer.
// We need to doubly-indirect before setting cfa.
WORD(execute, 39, "EXECUTE", 7, &header_zbranch) {
  ACCOUNT(execute);
  PRINT_TRACE("EXECUTE");
  cfa = (code**) *(sp++);
  ca = *cfa;
  NEXT1;
}

WORD(evaluate, 40, "EVALUATE", 8, &header_execute) {
  ACCOUNT(evaluate);
  PRINT_TRACE("EVALUATE");
  inputIndex++;
  SRC.parseLength = sp[0];
  SRC.parseBuffer = (char*) sp[1];
  SRC.type = -1; // EVALUATE
  SRC.inputPtr = 0;
  sp += 2;

  // Set up the return stack to aim at whatever we were doing when EVALUATE was
  // called, and then jump back into interpreting.
  // TODO: This might slowly leak stack frames? Should double-check that.
  // That might be solved by moving this hack to be a special case where quit_
  // calls refill_. That's actually how my ARM assembler Forth system works.
  *(--rsp) = (cell) ip;
  goto *quit_inner;
}


// Input
cell refill_(void) {
  if (SRC.type == -1) { // EVALUATE
    // EVALUATE strings cannot be refilled. Pop the source.
    inputIndex--;
    // And do an EXIT to return to executing whoever called EVALUATE.
    ip = (code**) *(rsp++);
    NEXT;
    return 0;
  } else if ( SRC.type == 0) { // KEYBOARD
    str1 = readline("> ");
    SRC.parseLength = strlen(str1);
    strncpy(SRC.parseBuffer, str1, SRC.parseLength);
    SRC.inputPtr = 0;
    free(str1);
    return -1;
  } else if ( (SRC.type & EXTERNAL_SYMBOL_FLAG) != 0 ) {
    // External symbol, pseudofile.
    external_source *ext = (external_source*) (SRC.type & EXTERNAL_SYMBOL_MASK);
    if (ext->current >= ext->end) {
      inputIndex--;
      return 0;
    }

    str1 = ext->current;
    while (str1 < ext->end && *str1 != '\n') {
      str1++;
    }
    SRC.parseLength = str1 - ext->current;
    strncpy(SRC.parseBuffer, ext->current, SRC.parseLength);
    SRC.inputPtr = 0;

    ext->current = str1 < ext->end ? str1 + 1 : ext->end;
    return -1;
  } else {
    // Real file.
    str1 = NULL;
    tempSize = 0;
    c1 = getline(&str1, &tempSize, (FILE*) SRC.type);

    if (c1 == -1) {
      // Dump the source and recurse.
      inputIndex--;
      return 0;
    } else {
      // Knock off the trailing newline, if present.
      if (str1[c1 - 1] == '\n') c1--;
      strncpy(SRC.parseBuffer, str1, c1);
      free(str1);
      SRC.parseLength = c1;
      SRC.inputPtr = 0;
      return -1;
    }
  }
}

// TODO: This one is pushing in the assembly. Triggered by calling refill_?
WORD(refill, 41, "REFILL", 6, &header_evaluate) {
  ACCOUNT(refill);
  PRINT_TRACE("REFILL");
  // Special case here. When the input source is EVALUATE, return false and do
  // nothing else. We don't want to actually call refill_ for that case.
  if (SRC.type == -1) {
    *(--sp) = 0;
  } else {
    *(--sp) = refill_();
  }
  NEXT;
}

WORD(accept, 42, "ACCEPT", 6, &header_refill) {
  ACCOUNT(accept);
  PRINT_TRACE("ACCEPT");
  str1 = readline(NULL); // No prompt.
  c1 = strlen(str1);
  if (sp[0] < c1) c1 = sp[0];
  strncpy((char*) sp[1], str1, c1);
  sp[1] = c1;
  sp++;
  free(str1);
  NEXT;
}

WORD(key, 43, "KEY", 3, &header_accept) {
  ACCOUNT(key);
  PRINT_TRACE("KEY");

  // Grab the current terminal settings.
  tcgetattr(STDIN_FILENO, &old_tio);
  // Copy to preserve the original.
  new_tio = old_tio;
  // Disable the canonical mode (buffered I/O) flag and local echo.
  new_tio.c_lflag &= (~ICANON & ~ECHO);
  // And write it back.
  tcsetattr(STDIN_FILENO, TCSANOW, &new_tio);

  // Read a single character.
  *(--sp) = getchar();

  // And put things back.
  tcsetattr(STDIN_FILENO, TCSANOW, &old_tio);
  NEXT;
}

WORD(latest, 44, "(LATEST)", 8, &header_key) {
  ACCOUNT(latest);
  PRINT_TRACE("(LATEST)");
  *(--sp) = (cell) currentDictionary;
  NEXT;
}

WORD(in_ptr, 45, ">IN", 3, &header_latest) {
  ACCOUNT(in_ptr);
  PRINT_TRACE(">IN");
  *(--sp) = (cell) (&SRC.inputPtr);
  NEXT;
}

WORD(emit, 46, "EMIT", 4, &header_in_ptr) {
  ACCOUNT(emit);
  PRINT_TRACE("EMIT");
  fputc(*(sp++), stdout);
  NEXT;
}

WORD(source, 47, "SOURCE", 6, &header_emit) {
  ACCOUNT(source);
  PRINT_TRACE("SOURCE");
  sp -= 2;
  sp[0] = SRC.parseLength;
  sp[1] = (cell) SRC.parseBuffer;
  NEXT;
}

WORD(source_id, 48, "SOURCE-ID", 9, &header_source) {
  ACCOUNT(source_id);
  PRINT_TRACE("SOURCE-ID");
  *(--sp) = SRC.type;
  NEXT;
}


// Sizes and metadata
WORD(size_cell, 49, "(/CELL)", 7, &header_source_id) {
  ACCOUNT(size_cell);
  PRINT_TRACE("(/CELL)");
  *(--sp) = (cell) sizeof(cell);
  NEXT;
}

WORD(size_char, 50, "(/CHAR)", 7, &header_size_cell) {
  ACCOUNT(size_char);
  PRINT_TRACE("(/CHAR)");
  *(--sp) = (cell) sizeof(char);
  NEXT;
}

WORD(cells, 51, "CELLS", 5, &header_size_char) {
  ACCOUNT(cells);
  PRINT_TRACE("CELLS");
  sp[0] *= sizeof(cell);
  NEXT;
}

WORD(chars, 52, "CHARS", 5, &header_cells) {
  ACCOUNT(chars);
  PRINT_TRACE("CELLS");
  sp[0] *= sizeof(char);
  NEXT;
}

WORD(unit_bits, 53, "(ADDRESS-UNIT-BITS)", 19, &header_chars) {
  ACCOUNT(unit_bits);
  PRINT_TRACE("(ADDRESS-UNIT-BITS)");
  *(--sp) = (cell) (CHAR_BIT);
  NEXT;
}

WORD(stack_cells, 54, "(STACK-CELLS)", 13, &header_unit_bits) {
  ACCOUNT(stack_cells);
  PRINT_TRACE("(STACK-CELLS)");
  *(--sp) = (cell) DATA_STACK_SIZE;
  NEXT;
}
WORD(return_stack_cells, 55, "(RETURN-STACK-CELLS)", 20, &header_stack_cells) {
  ACCOUNT(return_stack_cells);
  PRINT_TRACE("(RETURN-STACK-CELLS)");
  *(--sp) = (cell) RETURN_STACK_SIZE;
  NEXT;
}

// Converts a header* eg. from (latest) into the DOES> address, which is
// the cell after the CFA.
WORD(to_does, 56, "(>DOES)", 7, &header_return_stack_cells) {
  ACCOUNT(to_does);
  PRINT_TRACE("(>DOES)");
  tempHeader = (header*) sp[0];
  sp[0] = ((cell) &(tempHeader->code_field)) + sizeof(cell);
  NEXT;
}

// Converts a header* eg. from (latest) into the code field address.
WORD(to_cfa, 57, "(>CFA)", 6, &header_to_does) {
  ACCOUNT(to_cfa);
  PRINT_TRACE("(>CFA)");
  tempHeader = (header*) sp[0];
  sp[0] = (cell) &(tempHeader->code_field);
  NEXT;
}

// Advances a CFA to be the data-space pointer, which is for a CREATEd
// definition two cells after the xt.
WORD(to_body, 58, ">BODY", 5, & header_to_cfa) {
  ACCOUNT(to_body);
  PRINT_TRACE(">BODY");
  sp[0] += (cell) (2 * sizeof(cell));
  NEXT;
}

// Pushes the last word that was defined, whether with : or :NONAME.
WORD(last_word, 59, "(LAST-WORD)", 11, &header_to_body) {
  ACCOUNT(last_word);
  PRINT_TRACE("(LAST-WORD)");
  *(--sp) = (cell) lastWord;
  NEXT;
}


// Compiler helpers

// Pushes ip -> rsp, and puts my own data field into ip.
WORD(docol, 60, "(DOCOL)", 7, &header_last_word) {
  ACCOUNT(docol);
  PRINT_TRACE("(DOCOL)");
  *(--rsp) = (cell) ip;
  ip = &(cfa[1]);
  NEXT;
}

// Pushes its data field onto the stack.
WORD(dolit, 61, "(DOLIT)", 7, &header_docol) {
  ACCOUNT(dolit);
  PRINT_TRACE("(DOLIT)");
  *(--sp) = (cell) *(ip++);
  NEXT;
}

WORD(dostring, 62, "(DOSTRING)", 10, &header_dolit) {
  ACCOUNT(dostring);
  PRINT_TRACE("(DOSTRING)");
  str1 = ((char*) ip);
  c1 = (cell) *str1;
  sp -= 2;
  sp[1] = (cell) (str1 + 1);
  sp[0] = c1;

  str1 += c1 + 1 + (sizeof(cell) - 1);
  str1 = (char*) (((cell) str1) & ~(sizeof(cell) - 1));
  ip = (code**) str1;

  NEXT;
}

// CREATE compiles 0 and then the user's code into the data space.
// It uses (dodoes) as the doer word, not docol! That will push the address of
// the user's data space area, as intended (cfa + 2 cells) and then check that
// 0 at cfa + 1 cell. If it's 0, do nothing. Otherwise, jump to that point.
WORD(dodoes, 63, "(DODOES)", 8, &header_dostring) {
  ACCOUNT(dodoes);
  PRINT_TRACE("(DODOES)");
  str1 = (char*) cfa;
  *(--sp) = (cell) (str1 + 2 * sizeof(cell));
  c1 = (cell) *((code**) (str1 + sizeof(cell)));

  // Similar to docol, push onto the return stack and jump.
  if (c1 != 0) {
    *(--rsp) = (cell) ip;
    ip = (code**) c1;
  }
  NEXT;
}

void parse_(void) {
  if ( SRC.inputPtr >= SRC.parseLength ) {
    sp[0] = 0;
    *(--sp) = 0;
  } else {
    ch1 = (char) sp[0];
    str1 = SRC.parseBuffer + SRC.inputPtr;
    c1 = 0;
    while ( SRC.inputPtr < SRC.parseLength && SRC.parseBuffer[SRC.inputPtr] != ch1 ) {
      SRC.inputPtr++;
      c1++;
    }
    if ( SRC.inputPtr < SRC.parseLength ) SRC.inputPtr++; // Skip over the delimiter.
    sp[0] = (cell) str1;
    *(--sp) = c1;
  }
}

void parse_name_(void) {
  // Skip any leading delimiters.
  while ( SRC.inputPtr < SRC.parseLength && (SRC.parseBuffer[SRC.inputPtr] == ' ' || SRC.parseBuffer[SRC.inputPtr] == '\t') ) {
    SRC.inputPtr++;
  }
  c1 = 0;
  str1 = SRC.parseBuffer + SRC.inputPtr;
  while ( SRC.inputPtr < SRC.parseLength && SRC.parseBuffer[SRC.inputPtr] != ' ' ) {
    SRC.inputPtr++;
    c1++;
  }
  if (SRC.inputPtr < SRC.parseLength) SRC.inputPtr++; // Jump over a trailing delimiter.
  *(--sp) = (cell) str1;
  *(--sp) = c1;
}

// The basic >NUMBER - unsigned values only, no magic $ff or whatever.
// sp[0] is the length, sp[1] the pointer, sp[2] the high word, sp[3] the low.
// ( lo hi c-addr u -- lo hi c-addr u )
void to_number_int_(void) {
  // Copying the numbers into the buffers.
  for (c1 = 0; c1 < (cell) sizeof(cell); c1++) {
    numBuf[c1] = (unsigned char) ((((ucell) sp[3]) >> (c1*8)) & 0xff);
    numBuf[sizeof(cell) + c1] = (unsigned char) ((((ucell) sp[2]) >> (c1*8)) & 0xff);
  }

  while (sp[0] > 0) {
    c1 = (cell) *str1;
    if ('0' <= c1 && c1 <= '9') {
      c1 -= '0';
    } else if ('A' <= c1 && c1 <= 'Z') {
      c1 = c1 - 'A' + 10;
    } else if ('a' <= c1 && c1 <= 'z') {
      c1 = c1 - 'a' + 10;
    } else {
      break;
    }

    if (c1 >= (cell) tempSize) break;

    // Otherwise, a valid character, so multiply it in.
    for (c3 = 0; c3 < 2 * (cell) sizeof(cell) ; c3++) {
      c2 = ((ucell) numBuf[c3]) * tempSize + c1;
      numBuf[c3] = (unsigned char) (c2 & 0xff);
      c1 = (c2 >> 8) & 0xff;
    }

    sp[0]--;
    str1++;
  }

  sp[2] = 0;
  sp[3] = 0;
  for (c1 = 0; c1 < (cell) sizeof(cell); c1++) {
    sp[3] |= (cell) (((ucell) numBuf[c1]) << (c1*8));
    sp[2] |= (cell) (((ucell) numBuf[sizeof(cell) + c1]) << (c1*8));
  }
  sp[1] = (cell) str1;
}

void to_number_(void) {
  tempSize = base;
  str1 = (char*) sp[1];
  to_number_int_();
}

// This is the full number parser, for use by quit_.
void parse_number_(void) {
  // sp[0] is the length, sp[1] the pointer, sp[2] the high word, sp[3] the low.
  // ( lo hi c-addr u -- lo hi c-addr u )
  str1 = (char*) sp[1];
  tempSize = base;
  if (*str1 == '$' || *str1 == '#' || *str1 == '%') {
    tempSize = *str1 == '$' ? 16 : *str1 == '#' ? 10 : 2;
    str1++;
    sp[0]--;
  } else if (*str1 == '\'') {
    sp[0] -= 3;
    sp[1] += 3;
    sp[3] = str1[1];
    return;
  }

  // Usin ch1 as a negation flag.
  ch1 = 0;
  if (*str1 == '-') {
    sp[0]--;
    str1++;
    ch1 = 1;
  }

  // Now parse the number itself.
  to_number_int_();

  // And negate if needed.
  if (ch1) {
    sp[3] = ~sp[3];
    sp[2] = ~sp[2];
    sp[3]++;
    if (sp[3] == 0) sp[2]++;
  }
}

// Expects c-addr u on top of the stack.
// Returns 0 0 on not found, xt 1 for immediate, or xt -1 for not immediate.
void find_(void) {
  tempHeaderPtr = currentDictionary;
  while (tempHeaderPtr != NULL) {
    tempHeader = *tempHeaderPtr;
    while (tempHeader != NULL) {
      if ((tempHeader->metadata & LEN_HIDDEN_MASK) == sp[0]) {
        if (strncasecmp(tempHeader->name, (char*) sp[1], sp[0]) == 0) {
          sp[1] = (cell) (&(tempHeader->code_field));
          sp[0] = (tempHeader->metadata & IMMEDIATE) == 0 ? -1 : 1;
          return;
        }
      }
      tempHeader = tempHeader->link;
    }
    if (tempHeaderPtr == searchOrder) break;
    tempHeaderPtr--;
  }
  sp[1] = 0;
  sp[0] = 0;
}

WORD(parse, 64, "PARSE", 5, &header_dodoes) {
  ACCOUNT(parse);
  PRINT_TRACE("PARSE");
  parse_();
  NEXT;
}

WORD(parse_name, 65, "PARSE-NAME", 10, &header_parse) {
  ACCOUNT(parse_name);
  PRINT_TRACE("PARSE-NAME");
  parse_name_();
  NEXT;
}

WORD(to_number, 66, ">NUMBER", 7, &header_parse_name) {
  ACCOUNT(to_number);
  PRINT_TRACE(">NUMBER");
  to_number_();
  NEXT;
}

// Parses a name, and constructs a header for it.
// When finished, HERE is the data space properly, ready for compilation.
// TODO: This function pushes %rbx. Why? Maybe branch its bits into a separate
// function?
WORD(create, 67, "CREATE", 6, &header_to_number) {
  ACCOUNT(create);
  PRINT_TRACE("CREATE");
  parse_name_(); // sp[0] = length, sp[1] = string
  dsp.chars = (char*) ((((cell)dsp.chars) + sizeof(cell) - 1) & ~(sizeof(cell) - 1));
  tempHeader = (header*) dsp.chars;
  dsp.chars += sizeof(header);
  tempHeader->link = *currentDictionary;
  *currentDictionary = tempHeader;

  tempHeader->metadata = sp[0];
  tempHeader->name = (char*) malloc(sp[0] * sizeof(char));
  strncpy(tempHeader->name, (char*) sp[1], sp[0]);
  sp += 2;
  tempHeader->code_field = &code_dodoes;

  // Add the extra cell for dodoes; this is the DOES> address, or 0 for none.
  *(dsp.cells++) = 0;
  NEXT;
}

// TODO: This is allocating stack space - why?
WORD(find, 68, "(FIND)", 6, &header_create) {
  ACCOUNT(find);
  PRINT_TRACE("(FIND)");
  find_();
  NEXT;
}

WORD(depth, 69, "DEPTH", 5, &header_find) {
  ACCOUNT(depth);
  PRINT_TRACE("DEPTH");
  c1 = (cell) (((char*) spTop) - ((char*) sp)) / sizeof(cell);
  *(--sp) = c1;
  NEXT;
}

WORD(sp_fetch, 70, "SP@", 3, &header_depth) {
  ACCOUNT(sp_fetch);
  PRINT_TRACE("SP@");
  c1 = (cell) sp;
  *(--sp) = c1;
  NEXT;
}

WORD(sp_store, 71, "SP!", 3, &header_sp_fetch) {
  ACCOUNT(sp_store);
  PRINT_TRACE("SP!");
  c1 = sp[0];
  sp = (cell*) c1;
  NEXT;
}

WORD(rp_fetch, 72, "RP@", 3, &header_sp_store) {
  ACCOUNT(rp_fetch);
  PRINT_TRACE("RP@");
  *(--sp) = (cell) rsp;
  NEXT;
}

WORD(rp_store, 73, "RP!", 3, &header_rp_fetch) {
  ACCOUNT(rp_store);
  PRINT_TRACE("RP!");
  rsp = (cell*) *(sp++);
  NEXT;
}

void dot_s_(void) {
  printf("[%" PRIdPTR "] ", (cell) (((char*) spTop) - ((char*) sp)) / sizeof(cell));
  for (c1 = (cell) (&spTop[-1]); c1 >= (cell) sp; c1 -= sizeof(cell*)) {
    printf("%" PRIdPTR " ", *((cell*) c1));
  }
  printf("\n");
}

WORD(dot_s, 74, ".S", 2, &header_rp_store) {
  ACCOUNT(dot_s);
  PRINT_TRACE(".S");
  dot_s_();
  NEXT;
}

void u_dot_s_(void) {
  printf("[%" PRIdPTR "] ", (cell) (((char*) spTop) - ((char*) sp)) / sizeof(cell));
  for (c1 = (cell) (&spTop[-1]); c1 >= (cell) sp; c1 -= sizeof(cell*)) {
    printf("%" PRIxPTR " ", *((cell*) c1));
  }
  printf("\n");
}

WORD(u_dot_s, 75, "U.S", 3, &header_dot_s) {
  ACCOUNT(u_dot_s);
  PRINT_TRACE("U.S");
  u_dot_s_();
  NEXT;
}

// File access
// This is a hack included to support the assemblers and such.
// It writes a block of bytes to a binary file.
WORD(dump_file, 76, "(DUMP-FILE)", 11, &header_u_dot_s) {
  ACCOUNT(dump_file);
  PRINT_TRACE("(DUMP-FILE)");
  // ( c-addr1 u1 c-addr2 u2 ) String on top (2) and binary data below (1)
  // Open the named file for truncated write-only.
  strncpy(tempBuf, (char*) sp[1], sp[0]);
  tempBuf[sp[0]] = '\0';
  tempFile = fopen(tempBuf, "wb");
  if (tempFile == NULL) {
    fprintf(stderr, "*** Failed to open file for writing: %s\n", tempBuf);
  } else {
    c1 = (cell) fwrite((void*) sp[3], 1, sp[2], tempFile);
    printf("(Dumped %" PRIdPTR " of %" PRIdPTR " bytes to %s)\n", c1, sp[2], tempBuf);
    fclose(tempFile);
    tempFile = NULL;
  }
  NEXT;
}


// Primitive for calling a (DOCOL) word.
// Expects the next cell in ip-space to be the address of the code.
// Otherwise it resembles a (DOCOL).
super_key_t key_call_ = 100;

void call_() {
  ACCOUNT(call_);
  PRINT_TRACE("call_");
  ca = *(ip++);
  *(--rsp) = (cell) ip;
  ip = (code**) ca;
  NEXT;
}

// Expects c1 to be the code*.
// Sets key1 to the associated key. Exits if not found.
void lookup_primitive() {
  for (c2 = 0; c2 < primitive_count; c2++) {
    if (primitives[c2].implementation == (code*) c1) {
      key1 = primitives[c2].key;
      return;
    }
  }
  exit(40);
}

void drain_queue_(void) {
#ifdef ENABLE_SUPERINSTRUCTIONS
  // Try to find the longest possible sequence that has a superinstruction.
  key1 = 0;
  tempQueue = queue;
  c1 = 0;
  while (tempQueue != NULL) {
    key1 |= tempQueue->key << (8 * c1);
    c1++;
    tempQueue = tempQueue->next;
  }

  // c1 remains the number of primitives we're attempting to combine.
  while (c1 > 1) {
    for (c2 = 0; c2 < nextSuperinstruction; c2++) {
      if (superinstructions[c2].key == key1) {
        // We have a match!
        // Compile it in.
#ifdef SUPERINSTRUCTION_DEBUG
        fprintf(stderr, "Superinstruction match! %x %" PRIuPTR " %d %" PRIuPTR "\n",
            key1, (cell) superinstructions[c2].implementation, queue->hasValue,
            queue->value);
#endif

        *(dsp.cells++) = (cell) superinstructions[c2].implementation;

        while (c1 > 0) {
          if (queue->hasValue) {
            *(dsp.cells++) = queue->value;
          }
          queue = queue->next;
          queue_length--;
          c1--;
        }
        if (queue == NULL) queueTail = NULL;
#ifdef SUPERINSTRUCTION_DEBUG
        fprintf(stderr, "\tQueue length remaining: %d\n", queue_length);
#endif
        return;
      }
    }
    c1--;
    // Mask off another byte and try again.
    key1 &= ((super_key_t) -1) >> ((4 - c1) * 8);
  }
#endif

  // If we get down here, we've failed to find any superinstruction, but still
  // need to make space in the queue. Therefore, compile the singular entry and
  // advance the queue.
#ifdef SUPERINSTRUCTION_DEBUG
  fprintf(stderr, "Basic dequeue, key %d. %d items remaining.\n",
      queue->key, queue_length - 1);
#endif
  *(dsp.cells++) = (cell) queue->target;
  if (queue->hasValue) *(dsp.cells++) = queue->value;
  queue = queue->next;
  if (queue == NULL) queueTail = NULL;
  queue_length--;
}

void bump_queue_tail_() {
  if (queueTail == NULL) {
    queue = queueTail = &queueSource[next_queue_source++];
  } else {
    queueTail->next = &queueSource[next_queue_source++];
    queueTail = queueTail->next;
  }
  queueTail->next = NULL;
  next_queue_source &= 3;
  queue_length++;
}

// This is the heart of the new superinstruction system.
// It should build up a queue of primitives requested, until it fills up, then
// convert into the most efficient possible superinstructions.
void compile_() {
  // If the queue is full, drain it first.
  if (queue_length >= 4) {
    drain_queue_();
  }

  bump_queue_tail_();
  // queueTail now points at a valid queue slot.

  // Check the doer-word. If we're looking at a (DOCOL) word, compile a call_.
  // TODO: Probably need custom handling for other stuff too: (DODOES),
  // (DOSTRING)?
  if (*((code**) sp[0]) == &code_docol) {
#ifdef SUPERINSTRUCTION_DEBUG
    fprintf(stderr, "Enqueuing a call_\n");
#endif
    queueTail->target = &call_;
    queueTail->hasValue = 1;
    queueTail->value = (cell) (((char*) *(sp++)) + sizeof(cell));
    queueTail->key = key_call_;
  } else if (*((code**) sp[0]) == &code_dodoes) {
    // (DODOES) pushes the data space pointer (CFA + 2 cells) onto the stack,
    // then checks CFA[1]. If that's 0, do nothing. If it's a CFA, jump to it.
    // Here we inline that into a literal for the data space pointer followed
    // optionally by a call_ to the DOES> code.

#ifdef SUPERINSTRUCTION_DEBUG
    fprintf(stderr, "Enqueuing a (dodoes)\n");
#endif
    queueTail->target = &code_dolit;
    queueTail->hasValue = 1;
    queueTail->value = (cell) (((ucell) sp[0]) + 2 * sizeof(cell));
    queueTail->key = key_dolit;

    if (*((cell*) (((ucell) sp[0]) + sizeof(cell))) != 0) {
      if (queue_length == 4) drain_queue_();
      bump_queue_tail_();

#ifdef SUPERINSTRUCTION_DEBUG
    fprintf(stderr, "\tWith a DOES>\n");
#endif

      queueTail->target = &call_;
      queueTail->hasValue = 1;
      queueTail->value = (cell) *((code**) (((ucell) sp[0]) + sizeof(cell)));
      queueTail->key = key_call_;
    }

    // The other two branches do this in-line, but I need to do it here.
    sp++;
  } else {
#ifdef SUPERINSTRUCTION_DEBUG
    tempHeader = (header*) (sp[0] - 3 * sizeof(cell));
    fprintf(stderr, "Enqueuing a primitive: %.*s\n",
        (int) (tempHeader->metadata & LEN_MASK), tempHeader->name);
#endif
    c1 = (cell) *((code**) *(sp++));
    lookup_primitive();
    queueTail->target = (code*) c1;
    queueTail->hasValue = 0;
    queueTail->key = key1;
  }
}

void compile_lit_() {
  // If the queue is full, drain it first.
  if (queue_length >= 4) {
    drain_queue_();
  }

  bump_queue_tail_();
  queueTail->target = &code_dolit;
  queueTail->hasValue = 1;
  queueTail->value = *(sp++);
  queueTail->key = key_dolit;
}


// This could easily enough be turned into a Forth word.
char *savedString;
cell savedLength;

void quit_(void) {
  // Empty the stacks.
quit_top:
  sp = spTop;
  rsp = rspTop;
  state = INTERPRETING;

  // If this is not the first QUIT, reset to keyboard input.
  if (!firstQuit) {
    inputIndex = 0;
  }

  // Save the label below for use by EVALUATE.
  quit_inner = &&quit_loop;

  // Refill the input buffer.
  refill_();
  // And start trying to parse things.
  while (true) {
    // ( )
quit_loop:
    while (true) {
      parse_name_(); // ( c-addr u )
      if (sp[0] != 0) {
        break;
      } else {
        if (SRC.type == 0) printf("  ok\n");
        sp += 2;
        refill_();
      }
    }

    // ( c-addr u ) and u is nonzero
    savedString = (char*) sp[1]; // Set aside the string and length.
    savedLength = sp[0];
    //print(savedString, savedLength);
    //printf("\n");
    find_(); // xt immediate (or 0 0)
    if (sp[0] == 0) { // Failed to parse. Try to parse as a number.
      // I can use the existing ( 0 0 ) as the empty number for >number
      sp -= 2;
      sp[0] = savedLength;
      sp[1] = (cell) savedString; // Bring back the string and length.

      parse_number_();
      if (sp[0] == 0) { // Successful parse, handle the number.
        if (state == COMPILING) {
          sp += 3; // Number now on top.
          compile_lit_();
        } else {
          // Clear my mess from the stack, but leave the new number atop it.
          sp += 3;
        }
      } else { // Failed parse of a number. Unrecognized word.
        strncpy(tempBuf, savedString, savedLength);
        tempBuf[savedLength] = '\0';
        fprintf(stderr, "*** Unrecognized word: %s\n", tempBuf);
        goto quit_top;
      }
    } else {
      // Successful parse. ( xt 1 ) indicates immediate, ( xt -1 ) not.
      if (sp[0] == 1 || state == INTERPRETING) {
        quitTop = &&quit_loop;
        ip = &quitTop;
        cfa = (code**) sp[1];
        sp += 2;
        //NEXT1;
        QUIT_JUMP_IN;
        __builtin_unreachable();
      } else { // Compiling mode
        sp++;
        compile_();
      }
    }
  }
  // Should never be reachable.
}

WORD(quit, 77, "QUIT", 4, &header_dump_file) {
  ACCOUNT(quit);
  PRINT_TRACE("QUIT");
  inputIndex = 0;
  quit_();
  NEXT;
}

WORD(bye, 78, "BYE", 3, &header_quit) {
  ACCOUNT(bye);
  PRINT_TRACE("BYE");
#ifdef ACCOUNTING
  // Dump the accounts array to stderr.
  c1 = 0;
  fwrite(accounts, 1, accountIndex, stderr);
#endif
  exit(0);
}

// TODO: This is pushing onto the stack! Fix it! This one is important.
WORD(compile_comma, 79, "COMPILE,", 8, &header_bye) {
  compile_();
  NEXT;
}

WORD(literal, 101, "LITERAL", 7 | IMMEDIATE, &header_compile_comma) {
  // Compiles the value on top of the stack into the current definition.
  compile_lit_();
  NEXT;
}

WORD(compile_literal, 102, "[LITERAL]", 9, &header_literal) {
  compile_lit_();
  NEXT;
}

WORD(compile_zbranch, 103, "[0BRANCH]", 9, &header_compile_literal) {
  *(--sp) = (cell) &(header_zbranch.code_field);
  compile_();
  while (queue_length > 0) drain_queue_();
  *(--sp) = (cell) dsp.cells;
  *(dsp.cells++) = 0;
  NEXT;
}

WORD(compile_branch, 104, "[BRANCH]", 8, &header_compile_zbranch) {
  *(--sp) = (cell) &(header_branch.code_field);
  compile_();
  while (queue_length > 0) drain_queue_();
  *(--sp) = (cell) dsp.cells;
  *(dsp.cells++) = 0;
  NEXT;
}

WORD(control_flush, 105, "(CONTROL-FLUSH)", 15, &header_compile_branch) {
  while (queue_length > 0) drain_queue_();
  NEXT;
}

WORD(debug_break, 80, "(DEBUG)", 7, &header_control_flush) {
  NEXT;
}


// File Access
// Access modes are defined as in the following constants, so they can be
// manipulated in Forth safely.
#define FA_READ (1)
#define FA_WRITE (2)
#define FA_BIN (4)
#define FA_TRUNC (8)

// TODO: Most of the file access words are pushing. Fix that.
WORD(close_file, 81, "CLOSE-FILE", 10, &header_debug_break) {
  c1 = (cell) fclose((FILE*) sp[0]);
  sp[0] = c1 ? errno : 0;
  NEXT;
}

char *file_modes[16] = {
  NULL,  // 0 = none
  "r",   // 1 = read, no-truncate
  "r+",  // 2 = write-only, no-truncate
  "r+",  // 3 = read/write, no-truncate
  NULL,  // 4 = bin only, busted.
  "rb",  // 5 = read-only, bin, no-truncate
  "r+b", // 6 = write-only, bin, no-truncate
  "r+b", // 7 = read/write, bin, no-truncate
  NULL,  // 8 = truncate only, busted.
  "w+",  // 9 = read-only, truncated
  "w",   // 10 = write-only, truncated
  "w+",  // 11 = read/write, truncated
  NULL,  // 12 = bin|trunc, but no main mode
  "w+b", // 13 = read-only, bin, truncated
  "wb",  // 14 = write-only, bin, truncated
  "w+b" // 15 = read/write, bin, truncated
};

WORD(create_file, 82, "CREATE-FILE", 11, &header_close_file) {
  strncpy(tempBuf, (char*) sp[2], sp[1]);
  tempBuf[sp[1]] = '\0';
  sp++;
  sp[1] = (cell) fopen(tempBuf, file_modes[sp[0] | FA_TRUNC]);
  sp[0] = sp[1] == 0 ? errno : 0;
  NEXT;
}

// Don't truncate files that exist. Opening a file for R/O that doesn't exist is
// a failure, but opening a file that doesn't exist for W/O or R/W should
// create.
// Therefore if we try the normal open, and it fails, we should try again with
// TRUNC enabled, IFF the FA_WRITE bit is set.
WORD(open_file, 83, "OPEN-FILE", 9, &header_create_file) {
  strncpy(tempBuf, (char*) sp[2], sp[1]);
  tempBuf[sp[1]] = '\0';
  sp[2] = (cell) fopen(tempBuf, file_modes[sp[0]]);
  if ((FILE*) sp[2] == NULL && (sp[0] & FA_WRITE) != 0) {
    // Try again with TRUNC added to allow creation.
    sp[2] = (cell) fopen(tempBuf, file_modes[sp[0] | FA_TRUNC]);
  }
  sp[1] = sp[2] == 0 ? errno : 0;
  sp++;
  NEXT;
}

WORD(delete_file, 84, "DELETE-FILE", 11, &header_open_file) {
  strncpy(tempBuf, (char*) sp[1], sp[0]);
  tempBuf[sp[0]] = '\0';
  sp++;
  sp[0] = remove(tempBuf);
  if (sp[0] == -1) sp[0] = errno;
  NEXT;
}

WORD(file_position, 85, "FILE-POSITION", 13, &header_delete_file) {
  sp -= 2;
  sp[1] = 0;
  sp[2] = (cell) ftell((FILE*) sp[2]);
  sp[0] = sp[2] == -1 ? errno : 0;
  NEXT;
}

/*
WORD(file_size, "FILE-SIZE", 10, &header_file_position) {
  sp -= 2;
  sp[1] = 0;
  sp[0] = fstat(fileno((FILE*) sp[2]), &tempStat);
  if (sp[0] == 0) {
    sp[2] = tempStat.st_size;
  } else {
    sp[2] = 0;
    sp[0] = errno;
  }
  NEXT;
}
*/

WORD(file_size, 86, "FILE-SIZE", 9, &header_file_position) {
  sp -= 2;
  sp[1] = 0;
  c1 = ftell((FILE*) sp[2]); // Save the position.
  if (c1 < 0) {
    sp[0] = errno;
  } else {
    c2 = fseek((FILE*) sp[2], 0L, SEEK_END);
    if (c2 < 0) {
      sp[0] = errno;
      fseek((FILE*) sp[2], (long) c1, SEEK_SET);
    } else {
      c2 = ftell((FILE*) sp[2]);
      fseek((FILE*) sp[2], (long) c1, SEEK_SET);
      sp[2] = c2;
      sp[0] = 0;
    }
  }
  NEXT;
}


WORD(include_file, 87, "INCLUDE-FILE", 12, &header_file_size) {
  inputIndex++;
  SRC.type = *(sp++);
  SRC.inputPtr = 0;
  SRC.parseLength = 0;
  SRC.parseBuffer = parseBuffers[inputIndex];
  NEXT;
}

WORD(read_file, 88, "READ-FILE", 9, &header_include_file) {
  c1 = (cell) fread((void*) sp[2], 1, sp[1], (FILE*) sp[0]);
  if (c1 == 0) {
    if (feof((FILE*) sp[0])) {
      sp++;
      sp[0] = 0;
      sp[1] = 0;
    } else {
      sp[1] = ferror((FILE*) sp[0]);
      sp[2] = 0;
      sp++;
    }
  } else {
    sp++;
    sp[1] = c1;
    sp[0] = 0;
  }
  NEXT;
}

// Expects a buffer and size. Reads at most that many characters, plus the
// delimiter. Should return a size that EXCLUDES the terminator.
// Uses getline, and if the line turns out to be longer than our buffer, the
// file is repositioned accordingly.
WORD(read_line, 89, "READ-LINE", 9, &header_read_file) {
  str1 = NULL;
  tempSize = 0;
  c1 = getline(&str1, &tempSize, (FILE*) sp[0]);
  if (c1 == -1) {
    sp[0] = errno;
    sp[2] = 0;
    sp[1] = 0;
  } else if (c1 == 0) {
    sp[0] = 0;
    sp[1] = 0;
    sp[2] = 0;
  } else {
    if (c1 - 1 > sp[1]) { // Line is too long for the buffer.
      fseek((FILE*) sp[0], c1 - sp[1], SEEK_CUR);
      c1 = sp[1] + 1;
    } else if (str1[c1 - 1] != '\n') { // Found EOF, not newline.
      c1++;
    }

    strncpy((char*) sp[2], str1, c1 - 1);
    sp[0] = 0;
    sp[1] = true;
    sp[2] = c1 - 1;
  }

  if (str1 != NULL) free(str1);
  NEXT;
}

WORD(reposition_file, 90, "REPOSITION-FILE", 15, &header_read_line) {
  sp[2] = fseek((FILE*) sp[0], sp[2], SEEK_SET);
  sp += 2;
  if (sp[0] == -1) sp[0] = errno;
  NEXT;
}

WORD(resize_file, 91, "RESIZE-FILE", 11, &header_reposition_file) {
  sp[2] = ftruncate(fileno((FILE*) sp[0]), sp[2]);
  sp += 2;
  sp[0] = sp[0] == -1 ? errno : 0;
  NEXT;
}

WORD(write_file, 92, "WRITE-FILE", 10, &header_resize_file) {
  //printf("%d\n", sp[1]);
  c1 = fwrite((void*) sp[2], 1, sp[1], (FILE*) sp[0]);
  sp += 2;
  sp[0] = 0;
  NEXT;
}

WORD(write_line, 93, "WRITE-LINE", 10, &header_write_file) {
  strncpy(tempBuf, (char*) sp[2], sp[1]);
  tempBuf[sp[1]] = '\n';
  c1 = fwrite((void*) tempBuf, 1, sp[1] + 1, (FILE*) sp[0]);
  sp += 2;
  sp[0] = 0;
  NEXT;
}

WORD(flush_file, 94, "FLUSH-FILE", 10, &header_write_line) {
  sp[0] = (cell) fsync(fileno((FILE*) sp[0]));
  if (sp[0] == -1) sp[0] = errno;
  NEXT;
}


// And back to core.

// TODO: This is pushing - fix it!
WORD(colon, 95, ":", 1, &header_flush_file) {
  ACCOUNT(colon);
  PRINT_TRACE(":");
  // Align HERE.
  dsp.chars = (char*) ((((ucell) (dsp.chars)) + sizeof(cell) - 1) & ~(sizeof(cell) - 1));
  tempHeader = (header*) dsp.chars;
  dsp.chars += sizeof(header);
  tempHeader->link = *currentDictionary;
  *currentDictionary = tempHeader;
  parse_name_(); // ( c-addr u )
  if (sp[0] == 0) {
    fprintf(stderr, "*** Colon definition with no name\n");
    code_quit();
    // Never returns
  }

#ifdef DEBUG
  print((char*) sp[1], sp[0]);
#endif
  tempHeader->name = (char*) malloc(sp[0]);
  strncpy(tempHeader->name, (char*) sp[1], sp[0]);
  tempHeader->metadata = sp[0] | HIDDEN;
  sp += 2;
  tempHeader->code_field = &code_docol;
  lastWord = &(tempHeader->code_field);

#ifdef DEBUG
  printf(" starts at %" PRIxPTR "\n", (cell) dsp.chars);
#endif

  state = COMPILING;
  NEXT;
}

WORD(colon_no_name, 96, ":NONAME", 7, &header_colon) {
  ACCOUNT(colon_no_name);
  PRINT_TRACE(":NONAME");

  // Similar to : but without parsing and storing a name.
  // Has no header, just pushes its own xt onto the stack.

  // Align HERE.
  dsp.chars = (char*) ((((ucell) (dsp.chars)) + sizeof(cell) - 1) & ~(sizeof(cell) - 1));
  lastWord = (code**) dsp.cells;
  *(--sp) = (cell) dsp.cells;
  *(dsp.cells++) = (cell) &code_docol;

  state = COMPILING;
  NEXT;
}

// Pop the return stack and NEXT into it.
#define EXIT_NEXT ip = (code**) *(rsp++);\
NEXT

#define CALL_NEXT ca = *(ip++);\
  *(--rsp) = (cell) ip;\
  ip = (code**) ca;\
  NEXT

WORD(exit, 97, "EXIT", 4, &header_colon_no_name) {
  ACCOUNT(exit);
  PRINT_TRACE("EXIT");
  EXIT_NEXT;
}

// TODO: This is broken in the new style, but I'm ignoring it.
WORD(see, 98, "SEE", 3, &header_exit) {
  ACCOUNT(see);
  PRINT_TRACE("SEE");
  // Parses a word and visualizes its contents.
  parse_name_();
  printf("Decompiling ");
  print((char*) sp[1], sp[0]);
  printf("\n");

  find_(); // Now xt and flag on the stack.
  if (sp[0] == 0) {
    printf("NOT FOUND!\n");
  } else {
    cfa = (code**) sp[1];
    if (*cfa != &code_docol) {
      printf("Not compiled using DOCOL; can't SEE native words.\n");
    } else {
      tempHeader = NULL;
      do {
        cfa++;
        // If the previous word was dolit, then this value is a literal, not
        // a word pointer.
        // Likewise, if it was dostring, we should print the string.
        // Likewise, if it was a branch, we should show the branch target.
        if (tempHeader == &header_dolit) {
          tempHeader = NULL; // Reset tempHeader, or it gets stuck on this case.
          c1 = (cell) *cfa;
          printf("%" PRIuPTR ": (literal) %" PRIdPTR "\n", (ucell) cfa, c1);
        } else if (tempHeader == &header_zbranch || tempHeader == &header_branch) {
          tempHeader = NULL;
          c1 = (cell) *cfa;
          c1 = (cell) (((char*) cfa) + c1);
          printf("%" PRIuPTR ": branch by %" PRIdPTR " to: %" PRIuPTR "\n", (ucell) cfa, (cell) *cfa, c1);
        } else if (tempHeader == &header_dostring) {
          tempHeader = NULL;
          str1 = (char*) cfa;
          c1 = (cell) *str1;
          str1++;
          strncpy(tempBuf, str1, c1);
          tempBuf[c1] = '\0';
          while (c1 > 0) {
            printf("%d ", *str1);
            str1++;
            c1--;
          }
          printf("\"%s\"\n", tempBuf);
          cfa = (code**) ((ucell) (str1 + (sizeof(cell) - 1)) & ((ucell) (~(sizeof(cell) - 1))));
        } else {
          str1 = (char*) *cfa;
          tempHeader = (header*) (str1 - sizeof(cell) * 3);
          printf("%" PRIuPTR ": ", (ucell) cfa);
          print(tempHeader->name, tempHeader->metadata & LEN_MASK);
          printf("\n");
        }
      } while (*cfa != (code*) &(header_exit.code_field));
    }
  }

  sp += 2; // Drop the parsed values.
  NEXT;
}

WORD(utime, 106, "UTIME", 5, &header_see) {
  ACCOUNT(utime);
  PRINT_TRACE("UTIME");

  // The return value here is a double-cell integer, but we need to check if
  // time_t is smaller than a cell (64-bit) or not (32-bit).
  gettimeofday(&timeVal, NULL);
  sp -= 2;
  // Microseconds are millionths of seconds. Check if we're on a 64-bit machine.
  // If so there's enough room in the low cell of the double-cell return for the 
  // complete time value. If on a 32-bit machine, it won't fit.
  if (sizeof(cell) > 4) {
    sp[1] = (cell) ((ucell) timeVal.tv_sec) * 1000000 + ((ucell) timeVal.tv_usec);
    sp[0] = 0;
  } else {
    i64 = ((uint64_t) timeVal.tv_sec) * 1000000 + ((uint64_t) timeVal.tv_usec);
    sp[1] = (i64 >> 32);
    sp[0] = i64 & 0xffffffff;
  }
  NEXT;
}

// TODO: This is pushing - fix it.
WORD(semicolon, 99, ";", 1 | IMMEDIATE, &header_utime) {
  ACCOUNT(semicolon);
  PRINT_TRACE(";");
  (*currentDictionary)->metadata &= (~HIDDEN); // Clear the hidden bit.

  // Compile an EXIT
  *(--sp) = (cell) &(header_exit.code_field);
  compile_();
  // And drain the queue completely - this definition is over.
  while (queue_length) drain_queue_();

  // And stop compiling.
  state = INTERPRETING;
  NEXT;
}

// NB: If anything gets added after SEMICOLON, change the dictionary below.

void init_primitives(void);
void init_superinstructions(void);

int main(int argc, char **argv) {
  currentDictionary = searchOrder;
  *currentDictionary = &header_semicolon;
  base = 10;
  inputIndex = 0;
  SRC.type = SRC.parseLength = SRC.inputPtr = 0;
  SRC.parseBuffer = parseBuffers[inputIndex];

  // Open the input files in reverse order and push them as file inputs.
  argc--;
  for (; argc > 0; argc--) {
    inputIndex++;
    SRC.type = (cell) fopen(argv[argc], "r");
    if ((FILE*) SRC.type == NULL) {
      fprintf(stderr, "Could not load input file: %s\n", argv[argc]);
      exit(1);
    }

    SRC.inputPtr = 0;
    SRC.parseLength = 0;
    SRC.parseBuffer = parseBuffers[inputIndex];
  }

  // Turn the external Forth libraries into input sources.
  external_source *ext;
  EXTERNAL_FILES(EXTERNAL_INPUT_SOURCES)

  init_primitives();
  init_superinstructions();

  quit_();
}

#define INIT_PRIM(id) primitives[key_ ## id - 1] = (superinstruction) { &code_ ## id, key_ ## id }
void init_primitives(void) {
  INIT_PRIM(plus);
  INIT_PRIM(minus);
  INIT_PRIM(times);
  INIT_PRIM(div);
  INIT_PRIM(udiv);
  INIT_PRIM(mod);
  INIT_PRIM(umod);
  INIT_PRIM(and);
  INIT_PRIM(or);
  INIT_PRIM(xor);
  INIT_PRIM(lshift);
  INIT_PRIM(rshift);
  INIT_PRIM(base);
  INIT_PRIM(less_than);
  INIT_PRIM(less_than_unsigned);
  INIT_PRIM(equal);
  INIT_PRIM(dup);
  INIT_PRIM(swap);
  INIT_PRIM(drop);
  INIT_PRIM(over);
  INIT_PRIM(rot);
  INIT_PRIM(neg_rot);
  INIT_PRIM(two_drop);
  INIT_PRIM(two_dup);
  INIT_PRIM(two_swap);
  INIT_PRIM(two_over);
  INIT_PRIM(to_r);
  INIT_PRIM(from_r);
  INIT_PRIM(fetch);
  INIT_PRIM(store);
  INIT_PRIM(cfetch);
  INIT_PRIM(cstore);
  INIT_PRIM(raw_alloc);
  INIT_PRIM(here_ptr);
  INIT_PRIM(print_internal);
  INIT_PRIM(state);
  INIT_PRIM(branch);
  INIT_PRIM(zbranch);
  INIT_PRIM(execute);
  INIT_PRIM(evaluate);
  INIT_PRIM(refill);
  INIT_PRIM(accept);
  INIT_PRIM(key);
  INIT_PRIM(latest);
  INIT_PRIM(in_ptr);
  INIT_PRIM(emit);
  INIT_PRIM(source);
  INIT_PRIM(source_id);
  INIT_PRIM(size_cell);
  INIT_PRIM(size_char);
  INIT_PRIM(cells);
  INIT_PRIM(chars);
  INIT_PRIM(unit_bits);
  INIT_PRIM(stack_cells);
  INIT_PRIM(return_stack_cells);
  INIT_PRIM(to_does);
  INIT_PRIM(to_cfa);
  INIT_PRIM(to_body);
  INIT_PRIM(last_word);
  INIT_PRIM(docol);
  INIT_PRIM(dolit);
  INIT_PRIM(dostring);
  INIT_PRIM(dodoes);
  INIT_PRIM(parse);
  INIT_PRIM(parse_name);
  INIT_PRIM(to_number);
  INIT_PRIM(create);
  INIT_PRIM(find);
  INIT_PRIM(depth);
  INIT_PRIM(sp_fetch);
  INIT_PRIM(sp_store);
  INIT_PRIM(rp_fetch);
  INIT_PRIM(rp_store);
  INIT_PRIM(dot_s);
  INIT_PRIM(u_dot_s);
  INIT_PRIM(dump_file);
  INIT_PRIM(quit);
  INIT_PRIM(bye);
  INIT_PRIM(compile_comma);
  INIT_PRIM(debug_break);
  INIT_PRIM(close_file);
  INIT_PRIM(create_file);
  INIT_PRIM(open_file);
  INIT_PRIM(delete_file);
  INIT_PRIM(file_position);
  INIT_PRIM(file_size);
  INIT_PRIM(file_size);
  INIT_PRIM(include_file);
  INIT_PRIM(read_file);
  INIT_PRIM(read_line);
  INIT_PRIM(reposition_file);
  INIT_PRIM(resize_file);
  INIT_PRIM(write_file);
  INIT_PRIM(write_line);
  INIT_PRIM(flush_file);
  INIT_PRIM(colon);
  INIT_PRIM(colon_no_name);
  INIT_PRIM(exit);
  INIT_PRIM(see);
  INIT_PRIM(semicolon);
  INIT_PRIM(literal);
  INIT_PRIM(compile_literal);
  INIT_PRIM(compile_zbranch);
  INIT_PRIM(compile_branch);
  INIT_PRIM(control_flush);
  INIT_PRIM(utime);
}


// Superinstruction implementations
DEF_SI2(from_r, from_r) {
  sp -= 2;
  sp[1] = rsp[0];
  sp[0] = rsp[1];
  rsp += 2;
  NEXT;
}

DEF_SI2(fetch, exit) {
  sp[0] = *((cell*) sp[0]);
  EXIT_NEXT;
}

DEF_SI2(swap, to_r) {
  c1 = sp[1];
  sp[1] = sp[0];
  sp++;
  *(--rsp) = c1;
  NEXT;
}

DEF_SI2(to_r, swap) {
  *(--rsp) = sp[0];
  c1 = sp[2];
  sp[2] = sp[1];
  sp[1] = c1;
  sp++;
  NEXT;
}

DEF_SI2(to_r, exit) {
  // Not using EXIT_NEXT here, for speed.
  ip = (code**) *(sp++);
  NEXT;
}

DEF_SI2(from_r, dup) {
  sp -= 2;
  sp[1] = rsp[0];
  sp[0] = rsp[0];
  rsp++;
  NEXT;
}

DEF_SI2(dolit, equal) {
  c1 = (cell) *(ip++);
  sp[0] = sp[0] == c1 ? true : false;
  NEXT;
}

DEF_SI2(dolit, fetch) {
  *(--sp) = *((cell*) *(ip++));
  NEXT;
}

DEF_SI2(dup, to_r) {
  *(--rsp) = sp[0];
  NEXT;
}

DEF_SI2(dolit, dolit) {
  sp -= 2;
  sp[1] = (cell) *(ip++);
  sp[0] = (cell) *(ip++);
  NEXT;
}

DEF_SI2(plus, exit) {
  sp[1] += sp[0];
  sp++;
  EXIT_NEXT;
}

DEF_SI2(dolit, plus) {
  sp[0] += (cell) *(ip++);
  NEXT;
}

DEF_SI2(dolit, less_than) {
  sp[0] = sp[0] < ((cell) *(ip++)) ? true : false;
  NEXT;
}

DEF_SI2(plus, fetch) {
  sp[1] = *((cell*) (sp[0] + sp[1]));
  sp++;
  NEXT;
}

DEF_SI2(to_r, to_r) {
  rsp -= 2;
  rsp[1] = sp[0];
  rsp[0] = sp[1];
  sp += 2;
  NEXT;
}

DEF_SI2(dolit, call_) {
  *(--sp) = (cell) *(ip++);
  CALL_NEXT;
}

DEF_SI2(equal, exit) {
  sp[1] = sp[1] == sp[0] ? true : false;
  sp++;
  EXIT_NEXT;
}


// 3-part superinstructions

DEF_SI3(to_r, swap, from_r) {
  // Actually just swapping sp[1] and sp[2].
  c1 = sp[2];
  sp[2] = sp[1];
  sp[1] = c1;
  NEXT;
}

DEF_SI3(swap, to_r, exit) {
  *(--rsp) = sp[1];
  sp[1] = sp[0];
  sp++;
  EXIT_NEXT;
}

DEF_SI3(from_r, from_r, dup) {
  sp -= 3;
  sp[2] = rsp[0];
  sp[0] = sp[1] = rsp[1];
  rsp += 2;
  NEXT;
}

DEF_SI3(dup, to_r, swap) {
  *(--rsp) = sp[0];
  c1 = sp[1];
  sp[1] = sp[0];
  sp[0] = c1;
  NEXT;
}

DEF_SI3(from_r, dup, to_r) {
  *(--sp) = rsp[0];
  NEXT;
}

DEF_SI3(dolit, fetch, exit) {
  *(--sp) = *((cell*) *(ip++));
  EXIT_NEXT;
}

DEF_SI3(dolit, plus, exit) {
  sp[0] += (cell) *(ip++);
  EXIT_NEXT;
}

DEF_SI3(dolit, less_than, exit) {
  sp[0] = sp[0] < ((cell) *(ip++)) ? true : false;
  EXIT_NEXT;
}

// TODO: This is a candidate for compile-time inlining, actually.
// Probably not worth the investment.
DEF_SI3(dolit, dolit, plus) {
  *(--sp) = ((cell*) ip)[0] + ((cell*) ip)[1];
  ip += 2;
  NEXT;
}

DEF_SI3(cells, sp_fetch, plus) {
  sp[0] = ((cell) sp) + (sp[0] * sizeof(cell));
  NEXT;
}

DEF_SI3(to_r, swap, to_r) {
  *(--rsp) = sp[0];
  *(--rsp) = sp[2];
  sp[2] = sp[1];
  sp += 2;
  NEXT;
}

DEF_SI3(dolit, equal, exit) {
  sp[0] = sp[0] == ((cell) *(ip++)) ? true : false;
  EXIT_NEXT;
}

DEF_SI3(sp_fetch, plus, fetch) {
  sp[0] = *((cell*) ((cell) sp) + sp[0]);
  NEXT;
}

DEF_SI3(plus, fetch, exit) {
  sp[1] = *((cell*) sp[1] + sp[0]);
  sp++;
  EXIT_NEXT;
}

DEF_SI3(from_r, from_r, two_dup) {
  sp -= 4;
  sp[3] = rsp[0];
  sp[1] = rsp[0];
  sp[2] = rsp[1];
  sp[0] = rsp[1];
  rsp += 2;
  NEXT;
}

// ( a b c -- c a b -- c a+b -- c / a+b )
DEF_SI3(neg_rot, plus, to_r) {
  *(--rsp) = sp[1] + sp[2];
  sp[2] = sp[0];
  sp += 2;
  NEXT;
}

DEF_SI3(two_dup, minus, to_r) {
  *(--rsp) = sp[1] - sp[0];
  NEXT;
}


// 4-part superinstructions

DEF_SI4(to_r, swap, to_r, exit) {
  c1 = rsp[0];
  rsp[0] = sp[0];
  sp[0] = c1;
  EXIT_NEXT;
}

// ( a b -- b   R: a b )
DEF_SI4(dup, to_r, swap, to_r) {
  rsp -= 2;
  rsp[1] = sp[0];
  rsp[0] = sp[1];
  sp[1] = sp[0];
  sp++;
  NEXT;
}

DEF_SI4(from_r, dup, to_r, swap) {
  sp--;
  sp[0] = sp[1];
  sp[1] = rsp[0];
  NEXT;
}

DEF_SI4(from_r, from_r, dup, to_r) {
  sp -= 2;
  sp[1] = rsp[0];
  sp[0] = rsp[1];
  rsp++;
  NEXT;
}

DEF_SI4(cells, sp_fetch, plus, fetch) {
  sp[0] = *((cell*) ((sp[0] * sizeof(cell)) + ((cell) sp)));
  NEXT;
}

DEF_SI4(two_dup, minus, to_r, dolit) {
  *(--rsp) = sp[1] - sp[0];
  *(--sp) = (cell) *(ip++);
  NEXT;
}

// ( a  R: b -- a b -- a b a b -- a b a-b -- a b  R: a-b )
DEF_SI4(from_r, two_dup, minus, to_r) {
  *(--sp) = rsp[0];
  rsp[0] = sp[1] - sp[0];
  NEXT;
}

DEF_SI4(from_r, from_r, two_dup, minus) {
  sp -= 3;
  sp[2] = rsp[0];
  sp[1] = rsp[1];
  sp[0] = sp[2] - sp[1];
  rsp += 2;
  NEXT;
}

void init_superinstructions(void) {
  nextSuperinstruction = 0;

  ADD_SI2(from_r, from_r);
  ADD_SI2(fetch, exit);
  ADD_SI2(swap, to_r);
  ADD_SI2(to_r, swap);
  ADD_SI2(to_r, exit);
  ADD_SI2(from_r, dup);
  ADD_SI2(dolit, equal);
  ADD_SI2(dolit, fetch);
  ADD_SI2(dup, to_r);
  ADD_SI2(dolit, dolit);
  ADD_SI2(plus, exit);
  ADD_SI2(dolit, plus);
  ADD_SI2(dolit, less_than);
  ADD_SI2(plus, fetch);
  ADD_SI2(to_r, to_r);
  ADD_SI2(dolit, call_);
  ADD_SI2(equal, exit);

  ADD_SI3(to_r, swap, from_r);
  ADD_SI3(swap, to_r, exit);
  ADD_SI3(from_r, from_r, dup);
  ADD_SI3(dup, to_r, swap);
  ADD_SI3(cells, sp_fetch, plus);
  ADD_SI3(to_r, swap, to_r);
  ADD_SI3(dolit, equal, exit);
  ADD_SI3(from_r, dup, to_r);
  ADD_SI3(dolit, plus, exit);
  ADD_SI3(dolit, less_than, exit);
  ADD_SI3(sp_fetch, plus, fetch);
  ADD_SI3(plus, fetch, exit);
  ADD_SI3(from_r, from_r, two_dup);
  ADD_SI3(neg_rot, plus, to_r);
  ADD_SI3(two_dup, minus, to_r);

  ADD_SI4(to_r, swap, to_r, exit);
  ADD_SI4(dup, to_r, swap, to_r);
  ADD_SI4(from_r, dup, to_r, swap);
  ADD_SI4(from_r, from_r, dup, to_r);
  ADD_SI4(cells, sp_fetch, plus, fetch);
  ADD_SI4(two_dup, minus, to_r, dolit);
  ADD_SI4(from_r, two_dup, minus, to_r);
  ADD_SI4(from_r, from_r, two_dup, minus);
}

// TODO: Converting PICK into C would probably speed up loops a lot; it looks
// like several of the hottest superinstructions are coming from (LOOP-END),
// which uses PICK.

