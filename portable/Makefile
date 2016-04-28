MODULE_DIR=lib
FORTH_MODULES=$(shell find $(MODULE_DIR) -name "*.fs")
FORTH_OBJECTS := $(FORTH_MODULES:%.fs=%.o)

LIBS=-lreadline
INCLUDES=-Iinclude

BENCHMARKS=bubble-sort fib matrix-mult mm-rtcg sieve

CC?=gcc

CFLAGS+=-std=c99 -Wall -Wextra -fomit-frame-pointer
ifeq ($(ACCOUNTING), yes)
  CFLAGS+=-DACCOUNTING
  SUPERINSTRUCTIONS=no
endif

ifneq ($(SUPERINSTRUCTIONS), no)
  CFLAGS+=-DENABLE_SUPERINSTRUCTIONS
endif

ifeq ($(SUPERINSTRUCTION_DEBUG), yes)
  CFLAGS+=-DSUPERINSTRUCTION_DEBUG
endif

ifneq ($(OPT), no)
  # This is all the flags mentioned on -O1. -O1 itself fails, however.
  # TODO: Figure out why, someday. For now, these help.
  # TODO: Actually set up benchmarks.
  CFLAGS+=-fbranch-count-reg -fcombine-stack-adjustments -fcompare-elim \
      -fcprop-registers -fdefer-pop -fforward-propagate \
      -fguess-branch-probability -fif-conversion2 -fif-conversion \
      -finline-functions-called-once -fipa-profile  -fipa-pure-const \
      -fipa-reference -fmove-loop-invariants -fshrink-wrap -fsplit-wide-types \
      -fssa-phiopt -ftree-bit-ccp -ftree-ccp -ftree-ch -ftree-copy-prop \
      -ftree-copyrename -ftree-dce -ftree-dominator-opts -ftree-dse -ftree-fre \
      -ftree-pta -ftree-sink -ftree-slsr -ftree-sra -ftree-ter
endif

ifeq ($(DEBUG), yes)
  CFLAGS+=-g
endif


ELF_FORMAT=$(shell objcopy --info | head -n 2 | tail -n 1)
ELF_ARCH=$(shell objcopy --info | head -n 4 | tail -n 1)

# Need to have slightly different gold test output on 32- and 64-bit platforms.
TEST_GOLD=test/test.32.gold
ifneq ($(filter %64,$(shell uname -m)),)
    TEST_GOLD=test/test.64.gold
endif

.PHONY: all

default: all

vm.o: vm.c
	$(CC) $(CFLAGS) $(INCLUDES) -c vm.c $(LIBS)

$(MODULE_DIR)/%.o: $(MODULE_DIR)/%.fs
	objcopy --input binary --output $(ELF_FORMAT) \
	  --binary-architecture $(ELF_ARCH) $< $@

forth: vm.o $(FORTH_OBJECTS)
	$(CC) $(CFLAGS) $(CFLAGS_NORMAL) $(INCLUDES) -o forth vm.o \
	  $(FORTH_OBJECTS) $(LIBS)

all: forth

clean: FORCE
	rm -f *.o lib/*.o forth

test: forth FORCE
	./forth \
	  test/ttester.fs \
	  test/core01.fs \
	  test/ext.fs \
	  test/files.fs \
	  test/final.fs \
	  > test.out < test/test.in
	cmp -s test.out $(TEST_GOLD) || (echo Tests failed, output does not match gold && rm -f fatest*.txt test.out && exit 1)
	rm -f fatest*.txt test.out

bench: FORCE forth
	@for a in $(BENCHMARKS); do \
	echo =======   $$a   ======== ; \
	time ./forth bench/$$a.fs ; \
	done

FORCE:

