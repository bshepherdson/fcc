LIBS=-lreadline
INCLUDES=-Iinclude

CC?=gcc

CFLAGS+=-std=c99 -Wall -Wextra

ifeq ($(DEBUG), yes)
  CFLAGS+=-g
endif

HEADERS=$(wildcard include/*.h)
SRCS=$(wildcard md/**/*.c) $(wildcard *.c)
OBJS=$(SRCS:%.c=%.o)


.PHONY: all

default: all

objs: $(SRCS) $(HEADERS)
	$(CC) $(CFLAGS) $(INCLUDES) -c $(SRCS) $(LIBS)

forth: objs
	$(CC) $(CFLAGS) $(INCLUDES) -o forth $(OBJS) $(LIBS)

all: forth

clean: FORCE
	rm -f *.o md/**/*.o forth

FORCE:

