// Return overall QC result based on Assembly QC, Mapping QC and Taxonomy QC
process OVERALL_QC {
    label 'bash_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), val(ASSEMBLY_QC), val(MAPPING_QC), val(TAXONOMY_QC)

    output:
    tuple val(sample_id), env(OVERALL_QC), emit: result

    shell:
    '''
    if [[ "!{ASSEMBLY_QC}" == "PASS" ]] && [[ "!{MAPPING_QC}" == "PASS" ]] && [[ "!{TAXONOMY_QC}" == "PASS" ]]; then
        OVERALL_QC="PASS"
    else
        OVERALL_QC="FAIL"
    fi
    '''
}
