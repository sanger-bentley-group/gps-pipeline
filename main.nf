#!/usr/bin/env nextflow

// Get host OS type
params.os = System.properties['os.name']
// Default directory for input reads
params.reads = "${projectDir}/data"
// Default directory for SPAdes 
params.spades_local = "${projectDir}/bin/spades"
// Default git and local directory for SeroBA 
params.seroba_remote = "https://github.com/sanger-pathogens/seroba.git"
params.seroba_local = "${projectDir}/bin/seroba"


// Import modules
include { PREPROCESSING } from './modules/preprocessing'
include { GET_SPADES; ASSEMBLING } from './modules/assembling'
include { GET_SEROBA_DB; SEROTYPING; SEROTYPE_SUMMARY } from './modules/serotyping'


// Main workflow
workflow {
    // Get path to SPAdes executable, download if necessary
    spades_py = GET_SPADES(params.os, params.spades_local)
    // Get path to SeroBA databases, clone and rebuild if necessary
    seroba_db = GET_SEROBA_DB(params.seroba_remote, params.seroba_local)

    // Get read pairs into Channel raw_read_pairs_ch
    raw_read_pairs_ch = Channel.fromFilePairs( "$params.reads/*_{1,2}.fastq.gz", checkIfExists: true )

    // Preprocess read pairs, and output into Channel prcoessed_reads_ch
    prcoessed_reads_ch = PREPROCESSING(raw_read_pairs_ch)

    // From the Channel prcoessed_reads_ch, assemble the preprocess read pairs 
    ASSEMBLING(spades_py, prcoessed_reads_ch)

    // From the Channel prcoessed_reads_ch, serotype the preprocess read pairs, then summarise the results
    serotype_ch = SEROTYPING(seroba_db, prcoessed_reads_ch)
    SEROTYPE_SUMMARY(serotype_ch.collect())
}