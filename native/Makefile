LIBS=-lreadline
INCLUDES=-Iinclude

CC?=gcc

CFLAGS+=-std=c99 -Wall -Wextra -Wno-unused-parameter

ifeq ($(DEBUG), yes)
  CFLAGS+=-g
endif

HEADERS=$(wildcard include/*.h)
SRCS=$(wildcard *.c)
OBJS=$(SRCS:%.c=%.o)

# TODO: Make this check your platform and react accordingly.
PRIMITIVE=md/arm/primitives.c


.PHONY: all

default: all

primitive: $(HEADERS) $(PRIMITIVE)
	$(CC) $(CFLAGS) $(INCLUDES) -c $(PRIMITIVE) -o primitive.o $(LIBS)

objs: $(SRCS) $(HEADERS)
	$(CC) $(CFLAGS) $(INCLUDES) -c $(SRCS) $(LIBS)

forth: objs primitive
	$(CC) $(CFLAGS) $(INCLUDES) -o forth $(OBJS) primitive.o $(LIBS)

all: forth

clean: FORCE
	rm -f *.o md/**/*.o forth

FORCE:

