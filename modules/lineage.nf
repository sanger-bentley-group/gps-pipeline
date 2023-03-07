// Return PopPUNK database path
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

    if [ ! -f !{local}/$DB_NAME/done_poppunk_$DB_NAME ] || [ ! -f !{local}/$DB_NAME/$DB_NAME.h5 ]; then
        rm -rf !{local}/$DB_NAME

        wget !{db_remote} -O poppunk_db.tar.gz
        tar -xzf poppunk_db.tar.gz -C !{local}
        rm poppunk_db.tar.gz

        touch !{local}/$DB_NAME/done_poppunk_$DB_NAME
    fi
    '''
}

// Return PopPUNK External Clusters file path
// Check if GET_POPPUNK_EXT_CLUSTERS has run successfully on the specific external clusters file.
// If not: clean and download to params.poppunk_local
process GET_POPPUNK_EXT_CLUSTERS {
    label 'bash_container'

    input:
    val ext_clusters_remote
    path local

    output:
    env EXT_CLUSTERS_FILE

    shell:
    '''
    EXT_CLUSTERS_FILE=$(basename !{ext_clusters_remote})

    if [ ! -f !{local}/$EXT_CLUSTERS_FILE ] || [ ! -f !{local}/done_$EXT_CLUSTERS_FILE ]; then
        rm -f !{local}/$EXT_CLUSTERS_FILE !{local}/done_$EXT_CLUSTERS_FILE

        wget !{ext_clusters_remote} -O !{local}/$EXT_CLUSTERS_FILE

        touch !{local}/done_$EXT_CLUSTERS_FILE
    fi
    '''
}

// Run PopPUNK to assign GPSCs to samples
// Add "prefix_" to all sample names in qfile to avoid poppunk_assign crashing due to sample name already exists in database
// Remove "prefix_" from all sample names in the output
process LINEAGE {
    label 'poppunk_container'

    input:
    tuple path(poppunk_dir), val(db_name)
    val ext_clusters_file
    path poppunk_qfile

    output:
    path "result.csv", emit: csv

    shell:
    '''
    sed 's/^/prefix_/' !{poppunk_qfile} > safe_qfile.txt
    poppunk_assign --db !{poppunk_dir}/!{db_name} --external-clustering !{poppunk_dir}/!{ext_clusters_file} --query safe_qfile.txt --output output --threads $(nproc)
    sed 's/^prefix_//' output/output_external_clusters.csv > result.csv
    '''
}