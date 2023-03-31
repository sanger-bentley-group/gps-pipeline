function GET_RES {
    echo $( < $JSON_FILE jq -r --arg target "$1" '.resistanceProfile[] | select( .agent.key == $target ) | .state' \
        | sed 's/NOT_FOUND/NONE/g' \
        | tr '[:lower:]' '[:upper:]' )
}

function GET_DETERMINANTS {
    echo $( < $JSON_FILE jq -r --arg target "$1" '.resistanceProfile[] | select( .agent.key == $target ) | .determinantRules | keys[] // "_"' \
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
