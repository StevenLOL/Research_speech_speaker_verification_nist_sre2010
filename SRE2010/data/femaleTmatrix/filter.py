import os
import sys

ifile=sys.argv[1]
patt=sys.argv[2]


fd=open(ifile).readlines()
fout=open(ifile,'w')
for f in fd:
    if not patt in f:
        fout.write(f)
fout.close()
