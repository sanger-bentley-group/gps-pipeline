// Return PopPUNK database path and database name, download if necessary
process GET_POPPUNK_DB {
    label 'bash_container'
    label 'farm_low'

    input:
    val db_remote
    path local

    output:
    path local, emit: path
    env DB_NAME, emit: database

    script:
    json='done_poppunk.json'
    """
    DB_REMOTE="$db_remote"
    DB_LOCAL="$local"
    JSON_FILE="$json"

    source check-download_poppunk_db.sh
    """
}

// Return PopPUNK External Clusters file name, download if necessary
process GET_POPPUNK_EXT_CLUSTERS {
    label 'bash_container'
    label 'farm_low'

    input:
    val ext_clusters_remote
    path local

    output:
    env EXT_CLUSTERS_CSV, emit: file

    script:
    json='done_poppunk_ext.json'
    """
    EXT_CLUSTERS_REMOTE="$ext_clusters_remote"
    EXT_CLUSTERS_LOCAL="$local"
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
    label 'farm_scratchless'

    tag 'All samples'

    input:
    path poppunk_dir
    val db_name
    val ext_clusters_file
    path qfile

    output:
    path '*.csv', emit: reports

    script:
    """
    QFILE="$qfile"
    POPPUNK_DIR="$poppunk_dir"
    DB_NAME="$db_name"
    EXT_CLUSTERS_FILE="$ext_clusters_file"

    source get_lineage.sh
    """
}
