#!/usr/bin/env bash

data=$1
awk_cmd() { awk -M -v PREC="double" -v OFMT="%.6f" -v OFS="\t" "$@" ; }

obs_exp() {
  # $1=[token] $2=[f_corpus] $3=[f_coll*]
  awk_cmd 'NR==FNR { N += $2; n += $3; next }        # sums
    { print $3,         $2 - $3,                     # O11=$1, O12=$2
      n - $3,           N - ($2 - $3 + n),           # O21=$3, O22=$4
      $2 * n / N,       $2 * ($3 + $3 + N - n) / N,  # E11=$5, E12=$6
      (N - $2) * n / N, (N - $2) * (N - n) / N       # E21=$7, E22=$8
    }' $1 $1
}

logl() {
  for i in 1 2 3 4; do
    awk_cmd -v O=$i 'E=O+4 { print $O * log($O/$E) }' $1 > tmp_$i &
  done; wait
  paste tmp_* | awk_cmd '{ print ($1+$2+$3+$4) * 2 }'
}

obs_exp $data > tmp_O_E
printf "TOKEN\tF_CORP\tF_COLL\tEXP\tLOGLIKELIHOOD\n"
logl tmp_O_E | paste $data <(cut -f5 tmp_O_E) - \
  | awk_cmd '{ print $1,$2,$3,$4, ($4>$3) ? -$5 : $5 }' | sort -nr -k5

rm tmp*

# corpus="LOB"
# attr="lemma"

# cqp_query() {
# cqp -c <<-:
#   $corpus; set pp off;
#   N=[class = "VERB"];
#   CXN=[$attr = "begin" & class = "VERB"] [$attr = "to"] [pos = "v.i"%c];
#   group N match $attr > "$1";
#   group CXN matchend $attr > "$2";
#   size N; size CXN;
# :
# }

# join_freqs() { join -t $'\t' -a1 -e0 -o 1.1,1.2,2.2 <(sort $1) <(sort $2); }

# fold() {
#   awk_cmd 'BEGIN { OFS = "\t" } { a[tolower($1)] += $2 }
#              END { for (i in a) print i, a[i] }' $1
# }

# sizes=( $(cqp_query corp cxn | sed '1d') )
# join_freqs <(fold corp) <(fold cxn) > table

# obs() {
#   # [token] [f_corpus] [f_coll*]
#   awk_cmd -v n=$1 -v cxn=$2 '{ print \
#     $3,       $2-$3,             # O11=$1, O12=$2
#     cxn - $3, n - ($2-$3 + cxn)  # O21=$3, O22=$4
#     }' $3
# }

# exp() {
#   awk_cmd -v n=$1 '{ print $0,                     # OBS={1..4}
#     ($1+$2) * ($1+$3) / n, ($1+$2) * ($2+$4) / n,  # E11=$5, E12=$6
#     ($3+$4) * ($1+$3) / n, ($3+$4) * ($2+$4) / n   # E21=$7, E22=$8
#     }' $2
# }

# colsum() { awk_cmd -v col=$1 '{ n += $col } END { print n }' $2 ; }
# n=$(colsum 2 table); cxn=$(colsum 3 table)

# # fast way to produce corpus freqs without constraints
# cut -f1,3 freqs | tee testfile | cwb-lexdecode -f -F <(cut -f2 -) BNC | awk_cmd '{print 1}' | paste - testfil
# # on cwb 3.5
# cut -f1,3 freqs | tee tmp | cwb-lexdecode -b -f -F <(cut -f2 -) BNC | paste - tmp

# 112156361; 19098
