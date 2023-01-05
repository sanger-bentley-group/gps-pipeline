// Run fastp to preprocess the FASTQs 
process PREPROCESS {
    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("processed-${sample_id}_1.fastq.gz"), path("processed-${sample_id}_2.fastq.gz"), path("processed-${sample_id}_unpaired.fastq.gz"), emit: processed_reads
    tuple val(sample_id), path("fastp.json"), emit: json

    shell:
    '''
    fastp --in1 !{reads[0]} --in2 !{reads[1]} --out1 processed-!{sample_id}_1.fastq.gz --out2 processed-!{sample_id}_2.fastq.gz --unpaired1 processed-!{sample_id}_unpaired.fastq.gz --unpaired2 processed-!{sample_id}_unpaired.fastq.gz
    '''
}

// Get total base count from fastp.json
process GET_BASES {
    input:
    tuple val(sample_id), path(json)

    output:
    tuple val(sample_id), env(BASES)

    shell:
    '''
    BASES=$(< fastp.json jq .summary.after_filtering.total_bases)
    '''
}