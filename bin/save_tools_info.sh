# Save received tools versions into a JSON file

add_version () {
    jq -n --arg version "$1" '.version = $version'
}

add_version_and_nproc_value () {
    jq -n --arg version "$1" --arg nproc_value "$2" '.version = $version | .nproc_value = $nproc_value'
}

jq -n \
    --argjson python "$(add_version "$PYTHON_VERSION")" \
    --argjson fastp "$(add_version "$FASTP_VERSION")" \
    --argjson unicycler "$(add_version_and_nproc_value "$UNICYCLER_VERSION" "$UNICYCLER_NPROC_VALUE")" \
    --argjson shovill "$(add_version_and_nproc_value "$SHOVILL_VERSION" "$SHOVILL_NPROC_VALUE")" \
    --argjson quast "$(add_version "$QUAST_VERSION")" \
    --argjson bwa "$(add_version "$BWA_VERSION")" \
    --argjson samtools "$(add_version "$SAMTOOLS_VERSION")" \
    --argjson bcftools "$(add_version "$BCFTOOLS_VERSION")" \
    --argjson poppunk "$(add_version "$POPPUNK_VERSION")" \
    --argjson mlst "$(add_version "$MLST_VERSION")" \
    --argjson kraken2 "$(add_version "$KRAKEN2_VERSION")" \
    --argjson seroba "$(add_version "$SEROBA_VERSION")" \
    --argjson ariba "$(add_version "$ARIBA_VERSION")" \
    '$ARGS.named' > "$JSON_FILE"
