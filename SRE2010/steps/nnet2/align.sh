#!/bin/bash
# Copyright 2012  Brno University of Technology (Author: Karel Vesely)
#           2013  Johns Hopkins University (Author: Daniel Povey)
# Apache 2.0

# Computes training alignments using MLP model

# If you supply the "--use-graphs true" option, it will use the training
# graphs from the source directory (where the model is).  In this
# case the number of jobs must match with the source directory.


# Begin configuration section.  
nj=4
cmd=run.pl
# Begin configuration.
scale_opts="--transition-scale=1.0 --acoustic-scale=0.1 --self-loop-scale=0.1"
beam=10
retry_beam=40
transform_dir=
iter=final
use_gpu=no
# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. parse_options.sh || exit 1;

if [ $# != 4 ]; then
   echo "Usage: $0 [--transform-dir <transform-dir>] <data-dir> <lang-dir> <src-dir> <align-dir>"
   echo "e.g.: $0 data/train data/lang exp/nnet4 exp/nnet4_ali"
   echo "main options (for others, see top of script file)"
   echo "  --config <config-file>                           # config containing options"
   echo "  --nj <nj>                                        # number of parallel jobs"
   echo "  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs."
   exit 1;
fi

data=$1
lang=$2
srcdir=$3
dir=$4

oov=`cat $lang/oov.int` || exit 1;
mkdir -p $dir/log
echo $nj > $dir/num_jobs
sdata=$data/split$nj
[[ -d $sdata && $data/feats.scp -ot $sdata ]] || split_data.sh $data $nj || exit 1;

for f in $srcdir/tree $srcdir/${iter}.mdl $data/feats.scp $lang/L.fst; do
  [ ! -f $f ] && echo "$0: no such file $f" && exit 1;
done

cp $srcdir/{tree,${iter}.mdl} $dir || exit 1;


## Set up features.  Note: these are different from the normal features
## because we have one rspecifier that has the features for the entire
## training set, not separate ones for each batch.
if [ -z "$feat_type" ]; then
  if [ -f $srcdir/final.mat ]; then feat_type=lda; else feat_type=raw; fi
fi
echo "$0: feature type is $feat_type"

norm_vars=`cat $srcdir/norm_vars 2>/dev/null` || norm_vars=false # cmn/cmvn option, default false.
cp $srcdir/norm_vars $dir 2>/dev/null

case $feat_type in
  raw) feats="ark,s,cs:apply-cmvn --norm-vars=$norm_vars --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- |"
   ;;
  lda) 
    splice_opts=`cat $srcdir/splice_opts 2>/dev/null`
    cp $srcdir/splice_opts $dir 2>/dev/null
    cp $srcdir/final.mat $dir || exit 1;
    feats="ark,s,cs:apply-cmvn --norm-vars=$norm_vars --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- | splice-feats $splice_opts ark:- ark:- | transform-feats $dir/final.mat ark:- ark:- |"
    ;;
  *) echo "$0: invalid feature type $feat_type" && exit 1;
esac
if [ ! -z "$transform_dir" ]; then
  if ! [ $nj -eq `cat $transform_dir/num_jobs` ]; then
    echo "$0: Number of jobs mismatch with transform-dir: $nj versus `cat $transform_dir/num_jobs`";
    exit 1;
  fi
  if [ $feat_type == "lda" ]; then
    [ ! -f $transform_dir/trans.1 ] && echo "No such file $transform_dir/raw_trans.1" && exit 1;
    echo "$0: using transforms from $transform_dir"
    feats="$feats transform-feats --utt2spk=ark:$sdata/JOB/utt2spk ark:$transform_dir/trans.JOB ark:- ark:- |"
  fi
  if [ $feat_type == "raw" ]; then
    [ ! -f $transform_dir/raw_trans.1 ] && echo "No such file $transform_dir/raw_trans.1" && exit 1;
    echo "$0: using raw-fMLLR transforms from $transform_dir"
    feats="$feats transform-feats --utt2spk=ark:$sdata/JOB/utt2spk ark:$transform_dir/raw_trans.JOB ark:- ark:- |"
  fi
fi


echo "$0: aligning data in $data using model from $srcdir, putting alignments in $dir"

tra="ark:utils/sym2int.pl --map-oov $oov -f 2- $lang/words.txt $sdata/JOB/text|";

$cmd JOB=1:$nj $dir/log/align.JOB.log \
  compile-train-graphs $dir/tree $srcdir/${iter}.mdl  $lang/L.fst "$tra" ark:- \| \
  nnet-align-compiled $scale_opts --use-gpu=$use_gpu --beam=$beam --retry-beam=$retry_beam \
    $srcdir/${iter}.mdl ark:- "$feats" "ark:|gzip -c >$dir/ali.JOB.gz" || exit 1;

echo "$0: done aligning data."

