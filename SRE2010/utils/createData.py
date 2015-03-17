import os
import sys

def copyData(ifolder,ofolder,wavfolder,keepvad='1'):
    filelist=['utt2spk','spk2utt']
    os.system('mkdir -p %s'%(ofolder))
    fdata=open(ifolder+'/wav.scp').readlines()
    with open(ofolder+'/wav.scp','w') as fout:
        for f in fdata:
            fid=f.split()[0]
            fout.write(fid+' '+wavfolder+'/'+fid+'.wav\n')
    os.system('cp %s/utt2spk %s/utt2spk'%(ifolder,ofolder))
    os.system('cp %s/spk2utt %s/spk2utt'%(ifolder,ofolder))    
    os.system('cp %s/spk2gender %s/spk2gender'%(ifolder,ofolder))
    if keepvad=='1':
        os.system('cp %s/vad.scp %s/vad.scp'%(ifolder,ofolder))

if __name__=='__main__':
    print sys.argv
    if len(sys.argv)==5:
        copyData(sys.argv[1],sys.argv[2],sys.argv[3],keepvad=sys.argv[4])
    else:
        copyData(sys.argv[1],sys.argv[2],sys.argv[3])