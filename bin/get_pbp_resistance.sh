function GET_VALUE {
    echo $( < $JSON_FILE jq -r --arg target "$1" '.[$target]' \
        | sed 's/=/eq_sign/g' )
}

function GET_RES {
    echo $( < $JSON_FILE jq -r --arg target "$1" '.[$target]' \
        | sed 's/^S$/SENSITIVE/g;s/^I$/INTERMEDIATE/g;s/^R$/RESISTANT/g' )
}

JSON_FILE=$1

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
