#! /usr/bin/env python3

# Output AMR of a sample based on its ARIBA report and ARIBA metadata

import sys
from collections import defaultdict
import re
import csv
import pandas as pd


# Check argv
if len(sys.argv) != 4:
    sys.exit('Usage: parse_other_resistance.py DEBUG_REPORT_PATH METADATA_PATH OUTPUT_FILE')

# Global Constants
DEBUG_REPORT_PATH = sys.argv[1]
METADATA_PATH = sys.argv[2]
OUTPUT_FILE = sys.argv[3]
LOW_COVERAGE = "Low Coverage" # String for Low Coverage warning


def main():
    target_dict = get_target()
    hit_dict = find_hit(target_dict)
    output = get_output(hit_dict)

    # Save output to OUTPUT_FILE in csv format
    pd.DataFrame([output]).to_csv(OUTPUT_FILE, index=False, quoting=csv.QUOTE_ALL)


# Saving all targets in metadata as key and their information as values
def get_target():
    df_metadata = pd.read_csv(METADATA_PATH, sep='\t')
    target_dict = defaultdict(lambda: defaultdict(set))

    # Add ref_group based on ref_name to the Dataframe
    df_metadata['ref_group'] = df_metadata['ref_name'].apply(lambda x: x.split('_')[0])

    # Handle each AMR target one-by-one
    for target, df_target in df_metadata.groupby('target'):
        # Create Dataframe slices with presence and variant mechanism respectively
        df_target_presence = df_target[df_target["var_only"] == 0]
        df_target_var = df_target[df_target["var_only"] == 1]
        
        # Logic if presence of gene/non-gene is a mechanism of this target, add releveant ref_name to the existing set (create one by default if set does not exist)
        if len(df_target_presence.index) != 0:
            target_dict[target]['presence'].update(df_target_presence['ref_name'])

        # Logic if variant of gene/non-gene is a mechanism of this target
        if len(df_target_var.index) != 0:
            target_dict[target]['variant'] = defaultdict(lambda: defaultdict(lambda: defaultdict(set)))

            # Further handle each ref_group one-by-one
            for ref_group, df_ref_group in df_target_var.groupby('ref_group'):
                # Each gene/non-gene group can only be gene or non-gene, cannot be both
                is_gene = df_ref_group['gene'].unique()
                if len(is_gene) != 1:
                    raise Exception(f"Error: Conflicting information. {ref_group} is considered as both gene and non-gene in the provided ARIBA metadata.")
                is_gene = is_gene[0]
                    
                # Save whether this ref_group is a gene or not 
                target_dict[target]['variant'][ref_group]['is_gene'] = bool(is_gene)

                # Save variants of each individual gene/non-gene within the ref_group
                for ref, df_ref in df_ref_group.groupby('ref_name'):
                    target_dict[target]['variant'][ref_group]['ref'][ref].update(df_ref['var_change'])

    return target_dict


# Finding hits in ARIBA results based on targets_dict and save hits to hits_dict
def find_hit(target_dict):
    df_report = pd.read_csv(DEBUG_REPORT_PATH, sep="\t")

    # Remove rows with non-numeric value in ref_base_assembled, ref_len, or ctg_cov
    df_report['ref_base_assembled'] = pd.to_numeric(df_report['ref_base_assembled'], errors='coerce')
    df_report['ref_len'] = pd.to_numeric(df_report['ref_len'], errors='coerce')
    df_report['ctg_cov'] = pd.to_numeric(df_report['ctg_cov'], errors='coerce')
    df_report.dropna(subset=['ref_base_assembled', 'ref_len', 'ctg_cov'], inplace=True)

    # Calculate reference coverage
    df_report['coverage'] = df_report['ref_base_assembled'] / df_report['ref_len']

    # Saving all targets in metadata as key and their determinants (i.e. hits) found in ARIBA result as values in set format 
    hit_dict = {target: set() for target in target_dict}

    # Handle each AMR target one-by-one
    for target, target_content in target_dict.items():
        # Logic if presence of gene/non-gene is a mechanism of this target 
        if 'presence' in target_content:
            for ref in target_content['presence']:
                # Add refs that pass coverage and mapped read depth checks
                df_report_hit = df_report[
                    (df_report['ref_name'] == ref) &
                    (df_report['coverage'] >= 0.8) &
                    (df_report['ctg_cov'] >= 20)
                ]
                hit_dict[target].update(df_report_hit['ref_name'])

        # Logic if variant of gene/non-gene is a mechanism of this target
        if 'variant' in target_content:
            # Further handle each ref_group one-by-one
            for ref_group, ref_group_content in target_content['variant'].items():
                # Create Dataframe slices of entries in ref_group only 
                df_ref_group = df_report[df_report['ref_name'].str.startswith(f"{ref_group}_")]

                # If ref_group is gene:
                # - further slice Dataframe to include those with 10x mapped depth only
                # - if no entry in ref_group has 10x+ depth, mark ref_group as Low Coverage and skip 
                if ref_group_content['is_gene']:
                    df_ref_group = df_ref_group[df_ref_group['ctg_cov'] >= 10]
                    if len(df_ref_group.index) == 0:
                        hit_dict[target].add(f'{ref_group} {LOW_COVERAGE}')
                        continue

                # folP ref_group specific criteria: ref_ctg_effect (effect of change between reference and contig) is one of those lead to amino acid changes and the change occurs within nt 166-201 (covering changes affecting aa 56 - 67)
                if ref_group.lower() == "folp":
                    df_ref_group_hit = df_ref_group[
                        (df_ref_group["ref_ctg_effect"].str.lower().isin(['fshift', 'trunc', 'indels', 'ins', 'del', 'multiple', 'nonsyn'])) &
                        (df_ref_group["ref_start"].apply(pd.to_numeric, errors='coerce').between(166, 201) | df_ref_group["ref_end"].apply(pd.to_numeric, errors='coerce').between(166, 201))
                    ]
                    for ref_start, ref_end, ref_name, ref_ctg_effect in df_ref_group_hit[['ref_start', 'ref_end', 'ref_name', 'ref_ctg_effect']].itertuples(index=False, name=None):
                        pos = ref_start if ref_start == ref_end else f'{ref_start}-{ref_end}'
                        hit_dict[target].add(f"{ref_name} {ref_ctg_effect} at {pos}")

                # Criteria for other ref_group: known_var_change is one of the known variants and has_known_var is 1
                else:
                    # Handle each ref_name within the ref_group one-by-one
                    for ref, vars in ref_group_content['ref'].items():
                        df_ref_group_hit = df_ref_group[
                            (df_ref_group['ref_name'] == ref) & 
                            (df_ref_group['known_var_change'].isin(vars)) & 
                            (df_ref_group['has_known_var'].astype(str) == '1')
                        ]
                        if len(df_ref_group_hit.index) != 0:
                            for var_hit in df_ref_group_hit['known_var_change'].unique():
                                hit_dict[target].add(f'{ref} Variant {var_hit}')

    return hit_dict


# Generating final output dataframe based on hit_dict
def get_output(hit_dict):
    output = {}

    # Go through targets in hit_dict
    for target in hit_dict:
        # If the target has no hit, set output as S or NEG (for PILI-1/2), and determinant as _
        if len(hit_dict[target]) == 0:
            if target.lower().startswith('pili'):
                output[target] = 'NEG'
            else:
                output[f'{target}_Res'] = 'S'

            output[f'{target}_Determinant'] = '_'
        else:
            # FQ specific-criteria
            if target.lower() == 'fq':
                # If gyrA or gyrB is mutated, FQ is R
                if any(re.match(rf"^gyr[AB](?!.*{LOW_COVERAGE}$).*$", determinant) for determinant in hit_dict[target]):
                    output[f'{target}_Res'] = 'R'
                # else if gyrA or gyrB have low coverage, FQ is Indeterminable as it cannot be sure whether it will be a R or not
                elif any(re.match(rf"^gyr[AB].*{LOW_COVERAGE}$", determinant) for determinant in hit_dict[target]):
                    output[f'{target}_Res'] = 'Indeterminable'
                # If parC or parE is mutated, FQ is I as gyrA or gyrB mutation already excluded
                elif any(re.match(rf"^par[CE](?!.*{LOW_COVERAGE}$).*$", determinant) for determinant in hit_dict[target]):
                    output[f'{target}_Res'] = 'I'
                # else if parC or parE have low coverage, FQ is Indeterminable as it cannot be sure whether it will be a I or not
                elif any(re.match(rf"^par[CE].*{LOW_COVERAGE}$", determinant) for determinant in hit_dict[target]):
                    output[f'{target}_Res'] = 'Indeterminable'
                # Should only reach this part if all of gyrA, gyrB, parC, parE have good coverage and not mutated, but other hit(s) exist 
                else:
                    raise Exception(f"Error: Unexpect determinant scenario of {target}: {'; '.join(hit_dict[target])}")

            # Criteria for other targets
            else:
                # If all determinants have Low Coverage warning, set output as Indeterminable
                if hit_dict[target] and all(re.match(rf"^.*{LOW_COVERAGE}$", determinant) for determinant in hit_dict[target]):
                    output[f'{target}_Res'] = 'Indeterminable'
                # If the target has a hit without Low Coverage warning, set output as R or POS (for PILI-1/2), and join all hits as determinant
                else:
                    if target.lower().startswith('pili'):
                        output[target] = 'POS'
                    else:
                        output[f'{target}_Res'] = 'R'

            output[f'{target}_Determinant'] = '; '.join(sorted(hit_dict[target]))

    add_inferred_results(output, hit_dict)

    return output


# Inferred cases to add to output
def add_inferred_results(output, hit_dict):
    # If TET exists and DOX does not: add DOX to output; directly copy output and determinant
    if 'TET_Res' in output and 'DOX_Res' not in output:
        output['DOX_Res'] = output['TET_Res']
        output['DOX_Determinant'] = output['TET_Determinant']

    # If FQ exists and LFX does not: add LFX to output; directly copy output and determinant
    if 'FQ_Res' in output and 'LFX_Res' not in output:
        output['LFX_Res'] = output['FQ_Res']
        output['LFX_Determinant'] = output['FQ_Determinant']

    # If both TMP and SMX exists, and COT does not: add COT to output.
    if 'TMP_Res' in output and 'SMX_Res' in output and 'COT_Res' not in output:
        # If Indeterminable in either, COT is Indeterminable; If R in both, COT is R; if R in one of them, COT is I; if S in both, COT is S
        if output['TMP_Res'] == 'Indeterminable' or output['SMX_Res'] == 'Indeterminable':
            output['COT_Res'] = 'Indeterminable'
        elif output['TMP_Res'] == 'R' and output['SMX_Res'] == 'R':
            output['COT_Res'] = 'R'
        elif (output['TMP_Res'] == 'R') ^ (output['SMX_Res'] == 'R'):
            output['COT_Res'] = 'I'
        elif output['TMP_Res'] == 'S' and output['SMX_Res'] == 'S':
            output['COT_Res'] = 'S'

        # Copy TMP_Determinant and SMX_Determinant to COT_Determinant
        output['COT_Determinant'] = res if (res := '; '.join(sorted(hit_dict['TMP'].union(hit_dict['SMX'])))) else '_'

    # If ERY_CLI exists: add ERY and CLI to output.
    if 'ERY_CLI_Res' in output:
        # If ERY_CLI is R, ERY and CLI are R, and add ERY_CLI determinant to their determinants
        # If ERY_CLI is S, ERY and CLI are S if they do not already exist, otherwise leave them unchanged
        if output['ERY_CLI_Res'] == 'R':
            output['ERY_Res'] = 'R'
            output['CLI_Res'] = 'R'
        elif output['ERY_CLI_Res'] == 'S':
            output['ERY_Res'] = output['ERY_Res'] if 'ERY_Res' in output else 'S'
            output['CLI_Res'] = output['CLI_Res'] if 'CLI_Res' in output else 'S'
        
        output['ERY_Determinant'] = '; '.join(sorted(hit_dict['ERY_CLI'].union(hit_dict['ERY']))) if 'ERY' in hit_dict and len(hit_dict['ERY']) != 0 else output['ERY_CLI_Determinant']
        output['CLI_Determinant'] = '; '.join(sorted(hit_dict['ERY_CLI'].union(hit_dict['CLI']))) if 'CLI' in hit_dict and len(hit_dict['CLI']) != 0 else output['ERY_CLI_Determinant']


if __name__ == "__main__":
    main()
