#!/usr/bin/env nextflow 

params.reads = "${projectDir}/data"
params.seroba_remote = "https://github.com/sanger-pathogens/seroba.git"
params.seroba_local = "${projectDir}/seroba"


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
    tuple val(sample_id), path(reads)

    output:
    path "$sample_id/pred.tsv"

    script:
    """
    seroba runSerotyping $database ${reads[0]} ${reads[1]} $sample_id
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


workflow {
    seroba_db = GET_SEROBA_DB(params.seroba_remote, params.seroba_local)
    read_pairs_ch = Channel.fromFilePairs( "$params.reads/*_{1,2}.fastq.gz", checkIfExists: true )
    
    serotype_ch = SEROTYPING(seroba_db, read_pairs_ch)
    
    SEROTYPE_SUMMARY(serotype_ch.collect())
}