#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
# cd $tmp

corpus=$1; p_attr=$2; s_attr=$3
n="$(cwb-lexdecode -S "$corpus" | sed -n '1s/[^0-9]//gp')"

# original: # 0.5 * sum(abs(v[i]/f-s[i]))=DP
# less heavy variation: 0.5 * sum(abs(..v[i]>1../f - s[i])) + sum(..v[i] == 0..)
inner() { awk '{print ($1 / $2) - $3}' | sed 's/^-//g' ; }
sum_by_key() { awk '{x[$1] += $2} END {for (i in x) print i,x[i]}' ; }
outer() { awk '{print $1, ($2 + $3) / 2}' ; }

# TODO: make an -f option to provide a preprocessed frequency list
# get frequencies of tokens in parts: v
# -C option would be great, but filters most s-attributes
cwb-scan-corpus -o freq_list "$corpus" "$p_attr" "$s_attr"

# sort for join; using buffer file piping directly into sort is 20% slower
sort -k3 freq_list > freqs_sort
cut -f1 freqs_sort > freqs &
cut -f2 freqs_sort > vocab &
rm freq_list &

# s = n_part / n; +1 due to 0-indexing; \ annotate list with s
cwb-s-decode "$corpus" -S "$s_attr" \
  | awk -v n=$n '{x[$3] += $2-$1+1} END {for (i in x) print x[i] / n, i}' \
  | sort -k2 | join -1 3 -2 2 -o 2.1 freqs_sort - > parts_perc
rm freqs_sort &

# sum parts_perc where token doesn't exist
paste vocab parts_perc | sum_by_key | awk '{print 1 - $2}' > not_parts_perc &

# annotate corpus frequencies f
# add values from parts without token
cwb-lexdecode -f0 -P "$p_attr" -F vocab "$corpus" | awk '{print $1}' \
  | paste freqs - parts_perc | inner | paste vocab - | sum_by_key \
  | paste - not_parts_perc | outer | sort -n -k2

# # split into one file per part
# sort -k3 corp | awk '!($3 in arr) {arr[$3]=++i} {print $2, $1 > ("part_" $3)}'
