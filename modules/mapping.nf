process GET_REF_GENOME_BWA_DB_PREFIX {
    input:
    path reference
    val local

    output:
    val "$local/ref"

    shell:
    '''
    if [ ! -f !{local}/ref.amb ] || [ ! -f !{local}/ref.ann ] || [ ! -f !{local}/ref.bwt ] || [ ! -f !{local}/ref.pac ] || [ ! -f !{local}/ref.sa ] ; then
        bwa index -p ref !{reference}

        rm -rf !{local}
        mkdir -p !{local}
        mv ref.amb ref.ann ref.bwt ref.pac ref.sa -t !{local}
    fi 
    '''
}