LIBS=-lreadline
CFLAGS=-g -std=c99 -O0 -Wall -Wextra
INCLUDES=-Iinclude

default: all

all: vm.c
	gcc $(CFLAGS) $(INCLUDES) -o forth vm.c $(LIBS)

asm: vm.c
	gcc $(CFLAGS) $(INCLUDES) -S vm.c $(LIBS)

clean:
	rm forth
