// Run fastp to preprocess the FASTQs
process PREPROCESS {
    label 'fastp_container'
    label 'farm_mid'

    tag "$sample_id"

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path(processed_one), path(processed_two), path(processed_unpaired), emit: processed_reads
    tuple val(sample_id), path('fastp.json'), emit: json

    script:
    read_one="${reads[0]}"
    read_two="${reads[1]}"
    processed_one="processed-${sample_id}_1.fastq.gz"
    processed_two="processed-${sample_id}_2.fastq.gz"
    processed_unpaired="processed-${sample_id}_unpaired.fastq.gz"
    """
    fastp --thread `nproc` --in1 "$read_one" --in2 "$read_two" --out1 "$processed_one" --out2 "$processed_two" --unpaired1 "$processed_unpaired" --unpaired2 "$processed_unpaired"
    """
}

// Extract total base count and determine QC result based on output JSON file of fastp 
process READ_QC {
    label 'bash_container'
    label 'farm_low'

    tag "$sample_id"

    input:
    tuple val(sample_id), path(json)
    val(qc_length_low)
    val(qc_depth)

    output:
    tuple val(sample_id), env(BASES), emit: bases
    tuple val(sample_id), env(READ_QC), emit: result

    script:
    """
    JSON="$json"
    QC_LENGTH_LOW="$qc_length_low"
    QC_DEPTH="$qc_depth"

    source read_qc.sh
    """
}
