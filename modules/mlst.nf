// Run mlst to perform PubMLST typing on samples
process MLST {
    label 'mlst_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), path(assembly)

    output:
    tuple val(sample_id), path(mlst_report), emit: report

    script:
    mlst_report='mlst_report.csv'
    """
    ASSEMBLY="$assembly"
    MLST_REPORT="$mlst_report"

    source get_mlst.sh
    """
}
