#! /usr/bin/env python3

# Generate overall report based on sample reports and columns specified by COLUMNS_BY_CATEGORY and ARIBA metadata

import sys
from itertools import chain
import pandas as pd
import glob


# Specify columns need to be included in the output file and their orders (except those based on ARIBA metadata)
COLUMNS_BY_CATEGORY = {
    'IDENTIFICATION': ['Sample_ID'],
    'QC': ['Read_QC' , 'Assembly_QC' , 'Mapping_QC' , 'Taxonomy_QC' , 'Overall_QC'] ,
    'READ': ['Bases'], 
    'ASSEMBLY': ['Contigs#' , 'Assembly_Length' , 'Seq_Depth'],
    'MAPPING': ['Ref_Cov_%' , 'Het-SNP#'],
    'TAXONOMY': ['S.Pneumo_%', 'Second_Species', 'Second_Species_%'],
    'LINEAGE': ['GPSC'],
    'SEROTYPE': ['Serotype'],
    'MLST': ['ST' , 'aroE' , 'gdh' , 'gki' , 'recP' , 'spi' , 'xpt' , 'ddl'],
    'PBP': ['pbp1a' , 'pbp2b' , 'pbp2x' , 'AMO_MIC' , 'AMO_Res' , 'CFT_MIC' , 'CFT_Res(Meningital)' , 'CFT_Res(Non-meningital)' , 'TAX_MIC' , 'TAX_Res(Meningital)' , 'TAX_Res(Non-meningital)' , 'CFX_MIC' , 'CFX_Res' , 'MER_MIC' , 'MER_Res' , 'PEN_MIC' , 'PEN_Res(Meningital)' , 'PEN_Res(Non-meningital)']
}


# Check argv and save to global variables
if len(sys.argv) != 4:
    sys.exit('Usage: generate_overall_report.py INPUT_PATTERN ARIBA_METADATA OUTPUT_FILE')
INPUT_PATTERN = sys.argv[1]
ARIBA_METADATA = sys.argv[2]
OUTPUT_FILE = sys.argv[3]


def main():
    output_columns = get_output_columns()
    df_output = get_df_output(output_columns)

    # Saving df_output to OUTPUT_FILE in csv format
    df_output.to_csv(OUTPUT_FILE, index=False, na_rep='_')


# Get output columns based on COLUMNS_BY_CATEGORY and ARIBA metadata
def get_output_columns():
    output_columns = list(chain.from_iterable(COLUMNS_BY_CATEGORY.values()))
    add_ariba_columns(output_columns)
    return output_columns


# Based on ARIBA metadata, add additional output columns
def add_ariba_columns(output_columns):
    # Get all targets in ARIBA metadata
    ariba_targets = set(pd.read_csv(ARIBA_METADATA, sep='\t')['target'].unique())

    # Adding special cases if certain targets exist
    if 'TET' in ariba_targets:
        ariba_targets.add('DOX')
    if 'FQ' in ariba_targets:
        ariba_targets.add('LFX')
    if 'TMP' in ariba_targets and 'SMX' in ariba_targets:
        ariba_targets.add('COT')
    if 'ERY_CLI' in ariba_targets:
        ariba_targets.update(['ERY', 'CLI'])

    # Add all targets alphabetically, except always adding PILI at the end
    pilis = []
    for target in sorted(ariba_targets):
        if target.lower().startswith('pili'):
            pilis.append(target)
        else:
            output_columns.extend([f'{target}_Res', f'{target}_Determinant'])
    for pili in pilis:
        output_columns.extend([f'{pili}', f'{pili}_Determinant'])


# Generating df_output based on all sample reports with columns in the order of output_columns
def get_df_output(output_columns):
    # Generate an empty dataframe as df_manifest based on output_columns
    df_manifest = pd.DataFrame(columns=output_columns)

    # Generate a dataframe for each sample report and then concat df_manifest and all dataframes into df_output 
    dfs = [df_manifest]
    reports = glob.glob(INPUT_PATTERN)
    for report in reports:
        df = pd.read_csv(report, dtype=str)
        dfs.append(df)
    df_output = pd.concat(dfs, ignore_index=True).sort_values(by=['Sample_ID'])

    # Ensure column order in df_output is the same as output_columns
    df_output = df_output[output_columns]

    return df_output


if __name__ == "__main__":
    main()
