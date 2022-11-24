#!/usr/bin/env nextflow

// Get host OS type
params.os = System.properties['os.name']
// Default directory for input reads
params.reads = "${projectDir}/data"
// Default directory for SPAdes 
params.spades_local = "${projectDir}/bin/spades"
// Default directory for Unicycler
params.unicycler_local = "${projectDir}/bin/unicycler"
// Default git and local directory for SeroBA 
params.seroba_remote = "https://github.com/sanger-pathogens/seroba.git"
params.seroba_local = "${projectDir}/bin/seroba"


// Import modules
include { PREPROCESSING } from './modules/preprocessing'
include { GET_SPADES; GET_UNICYCLER; ASSEMBLING } from './modules/assembling'
include { GET_SEROBA_DB; SEROTYPING; SEROTYPE_SUMMARY } from './modules/serotyping'


// Main workflow
workflow {
    // ===============
    
    // Currently SPAdes v3.15.5 and Unicycler v0.5.0 are not available in Conda of MacOS, 
    // and older versions yield suboptimal assemblies or lead to critical errors
    // therefore separate download / compiling is required for now
    // might remove this part and update environment.yml when the pipeline is dockerised in a Linux environment
    
    // Get path to SPAdes executable, download if necessary
    spades_py = GET_SPADES(params.os, params.spades_local)
    
    // Get path to Unicycler executable, download if necessary
    unicycler_runner_py = GET_UNICYCLER(params.os, params.unicycler_local)
    
    // ===============

    // Get path to SeroBA databases, clone and rebuild if necessary
    seroba_db = GET_SEROBA_DB(params.seroba_remote, params.seroba_local)

    // Get read pairs into Channel raw_read_pairs_ch
    raw_read_pairs_ch = Channel.fromFilePairs( "$params.reads/*_{1,2}.fastq.gz", checkIfExists: true )

    // Preprocess read pairs, and output into Channel prcoessed_reads_ch
    prcoessed_reads_ch = PREPROCESSING(raw_read_pairs_ch)

    // From the Channel prcoessed_reads_ch, assemble the preprocess read pairs 
    ASSEMBLING(unicycler_runner_py, spades_py, prcoessed_reads_ch)

    // From the Channel prcoessed_reads_ch, serotype the preprocess read pairs, then summarise the results
    serotype_ch = SEROTYPING(seroba_db, prcoessed_reads_ch)
    SEROTYPE_SUMMARY(serotype_ch.collect())
}