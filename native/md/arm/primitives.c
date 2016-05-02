#ifdef __arm__

#include <compiler.h>
#include <primitives.h>

#define REG_RSP (12)
#define REG_SP (13)
#define REG_LR (14)
#define REG_PC (15)


#define MAX_GP_REG (11)

#define COMPILE(rhs) *(compiler_state->op++) = rhs

/*
 Design for the ARM implementation.
 The code for a nonprimitive is a fully inlined assembly function.
 - The data stack pointer is ARM's SP, R13.
 - The return stack pointer is ARM's R12.
 - It returns by popping RSP into PC.
*/

// Called during compile state initialization, to set any machine-dependent
// things, especially the register usage.
void primitive_compiler_init(void) {
  // On ARM, the PC (15) and SP (13) are always used. The rest are fair game
  // for use by the code.
  for (cell i = 0; i <= MAX_GP_REG; i++) {
    compiler_state->free_registers[i] = 1;
  }

  compiler_state->free_registers[REG_RSP] = 0;
  compiler_state->free_registers[REG_SP]  = 0;
  compiler_state->free_registers[REG_LR]  = 0; // Usable as general purpose?
  compiler_state->free_registers[REG_PC]  = 0;
}




// Core machinery.
ucell _resolve_push_lit(state *s, void* data, ucell offset) {
}

// Pushing a literal varies depending on how big the literal is and whether it
// can be assembled as one instruction or not.
// START HERE: Look up immediate MOV operands. Even rotations and so on.
// Can assemble with a few instructions if necessary.
// We're going to duplicate that logic for both of these functions, but that's
// okay, this is compile-time code.
//
// The plan: we have a 4-bit shift and 8-bit immediate. The shift is actually by
// multiples of 2, from 0 to 30. So at compile time while pushing a literal, we
// fiddle with the literal to see if it can be expressed as a literal or negated
// literal. If so, we assemble it with a literal MOV or MVN.
//
// Failing that, append it to the literal pool (which needs to be added to the
// compiler state) and replaced with:
//   add $target, pc, offset
//   ldr $target, $target
// TODO: Literal pools are a standard part of the assembler, so presumably their
// cache behavior is not terrible? Double-check that.
//
// Literals will probably go at the end - then the literal offset can be
// computed between resolving and emitting.
//
// I've added code for that to compile_emit. It will set literal_pool_offset.

ucell primitive_emit_literal_pool(state *s, cell value, ucell offset, void *target) {
  // Just write the value out as a 32-bit integer.
  // I shouldn't need to ensure alignment here; we only ever write to the output
  // 32 bits at a time in ARM mode.
  *((cell*) target) = value;
  return 4;
}



// Save all working stack values to the real stack in memory.
// TODO: A block of registers in ascending order (a common case) can be pushed
// with a single STM instruction.
void drain_stack(void) {
  for (cell i = 0; i < compiler_state->depth; i++) {
    if (compiler_state->stack[i].isLiteral) {
      COMPILE(OP_PUSH_LIT(compiler_state->stack[i].value));
    } else {
      COMPILE(OP_PUSH_REG(compiler_state->stack[i].value));
      free_reg(compiler_stack->stack[i].value);
    }
  }
}

#define RESOLVE(name) ucell _resolve_ ## name (state *s, void* data, ucell offset, void *target)
#define EMIT(name) ucell _emit_ ## name (state *s, void* data, ucell offset, void *target)
#define OP0(name) { &_resolve_ ## name, &_emit_ ## name, 0 }
#define OP(name, data) { &_resolve_ ## name, &_emit_ ## name, data }

#define WRITE(t, val) *((uint32_t*) t) = val

// TODO: Double-check that the PC, which is running ahead, is actually right.
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
  // For this load we want to store the PC at pre-decremented, write-back RSP.
  // 0000 0101 0010 base src 0
  WRITE(target, 0x05200000 | (REG_RSP << 16) | (REG_PC << 12));
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
void prim_call_nonprimitive(nonprimitive *np) {
  // For a docol nonprimitive, we need to save our current location, and then
  // jump to the implementation.
  //
  // Need to flush the stack from registers to the real stack first.
  drain_stack();

  // Now push the PC to RSP.
  // ARM documentation says that the PC is usually 8 bytes ahead, but sometimes
  // can be an implementation-defined amount away.
  // For now I'm hardcoding this for the RasPi 2's processor, which I think is
  // 8. That means the target return address I'm pushing is exactly right:
  // While I'm executing the push instruction, the jump is next, followed by the 
  // instruction I want to be running on return.
  COMPILE(OP0(push_rsp));

  // A literal branch instruction has a range of +/- 32MB.
  // For now I assume we can reach it.
  // TODO: Handle out-of-range branching with the literal pool and BX.
  // Remember that PC is 8 bytes ahead.
  COMPILE(OP(branch_abs, np->code));
}

#endif
