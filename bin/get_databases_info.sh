# Save received databases information into a JSON file

add_bwa_db () {
    BWA_DB_JSON=${BWA_DB_PATH}/${BWA_JSON}
    if [ -f "$BWA_DB_JSON" ]; then
        REFERENCE=$(jq -r .reference $BWA_DB_JSON)
        REFERENCE_MD5=$(jq -r .reference_md5 $BWA_DB_JSON)
        CREATE_TIME=$(jq -r .create_time $BWA_DB_JSON)
    else
        REFERENCE="Not yet created"
        REFERENCE_MD5="Not yet created"
        CREATE_TIME="Not yet created"
    fi
    jq -n --arg ref "$REFERENCE" --arg ref_md5 "$REFERENCE_MD5" --arg create_time "$CREATE_TIME" '. = {"reference": $ref, "reference_md5": $ref_md5, "create_time": $create_time}'
}

add_ariba_db () {
    ARIBA_DB_JSON=${ARIBA_DB_PATH}/${ARIBA_JSON}
    if [ -f "$ARIBA_DB_JSON" ]; then
        REFERENCE=$(jq -r .reference $ARIBA_DB_JSON)
        REFERENCE_MD5=$(jq -r .reference_md5 $ARIBA_DB_JSON)
        METADATA=$(jq -r .metadata $ARIBA_DB_JSON)
        METADATA_MD5=$(jq -r .metadata_md5 $ARIBA_DB_JSON)
        CREATE_TIME=$(jq -r .create_time $ARIBA_DB_JSON)
    else
        REFERENCE="Not yet created"
        REFERENCE_MD5="Not yet created"
        METADATA="Not yet created"
        METADATA_MD5="Not yet created"
        CREATE_TIME="Not yet created"
    fi
    jq -n --arg ref "$REFERENCE" --arg ref_md5 "$REFERENCE_MD5" --arg meta "$METADATA" --arg meta_md5 "$METADATA_MD5" --arg create_time "$CREATE_TIME" '. = {"reference": $ref, "reference_md5": $ref_md5, "metadata": $meta, "metadata_md5": $meta_md5, "create_time": $create_time}'
}

add_seroba_db () {
    SEROBA_DB_JSON=${SEROBA_DB_PATH}/${SEROBA_JSON}
    if [ -f "$SEROBA_DB_JSON" ]; then
        GIT=$(jq -r .git $SEROBA_DB_JSON)
        KMER=$(jq -r .kmer $SEROBA_DB_JSON)
        CREATE_TIME=$(jq -r .create_time $SEROBA_DB_JSON)
    else
        GIT="Not yet created"
        KMER="Not yet created"
        CREATE_TIME="Not yet created"
    fi
    jq -n --arg git "$GIT" --arg kmer "$KMER" --arg create_time "$CREATE_TIME" '. = {"git": $git, "kmer": $kmer, "create_time": $create_time}'
}

add_url_db () {
    DB_JSON=$1
    if [ -f "$DB_JSON" ]; then
        URL=$(jq -r .url $DB_JSON)
        SAVE_TIME=$(jq -r .save_time $DB_JSON)
    else
        URL="Not yet downloaded"
        SAVE_TIME="Not yet downloaded"
    fi
    jq -n --arg url "$URL" --arg save_time "$SAVE_TIME" '. = {"url": $url, "save_time": $save_time}'
}

jq -n \
    --argjson bwa_db "$(add_bwa_db)" \
    --argjson ariba_db "$(add_ariba_db)" \
    --argjson seroba_db "$(add_seroba_db)" \
    --argjson kraken2_db "$(add_url_db "${KRAKEN2_DB_PATH}/${KRAKEN2_JSON}")" \
    --argjson poppunnk_db "$(add_url_db "${POPPUNK_DB_PATH}/${POPPUNK_JSON}")" \
    --argjson poppunk_ext "$(add_url_db "${POPPUNK_DB_PATH}/${POPPUNK_EXT_JSON}")" \
    '$ARGS.named' > $JSON_FILE
