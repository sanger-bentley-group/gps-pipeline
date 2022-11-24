// Return SPAdes executable path
// Check if SPAdes executable is v3.15.5. If not: clean, download (process is OS-specific), unzip and move content to params.spades_local
process GET_SPADES {
    input:
    val os
    val local

    output:
    val "$local/bin/spades.py"

    script:
    """
    if [[ ! -f $local/bin/spades.py ]] || ! $local/bin/spades.py --version | grep -q 'v3.15.5' ; then
        if [[ "$os" == "Linux" ]]; then
            wget https://github.com/ablab/spades/releases/download/v3.15.5/SPAdes-3.15.5-Linux.tar.gz
        elif [[ "$os" == "Mac OS X" ]]; then
            curl -L https://github.com/ablab/spades/releases/download/v3.15.5/SPAdes-3.15.5-Darwin.tar.gz > SPAdes-3.15.5-Darwin.tar.gz
        fi

        tar -xzf SPAdes-3.15.5-*.tar.gz

        rm -rf $local
        mkdir -p $local
        mv SPAdes*/* $local/
    fi 
    """
}

process GET_UNICYCLER {
    input:
    val os
    val local

    output:
    val "$local/unicycler-runner.py"

    script:
    """
    if [[ ! -f $local/unicycler-runner.py ]] || ! $local/unicycler-runner.py --version | grep -q 'v0.5.0' ; then
        
        if [[ "$os" == "Linux" ]]; then
            wget https://github.com/rrwick/Unicycler/archive/refs/tags/v0.5.0.tar.gz
        elif [[ "$os" == "Mac OS X" ]]; then
            curl -L https://github.com/rrwick/Unicycler/archive/refs/tags/v0.5.0.tar.gz > v0.5.0.tar.gz
        fi
        
        tar -xzf v0.5.0.tar.gz

        rm -rf $local
        mkdir -p $local
        mv Unicycler-0.5.0/* $local/

        cd $local
        arch -x86_64 make
    fi 
    """
}

// Run Unicycler to get assemblies using specific SPAdes executable
// Hardlink the assemblies to results directory
process ASSEMBLING {
    publishDir "results", mode: 'link'

    input:
    val unicycler_runner
    val spades
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    path "${sample_id}.contigs.fasta"

    script:
    """
    $unicycler_runner -1 $read1 -2 $read2 -s $unpaired -o results --spades_path $spades
    mv results/assembly.fasta ${sample_id}.contigs.fasta
    """
}