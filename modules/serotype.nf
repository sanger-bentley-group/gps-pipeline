// Return boolean of CREATE_DB
// Check if GET_SEROBA_DB and CREATE_SEROBA_DB has run successfully and pull to check if SeroBA database is up-to-date.
// If outdated or does not exist: clean and clone, set CREATE_DB to true
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

// Return SeroBA databases path
// If create_db == true: re-create KMC and ARIBA databases
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
    """
    SEROBA_DIR="$seroba_dir"
    DATABASE="$database"
    READ1="$read1"
    READ2="$read2"
    SAMPLE_ID="$sample_id"

    source get_serotype.sh
    """
}
