# Check if database was downloaded from specific link, also prepared by the specific Kmer
# If not: remove files in database directory and download, re-create KMC and ARIBA databases, also save metadata to JSON

ZIPPED_REPO='seroba.tar.gz'

if  [ ! -f "${DB_LOCAL}/${JSON_FILE}" ] || \
    [ ! "$(grep '"url"' "${DB_LOCAL}/${JSON_FILE}" | sed -r 's/.+: "(.*)",?/\1/')" == "$DB_REMOTE" ] || \
    [ ! "$(grep '"kmer"' "${DB_LOCAL}/${JSON_FILE}" | sed -r 's/.+: "(.*)",?/\1/')" == "$KMER" ] || \
    [ ! -d "${DB_LOCAL}/ariba_db" ] || \
    [ ! -d "${DB_LOCAL}/kmer_db" ] || \
    [ ! -d "${DB_LOCAL}/streptococcus-pneumoniae-ctvdb"] || \
    [ ! -f "${DB_LOCAL}/cd_cluster.tsv" ] || \
    [ ! -f "${DB_LOCAL}/cdhit_cluster" ] || \
    [ ! -f "${DB_LOCAL}/kmer_size.txt" ] || \
    [ ! -f "${DB_LOCAL}/meta.tsv" ] || \
    [ ! -f "${DB_LOCAL}/reference.fasta" ]; then

    rm -rf "${DB_LOCAL}"

    wget "${DB_REMOTE}" -O $ZIPPED_REPO

    mkdir tmp
    tar -xzf $ZIPPED_REPO --strip-components=1 -C tmp

    mkdir -p "${DB_LOCAL}"
    mv tmp/database/* "${DB_LOCAL}"

    seroba createDBs "${DB_LOCAL}" "${KMER}"

    rm -f $ZIPPED_REPO

    echo -e "{\n  \"url\": \"$DB_REMOTE\",\n  \"kmer\": \"$KMER\",\n  \"create_time\": \"$(date +"%Y-%m-%d %H:%M:%S %Z")\"\n}" > "${DB_LOCAL}/${JSON_FILE}"

fi
