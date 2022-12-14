// Return Kraken 2 database path
// Simple check if hash.k2d exists. If not: clean, download, and unzip to params.kraken2_db_local
process GET_KRAKEN_DB {
    input:
    val remote
    val local

    output:
    val local

    shell:
    '''
    if [[ ! -f !{local}/hash.k2d ]]; then
        curl -L !{remote} > kraken_db.tar.gz

        rm -rf !{local}
        mkdir -p !{local}

        tar -xzf kraken_db.tar.gz -C !{local}

        rm -f kraken_db.tar.gz
    fi 
    '''
}

// Run Kraken 2 to assess Streptococcus pneumoniae percentage in reads
process TAXONOMY {
    input:
    val kraken_db
    val kraken2_memory_mapping
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    tuple val(sample_id), env(PERCENTAGE), env(TAXONOMY_QC), emit: detailed_result
    tuple val(sample_id), env(TAXONOMY_QC), emit: result

    shell:
    '''
    if [ !{kraken2_memory_mapping} = true ]; then
        kraken2 --use-names --memory-mapping --db !{kraken_db} --paired !{read1} !{read2} --report kraken_report.txt
    else
        kraken2 --use-names --db !{kraken_db} --paired !{read1} !{read2} --report kraken_report.txt
    fi

    PERCENTAGE=$(awk -F"\t" '$4 ~ /^S$/ && $6 ~ /Streptococcus pneumoniae$/ { gsub(/^[ \t]+/, "", $1); printf "%.2f", $1 }' kraken_report.txt)

    if [ -z "${PERCENTAGE}" ]; then
        PERCENTAGE="0.00"
    fi

    if (( $(echo "$PERCENTAGE > 60.00" | bc -l) )); then
        TAXONOMY_QC="PASS"
    else
        TAXONOMY_QC="FAIL"
    fi
    '''
}