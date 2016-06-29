#ifndef CORE_H
#define CORE_H

#include <inttypes.h>

// Basic definitions and fundamental includes.

typedef intptr_t cell;
typedef uintptr_t ucell;

typedef unsigned char bool;

#define true (-1)
#define false (0)


// This will need to be different on different platforms.
// For now, it's ARM only.
typedef uint32_t output_t;

#endif
