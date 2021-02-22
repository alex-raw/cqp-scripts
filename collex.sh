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
