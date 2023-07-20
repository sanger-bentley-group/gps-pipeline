// Return database path and prefix, construct if necessary
process CREATE_REF_GENOME_BWA_DB {
    label 'bwa_container'
    label 'farm_mid'

    input:
    path reference
    path local

    output:
    path(local), emit: path
    val(prefix), emit: prefix

    script:
    prefix='reference'
    json='done_bwa_db.json'
    """
    REFERENCE="$reference"
    DB_LOCAL="$local"
    PREFIX="$prefix"
    JSON_FILE="$json"

    source create_ref_genome_bwa_db.sh
    """
}

// Map the reads to reference using BWA-MEM algorithm
// Return mapped SAM
process MAPPING {
    label 'bwa_container'
    label 'farm_mid'

    tag "$sample_id"

    input:
    path bwa_ref_db_dir
    val prefix
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    tuple val(sample_id), path(sam), emit: sam

    script:
    sam="${sample_id}_mapped.sam"
    """
    bwa mem -t `nproc` "${bwa_ref_db_dir}/${prefix}" <(zcat -f -- < "$read1") <(zcat -f -- < "$read2") > "$sam"
    """
}

// Convert mapped SAM into BAM and sort it
// Return mapped and sorted BAM, and reference coverage percentage by the reads
process SAM_TO_SORTED_BAM {
    label 'samtools_container'
    label 'farm_mid'

    tag "$sample_id"

    input:
    tuple val(sample_id), path(sam)
    val lite

    output:
    tuple val(sample_id), path(bam), emit: bam
    tuple val(sample_id), env(COVERAGE), emit: ref_coverage

    script:
    bam="${sample_id}_mapped_sorted.bam"
    """
    samtools view -@ `nproc` -b "$sam" > mapped.bam

    samtools sort -@ `nproc` -o "$bam" mapped.bam
    rm mapped.bam

    if [ $lite = true ]; then
        rm `readlink -f "$sam"`
    fi

    BAM="$bam"
    source get_ref_coverage.sh
    """
}

// Return .vcf by calling the SNPs
process SNP_CALL {
    label 'bcftools_container'
    label 'farm_mid'

    tag "$sample_id"

    input:
    path reference
    tuple val(sample_id), path(bam)
    val lite

    output:
    tuple val(sample_id), path(vcf), emit: vcf

    script:
    vcf="${sample_id}.vcf"
    """
    bcftools mpileup --threads `nproc` -f "$reference" "$bam" | bcftools call --threads `nproc` -mv -O v -o "$vcf"

    if [ $lite = true ]; then
        rm `readlink -f "$bam"`
    fi
    """
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

    script:
    """
    OUTPUT=`het_snp_count.py "$vcf" 50`
    """
}

// Extract mapping QC information and determine QC result based on reference coverage and count of Het-SNP sites
process MAPPING_QC {
    label 'bash_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), val(ref_coverage), val(het_snp_count)
    val(qc_ref_coverage)
    val(qc_het_snp_site)

    output:
    tuple val(sample_id), env(MAPPING_QC), emit: result
    tuple val(sample_id), path(mapping_qc_report), emit: report

    script:
    mapping_qc_report='mapping_qc_report.csv'
    """
    COVERAGE="$ref_coverage"
    HET_SNP="$het_snp_count"
    QC_REF_COVERAGE="$qc_ref_coverage"
    QC_HET_SNP_SITE="$qc_het_snp_site"
    MAPPING_QC_REPORT="$mapping_qc_report"

    source mapping_qc.sh
    """
}
