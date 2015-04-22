__author__ = 'steven'


__author__ = 'steven'

import os
import sys
import numpy as np


def processDataTable2(scores):
  #scores is a list of [scores ,ture/false labels]
  #scores[i,0] is the score
  #scores[i,1] is the 1 or 0
  print '# of scores:',len(scores)
  scores=sorted(scores); #  min->max
  sort_score=np.matrix(scores);
  minIndex=sys.maxint;
  minDis=sys.maxint;
  minTh=sys.maxint;
  alltrue=sort_score.sum(0)[0,1];
  allfalse=len(scores)-alltrue;
  eer=sys.maxint;
  fa=allfalse;
  miss=0;

  for i in range(0,len(scores)):
    #min -> max
    if sort_score[i,1]==1:
      miss+=1;
    else:
      fa-=1;


    fa_rate=float(fa)/allfalse;
    miss_rate=float(miss)/alltrue;

    if abs(fa_rate-miss_rate) < minDis:
      minDis=abs(fa_rate-miss_rate)
      eer=max(fa_rate,miss_rate);
      minIndex=i;
      minTh=sort_score[i,0];

  print eer,minTh
  return [eer,minTh]




def main(iscores):
    ds=open (iscores).readlines()
    ds=[s.strip().split() for s in ds]
    scores=[[float(s[0]),1 if s[1].lower()=='1' else 0] for s in ds]
    processDataTable2(scores)





if __name__=='__main__':
  # scores, keys
  main (sys.argv[1])
