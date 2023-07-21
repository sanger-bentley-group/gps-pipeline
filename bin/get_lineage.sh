# Run PopPUNK to assign GPSCs to samples

# Add "prefix_" to all sample names in qfile to avoid poppunk_assign crashing due to sample name already exists in database
# Remove "prefix_" from all sample names in the result

# Save results of individual sample into .csv with its name as filename 

sed 's/^/prefix_/' "$QFILE" > safe_qfile.txt
poppunk_assign --db "${POPPUNK_DIR}/${DB_NAME}" --external-clustering "${POPPUNK_DIR}/${EXT_CLUSTERS_FILE}" --query safe_qfile.txt --output output --threads $(nproc)
sed 's/^prefix_//' output/output_external_clusters.csv > result.txt


awk -F , 'NR!=1 { print "\"GPSC\"\n" "\"" $2 "\"" > $1 ".csv" }' result.txt