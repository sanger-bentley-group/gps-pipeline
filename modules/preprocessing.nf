process PREPROCESSING {
    publishDir "results", mode: "link"

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("processed-${sample_id}_1.fastq.gz"), path("processed-${sample_id}_2.fastq.gz"), path("processed-${sample_id}_unpaired.fastq.gz")

    script:
    """
    fastp --in1 ${reads[0]} --in2 ${reads[1]} --out1 processed-${sample_id}_1.fastq.gz --out2 processed-${sample_id}_2.fastq.gz --unpaired1 processed-${sample_id}_unpaired.fastq.gz --unpaired2 processed-${sample_id}_unpaired.fastq.gz
    """
}