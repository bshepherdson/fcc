# MODULE_DIR=../portable/core
# FORTH_MODULES=$(shell find $(MODULE_DIR) -name "*.fs")
# FORTH_OBJECTS := $(FORTH_MODULES:%.fs=%.o)

LIBS=-lreadline -ldl

# BENCHMARKS=bubble-sort fib matrix-mult mm-rtcg sieve 1mloop bpsieve loop-nest

CC?=gcc
FORTH?=gforth

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

ARCH=$(shell uname -m)
PLATFORM=$(shell uname)
MD=md/$(PLATFORM)/$(ARCH)

.PHONY: all

default: all

gen_out.o: $(MD)/header.s $(MD)/funops.fs setup.fs engine.fs generator.fs
	$(FORTH) setup.fs $(MD)/funops.fs engine.fs generator.fs
	cat $(MD)/header.s gen_out.s > __make_temp.s
	mv __make_temp.s gen_out.s
	$(CC) $(CFLAGS) -c $(MD)/header.s gen_out.s $(LIBS)

#$(MODULE_DIR)/%.o: $(MODULE_DIR)/%.fs
#	objcopy --input binary --output $(ELF_FORMAT) \
#	  --binary-architecture $(ELF_ARCH) $< $@

#forth: vm.o $(FORTH_OBJECTS)
#	$(CC) $(CFLAGS) $(CFLAGS_NORMAL) $(INCLUDES) -o forth vm.o \
#	  $(FORTH_OBJECTS) $(LIBS)

forth: gen_out.o

all: forth

clean: FORCE
	rm -f *.o forth gen_out.s

FORCE:

