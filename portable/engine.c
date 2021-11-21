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

#include <dlfcn.h>

#include <editline.h>

// Verbose output - every primitive, colon word, and call is announced.
#define VERBOSE 0

// Keep TOS in a register. This is a modest for substantial performance
// improvement, roughly 5% by itself on x86_64.
#define TOS_REG 1


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
// The linker includes them as symbols like _binary_core_exception_fs.
// The "extern char" references here are not pointers, they're the actual
// character at position 0. Therefore we take &_binary_core_exception_fs and use
// that as the input pointer.
// In order to distinguish these pointers from the FILE* inputs used by
// command-line arguments or INCLUDE and friends, I add EXTERN_SYMBOL_FLAG to
// them, and use EXTERN_SYMBOL_MASK to strip it off.

#define EXTERNAL_SYMBOL_FLAG (1)
#define EXTERNAL_SYMBOL_MASK (~1)

#define EXTERNAL_START(name) _binary_core_ ## name ## _fs_start
#define EXTERNAL_END(name) _binary_core_ ## name ## _fs_end
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

// Flags for the state variable.
#define COMPILING (1)
#define INTERPRETING (0)

// Sizes in address units.
typedef intptr_t cell;
typedef uintptr_t ucell;
typedef unsigned char bool;
#define true (-1)
#define false (0)
#define CHAR_SIZE 1
#define CELL_SIZE sizeof(cell)

// It helps to keep tracking of code addresses vs. code field addresses to have
// this as a distinctive type.
// code* is the address we should goto to run this code.
// code** is an array of code, eg. a thread.
typedef void code;

// Remember to update WORDS in the tools word set if the format of the
// dictionary or individual headers within it changes.
// NB: For primitive headers code_field points to what we should execute.
// For nonprimitive headers code_field points to prim_docol.
typedef struct header_ {
  struct header_ *link;
  cell metadata; // See below.
  char *name; // Note that this is a fixed-size pointer, not inlined.
  code *code_field;
} header;


// Globals that drive the Forth engine: SP, RSP, IP, CFA.
// These should generally be pinned to registers.
// Stacks are full-descending, and can therefore be used like arrays.

#define DATA_STACK_SIZE 16384
cell _stack_data[DATA_STACK_SIZE] __attribute__ ((aligned (1024)));

#define RETURN_STACK_SIZE 1024
cell _stack_return[RETURN_STACK_SIZE] __attribute__ ((aligned (1024)));

cell *spTop = &(_stack_data[DATA_STACK_SIZE]);
cell *rspTop = &(_stack_return[RETURN_STACK_SIZE]);
cell *rsp; // TODO Maybe find a register for this one?

#if defined(__x86_64__)
register cell *sp asm ("rbx");
register code **ip asm ("rbp");
#if TOS_REG
register cell tos asm ("r14");
#endif
#else
#error Not a known machine!
#endif

// Only used for "heavy" calls - EXECUTE, etc.
// Most calls are direct threaded and don't need this pointer,
// or they use the (call) primitive rather than (docol).
code **cfa;
code *ca;

bool firstQuit = 1;
void *quitTop = NULL;

union {
  cell* cells;
  char* chars;
} dsp;

#define ALIGN_DSP(type) (dsp.chars = (char*) ((((ucell) dsp.chars) + sizeof(type) - 1) & ~(sizeof(type) - 1)))


#define INPUT_SOURCE_COUNT (32)

// A few more core globals.
cell state;
cell base;
header *searchOrder[16];
cell searchIndex; // Index of the first word list to search.
header **compilationWordlist;
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


// And some miscellaneous helper globals used in a few functions.
cell c1, c2, c3;
char tempBuf[256];


// These definitions and variables are for the primitive system, for the queue
// of operations and the map of implemented superinstructions.
typedef uint32_t super_key_t;


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
int primitive_count = 0;
header *last_header;



#define LEN_MASK        (0xff)
#define LEN_HIDDEN_MASK (0x1ff)
#define HIDDEN          (0x100)
#define IMMEDIATE       (0x200)
#define TOP_BIT         (1 << (8 * sizeof(void*) - 1))

void print(char *str, cell len) {
  char* s = (char*) malloc(len + 1);
  strncpy(s, str, len);
  s[len] = '\0';
  printf("%s", s);
  free(s);
}

typedef struct {
  cell length;
  char* text;
} string;


// VM macros! These hide a lot of the implementation details from the generated
// code, such as where the IP and SP are stored, whether TOS is in the register,
// etc.

// NB: If NEXT changes, EXECUTE might need to change too (it uses NEXT1)
#define NEXT1 do { goto *ca; } while(0)
#define NEXT do { goto **ip++; } while(0)


// Called at the top of primitives to create a jump label. These jumps are
// prim_foo. Needs the identifier, not the Forth name.
#define LABEL(inst_name) prim_ ## inst_name: \
  asm volatile ("tag_" #inst_name ": .global tag_" #inst_name)

// Called at the top of primitives with the Forth name as a string.
// Usually does nothing, this can be used to print debug info or to log
// primitives for superinstruction profiling.
// Includes the ; if it does anything!
#if VERBOSE
#define NAME(inst_name_string) { \
  fprintf(stderr, "Primitive: %s\n", inst_name_string); \
  for (cell *p = &(spTop[-1]); p >= sp; p--) {\
    fprintf(stderr, "\t%ld\n", *p);\
  }\
}
#else
#define NAME(inst_name_string)
#endif

#define INC_ip_bytes(n) (ip = (code**) (((cell) ip) + ((cell) (n))))
#define INC_ip(n) (ip += n)
#define SET_ip(target) (ip = target)
#define ipTOS (ip[0])

#define INC_sp(n) (sp += n)
#define SET_sp(target) (sp = target)
// Accesses the stack at the given value.
#define spREF(index) (sp[index])

#if TOS_REG
#define spTOS (tos)
#define STORE_SP_TOS (sp[0] = tos)
#define FETCH_SP_TOS (tos = sp[0])
#else
#define spTOS (spREF(0))
#define STORE_SP_TOS ({})
#define FETCH_SP_TOS ({})
#endif

#define INC_rsp(n) (rsp += n)
#define SET_rsp(target) (rsp = target)
#define rspREF(index) (rsp[index])
#define rspTOS (rsp[0])


// Type conversions.
#define conv_sp_to_i(rhs) (rhs)
#define conv_sp_to_a(rhs) ((cell*) (rhs))
#define conv_sp_to_u(rhs) ((ucell) (rhs))
#define conv_sp_to_c(rhs) ((unsigned char) (rhs))
#define conv_sp_to_s(rhs) ((char*) (rhs))
#define conv_sp_to_F(rhs) ((FILE*) (rhs))
#define conv_sp_to_C(rhs) ((code**) (rhs))

#define conv_sp_from_i(rhs) (rhs)
#define conv_sp_from_a(rhs) ((cell) (rhs))
#define conv_sp_from_u(rhs) ((cell) (rhs))
#define conv_sp_from_c(rhs) ((cell) (rhs))
#define conv_sp_from_c(rhs) ((cell) (rhs))
#define conv_sp_from_s(rhs) ((cell) (rhs))
#define conv_sp_from_F(rhs) ((cell) (rhs))
#define conv_sp_from_C(rhs) ((cell) (rhs))

#define conv_rsp_to_i(rhs) (rhs)
#define conv_rsp_to_a(rhs) ((cell*) (rhs))
#define conv_rsp_to_C(rhs) ((code*) (rhs))
#define conv_rsp_from_i(rhs) (rhs)
#define conv_rsp_from_a(rhs) ((cell) (rhs))
#define conv_rsp_from_C(rhs) ((cell) (rhs))

#define conv_ip_to_i(rhs) ((cell) (rhs))
#define conv_ip_to_s(rhs) ((char*) (rhs))

code *ca_docol;
code *ca_dolit;
code *ca_dodoes;
code *ca_exit;
code *ca_branch;
code *ca_zbranch;
code *ca_call;

super_key_t key_dolit, key_call_forth;

cell refill_(void) {
  if (SRC.type == -1) { // EVALUATE
    // EVALUATE strings cannot be refilled. Pop the source and return false.
    inputIndex--;
    return false;
  } else if (SRC.type == 0) { // KEYBOARD
    char* s = readline("> ");
    SRC.parseLength = strlen(s);
    strncpy(SRC.parseBuffer, s, SRC.parseLength);
    SRC.inputPtr = 0;
    free(s);
    return true;
  } else if ( (SRC.type & EXTERNAL_SYMBOL_FLAG) != 0 ) {
    // External symbol, pseudofile.
    external_source *ext = (external_source*) (SRC.type & EXTERNAL_SYMBOL_MASK);
    if (ext->current >= ext->end) {
      inputIndex--;
      return false;
    }

    char* s = ext->current;
    while (s < ext->end && *s != '\n') {
      s++;
    }
    SRC.parseLength = s - ext->current;
    strncpy(SRC.parseBuffer, ext->current, SRC.parseLength);

    // DEBUG only
    //print(SRC.parseBuffer, SRC.parseLength);

    SRC.inputPtr = 0;

    ext->current = s < ext->end ? s + 1 : ext->end;
    return true;
  } else {
    // Real file.
    char *s = NULL;
    size_t size = 0;
    cell read = getline(&s, &size, (FILE*) SRC.type);

    if (read == -1) {
      // Dump the source and recurse.
      inputIndex--;
      return false;
    } else {
      // Knock off the trailing newline, if present.
      if (s[read - 1] == '\n') read--;
      strncpy(SRC.parseBuffer, s, read);
      free(s);
      SRC.parseLength = read;
      SRC.inputPtr = 0;
      return true;
    }
  }
}

void parse_(char delim, char **s, cell* len) {
  if ( SRC.inputPtr >= SRC.parseLength ) {
    *s = 0;
    *len = 0;
    return;
  }

  *s = SRC.parseBuffer + SRC.inputPtr;
  *len = 0;
  while ( SRC.inputPtr < SRC.parseLength && SRC.parseBuffer[SRC.inputPtr] != delim ) {
    SRC.inputPtr++;
    (*len)++;
  }
  if ( SRC.inputPtr < SRC.parseLength ) SRC.inputPtr++; // Skip over the delimiter.
}

string parse_name_() {
  // Skip any leading delimiters.
  string s;
  while ( SRC.inputPtr < SRC.parseLength && (SRC.parseBuffer[SRC.inputPtr] == ' ' || SRC.parseBuffer[SRC.inputPtr] == '\t') ) {
    SRC.inputPtr++;
  }
  s.length = 0;
  s.text = SRC.parseBuffer + SRC.inputPtr;
  while ( SRC.inputPtr < SRC.parseLength && SRC.parseBuffer[SRC.inputPtr] != ' ' ) {
    SRC.inputPtr++;
    s.length++;
  }
  if (SRC.inputPtr < SRC.parseLength) SRC.inputPtr++; // Jump over a trailing delimiter.
  return s;
}

// The basic >NUMBER - unsigned values only, no magic $ff or whatever.
// sp[0] is the length, sp[1] the pointer, sp[2] the high word, sp[3] the low.
// ( lo hi c-addr u -- lo hi c-addr u )
void to_number_(void) {
  // Copying the numbers into the buffers.
  unsigned char numBuf[2 * sizeof(cell)];

  for (cell i = 0; i < (cell) sizeof(cell); i++) {
    numBuf[i] = (unsigned char) ((((ucell) spREF(3)) >> (i*8)) & 0xff);
    numBuf[sizeof(cell) + i] = (unsigned char) ((((ucell) spREF(2)) >> (i*8)) & 0xff);
  }

  while (spTOS > 0) {
    cell c1 = (cell) *((char*) spREF(1));
    if ('0' <= c1 && c1 <= '9') {
      c1 -= '0';
    } else if ('A' <= c1 && c1 <= 'Z') {
      c1 = c1 - 'A' + 10;
    } else if ('a' <= c1 && c1 <= 'z') {
      c1 = c1 - 'a' + 10;
    } else {
      break;
    }

    if (c1 >= base) break;

    // Otherwise, a valid character, so multiply it in.
    for (cell c3 = 0; c3 < 2 * (cell) sizeof(cell) ; c3++) {
      cell c2 = ((ucell) numBuf[c3]) * base + c1;
      numBuf[c3] = (unsigned char) (c2 & 0xff);
      c1 = (c2 >> 8) & 0xff;
    }

    spTOS--;
    spREF(1)++;
  }

  spREF(2) = 0;
  spREF(3) = 0;
  for (cell c1 = 0; c1 < (cell) sizeof(cell); c1++) {
    spREF(3) |= (cell) (((ucell) numBuf[c1]) << (c1*8));
    spREF(2) |= (cell) (((ucell) numBuf[sizeof(cell) + c1]) << (c1*8));
  }
}

// This is the full number parser, for use by quit_.
void parse_number_(void) {
  // sp[0] is the length, sp[1] the pointer, sp[2] the high word, sp[3] the low.
  // ( lo hi c-addr u -- lo hi c-addr u )
  char first = ((char*) spREF(1))[0];
  cell oldBase = base;
  if (first == '$' || first == '#' || first == '%') {

    base = first == '$' ? 16 : first == '#' ? 10 : 2;
    spREF(1)++;
    spTOS--;
  } else if (first == '\'') {
    spTOS -= 3;
    spREF(3) = (cell) ((char*) spREF(1))[1];
    spREF(1) += 3;
    return;
  }

  bool negated = false;
  if (*((char*) spREF(1)) == '-') {
    spTOS--;
    spREF(1)++;
    negated = true;
  }

  // Now parse the number itself.
  to_number_();

  // And negate if needed.
  if (negated) {
    spREF(3) = ~spREF(3);
    spREF(2) = ~spREF(2);
    spREF(3)++;
    if (spREF(3) == 0) spREF(2)++;
  }
  base = oldBase;
}

header* find_(const char *s, const cell len) {
  for (cell i = searchIndex; i >= 0; i--) {
    header *h = searchOrder[i];
    while (h != NULL) {
      if ((h->metadata & LEN_HIDDEN_MASK) == len) {
        if (strncasecmp(h->name, s, len) == 0) {
          return h;
        }
      }
      h = h->link;
    }
  }
  return NULL;
}



// Exits with 40 if not found.
super_key_t lookup_primitive(code* target) {
  for (cell i = 0; i < primitive_count; i++) {
    if (primitives[i].implementation == target) {
      return primitives[i].key;
    }
  }
  exit(40);
}


void drain_queue_(void) {
  // TODO Superinstructions implementations
  *(dsp.cells++) = (cell) queue->target;
  if (queue->hasValue) *(dsp.cells++) = queue->value;
  queue = queue->next;
  if (queue == NULL) queueTail = NULL;
  queue_length--;
}

void bump_queue_tail_(void) {
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


// This is the heart of the superinstruction system.
// It should build up a queue of primitives requested, until it fills up, then
// convert into the most efficient possible superinstructions.
//
// h->code_field points to the code field, which is either a simple pointer to
// the primitive code, or the code thread (the docol at the start).
// compile_ gets passed the h->code_field.
void compile_(code** cfa) {
  // If the queue is full, drain it first.
  if (queue_length >= 4) {
    drain_queue_();
  }

  bump_queue_tail_();
  // queueTail now points at a free queue slot.

  // Check the doer-word. If it's a (DOCOL) word, compile a call_forth.
  if (cfa[0] == ca_docol) {
    queueTail->target = ca_call;
    queueTail->hasValue = 1;
    // cfa points to the thread, where docol is the first thread.
    // cfa[0] is docol; cfa[1] is the first real word.
    // &cfa[1], then, is the pointer we actually want.
    queueTail->value = (cell) &cfa[1];
    queueTail->key = key_call_forth;
  } else if (cfa[0] == ca_dodoes) {
    // (DODOES) pushes the data space pointer (&cfa[2]) onto the stack,
    // then checks cfa[1]. If it's 0, do nothing. If not, it's another CFA, jump
    // to it.
    // Here we inline that into a literal for the data space pointer,
    // followed optionally by a call_ to the DOES> code.
    queueTail->target = ca_dolit;
    queueTail->hasValue = 1;
    queueTail->value = (cell) &cfa[2];
    queueTail->key = key_dolit;

    if (cfa[1] != 0) {
      if (queue_length == 4) drain_queue_();
      bump_queue_tail_();
      queueTail->target = ca_call;
      queueTail->hasValue = 1;
      queueTail->value = (cell) cfa[1];
      queueTail->key = key_call_forth;
    }
  } else {
    // For a primitive, the type of cfa is a lie. It's actually a code*
    // directly.
    super_key_t key = lookup_primitive(cfa[0]);
    queueTail->target = cfa[0];
    queueTail->hasValue = 0;
    queueTail->key = key;
  }
}

void compile_lit_(cell value) {
  // If the queue is full, drain it first.
  if (queue_length >= 4) {
    drain_queue_();
  }

  bump_queue_tail_();
  queueTail->target = ca_dolit;
  queueTail->hasValue = 1;
  queueTail->value = value;
  queueTail->key = key_dolit;
}


// File Access
// Access modes are defined as in the following constants, so they can be
// manipulated in Forth safely.
#define FA_READ (1)
#define FA_WRITE (2)
#define FA_BIN (4)
#define FA_TRUNC (8)

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


// Given a code field address (eg. &h->code_field) this searches through the
// word lists until it finds the corresponding word, and returns it.
// This *moves* cfa so it points at the next word, not at my data field.
header* find_by_cfa_(code ***cfa) {
  for (cell i = searchIndex; i >= 0; i--) {
    header *h = searchOrder[i];
    while (h != NULL) {
      if (h->code_field == **cfa) {
        return h;
      } else if (h->code_field == ca_docol &&
          (((void*) &(h->code_field)) + sizeof(cell)) == (*cfa)[1]) {
        (*cfa)++;
        return h;
      }
      h = h->link;
    }
  }
  return NULL;
}

void print_name_(header *h) {
  printf("%.*s \n", (int) h->metadata & LEN_MASK, h->name);
}

void see_singular_(char* label, header *word) {
  printf("%s<%.*s>\n", label, (int) word->metadata & LEN_MASK, word->name);
}

void see_docol_(header *word) {
  printf(": %.*s   \n", (int) word->metadata & LEN_MASK, word->name);
  code **thread = ((code**) word) + 4;
  while (true) {
    if (*thread == ca_dolit) {
      printf("%" PRIdPTR "__$%" PRIxPTR " \n", (cell) thread[1], (ucell) thread[1]);
      thread += 2;
    } else if (*thread == ca_zbranch || *thread == ca_branch) {
      printf("%s: %" PRIdPTR " bytes / %" PRIdPTR " cells\n",
          *thread == ca_zbranch ? "0branch" : "branch",
          (cell) thread[1], ((cell) thread[1]) / sizeof(cell));
      thread += 2;
    } else {
      // find_by_cfa moves the thread pointer if there's an extra field there.
      header* word = find_by_cfa_(&thread);
      print_name_(word);
      thread++;
      if (word->code_field == ca_exit) break;
    }
  }
  putchar('\n');
}

void see_(void) {
  string s = parse_name_();
  header *h = find_(s.text, s.length);

  if (h == NULL) {
    fprintf(stderr, "*** Unknown SEE word: %.*s\n", (int) s.length, s.text);
    return;
  }

  if (h->code_field == ca_docol) {
    see_docol_(h);
  } else if (h->code_field == ca_dodoes) {
    see_singular_("var", h);
  } else {
    see_singular_("primitive", h);
  }
}

void debug_words_(void) {
  printf("Words:\n");
  for (header *h = *compilationWordlist; h != 0; h = h->link) {
    printf("%ld\t'%.*s'\n", h->metadata, (int) (h->metadata & LEN_MASK), h->name);
  }
}

header* quitHeader;
volatile string quitString;
bool initDone = false;


void reset_interpreter_(void) {
  sp = spTop;
  rsp = rspTop;
  state = INTERPRETING;

  // If this is not the first QUIT, reset to keyboard input.
  if (!firstQuit) {
    inputIndex = 0;
  }
  firstQuit = 0;
}

// Runs a single input source until it runs out, then returns.
// Expects that source to have already been refill'd once, so the buffer is
// ready.
void interpret_(void) {
  // TODO Remove these? I think we can shrink or avoid this.
  cell blanks[256];
  (void)(blanks); // Touch it so it's not "unused".

  if (false) {
#include "./primitives.in"
  }

  // One-time init, partly generated and partly here.
  if (!initDone) {
#include "./init.in"

    *compilationWordlist = last_header;
    ca_docol = &&prim_docol;
    ca_dolit = &&prim_dolit;
    ca_dodoes = &&prim_dodoes;
    ca_branch = &&prim_branch;
    ca_zbranch = &&prim_zbranch;
    ca_exit = &&prim_exit;
    ca_call = &&prim_call_forth;
    initDone = true;
  }


quit_loop:
  while (true) {
    while (true) {
      quitString = parse_name_();
      if (quitString.length != 0) {
        break;
      } else {
        if (SRC.type == 0) printf("  ok\n");
        if (!refill_()) return;
      }
    }

    quitHeader = find_(quitString.text, quitString.length);

    if (quitHeader == NULL) { // Failed to parse. Try to parse as a number.
      STORE_SP_TOS;
      INC_sp(-4);
      spTOS = quitString.length;
      spREF(1) = (cell) quitString.text; // Bring back the string and length.
      spREF(2) = 0;
      spREF(3) = 0;

      parse_number_();
      if (spTOS == 0) { // Successful parse, handle the number.
        if (state == COMPILING) {
          compile_lit_(sp[3]);
          INC_sp(4); // Number now on top.
          FETCH_SP_TOS;
        } else {
          // Clear my mess from the stack, but leave the new number atop it.
          spTOS = sp[3];
          INC_sp(3);
        }
      } else { // Failed parse of a number. Unrecognized word.
        strncpy(tempBuf, quitString.text, quitString.length);
        tempBuf[quitString.length] = '\0';
        fprintf(stderr, "*** Unrecognized word: %s\n", tempBuf);
      }
    } else {
      // Successful parse: quitHeader holds the word.
      if ((quitHeader->metadata & IMMEDIATE) == 0 && state == COMPILING) {
        compile_(&quitHeader->code_field);
      } else {
        // Jump into the interpretive code.
        quitTop = &&quit_loop;
        SET_ip(&quitTop);
        // cfa is a code**, ca is code*, and our jump target.
        cfa = &quitHeader->code_field;
        ca = cfa[0];
        goto *ca;
      }
    }
  }
}


void quit_(void) {
  reset_interpreter_(); // Clears stacks, resets to keyboard (except first)
  while (true) {
    // Refill the input buffer the first time.
    refill_();
    // And start trying to parse things.
    interpret_();
  }
}

int main(int argc, char **argv) {
  compilationWordlist = searchOrder;
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

    SRC.inputPtr = SRC.parseLength = 0;
    SRC.parseBuffer = parseBuffers[inputIndex];
  }

  // Turn the external Forth libraries into input sources.
  external_source *ext;
  EXTERNAL_FILES(EXTERNAL_INPUT_SOURCES)

  quit_();
}

