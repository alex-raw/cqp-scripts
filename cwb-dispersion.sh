#!/usr/bin/env bash
set -uo pipefail
set -x

corpus=$1
p_attr=$2
s_attr=$3

abs_path() { echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")" ; }
[ ${4:-} ] && freq_list=$(abs_path ${4:-})

tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
# cd "${tmp}"

# Prevent whitespace to separate fields
awk_cmd() {
  mawk \
    -v FS='\t' \
    -v OFS='\t' \
    -v OFMT="%.15f" \
    "$@"
}

# original: # DP=0.5 * sum(abs(v[i]/f-s[i]))
# less heavy variation: 0.5 * sum(abs(..v[i]>1../f - s[i])) + sum(..v[i] == 0..)
inner() { awk_cmd '{print ($1 / $2) - $3}' | sed 's/^-//g' ; }
outer() { awk_cmd '{print $1, ($2 + $3) / 2}' ; }
sum_by_key() { awk_cmd '{x[$1] += $2} END {for (i in x) print i, x[i]}' ; }
normalize() { awk_cmd -v min_s=$1 \
  'BEGIN {OFMT="%.8f"}  {print $1, $2 / 1 - min_s}'
}

# get frequencies of tokens in parts: v
# -C option would be great, but filters most s-attributes
if [ -z ${freq_list:-} ]; then
  cwb-scan-corpus -o freq_list "$corpus" "$p_attr" "$s_attr"
  freq_list="freq_list"
fi

# TODO: case-fold here

# s = n_part / n; +1 due to 0-indexing;
cwb-s-decode "$corpus" -S "$s_attr" \
  | awk_cmd -v n=$(cwb-lexdecode -S "$corpus" | sed -n '1s/[^0-9]//gp') \
      '{ x[$3] += $2-$1+1} END {for (i in x) print i, x[i] / n }' \
  | sort -T . > parts
min_s=$(cut -f2 parts | sort -n | head -1)
# FIXME: strange bug: exits after head -1 when set -e, without error displayed
# but only with some input

# sort for join; using buffer file piping directly into sort is 20% slower
# Replace with cwb-scan-corpus -S in newer versions of CWB
sort -T . -t $'\t' -k3 "${freq_list}" > freqs_sort
join -t $'\t' -1 3 -o 2.2 freqs_sort parts > parts_perc &
awk_cmd '{ print $1 > "freqs"
           print $2 > "vocab"}' freqs_sort

# sum parts_perc where token doesn't exist
paste vocab parts_perc | sum_by_key \
  | awk_cmd '{print 1 - $2}' > not_parts_perc &

# annotate corpus frequencies f
cwb-lexdecode -f -P "$p_attr" -F vocab "$corpus" | awk '{print $1}' \
  | paste freqs - parts_perc | inner \
  | paste vocab - | sum_by_key \
  | paste - not_parts_perc | outer \
  | normalize "${min_s}" | sort -T . -t $'\t' -n -k2
# drop awk print $1 with newer version for cwb-lexdecode -b
