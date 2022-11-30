process ASSEMBLY_QC {
    input:
    tuple val(sample_id), path(assembly), val(bases)

    output:
    tuple val(sample_id), env(CONTIGS), env(LENGTH), env(DEPTH), env(ASSEMBLY_QC), emit: results

    shell:
    '''
    quast -o results !{assembly}
    
    CONTIGS=$(awk -F'\t' '$1 == "# contigs" { print $2 }' results/report.tsv)
    LENGTH=$(awk -F'\t' '$1 == "Total length" { print $2 }' results/report.tsv)
    DEPTH=$(printf "%.0f" $((!{bases} / $LENGTH)))
    
    if (( $CONTIGS < 500 )) && (( $LENGTH >= 1900000 )) && (( $LENGTH <= 2300000 )) && (( $DEPTH >= 20 )); then
        ASSEMBLY_QC="PASS"
    else
        ASSEMBLY_QC="FAIL"
    fi
    '''
}