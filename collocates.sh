#!/usr/bin/env sh

ncol=$(head -1 $1 | wc -w)
touch $2

for i in $(seq $ncol)
do
    cut $1 -f$i -d " " | sort | uniq -c | sort -rn | \
    sed -e 's/^[ ]*//g' \
        -e 's/,/","/g' \
       	-e 's/ /,/g' > /tmp/col$i &
done
wait

paste -d, /tmp/col[0-9]* > $2

rm /tmp/col[0-9]*
