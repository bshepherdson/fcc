#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
#include <limits.h>
#include <unistd.h>
#include <termios.h>

#include <readline/readline.h>
//#include <readline/history.h>

#include <md.h>

// Meta-macro that takes another macro and runs it for each external library.
// To add a new external file, it should be sufficient to add it here.
// NB: THESE ARE IN REVERSE ORDER. The bottom-most is loaded first!
#define EXTERNAL_FILES(F) \
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
  SRC.parseLength = 0;

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

code ***ip;
code **cfa;

bool firstQuit = 1;
code *quitTop = NULL;
code **quitTopPtr = &quitTop;

union {
  cell* cells;
  char* chars;
} dsp;


// A few more core globals.
cell state;
cell base;
header *dictionary;

typedef struct {
  cell parseLength;
  cell inputPtr; // Indexes into parseBuffer.
  cell type;     // 0 = KEYBOARD, -1 = EVALUATE, 0> fileid or extern symbol
  char parseBuffer[256];
} source;

source inputSources[16];
cell inputIndex;
#define SRC (inputSources[inputIndex])


// And some miscellaneous helpers. These exist because I can't use locals in
// these C implementations without leaking stack space.
cell c1;
char ch1;
char* str1;
char** strptr1;
size_t tempSize;
header* tempHeader;
char tempBuf[256];
FILE* tempFile;

struct termios old_tio, new_tio;

// NB: If NEXT changes, EXECUTE might need to change too (it uses NEXT1)
// This flag is set in my YCM compile flags, which prevents errors.
// Clang (used by YCM) whines about computed GOTOs when the function defines no
// labels.
#ifdef __YCM__
#define NEXT1 __junk: do { goto __junk; } while(0)
#define NEXT __junk: do { goto __junk; } while(0)
#else
#define NEXT1 do { goto **cfa; } while(0)
#define NEXT do { cfa = *ip++; goto **cfa; } while(0)
#endif

// Implementations of the VM primitives.
// These functions MUST NOT USE locals, since that will use the stack.
// They should probably be one-liners, or nearly so, in C.
// They should generally finish with the NEXT or NEXT1 macros.

#define LEN_MASK        (0xff)
#define LEN_HIDDEN_MASK (0x1ff)
#define HIDDEN          (0x100)
#define IMMEDIATE       (0x200)

#define WORD(id, name, metadata, link) __attribute__((__noreturn__, __used__)) void code_ ## id (void);\
header header_ ## id = { link, metadata, name, &code_ ## id };\
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
WORD(plus, "+", 1, NULL) {
  PRINT_TRACE("+");
  sp[1] = sp[0] + sp[1];
  sp++;
  NEXT;
}

WORD(minus, "-", 1, &header_plus) {
  PRINT_TRACE("-");
  sp[1] = sp[1] - sp[0];
  sp++;
  NEXT;
}

WORD(times, "*", 1, &header_minus) {
  PRINT_TRACE("*");
  sp[1] = sp[1] * sp[0];
  sp++;
  NEXT;
}

WORD(div, "/", 1, &header_times) {
  PRINT_TRACE("/");
  sp[1] = sp[1] / sp[0];
  sp++;
  NEXT;
}

WORD(mod, "MOD", 3, &header_div) {
  PRINT_TRACE("MOD");
  sp[1] = sp[1] % sp[0];
  sp++;
  NEXT;
}


// Bitwise ops
WORD(and, "AND", 3, &header_mod) {
  PRINT_TRACE("AND");
  sp[1] = sp[1] & sp[0];
  sp++;
  NEXT;
}
WORD(or, "OR", 2, &header_and) {
  PRINT_TRACE("OR");
  sp[1] = sp[1] | sp[0];
  sp++;
  NEXT;
}
WORD(xor, "XOR", 3, &header_or) {
  PRINT_TRACE("XOR");
  sp[1] = sp[1] ^ sp[0];
  sp++;
  NEXT;
}

// Shifts
WORD(lshift, "LSHIFT", 6, &header_xor) {
  PRINT_TRACE("LSHIFT");
  sp[1] = ((ucell) sp[1]) << sp[0];
  sp++;
  NEXT;
}

WORD(rshift, "RSHIFT", 6, &header_lshift) {
  PRINT_TRACE("RSHIFT");
  sp[1] = ((ucell) sp[1]) >> sp[0];
  sp++;
  NEXT;
}

WORD(base, "BASE", 4, &header_rshift) {
  PRINT_TRACE("BASE");
  *(--sp) = (cell) &base;
  NEXT;
}

// Comparison
WORD(less_than, "<", 1, &header_base) {
  PRINT_TRACE("<");
  sp[1] = (sp[1] < sp[0]) ? -1 : 0;
  sp++;
  NEXT;
}

WORD(less_than_unsigned, "U<", 2, &header_less_than) {
  PRINT_TRACE("U<");
  sp[1] = ((ucell) sp[1]) < ((ucell) sp[0]) ? -1 : 0;
  sp++;
  NEXT;
}

WORD(equal, "=", 1, &header_less_than_unsigned) {
  PRINT_TRACE("=");
  sp[1] = sp[0] == sp[1] ? -1 : 0;
  sp++;
  NEXT;
}

// Stack manipulation
WORD(dup, "DUP", 3, &header_equal) {
  PRINT_TRACE("DUP");
  sp--;
  sp[0] = sp[1];
  NEXT;
}

WORD(swap, "SWAP", 4, &header_dup) {
  PRINT_TRACE("SWAP");
  c1 = sp[0];
  sp[0] = sp[1];
  sp[1] = c1;
  NEXT;
}

WORD(drop, "DROP", 4, &header_swap) {
  PRINT_TRACE("DROP");
  sp++;
  NEXT;
}

WORD(to_r, ">R", 2, &header_drop) {
  PRINT_TRACE(">R");
  *(--rsp) = *(sp++);
  NEXT;
}

WORD(from_r, "R>", 2, &header_to_r) {
  PRINT_TRACE("R>");
  *(--sp) = *(rsp++);
  NEXT;
}

// Memory access
WORD(fetch, "@", 1, &header_from_r) {
  PRINT_TRACE("@");
  sp[0] = *((cell*) sp[0]);
  NEXT;
}
WORD(store, "!", 1, &header_fetch) {
  PRINT_TRACE("!");
  *((cell*) sp[0]) = sp[1];
  sp += 2;
  NEXT;
}
WORD(cfetch, "C@", 2, &header_store) {
  PRINT_TRACE("C@");
  sp[0] = (cell) *((char*) sp[0]);
  NEXT;
}
WORD(cstore, "C!", 2, &header_cfetch) {
  PRINT_TRACE("C!");
  *((char*) sp[0]) = (char) sp[1];
  sp += 2;
  NEXT;
}

// Allocates new regions. Might use malloc, or just an advancing pointer.
// The library calls this to acquire somewhere to put HERE.
// ( size-in-address-units -- a-addr )
WORD(raw_alloc, "(ALLOCATE)", 10, &header_cstore) {
  PRINT_TRACE("(ALLOCATE)");
  sp[0] = (cell) malloc(sp[0]);
  NEXT;
}

WORD(here_ptr, "(>HERE)", 7, &header_raw_alloc) {
  PRINT_TRACE("(>HERE)");
  *(--sp) = (cell) (&dsp);
  NEXT;
}

WORD(print_internal, "(PRINT)", 7, &header_here_ptr) {
  PRINT_TRACE("(PRINT)");
  printf("%" PRIdPTR " ", sp[0]);
  sp++;
  NEXT;
}

WORD(state, "STATE", 5, &header_print_internal) {
  PRINT_TRACE("STATE");
  *(--sp) = (cell) &state;
  NEXT;
}

// Branches
// Jumps unconditionally by the delta (in bytes) of the next CFA.
WORD(branch, "(BRANCH)", 8, &header_state) {
  PRINT_TRACE("(BRANCH)");
  str1 = (char*) ip;
  str1 += (cell) *ip;
  ip = (code***) str1;
  NEXT;
}

// Consumes the top argument on the stack. If it's 0, jumps over the branch
// address. Otherwise, identical to branch above.
WORD(zbranch, "(0BRANCH)", 9, &header_branch) {
  PRINT_TRACE("(0BRANCH)");
  str1 = (char*) ip;
  c1 = *(sp++) == 0 ? (cell) *ip : (cell) sizeof(cell);
  PRINT_DEBUG("0BRANCH delta: %" PRIdPTR "\n", c1);
  str1 += c1;
  ip = (code***) str1;
  NEXT;
}

WORD(execute, "EXECUTE", 7, &header_zbranch) {
  PRINT_TRACE("EXECUTE");
  cfa = (code**) *(sp++);
  NEXT1;
}

WORD(evaluate, "EVALUATE", 8, &header_execute) {
  PRINT_TRACE("EVALUATE");
  inputIndex++;
  SRC.parseLength = sp[0];
  strncpy(SRC.parseBuffer, (char*) sp[1], sp[0]);
  SRC.type = -1; // EVALUATE
  SRC.inputPtr = 0;
  sp += 2;
  NEXT;
}


// Input
cell refill_(void) {
  if (SRC.type == -1) { // EVALUATE
    // EVALUATE strings cannot be refilled. Pop the source.
    inputIndex--;
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

WORD(refill, "REFILL", 6, &header_evaluate) {
  PRINT_TRACE("REFILL");
  *(--sp) = refill_();
  NEXT;
}

WORD(accept, "ACCEPT", 6, &header_refill) {
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

WORD(key, "KEY", 3, &header_accept) {
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

WORD(latest, "(LATEST)", 8, &header_key) {
  PRINT_TRACE("(LATEST)");
  *(--sp) = (cell) &dictionary;
  NEXT;
}

WORD(in_ptr, ">IN", 3, &header_latest) {
  PRINT_TRACE(">IN");
  *(--sp) = (cell) (&SRC.inputPtr);
  NEXT;
}

WORD(emit, "EMIT", 4, &header_in_ptr) {
  PRINT_TRACE("EMIT");
  fputc(*(sp++), stdout);
  NEXT;
}

WORD(source, "SOURCE", 6, &header_emit) {
  PRINT_TRACE("SOURCE");
  sp -= 2;
  sp[0] = SRC.parseLength;
  sp[1] = (cell) SRC.parseBuffer;
  NEXT;
}

WORD(source_id, "SOURCE-ID", 9, &header_source) {
  PRINT_TRACE("SOURCE-ID");
  *(--sp) = SRC.type;
  NEXT;
}


// Sizes and metadata
WORD(size_cell, "(/CELL)", 7, &header_source_id) {
  PRINT_TRACE("(/CELL)");
  *(--sp) = (cell) sizeof(cell);
  NEXT;
}

WORD(size_char, "(/CHAR)", 7, &header_size_cell) {
  PRINT_TRACE("(/CHAR)");
  *(--sp) = (cell) sizeof(char);
  NEXT;
}

WORD(unit_bits, "(ADDRESS-UNIT-BITS)", 19, &header_size_char) {
  PRINT_TRACE("(ADDRESS-UNIT-BITS)");
  *(--sp) = (cell) (CHAR_BIT);
  NEXT;
}

WORD(stack_cells, "(STACK-CELLS)", 13, &header_unit_bits) {
  PRINT_TRACE("(STACK-CELLS)");
  *(--sp) = (cell) DATA_STACK_SIZE;
  NEXT;
}
WORD(return_stack_cells, "(RETURN-STACK-CELLS)", 20, &header_stack_cells) {
  PRINT_TRACE("(RETURN-STACK-CELLS)");
  *(--sp) = (cell) RETURN_STACK_SIZE;
  NEXT;
}

// Converts a header* eg. from (latest) into the DOES> address, which is
// the cell after the CFA.
WORD(to_does, "(>DOES)", 7, &header_return_stack_cells) {
  PRINT_TRACE("(>DOES)");
  tempHeader = (header*) sp[0];
  sp[0] = ((cell) &(tempHeader->code_field)) + sizeof(cell);
  NEXT;
}

// Converts a header* eg. from (latest) into the DOES> address, which is
// the cell after the CFA.
WORD(to_cfa, "(>CFA)", 6, &header_to_does) {
  PRINT_TRACE("(>CFA)");
  tempHeader = (header*) sp[0];
  sp[0] = (cell) &(tempHeader->code_field);
  NEXT;
}

// Advances a CFA to be the data-space pointer, which is for a CREATEd
// definition two cells after the xt.
WORD(to_body, ">BODY", 5, & header_to_cfa) {
  PRINT_TRACE(">BODY");
  sp[0] += (cell) (2 * sizeof(cell));
  NEXT;
}


// Compiler helpers

// Pushes ip -> rsp, and puts my own data field into ip.
WORD(docol, "(DOCOL)", 7, &header_to_body) {
  PRINT_TRACE("(DOCOL)");
  *(--rsp) = (cell) ip;
  ip = (code***) &(cfa[1]);
  NEXT;
}

// Pushes its data field onto the stack.
WORD(dolit, "(DOLIT)", 7, &header_docol) {
  PRINT_TRACE("(DOLIT)");
  *(--sp) = (cell) *(ip++);
  NEXT;
}

WORD(dostring, "(DOSTRING)", 10, &header_dolit) {
  PRINT_TRACE("(DOSTRING)");
  str1 = ((char*) ip);
  c1 = (cell) *str1;
  sp -= 2;
  sp[1] = (cell) (str1 + 1);
  sp[0] = c1;

  str1 += c1 + 1 + (sizeof(cell) - 1);
  str1 = (char*) (((cell) str1) & ~(sizeof(cell) - 1));
  ip = (code***) str1;

  NEXT;
}

// CREATE compiles 0 and then the user's code into the data space.
// It uses (dodoes) as the doer word, not docol! That will push the address of
// the user's data space area, as intended (cfa + 2 cells) and then check that
// 0 at cfa + 1 cell. If it's 0, do nothing. Otherwise, jump to that point.
WORD(dodoes, "(DODOES)", 8, &header_dostring) {
  PRINT_TRACE("(DODOES)");
  *(--sp) = (cell) &(cfa[2]);
  c1 = (cell) cfa[1];

  // Similar to docol, push onto the return stack and jump.
  if (c1 != 0) {
    *(--rsp) = (cell) ip;
    ip = (code***) c1;
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

void to_number_(void) {
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
    sp[3] *= tempSize;
    sp[3] += c1;
    sp[0]--;
    str1++;
  }
  sp[1] = (cell) str1;
  if (ch1) sp[3] = -sp[3];
}

// Expects c-addr u on top of the stack.
// Returns 0 0 on not found, xt 1 for immediate, or xt -1 for not immediate.
void find_(void) {
  tempHeader = dictionary;
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
  sp[1] = 0;
  sp[0] = 0;
}

WORD(parse, "PARSE", 5, &header_dodoes) {
  PRINT_TRACE("PARSE");
  parse_();
  NEXT;
}

WORD(parse_name, "PARSE-NAME", 10, &header_parse) {
  PRINT_TRACE("PARSE-NAME");
  parse_name_();
  NEXT;
}

WORD(to_number, ">NUMBER", 7, &header_parse_name) {
  PRINT_TRACE(">NUMBER");
  to_number_();
  NEXT;
}

// Parses a name, and constructs a header for it.
// When finished, HERE is the data space properly, ready for compilation.
WORD(create, "CREATE", 6, &header_to_number) {
  PRINT_TRACE("CREATE");
  parse_name_(); // sp[0] = length, sp[1] = string
  dsp.chars = (char*) ((((cell)dsp.chars) + sizeof(cell) - 1) & ~(sizeof(cell) - 1));
  tempHeader = (header*) dsp.chars;
  dsp.chars += sizeof(header);
  tempHeader->link = dictionary;
  dictionary = tempHeader;

  tempHeader->metadata = sp[0];
  tempHeader->name = (char*) malloc(sp[0] * sizeof(char));
  strncpy(tempHeader->name, (char*) sp[1], sp[0]);
  sp += 2;
  tempHeader->code_field = &code_dodoes;

  // Add the extra cell for dodoes; this is the DOES> address, or 0 for none.
  *(dsp.cells++) = 0;
  NEXT;
}

WORD(find, "(FIND)", 6, &header_create) {
  PRINT_TRACE("(FIND)");
  find_();
  NEXT;
}

WORD(depth, "DEPTH", 5, &header_find) {
  PRINT_TRACE("DEPTH");
  c1 = (cell) (((char*) spTop) - ((char*) sp)) / sizeof(cell);
  *(--sp) = c1;
  NEXT;
}

WORD(sp_fetch, "SP@", 3, &header_depth) {
  PRINT_TRACE("SP@");
  c1 = (cell) sp;
  *(--sp) = c1;
  NEXT;
}

WORD(sp_store, "SP!", 3, &header_sp_fetch) {
  PRINT_TRACE("SP!");
  c1 = sp[0];
  sp = (cell*) c1;
  NEXT;
}

WORD(rp_fetch, "RP@", 3, &header_sp_store) {
  PRINT_TRACE("RP@");
  *(--sp) = (cell) rsp;
  NEXT;
}

WORD(rp_store, "RP!", 3, &header_rp_fetch) {
  PRINT_TRACE("RP!");
  rsp = (cell*) *(sp++);
  NEXT;
}

WORD(dot_s, ".S", 2, &header_rp_store) {
  PRINT_TRACE(".S");
  printf("[%" PRIdPTR "] ", (cell) (((char*) spTop) - ((char*) sp)) / sizeof(cell));
  for (c1 = (cell) (&spTop[-1]); c1 >= (cell) sp; c1 -= sizeof(cell*)) {
    printf("%" PRIdPTR " ", *((cell*) c1));
  }
  printf("\n");
  NEXT;
}

// File access
// This is a hack included to support the assemblers and such.
// It writes a block of bytes to a binary file.
WORD(dump_file, "(DUMP-FILE)", 11, &header_dot_s) {
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

      to_number_();
      if (sp[0] == 0) { // Successful parse, handle the number.
        if (state == COMPILING) {
          *(dsp.cells++) = (cell) &(header_dolit.code_field);
          *(dsp.cells++) = sp[3]; // Compile low word as the literal.
          sp += 4; // And clear the stack.
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
        ip = &quitTopPtr;
        cfa = (code**) sp[1];
        sp += 2;
        //NEXT1;
        QUIT_JUMP_IN;
        __builtin_unreachable();
      } else { // Compiling mode
        *(dsp.cells++) = sp[1];
        sp += 2;
      }
    }
  }
  // Should never be reachable.
}

WORD(quit, "QUIT", 4, &header_dump_file) {
  PRINT_TRACE("QUIT");
  inputIndex = 0;
  quit_();
  NEXT;
}

WORD(bye, "BYE", 3, &header_quit) {
  PRINT_TRACE("BYE");
  exit(0);
}

WORD(colon, ":", 1, &header_bye) {
  PRINT_TRACE(":");
  tempHeader = (header*) dsp.chars;
  dsp.chars += sizeof(header);
  tempHeader->link = dictionary;
  dictionary = tempHeader;
  parse_name_(); // ( c-addr u )
  if (sp[0] == 0) {
    fprintf(stderr, "*** Colon definition with no name\n");
    code_quit();
    // Never returns
  }

  tempHeader->name = (char*) malloc(sp[0]);
  strncpy(tempHeader->name, (char*) sp[1], sp[0]);
  tempHeader->metadata = sp[0] | HIDDEN;
  sp += 2;
  tempHeader->code_field = &code_docol;

  state = COMPILING;
  NEXT;
}

WORD(exit, "EXIT", 4, &header_colon) {
  PRINT_TRACE("EXIT");
  // Pop the return stack and NEXT into it.
  ip = (code***) *(rsp++);
  NEXT;
}

WORD(see, "SEE", 3, &header_exit) {
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

WORD(semicolon, ";", 1 | IMMEDIATE, &header_see) {
  PRINT_TRACE(";");
  dictionary->metadata &= (~HIDDEN); // Clear the hidden bit.
  // Compile an EXIT
  *(dsp.cells++) = (cell) &(header_exit.code_field);
  // And stop compiling.
  state = INTERPRETING;
  NEXT;
}

// NB: If anything gets added after SEMICOLON, change the dictionary below.

int main(int argc, char **argv) {
  dictionary = &header_semicolon;
  base = 10;
  inputIndex = 0;
  SRC.type = SRC.parseLength = SRC.inputPtr = 0;

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
  }

  // Turn the external Forth libraries into input sources.
  external_source *ext;
  EXTERNAL_FILES(EXTERNAL_INPUT_SOURCES)

  quit_();
}

