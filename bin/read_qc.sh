# Extract total base count and determine QC result based on output JSON file of fastp 

BASES=$(< $JSON jq -r .summary.after_filtering.total_bases)

if (( $(echo "$BASES >= ($QC_LENGTH_LOW*$QC_DEPTH)" | bc -l) )); then
    READ_QC="PASS"
else
    READ_QC="FAIL"
fi

echo \"Read_QC\",\"Bases\" > $READ_QC_REPORT
echo \"$READ_QC\",\"$BASES\" >> $READ_QC_REPORT