MODULE_DIR=lib
FORTH_MODULES=$(shell find $(MODULE_DIR) -name "*.fs")
FORTH_OBJECTS := $(FORTH_MODULES:%.fs=%.o)

LIBS=-lreadline
CFLAGS=-std=c99 -Wall -Wextra -fomit-frame-pointer -O0
INCLUDES=-Iinclude

ELF_FORMAT=$(shell objcopy --info | head -n 2 | tail -n 1)
ELF_ARCH=$(shell objcopy --info | head -n 4 | tail -n 1)

.PHONY: all

default: all

vm.o: vm.c
	gcc $(CFLAGS) $(INCLUDES) -c vm.c $(LIBS)

$(MODULE_DIR)/%.o: $(MODULE_DIR)/%.fs
	objcopy --input binary --output $(ELF_FORMAT) \
	  --binary-architecture $(ELF_ARCH) $< $@

forth: vm.o $(FORTH_OBJECTS)
	gcc $(CFLAGS) $(CFLAGS_NORMAL) $(INCLUDES) -o forth vm.o \
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
	cmp -s test.out test/test.gold || (echo Tests failed, output does not match gold && rm -f fatest*.txt test.out && exit 1)
	rm -f fatest*.txt test.out

FORCE:

