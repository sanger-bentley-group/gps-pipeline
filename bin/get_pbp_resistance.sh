# Extract the results from the output file of the PBP AMR predictor

# For all, replace null or space-only string with empty string
# For resistances, S, I and R in the file are output as SENSITIVE, INTERMEDIATE and RESISTANT respectively

function GET_VALUE {
    echo $( < $JSON_FILE jq -r --arg target "$1" '.[$target]' \
        | sed 's/^null$//g;s/^\s+$//g' )
}

function GET_RES {
    echo $( < $JSON_FILE jq -r --arg target "$1" '.[$target]' \
        | sed 's/^S$/SENSITIVE/g;s/^I$/INTERMEDIATE/g;s/^R$/RESISTANT/g;s/^null$//g;s/^\s+$//g' )
}

pbp1a=$(GET_VALUE "pbp1a")
pbp2b=$(GET_VALUE "pbp2b")
pbp2x=$(GET_VALUE "pbp2x")
AMO_MIC=$(GET_VALUE "amxMic")
AMO=$(GET_RES "amx")
CFT_MIC=$(GET_VALUE "croMic")
CFT_NONMENINGITIS=$(GET_RES "croNonMeningitis")
CFT_MENINGITIS=$(GET_RES "croMeningitis")
TAX_MIC=$(GET_VALUE "ctxMic")
TAX_NONMENINGITIS=$(GET_RES "ctxNonMeningitis")
TAX_MENINGITIS=$(GET_RES "ctxMeningitis")
CFX_MIC=$(GET_VALUE "cxmMic")
CFX=$(GET_RES "cxm")
MER_MIC=$(GET_VALUE "memMic")
MER=$(GET_RES "mem")
PEN_MIC=$(GET_VALUE "penMic")
PEN_NONMENINGITIS=$(GET_RES "penNonMeningitis")
PEN_MENINGITIS=$(GET_RES "penMeningitis")
