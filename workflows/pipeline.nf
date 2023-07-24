// Import process modules
include { PREPROCESS; READ_QC } from "$projectDir/modules/preprocess"
include { ASSEMBLY_UNICYCLER; ASSEMBLY_SHOVILL; ASSEMBLY_ASSESS; ASSEMBLY_QC } from "$projectDir/modules/assembly"
include { CREATE_REF_GENOME_BWA_DB; MAPPING; SAM_TO_SORTED_BAM; SNP_CALL; HET_SNP_COUNT; MAPPING_QC } from "$projectDir/modules/mapping"
include { GET_KRAKEN2_DB; TAXONOMY; TAXONOMY_QC } from "$projectDir/modules/taxonomy"
include { OVERALL_QC } from "$projectDir/modules/overall_qc"
include { GET_POPPUNK_DB; GET_POPPUNK_EXT_CLUSTERS; LINEAGE } from "$projectDir/modules/lineage"
include { GET_SEROBA_DB; CREATE_SEROBA_DB; SEROTYPE } from "$projectDir/modules/serotype"
include { MLST } from "$projectDir/modules/mlst"
include { PBP_RESISTANCE; GET_PBP_RESISTANCE; CREATE_ARIBA_DB; OTHER_RESISTANCE; GET_OTHER_RESISTANCE } from "$projectDir/modules/amr"
include { GENERATE_SAMPLE_REPORT; GENERATE_OVERALL_REPORT } from "$projectDir/modules/output"

// Main pipeline workflow
workflow PIPELINE {
    main:
    // Get path and prefix of Reference Genome BWA Database, generate from assembly if necessary
    CREATE_REF_GENOME_BWA_DB(params.ref_genome, params.ref_genome_bwa_db_local)

    // Get path to Kraken2 Database, download if necessary
    GET_KRAKEN2_DB(params.kraken2_db_remote, params.kraken2_db_local)

    // Get path to SeroBA Databases, clone and rebuild if necessary
    GET_SEROBA_DB(params.seroba_remote, params.seroba_local, params.seroba_kmer)
    CREATE_SEROBA_DB(params.seroba_remote, params.seroba_local, GET_SEROBA_DB.out.create_db, params.seroba_kmer)

    // Get paths to PopPUNK Database and External Clusters, download if necessary
    GET_POPPUNK_DB(params.poppunk_db_remote, params.poppunk_local)
    GET_POPPUNK_EXT_CLUSTERS(params.poppunk_ext_remote, params.poppunk_local)

    // Get path to ARIBA database, generate from reference sequences and metadata if ncessary
    CREATE_ARIBA_DB(params.ariba_ref, params.ariba_metadata, params.ariba_db_local)

    // Get read pairs into Channel raw_read_pairs_ch
    raw_read_pairs_ch = Channel.fromFilePairs("$params.reads/*_{,R}{1,2}{,_001}.{fq,fastq}{,.gz}", checkIfExists: true)

    // Preprocess read pairs
    // Output into Channels PREPROCESS.out.processed_reads & PREPROCESS.out.json
    PREPROCESS(raw_read_pairs_ch)

    // From Channel PREPROCESS.out.json, provide Read QC status
    // Output into Channel READ_QC_PASSED_READS_ch
    READ_QC(PREPROCESS.out.json, params.length_low, params.depth)

    // From Channel PREPROCESS.out.processed_reads, only output reads of samples passed Read QC based on Channel READ_QC.out.result
    READ_QC_PASSED_READS_ch = READ_QC.out.result.join(PREPROCESS.out.processed_reads, failOnDuplicate: true, failOnMismatch: true)
                        .filter { it[1] == 'PASS' }
                        .map { it[0, 2..-1] }

    // From Channel READ_QC_PASSED_READS_ch, assemble the preprocess read pairs
    // Output into Channel ASSEMBLY_ch, and hardlink the assemblies to $params.output directory
    switch (params.assembler) {
        case 'shovill':
            ASSEMBLY_ch = ASSEMBLY_SHOVILL(READ_QC_PASSED_READS_ch, params.min_contig_length)
            break

        case 'unicycler':
            ASSEMBLY_ch = ASSEMBLY_UNICYCLER(READ_QC_PASSED_READS_ch, params.min_contig_length)
            break
    }

    // From Channel ASSEMBLY_ch, assess assembly quality
    ASSEMBLY_ASSESS(ASSEMBLY_ch)

    // From Channel ASSEMBLY_ASSESS.out.report and Channel READ_QC.out.bases, provide Assembly QC status
    // Output into Channels ASSEMBLY_QC.out.detailed_result & ASSEMBLY_QC.out.result
    ASSEMBLY_QC(
        ASSEMBLY_ASSESS.out.report
        .join(READ_QC.out.bases, failOnDuplicate: true),
        params.contigs,
        params.length_low,
        params.length_high,
        params.depth
    )

    // From Channel READ_QC_PASSED_READS_ch map reads to reference
    // Output into Channel MAPPING.out.sam
    MAPPING(CREATE_REF_GENOME_BWA_DB.out.path, CREATE_REF_GENOME_BWA_DB.out.prefix, READ_QC_PASSED_READS_ch)

    // From Channel MAPPING.out.sam, Convert SAM into sorted BAM and calculate reference coverage
    // Output into Channels SAM_TO_SORTED_BAM.out.bam and SAM_TO_SORTED_BAM.out.ref_coverage
    SAM_TO_SORTED_BAM(MAPPING.out.sam, params.lite)

    // From Channel SAM_TO_SORTED_BAM.out.bam calculates non-cluster Het-SNP site count
    // Output into Channel HET_SNP_COUNT.out.result
    SNP_CALL(params.ref_genome, SAM_TO_SORTED_BAM.out.bam, params.lite) | HET_SNP_COUNT

    // Merge Channels SAM_TO_SORTED_BAM.out.ref_coverage & HET_SNP_COUNT.out.result to provide Mapping QC Status
    // Output into Channels MAPPING_QC.out.detailed_result & MAPPING_QC.out.result
    MAPPING_QC(
        SAM_TO_SORTED_BAM.out.ref_coverage
        .join(HET_SNP_COUNT.out.result, failOnDuplicate: true, failOnMismatch: true),
        params.ref_coverage,
        params.het_snp_site
    )

    // From Channel READ_QC_PASSED_READS_ch assess Streptococcus pneumoniae percentage in reads
    // Output into Channels TAXONOMY.out.detailed_result & TAXONOMY.out.result report
    TAXONOMY(GET_KRAKEN2_DB.out.path, params.kraken2_memory_mapping, READ_QC_PASSED_READS_ch)

    // From Channel TAXONOMY.out.report, provide taxonomy QC status
    // Output into Channels TAXONOMY_QC.out.detailed_result & TAXONOMY_QC.out.result report
    TAXONOMY_QC(TAXONOMY.out.report, params.spneumo_percentage)

    // Merge Channels ASSEMBLY_QC.out.result & MAPPING_QC.out.result & TAXONOMY_QC.out.result to provide Overall QC Status
    // Output into Channel OVERALL_QC.out.result
    OVERALL_QC(
        READ_QC.out.result
        .join(ASSEMBLY_QC.out.result, failOnDuplicate: true, remainder: true)
        .join(MAPPING_QC.out.result, failOnDuplicate: true, remainder: true)
        .join(TAXONOMY_QC.out.result, failOnDuplicate: true, remainder: true)
    )

    // From Channel READ_QC_PASSED_READS_ch, only output reads of samples passed overall QC based on Channel OVERALL_QC.out.result
    OVERALL_QC_PASSED_READS_ch = OVERALL_QC.out.result.join(READ_QC_PASSED_READS_ch, failOnDuplicate: true)
                        .filter { it[1] == 'PASS' }
                        .map { it[0, 2..-1] }

    // From Channel ASSEMBLY_ch, only output assemblies of samples passed overall QC based on Channel OVERALL_QC.out.result
    OVERALL_QC_PASSED_ASSEMBLIES_ch = OVERALL_QC.out.result.join(ASSEMBLY_ch, failOnDuplicate: true)
                            .filter { it[1] == 'PASS' }
                            .map { it[0, 2..-1] }

    // From Channel OVERALL_QC_PASSED_ASSEMBLIES_ch, generate PopPUNK query file containing assemblies of samples passed overall QC
    // Output into POPPUNK_QFILE
    POPPUNK_QFILE = OVERALL_QC_PASSED_ASSEMBLIES_ch
                    .map { it.join'\t' }
                    .collectFile(name: 'qfile.txt', newLine: true)

    // From generated POPPUNK_QFILE, assign GPSC to samples passed overall QC
    LINEAGE(GET_POPPUNK_DB.out.path, GET_POPPUNK_DB.out.database, GET_POPPUNK_EXT_CLUSTERS.out.file, POPPUNK_QFILE)

    // From Channel OVERALL_QC_PASSED_READS_ch, serotype the preprocess reads of samples passed overall QC
    // Output into Channel SEROTYPE.out.result
    SEROTYPE(CREATE_SEROBA_DB.out.path, CREATE_SEROBA_DB.out.database, OVERALL_QC_PASSED_READS_ch)

    // From Channel OVERALL_QC_PASSED_ASSEMBLIES_ch, PubMLST typing the assemblies of samples passed overall QC
    // Output into Channel MLST.out.result
    MLST(OVERALL_QC_PASSED_ASSEMBLIES_ch)

    // From Channel OVERALL_QC_PASSED_ASSEMBLIES_ch, assign PBP genes and estimate MIC (minimum inhibitory concentration) for 6 Beta-lactam antibiotics
    // Output into Channel GET_PBP_RESISTANCE.out.result
    PBP_RESISTANCE(OVERALL_QC_PASSED_ASSEMBLIES_ch)
    GET_PBP_RESISTANCE(PBP_RESISTANCE.out.json)

    // From Channel OVERALL_QC_PASSED_ASSEMBLIES_ch, infer resistance (also determinants if any) of other antimicrobials
    // Output into Channel GET_OTHER_RESISTANCE.out.result
    OTHER_RESISTANCE(CREATE_ARIBA_DB.out.path, CREATE_ARIBA_DB.out.database, OVERALL_QC_PASSED_READS_ch)
    GET_OTHER_RESISTANCE(OTHER_RESISTANCE.out.reports, params.ariba_metadata)

    // Generate sample reports by merging outputs from all result-generating modules
    GENERATE_SAMPLE_REPORT(
        READ_QC.out.report
        .join(ASSEMBLY_QC.out.report, failOnDuplicate: true, remainder: true)
        .join(MAPPING_QC.out.report, failOnDuplicate: true, remainder: true)
        .join(TAXONOMY_QC.out.report, failOnDuplicate: true, remainder: true)
        .join(OVERALL_QC.out.report, failOnDuplicate: true, remainder: true)
        .join(SEROTYPE.out.report, failOnDuplicate: true, remainder: true)
        .join(MLST.out.report, failOnDuplicate: true, remainder: true)
        .join(GET_PBP_RESISTANCE.out.report, failOnDuplicate: true, remainder: true)
        .join(GET_OTHER_RESISTANCE.out.report, failOnDuplicate: true, remainder: true)
        .join(LINEAGE.out.reports.flatten().map { [it.name.take(it.name.lastIndexOf('.')), it] }, failOnDuplicate: true, remainder: true) // Turn reports list into channel, and map back Sample_ID based on output file name
        .map { [it[0], it[1..-1].minus(null)] } // Map Sample_ID to index 0 and all reports (with null entries removed) as a list to index 1
    )

    // Generate overall report by concatenating sample reports
    GENERATE_OVERALL_REPORT(GENERATE_SAMPLE_REPORT.out.report.collect(), params.ariba_metadata)

    // Pass databases information to SAVE_INFO sub-workflow
    DATABASES_INFO = CREATE_REF_GENOME_BWA_DB.out.path.map { [["bwa_db_path", it]] }
                        .merge(CREATE_ARIBA_DB.out.path.map { [["ariba_db_path", it]] })
                        .merge(GET_KRAKEN2_DB.out.path.map { [["kraken2_db_path", it]] })
                        .merge(CREATE_SEROBA_DB.out.path.map { [["seroba_db_path", it]] })
                        .merge(GET_POPPUNK_DB.out.path.map { [["poppunk_db_path", it]] })
                        .merge(GET_POPPUNK_EXT_CLUSTERS.out.file.map { [["poppunk_ext_file", it]] })
                        // Save key-value tuples into a map
                        .map { it.collectEntries() }

    emit:
    databases_info = DATABASES_INFO
}
