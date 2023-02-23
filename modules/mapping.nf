// Return database prefix with path for bwa mem runs
// Check if GET_REF_GENOME_BWA_DB_PREFIX has run successfully on the specific reference.
// If not: construct the FM-index database of the reference genome for BWA
process GET_REF_GENOME_BWA_DB_PREFIX {
    input:
    path reference
    val local

    output:
    val "$local/ref"

    shell:
    '''
    if [ ! -f !{local}/done_bwa_db_!{reference} ] || [ ! -f !{local}/ref.amb ] || [ ! -f !{local}/ref.ann ] || [ ! -f !{local}/ref.bwt ] || [ ! -f !{local}/ref.pac ] || [ ! -f !{local}/ref.sa ] ; then
        rm -rf !{local}
        mkdir -p !{local}

        bwa index -p ref !{reference}
        
        mv ref.amb ref.ann ref.bwt ref.pac ref.sa -t !{local}
        
        touch !{local}/done_bwa_db_!{reference}
    fi 
    '''
}

// Map the reads to reference using BWA-MEM algorithm
// Return SAM
process MAPPING {
    input:
    val reference_prefix
    tuple val(sample_id), path(read1), path(read2), path(unpaired)

    output:
    tuple val(sample_id), path("${sample_id}_mapped.sam"), emit: sam

    shell:
    '''
    bwa mem -t $(nproc) !{reference_prefix} <(zcat < !{read1}) <(zcat < !{read2}) > !{sample_id}_mapped.sam
    '''
}

// Convert SAM into BAM and sort it
// Return sorted BAM
process SAM_TO_SORTED_BAM {
    input:
    tuple val(sample_id), path(sam)

    output:
    tuple val(sample_id), path("${sample_id}_mapped_sorted.bam"), emit: bam

    shell:
    '''
    samtools view -@ $(($(nproc) - 1)) -b !{sam} > !{sample_id}_mapped.bam
    rm !{sam}

    samtools sort -o -@ $(nproc) !{sample_id}_mapped_sorted.bam !{sample_id}_mapped.bam
    rm !{sample_id}_mapped.bam
    '''
}

// Return reference coverage percentage by the reads
process REF_COVERAGE {
    input:
    tuple val(sample_id), path(bam)

    output:
    tuple val(sample_id), env(COVERAGE), emit: result

    shell:
    '''
    samtools index -@ $(($(nproc) - 1)) !{bam}
    COVERAGE=$(samtools coverage !{bam} | awk -F'\t' 'FNR==2 {print $6}')
    '''
}

// Return .vcf by calling the SNPs
process SNP_CALL {
    input:
    path reference
    tuple val(sample_id), path(bam)

    output:
    tuple val(sample_id), path("${sample_id}.vcf"), emit: vcf

    shell:
    '''
    bcftools mpileup --threads $(nproc) -f !{reference} !{bam} | bcftools call --threads $(nproc) -mv -O v -o !{sample_id}.vcf
    '''
}

// Return non-cluster heterozygous SNP (Het-SNP) site count
process HET_SNP_COUNT {
    input:
    tuple val(sample_id), path(vcf)

    output:
    tuple val(sample_id), stdout, emit: result

    shell:
    '''
    #! /usr/bin/env python3

    import re

    # Input VCF path
    vcf = "!{vcf}"
    # Minimum distance between SNPs to not consider as part of cluster
    min_snp_distance = 50


    with open(vcf) as f:
        lines = [line.strip() for line in f]

        # List of positions of non-cluster Het-SNPs 
        het_noncluster_pos = []
        # Previous Het-SNP position. Initialise with the negative of min_snp_distance for calculation of the sites in starting positions
        prev_het_pos = -min_snp_distance

        for line in lines:
            # Skip lines of header and INDEL calls
            if line.startswith("#") or "INDEL" in line:
                continue
            
            # Get fields from the call
            chrom, pos, id, ref, alt, qual, filter, info, format, sample = line.split("\t")

            # Get DP (The number of reads covering or bridging POS) from the INFO field
            dp = re.search(r'DP=([0-9]+)', info).group(1)
            # Get DP4 (Number of forward ref alleles; reverse ref; forward non-ref; reverse non-ref alleles, used in variant calling) from the INFO field
            reads_for_ref, reads_rev_ref, reads_for_non_ref, reads_rev_non_ref = re.search(r'DP4=([0-9,]+)', info).group(1).split(",")
            # Get MQ (Root-Mean-Square mapping quality of covering reads) from the INFO field
            mq = re.search(r'MQ=([0-9]+)', info).group(1)

            # Get PV4 (P-values for strand bias; baseQ bias; mapQ bias; tail distance bias) from the INFO field; set to None if it is not found
            try:
                pv4 = re.search(r'PV4=([0-9,.]+)', info).group(1)
            except AttributeError:
                pv4 = None

            # Ensure qual is float
            qual = float(qual)
            # Ensure pos, dp, mq, reads_for_ref, reads_rev_ref, reads_for_non_ref, reads_rev_non_ref are int
            pos, dp, mq, reads_for_ref, reads_rev_ref, reads_for_non_ref, reads_rev_non_ref = map(int, [pos, dp, mq, reads_for_ref, reads_rev_ref, reads_for_non_ref, reads_rev_non_ref])

            # Basic quality filter, skip this call if fails
            if not(qual > 50 and dp > 5 and mq > 30 and reads_for_non_ref > 2 and reads_rev_non_ref > 2):
                continue
            
            # Further quality filter if PV4 exists, skip this call if fails
            if pv4 is not None:
                pv_strand, pv_baseq, pv_mapq, pv_tail_distance = map(float, pv4.split(","))
                if not (pv_strand > 0.001 and pv_mapq > 0.001 and pv_tail_distance > 0.001):
                    continue

            # Calculate forward and reverse non-reference reads ratios (variant allele frequencies)
            forward_non_ref_ratio = reads_for_non_ref / (reads_for_non_ref + reads_for_ref)
            reverse_non_ref_ratio = reads_rev_non_ref / (reads_rev_non_ref + reads_rev_ref)

            # Consider as Het-SNP when both forward and reverse non-reference reads ratios are below 0.90
            if forward_non_ref_ratio < 0.90 and reverse_non_ref_ratio < 0.90:
                # If the distance between current and previous Het-SNP position is >= the minimum non-cluster SNP distance,
                # add the position to the list of non-cluster Het-SNP positions
                if pos - prev_het_pos >= min_snp_distance:
                    het_noncluster_pos.append(pos)
                # If the last Het-SNP in the list of non-cluster Het-SNP positions is part of the current cluster, remove it
                elif het_noncluster_pos and pos - het_noncluster_pos[-1] < min_snp_distance:
                    het_noncluster_pos.pop()
                # Mark current pos as previous Het-SNP pos for the next Het-SNP
                prev_het_pos = pos

        # Amount of non-cluster Het-SNP sites, print to be captured by Nextflow
        het_noncluster_sites = len(het_noncluster_pos)
        print(het_noncluster_sites, end="")
    '''
}

// Return overall mapping QC result based on reference coverage and count of Het-SNP sites
process MAPPING_QC {
    input:
    tuple val(sample_id), val(ref_coverage), val(het_snp_count)

    output:
    tuple val(sample_id), env(COVERAGE), env(HET_SNP), env(MAPPING_QC), emit: detailed_result
    tuple val(sample_id), env(MAPPING_QC), emit: result

    shell:
    '''
    COVERAGE=$(printf %.2f !{ref_coverage})
    HET_SNP=!{het_snp_count}
    
    if (( $(echo "$COVERAGE > 60.00" | bc -l) )) && (( $HET_SNP < 220 )); then
        MAPPING_QC="PASS"
    else
        MAPPING_QC="FAIL"
    fi
    '''
}