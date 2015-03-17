#!/bin/bash

format=pdf # pdf svg
mode=display # display save

. utils/parse_options.sh

if [ $# != 3 ]; then
   echo "usage: $0 [--mode display|save] [--format pdf|svg] <utt-id> <lattice-ark> <word-list>"
   echo "e.g.:  $0 utt-0001 \"test/lat.*.gz\" tri1/graph/words.txt"
   exit 1;
fi

. path.sh

uttid=$1
lat=$2
words=$3

tmpdir=$(mktemp -d); # trap "rm -r $tmpdir" EXIT # cleanup

gunzip -c $lat | lattice-to-fst ark:- ark,scp:$tmpdir/fst.ark,$tmpdir/fst.scp || exit 1
! grep "^$uttid " $tmpdir/fst.scp && echo "ERROR : Missing utterance '$uttid' from gzipped lattice ark '$lat'" && exit 1
fstcopy "scp:grep '^$uttid ' $tmpdir/fst.scp |" "scp:echo $uttid $tmpdir/$uttid.fst |" || exit 1
fstdraw --portrait=true --osymbols=$words $tmpdir/$uttid.fst | dot -T${format} > $tmpdir/$uttid.${format}

if [ "$(uname)" == "Darwin" ]; then
    doc_open=open
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    doc_open=xdg-open
elif [ $mode == "display" ] ; then
        echo "Can not automaticly open file on your operating system"
        mode=save
fi

[ $mode == "display" ] && $doc_open $tmpdir/$uttid.${format}
[[ $mode == "display" && $? -ne 0 ]] && echo "Failed to open ${format} format." && mode=save
[ $mode == "save" ] && echo "Saving to $uttid.${format}" && cp $tmpdir/$uttid.${format} .

exit 0
