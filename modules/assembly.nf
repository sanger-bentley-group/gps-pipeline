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

    if ( thread.toInteger() == 0 )
        """
        unicycler -1 "$read1" -2 "$read2" -s "$unpaired" -o results -t "`nproc`" --min_fasta_length "$min_contig_length"
        mv results/assembly.fasta "${fasta}"
        """
    else   
        """
        unicycler -1 "$read1" -2 "$read2" -s "$unpaired" -o results -t "$thread" --min_fasta_length "$min_contig_length"
        mv results/assembly.fasta "${fasta}"
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
    
    if ( thread.toInteger() == 0 )
        """
        shovill --R1 "$read1" --R2 "$read2" --outdir results --cpus "`nproc`" --minlen "$min_contig_length" --force
        mv results/contigs.fa "${fasta}"
        """
    else
        """
        shovill --R1 "$read1" --R2 "$read2" --outdir results --cpus "$thread" --minlen "$min_contig_length" --force
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
