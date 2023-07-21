# Run mlst to perform PubMLST typing on samples

OUTPUT='output.tsv'

mlst --legacy --scheme spneumoniae "$ASSEMBLY" > $OUTPUT

ST=$(awk -F'\t' 'FNR == 2 {print $3}' $OUTPUT)
aroE=$(awk -F'\t' 'FNR == 2 {print $4}' $OUTPUT)
gdh=$(awk -F'\t' 'FNR == 2 {print $5}' $OUTPUT)
gki=$(awk -F'\t' 'FNR == 2 {print $6}' $OUTPUT)
recP=$(awk -F'\t' 'FNR == 2 {print $7}' $OUTPUT)
spi=$(awk -F'\t' 'FNR == 2 {print $8}' $OUTPUT)
xpt=$(awk -F'\t' 'FNR == 2 {print $9}' $OUTPUT)
ddl=$(awk -F'\t' 'FNR == 2 {print $10}' $OUTPUT)

echo \"ST\",\"aroE\",\"gdh\",\"gki\",\"recP\",\"spi\",\"xpt\",\"ddl\" > $MLST_REPORT
echo \"$ST\",\"$aroE\",\"$gdh\",\"$gki\",\"$recP\",\"$spi\",\"$xpt\",\"$ddl\" >> $MLST_REPORT