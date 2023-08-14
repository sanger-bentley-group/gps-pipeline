# Check if BWA database was prepared from the specific reference.
# If not: remove files in database directory, and construct the FM-index database of the reference genome for BWA, also save metadata to JSON

REFERENCE_MD5=$(md5sum "$REFERENCE" | awk '{ print $1 }')

if  [ ! -f "${DB_LOCAL}/${JSON_FILE}" ] || \
    [ ! "$(grep '"reference"' "${DB_LOCAL}/${JSON_FILE}" | sed -r 's/.+: "(.*)",?/\1/')" == "$REFERENCE" ] || \
    [ ! "$(grep '"reference_md5"' "${DB_LOCAL}/${JSON_FILE}" | sed -r 's/.+: "(.*)",?/\1/')" == "$REFERENCE_MD5" ] || \
    [ ! -f "${DB_LOCAL}/${PREFIX}.amb" ] || \
    [ ! -f "${DB_LOCAL}/${PREFIX}.ann" ] || \
    [ ! -f "${DB_LOCAL}/${PREFIX}.bwt" ] || \
    [ ! -f "${DB_LOCAL}/${PREFIX}.pac" ] || \
    [ ! -f "${DB_LOCAL}/${PREFIX}.sa" ] ; then

    rm -rf "${DB_LOCAL}"

    bwa index -p "$PREFIX" "$REFERENCE"

    mkdir -p "${DB_LOCAL}"
    mv "${PREFIX}.amb" "${PREFIX}.ann" "${PREFIX}.bwt" "${PREFIX}.pac" "${PREFIX}.sa" -t "${DB_LOCAL}/${OUTPUT}"

    echo -e "{\n  \"reference\": \"$REFERENCE\",\n  \"reference_md5\": \"$REFERENCE_MD5\",\n  \"create_time\": \"$(date +"%Y-%m-%d %H:%M:%S %Z")\"\n}" > "${DB_LOCAL}/${JSON_FILE}"

fi
