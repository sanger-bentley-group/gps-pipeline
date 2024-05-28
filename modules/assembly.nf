// Run Unicycler to get assembly
// Return sample_id and assembly, and publish the assembly to ${params.output}/assemblies directory based on ${params.assembly_publish}
process ASSEMBLY_UNICYCLER {
    label 'unicycler_container'
    label 'farm_high_fallible'

    errorStrategy 'ignore'

    tag "$sample_id"

    publishDir "${params.output}/assemblies", mode: "${params.assembly_publish}"

    input:
    tuple val(sample_id), path(read1), path(read2), path(unpaired)
    val min_contig_length
    val assembler_thread

    output:
    tuple val(sample_id), path(fasta)

    script:
    fasta="${sample_id}.contigs.fasta"
    thread="$assembler_thread"
    """
    READ1=$read1
    READ2=$read2
    UNPAIRED=$unpaired
    MIN_CONTIG_LENGTH=$min_contig_length
    FASTA=$fasta
    THREAD=$thread

    source get_assembly_unicycler.sh
    """
}

// Run Shovill to get assembly
// Return sample_id and assembly, and publish the assembly to ${params.output}/assemblies directory based on ${params.assembly_publish}
process ASSEMBLY_SHOVILL {
    label 'shovill_container'
    label 'farm_high_fallible'

    errorStrategy 'ignore'

    tag "$sample_id"

    publishDir "${params.output}/assemblies", mode: "${params.assembly_publish}"

    input:
    tuple val(sample_id), path(read1), path(read2), path(unpaired)
    val min_contig_length
    val assembler_thread

    output:
    tuple val(sample_id), path(fasta)

    script:
    fasta="${sample_id}.contigs.fasta"
    thread="$assembler_thread"
    """
    READ1=$read1
    READ2=$read2
    MIN_CONTIG_LENGTH=$min_contig_length
    FASTA=$fasta
    THREAD=$thread

    source get_assembly_shovill.sh
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

// Extract assembly QC information and determine QC result based on report.tsv from Quast, and total base count
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
    tuple val(sample_id), env(ASSEMBLY_QC), emit: result
    tuple val(sample_id), path(assembly_qc_report), emit: report

    script:
    assembly_qc_report='assembly_qc_report.csv'
    """
    REPORT="$report"
    BASES="$bases"
    QC_CONTIGS="$qc_contigs"
    QC_LENGTH_LOW="$qc_length_low"
    QC_LENGTH_HIGH="$qc_length_high"
    QC_DEPTH="$qc_depth"
    ASSEMBLY_QC_REPORT="$assembly_qc_report"
    
    source get_assembly_qc.sh      
    """
}
