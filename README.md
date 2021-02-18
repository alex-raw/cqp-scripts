# cqp-scripts
Collection of scripts for wrangling output formats from or querying corpora with CQP (CWB / The IMS Open Corpus Workbench)

## Usage notes

Scripts prefixed with `cwb` are designed to mimic the behavior of the CWB CLI tools, therefore, depend on an existing CWB setup and corresponding environment variables.

All other scripts work independently with plain text input usually expected to be tab or space delimited.

## One-Liners

#### Corpus token number

```
$ cwb-lexdecode -S BNC | sed -n '1s/[^0-9]//gp'
1176983
```

#### Frequency list for s-attribute

```
# fast:
$ cwb-s-decode BNC -S text_genre | awk '{x[$3] += $2-$1+1} END {for (i in x) print i,x[i]}'
7518 A00
8801 A01
3703 A02
21701 A03
43861 A04
...

# small:
$ cwb-scan-corpus BNC text_genre
```

#### Frequency list of word lengths

```
$ cwb-lexdecode -lf BNC | awk '{l[$2] += $1} END {for (i in l) print i,l[i]}'
1 15187040
2 17886516
3 22537304
4 15956906
5 10396972
...
```

#### Frequency list: case-sensitive to case-insensitive

```
awk '{a[tolower($2)] += $1} END {for (i in a) print a[i], i}'
```

## Links:
- [CWB/CQP](https://sourceforge.net/projects/cwb/)
