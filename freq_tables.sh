#!/usr/bin/env bash
LC_ALL=C

# {{{ Usage

usage() {
cat <<-END
DESCRIPTION
    Tool to create count-annotated collocation tables from square, whitespace-delimited input,
    typically a concordance (e.g. from output of CQP tabulate). Tabs, take precedence, so
    collocation tables with multi-word units can be created if spaces are used as secondary
    separator.
    (c) 2021 Alexander Rauhut, GNU General Public License 3.0.

USAGE
    [<stdin>] $0 [options] [infile]

    -c|--case)   ignore case when counting
    -h|--header) print header; only makes sense for KWIC input without meta-information
    -m|--match)  provide match position for -h option if not provided, the center column is used
    --mawk)      use faster mawk interpreter to get counts
    --help)      view this help file
"
END
}

# }}} --------------------------------------------------------------------------
# {{{  Defaults and Options

set -o errexit
set -o nounset
set -o pipefail

while [ $# -gt 0 ]; do
  case "$1" in
    -c|--ignore-case)   case=true; shift ;;
    -h|--header)        header=true; shift ;;
    -m|--match)         match_i=$2; shift; shift ;;
    --mawk)             mawk=true; shift ;;
    --help)             usage; exit 0 ;;
    *) break ;;
  esac
done

# set up temp directory and make sure it's deleted on any exit
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

# take stdin or file; buffer data on disk for parallel processing
[ -p /dev/stdin ] && cat /dev/stdin > "${tmp}"/buffer
data="${1:-"${tmp}/buffer"}"

# Test for input format; error out if not whitespace
if head -5 "$data" | grep -qs $'\t'; then
  delim=$'\t'
elif head -5 "$data" | grep -qs ' '; then
  delim=' '
else
  echo "Neither spaces nor tabs detected."; exit 1
fi

# }}} --------------------------------------------------------------------------
# {{{ Main functions

count() {
  [ ${mawk:-} ] && awk_cmd="mawk" || awk_cmd="awk"
  $awk_cmd -v OFS='\t' '{ f[$0]++; } END { for (tok in f) print(f[tok], tok) }'
}

fold_case() { tr "[:upper:]" "[:lower:]" ; }

# parallel execution per column
file_per_column() {
  # infer column number from 10th line; see NOTE2 below
  ncol=$(head -10 "$data" | tail -1 | wc -w)
  fun=$1

  for i in $(seq "$ncol"); do
    cut -f "$i" -d " " "$data" | "$fun" | sort -nr > "$tmp"/out$i &
  done; wait
}

# paste doesn't handle ragged multi cols;
bind_cols() { paste "$tmp"/out* | perl -pe 's/^\t|(?<=(\t))\t/\t\t/g' ; }

make_header() {
  [ -z "${match_i:-}" ] && match_i=$(( ncol / 2 + 1 )) # column index of match
  left=$(( match_i - 1 )); right=$(( ncol - match_i ))
  for (( i=left; i>=1; i-- )); do printf "frq_L$i\tL$i\t"; done
  printf "frq_M\tM\t"
  for (( i=1; i<=right; i++ )); do printf "frq_R$i\tR$i\t"; done
  printf "\n"
}

# }}} --------------------------------------------------------------------------
# {{{ Execution

if [ ${case:-} ]; then
  get_freqs() { fold_case | count ; }
else
  get_freqs() { count ; }
fi

file_per_column get_freqs
[ ${header:-} ] && make_header
bind_cols

# }}} --------------------------------------------------------------------------
# {{{ Notes
#
# TODO: diacritic folding as in cqp %d;
# seems tricky to make iconv work consistently on Mac and Linux
# need to test what cqp %d does
#
# TODO: Add input testing

# NOTE2:
# Using 10th line to infer column number because output of cqp tabulate
# is not aligned if one of the matches k words away from the beginning or end
# of the corpus where k is the range;
# 10 is arbitrary but save without much overhead
#
# }}} --------------------------------------------------------------------------
# {{{ License
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
