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
    publishDir "results", mode: 'link'

    input:
    val spades
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    path "${sample_id}.contigs.fasta"

    script:
    """
    unicycler -1 $read1 -2 $read2 -s $unpaired -o results --no_correct --no_pilon --spades_path $spades
    mv results/assembly.fasta ${sample_id}.contigs.fasta
    """
}