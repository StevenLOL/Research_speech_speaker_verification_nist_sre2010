#!/bin/bash
# Copyright 2013 Karel Vesely

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED
# WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
# MERCHANTABLITY OR NON-INFRINGEMENT.
# See the Apache 2 License for the specific language governing permissions and
# limitations under the License.

# To be run from ..
#
# Deep Belief Network pre-training by Contrastive Divergence (CD-1) algorithm.
# The script can pre-train on plain features (ie. saved fMLLR features), 
# or modified features (CMN, delta).
# The script creates feature-transform in nnet format, which contains splice 
# and shift+scale (zero mean and unit variance on DBN input).
#
# For special cases it is possible to use external feature-transform.
# 

# Begin configuration.
#
# nnet config
nn_depth=6     #number of hidden layers
hid_dim=2048   #number of units per layer
param_stddev_first=0.1 #init parameters in 1st RBM
param_stddev=0.1 #init parameters in other RBMs
# number of iterations
rbm_iter=1            #number of pre-training epochs (Gaussian-Bernoulli RBM has 2x more)
rbm_drop_data=0.0     #sample the training set, 1.0 drops all the data, 0.0 keeps all
# pre-training opts
rbm_lrate=0.4         #RBM learning rate
rbm_lrate_low=0.01    #lower RBM learning rate (for Gaussian units)
rbm_l2penalty=0.0002  #L2 penalty (increases RBM-mixing rate)
rbm_extra_opts=
# data processing config
copy_feats=true    # resave the features randomized consecutively to tmpdir
# feature config
feature_transform= # Optionally reuse feature processing front-end (override splice,etc.)
feature_transform_proto= # Optionally pass prototype of feature transform
delta_order=       # Optionally use deltas on the input features
apply_cmvn=false   # Optionally do CMVN of the input features
norm_vars=false    # When apply_cmvn=true, this enables CVN
splice=5           # Temporal splicing
splice_step=1      # Stepsize of the splicing (1 is consecutive splice, 
                   # value 2 would do [ -10 -8 -6 -4 -2 0 2 4 6 8 10 ] splicing)
# misc.
verbose=1 # enable per-cache reports
# End configuration.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh;
. parse_options.sh || exit 1;


if [ $# != 2 ]; then
   echo "Usage: $0 <data> <exp-dir>"
   echo " e.g.: $0 data/train exp/rbm_pretrain"
   echo "main options (for others, see top of script file)"
   echo "  --config <config-file>           # config containing options"
   echo ""
   echo "  --nn-depth <N>                   # number of RBM layers"
   echo "  --hid-dim <N>                    # number of hidden units per layer"
   echo "  --rbm-iter <N>                   # number of CD-1 iterations per layer"
   echo "  --dbm-drop-data <float>          # probability of frame-dropping,"
   echo "                                   # can be used to subsample large datasets"
   echo "  --rbm-lrate <float>              # learning-rate for Bernoulli-Bernoulli RBMs"
   echo "  --rbm-lrate-low <float>          # learning-rate for Gaussian-Bernoulli RBM"
   echo ""
   echo "  --copy-feats <bool>              # copy features to /tmp, to accelerate training"
   echo "  --apply-cmvn <bool>              # normalize input features (opt.)"
   echo "    --norm-vars <bool>               # use variance normalization (opt.)"
   echo "  --splice <N>                     # splice +/-N frames of input features"
   exit 1;
fi

data=$1
dir=$2


for f in $data/feats.scp; do
  [ ! -f $f ] && echo "$0: no such file $f" && exit 1;
done

echo "# INFO"
echo "$0 : Pre-training Deep Belief Network as a stack of RBMs"
printf "\t dir       : $dir \n"
printf "\t Train-set : $data \n"

[ -e $dir/${nn_depth}.dbn ] && echo "$0 Skipping, already have $dir/${nn_depth}.dbn" && exit 0

mkdir -p $dir/log

###### PREPARE FEATURES ######
echo
echo "# PREPARING FEATURES"
# shuffle the list
echo "Preparing train/cv lists"
cat $data/feats.scp | utils/shuffle_list.pl --srand ${seed:-777} > $dir/train.scp
# print the list size
wc -l $dir/train.scp

#re-save the shuffled features, so they are stored sequentially on the disk in /tmp/
if [ "$copy_feats" == "true" ]; then
  tmpdir=$(mktemp -d); mv $dir/train.scp $dir/train.scp_non_local
  utils/nnet/copy_feats.sh $dir/train.scp_non_local $tmpdir $dir/train.scp
  #remove data on exit...
  trap "echo \"Removing features tmpdir $tmpdir @ $(hostname)\"; rm -r $tmpdir" EXIT
fi

#create a 10k utt subset for global cmvn estimates
head -n 10000 $dir/train.scp > $dir/train.scp.10k



###### PREPARE FEATURE PIPELINE ######

#read the features
feats="ark:copy-feats scp:$dir/train.scp ark:- |"

#optionally add per-speaker CMVN
if [ $apply_cmvn == "true" ]; then
  echo "Will use CMVN statistics : $data/cmvn.scp"
  [ ! -r $data/cmvn.scp ] && echo "Cannot find cmvn stats $data/cmvn.scp" && exit 1;
  cmvn="scp:$data/cmvn.scp"
  feats="$feats apply-cmvn --print-args=false --norm-vars=$norm_vars --utt2spk=ark:$data/utt2spk $cmvn ark:- ark:- |"
  # keep track of norm_vars option
  echo "$norm_vars" >$dir/norm_vars 
else
  echo "apply_cmvn disabled (per speaker norm. on input features)"
fi

#optionally add deltas
if [ "$delta_order" != "" ]; then
  feats="$feats add-deltas --delta-order=$delta_order ark:- ark:- |"
  echo "$delta_order" > $dir/delta_order
fi

#get feature dim
echo -n "Getting feature dim : "
feat_dim=$(feat-to-dim --print-args=false scp:$dir/train.scp -)
echo $feat_dim


# Now we will start building feature_transform which will 
# be applied in CUDA to gain more speed.
#
# We will use 1GPU for both feature_transform and MLP training in one binary tool. 
# This is against the kaldi spirit, but it is necessary, because on some sites a GPU 
# cannot be shared accross by two or more processes (compute exclusive mode),
# and we would like to use single GPU per training instance,
# so that the grid resources can be used efficiently...


if [ ! -z "$feature_transform" ]; then
  echo Using already prepared feature_transform: $feature_transform
  cp $feature_transform $dir/final.feature_transform
else
  if [ ! -z "$feature_transform_proto" ]; then
    feature_transform=$dir/tr_$(basename $feature_transform_proto)
    log=$dir/log/feature-transform-initialize.log
    nnet-initialize --binary=false $feature_transform_proto $feature_transform 2>$log || { cat $log; exit 1; }
  else
    # Generate the splice transform
    echo "Using splice +/- $splice , step $splice_step"
    feature_transform=$dir/tr_splice$splice-$splice_step.nnet
    utils/nnet/gen_splice.py --fea-dim=$feat_dim --splice=$splice --splice-step=$splice_step > $feature_transform
  fi

  # Renormalize the MLP input to zero mean and unit variance
  feature_transform_old=$feature_transform
  feature_transform=${feature_transform%.nnet}_cmvn-g.nnet
  echo "Renormalizing MLP input features into $feature_transform"
  nnet-forward --use-gpu=yes \
    $feature_transform_old "$(echo $feats | sed 's|train.scp|train.scp.10k|')" \
    ark:- 2>$dir/log/cmvn_glob_fwd.log |\
  compute-cmvn-stats ark:- - | cmvn-to-nnet - - |\
  nnet-concat --binary=false $feature_transform_old - $feature_transform

  # MAKE LINK TO THE FINAL feature_transform, so the other scripts will find it ######
  [ -f $dir/final.feature_transform ] && unlink $dir/final.feature_transform
  (cd $dir; ln -s $(basename $feature_transform) final.feature_transform )
fi



###### GET THE DIMENSIONS ######
num_fea=$(feat-to-dim --print-args=false "$feats nnet-forward --use-gpu=no $feature_transform ark:- ark:- |" - 2>/dev/null)
num_hid=$hid_dim


###### PERFORM THE PRE-TRAINING ######
for depth in $(seq 1 $nn_depth); do
  echo
  echo "# PRE-TRAINING RBM LAYER $depth"
  RBM=$dir/$depth.rbm
  [ -f $RBM ] && echo "RBM '$RBM' already trained, skipping." && continue

  #The first RBM needs special treatment, because of Gussian input nodes
  if [ "$depth" == "1" ]; then
    #This is Gaussian-Bernoulli RBM
    #initialize
    echo "Initializing '$RBM.init'"
    echo "<NnetProto>
    <Rbm> <InputDim> $num_fea <OutputDim> $num_hid <VisibleType> gauss <HiddenType> bern <ParamStddev> $param_stddev_first
    </NnetProto>
    " > $RBM.proto
    nnet-initialize $RBM.proto $RBM.init 2>$dir/log/nnet-initialize.$depth.log || exit 1
    #pre-train
    echo "Pretraining '$RBM' (reduced lrate and 2x more iters)"
    rbm-train-cd1-frmshuff --learn-rate=$rbm_lrate_low --l2-penalty=$rbm_l2penalty \
      --num-iters=$((2*$rbm_iter)) --drop-data=$rbm_drop_data --verbose=$verbose \
      --feature-transform=$feature_transform \
      $rbm_extra_opts \
      $RBM.init "$feats" $RBM 2>$dir/log/rbm.$depth.log || exit 1
  else
    #This is Bernoulli-Bernoulli RBM
    #cmvn stats for init
    echo "Computing cmvn stats '$dir/$depth.cmvn' for RBM initialization"
    if [ ! -f $dir/$depth.cmvn ]; then 
      nnet-forward --use-gpu=yes \
       "nnet-concat $feature_transform $dir/$((depth-1)).dbn - |" \
        "$(echo $feats | sed 's|train.scp|train.scp.10k|')" \
        ark:- 2>$dir/log/cmvn_fwd.$depth.log | \
      compute-cmvn-stats ark:- - 2>$dir/log/cmvn.$depth.log | \
      cmvn-to-nnet - $dir/$depth.cmvn || exit 1
    else
      echo compute-cmvn-stats already done, skipping.
    fi
    #initialize
    echo "Initializing '$RBM.init'"
    echo "<NnetProto>
    <Rbm> <InputDim> $num_hid <OutputDim> $num_hid <VisibleType> bern <HiddenType> bern <ParamStddev> $param_stddev <VisibleBiasCmvnFilename> $dir/$depth.cmvn
    </NnetProto>
    " > $RBM.proto
    nnet-initialize $RBM.proto $RBM.init 2>$dir/log/nnet-initialize.$depth.log || exit 1
    #pre-train
    echo "Pretraining '$RBM'"
    rbm-train-cd1-frmshuff --learn-rate=$rbm_lrate --l2-penalty=$rbm_l2penalty \
      --num-iters=$rbm_iter --drop-data=$rbm_drop_data --verbose=$verbose \
      --feature-transform="nnet-concat $feature_transform $dir/$((depth-1)).dbn - |" \
      $rbm_extra_opts \
      $RBM.init "$feats" $RBM 2>$dir/log/rbm.$depth.log || exit 1
  fi

  #Create DBN stack
  if [ "$depth" == "1" ]; then
    rbm-convert-to-nnet --binary=true $RBM $dir/$depth.dbn
  else 
    rbm-convert-to-nnet --binary=true $RBM - | \
    nnet-concat $dir/$((depth-1)).dbn - $dir/$depth.dbn
  fi

done

echo
echo "# REPORT"
echo "# RBM pre-training progress (line per-layer)"
grep progress $dir/log/rbm.*.log
echo 

echo "Pre-training finished."

sleep 3
exit 0
