# Extract assembly QC information and determine QC result based on report.tsv from Quast, total base count

CONTIGS=$(awk -F'\t' '$1 == "# contigs (>= 0 bp)" { print $2 }' $REPORT)
LENGTH=$(awk -F'\t' '$1 == "Total length" { print $2 }' $REPORT)
DEPTH=$(printf %.2f $(echo "$BASES / $LENGTH" | bc -l) )

if (( $CONTIGS < $QC_CONTIGS )) && (( $LENGTH >= $QC_LENGTH_LOW )) && (( $LENGTH <= $QC_LENGTH_HIGH )) && (( $(echo "$DEPTH >= $QC_DEPTH" | bc -l) )); then
    ASSEMBLY_QC="PASS"
else
    ASSEMBLY_QC="FAIL"
fi

echo \"Assembly_QC\",\"Contigs#\",\"Assembly_Length\",\"Seq_Depth\" > $ASSEMBLY_QC_REPORT
echo \"$ASSEMBLY_QC\",\"$CONTIGS\",\"$LENGTH\",\"$DEPTH\" >> $ASSEMBLY_QC_REPORT