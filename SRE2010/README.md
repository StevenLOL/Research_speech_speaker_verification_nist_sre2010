Here is the Kaldi SRE2010 folder, please notice that this project is based on Kaldi SRE2008 example,forked under version r3473. PLDA adaption in the latest release is not used in this project.





To make it work:

###some script are changed so that the the file may not need in sorted order

1. install kaldi 	
	```
	svn checkout -r 3473 https://svn.code.sf.net/p/kaldi/code/trunk/
	```
2. change in path.sh to point to your kaldi system folder
3. change path in wav.scp data folder
4. make sure files in sid/steps/utils are executable
5. evaluation method used are equal error rate EER



#Folders:
##Data
###Data folder contains the reference to the following data
femaleTmatrix, female_ubm : data used for background model training.
enroll* :enrollment data used to build known speaker model (indeed just a vector).
test*:  data refer to data used to verify system performance.

##MFCC, exp
System generated folders, 
MFCC hold the mfcc features
exp contains ubm, iVectorExtractor,ivectors , and LDA/PLDA model
