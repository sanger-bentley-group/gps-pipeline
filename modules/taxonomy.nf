// Return Kraken 2 database path
// Check if GET_KRAKEN_DB has run successfully on the specific database. 
// If not: clean, download, and unzip to params.kraken2_db_local
process GET_KRAKEN_DB {
    label 'bash_container'

    input:
    val remote
    path local

    output:
    path local

    shell:
    '''
    DB_NAME=$(basename !{remote})

    if [ ! -f !{local}/done_kraken_${DB_NAME} ] || [ ! -f !{local}/hash.k2d ]; then
        rm -rf !{local}/{,.[!.],..?}*

        wget !{remote} -O kraken_db.tar.gz
        tar -xzf kraken_db.tar.gz -C !{local}
        rm -f kraken_db.tar.gz

        touch !{local}/done_kraken_${DB_NAME}
    fi 
    '''
}

// Run Kraken 2 to assess Streptococcus pneumoniae percentage in reads
process TAXONOMY {
    label 'kraken2_container'

    input:
    path kraken_db
    val kraken2_memory_mapping
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    tuple val(sample_id), path("kraken_report.txt"), emit: report

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

    input:
    tuple val(sample_id), path(kraken_report)
    val(qc_spneumo_percentage)

    output:
    tuple val(sample_id), env(PERCENTAGE), env(TAXONOMY_QC), emit: detailed_result
    tuple val(sample_id), env(TAXONOMY_QC), emit: result

    shell:
    '''
    PERCENTAGE=$(awk -F"\t" '$4 ~ /^S$/ && $6 ~ /Streptococcus pneumoniae$/ { gsub(/^[ \t]+/, "", $1); printf "%.2f", $1 }' !{kraken_report})

    if [ -z "${PERCENTAGE}" ]; then
        PERCENTAGE="0.00"
    fi

    if (( $(echo "$PERCENTAGE > !{qc_spneumo_percentage}" | bc -l) )); then
        TAXONOMY_QC="PASS"
    else
        TAXONOMY_QC="FAIL"
    fi
    '''
}