LIBS=-lreadline
CFLAGS=-std=c99 -Wall -Wextra -fomit-frame-pointer
INCLUDES=-Iinclude

CFLAGS_NORMAL=-O0
CFLAGS_DEBUG=-g -O0 -DDEBUG
CFLAGS_TRACE=$(CFLAGS_DEBUG) -DTRACE

default: all

all: vm.c
	gcc $(CFLAGS) $(CFLAGS_NORMAL) $(INCLUDES) -o forth vm.c $(LIBS)

debug: vm.c
	gcc $(CFLAGS) $(CFLAGS_DEBUG)  $(INCLUDES) -o forth vm.c $(LIBS)

trace: vm.c
	gcc $(CFLAGS) $(CFLAGS_TRACE)  $(INCLUDES) -o forth vm.c $(LIBS)

asm: vm.c
	gcc $(CFLAGS) $(CFLAGS_NORMAL) $(INCLUDES) -S vm.c $(LIBS)

clean:
	rm forth
