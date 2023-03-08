// Return boolean of CREATE_DB
// Check if GET_SEROBA_DB and CREATE_SEROBA_DB has run successfully and pull to check if SeroBA database is up-to-date. 
// If outdated or does not exist: clean and clone, set CREATE_DB to true
process GET_SEROBA_DB {
    label 'git_container'
    
    input:
    val remote
    path local
    val kmer

    output:
    env CREATE_DB, emit: create_db

    shell:
    '''
    # Assume up-to-date if done_seroba exists and the host cannot be resolved (often means the Internet is not available)
    if  [ ! -f !{local}/done_seroba.json ] || \
        [ ! "$(grep 'git' !{local}/done_seroba.json | sed -r 's/.+: "(.*)",/\\1/')" == "!{remote}" ] || \
        [ ! "$(grep 'kmer' !{local}/done_seroba.json | sed -r 's/.+: "(.*)",/\\1/')" == "!{kmer}" ] || \
        !((git -C !{local} pull || echo 'Already up-to-date') | grep -q 'Already up[- ]to[- ]date'); then

        rm -rf !{local}/{,.[!.],..?}*
        git clone !{remote} !{local}

        CREATE_DB=true

    else

        CREATE_DB=false
    
    fi
    '''
}

// Return SeroBA databases path
// If create_db == true: re-create KMC and ARIBA databases
process CREATE_SEROBA_DB {
    label 'seroba_container'

    input:
    val remote
    path seroba_dir
    val create_db
    val kmer

    output:
    tuple path(seroba_dir), env(DATABASE)

    shell:
    '''
    DATABASE=database

    if [ !{create_db} = true ]; then

        seroba createDBs !{seroba_dir}/${DATABASE}/ !{kmer}

        echo -e '{\n  "git": "!{remote}",\n  "kmer": "!{kmer}",\n  "create_time": "'"$(date +"%Y-%m-%d %H:%M:%S")"'"\n}' > !{seroba_dir}/done_seroba.json

    fi
    '''
}

// Run SeroBA to serotype samples
process SEROTYPE {
    label 'seroba_container'

    input:
    tuple path(seroba_dir), val(database)
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    tuple val(sample_id), env(SEROTYPE), env(SEROBA_COMMENT), emit: result

    shell:
    '''
    seroba runSerotyping !{seroba_dir}/!{database} !{read1} !{read2} !{sample_id}

    SEROTYPE=$(awk -F'\t' '{ print $2 }' !{sample_id}/pred.tsv)
    SEROBA_COMMENT=$(awk -F'\t' '$3!=""{ print $3 } $3==""{ print "_" }' !{sample_id}/pred.tsv)
    '''
}