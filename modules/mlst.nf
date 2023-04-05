// Run mlst to perform PubMLST typing on samples
process MLST {
    label 'mlst_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), path(assembly)

    output:
    tuple val(sample_id), env(ST), env(aroE), env(gdh), env(gki), env(recP), env(spi), env(xpt), env(ddl), emit: result

    script:
    """
    ASSEMBLY="$assembly"

    source get_mlst.sh
    """
}
