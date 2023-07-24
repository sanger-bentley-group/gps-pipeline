#! /usr/bin/env python3

import sys
import glob
import pandas as pd 

workdir_path = sys.argv[1]
ariba_metadata = sys.argv[2]
output_file = sys.argv[3]

output_columns = ['Sample_ID' , 'Read_QC' , 'Assembly_QC' , 'Mapping_QC' , 'Taxonomy_QC' , 'Overall_QC' , 'Bases' , 'Contigs#' , 'Assembly_Length' , 'Seq_Depth' , 'Ref_Cov_%' , 'Het-SNP#' , 'S.Pneumo_%' , 'GPSC' , 'Serotype' , 'ST' , 'aroE' , 'gdh' , 'gki' , 'recP' , 'spi' , 'xpt' , 'ddl' , 'pbp1a' , 'pbp2b' , 'pbp2x' , 'AMO_MIC' , 'AMO_Res' , 'CFT_MIC' , 'CFT_Res(Meningital)' , 'CFT_Res(Non-meningital)' , 'TAX_MIC' , 'TAX_Res(Meningital)' , 'TAX_Res(Non-meningital)' , 'CFX_MIC' , 'CFX_Res' , 'MER_MIC' , 'MER_Res' , 'PEN_MIC' , 'PEN_Res(Meningital)' , 'PEN_Res(Non-meningital)' , 'CHL_Res' , 'CHL_Determinant' , 'ERY_Res' , 'ERY_Determinant' , 'CLI_Res' , 'CLI_Determinant' , 'ERY_CLI_Res' , 'ERY_CLI_Determinant' , 'FQ_Res' , 'FQ_Determinant' , 'LFX_Res' , 'LFX_Determinant' , 'KAN_Res' , 'KAN_Determinant' , 'TET_Res' , 'TET_Determinant' , 'DOX_Res' , 'DOX_Determinant' , 'TMP_Res' , 'TMP_Determinant' , 'SMX_Res' , 'SMX_Determinant' , 'COT_Res' , 'COT_Determinant' , 'RIF_Res' , 'RIF_Determinant' , 'VAN_Res' , 'VAN_Determinant' , 'PILI1' , 'PILI1_Determinant' , 'PILI2' , 'PILI2_Determinant']
df_manifest = pd.DataFrame(columns=output_columns)

dfs = [df_manifest]

reports = glob.glob(workdir_path +'/*.csv')
for report in reports:
    df = pd.read_csv(report)
    dfs.append(df)
  
df_output = pd.concat(dfs, ignore_index=True).sort_values(by=['Sample_ID'])
df_output.to_csv(output_file, index=False, na_rep='_')
