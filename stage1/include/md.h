#ifndef _MD_H
#define _MD_H

// Machine-dependent header file.

#ifdef __arm__
#define QUIT_JUMP_IN __asm__("bx %0" : /* outputs  */ : "r" (**cfa) : "memory")
#elif __i386__
#define QUIT_JUMP_IN __asm__("jmpl *%0" : /* outputs */ : "r" (*cfa) : "memory")
#elif __x86_64__
#define QUIT_JUMP_IN __asm__("jmpq *%0" : /* outputs */ : "r" (*cfa) : "memory")
#endif

#endif
