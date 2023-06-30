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
    """
    DB_REMOTE="$db_remote"
    DB_LOCAL="$local"

    source get_poppunk_db.sh
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
    """
    EXT_CLUSTERS_REMOTE="$ext_clusters_remote"
    EXT_CLUSTERS_LOCAL="$local"

    source get_poppunk_ext_clusters.sh    
    """
}

// Run PopPUNK to assign GPSCs to samples
// Add "prefix_" to all sample names in qfile to avoid poppunk_assign crashing due to sample name already exists in database
// Remove "prefix_" from all sample names in the output
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
    path(result), emit: csv

    script:
    result='result.csv'
    """
    sed 's/^/prefix_/' "$qfile" > safe_qfile.txt
    poppunk_assign --db "${poppunk_dir}/${db_name}" --external-clustering "${poppunk_dir}/${ext_clusters_file}" --query safe_qfile.txt --output output --threads `nproc`
    sed 's/^prefix_//' output/output_external_clusters.csv > "$result"
    """
}
