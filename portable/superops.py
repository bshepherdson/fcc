#!/usr/bin/env python

from collections import deque
import operator

f = open("accounting.raw", "r")

width = 4
q = []

# setsOf[i] => a dictionary of occurrence counts for sequences of length i + 1
setsOf = []
for i in range(0, width):
    setsOf.append({})
    q.append(f.readline())

def account(q, i):
    s = ' -> '.join(q[0:i + 1])
    if s in setsOf[i]:
        setsOf[i][s] = setsOf[i][s] + 1
    else:
        setsOf[i][s] = 1

for line in f:
    for i in range(0, width):
        account(q, i)
    del q[0]
    q.append(line.rstrip())

f.close()

# TODO: Last couple lines aren't getting properly counted.

for i in range(0, width):
    print("Sequences of length %d" % (i + 1))
    print("=====================")

    by_count = sorted(setsOf[i].items(), key=operator.itemgetter(1), reverse=True)
    for t in by_count:
        print("%d\t%s" % (t[1], t[0]))
    print("\n\n")



