# Determine overall QC result based on File Validity, Read QC, Assembly QC, Mapping QC and Taxonomy QC
# In case File Validity is not PASS, save its value (i.e. description of the issue) to Overall QC
# In case of assembler failure, there will be no Assembly QC input, save ASSEMBLER FAILURE to Overall QC

if [[ ! "$FILE_VALIDITY" == "PASS" ]]; then
    OVERALL_QC="$FILE_VALIDITY"
elif [[ "$READ_QC" == "PASS" ]] && [[ "$ASSEMBLY_QC" == "PASS" ]] && [[ "$MAPPING_QC" == "PASS" ]] && [[ "$TAXONOMY_QC" == "PASS" ]]; then
    OVERALL_QC="PASS"
elif [[ "$READ_QC" == "PASS" ]] && [[ "$ASSEMBLY_QC" == "null" ]]; then
    OVERALL_QC="ASSEMBLER FAILURE"
else
    OVERALL_QC="FAIL"
fi

echo \"Overall_QC\" > "$OVERALL_QC_REPORT"
echo \""$OVERALL_QC"\" >> "$OVERALL_QC_REPORT"
