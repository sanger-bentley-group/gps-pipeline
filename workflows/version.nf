include { IMAGES; COMBINE_INFO; PRINT_VERSION; GIT_VERSION; PYTHON_VERSION; FASTP_VERSION; UNICYCLER_VERSION; SHOVILL_VERSION; QUAST_VERSION; BWA_VERSION; SAMTOOLS_VERSION; BCFTOOLS_VERSION; POPPUNK_VERSION; MLST_VERSION; KRAKEN2_VERSION; SEROBA_VERSION } from "$projectDir/modules/info"

// Alternative workflow for getting versions of pipeline and tools
workflow GET_VERSION {
    IMAGES(Channel.fromPath( "$projectDir/nextflow.config" ))

    GIT_VERSION()
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

    COMBINE_INFO(
        params.pipeline_version,
        IMAGES.out.json, 
        GIT_VERSION.out, 
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
        SEROBA_VERSION.out
    )
    
    PRINT_VERSION(COMBINE_INFO.out.json, params.version, params.output)
}