// Return Kraken 2 database path, download if necessary
process GET_KRAKEN_DB {
    label 'bash_container'
    label 'farm_low'

    input:
    val remote
    path local

    output:
    path local

    script:
    """
    DB_REMOTE="$remote"
    DB_LOCAL="$local"

    source get_kraken_db.sh
    """
}

// Run Kraken 2 to assess Streptococcus pneumoniae percentage in reads
process TAXONOMY {
    label 'kraken2_container'
    label 'farm_high'

    tag "$sample_id"

    input:
    path kraken_db
    val kraken2_memory_mapping
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    tuple val(sample_id), path(report), emit: report

    script:
    report='kraken_report.txt'

    if (kraken2_memory_mapping === true)
        """
        kraken2 --threads `nproc` --use-names --memory-mapping --db "$kraken_db" --paired "$read1" "$read2" --report "$report"
        """
    else if (kraken2_memory_mapping === false)
        """
        kraken2 --threads `nproc` --use-names --db "$kraken_db" --paired "$read1" "$read2" --report "$report"
        """
    else
        error "The value for --kraken2_memory_mapping is not valid."
}

// Extract taxonomy QC information and determine QC result based on kraken_report.txt
process TAXONOMY_QC {
    label 'bash_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), path(kraken_report)
    val(qc_spneumo_percentage)

    output:
    tuple val(sample_id), env(PERCENTAGE), emit: percentage
    tuple val(sample_id), env(TAXONOMY_QC), emit: result

    script:
    """
    KRAKEN_REPORT="$kraken_report"
    QC_SPNEUMO_PERCENTAGE="$qc_spneumo_percentage"

    source taxonomy_qc.sh
    """
}
