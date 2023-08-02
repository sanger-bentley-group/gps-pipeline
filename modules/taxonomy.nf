// Return Kraken 2 database path, download if necessary
process GET_KRAKEN2_DB {
    label 'bash_container'
    label 'farm_low'

    input:
    val remote
    path local

    output:
    path local, emit: path

    script:
    json='done_kraken.json'
    """
    DB_REMOTE="$remote"
    DB_LOCAL="$local"
    JSON_FILE="$json"

    source check-download_kraken2_db.sh
    """
}

// Run Kraken 2 to assess Streptococcus pneumoniae percentage in reads
process TAXONOMY {
    label 'kraken2_container'
    label 'farm_high'

    tag "$sample_id"

    input:
    path kraken2_db
    val kraken2_memory_mapping
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    tuple val(sample_id), path(report), emit: report

    script:
    report='kraken2_report.txt'

    if (kraken2_memory_mapping === true)
        """
        kraken2 --threads "`nproc`" --use-names --memory-mapping --db "$kraken2_db" --paired "$read1" "$read2" --report "$report" --output -
        """
    else if (kraken2_memory_mapping === false)
        """
        kraken2 --threads "`nproc`" --use-names --db "$kraken2_db" --paired "$read1" "$read2" --report "$report" --output -
        """
    else
        error "The value for --kraken2_memory_mapping is not valid."
}

// Extract taxonomy QC information and determine QC result based on kraken2_report.txt
process TAXONOMY_QC {
    label 'bash_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), path(kraken2_report)
    val(qc_spneumo_percentage)

    output:
    tuple val(sample_id), env(TAXONOMY_QC), emit: result
    tuple val(sample_id), path(taxonomy_qc_report), emit: report

    script:
    taxonomy_qc_report='taxonomy_qc_report.csv'
    """
    KRAKEN2_REPORT="$kraken2_report"
    QC_SPNEUMO_PERCENTAGE="$qc_spneumo_percentage"
    TAXONOMY_QC_REPORT="$taxonomy_qc_report"

    source get_taxonomy_qc.sh
    """
}
