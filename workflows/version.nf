// Alternative workflow for getting versions of pipeline and tools
workflow GET_VERSION {
    /* 
    Command to get tool verion within containers

    bitnami/git:2.39.0 
    git -v | sed -r "s/.*\s(.+)/\\1/"

    python:3.11.1-bullseye
    python --version | sed -r "s/.*\s(.+)/\\1/"

    staphb/fastp:0.23.2
    fastp -v 2>&1 | sed -r "s/.*\s(.+)/\\1/"

    staphb/unicycler:0.5.0
    unicycler --version | sed -r "s/.*\sv(.+)/\\1/"

    staphb/shovill:1.1.0-2022Dec
    shovill -v | sed -r "s/.*\s(.+)/\\1/"

    staphb/quast:5.0.2
    quast.py -v | sed -r "s/.*\sv(.+)/\\1/"

    staphb/bwa:0.7.17
    bwa 2>&1 | grep Version | sed -r "s/.*:\s(.+)/\\1/"

    staphb/samtools:1.16
    samtools 2>&1 | grep Version | sed -r "s/.*:\s(.+)/\\1/"

    staphb/bcftools:1.16
    bcftools 2>&1 | grep Version | sed -r "s/.*:\s(.+)/\\1/"

    staphb/poppunk:2.5.0
    poppunk --version | sed -r "s/.*\s(.+)/\\1/"

    harryhungch/spn-pbp-amr:23.01.16
    -

    harryhungch/amrsearch:23.02.23
    -

    staphb/mlst:2.23.0
    mlst -v | sed -r "s/.*\s(.+)/\\1/" 

    staphb/kraken2:2.1.2-no-db
    kraken2 -v | grep version | sed -r "s/.*\s(.+)/\\1/"

    staphb/seroba:1.0.2
    seroba version
    */
}