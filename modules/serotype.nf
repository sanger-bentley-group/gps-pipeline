// Return boolean of CREATE_DB, download if necessary
process GET_SEROBA_DB {
    label 'git_container'
    label 'farm_low'

    input:
    val remote
    path local
    val kmer

    output:
    env CREATE_DB, emit: create_db

    script:
    """
    DB_REMOTE="$remote"
    DB_LOCAL="$local"
    KMER="$kmer"

    source get_seroba_db.sh
    """
}

// Return SeroBA databases path, create databases if necessary
process CREATE_SEROBA_DB {
    label 'seroba_container'
    label 'farm_low'

    input:
    val remote
    path local
    val create_db
    val kmer

    output:
    tuple path(local), val(database)

    script:
    database='database'
    """
    DATABASE="$database"
    DB_REMOTE="$remote"
    DB_LOCAL="$local"
    KMER="$kmer"
    CREATE_DB="$create_db"

    source create_seroba_db.sh
    """
}

// Run SeroBA to serotype samples
process SEROTYPE {
    label 'seroba_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple path(seroba_dir), val(database)
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    tuple val(sample_id), env(SEROTYPE), env(SEROBA_COMMENT), emit: result

    script:
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

        source get_serotype.sh
        """
    else if (workflow.containerEngine === 'singularity')
        """
        SEROBA_DIR="$seroba_dir"
        DATABASE="$database"
        READ1="$read1"
        READ2="$read2"
        SAMPLE_ID="$sample_id"

        mkdir SEROBA_WORKDIR && mv $seroba_dir $read1 $read2 SEROBA_WORKDIR && cd SEROBA_WORKDIR

        source get_serotype.sh

        cd ../
        """
    else
        error "The process must be run with Docker or Singularity as container engine."
}
