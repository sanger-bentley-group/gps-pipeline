#!/usr/bin/env nextflow 

params.reads = "${projectDir}/data"
params.spades_local = "${projectDir}/bin/spades"
params.os = System.properties['os.name']

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
    input:
    val spades
    tuple val(sample_id), path(reads)

    output:
    stdout

    script:
    """
    unicycler -1 ${reads[0]} -2 ${reads[1]} -s ${projectDir}/${params.reads}/${sample_id}_unpaired.fastq.gz -o results --no_correct --no_pilon --spades_path $spades
    """
}

workflow {
    spades_py = GET_SPADES(params.os, params.spades_local)
    read_pairs_ch = Channel.fromFilePairs( "$params.reads/*_{1,2}.fastq.gz", checkIfExists: true )

    ASSEMBLING(spades_py, read_pairs_ch)
}