// Determine overall QC result based on Assembly QC, Mapping QC and Taxonomy QC
process OVERALL_QC {
    label 'bash_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), val(read_qc), val(assembly_qc), val(mapping_qc), val(taxonomy_qc)

    output:
    tuple val(sample_id), env(OVERALL_QC), emit: result
    tuple val(sample_id), path(overall_qc_report), emit: report

    script:
    overall_qc_report='overall_qc_report.csv'
    """
    READ_QC="$read_qc"
    ASSEMBLY_QC="$assembly_qc"
    MAPPING_QC="$mapping_qc"
    TAXONOMY_QC="$taxonomy_qc"
    OVERALL_QC_REPORT="$overall_qc_report"

    source get_overall_qc.sh
    """
}
