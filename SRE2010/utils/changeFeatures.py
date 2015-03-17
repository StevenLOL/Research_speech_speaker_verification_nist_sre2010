import os
import sys

'''change the features of a data folder

input1 = data folder
input2 = folder for the features
input3 = output data folder location
output = new data folder with new location of features


'''

datafolder=sys.argv[1]
newFeatureFolder=sys.argv[2]
newdataFolder=sys.argv[3];
os.system('mkdir -p %s'%(newdataFolder))


for f in os.listdir(datafolder):
    print f
    if os.path.isfile(datafolder+'/'+f):
        if f=='feats.scp':
            fdata=open(datafolder+'/'+f).readlines()
            fout=open(newdataFolder+'/'+f,'w');
            
            for fline in fdata:
                fid=fline.split()[0]
                flocationid=fline.split('/')[-1]
                newline='%s %s/%s'%(fid,newFeatureFolder,flocationid)
                fout.write(newline)
            fout.close();
        else:
            os.system('cp %s/%s %s/%s'%(datafolder,f,newdataFolder,f))