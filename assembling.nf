#!/usr/bin/env nextflow 

params.reads = "${projectDir}/data"
params.spades_local = "${projectDir}/bin/spades"

process GET_SPADES {
    input:
    val os
    val local

    output:
    val "$local/bin/spades.py"

    script:
    """
    if [[ ! -f $local/bin/spades.py ]] || !($local/bin/spades.py --version | grep -q 'v3.15.5'); then
        if [[ "$os" == "Linux" ]]; then
            wget https://github.com/ablab/spades/releases/download/v3.15.5/SPAdes-3.15.5-Linux.tar.gz
            

        elif [[ "$os" == "Mac OS X" ]]; then
            curl -L https://github.com/ablab/spades/releases/download/v3.15.5/SPAdes-3.15.5-Darwin.tar.gz > SPAdes-3.15.5-Darwin.tar.gz
            tar -xzf SPAdes-3.15.5-Darwin.tar.gz
        fi

        tar -xzf SPAdes-3.15.5-*.tar.gz

        rm -rf $local
        mkdir -p $local
        mv SPAdes*/* $local/
    fi 
    """
}

process ASSEMBLING {
    publishDir "results", mode: "link", saveAs: { filename -> "${sample_id}_${filename}"}

    input:
    val spades
    tuple val(sample_id), path(reads)

    output:
    path "contigs.fasta"

    script:
    """
    $spades -1 ${reads[0]} -2 ${reads[1]} -o results
    """
}

workflow {
    spades_py = GET_SPADES(System.properties['os.name'], params.spades_local)
    read_pairs_ch = Channel.fromFilePairs( "$params.reads/*_{1,2}.fastq.gz", checkIfExists: true )

    ASSEMBLING(spades_py, read_pairs_ch)
}