import os
import sys

f=sys.argv[1]


data=open(f).readlines();

di=dict()
cout=0
for l in data:
    for s in l.strip().split():
        if not s in di:
            di[s]=1
        else:
            print 'error',s,cout
            cout+=1
         