# Research_speech_speaker_verification_nist_sre2010 [working in progress]




This baseline build on well-established iVector/PLDA speaker verification framework for SRE 2010 task.
It is based on Kaldi SRE2008 example,forked under version r3473.

#Data used in this system:
##Setup 1 
SRE2008 is not used for Tmatrix,PLDA,LDA training, reported as the clean iVector/PLDA base line in [1] with average EER 3.50%
###UBM training
Switchboard II Phase 2 and 3, Switchboard Cellular Part 1 and 2, and NIST SRE 2004, 2005 and 2006
###I Vector Extractor training
Switchboard II Phase 2 and 3, Switchboard Cellular Part 1 and 2, and NIST SRE 2004, 2005 and 2006
###Development Dataset
SRE2008
###Test Dataset
SRE2010

##Setup 2
SRE2008 is used for Tmatrix,PLDA,LDA training (WIP)
###UBM training
Switchboard II Phase 2 and 3, Switchboard Cellular Part 1 and 2, and NIST SRE 2004, 2005 and 2006,SRE2008
###I Vector Extractor training
Switchboard II Phase 2 and 3, Switchboard Cellular Part 1 and 2, and NIST SRE 2004, 2005 and 2006,SRE2008
###Development Dataset
XX
###Test Dataset
SRE2010

#Prerequisites
##data
having the Data listed above
##NIST DATA
##NIST Keys
#Kaldi
#Install Kaldi
#Kaldi structure


If you use this baseline kindly cite paper:

[1] Steven Du, Xiong Xiao, Eng Siong Chng, "DNN FEATURE COMPENSATION FOR NOISE ROBUST SPEAKER VERIFICATION", in proceedings of ChinaSIP 2015


