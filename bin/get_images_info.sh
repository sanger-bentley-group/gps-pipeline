# Extract containers information from nextflow.config and save into a JSON file

IMAGES=$(grep -E "container\s?=" $NEXTFLOW_CONFIG \
                | sort -u \
                | sed -r "s/\s+container\s?=\s?'(.+)'/\1/")

BASH=$(grep network-multitool <<< $IMAGES)
GIT=$(grep git <<< $IMAGES)
PYTHON=$(grep python <<< $IMAGES)
FASTP=$(grep fastp <<< $IMAGES)
UNICYCLER=$(grep unicycler <<< $IMAGES)
SHOVILL=$(grep shovill <<< $IMAGES)
QUAST=$(grep quast <<< $IMAGES)
BWA=$(grep bwa <<< $IMAGES)
SAMTOOLS=$(grep samtools <<< $IMAGES)
BCFTOOLS=$(grep bcftools <<< $IMAGES)
POPPUNK=$(grep poppunk <<< $IMAGES)
SPN_PBP_AMR=$(grep spn-pbp-amr <<< $IMAGES)
AMRSEARCH=$(grep amrsearch <<< $IMAGES)
MLST=$(grep mlst <<< $IMAGES)
KRAKEN2=$(grep kraken2 <<< $IMAGES)
SEROBA=$(grep seroba <<< $IMAGES)

add_container () {
    jq -n --arg container $1 '.container = $container'
}

jq -n \
    --argjson bash "$(add_container $BASH)" \
    --argjson git "$(add_container $GIT)" \
    --argjson python "$(add_container $PYTHON)" \
    --argjson fastp "$(add_container $FASTP)" \
    --argjson unicycler "$(add_container $UNICYCLER)" \
    --argjson shovill "$(add_container $SHOVILL)" \
    --argjson quast "$(add_container $QUAST)" \
    --argjson bwa "$(add_container $BWA)" \
    --argjson samtools "$(add_container $SAMTOOLS)" \
    --argjson bcftools "$(add_container $BCFTOOLS)" \
    --argjson poppunk "$(add_container $POPPUNK)" \
    --argjson spn_pbp_amr "$(add_container $SPN_PBP_AMR)" \
    --argjson amrsearch "$(add_container $AMRSEARCH)" \
    --argjson mlst "$(add_container $MLST)" \
    --argjson kraken2 "$(add_container $KRAKEN2)" \
    --argjson seroba "$(add_container $SEROBA)" \
    '$ARGS.named' > $JSON_FILE
