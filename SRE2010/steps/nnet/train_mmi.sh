#!/bin/bash
# Copyright 2013  Brno University of Technology (Author: Karel Vesely)  
# Apache 2.0.

# Sequence-discriminative MMI/BMMI training of DNN.
# 4 iterations (by default) of Stochastic Gradient Descent with per-utterance updates.
# Boosting of paths with more errors (BMMI) gets activated by '--boost <float>' option.

# For the numerator we have a fixed alignment rather than a lattice--
# this actually follows from the way lattices are defined in Kaldi, which
# is to have a single path for each word (output-symbol) sequence.


# Begin configuration section.
cmd=run.pl
num_iters=4
boost=0.0 #ie. disable boosting 
acwt=0.1
lmwt=1.0
learn_rate=0.00001
halving_factor=1.0 #ie. disable halving
drop_frames=true
verbose=1

seed=777    # seed value used for training data shuffling
# End configuration section

echo "$0 $@"  # Print the command line for logging

[ -f ./path.sh ] && . ./path.sh; # source the path.
. parse_options.sh || exit 1;

if [ $# -ne 6 ]; then
  echo "Usage: steps/$0 <data> <lang> <srcdir> <ali> <denlats> <exp>"
  echo " e.g.: steps/$0 data/train_all data/lang exp/tri3b_dnn exp/tri3b_dnn_ali exp/tri3b_dnn_denlats exp/tri3b_dnn_mmi"
  echo "Main options (for others, see top of script file)"
  echo "  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs."
  echo "  --config <config-file>                           # config containing options"
  echo "  --num-iters <N>                                  # number of iterations to run"
  echo "  --acwt <float>                                   # acoustic score scaling"
  echo "  --lmwt <float>                                   # linguistic score scaling"
  echo "  --learn-rate <float>                             # learning rate for NN training"
  echo "  --drop-frames <bool>                             # drop frames num/den completely disagree"
  echo "  --boost <boost-weight>                           # (e.g. 0.1), for boosted MMI.  (default 0)"
  
  exit 1;
fi

data=$1
lang=$2
srcdir=$3
alidir=$4
denlatdir=$5
dir=$6
mkdir -p $dir/log

for f in $data/feats.scp $alidir/{tree,final.mdl,ali.1.gz} $denlatdir/lat.scp $srcdir/{final.nnet,final.feature_transform}; do
  [ ! -f $f ] && echo "$0: no such file $f" && exit 1;
done

mkdir -p $dir/log

cp $alidir/{final.mdl,tree} $dir

silphonelist=`cat $lang/phones/silence.csl` || exit 1;



#Get the files we will need
nnet=$srcdir/$(readlink $srcdir/final.nnet || echo final.nnet);
[ -z "$nnet" ] && echo "Error nnet '$nnet' does not exist!" && exit 1;
cp $nnet $dir/0.nnet; nnet=$dir/0.nnet

class_frame_counts=$srcdir/ali_train_pdf.counts
[ -z "$class_frame_counts" ] && echo "Error class_frame_counts '$class_frame_counts' does not exist!" && exit 1;
cp $srcdir/ali_train_pdf.counts $dir

feature_transform=$srcdir/final.feature_transform
if [ ! -f $feature_transform ]; then
  echo "Missing feature_transform '$feature_transform'"
  exit 1
fi
cp $feature_transform $dir/final.feature_transform

model=$dir/final.mdl
[ -z "$model" ] && echo "Error transition model '$model' does not exist!" && exit 1;



# Shuffle the feature list to make the GD stochastic!
# By shuffling features, we have to use lattices with random access (indexed by .scp file).
cat $data/feats.scp | utils/shuffle_list.pl --srand $seed > $dir/train.scp


###
### Prepare feature pipeline
###
# Create the feature stream:
feats="ark,s,cs:copy-feats scp:$dir/train.scp ark:- |"
# Optionally add cmvn
if [ -f $srcdir/norm_vars ]; then
  norm_vars=$(cat $srcdir/norm_vars 2>/dev/null)
  [ ! -f $data/cmvn.scp ] && echo "$0: cannot find cmvn stats $data/cmvn.scp" && exit 1
  feats="$feats apply-cmvn --norm-vars=$norm_vars --utt2spk=ark:$data/utt2spk scp:$data/cmvn.scp ark:- ark:- |"
  cp $srcdir/norm_vars $dir
fi
# Optionally add deltas
if [ -f $srcdir/delta_order ]; then
  delta_order=$(cat $srcdir/delta_order)
  feats="$feats add-deltas --delta-order=$delta_order ark:- ark:- |"
  cp $srcdir/delta_order $dir
fi
###
###
###


###
### Prepare the alignments
### 
# Assuming all alignments will fit into memory
ali="ark:gunzip -c $alidir/ali.*.gz |"


###
### Prepare the lattices
###
# The lattices are indexed by SCP (they are not gziped because of the random access in SGD)
lats="scp:$denlatdir/lat.scp"

# Optionally apply boosting
if [[ "$boost" != "0.0" && "$boost" != 0 ]]; then
  #make lattice scp with same order as the shuffled feature scp
  awk '{ if(r==0) { latH[$1]=$2; }
         if(r==1) { if(latH[$1] != "") { print $1" "latH[$1] } }
  }' $denlatdir/lat.scp r=1 $dir/train.scp > $dir/lat.scp
  #get the list of alignments
  ali-to-phones $alidir/final.mdl "$ali" ark,t:- | awk '{print $1;}' > $dir/ali.lst
  #remove feature files which have no lattice or no alignment,
  #(so that the mmi training tool does not blow-up due to lattice caching)
  mv $dir/train.scp $dir/train.scp_unfilt
  awk '{ if(r==0) { latH[$1]="1"; }
         if(r==1) { aliH[$1]="1"; }
         if(r==2) { if((latH[$1] != "") && (aliH[$1] != "")) { print $0; } }
  }' $dir/lat.scp r=1 $dir/ali.lst r=2 $dir/train.scp_unfilt > $dir/train.scp
  #create the lat pipeline
  lats="ark,o:lattice-boost-ali --b=$boost --silence-phones=$silphonelist $alidir/final.mdl scp:$dir/lat.scp '$ali' ark:- |"
fi
###
###
###

# Run several iterations of the MMI/BMMI training
cur_mdl=$nnet
x=1
while [ $x -le $num_iters ]; do
  echo "Pass $x (learnrate $learn_rate)"
  if [ -f $dir/$x.nnet ]; then
    echo "Skipped, file $dir/$x.nnet exists"
  else
    $cmd $dir/log/mmi.$x.log \
     nnet-train-mmi-sequential \
       --feature-transform=$feature_transform \
       --class-frame-counts=$class_frame_counts \
       --acoustic-scale=$acwt \
       --lm-scale=$lmwt \
       --learn-rate=$learn_rate \
       --drop-frames=$drop_frames \
       --verbose=$verbose \
       $cur_mdl $alidir/final.mdl "$feats" "$lats" "$ali" $dir/$x.nnet || exit 1
  fi
  cur_mdl=$dir/$x.nnet

  #report the progress
  grep -B 2 MMI-objective $dir/log/mmi.$x.log | sed -e 's|^[^)]*)[^)]*)||'

  x=$((x+1))
  learn_rate=$(awk "BEGIN{print($learn_rate*$halving_factor)}")
  
done

(cd $dir; [ -e final.nnet ] && unlink final.nnet; ln -s $((x-1)).nnet final.nnet)

echo "MMI/BMMI training finished"



exit 0
