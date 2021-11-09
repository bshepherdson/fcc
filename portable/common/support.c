#define _GNU_SOURCE
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>
//#include <limits.h>
#include <unistd.h>
//#include <errno.h>
#include <termios.h>
#include <sys/stat.h>
//#include <sys/time.h>
#include <editline.h>

//#include <md.h>

#define EXTERNAL_SYMBOL_FLAG (1)
#define EXTERNAL_SYMBOL_MASK (~1)

typedef struct {
  char *current;
  char *end;
} external_source;

typedef intptr_t cell;
typedef uintptr_t ucell;
typedef unsigned char bool;
#define true (-1)
#define false (0)
#define CHAR_SIZE 1
#define CELL_SIZE sizeof(cell)

typedef void code(void);

typedef struct header_ {
  struct header_ *link;
  cell metadata; // See below.
  char *name;
  code *code_field;
} header;

// Globals that drive the Forth engine: RSP, CFA.
// SP and IP are pinned to registers.
// Stacks are full-descending, and can therefore be used like arrays.

#define DATA_STACK_SIZE 16384
cell _stack_data[DATA_STACK_SIZE];
cell *spTop = &(_stack_data[DATA_STACK_SIZE]);

#define RETURN_STACK_SIZE 1024
cell _stack_return[RETURN_STACK_SIZE];
cell *rspTop = &(_stack_return[RETURN_STACK_SIZE]);
cell *rsp;

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

cell searchArray[16];
cell searchIndex;
cell compilationWordlist;
cell forthWordlist;



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

// Next key to use:
int primitive_count = 114;

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
int nextSuperinstruction = 0;

super_key_t key1;

void print(char *str, cell len) {
  str1 = (char*) malloc(len + 1);
  strncpy(str1, str, len);
  str1[len] = '\0';
  printf("%s", str1);
  free(str1);
}


//// refill_evaluate_pop is defined in assembly.
//cell refill_evaluate_pop(void);
//
//// NB: Refilling from a completed EVALUATE is kinda magic since it needs to jump
//// into the caller directly.
//// I think jumping out of two C calls like that is busted, though. Might need
//// to set a flag or something?
//cell refill_(void) {
//  if (SRC.type == -1) { // EVALUATE
//    // EVALUATE strings cannot be refilled. Pop the source.
//    inputIndex--;
//    return refill_evaluate_pop();
//    // And do an EXIT to return to executing whoever called EVALUATE.
//    //ip = (code**) *(rsp++);
//    //NEXT;
//    //return 0;
//  } else if ( SRC.type == 0) { // KEYBOARD
//    str1 = readline("> ");
//    SRC.parseLength = strlen(str1);
//    strncpy(SRC.parseBuffer, str1, SRC.parseLength);
//    SRC.inputPtr = 0;
//    free(str1);
//    return -1;
//  } else if ( (SRC.type & EXTERNAL_SYMBOL_FLAG) != 0 ) {
//    // External symbol, pseudofile.
//    external_source *ext = (external_source*) (SRC.type & EXTERNAL_SYMBOL_MASK);
//    if (ext->current >= ext->end) {
//      inputIndex--;
//      return 0;
//    }
//
//    str1 = ext->current;
//    while (str1 < ext->end && *str1 != '\n') {
//      str1++;
//    }
//    SRC.parseLength = str1 - ext->current;
//    strncpy(SRC.parseBuffer, ext->current, SRC.parseLength);
//    SRC.inputPtr = 0;
//
//    ext->current = str1 < ext->end ? str1 + 1 : ext->end;
//    return -1;
//  } else {
//    // Real file.
//    str1 = NULL;
//    tempSize = 0;
//    c1 = getline(&str1, &tempSize, (FILE*) SRC.type);
//
//    if (c1 == -1) {
//      // Dump the source and recurse.
//      inputIndex--;
//      return 0;
//    } else {
//      // Knock off the trailing newline, if present.
//      if (str1[c1 - 1] == '\n') c1--;
//      strncpy(SRC.parseBuffer, str1, c1);
//      free(str1);
//      SRC.parseLength = c1;
//      SRC.inputPtr = 0;
//      return -1;
//    }
//  }
//}

// Input: c1 is the length, str1 the string.
// Output: c1 is TOS (the +/-1 flag), c2 is the XT.
// Both outputs are 0 if it's not found.
//void find_(void) {
//  c2 = searchIndex;
//  while (
//}

// Output: c1 is the key pressed.
void key_(void) {
  // Grab the current terminal settings.
  tcgetattr(STDIN_FILENO, &old_tio);
  // Copy to preserve the original.
  new_tio = old_tio;
  // Disable the canonical mode (buffered I/O) flag and local echo.
  new_tio.c_lflag &= (~ICANON & ~ECHO);
  // And write it back.
  tcsetattr(STDIN_FILENO, TCSANOW, &new_tio);

  // Read a single character.
  c1 = getchar();

  // And put things back.
  tcsetattr(STDIN_FILENO, TCSANOW, &old_tio);
}

// Input: ch1 is the separator.
// Output: Length in c1, string in str1.
void parse_(void) {
  if ( SRC.inputPtr >= SRC.parseLength ) {
    c1 = 0;
    str1 = (char*) 0;
  } else {
    str1 = SRC.parseBuffer + SRC.inputPtr;
    c1 = 0;
    while ( SRC.inputPtr < SRC.parseLength && SRC.parseBuffer[SRC.inputPtr] != ch1 ) {
      SRC.inputPtr++;
      c1++;
    }
    if ( SRC.inputPtr < SRC.parseLength ) SRC.inputPtr++; // Skip over the delimiter.
  }
}

// Output: c1 holds the length, str1 the string.
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
}

