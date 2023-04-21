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
    tuple val(sample_id), env(pbp1a), env(pbp2b), env(pbp2x), env(AMX_MIC), env(AMX), env(CRO_MIC), env(CRO_MENINGITIS), env(CRO_NONMENINGITIS), env(CTX_MIC), env(CTX_MENINGITIS), env(CTX_NONMENINGITIS), env(CXM_MIC), env(CXM), env(MEM_MIC), env(MEM), env(PEN_MIC), env(PEN_MENINGITIS), env(PEN_NONMENINGITIS), emit: result

    script:
    """
    JSON_FILE="$json"

    source get_pbp_resistance.sh
    """
}

// Run AMRsearch to infer resistance (also determinants if any) of other antimicrobials
process OTHER_RESISTANCE {
    label 'amrsearch_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), path(assembly)

    output:
    tuple val(sample_id), path(json), emit: json

    script:
    json='result.json'
    """
    java -jar /paarsnp/paarsnp.jar -i "$assembly" -s 1313 -o > $json
    """
}

// Extract the results from the output file of the AMRsearch
process GET_OTHER_RESISTANCE {
    label 'bash_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), path(json)

    output:
    tuple val(sample_id), env(CHL_RES), env(CHL_DETERMINANTS), env(CLI_RES), env(CLI_DETERMINANTS), env(ERY_RES), env(ERY_DETERMINANTS), env(FLQ_RES), env(FLQ_DETERMINANTS), env(KAN_RES), env(KAN_DETERMINANTS), env(LNZ_RES), env(LNZ_DETERMINANTS), env(TCY_RES), env(TCY_DETERMINANTS), env(TMP_RES), env(TMP_DETERMINANTS), env(SSS_RES), env(SSS_DETERMINANTS), env(SXT_RES), env(SXT_DETERMINANTS), emit: result

    script:
    """
    JSON_FILE="$json"
    
    source get_other_resistance.sh
    """
}
