// Run fastp to preprocess the FASTQs 
process PREPROCESSING {
    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("processed-${sample_id}_1.fastq.gz"), path("processed-${sample_id}_2.fastq.gz"), path("processed-${sample_id}_unpaired.fastq.gz"), emit: processed_reads
    tuple val(sample_id), env(BASES), emit: base_count

    shell:
    '''
    fastp --in1 !{reads[0]} --in2 !{reads[1]} --out1 processed-!{sample_id}_1.fastq.gz --out2 processed-!{sample_id}_2.fastq.gz --unpaired1 processed-!{sample_id}_unpaired.fastq.gz --unpaired2 processed-!{sample_id}_unpaired.fastq.gz
    
    BASES=$(cat "fastp.json" | python3 -c "import sys, json; print(json.load(sys.stdin)['summary']['after_filtering']['total_bases'])")
    '''
}