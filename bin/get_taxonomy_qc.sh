# Extract taxonomy QC information and determine QC result based on $KRAKEN2_REPORT

PERCENTAGE=$(awk -F"\t" '$4 ~ /^S$/ && $6 ~ /^\s*Streptococcus pneumoniae$/ { printf "%.2f", $1 }' "$KRAKEN2_REPORT")

TOP_NON_STREP_GENUS_RECORD=$(sort -nr -k1,1 -k2,2 "$KRAKEN2_REPORT" | awk -F"\t" '$4 ~ /^G$/ && $6 !~ /^\s*Streptococcus$/ { print; exit }')
TOP_NON_STREP_GENUS=$(awk -F"\t" '{ gsub(/^\s+/, "", $6); print $6 }' <<< "$TOP_NON_STREP_GENUS_RECORD")
TOP_NON_STREP_GENUS_PERCENTAGE=$(awk -F"\t" '{ printf "%.2f", $1 }' <<< "$TOP_NON_STREP_GENUS_RECORD")

if [ -z "$PERCENTAGE" ]; then
    PERCENTAGE="0.00"
fi

if [ -z "$TOP_NON_STREP_GENUS_PERCENTAGE" ]; then
    TOP_NON_STREP_GENUS_PERCENTAGE="0.00"
fi

if [[ "$(echo "$PERCENTAGE > $QC_SPNEUMO_PERCENTAGE" | bc -l)" == 1 ]] && [[ "$(echo "$TOP_NON_STREP_GENUS_PERCENTAGE <= $QC_TOP_NON_STREP_GENUS_PERCENTAGE" | bc -l)" == 1 ]]; then
    TAXONOMY_QC="PASS"
else
    TAXONOMY_QC="FAIL"
fi

echo \"Taxonomy_QC\",\"S.Pneumo_%\",\"Top_Non-Strep_Genus\",\"Top_Non-Strep_Genus_%\" > "$TAXONOMY_QC_REPORT"
echo \""$TAXONOMY_QC"\",\""$PERCENTAGE"\",\""${TOP_NON_STREP_GENUS:-}"\",\""${TOP_NON_STREP_GENUS_PERCENTAGE}"\" >> "$TAXONOMY_QC_REPORT"
