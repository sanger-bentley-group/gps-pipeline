// Return Seroba databases path
// Pull to check if seroba database is up-to-date. If outdated or does not exist: clean, clone and re-create kmc and ariba databases
process GET_SEROBA_DB {
    input:
    val remote
    val local

    output:
    val "$local/database"

    script:
    """
    if !(git -C $local pull | grep -q 'Already up to date'); then
        rm -rf $local
        git clone $remote $local
        seroba createDBs $local/database/ 71
    fi
    """
}

// Run Seroba to serotype samples
process SEROTYPING {
    input:
    path database
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    path "$sample_id/pred.tsv"

    script:
    """
    seroba runSerotyping $database $read1 $read2 $sample_id
    """
}

// Concatenate Seroba results
process SEROTYPE_SUMMARY {
    publishDir "results", mode: 'link'

    input:
    path "*.tsv"

    output:
    path "serotype_summary.tsv"

    script:
    """
    cat * >> serotype_summary.tsv
    """
}