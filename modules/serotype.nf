// Return SeroBA databases path, download and create databases if necessary
process GET_SEROBA_DB {
    label 'seroba_container'
    label 'farm_low'
    label 'farm_scratchless'
    label 'farm_slow'

    input:
    val remote
    path db
    val kmer

    output:
    path seroba_db, emit: path

    script:
    seroba_db="${db}/seroba"
    json='done_seroba.json'
    """
    DB_REMOTE="$remote"
    DB_LOCAL="$seroba_db"
    KMER="$kmer"
    JSON_FILE="$json"

    source check-create_seroba_db.sh
    """
}

// Run SeroBA to serotype samples
process SEROTYPE {
    label 'seroba_container'
    label 'farm_mid'

    tag "$sample_id"

    input:
    path seroba_db
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    tuple val(sample_id), path(serotype_report), emit: report

    script:
    serotype_report='serotype_report.csv'
    """
    SEROBA_DB="$seroba_db"
    READ1="$read1"
    READ2="$read2"
    SAMPLE_ID="$sample_id"
    SEROTYPE_REPORT="$serotype_report"

    source get_serotype.sh
    """
}
