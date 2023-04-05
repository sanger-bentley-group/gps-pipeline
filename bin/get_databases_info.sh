# Save received databases information into a JSON file

add_bwa_db () {
    BWA_DB_JSON=${BWA_DB_PATH}/done_bwa_db.json
    if [ -f "$BWA_DB_JSON" ]; then
        REFERENCE=$(jq -r .reference $BWA_DB_JSON)
        CREATE_TIME=$(jq -r .create_time $BWA_DB_JSON)
    else
        REFERENCE="Not yet created"
        CREATE_TIME="Not yet created"
    fi
    jq -n --arg ref "$REFERENCE" --arg create_time "$CREATE_TIME" '. = {"reference": $ref, "create_time": $create_time}'
}

add_seroba_db () {
    SEROBA_DB_JSON=${SEROBA_DB_PATH}/done_seroba.json
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
    --argjson seroba_db "$(add_seroba_db)" \
    --argjson kraken2_db "$(add_url_db "${KRAKEN2_DB_PATH}/done_kraken.json")" \
    --argjson poppunnk_db "$(add_url_db "${POPPUNK_DB_PATH}/done_poppunk.json")" \
    --argjson poppunk_ext "$(add_url_db "${POPPUNK_DB_PATH}/done_poppunk_ext.json")" \
    '$ARGS.named' > $JSON_FILE
