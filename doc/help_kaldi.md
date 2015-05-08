#Read/write kaldi features

##Raw Feature location

Most kaldi features are stored in mfcc folder. 

###The ark file

The ark stores the raw features, its size of ark is normally in few hundred MBs.
Eg: 20 dimensional MFCC features matrix is stored in the ark file like following:

UtteranceID1 [d1 d2 d3 d4 d5 .. d20\n d1 d2 d3 d4 d5 .. d20\n d1 d2 d3 d4 d5 .. d20\n ...]\n

UtteranceID2 [d1 d2 d3 d4 d5 .. d20\n d1 d2 d3 d4 d5 .. d20\n ]\n

Where \n means new line.

To view the feature, type the following command in the terminal

copy-feats ark:./abc.ark ark,t:

This command means copy the feature form input source (ark:./abc.ark) to output target (ark,t:) in this we leave it empty so the feature will print to the terminal.
Following two commands will dumpy the features to text file

copy-feats ark:./abc.ark ark,t: > a.txt
copy-feats ark:./abc.ark ark,t:a.txt



###The scp file

It is often saw a scp file with the same file name which describes the content of the ark file. The scp is only a text file,format for scp is in the utteranceid and feature location pairs per line.


for example abc.ark abc.scp

Following two commands will give same results

copy-feats scp:./abc.scp ark,t:
copy-feats ark:./abc.ark ark,t:

##Features in the data folder

feats.scp and vad.scp are two feature descriptors in the Kaldi data folder.
