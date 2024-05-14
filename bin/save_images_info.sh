# Save containers information of workflow into a JSON file

find_image () {
    sort -u "$PROCESSES_CONTAINERS_LIST" | grep "$1" | sed -r "s/.+\t(.+)/\1/"
}

BASH=$(find_image bash)
PYTHON=$(find_image python)
FASTP=$(find_image fastp)
UNICYCLER=$(find_image unicycler)
SHOVILL=$(find_image shovill)
QUAST=$(find_image quast)
BWA=$(find_image bwa)
SAMTOOLS=$(find_image samtools)
BCFTOOLS=$(find_image bcftools)
POPPUNK=$(find_image poppunk)
SPN_PBP_AMR=$(find_image spn-pbp-amr)
ARIBA=$(find_image ariba)
MLST=$(find_image mlst)
KRAKEN2=$(find_image kraken2)
SEROBA=$(find_image seroba)

add_container () {
    jq -n --arg container "$1" '.container = $container'
}

jq -n \
    --argjson bash "$(add_container "$BASH")" \
    --argjson python "$(add_container "$PYTHON")" \
    --argjson fastp "$(add_container "$FASTP")" \
    --argjson unicycler "$(add_container "$UNICYCLER")" \
    --argjson shovill "$(add_container "$SHOVILL")" \
    --argjson quast "$(add_container "$QUAST")" \
    --argjson bwa "$(add_container "$BWA")" \
    --argjson samtools "$(add_container "$SAMTOOLS")" \
    --argjson bcftools "$(add_container "$BCFTOOLS")" \
    --argjson poppunk "$(add_container "$POPPUNK")" \
    --argjson spn_pbp_amr "$(add_container "$SPN_PBP_AMR")" \
    --argjson ariba "$(add_container "$ARIBA")" \
    --argjson mlst "$(add_container "$MLST")" \
    --argjson kraken2 "$(add_container "$KRAKEN2")" \
    --argjson seroba "$(add_container "$SEROBA")" \
    '$ARGS.named' > "$JSON_FILE"
