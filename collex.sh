#!/usr/bin/env bash
LC_ALL=C

awk_cmd() { awk -M -v PREC="double" -v OFMT="%.6f" -v OFS="\t" "$@" ; }
# awk_cmd() { mawk -v OFMT="%.6f" -v OFS="\t" "$@" ; }

data=$1

# if sizes not given, calculate
colsum() { awk_cmd -v i=$1 '{ x += $i } END { print x }' $2 ; }
[ ${N:-} ] || N=$(colsum 2 $data)
[ ${n:-} ] || n=$(colsum 3 $data)

obs_exp() {
  # $1=[token] $2=[f_corpus] $3=[f_coll*]
  awk_cmd -v N=$N -v n=$n '{
    O11 = $3;        O12 = $2 - O11;         R1 = O11 + O12;
    O21 = n - O11;   O22 = N - $2 - n + O11; R2 = O21 + O22;
    C1  = O11 + O21; C2  = O12 + O22;

    E11 = C1 * R1 / N; E12 = C2 * R1 / N;
    E21 = C1 * R2 / N; E22 = C2 * R2 / N;

    print O11, O12, O21, O22, E11, E12, E21, E22
  }' $1
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

