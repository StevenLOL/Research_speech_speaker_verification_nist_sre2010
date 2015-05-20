#Read/write Kaldi features

We introduce the reading and writing of two type of features here, matrix like MFCC feature, and vector based iVector and VAD vector.

##Read Kaldi MFCC features

###Raw MFCC Feature location

Most Kaldi features are stored in mfcc folder with an extension of ark or scp.

####The ark file

The ark stores raw features, its size is normally in few hundred MBs.

Eg: 20 dimensional MFCC features matrix is stored in the ark file like following:

UtteranceID1 [d1 d2 d3 d4 d5 .. d20\n d1 d2 d3 d4 d5 .. d20\n d1 d2 d3 d4 d5 .. d20\n ...]\n

UtteranceID2 [d1 d2 d3 d4 d5 .. d20\n d1 d2 d3 d4 d5 .. d20\n ]\n

Where \n means new line.

To view raw feature, type the following command in the terminal
```
copy-feats ark:./abc.ark ark,t:
```
This command means copy the feature from input source (ark:source) to output target (ark,t:target),here we leave "target" empty so the feature will print to the terminal.
Following two commands will dump the features to text file
```
copy-feats ark:./abc.ark ark,t: > a.txt
copy-feats ark:./abc.ark ark,t:a.txt
```
And dump to binary file:
```
copy-feats ark:./abc.ark ark:a.bin
```


####The scp file

It is often saw a scp file which describes the content of an ark file.

The scp is only a text file, with following format:

UtteranceID1 arkLocation1:offset1 

UtteranceID2 arkLocation2:offset2




Following two commands will give same results
```
copy-feats scp:./abc.scp ark,t:
copy-feats ark:./abc.ark ark,t:
```
####Features in the data folder

feats.scp and vad.scp are two feature descriptors in the Kaldi data folder.


##Write kaldi MFCC features

One can write kaldi feature to the ark follow the given text format. However most script in Kaldi require its scp file, one way to create scp file is:
```
copy-feats ark:./abc.ark ark,scp:b.ark,b.scp
```


##Read/write kaldi iVector or VAD vector
Both iVector and VAD vector are in vector form. Read/write kaldi iVector is similar to read/write MFCC feature, only replace the copy-feats with copy-vector command.

###Raw iVetor Feature location

Most Kaldi iVector are stored in "exp" folder with an extension of ark or scp.

The VADs are stored in 'mfcc' folder.


###Read Kaldi iVector

iVector is sorted in the ark in a vector format:

UtteranceID1 [d1 d2 d3 d4 d5 .. d400]\n

UtteranceID2 [d1 d2 d3 d4 d5 .. d400]\n

VAD have same format except the length of VAD is depends on the length of utterance. 1 for voiced frame , 0 for unvoice frame. 1 frame= 10ms



Similar to read MFCC feature,following command will read the iVector:
```
copy-vector ark:./ivector.1.ark ark,t:
copy-vector ark:./ivector.1.ark ark,t:YOUR_TEXT_FILE

```

###Write Kaldi iVector

Once you know the iVector format, you can write it back easily.
Following command will convert your ark file to Kaldi format, and generate a scp file.

```
copy-vector ark,t:./your.ark ark,scp:kaldi.ivectors.ark,kaldi.ivectors.scp

```



##FAQ
###Where is the copy-feats and copy-vector ?
It is in your kaldi src folder. You need include their directoy in your path. Please refer to the path.sh in the this SRE folder.

To load the setting in the path.sh, type this in terminal in SRE2010 folder

```
. path.sh
```
Or you can put the setting in ~/.profile or ~/.bashrc



