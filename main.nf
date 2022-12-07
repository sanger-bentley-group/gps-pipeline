#!/usr/bin/env nextflow

// Default directory for input reads
params.reads = "$projectDir/input"
// Default output directory
params.output = "$projectDir/output"

// Get host OS type
params.os = System.properties['os.name']
// Default directory for SPAdes 
params.spades_local = "$projectDir/bin/spades"
// Default directory for Unicycler
params.unicycler_local = "$projectDir/bin/unicycler"
// Default git and local directory for SeroBA 
params.seroba_remote = "https://github.com/sanger-pathogens/seroba.git"
params.seroba_local = "$projectDir/bin/seroba"
// Default link and local directory for Kraken2 Database
params.kraken2_db_remote = "https://genome-idx.s3.amazonaws.com/kraken/k2_standard_08gb_20220926.tar.gz"
params.kraken2_db_local = "$projectDir/bin/kraken"
// Default referece genome assembly path and local directory for its BWA database 
params.ref_genome = "$projectDir/data/Streptococcus_pneumoniae_ATCC_700669_v1.fa"
params.ref_genome_bwa_db_local =  "$projectDir/bin/bwa_ref_db"

// Import modules
include { PREPROCESSING } from "$projectDir/modules/preprocessing"
include { GET_SPADES; GET_UNICYCLER; ASSEMBLING } from "$projectDir/modules/assembling"
include { GET_SEROBA_DB; SEROTYPING } from "$projectDir/modules/serotyping"
include { ASSEMBLY_QC } from "$projectDir/modules/assembly_qc"
include { GET_KRAKEN_DB; TAXONOMY } from "$projectDir/modules/taxonomy"
include { GET_REF_GENOME_BWA_DB_PREFIX; MAPPING; REF_COVERAGE; SNP_CALL; HET_SNP_SITES; MAPPING_QC } from "$projectDir/modules/mapping"


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

    // Get path to Kraken2 Database, download if necessary
    kraken2_db = GET_KRAKEN_DB(params.kraken2_db_remote, params.kraken2_db_local)

    // Get path to prefix of Reference Genome BWA Database, generate from assembly if necessary
    ref_genome_bwa_db_prefix = GET_REF_GENOME_BWA_DB_PREFIX(params.ref_genome, params.ref_genome_bwa_db_local)

    // Get read pairs into Channel raw_read_pairs_ch
    raw_read_pairs_ch = Channel.fromFilePairs( "$params.reads/*_{1,2}.fastq.gz", checkIfExists: true )

    // Preprocess read pairs
    // Output into Channels PREPROCESSING.out.processed_reads & PREPROCESSING.out.base_count
    PREPROCESSING(raw_read_pairs_ch)

    // From Channel PREPROCESSING.out.processed_reads, assemble the preprocess read pairs
    // Output into Channel ASSEMBLING.out.assembly, and hardlink the assemblies to $params.output directory
    ASSEMBLING(unicycler_runner_py, spades_py, PREPROCESSING.out.processed_reads)

    // From Channel ASSEMBLING.out.assembly and Channel PREPROCESSING.out.base_count, assess assembly quality
    // Output into Channels ASSEMBLY_QC.out.detailed_result & ASSEMBLY_QC.out.result
    ASSEMBLY_QC(
        ASSEMBLING.out.assembly
        .join(PREPROCESSING.out.base_count, failOnDuplicate: true, failOnMismatch: true)
    )

    // From Channel PREPROCESSING.out.processed_reads, serotype the preprocess read pairs
    // Output into Channels SEROTYPING.out.result
    SEROTYPING(seroba_db, PREPROCESSING.out.processed_reads)
    
    // From Channel PREPROCESSING.out.processed_reads assess Streptococcus pneumoniae percentage in reads
    // Output into Channels TAXONOMY.out.detailed_result & TAXONOMY.out.result
    TAXONOMY(kraken2_db, PREPROCESSING.out.processed_reads)

    MAPPING(ref_genome_bwa_db_prefix, PREPROCESSING.out.processed_reads)
    REF_COVERAGE(MAPPING.out.bam)
    SNP_CALL(params.ref_genome, MAPPING.out.bam) | HET_SNP_SITES
    MAPPING_QC(REF_COVERAGE.out.result.join(HET_SNP_SITES.out.result, failOnDuplicate: true))

    // Generate summary.csv by sorted sample_id based on merged Channels ASSEMBLY_QC.out.detailed_result & TAXONOMY.out.detailed_result & MAPPING_QC.out.detailed_result & SEROTYPING.out.result
    ASSEMBLY_QC.out.detailed_result
    .join(TAXONOMY.out.detailed_result, failOnDuplicate: true)
    .join(MAPPING_QC.out.detailed_result, failOnDuplicate: true)
    .join(SEROTYPING.out.result, failOnDuplicate: true)
        .map { it.join',' }
        .collectFile(
            name: "summary.csv",
            storeDir: "$params.output",
            seed: ["Sample_ID", "No_of_Contigs" , "Assembly_Length", "Seq_Depth", "Assembly_QC", "S.Pneumo_Percentage", "Taxonomy_QC", "Ref_Coverage_Percentage", "Het-SNP_Sites" ,"Mapping_QC","Serotype", "SeroBA_Comment"].join(","),
            sort: { it -> it.split(",")[0] },
            newLine: true
        )
}