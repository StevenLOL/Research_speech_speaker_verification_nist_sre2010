Here is the Kaldi SRE2010 folder, this project is based on Kaldi SRE2008 example,forked under version r3473.




To reproduce experimental results:



1. install Kaldi 	
	```
	svn checkout -r 3473 https://svn.code.sf.net/p/kaldi/code/trunk/
	```
2. git this projcet
2. change KaldiRoot in path.sh to point to your kaldi system
3. change path in wav.scp data folder
4. make sure files in sid/steps/utils are executable
5. evaluation method used are equal error rate EER



#Folders:
##Data folder
###Data folder contains the reference to the following data
1. femaleTmatrix, female_ubm : data used for background model training.
2. enroll* :enrollment data used to build known speaker model (indeed just a vector).
3. test*:  refer to data used to verify system performance.

###Contents of each data folder
1. wav.scp: 
>this is the most important file, it contains utteranceID and utterance location information
2. utt2spk:
>this file indicates the utterance and speaker relationship
3. spk2utt:
>this file indicates speaker to utterance relationship (1 to many)
4. feats.scp:
>will only appear when features are extracted, it contains utteranceID and feature location information
5. vad.scp:
>will only appear after compute VAD step,it contains utteranceID and feature location information
6. split*N*:
>Kldi divide data in N parts, execute the script simultaneously,known as data parallelism. 

###Some notes about the data
1. To ensure your data can be split into N parts, **utteranceID in wav.scp, utt2spk,feats.scp,vad.scp must have same order**.
2. utteranceID must be unique
3. utt2spk and spk2utt are interchangeable 
```
*PathToUtilsFolder*/spk2utt_to_utt2spk.pl spk2utt > utt2spk

*PathToUtilsFolder*/utt2spk_to_spk2utt.pl utt2spk > spk2utt
```
##MFCC, exp folder
System generated folders, 
MFCC hold the mfcc features, 
exp contains UBM, iVectorExtractor,ivectors , and LDA/PLDA model and score.
