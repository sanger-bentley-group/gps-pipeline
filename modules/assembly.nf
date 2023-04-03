// Run Unicycler to get assembly
// Use specific SPAdes executable if provided its directory
// Return sample_id and assembly, and hardlink the assembly to $params.output directory
process ASSEMBLY_UNICYCLER {
    label 'unicycler_container'
    label 'farm_high'

    tag "$sample_id"

    publishDir "$params.output/assemblies", mode: 'link'

    input:
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    tuple val(sample_id), path(fasta)

    script:
    fasta="${sample_id}.contigs.fasta"
    """
    unicycler -1 "$read1" -2 "$read2" -s "$unpaired" -o results -t `nproc`
    mv results/assembly.fasta "${fasta}"
    """
}

// Run Shovill to get assembly
// Return sample_id and assembly, and hardlink the assembly to $params.output directory
process ASSEMBLY_SHOVILL {
    label 'shovill_container'
    label 'farm_high'

    tag "$sample_id"

    publishDir "$params.output/assemblies", mode: 'link'

    input:
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    tuple val(sample_id), path(fasta)

    script:
    fasta="${sample_id}.contigs.fasta"
    """
    shovill --R1 "$read1" --R2 "$read2" --outdir results --cpus `nproc`
    mv results/contigs.fa "${fasta}"
    """
}

// Run quast to assess assembly quality
process ASSEMBLY_ASSESS {
    label 'quast_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), path(assembly)
    output:
    tuple val(sample_id), path('results/report.tsv'), emit: report

    script:
    """
    quast.py -o results "$assembly"
    """
}

// Return Assembly QC result based on report.tsv from Quast and total base count
process ASSEMBLY_QC {
    label 'bash_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), path(report), val(bases)
    val(qc_contigs)
    val(qc_length_low)
    val(qc_length_high)
    val(qc_depth)

    output:
    tuple val(sample_id), env(CONTIGS), env(LENGTH), env(DEPTH), env(ASSEMBLY_QC), emit: detailed_result
    tuple val(sample_id), env(ASSEMBLY_QC), emit: result

    script:
    """
    REPORT="$report"
    BASES="$bases"
    QC_CONTIGS="$qc_contigs"
    QC_LENGTH_LOW="$qc_length_low"
    QC_LENGTH_HIGH="$qc_length_high"
    QC_DEPTH="$qc_depth"
    
    source assembly_qc.sh      
    """
}
