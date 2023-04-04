# Return PopPUNK External Clusters file name

# Check if specific external clusters file exists and was obtained from the specific link.
# If not: remove all csv files, and download to database directory, also save metadata to done_poppunk_ext.json

EXT_CLUSTERS_CSV=$(basename "$EXT_CLUSTERS_REMOTE")
EXT_CLUSTERS_NAME=$(basename "$EXT_CLUSTERS_REMOTE" .csv)

if  [ ! -f ${EXT_CLUSTERS_LOCAL}/done_poppunk_ext.json ] || \
    [ ! "$EXT_CLUSTERS_REMOTE" == "$(jq -r .url ${EXT_CLUSTERS_LOCAL}/done_poppunk_ext.json)"  ] || \
    [ ! -f ${EXT_CLUSTERS_LOCAL}/${EXT_CLUSTERS_CSV} ]; then

    rm -f ${EXT_CLUSTERS_LOCAL}/*.csv
    rm -f ${EXT_CLUSTERS_LOCAL}/done_${EXT_CLUSTERS_NAME}.json

    wget $EXT_CLUSTERS_REMOTE -O ${EXT_CLUSTERS_LOCAL}/${EXT_CLUSTERS_CSV}

    jq -n \
        --arg url "$EXT_CLUSTERS_REMOTE" \
        --arg save_time "$(date +"%Y-%m-%d %H:%M:%S %Z")" \
        '{"url" : $url, "save_time": $save_time}' > ${EXT_CLUSTERS_LOCAL}/done_poppunk_ext.json

fi
