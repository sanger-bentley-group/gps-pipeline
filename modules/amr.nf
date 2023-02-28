// Run PBP AMR predictor to assign pbp genes and estimate samples' MIC (minimum inhibitory concentration) for 6 Beta-lactam antibiotics
process PBP_RESISTANCE {
    label 'spn_pbp_amr_container'

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
// "=" character are replaced by "eq_sign" string to avoid issue when Nextflow attempt to capture string variables with "=" character 
// Reported to Nextflow team via issue nextflow-io/nextflow#3553, and a fix will be released with version 23.04.0 in 2023 April (ETA) 
process GET_PBP_RESISTANCE {
    label 'bash_container'

    input:
    tuple val(sample_id), path(json)

    output:
    tuple val(sample_id), env(pbp1a), env(pbp2b), env(pbp2x), env(AMX_MIC), env(AMX), env(CRO_MIC), env(CRO_NONMENINGITIS), env(CRO_MENINGITIS), env(CTX_MIC), env(CTX_NONMENINGITIS), env(CTX_MENINGITIS), env(CXM_MIC), env(CXM), env(MEM_MIC), env(MEM), env(PEN_MIC), env(PEN_NONMENINGITIS), env(PEN_MENINGITIS), emit: result

    shell:
    '''
    function GET_VALUE {
        echo $( < !{json} jq -r --arg target "$1" '.[$target]' \
            | sed 's/=/eq_sign/g' )
    }

    function GET_RES {
        echo $( < !{json} jq -r --arg target "$1" '.[$target]' \
            | sed 's/^S$/SENSITIVE/g;s/^I$/INTERMEDIATE/g;s/^R$/RESISTANT/g' )
    }

    pbp1a=$(GET_VALUE "pbp1a")
    pbp2b=$(GET_VALUE "pbp2b")
    pbp2x=$(GET_VALUE "pbp2x")
    AMX_MIC=$(GET_VALUE "amxMic")
    AMX=$(GET_RES "amx")
    CRO_MIC=$(GET_VALUE "croMic")
    CRO_NONMENINGITIS=$(GET_RES "croNonMeningitis")
    CRO_MENINGITIS=$(GET_RES "croMeningitis")
    CTX_MIC=$(GET_VALUE "ctxMic")
    CTX_NONMENINGITIS=$(GET_RES "ctxNonMeningitis")
    CTX_MENINGITIS=$(GET_RES "ctxMeningitis")
    CXM_MIC=$(GET_VALUE "cxmMic")
    CXM=$(GET_RES "cxm")
    MEM_MIC=$(GET_VALUE "memMic")
    MEM=$(GET_RES "mem")
    PEN_MIC=$(GET_VALUE "penMic")
    PEN_NONMENINGITIS=$(GET_RES "penNonMeningitis")
    PEN_MENINGITIS=$(GET_RES "penMeningitis")
    '''
}

// Run AMRsearch to infer resistance (also determinants if any) of other antimicrobials
process OTHER_RESISTANCE {
    label 'amrsearch_container'

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
    label 'bash_container'

    input:
    tuple val(sample_id), path(json)

    output:
    tuple val(sample_id), env(CHL_RES), env(CHL_DETERMINANTS), env(CLI_RES), env(CLI_DETERMINANTS), env(ERY_RES), env(ERY_DETERMINANTS), env(FLQ_RES), env(FLQ_DETERMINANTS), env(KAN_RES), env(KAN_DETERMINANTS), env(LNZ_RES), env(LNZ_DETERMINANTS), env(TCY_RES), env(TCY_DETERMINANTS), env(TMP_RES), env(TMP_DETERMINANTS), env(SSS_RES), env(SSS_DETERMINANTS), env(SXT_RES), env(SXT_DETERMINANTS), emit: result

    shell:
    '''
    function GET_RES {
        echo $( < !{json} jq -r --arg target "$1" '.resistanceProfile[] | select( .agent.key == $target ) | .state' \
            | sed 's/NOT_FOUND/NONE/g' \
            | tr '[:lower:]' '[:upper:]' )
    }

    function GET_DETERMINANTS {
        echo $( < !{json} jq -r --arg target "$1" '.resistanceProfile[] | select( .agent.key == $target ) | .determinantRules | keys[] // "_"' \
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