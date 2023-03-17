// Return PopPUNK database path and database name
// Check if GET_POPPUNK_DB has run successfully on the specific database.
// If not: clean, download, and unzip to params.poppunk_local
process GET_POPPUNK_DB {
    label 'bash_container'

    input:
    val db_remote
    path local

    output:
    tuple path(local), env(DB_NAME)

    shell:
    '''
    DB_NAME=$(basename !{db_remote} .tar.gz)
    DB_PATH=!{local}/${DB_NAME}

    if  [ ! -f !{local}/done_poppunk.json ] || \
        [ ! "!{db_remote}" == "$(jq -r .url !{local}/done_poppunk.json)"  ] || \
        [ ! -f ${DB_PATH}/${DB_NAME}.h5 ] || \
        [ ! -f ${DB_PATH}/${DB_NAME}.dists.npy ] || \
        [ ! -f ${DB_PATH}/${DB_NAME}.dists.pkl ] || \
        [ ! -f ${DB_PATH}/${DB_NAME}_fit.npz ] || \
        [ ! -f ${DB_PATH}/${DB_NAME}_fit.pkl ] || \
        [ ! -f ${DB_PATH}/${DB_NAME}_graph.gt ] || \
        [ ! -f ${DB_PATH}/${DB_NAME}_clusters.csv ] || \
        [ ! -f ${DB_PATH}/${DB_NAME}.refs ]; then

        rm -rf !{local}/done_poppunk.json
        rm -rf !{local}/*/

        wget !{db_remote} -O poppunk_db.tar.gz
        tar -xzf poppunk_db.tar.gz -C !{local}
        rm poppunk_db.tar.gz

        jq -n \
            --arg url "!{db_remote}" \
            --arg save_time "$(date +"%Y-%m-%d %H:%M:%S")" \
            '{"url" : $url, "save_time": $save_time}' > !{local}/done_poppunk.json

    fi
    '''
}

// Return PopPUNK External Clusters file name
// Check if GET_POPPUNK_EXT_CLUSTERS has run successfully on the specific external clusters file.
// If not: clean and download to params.poppunk_local
process GET_POPPUNK_EXT_CLUSTERS {
    label 'bash_container'

    input:
    val ext_clusters_remote
    path local

    output:
    env EXT_CLUSTERS_CSV

    shell:
    '''
    EXT_CLUSTERS_CSV=$(basename !{ext_clusters_remote})
    EXT_CLUSTERS_NAME=$(basename !{ext_clusters_remote} .csv)

    if  [ ! -f !{local}/done_poppunk_ext.json ] || \
        [ ! "!{ext_clusters_remote}" == "$(jq -r .url !{local}/done_poppunk_ext.json)"  ] || \
        [ ! -f !{local}/${EXT_CLUSTERS_CSV} ]; then

        rm -f !{local}/${EXT_CLUSTERS_CSV} !{local}/done_${EXT_CLUSTERS_NAME}.json

        wget !{ext_clusters_remote} -O !{local}/${EXT_CLUSTERS_CSV}

        jq -n \
            --arg url "!{ext_clusters_remote}" \
            --arg save_time "$(date +"%Y-%m-%d %H:%M:%S")" \
            '{"url" : $url, "save_time": $save_time}' > !{local}/done_poppunk_ext.json

    fi
    '''
}

// Run PopPUNK to assign GPSCs to samples
// Add "prefix_" to all sample names in qfile to avoid poppunk_assign crashing due to sample name already exists in database
// Remove "prefix_" from all sample names in the output
process LINEAGE {
    label 'poppunk_container'

    tag 'All samples'

    input:
    tuple path(poppunk_dir), val(db_name)
    val ext_clusters_file
    path poppunk_qfile

    output:
    path 'result.csv', emit: csv

    shell:
    '''
    sed 's/^/prefix_/' !{poppunk_qfile} > safe_qfile.txt
    poppunk_assign --db !{poppunk_dir}/!{db_name} --external-clustering !{poppunk_dir}/!{ext_clusters_file} --query safe_qfile.txt --output output --threads $(nproc)
    sed 's/^prefix_//' output/output_external_clusters.csv > result.csv
    '''
}
