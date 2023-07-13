#! /usr/bin/env python3

import sys
from itertools import chain
from collections import defaultdict

report_path = sys.argv[1]
debug_report_path = sys.argv[2]
metadata_path = sys.argv[3]

with open(report_path) as report, open(debug_report_path) as debug_report, open(metadata_path) as metadata:
    # For saving (reference, gene, var_only) combinations as key and their information ({var_change: target}) as value found in metadata
    gene_dict = defaultdict(dict)

    # For saving targets found in metadata as key and their determinants (add to a set) as value
    target_dict = {}

    # Skip the header in metadata
    next(metadata)
    # Go through lines in metadata and save findings to gene_dict and target_dict
    for line in (line.strip() for line in metadata):
        # Extract useful fields
        fields = [str(field) for field in line.split("\t")] 
        ref_name, gene, var_only, var_change, _, target = fields

        # Populating gene_dict
        gene_dict[(ref_name, gene, var_only)].update({var_change: target})
        # Populating target_dict
        target_dict.update({target: set()})

    # Skip the header in report and debug report
    next(report)
    next(debug_report)
    # Go through lines in both report and debug report to detect targets
    for line in (line.strip() for line in chain(report, debug_report)):
        # Extract useful fields
        fields = [str(field) for field in line.split("\t")]
        ref_name, gene, var_only, ref_len, ref_base_assembled, known_var_change, has_known_var, ref_ctg_effect, ref_start, ref_end = fields[1], fields[2], fields[3], fields[7], fields[8], fields[16], fields[17], fields[19], fields[20], fields[21]

        # If coverage (ref_base_assembled / ref_len) < 0.9 or either variable contains non-numeric value, skip the line
        if not ref_base_assembled.isdigit() or not ref_len.isdigit() or int(ref_base_assembled)/int(ref_len) < 0.9:
            continue
        
        # If the known_var_change (. for genes, specific change for variants) is not found in the metadata of the (ref_name, gene, var_only) combination, skip the line
        gene_dict_key = (ref_name, gene, var_only)
        try:
            target = gene_dict[gene_dict_key][known_var_change]
        except KeyError: 
            continue

        # Logic for gene detection. Found means hit.
        if var_only == "0":
            target_dict[target].add(f'Found {ref_name}')
        
        # Logic for variant detection, further criteria required
        if var_only == "1":
            # folP-specific criteria: ref_ctg_effect (effect of change between reference and contig) is one of the keywords and the change occurs within nt 168-201
            if ref_name.lower().startswith("folp") and ref_ctg_effect.lower() in ('fshift', 'trunc', 'indel', 'ins', 'multiple') and (168 <= int(ref_start) <= 201 or 168 <= int(ref_end) <= 201):
                pos = ref_start if ref_start == ref_end else f'{ref_start}-{ref_end}'
                target_dict[target].add(f'{ref_name} {ref_ctg_effect} at {pos}')
            # Common criteria: the assembly has that variant
            elif has_known_var == "1":
                target_dict[target].add(f'{ref_name} {known_var_change}')

    print(target_dict)