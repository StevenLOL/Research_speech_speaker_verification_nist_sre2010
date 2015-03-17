#!/bin/bash
# Copyright 2012  Johns Hopkins University (Author: Daniel Povey).  Apache 2.0.

# Create denominator lattices for MMI/MPE training, with SGMM models.  If the
# features have fMLLR transforms you have to supply the --transform-dir option.
# It gets any speaker vectors from the "alignment dir" ($alidir).  Note: this is
# possibly a slight mismatch because the speaker vectors come from supervised
# adaptation.

# Begin configuration section.
nj=4
cmd=run.pl
sub_split=1
beam=13.0
lattice_beam=7.0
acwt=0.1
max_active=5000
transform_dir=
max_mem=20000000 # This will stop the processes getting too large.
# End configuration section.

echo "$0 $@"  # Print the command line for logging

[ -f ./path.sh ] && . ./path.sh; # source the path.
. parse_options.sh || exit 1;

if [ $# != 4 ]; then
   echo "Usage: steps/make_denlats_sgmm.sh [options] <data-dir> <lang-dir> <src-dir|alidir> <exp-dir>"
   echo "  e.g.: steps/make_denlats_sgmm.sh data/train data/lang exp/sgmm4a_ali exp/sgmm4a_denlats"
   echo "Works for (delta|lda) features, and (with --transform-dir option) such features"
   echo " plus transforms."
   echo ""
   echo "Main options (for others, see top of script file)"
   echo "  --config <config-file>                           # config containing options"
   echo "  --nj <nj>                                        # number of parallel jobs"
   echo "  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs."
   echo "  --sub-split <n-split>                            # e.g. 40; use this for "
   echo "                           # large databases so your jobs will be smaller and"
   echo "                           # will (individually) finish reasonably soon."
   echo "  --transform-dir <transform-dir>   # directory to find fMLLR transforms."
   exit 1;
fi

data=$1
lang=$2
alidir=$3 # could also be $srcdir, but only if no vectors supplied.
dir=$4

sdata=$data/split$nj
splice_opts=`cat $alidir/splice_opts 2>/dev/null`
norm_vars=`cat $srcdir/norm_vars 2>/dev/null` || norm_vars=false # cmn/cmvn option, default false.
mkdir -p $dir/log
[[ -d $sdata && $data/feats.scp -ot $sdata ]] || split_data.sh $data $nj || exit 1;
echo $nj > $dir/num_jobs

oov=`cat $lang/oov.int` || exit 1;

mkdir -p $dir

cp -r $lang $dir/

# Compute grammar FST which corresponds to unigram decoding graph.
new_lang="$dir/"$(basename "$lang")
echo "Making unigram grammar FST in $new_lang"
cat $data/text | utils/sym2int.pl --map-oov $oov -f 2- $lang/words.txt | \
  awk '{for(n=2;n<=NF;n++){ printf("%s ", $n); } printf("\n"); }' | \
  utils/make_unigram_grammar.pl | fstcompile > $new_lang/G.fst \
   || exit 1;

# mkgraph.sh expects a whole directory "lang", so put everything in one directory...
# it gets L_disambig.fst and G.fst (among other things) from $dir/lang, and
# final.mdl from $alidir; the output HCLG.fst goes in $dir/graph.

echo "Compiling decoding graph in $dir/dengraph"
if [ -s $dir/dengraph/HCLG.fst ] && [ $dir/dengraph/HCLG.fst -nt $srcdir/final.mdl ]; then
   echo "Graph $dir/dengraph/HCLG.fst already exists: skipping graph creation."
else
  utils/mkgraph.sh $new_lang $alidir $dir/dengraph || exit 1;
fi

if [ -f $alidir/final.mat ]; then feat_type=lda; else feat_type=delta; fi
echo "align_si.sh: feature type is $feat_type"

case $feat_type in
  delta) feats="ark,s,cs:apply-cmvn --norm-vars=$norm_vars --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- | add-deltas ark:- ark:- |";;
  lda) feats="ark,s,cs:apply-cmvn --norm-vars=$norm_vars --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- | splice-feats $splice_opts ark:- ark:- | transform-feats $alidir/final.mat ark:- ark:- |"
    cp $alidir/final.mat $dir    
   ;;
  *) echo "Invalid feature type $feat_type" && exit 1;
esac

if [ ! -z "$transform_dir" ]; then # add transforms to features...
  echo "$0: using fMLLR transforms from $transform_dir"
  [ ! -f $transform_dir/trans.1 ] && echo "Expected $transform_dir/trans.1 to exist."
  [ "`cat $transform_dir/num_jobs`" -ne "$nj" ] \
    && echo "$0: mismatch in number of jobs with $transform_dir" && exit 1;
  [ -f $alidir/final.mat ] && ! cmp $transform_dir/final.mat $alidir/final.mat && \
     echo "$0: LDA transforms differ between $alidir and $transform_dir"
  feats="$feats transform-feats --utt2spk=ark:$sdata/JOB/utt2spk ark:$transform_dir/trans.JOB ark:- ark:- |"
else
  echo "Assuming you don't have a SAT system, since no --transform-dir option supplied "
fi

if [ -f $alidir/gselect.1.gz ]; then
  gselect_opt="--gselect=ark,s,cs:gunzip -c $alidir/gselect.JOB.gz|"
else
  echo "$0: no such file $alidir/gselect.1.gz" && exit 1;
fi

if [ -f $alidir/vecs.1 ]; then
  spkvecs_opt="--spk-vecs=ark:$alidir/vecs.JOB --utt2spk=ark:$sdata/JOB/utt2spk"
else
  if [ -f $alidir/final.alimdl ]; then
    echo "You seem to have an SGMM system with speaker vectors,"
    echo "yet we can't find speaker vectors.  Perhaps you supplied"
    echo "the model director instead of the alignment directory?"
    exit 1;
  fi
fi

if [ $sub_split -eq 1 ]; then 
  $cmd JOB=1:$nj $dir/log/decode_den.JOB.log \
   sgmm-latgen-faster $spkvecs_opt "$gselect_opt" --beam=$beam \
     --lattice-beam=$lattice_beam --acoustic-scale=$acwt \
     --max-mem=$max_mem --max-active=$max_active --word-symbol-table=$lang/words.txt $alidir/final.mdl  \
     $dir/dengraph/HCLG.fst "$feats" "ark:|gzip -c >$dir/lat.JOB.gz" || exit 1;
else
  for n in `seq $nj`; do
    if [ -f $dir/.done.$n ] && [ $dir/.done.$n -nt $alidir/final.mdl ]; then
      echo "Not processing subset $n as already done (delete $dir/.done.$n if not)";
    else 
      sdata2=$data/split$nj/$n/split$sub_split;
      if [ ! -d $sdata2 ] || [ $sdata2 -ot $sdata/$n/feats.scp ]; then
        split_data.sh --per-utt $sdata/$n $sub_split || exit 1;
      fi
      mkdir -p $dir/log/$n
      mkdir -p $dir/part
      feats_subset=`echo $feats | sed "s/trans.JOB/trans.$n/g" | sed s:JOB/:$n/split$sub_split/JOB/:g`
      spkvecs_opt_subset=`echo $spkvecs_opt | sed "s/JOB/$n/g"`
      gselect_opt_subset=`echo $gselect_opt | sed "s/JOB/$n/g"`
      $cmd JOB=1:$sub_split $dir/log/$n/decode_den.JOB.log \
        sgmm-latgen-faster $spkvecs_opt_subset "$gselect_opt_subset" \
          --beam=$beam --lattice-beam=$lattice_beam \
          --acoustic-scale=$acwt --max-mem=$max_mem --max-active=$max_active \
          --word-symbol-table=$lang/words.txt $alidir/final.mdl  \
          $dir/dengraph/HCLG.fst "$feats_subset" "ark:|gzip -c >$dir/lat.$n.JOB.gz" || exit 1;
      echo Merging archives for data subset $n
      rm $dir/.error 2>/dev/null;
      for k in `seq $sub_split`; do
        gunzip -c $dir/lat.$n.$k.gz || touch $dir/.error;
      done | gzip -c > $dir/lat.$n.gz || touch $dir/.error;
      [ -f $dir/.error ] && echo Merging lattices for subset $n failed && exit 1;
      rm $dir/lat.$n.*.gz
      touch $dir/.done.$n
    fi
  done
fi


echo "$0: done generating denominator lattices with SGMMs."
