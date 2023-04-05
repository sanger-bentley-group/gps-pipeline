#! /usr/bin/env python3

# Return non-cluster heterozygous SNP (Het-SNP) site count

import re
import sys

# Input VCF path
vcf = sys.argv[1]
# Minimum distance between SNPs to not consider as part of cluster
min_snp_distance = int(sys.argv[2])


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
