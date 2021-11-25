MODULE_DIR=core
FORTH_MODULES=$(shell find $(MODULE_DIR) -name "*.fs")
FORTH_OBJECTS := $(FORTH_MODULES:%.fs=%.o)

# NOT this forth; the other Forth used for benchmark comparison.
FORTH?=gforth

LIBS=-leditline -ldl

BENCHMARKS=bubble-sort fib matrix-mult mm-rtcg sieve 1mloop bpsieve loop-nest \
					 6502emu int-spam

CC?=gcc
NODEJS?=node

CFLAGS+=-O2 -std=gnu17 -Wall -Wextra -Werror -Wno-unused-label -Wno-comment \
				-Wno-stringop-truncation -Wno-stringop-overflow -fPIC -g

ifeq ($(ACCOUNTING), 1)
CFLAGS+=-DACCOUNTING -Wno-discarded-qualifiers
endif

ifeq ($(DISABLE_SUPERINSTRUCTIONS), 1)
CFLAGS+=-USUPERINSTRUCTIONS
else
CFLAGS+=-DSUPERINSTRUCTIONS
endif

ifeq ($(PROFILING), 1)
CFLAGS+=-pg
endif


ELF_FORMAT=$(shell objcopy --info | head -n 2 | tail -n 1)
ELF_ARCH=$(shell objcopy --info | head -n 4 | tail -n 1)

# Need to have slightly different gold test output on 32- and 64-bit platforms.
TEST_GOLD=test/test.32.gold
ifneq ($(filter %64,$(shell uname -m)),)
    TEST_GOLD=test/test.64.gold
endif

ARCH=$(shell uname -m)

.PHONY: all

default: all

%.in: *.js
	$(NODEJS) generator.js

engine.o: engine.c primitives.in init.in
	$(CC) $(CFLAGS) $(INCLUDES) -c engine.c $(LIBS)

$(MODULE_DIR)/%.o: $(MODULE_DIR)/%.fs
	objcopy --input binary --output $(ELF_FORMAT) \
	  --binary-architecture $(ELF_ARCH) $< $@

forth: engine.o $(FORTH_OBJECTS)
	$(CC) $(CFLAGS) $(CFLAGS_NORMAL) $(INCLUDES) -o forth engine.o \
		$(FORTH_OBJECTS) $(LIBS)

all: forth

clean: FORCE
	rm -f *.o $(MODULE_DIR)/*.o forth primitives.in init.in

test: forth FORCE
	./forth \
	  test/ttester.fs \
	  test/core01.fs \
	  test/ext.fs \
	  test/files.fs \
	  test/tools.fs \
	  test/final.fs \
	  > test.out < test/test.in
	cmp -s test.out $(TEST_GOLD) || (echo Tests failed, output does not match gold && diff test.out $(TEST_GOLD) && rm -f fatest*.txt test.out && exit 1)
	rm -f fatest*.txt test.out

bench: FORCE forth
	@for a in $(BENCHMARKS); do \
	echo =======   $$a   ======== ; \
	time ./forth bench/$$a.fs ; \
	done

bench-baseline: FORCE
	@for a in $(BENCHMARKS); do \
	echo =======   $$a   ======== ; \
	time $(FORTH) bench/$$a.fs ; \
	done

FORCE:

