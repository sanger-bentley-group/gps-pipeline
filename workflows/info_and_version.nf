include { IMAGES; DATABASES; TOOLS; COMBINE_INFO; PARSE; PRINT; SAVE; PYTHON_VERSION; FASTP_VERSION; UNICYCLER_VERSION; SHOVILL_VERSION; QUAST_VERSION; BWA_VERSION; SAMTOOLS_VERSION; BCFTOOLS_VERSION; POPPUNK_VERSION; MLST_VERSION; KRAKEN2_VERSION; SEROBA_VERSION; ARIBA_VERSION } from "$projectDir/modules/info"

// Alternative workflow that prints versions of pipeline and tools
workflow PRINT_VERSION {
    take:
        resistance_to_mic
        pipeline_version

    main:
        GET_VERSION(
            "${params.db}/bwa",
            "${params.db}/ariba",
            "${params.db}/kraken2",
            "${params.db}/seroba",
            "${params.db}/poppunk",
            "${params.db}/poppunk_ext",
            resistance_to_mic,
            pipeline_version
        ) \
        | PARSE \
        | PRINT
}

// Sub-workflow of PIPELINE workflow the save versions of pipeline and tools, and QC parameters to info.txt at output dir
workflow SAVE_INFO {
    take:
        databases_info
        resistance_to_mic
        pipeline_version

    main:
        GET_VERSION(
            databases_info.bwa_db_path,
            databases_info.ariba_db_path,
            databases_info.kraken2_db_path,
            databases_info.seroba_db_path,
            databases_info.poppunk_db_path,
            databases_info.poppunk_ext_path,
            resistance_to_mic,
            pipeline_version
        ) \
       | PARSE \
       | SAVE
}

// Sub-workflow for generating a json that contains versions of pipeline and tools
workflow GET_VERSION {
    take:
        bwa_db_path
        ariba_db_path
        kraken2_db_path
        seroba_db_path
        poppunk_db_path
        poppunk_ext_path
        resistance_to_mic
        pipeline_version

    main:
        IMAGES(
            Channel.fromList(workflow.container.collect { "${it.key}\t${it.value}" })
                .unique()
                .collectFile(name: 'processesContainersList.tsv', newLine: true)
        )            

        DATABASES(
            bwa_db_path,
            ariba_db_path,
            kraken2_db_path,
            seroba_db_path,
            poppunk_db_path,
            poppunk_ext_path,
            resistance_to_mic
        )

        nextflow_version = "$nextflow.version"

        PYTHON_VERSION()
        FASTP_VERSION()
        UNICYCLER_VERSION()
        SHOVILL_VERSION()
        QUAST_VERSION()
        BWA_VERSION()
        SAMTOOLS_VERSION()
        BCFTOOLS_VERSION()
        POPPUNK_VERSION()
        MLST_VERSION()
        KRAKEN2_VERSION()
        SEROBA_VERSION()
        ARIBA_VERSION()

        TOOLS(
            PYTHON_VERSION.out,
            FASTP_VERSION.out,
            UNICYCLER_VERSION.out,
            SHOVILL_VERSION.out,
            QUAST_VERSION.out,
            BWA_VERSION.out,
            SAMTOOLS_VERSION.out,
            BCFTOOLS_VERSION.out,
            POPPUNK_VERSION.out,
            MLST_VERSION.out,
            KRAKEN2_VERSION.out,
            SEROBA_VERSION.out,
            ARIBA_VERSION.out
        )

        COMBINE_INFO(
            pipeline_version,
            nextflow_version,
            DATABASES.out.json,
            IMAGES.out.json,
            TOOLS.out.json
        )

    emit:
        COMBINE_INFO.out.json
}
