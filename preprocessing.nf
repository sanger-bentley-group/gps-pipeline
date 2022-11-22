#!/usr/bin/env nextflow 

params.reads = "${projectDir}/data"

process PREPROCESSING {
    publishDir "results", mode: "link"

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple path("preprocessed-${sample_id}_1.fastq.gz"), path("preprocessed-${sample_id}_2.fastq.gz")

    script:
    """
    fastp --in1 ${reads[0]} --in2 ${reads[1]} --out1 preprocessed-${sample_id}_1.fastq.gz --out2 preprocessed-${sample_id}_2.fastq.gz
    """
}

workflow {
    read_pairs_ch = Channel.fromFilePairs( "$params.reads/*_{1,2}.fastq.gz", checkIfExists: true )

    PREPROCESSING(read_pairs_ch)
}