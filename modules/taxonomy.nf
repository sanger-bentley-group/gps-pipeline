// Return Kraken 2 database path
// Check if GET_KRAKEN_DB has run successfully on the specific database.
// If not: clean, download, and unzip to params.kraken2_db_local
process GET_KRAKEN_DB {
    label 'bash_container'
    label 'farm_low'

    input:
    val remote
    path local

    output:
    path local

    shell:
    '''
    DB_REMOTE=!{remote}
    DB_LOCAL=!{local}

    source get_kraken_db.sh
    '''
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
    tuple val(sample_id), path('kraken_report.txt'), emit: report

    shell:
    '''
    if [ !{kraken2_memory_mapping} = true ]; then
        kraken2 --threads $(nproc) --use-names --memory-mapping --db !{kraken_db} --paired !{read1} !{read2} --report kraken_report.txt
    else
        kraken2 --threads $(nproc) --use-names --db !{kraken_db} --paired !{read1} !{read2} --report kraken_report.txt
    fi
    '''
}

// Return Taxonomy QC result based on kraken_report.txt
process TAXONOMY_QC {
    label 'bash_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), path(kraken_report)
    val(qc_spneumo_percentage)

    output:
    tuple val(sample_id), env(PERCENTAGE), env(TAXONOMY_QC), emit: detailed_result
    tuple val(sample_id), env(TAXONOMY_QC), emit: result

    shell:
    '''
    KRAKEN_REPORT=!{kraken_report}
    QC_SPNEUMO_PERCENTAGE=!{qc_spneumo_percentage}

    source taxonomy_qc.sh
    '''
}
