// Return PopPUNK database path
// Check if GET_POPPUNK_DB has run successfully on the specific database.
// If not: clean, download, and unzip to params.poppunk_db_local
process GET_POPPUNK_DB {
    input:
    val db_remote
    val local

    output:
    env POPPUNK_DB_DIR

    shell:
    '''
    DB_NAME=$(basename !{db_remote} .zip)

    if [ ! -f !{local}/$DB_NAME/done_poppunk_$DB_NAME ] || [ ! -f !{local}/$DB_NAME/$DB_NAME.h5 ]; then
        rm -rf !{local}/$DB_NAME
        mkdir -p !{local}

        curl -L !{db_remote} > $DB_NAME.zip
        jar -xf $DB_NAME.zip -C !{local}

        rm $DB_NAME.zip

        touch !{local}/$DB_NAME/done_poppunk_$DB_NAME
    fi

    POPPUNK_DB_DIR=!{local}/$DB_NAME
    '''
}

// Return PopPUNK External Clusters file path
// Check if GET_POPPUNK_EXT_CLUSTERS has run successfully on the specific external clusters file.
// If not: clean, download, and unzip to params.poppunk_db_local
process GET_POPPUNK_EXT_CLUSTERS {
    input:
    val ext_clusters_remote
    val local

    output:
    env EXT_CLUSTERS_PATH

    shell:
    '''
    EXT_CLUSTERS_FILE=$(basename !{ext_clusters_remote})

    if [ ! -f !{local}/$EXT_CLUSTERS_FILE ] || [ ! -f !{local}/done_$EXT_CLUSTERS_FILE ]; then
        rm -f !{local}/$EXT_CLUSTERS_FILE
        mkdir -p !{local}

        curl -L !{ext_clusters_remote} > !{local}/$EXT_CLUSTERS_FILE

        touch !{local}/done_$EXT_CLUSTERS_FILE
    fi

    EXT_CLUSTERS_PATH=!{local}/$EXT_CLUSTERS_FILE
    '''
}

// Run PopPUNK to assign GPSCs to samples
process LINEAGE {
    input:
    path poppunk_db
    path poppunk_ext_clusters
    path poppunk_qfile

    output:
    path "output/output_external_clusters.csv", emit: csv

    shell:
    '''
    sed -i 's/^/prefix_/' !{poppunk_qfile}
    poppunk_assign --db !{poppunk_db} --external-clustering !{poppunk_ext_clusters} --query !{poppunk_qfile} --output output --threads !{task.cpus}
    sed -i 's/prefix_//' output/output_external_clusters.csv
    '''
}