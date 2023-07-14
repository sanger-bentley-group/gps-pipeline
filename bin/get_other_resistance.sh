# Run get_other_resistance.py to infer AMR from ARIBA reports, then capture individual AMR from the output for Nextflow

function GET_VALUE {
    echo $(grep \"$1\" <<< $OUTPUT | sed -r 's/.+: "(.*)",?/\1/')
}

OUTPUT=$(get_other_resistance.py "$REPORT" "$REPORT_DEBUG" "$METADATA")

CHL_Res=$(GET_VALUE "CHL_Res")
CHL_Determinant=$(GET_VALUE "CHL_Determinant")
ERY_Res=$(GET_VALUE "ERY_Res")
ERY_Determinant=$(GET_VALUE "ERY_Determinant")
FQ_Res=$(GET_VALUE "FQ_Res")
FQ_Determinant=$(GET_VALUE "FQ_Determinant")
KAN_Res=$(GET_VALUE "KAN_Res")
KAN_Determinant=$(GET_VALUE "KAN_Determinant")
TET_Res=$(GET_VALUE "TET_Res")
TET_Determinant=$(GET_VALUE "TET_Determinant")
TMP_Res=$(GET_VALUE "TMP_Res")
TMP_Determinant=$(GET_VALUE "TMP_Determinant")
SMX_Res=$(GET_VALUE "SMX_Res")
SMX_Determinant=$(GET_VALUE "SMX_Determinant")
ERY_CLI_Res=$(GET_VALUE "ERY_CLI_Res")
ERY_CLI_Determinant=$(GET_VALUE "ERY_CLI_Determinant")
RIF_Res=$(GET_VALUE "RIF_Res")
RIF_Determinant=$(GET_VALUE "RIF_Determinant")
VAN_Res=$(GET_VALUE "VAN_Res")
VAN_Determinant=$(GET_VALUE "VAN_Determinant")
PILI1=$(GET_VALUE "PILI1")
PILI1_Determinant=$(GET_VALUE "PILI1_Determinant")
PILI2=$(GET_VALUE "PILI2")
PILI2_Determinant=$(GET_VALUE "PILI2_Determinant")