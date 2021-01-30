#!/usr/bin/env sh

usage() {
echo "CQP wrapper script to print frequency info, and basic productivity measures for a query.
Author: Alexander Rauhut

      Usage :  $0 [OPTIONS] CORPUS 'QUERY' ATTRIBUTE=word
      Queries have to be put in single quotes.

      If no ATTRIBUTE is supplied the default used is 'word'.
      Space delimited attributes have to be put in quotes.

      Options:
      -h|help        Display this message
      -p|pipe        Pipe tabulated output into command
      -o|outfile     Specify file to capture frequency list used to calculate table
      -c|case        Ignore Case (%c)
      -d|diacritics  Ignore Diacritics (%d)
      -e|echo        Print cqp command used
      -q|quiet       Suppress progress messages
      -v|version     Display version

      Examples:
      $0 BNC '[word = ".+ity"]'
      case-sensitive counts of case sensitive query

      $0 BNC -c '[word = ".+ity"%c]'
      case-insensitive counts of case insensitive query

      $0 -o freqlist.txt BNC '[word = ".+ity"]'
      keep frequency list

      $0 -o freqlist.txt BNC '[word = ".+ity"]' > freqinfo.txt
      save frequency list in freqlist.txt and script output in freqinfo.txt

      $0 -p -q BNC'[word = ".+ity"]'
      print command used by script in output; suppress waiting message
      "
}

# Waiting message
waiting () {
echo "...Processing\n$cqp_command\n\n
This might take a while depending on corpus size and query complexity
Try ctrl+c to exit; if process is stuck, press ctrl+\\
(German keyboard: AltGr+Strg+ß)
"
}

# ---------------------- Defaults and Options---------------------------

while [ $# -gt 0 ]; do
  case "$1" in
    -o|--outfile    )  shift; file="$1"; shift ;;
    -p|--pipe       )  pipe=true; shift  ;;
    -e|--echo       )  print=true; shift  ;;
    -c|--case       )  case="c"; shift  ;;
    -d|--diacritics )  diacritics="d"; shift  ;;
    -q|--quiet      )  quiet=true; shift  ;;
    -h|--help       )  usage; exit 0 ;;
    * ) break ;;
  esac
done

# input testing
[ $# -lt 2 ] && echo "Missing argument. Try "$0 -h" for more information." && exit 1
[ "$(echo $2 | grep -c "]")" -eq 0 ] && echo "Syntax error parsing query: missing ];
Did you forget to enclose your query in single quotes?" && exit 1
[ "$(echo $2 | grep -c "\"")" -eq 0 ] && echo "Syntax error parsing query: missing \";
Did you forget to enclose your query in single quotes?" && exit 1

# ----------------------------------------------------------------------
# Set up values
# case and diacritic folding
[ -z "$diacritics" ] && [ -z "$case" ] || fold="%$case$diacritics"

# setting up values
corpus=$1
query=$2
attr=$3
[ -z "$attr" ] && attr="word"
tmp="$(mktemp -d)"
tmp_file=$tmp/freqinfo
trap 'rm -rf -- "$tmp"' EXIT

# TODO: accept piped tabulate output

# TODO: add query constructor to allow multiple ATTRIBUTES
cqp_command="$corpus; A=$query; tabulate A match[0]..matchend[0] $attr $fold;"

[ -n "$(echo $cqp_command | grep -Po "%\w+ %")" ] && echo "Error: use either the -c/-d flag or specify %c/%d in the ATTRIBUTE argument" && exit 1

#-----------------------------------------------------------------------
# TODO: add feature: arbitrary amounts of query options and output as table?

[ $quiet ] || waiting >&2
echo "$cqp_command" | cqp -c | sed 1d > $tmp_file

freq () {
  wc -l $1 | cut -f1 -d " "
}

# token count; FIXME: Bug, sometimes values after $token 0
size="$(echo "$corpus; info;" | cqp -c | grep -Po "(?<=Size:    ).*")"
#TODO: replace with:
size="$(cwb-lexdecode -S BNC-BABY | head -1 | grep -oz "[0-9]")"
tokens=$(freq $tmp_file)
hapaxes=$(sort $tmp_file | uniq -c | tee $tmp_file | grep " 1 " | freq)
types=$(freq $tmp_file)
rel=$(echo "scale=15; $tokens / $size" | bc)
htr=$(echo "scale=15; $hapaxes / $tokens" | bc)
ttr=$(echo "scale=15; $types / $tokens" | bc)

[ $types = 0 ] && echo "Error: type count is zero; if query output isn't zero, this is a bug; try again or check query" >&2 && exit 1

# print result
[ $print ] && echo $cqp_command
printf "N \t%d
Tokens\t%d
Types\t%d
Hapaxes\t%d
F_rel\t%f
TTR\t%f
HTR\t%f
" "$size" "$tokens" "$types" "$hapaxes" "$rel" "$ttr" "$htr"

# if outfile do sort decreasing; copy tmp file
if [ -n "$file" ]; then
  sort -nr $tmp_file > $file
  [ $quiet ] || echo "Frequency list written to file: $file " >&2
fi

# {{{ License
#
# CQP wrapper script for frequencies and simple productivity measures
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
