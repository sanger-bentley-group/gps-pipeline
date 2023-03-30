GIT_VERSION=$1
PYTHON_VERSION=$2
FASTP_VERSION=$3
UNICYCLER_VERSION=$4
SHOVILL_VERSION=$5
QUAST_VERSION=$6
BWA_VERSION=$7
SAMTOOLS_VERSION=$8
BCFTOOLS_VERSION=$9
POPPUNK_VERSION=${10}
MLST_VERSION=${11}
KRAKEN2_VERSION=${12}
SEROBA_VERSION=${13}
JSON=${14}

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
    '$ARGS.named' > $JSON
