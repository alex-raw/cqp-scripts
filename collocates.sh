#!/usr/bin/env sh

usage() {
    echo "
    Tool to create count-annotated collocation tables from square, space-delimited input, typically a concordance.
    (e.g. from output of CQP tabulate)
    Author: Alexander Rauhut

    Usage: $0 [options] infile

	-h|--header)	print header
	-o|--omit)	omit original query match;
       			use with -m if match is not in the center;
	-m|--match)	provide match position for asymmetrical inputs
	-d|--delim)	a custom field separator for output;
			respective string is automatically quoted if it exists in data;
			strings containing spaces need to be quoted;
			symbols with special meaning in shell need to be escaped and quoted
	-l|--list)	out format with collocates ordered alphabetically
			in first column
	-P|--perl)	use faster perl implementation;
                        output is space and tab delimited; formatting options are ignored
	--help)		view this help file
    "
}

# ---------------------- Defaults and Options---------------------------
# no dash in argument = no options
# [ $(echo $@ | grep -o - | wc -l) = 0 ] && default=true

tab=$(printf '\t')
delim=$tab

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--header) header=true; shift ;;
    -o|--omit)   omit=true; shift ;;
    -l|--list)   list=true;         shift ;;
    -P|--perl)   perl=true;         shift ;;
    -m|--match)  shift; n_match=$1; shift ;;
    -d|--delim)  shift; delim="$1"; shift ;;
    --help)      usage; exit 0 ;;
    *) break ;;
  esac
done

[ $list ] && echo "The list option doesn't do anything yet" && exit 0

# take stdin or file
data="${1:-/dev/stdin}"
[ "$data" ] || echo

# hack to handle stdin; see below
[ "$data" != "$1" ] && cat $data > $TMP/table && data="$TMP/table"

# set up temp directory and make sure it's deleted on any exit
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
prefix="col_"

if [ -z "$perl" ]; then
  count() {
    sort | uniq -c | sort -rn \
      | awk -v x="$delim" '{ print $2 "\t" $1 }'
  }
else
  count() {
    perl -ne '
      $count{$_}++;
      END {
        print "$count{$_} $_" for sort {
          $count{$b} <=> $count{$a} || $b cmp $a
        } keys %count
      }'
  }
fi

# ---------------------- Loop count over columns-------------------------------
# infer column number from first line; parallel execution per column
ncol=$(head -1 $data | wc -w)
for i in $(seq $ncol); do
  cut -f $i -d " " $data | count > $TMP/$prefix$i &
done
wait

# paste inserts 1 separator too few for files with different lengths
bind_cols() {
  paste $TMP/$prefix[0-9]* | sed 's/\t\t/\t\t\t/g' | sed 's/^\t/\t\t/g'
}

[ $perl ] && bind_cols && exit 0

# ---------------------- Formatting options -----------------------------------

[ -z $n_match ] && n_match=$(( $ncol / 2 + 1 ))

make_header() {
  middle="match${delim}n_match${delim}"
  left=$(echo $(( $n_match - 1 )) \
    | xargs -i seq {} -1 1 \
    | awk -v x="$delim" '{ printf "L" $0 x "frq_L" $0 x }')
  right=$(echo $(( $ncol - $n_match )) \
    | xargs -i seq 1 {} \
    | awk -v x="$delim" '{ printf "R" $0 x "frq_R" $0 x }')
  echo "$left$middle$right" | sed "s/$delim$//"
}

format_output() {
  [ $header ] && make_header

  if [ "$delim" != "$tab" ]; then
    # escape quotes; quote delim in input; replace default \t with delim
    bind_cols \
      | sed -e 's/\"/\\"/g' \
      -e "s/$delim\t/\"$delim\"$delim/g" \
      -e "s/\t/$delim/g"
  else
    bind_cols
  fi
}

if [ $omit ]; then
  a=$(( $n_match + $n_match - 1 ))
  b=$(( $n_match + $n_match ))
  format_output | cut -f$a,$b -d "$delim" --complement
else
  format_output
fi

# TODO: Feature - test for delimiters in input to pass to cut,
# e.g. to allow comma separated concordances
# Shouldn't be too hard to implement

# TODO: Feature - transpose to wide list

# TODO: Add input testing

# IMPROVEMENT: figure out why not able to pipe output of cqp tabulate directly
# > tabulate...> "| this_script" produces wrong results
# test with other cqp output formats;
# using temporary file for now

# Known issue: doesn't work for spaces inside tokens;
# leads to misaligned columns;
# known issue with BROWN; "the"; tabulate Last...
# encoding error of corpus? bug/property of tabulate?
# could test and remove lines with wc -w

#-----------------------------------------------------------------------
# {{{ License
#
# Tool to create collocation tables with counts
# Copyright (C) 2020 Alexander Rauhut
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

# }}}
