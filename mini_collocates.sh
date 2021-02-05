#!/usr/bin/env bash
# Tool to create collocation tables with counts
# Mini version, no options, no fluff
# Copyright (C) 2020 Alexander Rauhut

data="${1:-/dev/stdin}"
tmp="$(mktemp -d)"; trap 'rm -rf -- "$tmp"' EXIT
[ "$data" != "$1" ] && cat "$data" > "$tmp"/table && data="$tmp/table"

# infer column number from first line; parallel execution per column
ncol=$(head -1 "$data" | wc -w)
for i in $(seq "$ncol"); do
  cut -f "$i" -d " " "$data" | perl -ne '
  $count{$_}++; END { print "$count{$_} $_" for sort {
              $count{$b} <=> $count{$a} || $a cmp $b
            } keys %count }' > "$tmp"/"${i}"out &
done
wait

# (don't shortcut to `-d "$delim"` or formatting breaks)
paste "$tmp"/[0-9]*out | sed "s/\t\t/\t\t\t/g" | sed "s/^\t/\t\t/g"
