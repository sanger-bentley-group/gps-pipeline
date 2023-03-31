// Return database prefix with path for bwa mem runs
// Check if GET_REF_GENOME_BWA_DB_PREFIX has run successfully on the specific reference.
// If not: construct the FM-index database of the reference genome for BWA
process GET_REF_GENOME_BWA_DB_PREFIX {
    label 'bwa_container'
    label 'farm_mid'

    input:
    path reference
    path local

    output:
    tuple path(local), val(prefix)

    shell:
    prefix='reference'
    '''
    REFERENCE="!{reference}"
    DB_LOCAL="!{local}"
    PREFIX="!{prefix}"

    source get_ref_genome_bwa_db_prefix.sh
    '''
}

// Map the reads to reference using BWA-MEM algorithm
// Return SAM
process MAPPING {
    label 'bwa_container'
    label 'farm_mid'

    tag "$sample_id"

    input:
    tuple path(bwa_ref_db_dir), val(prefix)
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    tuple val(sample_id), path("${sample_id}_mapped.sam"), emit: sam

    shell:
    '''
    bwa mem -t $(nproc) !{bwa_ref_db_dir}/!{prefix} <(zcat -f -- < !{read1}) <(zcat -f -- < !{read2}) > !{sample_id}_mapped.sam
    '''
}

// Convert SAM into BAM and sort it
// Return sorted BAM
process SAM_TO_SORTED_BAM {
    label 'samtools_container'
    label 'farm_mid'

    tag "$sample_id"

    input:
    tuple val(sample_id), path(sam)

    output:
    tuple val(sample_id), path("${sample_id}_mapped_sorted.bam"), emit: bam

    shell:
    '''
    samtools view -@ $(($(nproc) - 1)) -b !{sam} > !{sample_id}_mapped.bam
    rm !{sam}

    samtools sort -@ $(nproc) -o !{sample_id}_mapped_sorted.bam !{sample_id}_mapped.bam
    rm !{sample_id}_mapped.bam
    '''
}

// Return reference coverage percentage by the reads
process REF_COVERAGE {
    label 'samtools_container'
    label 'farm_mid'

    tag "$sample_id"

    input:
    tuple val(sample_id), path(bam)

    output:
    tuple val(sample_id), env(COVERAGE), emit: result

    shell:
    '''
    samtools index -@ $(($(nproc) - 1)) !{bam}
    COVERAGE=$(samtools coverage !{bam} | awk -F'\t' 'FNR==2 {print $6}')
    '''
}

// Return .vcf by calling the SNPs
process SNP_CALL {
    label 'bcftools_container'
    label 'farm_mid'

    tag "$sample_id"

    input:
    path reference
    tuple val(sample_id), path(bam)

    output:
    tuple val(sample_id), path("${sample_id}.vcf"), emit: vcf

    shell:
    '''
    bcftools mpileup --threads $(nproc) -f !{reference} !{bam} | bcftools call --threads $(nproc) -mv -O v -o !{sample_id}.vcf
    '''
}

// Return non-cluster heterozygous SNP (Het-SNP) site count
process HET_SNP_COUNT {
    label 'python_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), path(vcf)

    output:
    tuple val(sample_id), env(OUTPUT), emit: result

    shell:
    '''
    OUTPUT=$(het_snp_count.py !{vcf} 50)
    '''
}

// Return overall mapping QC result based on reference coverage and count of Het-SNP sites
process MAPPING_QC {
    label 'bash_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), val(ref_coverage), val(het_snp_count)
    val(qc_ref_coverage)
    val(qc_het_snp_site)

    output:
    tuple val(sample_id), env(COVERAGE), env(HET_SNP), env(MAPPING_QC), emit: detailed_result
    tuple val(sample_id), env(MAPPING_QC), emit: result

    shell:
    '''
    COVERAGE=!{ref_coverage}
    HET_SNP=!{het_snp_count}
    QC_REF_COVERAGE=!{qc_ref_coverage}
    QC_HET_SNP_SITE=!{qc_het_snp_site}

    source mapping_qc.sh
    '''
}
