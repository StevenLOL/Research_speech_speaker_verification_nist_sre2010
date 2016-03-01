#Update:

[Kaldi now has SRE10 example.](https://github.com/kaldi-asr/kaldi/tree/master/egs/sre10), so please use the recipes in the latest kaldi. Thanks. If you need infomation on Kaldi's data format you can still refer to [this document](doc/help_kaldi.md).


~~~
The subdirectories "v1" and so on are different iVector-based speaker 
 recognition recipes. The recipe in v1 demonstrates a standard approach 
 using a full-covariance GMM-UBM, iVectors, and a PLDA backend. The example 
 in v2 replaces the GMM of the v1 recipe with a time-delay deep neural 
 network.
~~~


# Kaldi SRE2010 

This baseline build on well-established iVector/PLDA speaker verification framework for SRE 2010 female tasks. This work is based on Kaldi SRE 2008 example. The result is reported as the clean iVector/PLDA baseline in [1] with average EER 3.50% over nine core conditions.


To run this experiment plese first check data, hardware and software [requirements](doc/help_sre2010.md) and then read this [guide](SRE2010). 

For information about kaldi data format and IO please read [this document](doc/help_kaldi.md).




If you feel this baseline helpful kindly cite Kaldi as well as this paper:

[1] Steven Du, Xiong Xiao, Eng Siong Chng, "DNN FEATURE COMPENSATION FOR NOISE ROBUST SPEAKER VERIFICATION", ChinaSIP 2015


