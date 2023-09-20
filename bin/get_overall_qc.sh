# Determine overall QC result based on Assembly QC, Mapping QC and Taxonomy QC
# In case of assembler failure, there will be no Assembly QC input, hence output result as ASSEMBLER FAILURE

if [[ "$READ_QC" == "PASS" ]] && [[ "$ASSEMBLY_QC" == "PASS" ]] && [[ "$MAPPING_QC" == "PASS" ]] && [[ "$TAXONOMY_QC" == "PASS" || "$TAXONOMY_QC" == "WARNING" ]]; then
    if [[ "$TAXONOMY_QC" == "WARNING" ]]; then
        OVERALL_QC="WARNING"
    else
        OVERALL_QC="PASS"
    fi
elif [[ "$READ_QC" == "FAIL" ]]; then
    OVERALL_QC="FAIL"
elif [[ "$ASSEMBLY_QC" == "null" ]]; then
    OVERALL_QC="ASSEMBLER FAILURE"
else
    OVERALL_QC="FAIL"
fi

echo \"Overall_QC\" > "$OVERALL_QC_REPORT"
echo \""$OVERALL_QC"\" >> "$OVERALL_QC_REPORT"
