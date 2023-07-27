#! /usr/bin/env python3

# Output AMR of a sample based on its ARIBA report and ARIBA metadata

import sys
from itertools import chain
from collections import defaultdict
import pandas as pd
import csv


# Check argv and save to global variables
if len(sys.argv) != 5:
    sys.exit('Usage: get_other_resistance.py REPORT_PATH DEBUG_REPORT_PATH METADATA_PATH OUTPUT_FILE')

REPORT_PATH = sys.argv[1]
DEBUG_REPORT_PATH = sys.argv[2]
METADATA_PATH = sys.argv[3]
OUTPUT_FILE = sys.argv[4]


def main():
    targets_dict, hits_dict = prepare_dicts()
    find_hits(targets_dict, hits_dict)
    output = get_output(hits_dict)

    # Save output to OUTPUT_FILE in csv format
    pd.DataFrame([output]).to_csv(OUTPUT_FILE, index=False, quoting=csv.QUOTE_ALL)


def prepare_dicts():
    # For saving (reference, gene, var_only) combinations as key and their information ({var_change: target}) as value found in metadata
    # Used to search whether there is a hit in the ARIBA result
    targets_dict = defaultdict(dict)

    # For saving targets found in metadata as key and their determinants (i.e. hits) found in ARIBA result as values in set
    hits_dict = {}

    with open(METADATA_PATH) as metadata:
        # Skip the header in metadata
        next(metadata)

        # Go through lines in metadata and save findings to targets_dict and hits_dict
        for line in (line.strip() for line in metadata):
            # Extract useful fields
            fields = [str(field) for field in line.split("\t")] 
            ref_name, gene, var_only, var_change, _, target = fields

            # Populating targets_dict
            targets_dict[(ref_name, gene, var_only)].update({var_change: target})
            # Populating hits_dict
            hits_dict.update({target: set()})
    
    return targets_dict, hits_dict


def find_hits(targets_dict, hits_dict):
    with open(REPORT_PATH) as report, open(DEBUG_REPORT_PATH) as debug_report:
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
            try:
                target = targets_dict[(ref_name, gene, var_only)][known_var_change]
            except KeyError: 
                continue

            # Logic for gene detection. Found means hit.
            if var_only == "0":
                hits_dict[target].add(f'{ref_name}')
            
            # Logic for variant detection, further criteria required
            if var_only == "1":
                # folP-specific criteria: ref_ctg_effect (effect of change between reference and contig) is one of the keywords and the change occurs within nt 168-201
                if ref_name.lower().startswith("folp") and ref_ctg_effect.lower() in ('fshift', 'trunc', 'indel', 'ins', 'multiple') and (168 <= int(ref_start) <= 201 or 168 <= int(ref_end) <= 201):
                    pos = ref_start if ref_start == ref_end else f'{ref_start}-{ref_end}'
                    hits_dict[target].add(f'{ref_name} {ref_ctg_effect} at {pos}')
                # Common criteria: the assembly has that variant
                elif has_known_var == "1":
                    hits_dict[target].add(f'{ref_name} Variant {known_var_change}')


def get_output(hits_dict):
    # For saving final output, where information is saved per-target
    output = {}

    # Go through targets in hits_dict
    for target in hits_dict:
        # If the target has no hit, set output as S or NEG (only for PILI-1/2), and determinant as _
        if len(hits_dict[target]) == 0:
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

            output[f'{target}_Determinant'] = '; '.join(sorted(hits_dict[target]))

    add_output_special_cases(output, hits_dict)

    return output


# Special cases to add to output
def add_output_special_cases(output, hits_dict):
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
            output['COT_Determinant'] = '; '.join(sorted(hits_dict['TMP'].union(hits_dict['SMX'])))
        elif (output['TMP_Res'] == 'R') ^ (output['SMX_Res'] == 'R'):
            output['COT_Res'] = 'I'
            output['COT_Determinant'] = '; '.join(sorted(hits_dict['TMP'].union(hits_dict['SMX'])))
        elif output['TMP_Res'] == 'S' and output['SMX_Res'] == 'S':
            output['COT_Res'] = 'S'
            output['COT_Determinant'] = '_'

    # If ERY_CLI exists: add ERY and CLI to output.
    # If ERY_CLI is R, ERY and CLI are R, and add ERY_CLI determinant to their determinants
    # If ERY_CLI is S, ERY and CLI are S if they do not already exist, otherwise leave them unchanged
    if 'ERY_CLI_Res' in output:
        if output['ERY_CLI_Res'] == 'R':
            output['ERY_Res'] = 'R'
            output['CLI_Res'] = 'R'
        elif output['ERY_CLI_Res'] == 'S':
            output['ERY_Res'] = output['ERY_Res'] if 'ERY_Res' in output else 'S'
            output['CLI_Res'] = output['CLI_Res'] if 'CLI_Res' in output else 'S'
        
        output['ERY_Determinant'] = '; '.join(sorted(hits_dict['ERY_CLI'].union(hits_dict['ERY']))) if 'ERY' in hits_dict and len(hits_dict['ERY']) != 0 else output['ERY_CLI_Determinant']
        output['CLI_Determinant'] = '; '.join(sorted(hits_dict['ERY_CLI'].union(hits_dict['CLI']))) if 'CLI' in hits_dict and len(hits_dict['CLI']) != 0 else output['ERY_CLI_Determinant']


if __name__ == "__main__":
    main()
