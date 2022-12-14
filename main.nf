#!/usr/bin/env nextflow


// Import modules
include { PREPROCESS } from "$projectDir/modules/preprocess"
include { GET_SPADES; GET_UNICYCLER; ASSEMBLY; ASSEMBLY_QC } from "$projectDir/modules/assembly"
include { GET_REF_GENOME_BWA_DB_PREFIX; MAPPING; REF_COVERAGE; SNP_CALL; HET_SNP_COUNT; MAPPING_QC } from "$projectDir/modules/mapping"
include { GET_KRAKEN_DB; TAXONOMY } from "$projectDir/modules/taxonomy"
include { OVERALL_QC } from "$projectDir/modules/overall_qc"
include { GET_SEROBA_DB; SEROTYPE } from "$projectDir/modules/serotype"
include { MLST } from "$projectDir/modules/mlst"


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
    // Output into Channels PREPROCESS.out.processed_reads & PREPROCESS.out.base_count
    PREPROCESS(raw_read_pairs_ch)

    // From Channel PREPROCESS.out.processed_reads, assemble the preprocess read pairs
    // Output into Channel ASSEMBLY.out.assembly, and hardlink the assemblies to $params.output directory
    ASSEMBLY(unicycler_runner_py, spades_py, PREPROCESS.out.processed_reads)

    // From Channel ASSEMBLY.out.assembly and Channel PREPROCESS.out.base_count, assess assembly quality
    // Output into Channels ASSEMBLY_QC.out.detailed_result & ASSEMBLY_QC.out.result
    ASSEMBLY_QC(
        ASSEMBLY.out.assembly
        .join(PREPROCESS.out.base_count, failOnDuplicate: true, failOnMismatch: true)
    )
    
    // From Channel PREPROCESS.out.processed_reads map reads to reference
    // Output into Channel MAPPING.out.bam
    MAPPING(ref_genome_bwa_db_prefix, PREPROCESS.out.processed_reads)

    // From Channel MAPPING.out.bam calculates reference coverage and non-cluster Het-SNP site count respecitvely
    // Output into Channels REF_COVERAGE.out.result & HET_SNP_COUNT.out.result respectively
    REF_COVERAGE(MAPPING.out.bam)
    SNP_CALL(params.ref_genome, MAPPING.out.bam) | HET_SNP_COUNT
    // Merge Channels REF_COVERAGE.out.result & HET_SNP_COUNT.out.result to provide Mapping QC Status
    // Output into Channels MAPPING_QC.out.detailed_result & MAPPING_QC.out.result
    MAPPING_QC(
        REF_COVERAGE.out.result
        .join(HET_SNP_COUNT.out.result, failOnDuplicate: true, failOnMismatch: true)
    )

    // From Channel PREPROCESS.out.processed_reads assess Streptococcus pneumoniae percentage in reads
    // Output into Channels TAXONOMY.out.detailed_result & TAXONOMY.out.result
    TAXONOMY(kraken2_db, params.kraken2_memory_mapping, PREPROCESS.out.processed_reads)

    // Merge Channels ASSEMBLY_QC.out.result & MAPPING_QC.out.result & TAXONOMY.out.result to provide Overall QC Status
    // Output into Channel OVERALL_QC.out.result
    OVERALL_QC(
        ASSEMBLY_QC.out.result
        .join(MAPPING_QC.out.result, failOnDuplicate: true, failOnMismatch: true)
        .join(TAXONOMY.out.result, failOnDuplicate: true, failOnMismatch: true)
    )

    // From Channel PREPROCESS.out.processed_reads, only output reads of samples passed overall QC based on Channel OVERALL_QC.out.result
    QC_PASSED_READS_ch = OVERALL_QC.out.result.join(PREPROCESS.out.processed_reads, failOnDuplicate: true, failOnMismatch: true)
                        .filter { it[1] == "PASS" }
                        .map { it -> it[0, 2..-1] }

    // From Channel ASSEMBLY.out.assembly, only output assemblies of samples passed overall QC based on Channel OVERALL_QC.out.result
    QC_PASSED_ASSEMBLIES_ch = OVERALL_QC.out.result.join(ASSEMBLY.out.assembly, failOnDuplicate: true, failOnMismatch: true)
                            .filter { it[1] == "PASS" }
                            .map { it -> it[0, 2..-1] }

    // From Channel QC_PASSED_READS_ch, serotype the preprocess reads of samples passed overall QC
    // Output into Channel SEROTYPE.out.result
    SEROTYPE(seroba_db, QC_PASSED_READS_ch)

    // From Channel QC_PASSED_ASSEMBLIES_ch, PubMLST typing the assemblies of samples passed overall QC
    // Output into Channel MLST.out.result
    MLST(QC_PASSED_ASSEMBLIES_ch)

    // Generate summary.csv by sorted sample_id based on merged Channels ASSEMBLY_QC.out.detailed_result & MAPPING_QC.out.detailed_result & TAXONOMY.out.detailed_result & SEROTYPE.out.result & MLST.out.result
    ASSEMBLY_QC.out.detailed_result
    .join(MAPPING_QC.out.detailed_result, failOnDuplicate: true, failOnMismatch: true)
    .join(TAXONOMY.out.detailed_result, failOnDuplicate: true, failOnMismatch: true)
    .join(OVERALL_QC.out.result, failOnDuplicate: true, failOnMismatch: true)
    .join(SEROTYPE.out.result, failOnDuplicate: true, remainder: true)
        .map { it -> (it[-1] == null) ? it[0..-2] + ["_"] * 2 : it}
    .join(MLST.out.result, failOnDuplicate: true, remainder: true)
        .map { it -> (it[-1] == null) ? it[0..-2] + ["_"] * 8: it}
    .map { it.join',' }
    .collectFile(
        name: "summary.csv",
        storeDir: "$params.output",
        seed: [
                "Sample_ID",
                "Contigs#" , "Assembly_Length", "Seq_Depth", "Assembly_QC", 
                "Ref_Cov_%", "Het-SNP#" , "Mapping_QC",
                "S.Pneumo_%", "Taxonomy_QC", "Overall_QC", 
                "Serotype", "SeroBA_Comment", 
                "ST", "aroE", "gdh", "gki", "recP", "spi", "xpt", "ddl"
            ].join(","),
        sort: { it -> it.split(",")[0] },
        newLine: true
    )
}