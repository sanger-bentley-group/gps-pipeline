// Return boolean of CREATE_DB
// Check if GET_SEROBA_DB and CREATE_SEROBA_DB has run successfully and pull to check if SeroBA database is up-to-date. 
// If outdated or does not exist: clean and clone, set CREATE_DB to true
process GET_SEROBA_DB {
    input:
    val remote
    val local

    output:
    env CREATE_DB, emit: create_db

    shell:
    '''
    # Assume up-to-date if done_seroba and the host cannot be resolved
    if [ ! -f !{local}/done_seroba ] || !((git -C !{local} pull || echo 'Already up-to-date') | grep -q 'Already up[- ]to[- ]date'); then
        rm -rf !{local}
        git clone !{remote} !{local}

        CREATE_DB=true
    else
        CREATE_DB=false
    fi
    '''
}

// Return SeroBA databases path
// If create_db == true: re-create kmc and ariba databases
process CREATE_SEROBA_DB {
    input:
    val local
    val create_db

    output:
    val "$local/database"

    shell:
    '''
    if [ !{create_db} = true ]; then
        seroba createDBs !{local}/database/ 71
        touch !{local}/done_seroba
    fi
    '''
}

// Run SeroBA to serotype samples
process SEROTYPE {
    input:
    val database
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    tuple val(sample_id), env(SEROTYPE), env(SEROBA_COMMENT), emit: result

    shell:
    '''
    seroba runSerotyping !{database} !{read1} !{read2} !{sample_id}

    SEROTYPE=$(awk -F'\t' '{ print $2 }' !{sample_id}/pred.tsv)
    SEROBA_COMMENT=$(awk -F'\t' '$3!=""{ print $3 } $3==""{ print "_" }' !{sample_id}/pred.tsv)
    '''
}