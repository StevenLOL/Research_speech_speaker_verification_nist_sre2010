Here is the Kaldi SRE2010 folder, please notice that this project is based on Kaldi SRE2008 example,forked under version r3473. PLDA adapation in the latest release is not used in this project.





To make it work:

###some script are changed so that the the file may not need in sorted order

1) change path for files in data folder
2) change path.sh to point to your kaldi system folder
3) make sure files in sid/steps/utils are executable
4) evaluation method used are equal error rate EER



#Folders:
##Data
###Data folder contains the reference to the following data
femaleTmatrix, female_ubm : data used for background model training.
enroll* :enrollment data used to build known speaker model (indeed just a vector).
test*:  data refer to data used to verfy system performance.

##MFCC, exp
System generated folders, 
MFCC hold the mfcc features
exp contains ubm, iVectorExtractor,ivectors , and LDA/PLDA model
