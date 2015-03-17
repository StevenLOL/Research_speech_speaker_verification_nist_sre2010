 scoredata=textscan(fopen('/media/ssd_/steven/sre10/research_sv_sre2010_kaldi/kaldi/core-core-cond04_key.hdf5.txt'),'%f %f');
 score=[scoredata{:,1}];
 class=[scoredata{:,2}];
 [Pmiss,Pfa] = rocch(score(class==1),score(class==0));
 eer = rocch2eer(Pmiss,Pfa)