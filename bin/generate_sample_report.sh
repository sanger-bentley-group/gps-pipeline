paste -d , *.csv \
| sed '1 s/^/\"Sample_ID\",/' \
| sed "2 s/^/\"${SAMPLE_ID}\",/" > "$SAMPLE_REPORT"
