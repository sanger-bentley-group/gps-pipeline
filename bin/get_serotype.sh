# Run SeroBA to serotype samples
{
    seroba runSerotyping "$SEROBA_DIR"/"$DATABASE" "$READ1" "$READ2" "$SAMPLE_ID" && SEROTYPE=$(awk -F'\t' '{ print $2 }' ${SAMPLE_ID}/pred.tsv)
} || {
    SEROTYPE="SEROBA FAILURE"
}
