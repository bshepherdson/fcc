#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <inttypes.h>

#include <readline/readline.h>
//#include <readline/history.h>

#include <md.h>

// Sizes in address units.
typedef intptr_t cell;
typedef uintptr_t ucell;
typedef unsigned char bool;
#define true (-1)
#define false (0)

// Globals that drive the Forth engine: SP, RSP, IP.
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

cell *ip;

char *pc;
char *pcTop;


typedef struct {
  cell parseLength;
  cell inputPtr; // Indexes into parseBuffer.
  cell type;     // 0 = KEYBOARD, -1 = EVALUATE, 0> fileid
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
code* tempOp;

// Implementations of the VM bytecodes.
// These functions MUST NOT USE locals, since that will use the stack.
// They should probably be one-liners, or nearly so, in C.

#ifdef DEBUG
#define PRINT_DEBUG(...) printf(__VA_ARGS__)
#else
#define PRINT_DEBUG(...)
#endif

code *ops[256];

cell globals[16];

// During these operations, pc points at the next op.

// Core
void op_nop(void) {
}
void op_lit(void) {
  *(--sp) = (cell) *(pc++);
}
void op_lit_bump(void) {
  sp[0] = (sp[0] << 8) | (((cell) *(pc++)) & 0xff);
}

void op_pc(void) {
  *(--sp) = (cell) pc;
}
void op_jmp(void) {
  pc = (char*) *(sp++);
}
void op_jmp_link(void) {
  c1 = sp[0];
  sp[0] = (cell) pc;
  pc = (char*) c1;
}
void op_jmp_zero(void) {
  // ( condition newPC -- )
  if (sp[1] == 0) {
    pc = (char*) sp[0];
  }
  sp += 2;
}

void op_ip(void) {
  *(--sp) = (cell) ip;
}
void op_ip_set(void) {
  ip = (cell*) *(sp++);
}
void op_ip_read(void) {
  *(--sp) = *ip;
  ip += sizeof(cell);
}

// Arithmetic
void op_plus(void) {
  sp[1] = sp[0] + sp[1];
  sp++;
}
void op_minus(void) {
  sp[1] = sp[1] - sp[0];
  sp++;
}
void op_times(void) {
  sp[1] = sp[0] * sp[1];
  sp++;
}
void op_div(void) {
  sp[1] = sp[1] / sp[0];
  sp++;
}
void op_mod(void) {
  sp[1] = sp[1] % sp[0];
  sp++;
}


// Bitwise
void op_and(void) {
  sp[1] = sp[1] & sp[0];
  sp++;
}
void op_or(void) {
  sp[1] = sp[1] | sp[0];
  sp++;
}
void op_xor(void) {
  sp[1] = sp[1] ^ sp[0];
  sp++;
}
void op_lshift(void) {
  sp[1] = ((ucell) sp[1]) << sp[0];
  sp++;
}
void op_rshift(void) {
  sp[1] = ((ucell) sp[1]) >> sp[0];
  sp++;
}


// Comparison
void op_lt(void) {
  sp[1] = (sp[1] < sp[0]) ? true : false;
  sp++;
}
void op_ult(void) {
  sp[1] = ((ucell) sp[1]) < ((ucell) sp[0]) ? true : false;
  sp++;
}
void op_eq(void) {
  sp[1] = sp[0] == sp[1] ? true : false;
  sp++;
}

// Stack manipulation
void op_dup(void) {
  sp--;
  sp[0] = sp[1];
}
void op_swap(void) {
  c1 = sp[0];
  sp[0] = sp[1];
  sp[1] = c1;
}
void op_drop(void) {
  sp++;
}

void op_to_r(void) {
  *(--rsp) = *(sp++);
}
void op_from_r(void) {
  *(--sp) = *(rsp++);
}
void op_depth(void) {
  c1 = (cell) (((char*) spTop) - ((char*) sp)) / sizeof(cell);
  *(--sp) = c1;
}

// Memory access
void op_fetch(void) {
  sp[0] = *((cell*) sp[0]);
}
void op_store(void) {
  *((cell*) sp[0]) = sp[1];
  sp += 2;
}
void op_cfetch(void) {
  sp[0] = (cell) *((char*) sp[0]);
}
void op_cstore(void) {
  *((char*) sp[0]) = (char) sp[1];
  sp += 2;
}

// Allocates new regions. Might use malloc, or just an advancing pointer.
// The library calls this to acquire somewhere to put HERE.
// ( size-in-address-units -- a-addr )
void op_allocate(void) {
  sp[0] = (cell) malloc(sp[0]);
}

void op_size_cell(void) {
  *(--sp) = (cell) sizeof(cell);
}
void op_size_char(void) {
  *(--sp)  = (cell) sizeof(char);
};

void op_var_read(void) {
  *(--sp) = globals[*(pc++)];
}
void op_var_write(void) {
  globals[*(pc++)] = *(sp++);
}
void op_var_addr(void) {
  *(--sp) = &(globals[*(pc++)]);
}


// Input
cell refill_(void) {
  if (SRC.type == -1) { // EVALUATE
    // EVALUATE strings cannot be refilled. Pop the source.
    inputIndex--;
    return false;
  } else if ( SRC.type == 0) { // KEYBOARD
    str1 = readline("> ");
    SRC.parseLength = strlen(str1);
    strncpy(SRC.parseBuffer, str1, SRC.parseLength);
    SRC.inputPtr = 0;
    free(str1);
    return true;
  } else {
    str1 = NULL;
    tempSize = 0;
    c1 = getline(&str1, &tempSize, (FILE*) SRC.type);

    if (c1 == -1) {
      // Dump the source and recurse.
      inputIndex--;
      return false;
    } else {
      // Knock off the trailing newline, if present.
      if (str1[c1 - 1] == '\n') c1--;
      strncpy(SRC.parseBuffer, str1, c1);
      free(str1);
      SRC.parseLength = c1;
      SRC.inputPtr = 0;
      return true;
    }
  }
}

void op_refill(void) {
  *(--sp) = refill_();
}

// >IN returns the *index* into the parse buffer.
void op_in(void) {
  *(--sp) = (cell) (&SRC.inputPtr);
}
// parse_buffer returns the real address of the parse buffer.
void op_parse_buffer(void) {
  *(--sp) = (cell) SRC.parseBuffer;
}
// parse_length returns the length of the parsed text in the buffer.
void op_parse_length(void) {
  *(--sp) = (cell) SRC.parseLength;
}

void op_emit(void) {
  fputc(*(sp++), stdout);
}


// Part of QUIT; pops all input sources and reads from the keyboard.
void op_clear_input(void) {
  inputIndex = 0;
}

void op_bye(void) {
  exit(0);
}



void vm_run(void) {
  while (true) {
    // Read from PC, bump it, and execute.
    ch1 = *pc;
    code *op = ops[ch1];
    if (op == 0) {
      fprintf(stderr, "Unknown VM bytecode %02hhx at \n", ch1, pcTop);
      exit(1);
    }
    *(op)();
  }
}


void init_ops_array(void) {
  // Core
  ops[0x00] = &op_nop;
  ops[0x01] = &op_lit;
  ops[0x02] = &op_lit_bump;
  ops[0x04] = &op_pc;
  ops[0x05] = &op_jmp;
  ops[0x06] = &op_jmp_link;
  ops[0x07] = &op_jump_zero;
  ops[0x08] = &op_ip;
  ops[0x09] = &op_ip_read;
  ops[0x0a] = &op_ip_set;
  ops[0x0f] = &op_bye;

  // Arithmetic
  ops[0x10] = &op_plus;
  ops[0x11] = &op_minus;
  ops[0x12] = &op_times;
  ops[0x13] = &op_div;
  ops[0x14] = &op_mod;
  // Bitwise
  ops[0x15] = &op_and;
  ops[0x16] = &op_or;
  ops[0x17] = &op_xor;
  ops[0x18] = &op_lshift;
  ops[0x19] = &op_rshift;
  // Comparison
  ops[0x1a] = &op_lt;
  ops[0x1b] = &op_ult;
  ops[0x1c] = &op_eq;

  // Stack
  ops[0x20] = &op_dup;
  ops[0x21] = &op_swap;
  ops[0x22] = &op_drop;
  ops[0x23] = &op_to_r;
  ops[0x24] = &op_from_r;
  ops[0x25] = &op_depth;

  // Memory
  ops[0x28] = &op_fetch;
  ops[0x29] = &op_store;
  ops[0x2a] = &op_cfetch;
  ops[0x2b] = &op_cstore;
  ops[0x2c] = &op_allocate;
  // System Specs
  ops[0x30] = &op_size_cell;
  ops[0x31] = &op_size_char;
  // Conveniences
  ops[0x38] = &op_var_read;
  ops[0x39] = &op_var_write;
  ops[0x3a] = &op_var_addr;
  // Input
  ops[0x40] = &op_refill;
  ops[0x41] = &op_clear_input;
  ops[0x44] = &op_in;
  ops[0x45] = &op_parse_buffer;
  ops[0x46] = &op_parse_length;
  // Output
  ops[0x48] = &op_emit;
}

// TODO: File input
int main(int argc, char **argv) {
  init_ops_array();

  inputIndex = 0;
  SRC.type = SRC.parseLength = SRC.inputPtr = 0;

  // Open the input files in reverse order and push them as file inputs.
  argc--;
  for (; argc > 1; argc--) {
    inputIndex++;
    SRC.type = (cell) fopen(argv[argc], "r");
    if ((FILE*) SRC.type == NULL) {
      fprintf(stderr, "Could not load input file: %s\n", argv[argc]);
      exit(1);
    }

    SRC.inputPtr = 0;
    SRC.parseLength = 0;
  }

  // The first argument should be the bytecode to run.
  struct stat info;
  stat(argv[1], &info);
  pc = pcTop = (char*) malloc(info.st_size);
  FILE* f = fopen(argv[1], "rb");
  fread(pc, info.st_size, 1, f);
  fclose(f);

  // pc is already set as the first VM bytecode to run.
  vm_run();
}

