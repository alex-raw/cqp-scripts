#!/usr/bin/env sh

# corpus size
n="$(cwb-lexdecode -S BROWN | head -1 | grep -oz "[0-9]")"

# get list of words and their text_id \
#  | count words per text_id | get rid of p-attribute name \
#  | alphabetical sort for later join | save as temp file
#  | get part sizes | make them proportions
# FIXME: yikes! need to fill in parts where word doesn't occur

cwb-decode BROWN -P word -S text_id \
  | sort | uniq -c | sed 's/word=//g' \
  | sort -k3 | tee per_part \
  | cut -f2 | sort | uniq -c \
  | awk -M -v n=$n '{ print $1 / n, $2 }' > parts

# replace corpus part names with their size
join -1 3 -2 2 -o 1.2 1.1 2.1 per_part parts > master_table

# annotate words with their frequency
cut -f1 -d " " master_table \
  | cwb-lexdecode -f0 -P word -F - BROWN \
  | awk '{print $1}' \
  | paste -d " " master_table - > final_table

# calculate (v / f) - s
awk '{print $1, ($2 / $4) - $3}' final_table | less

# TODO: check for precision errors
