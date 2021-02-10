#!/usr/bin/env bash

set -eo pipefail

# {{{ Usage

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
                        quotation marks embedded in the text are escaped with a backslash;
			delimiters containing spaces need to be quoted;
			symbols with special meaning in shell need to be escaped and quoted
        -s|--space)	use space as secondary delimiter to separate count from attribute
	--help)		view this help file
    "
}

# }}} --------------------------------------------------------------------------
# {{{  Defaults and Options

# $delim separates pairs, $sep delimits token from value
tab=$(printf '\t')
delim="$tab"
sep="$tab"

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--header) header=true; shift ;;
    -d|--delim)  delim="$2"; sep="$2"; shift; shift ;;
    -s|--space)  sep=" "; delim="$tab"; shift ;;
    -m|--match)  match_i=$2; shift; shift ;;
    -o|--omit)   omit=true; shift ;;
    -l|--list)   list=true; shift ;;
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

# infer column number from first line
ncol=$(head -1 "$data" | wc -w)
[ $match_i ] || match_i=$(( ncol / 2 + 1 )) # column index of match

# }}} --------------------------------------------------------------------------
# {{{ Main functions

count() {
  awk '{ f[$0]++; } END { for (tok in f) print(f[tok] " " tok) }' | sort -nr
}

# parallel execution per column
file_per_column() {
  count_fun=$1
  for i in $(seq "$ncol"); do
    cut -f "$i" -d " " "$data" | "$count_fun" > "$tmp"/"${i}"out &
  done
  wait
}

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

file_per_column count

if [ $omit ]; then
  a=$(( match_i * 2 - 1 )); b=$(( match_i * 2 ))
  [ $header ] && make_header | cut -f$a,$b -d "$delim" --complement
  format_output | cut -f$a,$b -d "$delim" --complement
else
  [ $header ] && make_header
  format_output
fi

# }}} --------------------------------------------------------------------------
# {{{ Notes
#
# TODO: Feature - wide list; separate script?
#
# TODO: Add input testing
#
# Known issue: doesn't work for spaces inside tokens;
# leads to misaligned columns;
# known issue with BROWN; "the"; tabulate Last...
# could test and remove lines with wc -w
# from CQP v3.4.24, the TokenSeparator and AttributeSeparator
# can be set to TAB or another illegal character (untested)
# see http://cwb.sourceforge.net/files/CQP_Tutorial/7_1.html
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
