#! /usr/bin/python -tt

import os
import sys

def main(ifolder):
	u2spk=open(ifolder+'/utt2spk').readlines();
	wscp=open(ifolder+'/wav.scp').readlines();
	us=[s.split()[0] for s in u2spk]
	owsp=open(ifolder+'/wav.scp','w');
	for s in wscp:
		uid=s.split()[0]
		if uid in us:
			owsp.write(s.strip()+'\n');
	owsp.close();
	if not os.path.isfile(ifolder+'/test.trials'):
		return;
	u2spk=open(ifolder+'/wav.scp').readlines();
	wscp=open(ifolder+'/test.trials').readlines();
	us=[s.split()[0] for s in u2spk]
	owsp=open(ifolder+'/test.trials','w');
	for s in wscp:
		uid=s.split()[1]
		if uid in us:
			owsp.write(s.strip()+'\n');
	owsp.close();
		

if __name__=='__main__':
	main(sys.argv[1]);