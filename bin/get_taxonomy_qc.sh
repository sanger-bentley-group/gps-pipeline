# Extract taxonomy QC information and determine QC result based on $KRAKEN2_REPORT

PERCENTAGE=$(awk -F"\t" '$4 ~ /^S$/ && $6 ~ /^\s*Streptococcus pneumoniae$/ { printf "%.2f", $1 }' "$KRAKEN2_REPORT")

if [ -z "$PERCENTAGE" ]; then
    PERCENTAGE="0.00"
fi

if [[ "$(echo "$PERCENTAGE > $QC_SPNEUMO_PERCENTAGE" | bc -l)" == 1 ]]; then
    SECOND_SPECIES_RECORD=$(sort -nr -k1 "$KRAKEN2_REPORT" | awk -F"\t" '$4 ~ /^S$/ && $6 !~ /^\s*Streptococcus pneumoniae$/ { print; exit }')

    SECOND_SPECIES=$(awk -F"\t" '{ gsub(/^\s+/, "", $6); print $6 }' <<< "$SECOND_SPECIES_RECORD")
    SECOND_SPECIES_PERCENTAGE=$(awk -F"\t" '{ printf "%.2f", $1 }' <<< "$SECOND_SPECIES_RECORD")

    if [[ "$(echo "$SECOND_SPECIES_PERCENTAGE > $QC_SECOND_SPECIES_PERCENTAGE" | bc -l)" == 1 ]]; then
        TAXONOMY_QC="WARNING"
    else
        TAXONOMY_QC="PASS"
    fi
else
    TAXONOMY_QC="FAIL"
fi

echo \"Taxonomy_QC\",\"S.Pneumo_%\",\"Second_Species\",\"Second_Species_%\" > "$TAXONOMY_QC_REPORT"
echo \""$TAXONOMY_QC"\",\""$PERCENTAGE"\",\""${SECOND_SPECIES:-}"\",\""${SECOND_SPECIES_PERCENTAGE:-}"\" >> "$TAXONOMY_QC_REPORT"
