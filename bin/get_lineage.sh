# Run PopPUNK to assign GPSCs to samples

# Add "prefix_" to all sample names in qfile to avoid poppunk_assign crashing due to sample name already exists in database
# Remove "prefix_" from all sample names in the result

# Save results of individual sample into .csv with its name as filename 

awk -F '\t' '{ print "gps_pipeline_poppunk_query_" NR "\t" $2 }' "$QFILE" > safe_qfile.txt

poppunk_assign --db "${POPPUNK_DIR}/${DB_NAME}" --external-clustering "${EXT_CLUSTERS_DIR}/${EXT_CLUSTERS_FILE}" --query safe_qfile.txt --output output --threads "$(nproc)"

tail -n +2 output/output_external_clusters.csv | sort -V > result.txt

paste <(cut -f 1 "$QFILE") <(cut -f 2 -d ',' result.txt) > renamed_result.txt

awk -F '\t' '{ print "\"GPSC\"\n" "\"" $2 "\"" > $1 ".csv" }' renamed_result.txt
