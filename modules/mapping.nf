// Return database path and prefix, construct if necessary
process GET_REF_GENOME_BWA_DB {
    label 'bwa_container'
    label 'farm_mid'
    label 'farm_scratchless'

    input:
    path reference
    path db

    output:
    path bwa_db, emit: path
    val prefix, emit: prefix

    script:
    bwa_db="${db}/bwa"
    prefix='reference'
    json='done_bwa_db.json'
    """
    REFERENCE="$reference"
    DB_LOCAL="$bwa_db"
    PREFIX="$prefix"
    JSON_FILE="$json"

    source check-create_ref_genome_bwa_db.sh
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
    bwa mem -t "`nproc`" "${bwa_ref_db_dir}/${prefix}" <(zcat -f -- < "$read1") <(zcat -f -- < "$read2") > "$sam"
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
    tuple val(sample_id), path(sorted_bam), emit: sorted_bam
    tuple val(sample_id), env(COVERAGE), emit: ref_coverage

    script:
    sorted_bam="${sample_id}_mapped_sorted.bam"
    """
    SAM="$sam"
    BAM="mapped.bam"
    SORTED_BAM="$sorted_bam"
    LITE="$lite"

    source convert_sam_to_sorted_bam.sh
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
    tuple val(sample_id), path(sorted_bam)
    val lite

    output:
    tuple val(sample_id), path(vcf), emit: vcf

    script:
    vcf="${sample_id}.vcf"
    """
    REFERENCE="$reference"
    SORTED_BAM="$sorted_bam"
    VCF="$vcf"
    LITE="$lite"

    source call_snp.sh
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
    het_snp_count_output='output.txt'
    """
    het_snp_count.py "$vcf" 50 "$het_snp_count_output"
    OUTPUT=`cat $het_snp_count_output`
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

    source get_mapping_qc.sh
    """
}
