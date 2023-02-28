// Run Unicycler to get assembly
// Use specific SPAdes executable if provided its directory
// Return sample_id and assembly, and hardlink the assembly to $params.output directory
process ASSEMBLY_UNICYCLER {
    label 'unicycler_container'

    publishDir "$params.output/assemblies", mode: 'link'

    input:
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    tuple val(sample_id), path("${sample_id}.contigs.fasta")

    shell:
    '''
    unicycler -1 !{read1} -2 !{read2} -s !{unpaired} -o results -t $(nproc)
    mv results/assembly.fasta !{sample_id}.contigs.fasta
    '''
}

// Run Shovill to get assembly
// Return sample_id and assembly, and hardlink the assembly to $params.output directory
process ASSEMBLY_SHOVILL {
    label 'shovill_container'

    publishDir "$params.output/assemblies", mode: 'link'

    input:
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    tuple val(sample_id), path("${sample_id}.contigs.fasta")

    shell:
    '''
    shovill --R1 !{read1} --R2 !{read2} --outdir results --cpus $(nproc)
    mv results/contigs.fa !{sample_id}.contigs.fasta
    '''
}

// Run quast to assess assembly quality
process ASSEMBLY_ASSESS {
    label 'quast_container'

    input:
    tuple val(sample_id), path(assembly)
    output:
    tuple val(sample_id), path("results/report.tsv"), emit: report

    shell:
    '''
    quast.py -o results !{assembly}
    '''
}

// Return Assembly QC result based on report.tsv from Quast and total base count 
process ASSEMBLY_QC {
    label 'bash_container'

    input:
    tuple val(sample_id), path(report), val(bases)

    output:
    tuple val(sample_id), env(CONTIGS), env(LENGTH), env(DEPTH), env(ASSEMBLY_QC), emit: detailed_result
    tuple val(sample_id), env(ASSEMBLY_QC), emit: result

    shell:
    '''
    CONTIGS=$(awk -F'\t' '$1 == "# contigs" { print $2 }' !{report})
    LENGTH=$(awk -F'\t' '$1 == "Total length" { print $2 }' !{report})
    DEPTH=$(printf %.2f $(echo "!{bases} / $LENGTH" | bc -l) )
    
    if (( $CONTIGS < 500 )) && (( $LENGTH >= 1900000 )) && (( $LENGTH <= 2300000 )) && (( $(echo "$DEPTH >= 20.00" | bc -l) )); then
        ASSEMBLY_QC="PASS"
    else
        ASSEMBLY_QC="FAIL"
    fi
    '''
}