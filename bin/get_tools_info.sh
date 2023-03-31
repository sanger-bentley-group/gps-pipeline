add_version () {
    jq -n --arg version $1 '.version = $version'
}

jq -n \
    --argjson git "$(add_version "$GIT_VERSION")" \
    --argjson python "$(add_version "$PYTHON_VERSION")" \
    --argjson fastp "$(add_version "$FASTP_VERSION")" \
    --argjson unicycler "$(add_version "$UNICYCLER_VERSION")" \
    --argjson shovill "$(add_version "$SHOVILL_VERSION")" \
    --argjson quast "$(add_version "$QUAST_VERSION")" \
    --argjson bwa "$(add_version "$BWA_VERSION")" \
    --argjson samtools "$(add_version "$SAMTOOLS_VERSION")" \
    --argjson bcftools "$(add_version "$BCFTOOLS_VERSION")" \
    --argjson poppunk "$(add_version "$POPPUNK_VERSION")" \
    --argjson mlst "$(add_version "$MLST_VERSION")" \
    --argjson kraken2 "$(add_version "$KRAKEN2_VERSION")" \
    --argjson seroba "$(add_version "$SEROBA_VERSION")" \
    '$ARGS.named' > $JSON_FILE
