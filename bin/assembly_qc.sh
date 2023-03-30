REPORT=$1
BASES=$2
QC_CONTIGS=$3
QC_LENGTH_LOW=$4
QC_LENGTH_HIGH=$5
QC_DEPTH=$6

CONTIGS=$(awk -F'\t' '$1 == "# contigs" { print $2 }' $REPORT)
LENGTH=$(awk -F'\t' '$1 == "Total length" { print $2 }' $REPORT)
DEPTH=$(printf %.2f $(echo "$BASES / $LENGTH" | bc -l) )

if (( $CONTIGS < $QC_CONTIGS )) && (( $LENGTH >= $QC_LENGTH_LOW )) && (( $LENGTH <= $QC_LENGTH_HIGH )) && (( $(echo "$DEPTH >= $QC_DEPTH" | bc -l) )); then
    ASSEMBLY_QC="PASS"
else
    ASSEMBLY_QC="FAIL"
fi
