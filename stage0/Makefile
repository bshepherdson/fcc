LIBS=-lreadline
CFLAGS=-g -std=c99

default: all

all: forth.c
	gcc $(CFLAGS) -o forth forth.c $(LIBS)

clean:
	rm forth
