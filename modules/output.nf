process GENERATE_SAMPLE_REPORT {
    label 'bash_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), path ('report*.csv')

    output:
    path sample_report

    script:
    sample_report="${sample_id}_report.csv"
    """
    SAMPLE_ID=$sample_id
    SAMPLE_REPORT=$sample_report

    source generate_sample_report.sh
    """
}