# Extract the results from the output file of the AMRsearch

# For resistances, change NOT_FOUND to S, lower cases to upper cases, SENSITIVE to S, INTERMEDIATE to I, RESISTANT to R, null or space-only string to empty string
# For determinants, determinants are sorted and separated by "; ", and no determinant is output as "_". Each acquired gene is output as "*gene*", each variant is output as "*gene*_*variant*"

function GET_RES {
    echo $( < $JSON_FILE jq -r --arg target "$1" '.resistanceProfile[] | select( .agent.key == $target ) | .state' \
        | tr '[:lower:]' '[:upper:]' \
        | sed 's/^NOT_FOUND$/S/g;s/^SENSITIVE$/S/g;s/^INTERMEDIATE$/I/g;s/^RESISTANT$/R/g;s/^null$//g;s/^\s+$//g' )
}

function GET_DETERMINANTS {
    DETERMINANTS=()

    ACQUIRED=( $(< $JSON_FILE jq -r --arg target "$1" '.resistanceProfile[] | select( .agent.key == $target ) | .determinants | .acquired | map(.gene)[]') )
    VARIANTS=( $(< $JSON_FILE jq -r --arg target "$1" '.resistanceProfile[] | select( .agent.key == $target ) | .determinants | .variants | map(.gene + "_" +.variant)[]') )

    if (( ${#ACQUIRED[@]} != 0 )); then
        DETERMINANTS+=( "${ACQUIRED[@]}" )
    fi

    if (( ${#VARIANTS[@]} != 0 )); then
        DETERMINANTS+=( "${VARIANTS[@]}" )
    fi

    if (( ${#DETERMINANTS[@]} == 0 )); then
        DETERMINANTS+=("_")
    fi

    IFS=$'\n' SORTED_DETERMINANTS=($(sort -f <<<"${DETERMINANTS[*]}")); unset IFS
    printf -v JOINED_DETERMINANTS '; %s' "${SORTED_DETERMINANTS[@]}"
    echo ${JOINED_DETERMINANTS:2}
}

CHL_RES=$(GET_RES "CHL")
CHL_DETERMINANTS=$(GET_DETERMINANTS "CHL")

CLD_RES=$(GET_RES "CLI")
CLD_DETERMINANTS=$(GET_DETERMINANTS "CLI")

ERY_RES=$(GET_RES "ERY")
ERY_DETERMINANTS=$(GET_DETERMINANTS "ERY")

FQ_RES=$(GET_RES "FLQ")
FQ_DETERMINANTS=$(GET_DETERMINANTS "FLQ")

KAN_RES=$(GET_RES "KAN")
KAN_DETERMINANTS=$(GET_DETERMINANTS "KAN")

LZO_RES=$(GET_RES "LNZ")
LZO_DETERMINANTS=$(GET_DETERMINANTS "LNZ")

TET_RES=$(GET_RES "TCY")
TET_DETERMINANTS=$(GET_DETERMINANTS "TCY")

TMP_RES=$(GET_RES "TMP")
TMP_DETERMINANTS=$(GET_DETERMINANTS "TMP")

SMX_RES=$(GET_RES "SSS")
SMX_DETERMINANTS=$(GET_DETERMINANTS "SSS")

COT_RES=$(GET_RES "SXT")
COT_DETERMINANTS=$(GET_DETERMINANTS "SXT")
