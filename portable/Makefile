MODULE_DIR=core
FORTH_MODULES=$(shell find $(MODULE_DIR) -name "*.fs")
FORTH_OBJECTS := $(FORTH_MODULES:%.fs=%.o)

# NOT this forth; the other Forth used for benchmark comparison.
BASE_FORTH?=gforth

NODEJS?=node
OBJCOPY?=objcopy

# For Linux
UNAME := $(shell uname)
EXTRA_SOURCES := vendor/linenoise/linenoise.c
ARCH := $(shell uname -m)

ifeq ($(UNAME), Linux)
LIBS=-ldl
CC?=gcc
endif

ifeq ($(UNAME), Darwin)
LIBS=
INCLUDES=-I/usr/local/include
LINK_FLAGS+=-L/opt/homebrew/Cellar/binutils/2.40/lib -fuse-ld=lld

export PATH := /opt/homebrew/Cellar/llvm@12/12.0.1_1/bin:$(PATH)

ifeq ($(ARCH), arm64)
CC=/opt/homebrew/bin/aarch64-apple-darwin21-gcc-12
OBJCOPY=/opt/homebrew/Cellar/binutils/2.40/aarch64-apple-darwin21.6.0/bin/objcopy
else
$(error TODO fix the flags for x86_64 gcc on Mac - I don't have one to test)
endif
endif


WARNINGS=-Wall -Wextra -Werror -Wno-unused-label -Wno-comment \
	 -Wno-stringop-truncation -Wno-stringop-overflow

BENCHMARKS=bubble-sort fib matrix-mult mm-rtcg sieve 1mloop bpsieve loop-nest \
	   6502emu int-spam

#CC=/Users/braden/bin/gcc
CFLAGS+=-O2 -std=gnu17 $(WARNINGS) -fPIC -g $(LINK_FLAGS)


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


# Need to have slightly different gold test output on 32- and 64-bit platforms.
TEST_GOLD=test/test.32.gold
ifneq ($(filter %64,$(shell uname -m)),)
    TEST_GOLD=test/test.64.gold
endif

.PHONY: all

default: all

%.in: *.js
	$(NODEJS) generator.js

engine.o: engine.c primitives.in init.in
	$(CC) $(CFLAGS) $(INCLUDES) -c engine.c $(EXTRA_SOURCES) $(LIBS)

$(MODULE_DIR)/%.s: $(MODULE_DIR)/%.fs embed.js
	$(NODEJS) embed.js $< $@

$(MODULE_DIR)/%.o: $(MODULE_DIR)/%.s
	$(CC) -c -o $@ $<

forth: engine.o $(FORTH_OBJECTS)
	$(CC) $(CFLAGS) $(CFLAGS_NORMAL) $(INCLUDES) -o forth engine.o \
		$(EXTRA_SOURCES) $(FORTH_OBJECTS) $(LIBS)

all: forth

clean: FORCE
	rm -f *.o $(MODULE_DIR)/*.o $(MODULE_DIR)/*.s forth primitives.in init.in

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
	time $(BASE_FORTH) bench/$$a.fs ; \
	done

FORCE:

