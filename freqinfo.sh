#!/usr/bin/env bash

__ScriptVersion="0.0.9999"

#-----------------------------------------------------------------------
#  Display usage information.
usage()
{
echo "CQP wrapper script to print frequency info, and basic productivity measures for a query.
Author: Alexander Rauhut

      Usage :  $0 [OPTIONS] CORPUS 'QUERY' ATTRIBUTE=word
      Queries have to be put in single quotes.

      If no ATTRIBUTE is supplied the default used is 'word'.
      Space delimited attributes have to be put in quotes.

      Options:
      -h|help        Display this message
      -o|outfile     Specify file to capture frequency list used to calculate table
      -c|case        Ignore Case (%c)
      -d|diacritics  Ignore Diacritics (%d)
      -p|print       Print cqp command used
      -q|quiet       Suppress progress messages
      -v|version     Display version

      Examples:
      $0 BNC '[word = ".+ity"]'
      case-sensitive counts of case sensitive query

      $0 BNC -c '[word = ".+ity"%c]'
      case-insensitive counts of case insensitive query

      $0 -o freqlist.txt BNC '[word = ".+ity"]'
      kepp frequency list

      $0 -o freqlist.txt BNC '[word = ".+ity"]' > freqinfo.txt
      save frequency list in freqlist.txt and script output in freqinfo.txt

      $0 -p BNC'[word = ".+ity"]'
      print command used by script in output
      "
}

# Waiting message
waiting ()
{
echo "...Processing
$cqp_command

This might take a while depending on corpus size and query complexity
Try ctrl+c to exit; if process is stuck, press ctrl+\\
(German keyboard: AltGr+Strg+ß)
"
}

#-----------------------------------------------------------------------
# Handle command line arguments

while getopts "hvo:pf:cdq" opt
do
    case $opt in
	h|help       )  usage; exit 0   ;;
	v|version    )  echo "$0 -- Version $__ScriptVersion"; exit 0   ;;
	o|outfile    )  file="$OPTARG" ;;
	p|print      )  print=true  ;;
	c|case       )  case="c" ;;
	d|diacritics )  diacritics="d" ;;
	q|quiet      )  quiet=true ;;
	* )  echo -e "\n  Option does not exist : $OPTARG\n"
	    usage; exit 1   ;;
    esac
done
shift $(($OPTIND-1))

# input testing
[ $# -eq 1 ] && echo Missing argument. Try "hapax -h" for more information. && exit 1
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
tmp="/tmp/freq.tmp"

# TODO: add query constructor to allow multiple ATTRIBUTES
cqp_command="$corpus; A=$query; tabulate A match[0]..matchend[0] $attr $fold;"

[ -n "$(echo $cqp_command | grep -Po "%\w+ %")" ] && echo "Error: use either the -c/-d flag or specify %c/%d in the ATTRIBUTE argument" && exit 1

#-----------------------------------------------------------------------
# TODO: add feature: arbitrary amounts of query options and output as table?
freq () {
    arg=$1
    wc -l $1 | cut -f1 -d " "
}

[ $quiet ] || waiting >/dev/stderr

# create temporary cqp batchfile because cqp -c is a bit buggy (3.0.0)
echo "$cqp_command" > /tmp/hpx_tmp

cqp -f /tmp/hpx_tmp > $tmp

# token count; FIXME: Bug, sometimes values after $token 0
size="$(echo "$corpus; info;" | cqp -c | grep -Po "(?<=Size:    ).*")"
tokens=$(freq $tmp)
hapaxes=$(sort $tmp | uniq -c | tee $tmp | grep " 1 " | freq)
types=$(freq $tmp)
rel=$(echo "scale=15; $tokens / $size" | bc)
htr=$(echo "scale=15; $hapaxes / $tokens" | bc)
ttr=$(echo "scale=15; $types / $tokens" | bc)


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

# if outfile do sort decreasing; otherwise clean tmp files
if [ -z $file ]; then
    rm $tmp
else
    sort -nr $tmp > $file && rm $tmp
    [ $quiet ] || echo "Frequency list written to file: $file " >/dev/stderr
fi

rm /tmp/hpx_tmp

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
