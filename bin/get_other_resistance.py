#! /usr/bin/env python3

# Output AMR of a sample based on its ARIBA report and ARIBA metadata

import sys
from itertools import chain
from collections import defaultdict
import json

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
            target_dict[target].add(f'{ref_name}')
        
        # Logic for variant detection, further criteria required
        if var_only == "1":
            # folP-specific criteria: ref_ctg_effect (effect of change between reference and contig) is one of the keywords and the change occurs within nt 168-201
            if ref_name.lower().startswith("folp") and ref_ctg_effect.lower() in ('fshift', 'trunc', 'indel', 'ins', 'multiple') and (168 <= int(ref_start) <= 201 or 168 <= int(ref_end) <= 201):
                pos = ref_start if ref_start == ref_end else f'{ref_start}-{ref_end}'
                target_dict[target].add(f'{ref_name} {ref_ctg_effect} at {pos}')
            # Common criteria: the assembly has that variant
            elif has_known_var == "1":
                target_dict[target].add(f'{ref_name} Variant {known_var_change}')

    # For saving final output, where information is saved per-target
    output = {}

    # Go through targets in metadata
    for target in target_dict:
        # If the target has no hit, set output as S or NEG (only for PILI-1/2), and determinant as _
        if len(target_dict[target]) == 0:
            if target.lower().startswith('pili'):
                output[target] = 'NEG'
            else:
                output[f'{target}_Res'] = 'S'

            output[f'{target}_Determinant'] = '_'
        # If the target has hit, set output as R or POS (only for PILI-1/2), and join all hits as determinant
        else:
            if target.lower().startswith('pili'):
                output[target] = 'POS'
            else:
                output[f'{target}_Res'] = 'R'

            output[f'{target}_Determinant'] = '; '.join(target_dict[target])

    # Special cases to add to output

    # If TET exists and DOX does not: add DOX to output; directly copy output and determinant
    if 'TET_Res' in output and 'DOX_Res' not in output:
        output['DOX_Res'] = output['TET_Res']
        output['DOX_Determinant'] = output['TET_Determinant']

    # If FQ exists and LFX does not: add LFX to output; directly copy output and determinant
    if 'FQ_Res' in output and 'LFX_Res' not in output:
        output['LFX_Res'] = output['FQ_Res']
        output['LFX_Determinant'] = output['FQ_Determinant']

    # If both TMP and SMX exists, and COT does not: add COT to output.
    # If R in both, COT is R; if R in one of them, COT is I; if S in both, COT is S
    # Copy TMP_Determinant and SMX_Determinant to COT_Determinant
    if 'TMP_Res' in output and 'SMX_Res' in output and 'COT_Res' not in output:
        if output['TMP_Res'] == 'R' and output['SMX_Res'] == 'R':
            output['COT_Res'] = 'R'
            output['COT_Determinant'] = '; '.join(target_dict['TMP'].union(target_dict['SMX']))
        elif (output['TMP_Res'] == 'R') ^ (output['SMX_Res'] == 'R'):
            output['COT_Res'] = 'I'
            output['COT_Determinant'] = '; '.join(target_dict['TMP'].union(target_dict['SMX']))
        elif output['TMP_Res'] == 'S' and output['SMX_Res'] == 'S':
            output['COT_Res'] = 'S'
            output['COT_Determinant'] = '_'

    # If ERY_CLI exists, add ERY and CLI to output.
    # If ERY_CLI is R, ERY and CLI are R, and add ERY_CLI determinant to their determinants
    # If ERY_CLI is S, ERY and CLI are S if they do not already exist, otherwise leave them unchanged
    if 'ERY_CLI_Res' in output:
        if output['ERY_CLI_Res'] == 'R':
            output['ERY_Res'] = 'R'
            output['CLI_Res'] = 'R'
        elif output['ERY_CLI_Res'] == 'S':
            output['ERY_Res'] = output['ERY_Res'] if 'ERY_Res' in output else 'S'
            output['CLI_Res'] = output['CLI_Res'] if 'CLI_Res' in output else 'S'
        
        output['ERY_Determinant'] = '; '.join(target_dict['ERY_CLI'].union(target_dict['ERY'])) if 'ERY' in target_dict else output['ERY_CLI_Determinant']
        output['CLI_Determinant'] = '; '.join(target_dict['ERY_CLI'].union(target_dict['CLI'])) if 'CLI' in target_dict else output['ERY_CLI_Determinant']

    print(json.dumps(output, indent=4))