if [[ "$ASSEMBLY_QC" == "PASS" ]] && [[ "$MAPPING_QC" == "PASS" ]] && [[ "$TAXONOMY_QC" == "PASS" ]]; then
    OVERALL_QC="PASS"
else
    OVERALL_QC="FAIL"
fi