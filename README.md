# cqp-scripts
Collection of scripts for wrangling output formats from or querying corpora with CQP (CWB / The IMS Open Corpus Workbench)

## Usage notes

Scripts prefixed with `cwb` are designed to mimic the behavior of the CWB CLI tools, therefore, depend on an existing CWB setup and corresponding environment variables.

All other scripts work independently with plain text input usually expected to be tab or space delimited.

Scripts with the prefix `mini` are debloated clones with hardcoded default behaviour.

## One-Liners

#### Corpus token number

```
$ cwb-lexdecode -S BNC | sed -n '1s/[^0-9]//gp'

1176983
```

#### Number of s-attribute regions

```
# without annotation
$ cwb-s-decode BNC -S s | wc -l

6026217

# with annotation
$ cwb-s-decode -n BNC -S text_genre | sort | uniq -c

132 S:meeting
6 S:parliament
16 S:pub_debate
16 S:sermon
25 S:speech:scripted
...
```

#### Frequency list per s-attribute

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
$ cwb-lexdecode -lf BNC | awk '{l[$2] += $1} END {for (i in l) print l[i], i}'

15187040 1
17886516 2
22537304 3
15956906 4
10396972 5
...
```

#### Frequency list of sentence lengths

```
$ cwb-s-decode BNC -S s | awk '{print $2-$1+1}' | sort | uniq -c | sort -n -k2
107735 1
318742 2
220191 3
211203 4
211266 5
...
```

#### Frequency list: case-sensitive to case-insensitive

```
awk '{a[tolower($2)] += $1} END {for (i in a) print a[i], i}'
```

## Links:
- [CWB/CQP](https://sourceforge.net/projects/cwb/)
