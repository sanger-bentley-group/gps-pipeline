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
process PARSE_PBP_RESISTANCE {
    label 'bash_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), path(json)

    output:
    tuple val(sample_id), path(pbp_amr_report), emit: report

    script:
    pbp_amr_report='pbp_amr_report.csv'
    """
    JSON_FILE="$json"
    PBP_AMR_REPORT="$pbp_amr_report"

    source parse_pbp_resistance.sh
    """
}

// Return database path, create if necessary
process GET_ARIBA_DB {
    label 'ariba_container'
    label 'farm_low'

    input:
    path ref_sequences
    path metadata
    path local

    output:
    path local, emit: path
    val output, emit: database

    script:
    output='database'
    json='done_ariba_db.json'
    """
    REF_SEQUENCES="$ref_sequences"
    METADATA="$metadata"
    DB_LOCAL="$local"
    OUTPUT="$output"
    JSON_FILE="$json"

    source check-create_ariba_db.sh
    """
}

// Run ARIBA to identify AMR
process OTHER_RESISTANCE {
    label 'ariba_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    path ariba_database
    val database
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    tuple val(sample_id), path(report), path(report_debug), emit: reports

    script:
    report='result/report.tsv'
    report_debug='result/debug.report.tsv'
    """
    ariba run --nucmer_min_id 80 --assembled_threshold 0.80 "$ariba_database/$database" "$read1" "$read2" result
    """
}

// Extracting resistance information from ARIBA report
process PARSE_OTHER_RESISTANCE {
    label 'python_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), path(report), path(report_debug)
    path metadata

    output:
    tuple val(sample_id), path(output_file), emit: report

    script:
    output_file="other_amr_report.csv"
    """
    parse_other_resistance.py "$report" "$report_debug" "$metadata" "$output_file"
    """
}
