// Run PBP AMR predictor to assign pbp genes and estimate samples' MIC (minimum inhibitory concentration) for 6 Beta-lactam antibiotics
process PBP_RESISTANCE {
    input:
    tuple val(sample_id), path(assembly)

    output:
    tuple val(sample_id), path("result.json"), emit: json

    shell:
    '''
    spn_pbp_amr !{assembly} > result.json
    '''
}

// Extract the results from the result.json file of the PBP AMR predictor
// 
// "=" character in MICs are replaced by "eq_sign" string to avoid issue when Nextflow attempt to capture string variables with "=" character 
// Reported to Nextflow team via issue nextflow-io/nextflow#3553, and a fix will be released with version 23.04.0 in 2023 April (ETA) 
process GET_PBP_RESISTANCE {
    input:
    tuple val(sample_id), path(json)

    output:
    tuple val(sample_id), env(pbp1a), env(pbp2b), env(pbp2x), env(AMX_MIC), env(AMX), env(CRO_MIC), env(CRO_NONMENINGITIS), env(CRO_MENINGITIS), env(CTX_MIC), env(CTX_NONMENINGITIS), env(CTX_MENINGITIS), env(CXM_MIC), env(CXM), env(MEM_MIC), env(MEM), env(PEN_MIC), env(PEN_NONMENINGITIS), env(PEN_MENINGITIS), emit: result

    shell:
    '''
    pbp1a=$(< !{json} jq -r .pbp1a)
    pbp2b=$(< !{json} jq -r .pbp2b)
    pbp2x=$(< !{json} jq -r .pbp2x)
    AMX_MIC=$(< !{json} jq -r .amxMic | sed -e 's/=/eq_sign/g')
    AMX=$(< !{json} jq -r .amx)
    CRO_MIC=$(< !{json} jq -r .croMic | sed -e 's/=/eq_sign/g')
    CRO_NONMENINGITIS=$(< !{json} jq -r .croNonMeningitis)
    CRO_MENINGITIS=$(< !{json} jq -r .croMeningitis)
    CTX_MIC=$(< !{json} jq -r .ctxMic | sed -e 's/=/eq_sign/g')
    CTX_NONMENINGITIS=$(< !{json} jq -r .ctxNonMeningitis)
    CTX_MENINGITIS=$(< !{json} jq -r .ctxMeningitis)
    CXM_MIC=$(< !{json} jq -r .cxmMic | sed -e 's/=/eq_sign/g')
    CXM=$(< !{json} jq -r .cxm)
    MEM_MIC=$(< !{json} jq -r .memMic | sed -e 's/=/eq_sign/g')
    MEM=$(< !{json} jq -r .mem)
    PEN_MIC=$(< !{json} jq -r .penMic | sed -e 's/=/eq_sign/g')
    PEN_NONMENINGITIS=$(< !{json} jq -r .penNonMeningitis)
    PEN_MENINGITIS=$(< !{json} jq -r .penMeningitis)
    '''
}

// Run AMRsearch to infer resistance (also determinants if any) of other antimicrobials
process OTHER_RESISTANCE {
    input:
    tuple val(sample_id), path(assembly)

    output:
    tuple val(sample_id), path("result.json"), emit: json

    shell:
    '''
    java -jar /paarsnp/paarsnp.jar -i !{assembly} -s 1313 -o > result.json
    '''
}

// Extract the results from the result.json file of the AMRsearch
process GET_OTHER_RESISTANCE {
    input:
    tuple val(sample_id), path(json)

    output:
    tuple val(sample_id), env(CHL_RES), env(CHL_DETERMINANTS), env(CLI_RES), env(CLI_DETERMINANTS), env(ERY_RES), env(ERY_DETERMINANTS), env(FLQ_RES), env(FLQ_DETERMINANTS), env(KAN_RES), env(KAN_DETERMINANTS), env(LNZ_RES), env(LNZ_DETERMINANTS), env(TCY_RES), env(TCY_DETERMINANTS), env(TMP_RES), env(TMP_DETERMINANTS), env(SSS_RES), env(SSS_DETERMINANTS), env(SXT_RES), env(SXT_DETERMINANTS), emit: result

    shell:
    '''
    function GET_RES {
        echo $( jq -r --arg target "$1" < !{json} '.resistanceProfile[] | select( .agent.key == $target ) | .state' \
            | sed 's/NOT_FOUND/NONE/g' \
            | tr '[:lower:]' '[:upper:]' )
    }

    function GET_DETERMINANTS {
        echo $( jq -r --arg target "$1" < !{json} '.resistanceProfile[] | select( .agent.key == $target ) | .determinantRules | keys[] // "_"' \
        | sed 's/__/; /g' )
    }

    CHL_RES=$(GET_RES "CHL")
    CHL_DETERMINANTS=$(GET_DETERMINANTS "CHL")

    CLI_RES=$(GET_RES "CLI")
    CLI_DETERMINANTS=$(GET_DETERMINANTS "CLI")

    ERY_RES=$(GET_RES "ERY")
    ERY_DETERMINANTS=$(GET_DETERMINANTS "ERY")

    FLQ_RES=$(GET_RES "FLQ")
    FLQ_DETERMINANTS=$(GET_DETERMINANTS "FLQ")

    KAN_RES=$(GET_RES "KAN")
    KAN_DETERMINANTS=$(GET_DETERMINANTS "KAN")

    LNZ_RES=$(GET_RES "LNZ")
    LNZ_DETERMINANTS=$(GET_DETERMINANTS "LNZ")

    TCY_RES=$(GET_RES "TCY")
    TCY_DETERMINANTS=$(GET_DETERMINANTS "TCY")

    TMP_RES=$(GET_RES "TMP")
    TMP_DETERMINANTS=$(GET_DETERMINANTS "TMP")

    SSS_RES=$(GET_RES "SSS")
    SSS_DETERMINANTS=$(GET_DETERMINANTS "SSS")

    SXT_RES=$(GET_RES "SXT")
    SXT_DETERMINANTS=$(GET_DETERMINANTS "SXT")
    '''
}