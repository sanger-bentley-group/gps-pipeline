#! /usr/bin/env python3

# Return non-cluster heterozygous SNP (Het-SNP) site count

import re
import sys


# Check argv and save to global variables
if len(sys.argv) != 4:
    sys.exit('Usage: het_snp_count.py VCF MIN_SNP_DISTANCE OUTPUT_FILE')
VCF = sys.argv[1]
MIN_SNP_DISTANCE = int(sys.argv[2]) # Minimum distance between SNPs to not consider as part of cluster
OUTPUT_FILE=sys.argv[3]


def main():
    with open(VCF) as vcf, open(OUTPUT_FILE, 'w') as output_file:
        lines = [line.strip() for line in vcf]

        # List of positions of non-cluster Het-SNPs 
        het_noncluster_pos = []
        # Previous Het-SNP position
        prev_het_pos = None

        for line in lines:
            # Skip lines of header and INDEL calls
            if line.startswith("#") or "INDEL" in line:
                continue
            
            pos, qual, info = extract_vcf_fields(line)

            dp, reads_for_ref, reads_rev_ref, reads_for_non_ref, reads_rev_non_ref, mq, pv4 = extract_info(info)

            if not quality_check(qual, dp, mq, reads_for_non_ref, reads_rev_non_ref, pv4):
                continue

            if is_het_snp(het_noncluster_pos, pos, prev_het_pos, reads_for_non_ref, reads_for_ref, reads_rev_non_ref, reads_rev_ref):
                # Mark current pos as previous Het-SNP pos for the next Het-SNP
                prev_het_pos = pos

        # Save amount of non-cluster Het-SNP sites to OUTPUT_FILE
        output_file.write(f'{len(het_noncluster_pos)}')


# Extract relevant fields from the call
def extract_vcf_fields(line):
    fields = line.split("\t")
    pos, qual, info = fields[1], fields[5], fields[7]

    # Ensure pos is int and qual is float
    return int(pos), float(qual), info


# Extract information from the INFO field
def extract_info(info):
    # Get DP (The number of reads covering or bridging POS)
    dp = re.search(r'DP=([0-9]+)', info).group(1)

    # Get DP4 (Number of forward ref alleles; reverse ref; forward non-ref; reverse non-ref alleles, used in variant calling) 
    reads_for_ref, reads_rev_ref, reads_for_non_ref, reads_rev_non_ref = re.search(r'DP4=([0-9,]+)', info).group(1).split(",")

    # Get MQ (Root-Mean-Square mapping quality of covering reads)
    mq = re.search(r'MQ=([0-9]+)', info).group(1)

    # Get PV4 (P-values for strand bias; baseQ bias; mapQ bias; tail distance bias); set to None if it is not found
    try:
        pv4 = re.search(r'PV4=([0-9,.]+)', info).group(1)
    except AttributeError:
        pv4 = None

    # Ensure dp, reads_for_ref, reads_rev_ref, reads_for_non_ref, reads_rev_non_ref, mq are int
    return *map(int, [dp, reads_for_ref, reads_rev_ref, reads_for_non_ref, reads_rev_non_ref, mq]), pv4


# Quality check for call
def quality_check(qual, dp, mq, reads_for_non_ref, reads_rev_non_ref, pv4):
    # Basic quality check, skip this call if fails
    if not(qual > 50 and dp > 5 and mq > 30 and reads_for_non_ref > 2 and reads_rev_non_ref > 2):
        return False
    
    # Further quality check if PV4 exists, skip this call if fails
    if pv4 is not None:
        pv_strand, pv_baseq, pv_mapq, pv_tail_distance = map(float, pv4.split(","))
        if not (pv_strand > 0.001 and pv_mapq > 0.001 and pv_tail_distance > 0.001):
            return False
    
    return True


# Check if this call is a Het-SNP and add/remove Het-SNP to/from het_noncluster_pos
def is_het_snp(het_noncluster_pos, pos, prev_het_pos, reads_for_non_ref, reads_for_ref, reads_rev_non_ref, reads_rev_ref):
    # Calculate forward and reverse non-reference reads ratios (variant allele frequencies)
    forward_non_ref_ratio = reads_for_non_ref / (reads_for_non_ref + reads_for_ref)
    reverse_non_ref_ratio = reads_rev_non_ref / (reads_rev_non_ref + reads_rev_ref)

    # Consider as Het-SNP when both forward and reverse non-reference reads ratios are below 0.90
    if forward_non_ref_ratio < 0.90 and reverse_non_ref_ratio < 0.90:
        # If the distance between current and previous Het-SNP position is >= the minimum non-cluster SNP distance or there is no previous Het-SNP,
        # add the position to the list of non-cluster Het-SNP positions
        if prev_het_pos is None or pos - prev_het_pos >= MIN_SNP_DISTANCE:
            het_noncluster_pos.append(pos)
        # If the last Het-SNP in the list of non-cluster Het-SNP positions is part of the current cluster, remove it
        elif het_noncluster_pos and pos - het_noncluster_pos[-1] < MIN_SNP_DISTANCE:
            het_noncluster_pos.pop()
    
        return True
    
    return False


if __name__ == "__main__":
    main()
