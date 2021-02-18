#!/usr/bin/env bash

set -o errexit
# set -o nounset
set -o pipefail

# {{{ Usage

usage() {
cat <<-END
DESCRIPTION
    Tool to create count-annotated collocation tables from square, space-delimited input,
    typically a concordance (e.g. from output of CQP tabulate).
    (c) 2021 Alexander Rauhut, GNU General Public License 3.0.

USAGE
    [<stdin>] $0 [options] [infile]

    -c|--case)   ignore case when counting
    -d|--delim)  a custom field separator for output;
                 respective string is automatically quoted if it exists in data;
                 quotation marks embedded in the text are escaped with a backslash;
                 delimiters containing spaces need to be quoted;
    -s|--space)  set space as secondary delimiter to separate count from attribute
    -m|--match)  provide match position for -h and -o options
                 if not provided, the center column is used
    -h|--header) print header; only makes sense for KWIC input without meta-information
    --mawk)      use faster mawk interpreter to get counts
    --help)      view this help file
"
END
}

# }}} --------------------------------------------------------------------------
# {{{  Defaults and Options

# $delim separates pairs, $sep delimits token from value
tab=$(printf '\t')
delim="$tab"
sep="$tab"

while [ $# -gt 0 ]; do
  case "$1" in
    -c|--case)   case=true; shift ;;
    -h|--header) header=true; shift ;;
    -d|--delim)  delim="$2"; sep="$2"; shift; shift ;;
    -s|--space)  sep=" "; delim="$tab"; shift ;;
    -m|--match)  match_i=$2; shift; shift ;;
    -l|--list)   list=true; shift ;;
    --mawk)      mawk=true; shift ;;
    --help)      usage; exit 0 ;;
    *) break ;;
  esac
done

# set up temp directory and make sure it's deleted on any exit
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

# take stdin or file; buffer data on disk for parallel processing
data="${1:-/dev/stdin}"
[ "$data" != "$1" ] && cat "$data" > "$tmp"/table && data="$tmp/table"

# Input testing
[ "$list" ] && echo "The -l|--list option doesn't do anything yet" && exit 1

# infer column number from 10th line; see NOTE2 below
ncol=$(head -10 "$data" | tail -1 | wc -w)
[ $match_i ] || match_i=$(( ncol / 2 + 1 )) # column index of match

# }}} --------------------------------------------------------------------------
# {{{ Main functions

[ $mawk ] && awk_cmd="mawk" || awk_cmd="awk"
count() {
  $awk_cmd '{ f[$0]++; } END { for (tok in f) print(f[tok] " " tok) }' | sort -nr
}

# parallel execution per column
file_per_column() {
  fun=$1
  for i in $(seq "$ncol"); do
    cut -f "$i" -d " " "$data" | "$fun" > "$tmp"/"${i}"out &
  done
  wait
}

fold_case() { tr "[:upper:]" "[:lower:]" ; }

# paste doesn't handle ragged multi cols;
# hard-coded tab as temporary delimiter on purpose
# (don't shortcut to `-d "$delim"` or formatting breaks)
bind_cols() {
  paste "$tmp"/[0-9]*out | sed "s/\t\t/\t\t\t/g" | sed "s/^\t/\t\t/g"
}

# }}} --------------------------------------------------------------------------
# {{{ Additional formatting

make_header() {
  echo | awk -v x="$sep" -v y="$delim" -v ncol=$ncol -v m=$match_i '
    { for (i = m - 1; i >= 1; i--) printf "L" i x "frq_L" i y;
      printf "M" x "frq_M" y;
      for (i = 1; i <= ncol - m; i++) printf "R" i x "frq_R" i y
    } END {printf "\n"}' | sed "s/.$//g"
}

format_output() {
  if [ "$delim" != "$tab" ]; then
    # escape quotes; quote delim in input; replace default \t with delim
    bind_cols \
      | sed -e 's/\"/\\"/g' \
            -e "s/$delim\t/\"$delim\"$delim/g" \
            -e "s/[[:blank:]]/$delim/g"
  elif [ "$sep" != " " ]; then
    bind_cols | sed "s/ /$delim/g"
  else
    bind_cols
  fi
}

# }}} --------------------------------------------------------------------------
# {{{ Execution

if [ $case ]; then
  get_freqs() { fold_case | count ; }
else
  get_freqs() { count ; }
fi

file_per_column get_freqs
[ $header ] && make_header
format_output

# }}} --------------------------------------------------------------------------
# {{{ Notes
#
# TODO: Feature - wide list; separate script?
#
# TODO: diacritic folding as in cqp %d;
# seems tricky to make iconv work consistently on Mac and Linux
# need to test what cqp %d does
#
# TODO: Add input testing
#
# NOTE1:
# Known issue: doesn't work for spaces inside tokens;
# leads to misaligned columns;
# known issue with BROWN; "the"; tabulate Last...
# could test and remove lines with wc -w
# from CQP v3.4.24, the TokenSeparator
# can be set to TAB or another illegal character (untested)
# see http://cwb.sourceforge.net/files/CQP_Tutorial/7_1.html
#
# NOTE2:
# Using 10th line to infer column number because output of cqp tabulate
# is not aligned if one of the matches k words away from the beginning or end
# of the corpus where k is the range;
# 10 is arbitrary but save without much overhead
#
# }}} --------------------------------------------------------------------------
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
# }}} --------------------------------------------------------------------------
