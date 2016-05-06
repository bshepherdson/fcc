#ifdef __arm__

#include <compiler.h>
#include <primitives.h>

#define REG_RSP (12)
#define REG_SP (13)
#define REG_LR (14)
#define REG_PC (15)


#define MAX_GP_REG (11)

#define COMPILE(state, rhs) *(state->op++) = rhs
#define WRITE(target, val) *((uint32_t*) target) = val

#define RESOLVE(name) ucell _resolve_ ## name (state *s, cell* data, ucell offset, void *target)
#define EMIT(name) ucell _emit_ ## name (state *s, cell data, ucell offset, void *target)
#define OP0(name) (operation) { &_resolve_ ## name, &_emit_ ## name, 0 }
#define OP(name, data) (operation) { &_resolve_ ## name, &_emit_ ## name, data }


/*
 Design for the ARM implementation.
 The code for a nonprimitive is a fully inlined assembly function.
 - The data stack pointer is ARM's SP, R13.
 - The return stack pointer is ARM's R12.
 - It returns by popping RSP into PC.
*/

// Called during compile state initialization, to set any machine-dependent
// things, especially the register usage.
void primitive_compiler_init(state *s) {
  // On ARM, the PC (15) and SP (13) are always used. The rest are fair game
  // for use by the code.
  for (cell i = 0; i <= MAX_GP_REG; i++) {
    s->free_registers[i] = 1;
  }

  s->free_registers[REG_RSP] = 0;
  s->free_registers[REG_SP]  = 0;
  s->free_registers[REG_LR]  = 0; // Usable as general purpose?
  s->free_registers[REG_PC]  = 0;
}



// This is a miscellaneous helper: it can be passed to COMPILE, and its payload
// is the actual instruction, already encoded.
RESOLVE(raw) {
  return 4;
}
EMIT(raw) {
  WRITE(target, data);
  return 4;
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
// - load_literal_to_reg is a helper that will COMPILE code for loading a
//   literal into a register, and will either use MOV, MVN or the literal pool.


ucell primitive_emit_literal_pool(state *s, cell value, ucell offset, void *target) {
  // Just write the value out as a 32-bit integer.
  // I shouldn't need to ensure alignment here; we only ever write to the output
  // 32 bits at a time in ARM mode.
  *((cell*) target) = value;
  return 4;
}

// The top four bits of data are the register. The lower 28 are the index into
// the literal pool.
RESOLVE(load_literal_pool_to_reg) {
  return 4;
}
EMIT(load_literal_pool_to_reg) {
  // Now s->literal_pool_offset is the offset of the literal pool from the start
  // of the compiled code. offset is my own location. PC is 8 bytes after my
  // offset (probably).
  // A LDR instruction takes a base register and a 12-byte unsigned offset.
  // That gives me a range of 1K instructions from here, which is probably
  // enough to be getting on with.
  // Our offset should be: literal_pool_offset - offset - 8, base register is
  // PC. If our offset above calls for more than 4096 bytes, we currently error
  // out.
  // TODO: Use a more flexible scheme.
  uint32_t op = s->literal_pool_offset - offset - 8;
  // Bit P=24 signals pre-indexing, [pc+offset], not [pc]+offset.
  op |= 1 << 24;
  // Bit U=23 signals adding
  op |= 1 << 23;
  // Bit L=20 signals load
  op |= 1 << 20;
  // Rn is the base register at bit 16
  op |= REG_PC << 16;
  // Rd is the destination register at bit 12; that's in the top 4 bits of data.
  op |= (data >> 28) << 12;

  // Signal a memory transfer with 01 in the type field.
  op |= 1 << 26;

  WRITE(target, op);
  return 4;
}

// data is the register number to push.
RESOLVE(push) {
  return 4;
}
EMIT(push) {
  // STR is encoded like this:
  // 31-28 = cond (all 0s)
  // 27-26 = 01
  // 25 = immediate is offset if 0, shifted register if 1.
  // 24 = 0 for post-index, 1 for pre-index
  // 23 = 0 for decrement, 1 for increment
  // 22 = 0 for words, 1 for bytes
  // 21 = 0 for no writeback, 1 for writeback
  // 20 = 0 for store, 1 for load
  // 19-16 = base register for address
  // 15-12 = source/destination value
  // 11-0 = immediate offset or 4+8 shift/reg
  //
  // For this load we want to store the reg at pre-decremented, write-back SP.
  // 0000 0101 0010 base src 0
  WRITE(target, 0x05200000 | (REG_SP << 16) | (data << 12));
  return 4;
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
void load_literal_to_reg(state *s, cell value, int reg) {
  // Check if our literal can be packed into the second operand, or if its
  // negation can.
  uint32_t operand = try_pack_literal_as_operand(value);
  if ( operand == 0xffffffff ) {
    // Assemble a complete MOV instruction, which is spelled:
    // cond 00 Immediate=1 MOV=1101 S=0 Rn=ignored/0 Rd 2nd-operand
    COMPILE(s, OP(raw, (1 << 25) | (0xd << 21) | (reg << 12) | operand));
    return;
  }

  operand = try_pack_literal_as_operand(~value);
  if ( operand == 0xffffffff ) {
    // Assemble a complete MVN instruction, which is spelled:
    // cond 00 Immediate=1 MVN=1111 S=0 Rn=ignored/0 Rd 2nd-operand
    COMPILE(s, OP(raw, (1 << 25) | (0xf << 21) | (reg << 12) | operand));
    return;
  }

  // Failing those, we'll have to use the literal pool.
  uint32_t index = s->literal_count++;
  s->literal_pool[index] = value;
  COMPILE(s, OP(load_literal_pool_to_reg, index | (reg << 28)));
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
      COMPILE(s, OP(push, scratch_reg));
    } else {
      COMPILE(s, OP(push, s->stack[i].value));
      if (scratch_reg == -1) scratch_reg = s->stack[i].value;
      else free_reg(s, s->stack[i].value);
    }
  }

  if (scratch_reg != -1) free_reg(s, scratch_reg);
  s->depth = 0;
}

// TODO: Double-check that the PC, which is running ahead, is actually right.
// data is the source register we're pushing; usually PC but not always.
RESOLVE(push_rsp) {
  return 4;
}
EMIT(push_rsp) {
  // STR is encoded like this:
  // 31-28 = cond (all 0s)
  // 27-26 = 01
  // 25 = immediate is offset if 0, shifted register if 1.
  // 24 = 0 for post-index, 1 for pre-index
  // 23 = 0 for decrement, 1 for increment
  // 22 = 0 for words, 1 for bytes
  // 21 = 0 for no writeback, 1 for writeback
  // 20 = 0 for store, 1 for load
  // 19-16 = base register for address
  // 15-12 = source/destination value
  // 11-0 = immediate offset or 4+8 shift/reg
  //
  // For this load we want to store the reg at pre-decremented, write-back RSP.
  // 0000 0101 0010 base src 0
  WRITE(target, 0x05200000 | (REG_RSP << 16) | (data << 12));
  return 4;
}



// Branches to an absolute address. Used for calling other nonprimitives.
// TODO: Handle targets farther away than the +/- 32MB limit of the B
// instruction.
RESOLVE(branch_abs) {
  return 4;
}
EMIT(branch_abs) {
  // The 24-bit signed literal is the offset from the current PC (8 bytes after
  // this instruction), shifted by two.
  // So first, let's compute the offset as signed 32-bit, then truncate it.
  //
  // NB: We're assuming that the jump is within range (+/- 32MB) which is
  // probably a safe assumption for Forth compiled code but maybe not for shared
  // libraries or whatever, which could be far away in another part of the
  // address space.

  int32_t diff = ((int32_t) data) - ((int32_t) (target + 8));
  // I should just be able to shift and truncate that.
  uint32_t instruction = (((uint32_t) diff) >> 2) & 0x00ffffff;

  // Branch instructions are encoded as condition, 101, link flag, offset.
  // We don't want to link, so the link flag is 0.
  instruction |= 0x0a000000;
  WRITE(target, instruction);
  return 4;
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
  COMPILE(s, OP(push_rsp, REG_PC));

  // A literal branch instruction has a range of +/- 32MB.
  // For now I assume we can reach it.
  // TODO: Handle out-of-range branching with the literal pool and BX.
  // Remember that PC is 8 bytes ahead.
  COMPILE(s, OP(branch_abs, (cell) np->code));
}

#define DP_AND (0x0)
#define DP_EOR (0x1)
#define DP_SUB (0x2)
#define DP_RSB (0x3)
#define DP_ADD (0x4)
#define DP_CMP (0xa)
#define DP_CMN (0xb)
#define DP_ORR (0xc)


// Generic handler for "data processing" primitives, like +, AND etc.
// These all have several cases and other tricky logic.
// data is the opcode for this specific operation (unshifted).
// data is -1 to signal to EMIT that it should do nothing.
// Most of these operations (AND, EOR, ORR, ADD) are commutative.
// SUB and RSB are a special case; we switch to RSB transparently in the case
// where TOS is a register and the one beneath is a literal.

// There are three cases here, depending on what the two operands on top are:
// ( reg reg -- reg ) straightforward
// ( reg lit -- reg ) check if the literal can be inlined, do so. if not, load
//     it into a newly allocate register then do case 1.
// ( lit reg -- reg ) same as above, with the special case of inverting SUB and
//     CMP to RSB and CMN.
// ( lit lit -- lit ) manipulate the literals at compile-time, no output.
RESOLVE(data_processing_primitive) {
  stacked* top = &(s->stack[s->depth - 1]);
  stacked* bottom = &(s->stack[s->depth - 2]);
  if ( top->is_literal && bottom->is_literal ) {
    // Easy case. Run the operation now, at compile time, and emit nothing.
    bool handled = 1;
    switch (*data) {
      case DP_AND: bottom->value &= top->value; break;
      case DP_EOR: bottom->value ^= top->value; break;
      case DP_SUB: bottom->value -= top->value; break;
      // No RSB, it can't happen here.
      case DP_ADD: bottom->value += top->value; break;
      case DP_ORR: bottom->value |= top->value; break;
      default: // If we can't handle it here, grab handled.
        handled = 0;
    }

    if (handled) {
      s->depth--;
      *data = -1; // Signal EMIT phase to do nothing.
      return 0;
    } else {
      // If we can't do it in-line, we'll need to convert both to registers.
      // Thus: 



      // START HERE: Damn it, the RESOLVE phase needs to be a lot stickier. It
      // needs to (more or less) completely build the instructions, leaving the
      // EMIT phase to really just be a fix-up for labels and the literal pool.
      // It should be empty for almost everything. That makes sure that the
      // stack is correct in a single pass and allows this kind of compile-time
      // constant folding.

      // Plan: Replace RESOLVE with EMIT and EMIT with FIX_LABELS. The latter
      // only really looks at the literals list, grabs one, and does something
      // with its value to the instruction emitted previously, which it should
      // modify in-place, since it's already been written out.

      // Actually, let me change the scheme altogether. We can write the
      // instructions out on the first pass, since we know how wide everything
      // needs to be and nothing is moving after the first pass.

      // Or is it better to have a more C-friendly data structure that describes
      // operations of various types, and construct those for later munging and
      // address-fiddling. How would a more conventional AST compiler do things?

      // Builds the AST, walks it in one or more passes adding extra information
      // at various nodes, then a final pass to construct assembler output.

      // But that hands off the final, assembly-generation step to the actual
      // assembler, which is not available here. That file can write itself into
      // the 
  }

  // If we're still here, we need to go through the usual flow.
}

#endif
