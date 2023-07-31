# Extract taxonomy QC information and determine QC result based on kraken2_report.txt

PERCENTAGE=$(awk -F"\t" '$4 ~ /^S$/ && $6 ~ /Streptococcus pneumoniae$/ { gsub(/^[ \t]+/, "", $1); printf "%.2f", $1 }' "$KRAKEN2_REPORT")

if [ -z "$PERCENTAGE" ]; then
    PERCENTAGE="0.00"
fi

if [[ "$(echo "$PERCENTAGE > $QC_SPNEUMO_PERCENTAGE" | bc -l)" == 1 ]]; then
    TAXONOMY_QC="PASS"
else
    TAXONOMY_QC="FAIL"
fi

echo \"Taxonomy_QC\",\"S.Pneumo_%\" > "$TAXONOMY_QC_REPORT"
echo \""$TAXONOMY_QC"\",\""$PERCENTAGE"\" >> "$TAXONOMY_QC_REPORT"
