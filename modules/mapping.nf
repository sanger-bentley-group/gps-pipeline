process GET_REF_GENOME_BWA_DB_PREFIX {
    input:
    path reference
    val local

    output:
    val "$local/ref"

    shell:
    '''
    if [ ! -f !{local}/ref.amb ] || [ ! -f !{local}/ref.ann ] || [ ! -f !{local}/ref.bwt ] || [ ! -f !{local}/ref.pac ] || [ ! -f !{local}/ref.sa ] ; then
        bwa index -p ref !{reference}

        rm -rf !{local}
        mkdir -p !{local}
        mv ref.amb ref.ann ref.bwt ref.pac ref.sa -t !{local}
    fi 
    '''
}


process MAPPING {
    input:
    val reference_prefix
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    tuple val(sample_id), path("${sample_id}_mapped_sorted.bam"), emit: bam

    shell:
    '''
    bwa mem !{reference_prefix} <(gzcat !{read1}) <(gzcat !{read2}) > !{sample_id}_mapped.sam

    samtools view -b !{sample_id}_mapped.sam > !{sample_id}_mapped.bam
    rm !{sample_id}_mapped.sam

    samtools sort -o !{sample_id}_mapped_sorted.bam !{sample_id}_mapped.bam
    rm !{sample_id}_mapped.bam
    '''
}