# Extract the results from the output file of the AMRsearch

# For resistances, change NOT_FOUND to NONE, and lower cases to upper cases
# For determinants, determinants are separated by "; ", and no determinant is output as "_". Each acquired gene is output as "*gene*", each variant is output as "*gene*_*variant*"

function GET_RES {
    echo $( < $JSON_FILE jq -r --arg target "$1" '.resistanceProfile[] | select( .agent.key == $target ) | .state' \
        | sed 's/NOT_FOUND/NONE/g' \
        | tr '[:lower:]' '[:upper:]' )
}

function GET_DETERMINANTS {
    DETERMINANTS=()

    ACQUIRED=$(< $JSON_FILE jq -r --arg target "$1" '.resistanceProfile[] | select( .agent.key == $target ) | .determinants | .acquired | map(.gene) | join("; ")')
    VARIANTS=$(< $JSON_FILE jq -r --arg target "$1" '.resistanceProfile[] | select( .agent.key == $target ) | .determinants | .variants | map(.gene + "_" +.variant) | join("; ")')

    if [ ! -z "$ACQUIRED" ]
    then
        DETERMINANTS+=("$ACQUIRED")
    fi

    if [ ! -z "$VARIANTS" ]
    then
        DETERMINANTS+=("$VARIANTS")
    fi

    if (( ${#DETERMINANTS[@]} == 0 )); then
        DETERMINANTS+=("_")
    fi

    printf -v DETERMINANTS_OUTPUT '; %s' "${DETERMINANTS[@]}"
    echo ${DETERMINANTS_OUTPUT:2}
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
