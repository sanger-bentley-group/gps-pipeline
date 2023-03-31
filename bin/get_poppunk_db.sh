DB_NAME=$(basename "$DB_REMOTE" .tar.gz)
DB_PATH="$DB_LOCAL"/${DB_NAME}

if  [ ! -f ${DB_LOCAL}/done_poppunk.json ] || \
    [ ! "$DB_REMOTE" == "$(jq -r .url ${DB_LOCAL}/done_poppunk.json)"  ] || \
    [ ! -f ${DB_PATH}/${DB_NAME}.h5 ] || \
    [ ! -f ${DB_PATH}/${DB_NAME}.dists.npy ] || \
    [ ! -f ${DB_PATH}/${DB_NAME}.dists.pkl ] || \
    [ ! -f ${DB_PATH}/${DB_NAME}_fit.npz ] || \
    [ ! -f ${DB_PATH}/${DB_NAME}_fit.pkl ] || \
    [ ! -f ${DB_PATH}/${DB_NAME}_graph.gt ] || \
    [ ! -f ${DB_PATH}/${DB_NAME}_clusters.csv ] || \
    [ ! -f ${DB_PATH}/${DB_NAME}.refs ]; then

    rm -rf ${DB_LOCAL}/done_poppunk.json
    rm -rf ${DB_LOCAL}/*/

    wget $DB_REMOTE -O poppunk_db.tar.gz
    tar -xzf poppunk_db.tar.gz -C $DB_LOCAL
    rm poppunk_db.tar.gz

    jq -n \
        --arg url "$DB_REMOTE" \
        --arg save_time "$(date +"%Y-%m-%d %H:%M:%S %Z")" \
        '{"url" : $url, "save_time": $save_time}' > ${DB_LOCAL}/done_poppunk.json

fi