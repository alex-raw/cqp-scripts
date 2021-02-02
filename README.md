# cqp-scripts
Collection of scripts for wrangling output formats from or querying corpora with CQP (CWB The IMS Open Corpus Workbench)

Links:
- [CWB/CQP](https://sourceforge.net/projects/cwb/)

One-Liners:
frequencies lists for s-attributes
```
fast:
$ cwb-s-decode BNC -S text_id | awk 'print {$2-$1+1, $3}'

small:
$ cwb-scan-corpus BNC text_id
```
