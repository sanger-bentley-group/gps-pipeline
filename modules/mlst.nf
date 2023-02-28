// Run mlst to perform PubMLST typing on samples
process MLST {
    label 'mlst_container'

    input:
    tuple val(sample_id), path(assembly)

    output:
    tuple val(sample_id), env(ST), env(aroE), env(gdh), env(gki), env(recP), env(spi), env(xpt), env(ddl), emit: result

    shell:
    '''
    mlst --legacy --scheme spneumoniae !{assembly} > output.tsv

    ST=$(awk -F'\t' 'FNR == 2 {print $3}' output.tsv)
    aroE=$(awk -F'\t' 'FNR == 2 {print $4}' output.tsv)
    gdh=$(awk -F'\t' 'FNR == 2 {print $5}' output.tsv)
    gki=$(awk -F'\t' 'FNR == 2 {print $6}' output.tsv)
    recP=$(awk -F'\t' 'FNR == 2 {print $7}' output.tsv)
    spi=$(awk -F'\t' 'FNR == 2 {print $8}' output.tsv)
    xpt=$(awk -F'\t' 'FNR == 2 {print $9}' output.tsv)
    ddl=$(awk -F'\t' 'FNR == 2 {print $10}' output.tsv)
    '''
}