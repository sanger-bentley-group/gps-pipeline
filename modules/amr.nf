// Run PBP AMR predictor to assign pbp genes and estimate samples' MIC (minimum inhibitory concentration) for 6 Beta-lactam antibiotics
process PBP_RESISTANCE {
    label 'spn_pbp_amr_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), path(assembly)

    output:
    tuple val(sample_id), path(json), emit: json

    script:
    json='result.json'
    """
    spn_pbp_amr "$assembly" > "$json"
    """
}

// Extract the results from the output file of the PBP AMR predictor
process GET_PBP_RESISTANCE {
    label 'bash_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), path(json)

    output:
    tuple val(sample_id), env(pbp1a), env(pbp2b), env(pbp2x), env(AMO_MIC), env(AMO), env(CFT_MIC), env(CFT_MENINGITIS), env(CFT_NONMENINGITIS), env(TAX_MIC), env(TAX_MENINGITIS), env(TAX_NONMENINGITIS), env(CFX_MIC), env(CFX), env(MER_MIC), env(MER), env(PEN_MIC), env(PEN_MENINGITIS), env(PEN_NONMENINGITIS), emit: result

    script:
    """
    JSON_FILE="$json"

    source get_pbp_resistance.sh
    """
}

// Create ARIBA database and return database path
process CREATE_ARIBA_DB {
    label 'ariba_container'
    label 'farm_low'

    input:
    path ref_sequences
    path metadata
    path local

    output:
    path "${local}/${output}"

    script:
    output='database'
    """
    REF_SEQUENCES="$ref_sequences"
    METADATA="$metadata"
    DB_LOCAL="$local"
    OUTPUT="$output"

    source create_ariba_db.sh
    """
}

// Run ARIBA to identify AMR
process OTHER_RESISTANCE {
    label 'ariba_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    path ariba_database
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    tuple val(sample_id), path(report), path(report_debug), emit: reports

    script:
    report='result/report.tsv'
    report_debug='result/debug.report.tsv'
    """
    ariba run --nucmer_min_id 80 --assembled_threshold 0.80 --assembler spades $ariba_database $read1 $read2 result
    """
}

// WIP, for extracting information from ARIBA report
process GET_OTHER_RESISTANCE {
    label 'bash_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), path(report), path(report_debug)

    script:
    """
    # TBC
    """
}
