// Return overall QC result based on Assembly QC, Mapping QC and Taxonomy QC
process OVERALL_QC {
    label 'bash_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), val(assembly_qc), val(mapping_qc), val(taxonomy_qc)

    output:
    tuple val(sample_id), env(OVERALL_QC), emit: result

    script:
    """
    ASSEMBLY_QC="$assembly_qc"
    MAPPING_QC="$mapping_qc"
    TAXONOMY_QC="$taxonomy_qc"

    source overall_qc.sh
    """
}
