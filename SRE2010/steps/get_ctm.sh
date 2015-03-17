#!/bin/bash
# Copyright Johns Hopkins University (Author: Daniel Povey) 2012.  Apache 2.0.

# This script produces CTM files from a decoding directory that has lattices
# present.


# begin configuration section.
cmd=run.pl
stage=0
use_segments=true # if we have a segments file, use it to convert
                  # the segments to be relative to the original files.
#end configuration section.

[ -f ./path.sh ] && . ./path.sh
. parse_options.sh || exit 1;

if [ $# -ne 3 ]; then
  echo "Usage: local/get_ctm.sh [options] <data-dir> <lang-dir|graph-dir> <decode-dir>"
  echo " Options:"
  echo "    --cmd (run.pl|queue.pl...)      # specify how to run the sub-processes."
  echo "    --stage (0|1|2)                 # start scoring script from part-way through."
  echo "    --use-segments (true|false)     # use segments and reco2file_and_channel files "
  echo "                                    # to produce a ctm relative to the original audio"
  echo "                                    # files, with channel information (typically needed"
  echo "                                    # for NIST scoring)."
  echo "e.g.:"
  echo "local/get_ctm.sh data/train data/lang exp/tri4a/decode/"
  exit 1;
fi

data=$1
lang=$2 # Note: may be graph directory not lang directory, but has the necessary stuff copied.
dir=$3

model=$dir/../final.mdl # assume model one level up from decoding dir.


for f in $lang/words.txt $lang/phones/word_boundary.int \
     $model $dir/lat.1.gz; do
  [ ! -f $f ] && echo "$0: expecting file $f to exist" && exit 1;
done

name=`basename $data`; # e.g. eval2000

mkdir -p $dir/scoring/log

if [ $stage -le 0 ]; then
  if [ -f $data/segments ]; then
    f=$data/reco2file_and_channel
    [ ! -f $f ] && echo "$0: expecting file $f to exist" && exit 1;
    filter_cmd="utils/convert_ctm.pl $data/segments $data/reco2file_and_channel"
  else
    filter_cmd=cat    
  fi

  $cmd LMWT=5:20 $dir/scoring/log/get_ctm.LMWT.log \
    mkdir -p $dir/score_LMWT/ '&&' \
    lattice-1best --lm-scale=LMWT "ark:gunzip -c $dir/lat.*.gz|" ark:- \| \
    lattice-align-words $lang/phones/word_boundary.int $model ark:- ark:- \| \
    nbest-to-ctm ark:- - \| \
    utils/int2sym.pl -f 5 $lang/words.txt \| \
    $filter_cmd '>' $dir/score_LMWT/$name.ctm || exit 1;
fi


