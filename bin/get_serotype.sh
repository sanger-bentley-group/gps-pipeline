# Run SeroBA to serotype samples

{
    seroba runSerotyping "${SEROBA_DB}" "$READ1" "$READ2" "$SAMPLE_ID" && SEROTYPE=$(awk -F'\t' '{ print $2 }' "${SAMPLE_ID}/pred.tsv")
} || {
    SEROTYPE="SEROBA FAILURE"
}

echo \"Serotype\" > "$SEROTYPE_REPORT"
echo \""$SEROTYPE"\" >> "$SEROTYPE_REPORT"
