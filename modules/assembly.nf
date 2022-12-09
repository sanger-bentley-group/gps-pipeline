// MacOS Specific
// Return SPAdes executable path
// Check if SPAdes executable is v3.15.5. If not: clean, download (process is OS-specific), unzip and move content to params.spades_local
process GET_SPADES {
    input:
    val local

    output:
    val "$local/bin/spades.py"

    shell:
    '''
    if [[ ! -f !{local}/bin/spades.py ]] || ! !{local}/bin/spades.py --version | grep -q 'v3.15.5' ; then
        curl -L https://github.com/ablab/spades/releases/download/v3.15.5/SPAdes-3.15.5-Darwin.tar.gz > SPAdes-3.15.5-Darwin.tar.gz
        tar -xzf SPAdes-3.15.5-*.tar.gz

        rm -rf !{local}
        mkdir -p !{local}
        mv SPAdes*/* !{local}/
    fi 
    '''
}

// MacOS Specific
// Return Unicycler executable path
// Check if Unicycler executable is v0.5.0. If not: clean, download, unzip, move content to params.unicycler_local and compile
process GET_UNICYCLER {
    input:
    val local

    output:
    val "$local/unicycler-runner.py"

    shell:
    '''
    if [[ ! -f !{local}/unicycler-runner.py ]] || ! !{local}/unicycler-runner.py --version | grep -q 'v0.5.0' ; then
        curl -L https://github.com/rrwick/Unicycler/archive/refs/tags/v0.5.0.tar.gz > v0.5.0.tar.gz
        
        tar -xzf v0.5.0.tar.gz

        rm -rf !{local}
        mkdir -p !{local}
        mv Unicycler-0.5.0/* !{local}/

        cd !{local}
        arch -x86_64 make
    fi 
    '''
}

// Run Unicycler to get assembly using specific SPAdes executable
// Return sample_id and assembly, and hardlink the assembly to $params.output directory
process ASSEMBLY {
    publishDir "$params.output/assemblies", mode: 'link'

    input:
    val unicycler_runner
    val spades
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    tuple val(sample_id), path("${sample_id}.contigs.fasta"), emit: assembly

    shell:
    '''
    !{unicycler_runner} -1 !{read1} -2 !{read2} -s !{unpaired} -o results --spades_path !{spades}
    
    mv results/assembly.fasta !{sample_id}.contigs.fasta
    '''
}

// Run quast to assess assembly quality
process ASSEMBLY_QC {
    input:
    tuple val(sample_id), path(assembly), val(bases)

    output:
    tuple val(sample_id), env(CONTIGS), env(LENGTH), env(DEPTH), env(ASSEMBLY_QC), emit: detailed_result
    tuple val(sample_id), env(ASSEMBLY_QC), emit: result

    shell:
    '''
    quast -o results !{assembly}
    
    CONTIGS=$(awk -F'\t' '$1 == "# contigs" { print $2 }' results/report.tsv)
    LENGTH=$(awk -F'\t' '$1 == "Total length" { print $2 }' results/report.tsv)
    DEPTH=$(printf %.2f $(echo "!{bases} / $LENGTH" | bc -l) )
    
    if (( $CONTIGS < 500 )) && (( $LENGTH >= 1900000 )) && (( $LENGTH <= 2300000 )) && (( $(echo "$DEPTH >= 20.00" | bc -l) )); then
        ASSEMBLY_QC="PASS"
    else
        ASSEMBLY_QC="FAIL"
    fi
    '''
}