#!/usr/bin/env nextflow

// Get host OS type
params.os = System.properties['os.name']
// Default directory for input reads
params.reads = "$projectDir/data"
// Default directory for SPAdes 
params.spades_local = "$projectDir/bin/spades"
// Default directory for Unicycler
params.unicycler_local = "$projectDir/bin/unicycler"
// Default git and local directory for SeroBA 
params.seroba_remote = "https://github.com/sanger-pathogens/seroba.git"
params.seroba_local = "$projectDir/bin/seroba"
// Default output directory
params.output = "$projectDir/results"


// Import modules
include { PREPROCESSING } from "$projectDir/modules/preprocessing"
include { GET_SPADES; GET_UNICYCLER; ASSEMBLING } from "$projectDir/modules/assembling"
include { GET_SEROBA_DB; SEROTYPING } from "$projectDir/modules/serotyping"
include { ASSEMBLY_QC } from "$projectDir/modules/assembly_qc"


// Main workflow
workflow {
    // ===============
    
    // Currently SPAdes v3.15.5 and Unicycler v0.5.0 are not available in Conda of MacOS, 
    // and older versions yield suboptimal assemblies or lead to critical errors
    // therefore separate download / compiling for MacOS is required for now
    // might update this part and merge environment_*.yml when the pipeline is dockerised in a Linux environment
    
    // Get path to SPAdes executable, download if necessary
    spades_py = ( params.os == "Mac OS X" ) ? GET_SPADES(params.spades_local) : "spades.py"
    
    // Get path to Unicycler executable, download if necessary
    unicycler_runner_py = ( params.os == "Mac OS X" ) ? GET_UNICYCLER(params.unicycler_local) : "unicycler"
    
    // ===============

    // Get path to SeroBA databases, clone and rebuild if necessary
    seroba_db = GET_SEROBA_DB(params.seroba_remote, params.seroba_local)

    // Get read pairs into Channel raw_read_pairs_ch
    raw_read_pairs_ch = Channel.fromFilePairs( "$params.reads/*_{1,2}.fastq.gz", checkIfExists: true )

    // Preprocess read pairs
    // Output into Channel PREPROCESSING.out.processed_reads and Channel PREPROCESSING.out.base_count
    PREPROCESSING(raw_read_pairs_ch)

    // From Channel PREPROCESSING.out.processed_reads, assemble the preprocess read pairs
    // Output into Channel ASSEMBLING.out.assembly, and hardlink the assemblies to $params.output directory
    ASSEMBLING(unicycler_runner_py, spades_py, PREPROCESSING.out.processed_reads)


    // From Channel ASSEMBLING.out.assembly and Channel PREPROCESSING.out.base_count, assess assembly quality
    // Output into Channel ASSEMBLY_QC.out.results
    ASSEMBLY_QC(
        ASSEMBLING.out.assembly.join(PREPROCESSING.out.base_count, by: 0, failOnDuplicate: true, failOnMismatch: true)
    ).view()

    // From Channel PREPROCESSING.out.processed_reads, serotype the preprocess read pairs, then gather the results
    // Save as serotype_summary.tsv
    SEROTYPING(seroba_db, PREPROCESSING.out.processed_reads)
        .collectFile(name: 'serotype_summary.tsv', storeDir: "$params.output")
}