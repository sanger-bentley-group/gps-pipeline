if [ $CREATE_DB = true ]; then

    seroba createDBs ${DB_LOCAL}/${DATABASE}/ ${KMER}

    echo -e "{\n  \"git\": \"$DB_REMOTE\",\n  \"kmer\": \"$KMER\",\n  \"create_time\": \"$(date +"%Y-%m-%d %H:%M:%S %Z")\"\n}" > ${DB_LOCAL}/done_seroba.json

fi