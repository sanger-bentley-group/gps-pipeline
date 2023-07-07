#! /usr/bin/env python3

import sys

report_path = sys.argv[1]
metadata_path = sys.argv[2]

with open(report_path) as report, open(metadata_path) as metadata:
    # Save (reference, gene, var_only) combination found in metadata
    gene_dict = {}
    # Save drug found in metadata
    drug_set = set()

    # Skip the header in metadata
    next(metadata)
    # Go through lines in metadata and save findings to gene_dict and drug_set
    lines = [line.strip() for line in metadata]
    for line in lines:
        fields = [str(field) for field in line.split("\t")] 
        reference, gene, var_only, var_change, _, drug = fields
        gene_dict[(reference, gene, var_only)] = {"var_change": var_change, "drug": drug}
        drug_set.add(drug)

    # Skip the header in report
    next(report)
    # Go through lines in report to detect targets
    lines = [line.strip() for line in report]
    for line in lines:
        # Extract useful fields
        fields = [str(field) for field in line.split("\t")]
        ref_name, gene, var_only, ref_len, ref_base_assembled, known_var_change, has_known_var = fields[1], fields[2], fields[3], fields[7], fields[8], fields[16], fields[17]

        # If coverage (ref_base_assembled / ref_len) < 0.9 or either variable contains non-numeric value, skip the line
        if not ref_base_assembled.isdigit() or not ref_len.isdigit() or int(ref_base_assembled)/int(ref_len) < 0.9:
            continue
        
        # WIP
        gene_dict_key = (ref_name, gene, var_only)
        if gene_dict_key in gene_dict:
            if var_only == "0":
                print(ref_name, gene_dict[gene_dict_key])
            if var_only == "1" and gene_dict[gene_dict_key]['var_change'] == known_var_change and has_known_var == "1":
                print(ref_name, gene_dict[gene_dict_key])
