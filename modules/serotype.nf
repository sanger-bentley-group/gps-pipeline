// Return boolean of CREATE_DB, remove and clone if necessary
process CHECK_SEROBA_DB {
    label 'git_container'
    label 'farm_low'

    input:
    val remote
    path local
    val kmer

    output:
    env CREATE_DB, emit: create_db

    script:
    json='done_seroba.json'
    """
    DB_REMOTE="$remote"
    DB_LOCAL="$local"
    KMER="$kmer"
    JSON_FILE="$json"

    source check_seroba_db.sh
    """
}

// Return SeroBA databases path, create databases if necessary
process GET_SEROBA_DB {
    label 'seroba_container'
    label 'farm_low'

    input:
    val remote
    path local
    val create_db
    val kmer

    output:
    path local, emit: path
    val database, emit: database

    script:
    database='database'
    json='done_seroba.json'
    """
    DATABASE="$database"
    DB_REMOTE="$remote"
    DB_LOCAL="$local"
    KMER="$kmer"
    CREATE_DB="$create_db"
    JSON_FILE="$json"

    source create_seroba_db.sh
    """
}

// Run SeroBA to serotype samples
process SEROTYPE {
    label 'seroba_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    path seroba_dir
    val database
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    tuple val(sample_id), path(serotype_report), emit: report

    script:
    serotype_report='serotype_report.csv'
    // When using Singularity as container engine, SeroBA sometimes gives incorrect result or critical error
    // Uncertain root cause, happen randomly when input are located directly in a Nextflow process work directory
    // Workaround: create and use a subdirectory to alter the path
    if (workflow.containerEngine === 'docker')
        """
        SEROBA_DIR="$seroba_dir"
        DATABASE="$database"
        READ1="$read1"
        READ2="$read2"
        SAMPLE_ID="$sample_id"
        SEROTYPE_REPORT="$serotype_report"

        source get_serotype.sh
        """
    else if (workflow.containerEngine === 'singularity')
        """
        SEROBA_DIR="$seroba_dir"
        DATABASE="$database"
        READ1="$read1"
        READ2="$read2"
        SAMPLE_ID="$sample_id"
        SEROTYPE_REPORT="$serotype_report"

        mkdir SEROBA_WORKDIR && mv $seroba_dir $read1 $read2 SEROBA_WORKDIR && cd SEROBA_WORKDIR

        source get_serotype.sh

        cd ../
        mv SEROBA_WORKDIR/$serotype_report ./
        """
    else
        error "The process must be run with Docker or Singularity as container engine."
}
