#!/usr/bin/env bash

n=$1 corpus=$2; attr=${3:-word}

for ((n=1; n<=$n; n++)); do i=$(( n - 1 ))
  cwb-scan-corpus -q -C $corpus $(eval echo "word+"{0..$i}"") \
    | sed 's/\t/ /2g' | sort -nr -k1 -T . > ${corpus}_${n}grams
done
