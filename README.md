# cqp-scripts
Collection of scripts for wrangling output formats from or querying corpora with CQP (CWB / The IMS Open Corpus Workbench)

## One-Liners:

#### frequencies lists for s-attributes
```
# fast:
$ cwb-s-decode BNC -S text_id | awk 'print {$2-$1+1, $3}'
7518 A00
8801 A01
3703 A02
21701 A03
43861 A04
...

# small:
$ cwb-scan-corpus BNC text_id
```

#### Frequency list of word lengths
```
$ cwb-lexdecode -lf BNC | cut -f1,2 | awk '{arr[$2] += $1} END {for (i in arr) print i,arr[i]}'
1 15187040
2 17886516
3 22537304
4 15956906
5 10396972
...
```

## Links:
- [CWB/CQP](https://sourceforge.net/projects/cwb/)
