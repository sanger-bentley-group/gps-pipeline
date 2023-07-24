#! /usr/bin/env python3

import sys
import glob
import pandas as pd 

workdir_path = sys.argv[1]
ariba_metadata = sys.argv[2]
output_file = sys.argv[3]

output_columns = ['Sample_ID' , 'Read_QC' , 'Assembly_QC' , 'Mapping_QC' , 'Taxonomy_QC' , 'Overall_QC' , 'Bases' , 'Contigs#' , 'Assembly_Length' , 'Seq_Depth' , 'Ref_Cov_%' , 'Het-SNP#' , 'S.Pneumo_%' , 'GPSC' , 'Serotype' , 'ST' , 'aroE' , 'gdh' , 'gki' , 'recP' , 'spi' , 'xpt' , 'ddl' , 'pbp1a' , 'pbp2b' , 'pbp2x' , 'AMO_MIC' , 'AMO_Res' , 'CFT_MIC' , 'CFT_Res(Meningital)' , 'CFT_Res(Non-meningital)' , 'TAX_MIC' , 'TAX_Res(Meningital)' , 'TAX_Res(Non-meningital)' , 'CFX_MIC' , 'CFX_Res' , 'MER_MIC' , 'MER_Res' , 'PEN_MIC' , 'PEN_Res(Meningital)' , 'PEN_Res(Non-meningital)']

ariba_targets = set(pd.read_csv(ariba_metadata, sep='\t')['target'].unique())

if 'TET' in ariba_targets:
    ariba_targets.add('DOX')

if 'FQ' in ariba_targets:
    ariba_targets.add('LFX')

if 'TMP' in ariba_targets and 'SMX' in ariba_targets:
    ariba_targets.add('COT')

if 'ERY_CLI' in ariba_targets:
    ariba_targets.update(['ERY', 'CLI'])

ariba_targets = sorted(ariba_targets)

pilis = []

for target in ariba_targets:
    if target.lower().startswith('pili'):
        pilis.append(target)
    else:
        output_columns.extend([f'{target}_Res', f'{target}_Determinant'])

for pili in pilis:
    output_columns.extend([f'{pili}', f'{pili}_Determinant'])

df_manifest = pd.DataFrame(columns=output_columns)

dfs = [df_manifest]

reports = glob.glob(workdir_path +'/*.csv')
for report in reports:
    df = pd.read_csv(report)
    dfs.append(df)
  
df_output = pd.concat(dfs, ignore_index=True).sort_values(by=['Sample_ID'])

df_output = df_output[output_columns]

df_output.to_csv(output_file, index=False, na_rep='_')
