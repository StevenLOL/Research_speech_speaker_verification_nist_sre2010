# Kaldi SRE2010 [working in progress]




This baseline build on well-established iVector/PLDA speaker verification framework for SRE 2010 female tasks. This work is based on Kaldi SRE 2008 example. The result is reported as the clean iVector/PLDA base line in [1] with average EER 3.50%. 


 


#Prerequisites
##1. Data
###UBM training
Switchboard II Phase 2 and 3, Switchboard Cellular Part 1 and 2, and NIST SRE 2004, 2005 and 2006
###I Vector Extractor training
Switchboard II Phase 2 and 3, Switchboard Cellular Part 1 and 2, and NIST SRE 2004, 2005 and 2006

*SRE2008 and MIXER5 are not used for Tmatrix,PLDA,LDA training, 

###Development Dataset
SRE2008

###Test Dataset
SRE2010

###NIST Keys
Keys for scoring
#2. Hardware
It's better to have a PC with more than 24GB memory.
#3. Kaldi
You need kladi system to run this experments. 



To run this experment plese read this [guide](SRE2010/README.md). Information about kaldi IO please read [this document](doc/help_kaldi.md).




If you use this baseline kindly cite paper:

[1] Steven Du, Xiong Xiao, Eng Siong Chng, "DNN FEATURE COMPENSATION FOR NOISE ROBUST SPEAKER VERIFICATION", ChinaSIP 2015


