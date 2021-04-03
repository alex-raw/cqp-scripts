#!/usr/bin/env sh

corpus=$1; attr=$2

# for entire corpus
cwb-decode -C "$corpus" -P "$attr" \
  | mawk -v FS='\t' -v OFS='\t' \ '
NR==1 {print $1, $2, 1; next}
{print $1, $2, NR - x[$1]; x[$1] = NR}
'

# for subsets/query results
# awk 'NR==1 {print $1, 0; next} {print $1, $2 - x[$1]; x[$1] = $2}'
