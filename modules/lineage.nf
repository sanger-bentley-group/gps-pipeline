// Return PopPUNK database path and database name, download if necessary
process GET_POPPUNK_DB {
    label 'bash_container'
    label 'farm_low'
    label 'farm_scratchless'
    label 'farm_slow'

    input:
    val db_remote
    path db

    output:
    path poppunk_db, emit: path
    env DB_NAME, emit: database

    script:
    poppunk_db="${db}/poppunk"
    json='done_poppunk.json'
    """
    DB_REMOTE="$db_remote"
    DB_LOCAL="$poppunk_db"
    JSON_FILE="$json"

    source check-download_poppunk_db.sh
    """
}

// Return PopPUNK External Clusters file name, download if necessary
process GET_POPPUNK_EXT_CLUSTERS {
    label 'bash_container'
    label 'farm_low'
    label 'farm_scratchless'
    label 'farm_slow'

    input:
    val ext_clusters_remote
    path db

    output:
    path poppunk_ext, emit: path
    env EXT_CLUSTERS_CSV, emit: file

    script:
    poppunk_ext="${db}/poppunk_ext"
    json='done_poppunk_ext.json'
    """
    EXT_CLUSTERS_REMOTE="$ext_clusters_remote"
    EXT_CLUSTERS_LOCAL="$poppunk_ext"
    JSON_FILE="$json"

    source check-download_poppunk_ext_clusters.sh    
    """
}

// Run PopPUNK to assign GPSCs to samples
// Save results of individual sample into .csv with its name as filename 
process LINEAGE {
    label 'poppunk_container'
    label 'farm_high'
    label 'farm_slow'

    tag 'All samples'

    input:
    path poppunk_dir
    val db_name
    path ext_clusters_dir
    val ext_clusters_file
    path qfile

    output:
    path '*.csv', emit: reports

    script:
    """
    QFILE="$qfile"
    POPPUNK_DIR="$poppunk_dir"
    DB_NAME="$db_name"
    EXT_CLUSTERS_DIR="$ext_clusters_dir"
    EXT_CLUSTERS_FILE="$ext_clusters_file"

    source get_lineage.sh
    """
}
