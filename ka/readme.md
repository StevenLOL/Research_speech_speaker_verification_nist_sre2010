These folders contain file lists for enrollment speakers and test iVector. They are used only during the evaluation and scoring phase, which normally are the last two phases in SV system, you can run through the system training, ivector extraction without these data.

#Download data
Please download the data files from [here](https://www.dropbox.com/s/p8enj5x7b373n69/ka.tar.gz?dl=0), put the SRE08 and SRE10 in this folder. Extract the trials folder from trials.tar.gz and put the folder in this directory.

#Folder: trials
In speaker verification, a known speaker iVector VS test iVector is named a trial. System have to produce a score for each trial to indicate how likely the test iVector is belong to the known speaker.

Consider m known speakers and n iVectors, there will be m*n trials. The trials folder contain the possible combination for trials in one trail per line format. They are all text files, can be easily processed by Kaldi. 

#Folder: SRE08 and SRE10
Compare to the raw text format, the hdf5 file lists in SRE08 and SRE10 folder are compact matrix representation of trials, rows represent the known speakers and columns are iVectors. The hdf5 files are contributed by [Dr Kong-Aik Lee](http://www1.i2r.a-star.edu.sg/~kalee/)
