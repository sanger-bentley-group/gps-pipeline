# Combine all csv reports into a single csv, then add Sample_ID as the first field

paste -d , *.csv \
| sed '1 s/^/\"Sample_ID\",/' \
| sed "2 s/^/\"${SAMPLE_ID}\",/" > "$SAMPLE_REPORT"
