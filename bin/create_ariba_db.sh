# Check if CREATE_ARIBA_DB has run successfully on the specific reference sequences and metadata.
# If not: remove the $OUTPUT directory, and prepare the ARIBA database from reference sequences and metadata, also save metadata to done_ariba_db.json

JSON="done_ariba_db.json"

REF_SEQUENCES_MD5=$(md5sum $REF_SEQUENCES | awk '{ print $1 }')
METADATA_MD5=$(md5sum $METADATA | awk '{ print $1 }')

if  [ ! -f ${DB_LOCAL}/${JSON} ] || \
    [ ! "$(grep '"reference"' ${DB_LOCAL}/${JSON} | sed -r 's/.+: "(.*)",/\1/')" == "$REF_SEQUENCES" ] || \
    [ ! "$(grep '"reference_md5"' ${DB_LOCAL}/${JSON} | sed -r 's/.+: "(.*)",/\1/')" == "$REF_SEQUENCES_MD5" ] || \
    [ ! "$(grep '"metadata"' ${DB_LOCAL}/${JSON} | sed -r 's/.+: "(.*)",/\1/')" == "$METADATA" ] || \
    [ ! "$(grep '"metadata_md5"' ${DB_LOCAL}/${JSON} | sed -r 's/.+: "(.*)",/\1/')" == "$METADATA_MD5" ] || \
    [ ! -f ${DB_LOCAL}/${OUTPUT}/00.info.txt ] || \
    [ ! -f ${DB_LOCAL}/${OUTPUT}/00.version_info.txt ] || \
    [ ! -f ${DB_LOCAL}/${OUTPUT}/01.filter.check_genes.log ] || \
    [ ! -f ${DB_LOCAL}/${OUTPUT}/01.filter.check_metadata.log ] || \
    [ ! -f ${DB_LOCAL}/${OUTPUT}/01.filter.check_metadata.tsv ] || \
    [ ! -f ${DB_LOCAL}/${OUTPUT}/01.filter.check_noncoding.log ] || \
    [ ! -f ${DB_LOCAL}/${OUTPUT}/02.cdhit.all.fa ] || \
    [ ! -f ${DB_LOCAL}/${OUTPUT}/02.cdhit.clusters.pickle ] || \
    [ ! -f ${DB_LOCAL}/${OUTPUT}/02.cdhit.clusters.tsv ] || \
    [ ! -f ${DB_LOCAL}/${OUTPUT}/02.cdhit.gene.fa ] || \
    [ ! -f ${DB_LOCAL}/${OUTPUT}/02.cdhit.gene.varonly.fa ] || \
    [ ! -f ${DB_LOCAL}/${OUTPUT}/02.cdhit.noncoding.fa ] || \
    [ ! -f ${DB_LOCAL}/${OUTPUT}/02.cdhit.noncoding.varonly.fa ] ; then

    rm -rf "$DB_LOCAL/$OUTPUT"
    
    ariba prepareref -f "$REF_SEQUENCES" -m "$METADATA" "$DB_LOCAL/$OUTPUT"

    echo -e "{\n  \"reference\": \"$REF_SEQUENCES\",\n  \"reference_md5\": \"$REF_SEQUENCES_MD5\",\n  \"metadata\": \"$METADATA\",\n  \"metadata_md5\": \"$METADATA_MD5\",\n  \"create_time\": \"$(date +"%Y-%m-%d %H:%M:%S %Z")\"\n}" > ${DB_LOCAL}/${JSON}

fi