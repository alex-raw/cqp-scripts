#!/usr/bin/env bash
# Tool to create collocation tables with counts
# Provide square space-delimited KWIC via stdin or file
# Mini version, no options, no fluff
# Copyright (C) 2020 Alexander Rauhut, GNU General Public License 3.0.

set -euo pipefail

tmp="$(mktemp -d)"; trap 'rm -rf -- "${tmp}"' EXIT
[ -p /dev/stdin ] && cat /dev/stdin > "${tmp}"/buffer

data="${1:-${tmp}/buffer}"
ncol=$(head -1 "${data}" | wc -w)

for i in $(seq $ncol); do
  cut -f $i -d " " "${data}" | awk '
  { f[$0]++; } END { for (tok in f) print(f[tok] " " tok) }
  ' | sort -nr > "${tmp}"/out$i &
done
wait

paste "${tmp}"/out* | sed "s/\t\t/\t\t\t/g" | sed "s/^\t/\t\t/g"
