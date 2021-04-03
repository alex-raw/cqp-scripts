#!/usr/bin/env bash
# -c case_fold; -0 include non-occurring

# tmp="$(mktemp -d)"
# trap 'rm -rf -- "$tmp"' EXIT
# cd $tmp

corpus=${1:-COCA-S}; attr=${2:-word}

# make sure awk consistently reads and outputs tab separated columns
awk_cmd() { awk -v OFS='\t' "$@" ; }

# ignore case: convert everything to lower case and add together counts
fold() {
  awk_cmd '{ f[tolower($2)] += $1} END {for (tok in f) print f[tok], f }'
}

 # -b option after 3.5 for formatting instead of awk
raw() { cwb-lexdecode -f -P $2 $1 | awk_cmd '{print $1, $2}' ; }
raw_case() { cwb-lexdecode -f -P $2 $1 | fold ; }

clean() { cwb-scan-corpus -q -C $1 $2 ; }
clean_case() { cwb-scan-corpus -q -C $1 $2 | fold ; }

# join tab separated files with the key in the second column (token)
# if with_0: keep all keys from file one and print 0 if no match
# input needs to be sorted for join
join_freqs() {
  [ "$3" = "with_0" ] && with_zero="-a 1 -e 0 -o auto"
  join -t $'\t' -j 2 ${with_zero:-} <(sort -k2 $1) <(sort -k2 $2)
}

count() {
cqp -c <<:
$corpus;
"the"%c;
count by word on match[1] > "freqs";
# tabulate Last match[1]..matchend[-1] word > "table";
:
}

# annotate token list with p-attribute frequencies without constraints
simple() {
  awk '{ print $1 > "n" ; print $2 }' $1 \
    | cwb-lexdecode -f -F - -P $attr $corpus \
    | awk_cmd '{print $2, $1}' > N
  paste N n
}

# same but include missing tokens
simple_0() {
  raw $corpus $attr | join_freqs - $1
}

count
simple freqs

# TODO: cwb-lexdecode joins don't work on case-sensitive stuff

# # annotate word lists with arbitrary P-attribute constraints
# # 1. prepare word list
# cqp -c <<-:
# $corpus; define wordlist < ""
# :

# attr="word"
# corpus="COCA-S"

# raw "${corpus}" "${attr}" > bnc_raw
# raw "${corpus}" "${attr}" | fold > bnc_raw_case
# clean "${corpus}" "${attr}" > bnc_clean
# clean "${corpus}" "${attr}" | fold > bnc_clean_case

# From 3.5 documentation of cwb-scan-corpus
# > "Cleanup" means that any token values that are not "regular" words will be omitted.
# > A regular word consists only of one or more hyphen-connected components,
# > each of which is made up of either all letters or all digits,
# > and does not start or end with a hyphen.
