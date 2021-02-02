#!/usr/bin/env bash

tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
cd $tmp

corpus=$1; p_attr=$2; s_attr=$3

# -C option would be great, but filters most s-attributes
cwb-scan-corpus -o freq_list "$corpus" "$p_attr" "$s_attr"

# sort for join; using buffer file piping directly into sort is 20% slower
sort -k3 freq_list > freqs_sort
cut -f1 freqs_sort > freqs &
cut -f2 freqs_sort > vocab &

n="$(cwb-lexdecode -S "$corpus" | sed -n '1s/[^0-9]//gp')"
cwb-s-decode "$corpus" -S "$s_attr" | awk -v n=$n '{print ($2-$1+1) / n, $3}' \
  | sort -k2 | join -1 3 -2 2 -o 2.1 freqs_sort - > parts_perc

rm freqs_sort freq_list &

sum_by_key() {
  awk '{arr[$1] += $2} END {for (i in arr) print i,arr[i]}'
}

paste vocab parts_perc | sum_by_key \
  | awk '{print 1 - $2}' > not_parts_perc &

cwb-lexdecode -f0 -P "$p_attr" -F vocab "$corpus" | awk '{print $1}' \
  | paste freqs - parts_perc | awk '{print ($1 / $2) - $3}' | sed 's/^-//g' \
  | paste vocab - | sum_by_key \
  | paste - not_parts_perc | awk '{print $1, ($2 + $3) / 2}' \
  | sort -n -k2

# # split into one file per part
# sort -k3 corp | awk '!($3 in arr) {arr[$3]=++i} {print $2, $1 > ("part_" $3)}'
