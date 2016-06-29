#ifdef __arm__

#include <stdlib.h>
#include <sys/mman.h>

#include <compiler.h>
#include <primitives.h>

#define CODE_SPACE (4 * 1024 * 1024)

#define REG_RSP (12)
#define REG_SP (13)
#define REG_LR (14)
#define REG_PC (15)

#define COND_EQ (0x0)
#define COND_NE (0x1)
#define COND_CS (0x2)
#define COND_CC (0x3)
#define COND_MI (0x4)
#define COND_PL (0x5)
#define COND_VS (0x6)
#define COND_VC (0x7)
#define COND_HI (0x8)
#define COND_LO (0x9)
#define COND_GE (0xa)
#define COND_LT (0xb)
#define COND_GT (0xc)
#define COND_LE (0xd)
#define COND_AL (0xe)
#define COND_ALWAYS (0xe)

#define MAX_GP_REG (11)

// NB: WRITE actually overrides the condition to be ALWAYS.
// Use WRITE_COND to avoid that.
#define WRITE_COND(val) *(s->output++) = val
#define WRITE(val) *(s->output++) = (COND_ALWAYS << 28) | val

// Data processing instructions are spelled:
// 31-28 condition flags
// 26-27 00
// 25 = 1 for immediate 2nd operand, 0 for shifted register
// 21-24 = 4-bit opcode number, see OP_* macros
// 20 = S, the conditional setter
// 16-19 = Rn the first operand
// 12-15 = Rd the destination register
// 0-11 = 2nd operand.

// In immediate mode (bit 25 = 1) that's 4 bits of rotation and 8 of literal.
// In shifted register mode (bit 25 = 0) that's 8 bits of shift/rotate and 4 of
// register number.
#define DP_OP_REG(op, dest, arg1, arg2) ((op << 21) | (arg1 << 16) | (dest << 12) | arg2)
#define DP_OP_IMM(op, dest, arg1, arg2) ((1 << 25) | DP_OP_REG(op, dest, arg1, arg2))

// Pop is a post-indexed, upward, write-back load.
// LDR: cond 01 I=0 P=0 post U=1 up B=0 words W=1 writeback L=1 load base dest 4
#define OP_POP(base, dest) (0x04b00004 | ((base) << 16) | ((dest) << 12))

// Push is a pre-indexed, downward, write-back store.
// STR: cond 01 I=0 P=1 pre U=0 down B=0 words W=1 writeback L=0 store base src 4
#define OP_PUSH(base, src) (0x05200004 | ((base) << 16) | ((src) << 12))

// Vanilla load: no indexing, no writeback.
// LDR: cond 01 I=0 P=0 U=0 B=0 words W=0 no writeback L=1 load base dest
#define OP_LOAD(base, dest) (0x04100000 | ((base) << 16) | ((dest) << 12))
// Vanilla store: no indexing, no writeback.
// STR: cond 01 I=0 P=0 U=0 B=0 words W=0 no writeback L=0 store base dest
#define OP_STORE(base, src) (0x04000000 | ((base) << 16) | ((src) << 12))

#define OP_AND 0x0
#define OP_EOR 0x1
#define OP_SUB 0x2
#define OP_RSB 0x3
#define OP_ADD 0x4
#define OP_CMP 0xa
#define OP_ORR 0xc
#define OP_MOV 0xd
#define OP_MVN 0xf

/*
 Design for the ARM implementation.
 The code for a nonprimitive is a fully inlined assembly function.
 - The data stack pointer is ARM's SP, R13.
 - The return stack pointer is ARM's R12.
 - It returns by popping RSP into PC.
*/

void* code_area = NULL;

// Called during compile state initialization, to set any machine-dependent
// things, especially the register usage.
void primitive_compiler_init(state *s) {
  if (code_area == NULL) {
    code_area = malloc(CODE_SPACE);
  }

  // On ARM, the PC (15) and SP (13) are always used. The rest are fair game
  // for use by the code.
  for (cell i = 0; i <= MAX_GP_REG; i++) {
    s->free_registers[i] = 1;
  }

  s->free_registers[REG_RSP] = 0;
  s->free_registers[REG_SP]  = 0;
  s->free_registers[REG_LR]  = 0; // Usable as general purpose?
  s->free_registers[REG_PC]  = 0;

  s->output_start = code_area;
  s->output = code_area;
}

void primitive_compiler_finish(state *s) {
  code_area = s->output;
}


// Turning compile-time literals into real values is a little tricky.
// - In the best case, they can be inlined as literals to the "flexible second
//   operand" that ARM supports for the data processing instructions, or into a
//   literal load.
// - Even if we need to load the literal into a register on its own, it can
//   often still be inlined as the flexible second operand to MOV or MVN.
// - Failing that, we push it onto the "literal pool", part of the compiler
//   state. These 32-bit values are emitted after the end of the word.
//   PC-relative loads can be used to get those values into registers.

// To make this easier, there's a few helper functions.
// - try_pack_literal_as_operand attempts to turn a literal into a ready-to-use
//   flexible-second-operand value.
// - load_literal_to_reg is a helper that will emit code for loading a
//   literal into a register, and will either use MOV, MVN or the literal pool.


void primitive_emit_literal_pool(state *s, cell value) {
  // Just write the value out as a 32-bit integer.
  // I shouldn't need to ensure alignment here; we only ever write to the output
  // 32 bits at a time in ARM mode.
  WRITE(value);
}


void literal_pool_finalizer(state *s, output_t *target, void* data) {
  uint32_t offset = (uint32_t) (((char*) target) - ((char*) s->output_start));
  uint32_t op = s->literal_pool_offset - offset - 8 + (4 * ((int) data));
  *(target) |= op;
}

// Writes an instruction to load the literal at the given literal index from the
// literal pool. DOES NOT put the literal there; other code is responsible for
// that.
void load_literal_pool_to_reg(state *s, uint32_t literal_index, cell reg) {
  // Now s->literal_pool_offset is the offset of the literal pool from the start
  // of the compiled code. My own location is output - output_start farther on.
  // PC is 8 bytes after my offset (probably).
  // A LDR instruction takes a base register and a 12-byte unsigned offset.
  // That gives me a range of 1K instructions from here, which is probably
  // enough to be getting on with.
  // Our offset should be: literal_pool_offset - offset - 8, base register is
  // PC. If our offset above calls for more than 4096 bytes, we currently error
  // out.
  // TODO: Use a more flexible scheme.

  // First construct a finalizer aimed at the current output (written below).
  // Its argument is the literal_index.
  finalizer *f = &(s->finalizers[s->finalizer_count++]);
  f->target = s->output;
  f->data = (void*) literal_index;
  f->code = &literal_pool_finalizer;
  // Bit 26 is 1 to signal a memory transfer op.
  // Bit P=24 signals pre-indexing, [pc+offset], not [pc]+offset.
  // Bit U=23 signals adding
  // Bit L=20 signals load
  uint32_t op = 0x59 << 20;
  // Rn is the base register at bit 16
  op |= REG_PC << 16;
  // Rd is the destination register at bit 12
  op |= reg << 12;

  // That needs the actual offset |ed in, that's in the finalizer.

  WRITE(op);
}

// Adds a value into the literal pool, and writes code to load it into a
// register.
void push_literal_to_pool_and_load(state *s, cell value, cell reg) {
  uint32_t index = s->literal_count++;
  s->literal_pool[index] = value;
  load_literal_pool_to_reg(s, index, reg);
}

void push_reg(state *s, cell reg) {
  WRITE(OP_PUSH(REG_SP, reg));
}


// Returns either a ready-to-use flexible second operand field, or -1.
// Note that it doesn't try the negated value - that's specific to MOV/MVN, and
// this generic helper function is called by the implementations of + and so on.
uint32_t try_pack_literal_as_operand(cell data) {
  // The flexible second operand is an 8-bit value that can be rotated by any
  // even amount.
  // The plan:
  // - Loop over all 31 possible rotations of the input.
  // - Check if that rotated value masks with 0xff.
  uint32_t value = (uint32_t) data;
  uint32_t temp;
  uint32_t rot;
  bool fits = 0;
  for (rot = 0; rot <= 30; rot += 2) {
    // Rotate our value /left/ into temp.
    temp = (value >> (32 - rot)) | (value << rot);
    if ( (temp & 0xff) == temp ) {
      fits = 1;
      break;
    }
  }

  if (fits) {
    // Our 8-bit literal is temp & 0xff, rot >> 1 is the rotation.
    // The binary format for the second operand wants rrrrllllllll.
    return (temp & 0xff) | ((rot >> 1) << 8);
  }

  return -1;
}

// Loads a real literal from the compile-time stack into an actual register.
void load_literal_to_reg(state *s, cell value, cell reg) {
  // Check if our literal can be packed into the second operand, or if its
  // negation can.
  uint32_t operand = try_pack_literal_as_operand(value);
  if ( operand != 0xffffffff ) {
    WRITE(DP_OP_IMM(OP_MOV, reg, 0 /* arg1 is ignored */, operand));
    return;
  }

  operand = try_pack_literal_as_operand(~value);
  if ( operand != 0xffffffff ) {
    WRITE(DP_OP_IMM(OP_MVN, reg, 0 /* arg1 is ignored */, operand));
    return;
  }

  // Failing those, we'll have to use the literal pool.
  push_literal_to_pool_and_load(s, value, reg);
}

// Loads and consumes the value on top of the stack, and returns the register
// number that contains it.
cell pop_stack_reg(state *s) {
  if (s->depth == 0) {
    cell reg = alloc_reg(s);
    WRITE(OP_POP(REG_SP, reg));
    return reg;
  } else {
    // Stacked register, not much to do.
    stacked *item = &(s->stack[s->depth - 1]);
    cell reg;
    if (item->is_literal) {
      reg = alloc_reg(s);
      load_literal_to_reg(s, item->value, reg);
    } else {
      reg = item->value;
    }
    s->depth--;
    return reg;
  }
}

// Loads (and consumes) the value on top of the stack, and returns a suitable
// form for operand2.
// If the value is a literal and it will fit as a literal, this returns the
// correct operand2 value, including the I flag.
// If it's a register, stored in real memory, or too big a literal for the
// second operand, outputs the right code to load it into a register, and
// returns an operand value for that register.
//
// NB: This does not free the registers, even though they've been popped from
// the stack. To avoid leaking registers, make sure that operations clean up
// after themselves.
uint32_t pop_stack_operand2(state *s) {
  // Several cases here:
  // - Literal that fits - return in second operand form.
  // - Literal that doesn't fit - load to a register.
  // - Register - just use it.
  // - Real memory - load it to a freshly allocated register.
  // However, most of these are handled by pop_stack_reg above.
  // We just need to handle a literal that fits into the second operand.
  if (s->depth > 0 && s->stack[s->depth - 1].is_literal) {
    cell value = s->stack[s->depth - 1].value;
    uint32_t operand2 = try_pack_literal_as_operand(value);
    if (operand2 != 0xffffffff) {
      s->depth--;
      return operand2;
    }
  }

  return (uint32_t) pop_stack_reg(s);
}


// Save all working stack values to the real stack in memory.
// TODO: A block of registers in ascending order (a common case) can be pushed
// with a single STM instruction.
void drain_stack(state *s) {
  cell scratch_reg = -1;
  for (cell i = 0; i < s->depth; i++) {
    if (s->stack[i].is_literal) {
      if (scratch_reg == -1) scratch_reg = alloc_reg(s);
      load_literal_to_reg(s, s->stack[i].value, scratch_reg);
      push_reg(s, scratch_reg);
    } else {
      push_reg(s, s->stack[i].value);
      if (scratch_reg == -1) scratch_reg = s->stack[i].value;
      else free_reg(s, s->stack[i].value);
    }
  }

  if (scratch_reg != -1) free_reg(s, scratch_reg);
  s->depth = 0;
}

void push_rsp(state *s, cell reg) {
  WRITE(OP_PUSH(REG_RSP, reg));
}

cell pop_rsp(state *s) {
  cell reg = alloc_reg(s);
  WRITE(OP_POP(REG_RSP, reg));
  return reg;
}


// Branches to an absolute address. Used for calling other nonprimitives.
// TODO: Handle targets farther away than the +/- 32MB limit of the B
// instruction.
void branch_abs(state *s, cell target) {
  // The 24-bit signed literal is the offset from the current PC (8 bytes after
  // this instruction), shifted by two.
  // So first, let's compute the offset as signed 32-bit, then truncate it.
  //
  // NB: We're assuming that the jump is within range (+/- 32MB) which is
  // probably a safe assumption for Forth compiled code but maybe not for shared
  // libraries or whatever, which could be far away in another part of the
  // address space.

  int32_t diff = (int32_t) (((uint32_t) target) - (((uint32_t) (s->output_start)) + 8));
  // I should just be able to shift and truncate that.
  uint32_t instruction = (((uint32_t) diff) >> 2) & 0x00ffffff;

  // Branch instructions are encoded as condition, 101, link flag, offset.
  // We don't want to link, so the link flag is 0.
  instruction |= 0x0a000000;
  WRITE(instruction);
}


// Compiles a call to the nonprimitive's code.
// TODO: Handle codewords other than docol (eg. dodoes)
void prim_call_nonprimitive(state *s, nonprimitive *np) {
  // For a docol nonprimitive, we need to save our current location, and then
  // jump to the implementation.
  //
  // Need to flush the stack from registers to the real stack first.
  drain_stack(s);

  // Now push the PC to RSP.
  // ARM documentation says that the PC is usually 8 bytes ahead, but sometimes
  // can be an implementation-defined amount away.
  // For now I'm hardcoding this for the RasPi 2's processor, which I think is
  // 8. That means the target return address I'm pushing is exactly right:
  // While I'm executing the push instruction, the jump is next, followed by the 
  // instruction I want to be running on return.
  push_rsp(s, REG_PC);

  // A literal branch instruction has a range of +/- 32MB.
  // For now I assume we can reach it.
  // TODO: Handle out-of-range branching with the literal pool and BX.
  // Remember that PC is 8 bytes ahead.
  branch_abs(s, (cell) np->code);
}


// Check that it contains only the bottom 4 bits (ie. is a register).
void maybe_free_reg(state *s, cell operand) {
  if ((operand & (~15)) == 0) free_reg(s, operand);
}

// Generic handler for "data processing" primitives, like +, AND etc.
// These all have several cases and other tricky logic.
// Most of these operations (AND, EOR, ORR, ADD) are commutative.
// SUB and RSB are a special case; we switch to RSB transparently in the case
// where TOS is a register and the one beneath is a literal.

// TODO: Optimize the following special cases:
// - Two literals should be handled at compile time.
// - Literal on top should be handled in operand2 if possible.
// - Literal under a register should be handled with cleverness (and RSB).
// For now, it just does the naive thing using registers.
void data_processing(state *s, uint32_t op) {
  cell reg_top = pop_stack_operand2(s);
  cell reg_bot = pop_stack_reg(s);

  // Assemble the instruction.
  WRITE(DP_OP_REG(op, reg_bot, reg_bot, reg_top));
  // Push the top one back onto our compile-time stack.
  s->stack[s->depth].value = reg_bot;
  s->stack[s->depth].is_literal = 0;
  s->depth++;

  maybe_free_reg(s, reg_top);
}


// Direct primitive implementations.
#define PRIMITIVE(name) void prim_ ## name(state *s)
#define PRIMITIVE_DP(name, op) PRIMITIVE(name) { data_processing(s, op); }

PRIMITIVE_DP(plus, OP_ADD);
PRIMITIVE_DP(minus, OP_SUB);
PRIMITIVE_DP(and, OP_AND);
PRIMITIVE_DP(or, OP_ORR);
PRIMITIVE_DP(xor, OP_EOR);

void reg_to_compile_stack(state *s, cell reg) {
  stacked *stack = &(s->stack[s->depth++]);
  stack->is_literal = 0;
  stack->value = reg;
}

#define BINARY_REG_PRIMITIVE(name, expr) PRIMITIVE(name) {\
  cell reg_top = pop_stack_reg(s);\
  cell reg_bot = pop_stack_reg(s);\
  WRITE(expr);\
  reg_to_compile_stack(s, reg_bot);\
  free_reg(s, reg_top);\
}

// NUL can't have Rd and Rn the same.
// Fortunately multiplication is commutative, so we just make Rd and Rs the
// same.
// MUL: cond 000000 Accumulate=0 S=0 Rd Rn(ignored) Rs=bot 1001 Rm=top
BINARY_REG_PRIMITIVE(times, 0x00000090 | (reg_bot << 16) /* Rd */ |
      (reg_bot << 8) /* Rs */ | reg_top /* Rm */)


// LSHIFT and RSHIFT require digging into how MOV's rotations and stuff work.
// We effectively want: MOV TOS^, TOS^ LSL Rs=TOS
// Assemble the flexible second operand into this form:
// Rs=TOS 0 xx=shift_type 1 Rm=TOS^

// TODO: We could handle the TOS being a literal, and use the more literal
// shift form. This code always uses both arguments in registers.
#define SHIFT_EXPR(type) DP_OP_REG(OP_MOV, reg_bot,\
    0 /* arg1=Rn is ignored for MOV */, (reg_top << 8) | (type << 5)\
    | (1 << 4) | reg_bot)

BINARY_REG_PRIMITIVE(lshift, SHIFT_EXPR(0x0)); // Logical left
BINARY_REG_PRIMITIVE(rshift, SHIFT_EXPR(0x1)); // Logical right


// Comparison operations: use CMP to set up the flags, then put 0 into the
// destination register, then conditionally subtract 1 from it to make -1.
void do_comparison(state *s, uint32_t condition_flags) {
  cell reg_top = pop_stack_operand2(s);
  cell reg_bot = pop_stack_reg(s);

  reg_top |= 1 << 20; // S bit for setting the flags.

  WRITE(DP_OP_REG(OP_CMP, 0 /* Rd is ignored */, reg_bot, reg_top));
  // Now let's set the destination register to 0. We use EOR on itself.
  WRITE(DP_OP_REG(OP_EOR, reg_bot, reg_bot, reg_bot));

  // Now conditionally set it to 0xffffffff. We do that with a handwritten
  // MVN immediate 0, with condition flags.
  // MVN: cond 00 I=1 Op=MVN=1111 S=0 Rn=0 (ignored) Rd=bottom 0...
  WRITE_COND((condition_flags << 28) | (1 << 25) | (OP_MVN << 21) | (1 << 20) |
      (reg_bot << 12) /* Rd */);

  // Record the stacked register, and free the top one if needed.
  reg_to_compile_stack(s, reg_bot);
  maybe_free_reg(s, reg_top);
}

PRIMITIVE(equals) {
  do_comparison(s, COND_EQ);
}
PRIMITIVE(greater_than) {
  do_comparison(s, COND_GT);
}
PRIMITIVE(unsigned_greater_than) {
  do_comparison(s, COND_HI);
}

PRIMITIVE(dup) {
  // Three cases here:
  // - Literal - duplicate at compile time
  // - Register - emit a MOV
  // - Memory - emit a LDR

  // If it's in memory (depth == 0) load from SP without writeback.
  if (s->depth == 0) {
    // It's in memory, so load from SP, but without writeback.
    cell reg = alloc_reg(s);
    WRITE(OP_LOAD(REG_SP, reg));
    reg_to_compile_stack(s, reg);
    return;
  }

  // There's at least one value on the compile-time stack, so grab it.
  stacked *top = &(s->stack[s->depth - 1]);
  if (top->is_literal) {
    s->depth++;
    s->stack[s->depth - 1].is_literal = 1;
    s->stack[s->depth - 1].value = top->value;
    return;
  }

  // If we're still here, it's in a register. So generate a MOV.
  cell reg = alloc_reg(s);
  WRITE(DP_OP_REG(OP_MOV, reg, 0 /* arg1 ignored */, top->value));
  reg_to_compile_stack(s, reg);
}

PRIMITIVE(swap) {
  // Swap is a bit tricky, since there's a few cases.
  // If the depth is at least 2, just swap the records at compile time.
  // If it's less than that, load from memory onto the compile-time stack.
  if (s->depth >= 2) {
    stacked *top = &(s->stack[s->depth - 1]);
    stacked *bottom = &(s->stack[s->depth - 2]);
    cell value = top->value;
    bool is_literal = top->is_literal;
    top->value = bottom->value;
    top->is_literal = bottom->is_literal;
    bottom->value = value;
    bottom->is_literal = is_literal;
  } else if (s->depth == 1) {
    // Load with writeback from the stack.
    cell reg = alloc_reg(s);
    WRITE(OP_POP(REG_SP, reg));
    reg_to_compile_stack(s, reg);
  } else {
    cell reg_top = pop_stack_reg(s);
    cell reg_bottom = pop_stack_reg(s);
    reg_to_compile_stack(s, reg_top);
    reg_to_compile_stack(s, reg_bottom);
  }
}

PRIMITIVE(drop) {
  if (s->depth > 0) {
    if ( ! s->stack[s->depth - 1].is_literal ) {
      free_reg(s, s->stack[s->depth - 1].value);
    }
    s->depth--;
  } else {
    // Add 4 to SP.
    WRITE(DP_OP_IMM(OP_ADD, REG_SP, REG_SP, 4));
  }
}

PRIMITIVE(fetch_sp) {
  // MOV reg, sp
  cell reg = alloc_reg(s);
  WRITE(DP_OP_REG(OP_MOV, reg, 0 /* ignored */, REG_SP));
  reg_to_compile_stack(s, reg);
}

PRIMITIVE(store_sp) {
  // I hope you know what you're doing!
  // MOV sp, reg
  uint32_t operand2 = pop_stack_operand2(s);
  WRITE(DP_OP_REG(OP_MOV, REG_SP, 0 /* ignored */, operand2));
  maybe_free_reg(s, operand2);
}

PRIMITIVE(to_r) {
  cell reg = pop_stack_reg(s);
  push_rsp(s, reg);
  free_reg(s, reg);
}

PRIMITIVE(from_r) {
  cell reg = pop_rsp(s);
  reg_to_compile_stack(s, reg);
}

PRIMITIVE(r_fetch) {
  // Load from RSP without writeback.
  cell reg = alloc_reg(s);
  WRITE(OP_LOAD(REG_RSP, reg));
  reg_to_compile_stack(s, reg);
}


PRIMITIVE(fetch) {
  cell reg = pop_stack_reg(s);
  WRITE(OP_LOAD(reg, reg));
  reg_to_compile_stack(s, reg);
}

PRIMITIVE(store) {
  cell addr = pop_stack_reg(s);
  cell value = pop_stack_reg(s);
  WRITE(OP_STORE(addr, value));
  free_reg(s, addr);
  free_reg(s, value);
}

PRIMITIVE(cfetch) {
  cell reg = pop_stack_reg(s);
  WRITE(OP_LOAD(reg, reg) | (1 << 22)); // Bit 22 is B, byte mode.
  reg_to_compile_stack(s, reg);
}
PRIMITIVE(cstore) {
  cell addr = pop_stack_reg(s);
  cell value = pop_stack_reg(s);
  WRITE(OP_STORE(addr, value) | (1 << 22)); // Bit 22 is B, byte mode.
  free_reg(s, addr);
  free_reg(s, value);
}

PRIMITIVE(cells) {
  cell reg = pop_stack_reg(s);
  // Shift: 00100 00 0 = 4-bit logical left, literal.
  WRITE(DP_OP_REG(OP_MOV, reg, 0 /* ignored */, reg | (0x200)));
  reg_to_compile_stack(s, reg);
}

PRIMITIVE(chars) {
  // Do nothing.
}

// START HERE: Implement the branching primitives! They're one of the trickiest
// bits and may shake up the compiler state design even further.

// Other notes:
// - How are we keeping track of the code and data space pointers? Where do they
//   live? One idea: make them C globals, put their addresses into a stacked
//   literal by hand, and then emit code to load those literals and update them.
// - Need to figure out a design for word creation words. They can actually be
//   written in Forth sanely, if I can control how they are constructed.
// - What about xts? A single-cell value that exists for primitives, docol and
//   dodoes words. Need a plan for that! Simple addresses work for everything
//   but dodoes; maybe I can make it work for everything? Need to think about
//   it.
// - In addition to the two spaces, I need some core variables, like BASE,
//   STATE, (LATEST), etc.


// TODO: Audit the primitives above to make sure they're actually cleaning up
// their register allocations. All registers used should either finish on the
// stack or be freed up.
//
// Missing primitives (subject to revision):
// / MOD
// U/ UMOD
// (optionally:) OVER ROT -ROT and 2foo, for speed
// RP@ RP!
// (>HERE) (or similar)
// : ; CREATE DOES> :NONAME
// EXECUTE >BODY


// Open questions:
// - How to handle (DOSTRING)? Number literals are compiled directly, but
//   strings are a little more tricky. Add the strings to a similar pool in the
//   code? S" strings are immutable, and only legal at compile time.
// - What is an xt?

#endif
