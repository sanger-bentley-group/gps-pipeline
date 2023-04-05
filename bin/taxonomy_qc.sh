# Extract taxonomy QC information and determine QC result based on kraken_report.txt

PERCENTAGE=$(awk -F"\t" '$4 ~ /^S$/ && $6 ~ /Streptococcus pneumoniae$/ { gsub(/^[ \t]+/, "", $1); printf "%.2f", $1 }' $KRAKEN_REPORT)

if [ -z "$PERCENTAGE" ]; then
    PERCENTAGE="0.00"
fi

if (( $(echo "$PERCENTAGE > $QC_SPNEUMO_PERCENTAGE" | bc -l) )); then
    TAXONOMY_QC="PASS"
else
    TAXONOMY_QC="FAIL"
fi
