process GET_KRAKEN_DB {
    input:
    val remote
    val local

    output:
    val local

    shell:
    '''
    if [[ ! -f !{local}/hash.k2d ]]; then
        curl -L !{remote} > k2_standard_08gb.tar.gz

        rm -rf !{local}
        mkdir -p !{local}

        tar -xzf k2_standard_08gb.tar.gz -C !{local}

        rm -f k2_standard_08gb.tar.gz
    fi 
    '''
}