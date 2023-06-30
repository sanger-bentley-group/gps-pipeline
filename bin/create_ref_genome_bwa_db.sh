# Check if CREATE_REF_GENOME_BWA_DB has run successfully on the specific reference.
# If not: remove files in database directory, and construct the FM-index database of the reference genome for BWA, also save metadata to done_bwa_db.json

if  [ ! -f ${DB_LOCAL}/done_bwa_db.json ] || \
    [ ! "$(grep 'reference' ${DB_LOCAL}/done_bwa_db.json | sed -r 's/.+: "(.*)",/\1/')" == "$REFERENCE" ] || \
    [ ! -f ${DB_LOCAL}/${PREFIX}.amb ] || \
    [ ! -f ${DB_LOCAL}/${PREFIX}.ann ] || \
    [ ! -f ${DB_LOCAL}/${PREFIX}.bwt ] || \
    [ ! -f ${DB_LOCAL}/${PREFIX}.pac ] || \
    [ ! -f ${DB_LOCAL}/${PREFIX}.sa ] ; then

    rm -rf ${DB_LOCAL}/{,.[!.],..?}*

    bwa index -p $PREFIX $REFERENCE

    mv ${PREFIX}.amb ${PREFIX}.ann ${PREFIX}.bwt ${PREFIX}.pac ${PREFIX}.sa -t $DB_LOCAL

    echo -e "{\n  \"reference\": \"$REFERENCE\",\n  \"create_time\": \"$(date +"%Y-%m-%d %H:%M:%S %Z")\"\n}" > ${DB_LOCAL}/done_bwa_db.json

fi
