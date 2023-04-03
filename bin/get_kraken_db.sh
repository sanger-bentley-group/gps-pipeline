DB_NAME=$(basename $DB_REMOTE)

if  [ ! -f ${DB_LOCAL}/done_kraken.json ] || \
    [ ! "$DB_REMOTE" == "$(jq -r .url ${DB_LOCAL}/done_kraken.json)"  ] || \
    [ ! -f ${DB_LOCAL}/hash.k2d ] || \
    [ ! -f ${DB_LOCAL}/opts.k2d ] || \
    [ ! -f ${DB_LOCAL}/taxo.k2d ]; then

    rm -rf ${DB_LOCAL}/{,.[!.],..?}*

    wget ${DB_REMOTE} -O kraken_db.tar.gz
    tar -xzf kraken_db.tar.gz -C ${DB_LOCAL}
    rm -f kraken_db.tar.gz

    jq -n \
        --arg url "${DB_REMOTE}" \
        --arg save_time "$(date +"%Y-%m-%d %H:%M:%S %Z")" \
        '{"url" : $url, "save_time": $save_time}' > ${DB_LOCAL}/done_kraken.json

fi