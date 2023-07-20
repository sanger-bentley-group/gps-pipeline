# Extract mapping QC information and determine QC result based on reference coverage and count of Het-SNP sites

COVERAGE=$(printf %.2f $COVERAGE)

if (( $(echo "$COVERAGE > $QC_REF_COVERAGE" | bc -l) )) && (( $HET_SNP < $QC_HET_SNP_SITE )); then
    MAPPING_QC="PASS"
else
    MAPPING_QC="FAIL"
fi

echo \"Mapping_QC\",\"Ref_Cov_%\",\"Het-SNP#\" > $MAPPING_QC_REPORT
echo \"$MAPPING_QC\",\"$COVERAGE\",\"$QC_HET_SNP_SITE\" >> $MAPPING_QC_REPORT