#!/usr/bin/env bash

usage() {
    echo "
    Tool to create count-annotated collocation lists based on square, space-delimited input.
    (e.g. from output of CQP tabulate)
    Author: Alexander Rauhut

    Usage: $0 [options] infile
    "
}

# ---------------------- Defaults and Options---------------------------
delim="	"
keep=false
list=false

while test $# -gt 0; do
    case "$1" in
	-h|--help)
	    usage
	    exit 0 ;;
	-m|--keep-match)
	    shift
	    keep=true ;;
	-d|--delim)
	    shift
	    delim="$1"
	    shift ;;
	-l|--list)
	    shift
	    echo "this option doesn't do anything yet" ;;
	*)
	    break ;;
    esac
done

TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

# see below
data="${1:-/dev/stdin}"
[ "$data" != "$1" ] && cat $data > $TMP/table && data="$TMP/table"

# ---------------------- Loop count over columns------------------------
ncol=$(head -1 $data | wc -w | xargs seq)
for i in $ncol
do
    cut -f $i -d " " $data |
    sort | uniq -c | sort -rn | \
    sed -e "s/^[ ]*//g" \
       	-e "s/[ ]/$delim/g" > $TMP/col$i &
done
wait

# ---------------------- Formatting options ----------------------------
match="$(wc -l $TMP/col[0-9]* | sort -n | awk 'NR==1 {print $NF}')"
mv $match "$TMP/match" &&

if [ "$keep" = true ]
then
    match_files="$TMP/col[0-9]* $TMP/match"
else
    match_files="$TMP/col[0-9]*"
fi

if [ "$delim" != "	" ]
then
    paste $match_files |
    sed "s/$delim[	]/\"$delim\"$delim/g" |
    sed "s/[[:blank:]]/$delim/g"
else
    paste $match_files
fi

# TODO: figure out how to do table header for asymmetrical concordances
# should be easy based on $match

# TODO: Feature - test for delimiters in input to pass to cut,
# e.g. to allow comma separated concordances
# Shouldn't be too hard to implement

# TODO: Feature - transpose to wide list

# IMPROVEMENT: figure out why not able to pipe output of cqp tabulate directly
# > tabulate...> "| this_script" produces wrong results
# test with other cqp output formats;
# using temporary file for now

# Known issue: doesn't work for spaces inside tokens;
# leads to misaligned columns;
# known issue with BROWN; "the"; tabulate Last...
# encoding error of corpus? bug/property of tabulate?
# could test and remove lines with wc -w too big
# differences in counts should be minor and random
# keep=true becomes nonsensical

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
