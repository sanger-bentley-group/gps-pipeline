# GPS Unified Pipeline <!-- omit in toc -->

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-23.10.0-23aa62.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/singularity/)
[![Launch on Nextflow Tower](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Nextflow%20Tower-%234256e7)](https://tower.nf/launch?pipeline=https://github.com/harryhung/gps-unified-pipeline)

The GPS Unified Pipeline is a Nextflow pipeline designed for processing raw reads (FASTQ files) of *Streptococcus pneumoniae* samples. After preprocessing, the pipeline performs initial assessment based on the total bases in reads. Passed samples will be further assess based on assembly, mapping, and taxonomy. If the sample passes all quality controls (QC), the pipeline also provides the sample's serotype, multi-locus sequence typing (MLST), lineage (based on the [Global Pneumococcal Sequence Cluster (GPSC)](https://www.pneumogen.net/gps/GPSC_lineages.html)), and antimicrobial resistance (AMR) against multiple antimicrobials.

The pipeline is designed to be easy to set up and use, and is suitable for use on local machines and high-performance computing (HPC) clusters alike. Additionally, the pipeline only downloads essential files to enable the analysis, and no data is uploaded from the local environment, making it an ideal option for cases where the FASTQ files being analysed is confidential. After initialisation or the first successful complete run, the pipeline can be used offline unless you have changed the selection of any database or container image.

The development of this pipeline is part of the GPS Project ([Global Pneumococcal Sequencing Project](https://www.pneumogen.net/gps/)). 

&nbsp;
# Table of contents <!-- omit in toc -->
- [Workflow](#workflow)
- [Usage](#usage)
  - [Requirement](#requirement)
  - [Accepted Inputs](#accepted-inputs)
  - [Setup](#setup)
  - [Run](#run)
  - [Profile](#profile)
  - [Resume](#resume)
  - [Clean Up](#clean-up)
  - [Nextflow Tower (Optional)](#nextflow-tower-optional)
- [Pipeline Options](#pipeline-options)
  - [Alternative Workflows](#alternative-workflows)
  - [Input and Output](#input-and-output)
  - [QC Parameters](#qc-parameters)
  - [Assembly](#assembly)
  - [Mapping](#mapping)
  - [Taxonomy](#taxonomy)
  - [Serotype](#serotype)
  - [Lineage](#lineage)
  - [Other AMR](#other-amr)
  - [Singularity](#singularity)
  - [Experimental](#experimental)
- [Output](#output)
  - [Output Content](#output-content)
  - [Details of `results.csv`](#details-of-resultscsv)
- [Credits](#credits)


&nbsp;
# Workflow
![Workflow](doc/workflow.drawio.svg)

&nbsp;
# Usage
## Requirement
- A POSIX-compatible system (e.g. Linux, macOS, Windows with [WSL](https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux)) with Bash 3.2 or later
- Java 11 or later (up to 21) ([OpenJDK](https://openjdk.org/)/[Oracle Java](https://www.oracle.com/java/))
- [Docker](https://www.docker.com/) or [Singularity](https://sylabs.io/singularity/)/[Apptainer](https://apptainer.org/)
  - For Linux, [Singularity](https://sylabs.io/singularity/)/[Apptainer](https://apptainer.org/) or [Docker Engine](https://docs.docker.com/engine/) is recommended over [Docker Desktop for Linux](https://docs.docker.com/desktop/). The latter is known to cause permission issues when running the pipeline on Linux. 
- It is recommended to have at least 16GB of RAM and 100GB of free storage
  > ℹ️ Details on storage
  > - The pipeline core files use < 1GB
  > - All default databases use ~30GB in total
  > - All Docker images use ~12GB in total; alternatively, Singularity images use ~4GB in total
  > - The pipeline generates ~1.8GB intermediate files for each sample on average<br>(These files can be removed when the pipeline run is completed, please refer to [Clean Up](#clean-up))<br>
  (To further reduce storage requirement by sacrificing the ability to resume the pipeline, please refer to [Experimental](#experimental))
## Accepted Inputs
- Only Illumina paired-end short reads are supported
- Each sample is expected to be a pair of raw reads following this file name pattern: 
  - `*_{,R}{1,2}{,_001}.{fq,fastq}{,.gz}` 
    - example 1: `SampleName_R1_001.fastq.gz`, `SampleName_R2_001.fastq.gz`
    - example 2: `SampleName_1.fastq.gz`, `SampleName_2.fastq.gz`
    - example 3: `SampleName_R1.fq`, `SampleName_R2.fq`
## Setup 
1. Clone the repository (if Git is installed on your system)
    ```
    git clone https://github.com/HarryHung/gps-unified-pipeline.git
    ```
    or 
    
    Download and unzip/extract the [latest release](https://github.com/HarryHung/gps-unified-pipeline/releases)
2. Go into the local directory of the pipeline and it is ready to use without installation (the directory name might be different)
    ```
    cd gps-unified-pipeline
    ```
3. (Optional) You could perform an initialisation to download all required additional files and container images, so the pipeline can be used at any time with or without the Internet afterwards.
    > ⚠️ Docker or Singularity must be running, and an Internet connection is required.
    - Using Docker as the container engine
      ```
      ./run_pipeline --init
      ```
    - Using Singularity as the container engine
      ```
      ./run_pipeline --init -profile singularity
      ```

## Run
> ⚠️ Docker or Singularity must be running.
<!-- -->
> ⚠️ If this is the first run and initialisation was not performed, an Internet connection is required.
<!-- -->
> ℹ️ By default, Docker is used as the container engine and all the processes are executed by the local machine. See [Profile](#profile) for details on running the pipeline with Singularity or on a HPC cluster.
- You can run the pipeline without options. It will attempt to get the raw reads from the default location (i.e. `input` directory inside the `gps-unified-pipeline` local directory)
  ```
  ./run_pipeline
  ```
- You can also specify the location of the raw reads by adding the `--reads` option
  ```
  ./run_pipeline --reads /path/to/raw-reads-directory
  ```
- For a test run, you could obtain a small test dataset by running the included `download_test_input` script. The dataset will be saved to the `test_input` directory inside the pipeline local directory. You can then run the pipeline on the test data
  ```
  ./download_test_input
  ./run_pipeline --reads test_input
  ```
  - `9870_5#52` will fail the Taxonomy QC and hence Overall QC, therefore without analysis results
  - `17175_7#59` and `21127_1#156` should pass Overall QC, therefore with analysis results

## Profile
- By default, Docker is used as the container engine and all the processes are executed by the local machine. To change this, you could use Nextflow's built-in `-profile` option to switch to other available profiles
  > ℹ️ `-profile` is a built-in Nextflow option, it only has one leading `-`
  ```
  ./run_pipeline -profile [profile name]
  ```
- Available profiles: 
  | Profile Name | Details |
  | --- | --- |
  | `standard`<br> (Default) | Docker is used as the container engine. <br> Processes are executed locally. |
  | `singularity` |  Singularity is used as the container engine. <br> Processes are executed locally. |
  | `lsf` | **The pipeline should be launched from a LSF cluster head node with this profile.** <br>Singularity is used as the container engine. <br> Processes are submitted to your LSF cluster via `bsub` by the pipeline. <br> (Tested on Wellcome Sanger Institute farm5 LSF cluster only) <br> (Option `--kraken2_memory_mapping` default change to `false`.) |

## Resume
- If the pipeline is interrupted mid-run, Nextflow's built-in `-resume` option can be used to resume the pipeline execution instead of starting from scratch again
- You should use the same command of the original run, only add `-resume` at the end (i.e. all pipeline options should be identical) 
  > ℹ️ `-resume` is a built-in Nextflow option, it only has one leading `-`
  - If the original command is
    ```
    ./run_pipeline --reads /path/to/raw-reads-directory
    ```
  - The command to resume the pipeline execution should be
    ```
    ./run_pipeline --reads /path/to/raw-reads-directory -resume
    ```

## Clean Up
- During the run of the pipeline, Nextflow generates a considerable amount of intermediate files
- If the run has been completed and you do not intend to use the `-resume` option or those intermediate files, you can remove the intermediate files using one of the following ways:
  - Run the included `clean_pipeline` script
    - It runs the commands in manual removal for you
    - It removes the `work` directory and log files within the `gps-unified-pipeline` local directory
    ```
    ./clean_pipeline
    ```
  - Manual removal 
    - Remove the `work` directory and log files within the `gps-unified-pipeline` local directory
    ```
    rm -rf work
    rm -rf .nextflow.log*
    ```
  - Run `nextflow clean` command
    - This built-in command cleans up cache and work directories
    - By default, it only cleans up the latest run
    - For details and available options of `nextflow clean`, refer to the [Nextflow documentation](https://www.nextflow.io/docs/latest/cli.html#clean)
    ```
    ./nextflow clean
    ```

## Nextflow Tower (Optional)
The pipeline is compatible with [Launchpad](https://help.tower.nf/23.2/launch/launchpad/) of [Nextflow tower](https://tower.nf/) and [Nextflow `-with-tower` option](https://help.tower.nf/23.2/getting-started/deployment-options/#nextflow-with-tower). For more information, please refer to the [Nextflow Tower documentation](https://help.tower.nf/).

&nbsp;
# Pipeline Options
- The tables below contain the available options that can be used when you run the pipeline
- Usage:
  ```
  ./run_pipeline [option] [value]
  ```
> ℹ️ To permanently change the value of an option, edit the `nextflow.config` file inside the `gps-unified-pipeline` local directory.
<!-- -->
> ℹ️ `$projectDir` is a [Nextflow built-in implicit variables](https://www.nextflow.io/docs/latest/script.html?highlight=projectdir#implicit-variables), it is defined as the local directory of `gps-unified-pipeline`.
<!-- -->
> ℹ️ Pipeline options are not built-in Nextflow options, they are lead with `--` instead of `-`

## Alternative Workflows
  | Option | Values | Description |
  | --- | ---| --- |
  | `--init` | `true` or `false`<br />(Default: `false`) | Use alternative workflow for initialisation, which means downloading all required additional files and container images, and creating databases.<br />Can be enabled by including `--init` without value. |
  | `--version` | `true` or `false`<br />(Default: `false`)| Use alternative workflow for showing versions of pipeline, container images, tools and databases.<br />Can be enabled by including `--version` without value.<br /> (This workflow pulls the required container images if they are not yet available locally) |
  | `--help` | `true` or `false`<br />(Default: `false`)| Show help message.<br />Can be enabled by including `--help` without value. |

## Input and Output
  > ⚠️ `--output` overwrites existing results in the target directory if there is any
  <!-- -->
  > ⚠️ `--db` does not accept user provided local databases, directory content will be overwritten
  <!-- -->
  | Option | Values | Description |
  | --- | ---| --- |
  | `--reads` | Any valid path<br />(Default: `"$projectDir/input"`) | Path to the input directory that contains the reads to be processed. |
  | `--output` | Any valid path<br />(Default: `"$projectDir/output"`)| Path to the output directory that save the results. |
  | `--db` | Any valid path<br />(Default: `"$projectDir/databases"`)| Path to the directory saving databases used by the pipeline. |
  | `--assembly_publish` | `"link"` or `"symlink"` or `"copy"`<br />(Default: `"link"`)| Method used by Nextflow to publish the generated assemblies.<br>(The default setting `"link"` means hard link, therefore will fail if the output directory is set to outside of the working file system) |

## QC Parameters
> ℹ️ Read QC does not have directly accessible parameters. The minimum base count in reads of Read QC is based on the multiplication of `--length_low` and `--depth` of Assembly QC (i.e. default value is `38000000`).
<!-- -->
  | Option | Values | Description |
  | --- | ---| --- |
  | `--spneumo_percentage` | Any integer or float value<br />(Default: `60.00`) | Minimum *S. pneumoniae* percentage in reads to pass Taxonomy QC. |
  | `--non_strep_percentage` | Any integer or float value<br />(Default: `2.00`) | Maximum non-*Streptococcus* genus percentage in reads to pass Taxonomy QC. |
  | `--ref_coverage` | Any integer or float value<br />(Default: `60.00`) | Minimum reference coverage percentage by the reads to pass Mapping QC. |
  | `--het_snp_site` | Any integer value<br />(Default: `220`) | Maximum non-cluster heterozygous SNP (Het-SNP) site count to pass Mapping QC. |
  | `--contigs` | Any integer value<br />(Default: `500`) | Maximum contig count in assembly to pass Assembly QC. |
  | `--length_low` | Any integer value<br />(Default: `1900000`) | Minimum assembly length to pass Assembly QC. |
  | `--length_high` | Any integer value<br />(Default: `2300000`) | Maximum assembly length to pass Assembly QC. |
  | `--depth` | Any integer or float value<br />(Default: `20.00`) | Minimum sequencing depth to pass Assembly QC. |
  
## Assembly
  | Option | Values | Description |
  | --- | ---| --- |
  | `--assembler` | `"shovill"` or `"unicycler"`<br />(Default: `"shovill"`)| Using which SPAdes-based assembler to assemble the reads. |
  | `--min_contig_length` | Any integer value<br />(Default: `500`) | Minimum legnth of contig to be included in the assembly. |

## Mapping
  | Option | Values | Description |
  | --- | ---| --- |
  | `--ref_genome` | Any valid path to a `.fa` or `.fasta` file<br />(Default: `"$projectDir/data/ATCC_700669_v1.fa"`) | Path to the reference genome for mapping. |

## Taxonomy 
  | Option | Values | Description |
  | --- | ---| --- |
  | `--kraken2_db_remote` | Any valid URL to a Kraken2 database in `.tar.gz` or `.tgz` format<br />(Default: [Minikraken v1](https://genome-idx.s3.amazonaws.com/kraken/minikraken2_v1_8GB_201904.tgz)) | URL to a Kraken2 database. |
  | `--kraken2_memory_mapping` | `true` or `false`<br />(Default: `true`) | Using the memory mapping option of Kraken2 or not.<br />`true` means not loading the database into RAM, suitable for memory-limited or fast storage environments. |

## Serotype
  | Option | Values | Description |
  | --- | ---| --- |
  | `--seroba_db_remote` | Any valid URL to a SeroBA release in `.tar.gz` or `.tgz` format<br />(Default: [SeroBA v1.0.5](https://github.com/sanger-bentley-group/seroba/archive/refs/tags/v1.0.5.tar.gz))| URL to a SeroBA release. |
  | `--seroba_kmer` | Any integer value<br />(Default: `71`) | Kmer size for creating the KMC database of SeroBA. |

## Lineage
  | Option | Values | Description |
  | --- | ---| --- |
  | `--poppunk_db_remote` | Any valid URL to a PopPUNK database in `.tar.gz` or `.tgz` format<br />(Default: [GPS v6](https://gps-project.cog.sanger.ac.uk/GPS_v6.tar.gz)) | URL to a PopPUNK database. |
  | `--poppunk_ext_remote` | Any valid URL to a PopPUNK external clusters file in `.csv` format<br />(Default: [GPS v6 GPSC Designation](https://gps-project.cog.sanger.ac.uk/GPS_v6_external_clusters.csv)) | URL to a PopPUNK external clusters file. |

## Other AMR
  | Option | Values | Description |
  | --- | ---| --- |
  | `--ariba_ref` | Any valid path to a `.fa` or `.fasta` file<br />(Default: `"$projectDir/data/ariba_ref_sequences.fasta"`) | Path to the reference sequences for ARIBA. |
  | `--ariba_metadata` | Any valid path to a `tsv` file<br />(Default: `"$projectDir/data/ariba_metadata.tsv"`) | Path to the metadata file for ARIBA. |
  | `--resistance_to_mic` | Any valid path to a `tsv` file<br />(Default: `"$projectDir/data/resistance_to_MIC.tsv"`) | Path to the resistance phenotypes to MIC (minimum inhibitory concentration) lookup table. |

## Singularity
  > ℹ️ This section is only valid when Singularity is used as the container engine

  | Option | Values | Description |
  | --- | ---| --- |
  | `--singularity_cachedir` | Any valid path<br />(Default: `"$projectDir/singularity_cache"`) | Path to the directory where Singularity images should be saved to. |

## Experimental 
  | Option | Values | Description |
  | --- | ---| --- |
  | `--lite` | `true` or `false`<br>(Default: `false`) | ⚠️ Enable this option breaks Nextflow resume function.<br>Reduce storage requirement by removing intermediate `.sam` and `.bam` files once they are no longer needed while the pipeline is still running.<br>The quantity of reduction of storage requirement cannot be guaranteed.<br> Can be enabled by including `--lite` without value. |

# Output
- By default, the pipeline outputs the results into the `output` directory inside the `gps-unified-pipeline` local directory
- It can be changed by adding the option `--output`
  ```
  ./run_pipeline --output /path/to/output-directory
  ```
## Output Content  
- The following directories and files are output into the output directory
  | Directory / File | Description |
  | --- | ---|
  | `assemblies` | This directory contains all assemblies (`.fasta`) generated by the pipeline |
  | `results.csv` | This file contains all the information generated by the pipeline on each sample |
  | `info.txt` | This file contains information regarding the pipeline and parameters of the run |

## Details of `results.csv`
- The following fields can be found in the output `results.csv`
  > ℹ️ The output fields in Other AMR / Virulence type depends on the provided ARIBA reference sequences and metadata file, and resistance phenotypes to MIC lookup table, the below table is based on the defaults.
  <!-- -->
  > ℹ️ Minimum inhibitory concentration (MIC) of an antimicrobial is only provided if it is included in the resistance phenotypes to MIC lookup table
    <!-- -->
  > ℹ️ For resistance phenotypes: S = Sensitive/Susceptible; I = Intermediate; R = Resistant
    <!-- -->
  > ℹ️ For virulence genes: POS = Positive; NEG = Negative
  <!-- -->
  > ⚠️ If the result of `Overall_QC` of a sample is `ASSEMBLER FAILURE`, the assembler has crashed when trying to assembly the reads. You might want to re-run the sample with [another assembler](#assembly), or discard the sample if it is a low quality one.
  <!-- -->
  > ⚠️ If the result of `Serotype` of a sample is `SEROBA FAILURE`, SeroBA has crashed when trying to serotype the sample.
  <!-- -->
  | Field | Type | Description |
  | --- | --- | --- |
  | `Sample_ID` | Identification | Sample ID based on the raw reads file name |
  | `Read_QC` | QC | Read quality control result |
  | `Assembly_QC` | QC | Assembly quality control result |
  | `Mapping_QC` | QC | Mapping quality control result |
  | `Taxonomy_QC` | QC | Taxonomy quality control result |
  | `Overall_QC` | QC | Overall quality control result<br>(Based on `Assembly_QC`, `Mapping_QC` and `Taxonomy_QC`) |
  | `Bases` | Read | Number of bases in the reads<br>(Default: ≥ 38 Mb to pass Read QC) |
  | `Contigs#` | Assembly | Number of contigs in the assembly<br>(Default: ≤ 500 to pass Assembly QC) |
  | `Assembly_Length` | Assembly | Total length of the assembly<br>(Default: 1.9 - 2.3 Mb to pass Assembly QC) |
  | `Seq_Depth` | Assembly | Sequencing depth of the assembly<br>(Default: ≥ 20x to pass Assembly QC) |
  | `Ref_Cov_%` | Mapping | Percentage of reference covered by reads<br>(Default: ≥ 60% to pass Mapping QC) |
  | `Het-SNP#` | Mapping | Non-cluster heterozygous SNP (Het-SNP) site count<br>(Default: ≤ 220 to pass Mapping QC) |
  | `S.Pneumo_%` | Taxonomy | Percentage of reads assigned to *Streptococcus pneumoniae*<br>(Default: ≥ 60% to pass Taxonomy QC) |
  | `Top_Non-Strep_Genus` | Taxonomy | The most abundant non-*Streptococcus* genus in reads |
  | `Top_Non-Strep_Genus_%` | Taxonomy | Percentage of reads assigned to the most abundant non-*Streptococcus* genus<br>(Default: ≤ 2% to pass Taxonomy QC) |
  | `GPSC` | Lineage | GPSC Lineage |
  | `Serotype` | Serotype | Serotype |
  | `ST` | MLST | Sequence Type (ST) |
  | `aroE` | MLST | Allele ID of aroE |
  | `gdh` | MLST | Allele ID of gdh |
  | `gki` | MLST | Allele ID of gki |
  | `recP` | MLST | Allele ID of recP |
  | `spi` | MLST | Allele ID of spi |
  | `xpt` | MLST | Allele ID of xpt |
  | `ddl` | MLST | Allele ID of ddl |
  | `pbp1a` | PBP AMR | Allele ID of pbp1a |
  | `pbp2b` | PBP AMR | Allele ID of pbp2b |
  | `pbp2x` | PBP AMR | Allele ID of pbp2x |
  | `AMO_MIC` | PBP AMR | Estimated minimum inhibitory concentration (MIC) of amoxicillin (AMO) |
  | `AMO_Res` | PBP AMR | Resistance phenotype against AMO |
  | `CFT_MIC` | PBP AMR | Estimated MIC of ceftriaxone (CFT) |
  | `CFT_Res(Meningital)` | PBP AMR | Resistance phenotype against CFT in meningital form |
  | `CFT_Res(Non-meningital)` | PBP AMR | Resistance phenotype against CFT in non-meningital form |
  | `TAX_MIC` | PBP AMR | Estimated MIC of cefotaxime (TAX) |
  | `TAX_Res(Meningital)` | PBP AMR | Resistance phenotype against TAX in meningital form |
  | `TAX_Res(Non-meningital)` | PBP AMR | Resistance phenotype against TAX in non-meningital form |
  | `CFX_MIC` | PBP AMR | Estimated MIC of cefuroxime (CFX) |
  | `CFX_Res` | PBP AMR | Resistance phenotype against CFX |
  | `MER_MIC` | PBP AMR | Estimated MIC of meropenem (MER) |
  | `MER_Res` | PBP AMR | Resistance phenotype against MER |
  | `PEN_MIC` | PBP AMR | Estimated MIC of penicillin (PEN) |
  | `PEN_Res(Meningital)` | PBP AMR | Resistance phenotype against PEN in meningital form |
  | `PEN_Res(Non-meningital)` | PBP AMR | Resistance phenotype against PEN in non-meningital form |
  | `CHL_MIC` | Other AMR | Estimated MIC of Chloramphenicol (CHL) |
  | `CHL_Res` | Other AMR | Resistance phenotype against CHL |
  | `CHL_Determinant` | Other AMR | Known determinants that inferred the CHL resistance |
  | `CLI_MIC` | Other AMR | Estimated MIC of Clindamycin (CLI) |
  | `CLI_Res` | Other AMR | Resistance phenotype against CLI |
  | `CLI_Determinant` | Other AMR | Known determinants that inferred the CLI resistance |
  | `COT_MIC` | Other AMR | Estimated MIC of Co-Trimoxazole (COT) |
  | `COT_Res` | Other AMR | Resistance phenotype against COT |
  | `COT_Determinant` | Other AMR | Known determinants that inferred the COT resistance |
  | `DOX_MIC` | Other AMR | Estimated MIC of Doxycycline (DOX) |
  | `DOX_Res` | Other AMR | Resistance phenotype against DOX |
  | `DOX_Determinant` | Other AMR | Known determinants that inferred the DOX resistance |
  | `ERY_MIC` | Other AMR | Estimated MIC of Erythromycin (ERY) |
  | `ERY_Res` | Other AMR | Resistance phenotype against ERY |
  | `ERY_Determinant` | Other AMR | Known determinants that inferred the ERY resistance |
  | `ERY_CLI_Res` | Other AMR | Resistance phenotype against Erythromycin (ERY) and Clindamycin (CLI) |
  | `ERY_CLI_Determinant` | Other AMR | Known determinants that inferred the ERY and CLI resistance |
  | `FQ_Res` | Other AMR | Resistance phenotype against Fluoroquinolones (FQ) |
  | `FQ_Determinant` | Other AMR | Known determinants that inferred the FQ resistance |
  | `KAN_Res` | Other AMR | Resistance phenotype against Kanamycin (KAN) |
  | `KAN_Determinant` | Other AMR | Known determinants that inferred the KAN resistance |
  | `LFX_MIC` | Other AMR | Estimated MIC of Levofloxacin (LFX) |
  | `LFX_Res` | Other AMR | Resistance phenotype against LFX |
  | `LFX_Determinant` | Other AMR | Known determinants that inferred the LFX resistance |
  | `RIF_MIC` | Other AMR | Estimated MIC of Rifampin (RIF) |
  | `RIF_Res` | Other AMR | Resistance phenotype against RIF |
  | `RIF_Determinant` | Other AMR | Known determinants that inferred the RIF resistance |
  | `SMX_Res` | Other AMR | Resistance phenotype against Sulfamethoxazole (SMX) |
  | `SMX_Determinant` | Other AMR | Known determinants that inferred the SMX resistance |
  | `TET_MIC` | Other AMR | Estimated MIC of Tetracycline (TET) |
  | `TET_Res` | Other AMR | Resistance phenotype against TET |
  | `TET_Determinant` | Other AMR | Known determinants that inferred the TET resistance |
  | `TMP_Res` | Other AMR | Resistance phenotype against Trimethoprim (TMP) |
  | `TMP_Determinant` | Other AMR | Known determinants that inferred the TMP resistance |
  | `VAN_MIC` | Other AMR | Estimated MIC of Vancomycin (VAN) |
  | `VAN_Res` | Other AMR | Resistance phenotype against VAN |
  | `VAN_Determinant` | Other AMR | Known determinants that inferred the VAN resistance |
  | `PILI1` | Virulence | Expression of PILI-1 |
  | `PILI1_Determinant` | Virulence | Known determinants that inferred the PILI-1 expression |
  | `PILI2` | Virulence | Expression of PILI-2 |
  | `PILI2_Determinant` | Virulence | Known determinants that inferred the PILI-2 expression |

&nbsp;
# Credits
This project uses open-source components. You can find the homepage or source code of their open-source projects along with license information below. I acknowledge and am grateful to these developers for their contributions to open source.

[ARIBA](https://sanger-pathogens.github.io/ariba/)
- ARIBA: rapid antimicrobial resistance genotyping directly from sequencing reads Hunt M, Mather AE, Sánchez-Busó L, Page AJ, Parkhill J , Keane JA, Harris SR. Microbial Genomics 2017. doi: [110.1099/mgen.0.000131](http://mgen.microbiologyresearch.org/content/journal/mgen/10.1099/mgen.0.000131)
- License (GPL-3.0): https://github.com/sanger-pathogens/ariba/blob/master/LICENSE
- This tool is used in `GET_ARIBA_DB` and `OTHER_RESISTANCE` processes of the `amr.nf` module

[BCFtools](https://samtools.github.io/bcftools/) and [SAMtools](https://www.htslib.org/)
- Twelve years of SAMtools and BCFtools. Petr Danecek, James K Bonfield, Jennifer Liddle, John Marshall, Valeriu Ohan, Martin O Pollard, Andrew Whitwham, Thomas Keane, Shane A McCarthy, Robert M Davies, Heng Li. **GigaScience**, Volume 10, Issue 2, February 2021, giab008, https://doi.org/10.1093/gigascience/giab008
- Licenses
  - BCFtools (MIT/Expat or GPL-3.0): https://github.com/samtools/bcftools/blob/develop/LICENSE
  - SAMtools (MIT/Expat): https://github.com/samtools/samtools/blob/develop/LICENSE
- These tools are used in `SAM_TO_SORTED_BAM` and `SNP_CALL` processes of the `mapping.nf` module

[BWA](https://github.com/lh3/bwa)
- Li H. (2013) Aligning sequence reads, clone sequences and assembly contigs with BWA-MEM. [arXiv:1303.3997v2](http://arxiv.org/abs/1303.3997) [q-bio.GN]
- License (GPL-3.0): https://github.com/lh3/bwa/blob/master/COPYING
- This tool is used in `GET_REF_GENOME_BWA_DB` and `MAPPING` processes of the `mapping.nf` module

[Docker Images](https://hub.docker.com/u/staphb) of [ARIBA](https://hub.docker.com/r/staphb/ariba), [BCFtools](https://hub.docker.com/r/staphb/bcftools), [BWA](https://hub.docker.com/r/staphb/bwa), [fastp](https://hub.docker.com/r/staphb/fastp), [Kraken 2](https://hub.docker.com/r/staphb/kraken2), [mlst](https://hub.docker.com/r/staphb/mlst), [PopPUNK](https://hub.docker.com/r/staphb/poppunk), [QUAST](https://hub.docker.com/r/staphb/quast), [SAMtools](https://hub.docker.com/r/staphb/samtools), [Shovill](https://hub.docker.com/r/staphb/shovill), [Unicycler](https://hub.docker.com/r/staphb/unicycler) 
- [State Public Health Bioinformatics Workgroup](https://staphb.org/) ([@StaPH-B](https://github.com/StaPH-B))
- License (GPL-3.0): https://github.com/StaPH-B/docker-builds/blob/master/LICENSE
- These Docker images provide containerised environments with different bioinformatics tools for processes of multiple modules 

[Docker Image of network-multitool](https://hub.docker.com/r/wbitt/network-multitool)
- [Wbitt - We Bring In Tomorrow's Technolgies](https://wbitt.com/) ([@WBITT](https://github.com/wbitt))
- License (MIT): https://github.com/wbitt/Network-MultiTool/blob/master/LICENSE
- This Docker image provides the containerised environment with Bash tools for processes of multiple modules 

[Docker Image of Pandas](https://hub.docker.com/r/amancevice/pandas)
- Alexander Mancevice ([@amancevice](https://github.com/amancevice))
- License (MIT): https://github.com/amancevice/docker-pandas/blob/main/LICENSE
- This Docker image provides the containerised environment with Python and Pandas for `GENERATE_OVERALL_REPORT` process of the `output.nf` module, `HET_SNP_COUNT` process of the `mapping.nf` module and `PARSE_OTHER_RESISTANCE` process of the `amr.nf` module

[fastp](https://github.com/OpenGene/fastp)
- Shifu Chen, Yanqing Zhou, Yaru Chen, Jia Gu; fastp: an ultra-fast all-in-one FASTQ preprocessor, Bioinformatics, Volume 34, Issue 17, 1 September 2018, Pages i884–i890, https://doi.org/10.1093/bioinformatics/bty560
- License (MIT): https://github.com/OpenGene/fastp/blob/master/LICENSE
- This tool is used in `PREPROCESS` process of the `preprocess.nf` module

[GPSC_pipeline_nf](https://github.com/sanger-bentley-group/GPSC_pipeline_nf)
- Victoria Dyster ([@blue-moon22](https://github.com/blue-moon22))
- License (GPL-3.0): https://github.com/sanger-bentley-group/GPSC_pipeline_nf/blob/master/LICENSE
- Code adapted into the `get_lineage.sh` script

[Kraken 2](https://ccb.jhu.edu/software/kraken2/)
- Wood, D.E., Lu, J. & Langmead, B. Improved metagenomic analysis with Kraken 2. Genome Biol 20, 257 (2019). https://doi.org/10.1186/s13059-019-1891-0
- License (MIT): https://github.com/DerrickWood/kraken2/blob/master/LICENSE
- This tool is used in `TAXONOMY` process of the `taxonomy.nf` module

[mecA-HetSites-calculator](https://github.com/kumarnaren/mecA-HetSites-calculator) 
- Narender Kumar ([@kumarnaren](https://github.com/kumarnaren))
- License (GPL-3.0): https://github.com/kumarnaren/mecA-HetSites-calculator/blob/master/LICENSE
- Code was rewritten into the `het_snp_count.py` script

[mlst](https://github.com/tseemann/mlst)
- Torsten Seemann ([@tseemann](https://github.com/tseemann))
- License (GPL-2.0): https://github.com/tseemann/mlst/blob/master/LICENSE
- Incorporates components of the [PubMLST database](https://pubmlst.org/terms-conditions)
- This tool is used in `MLST` process of the `mlst.nf` module

[Nextflow](https://www.nextflow.io/)
- P. Di Tommaso, et al. Nextflow enables reproducible computational workflows. Nature Biotechnology 35, 316–319 (2017) doi:[10.1038/nbt.3820](http://www.nature.com/nbt/journal/v35/n4/full/nbt.3820.html)
- License (Apache 2.0): https://github.com/nextflow-io/nextflow/blob/master/COPYING
- This project is a Nextflow pipeline; Nextflow executable `nextflow` is included in this repository

[PopPUNK](https://poppunk.readthedocs.io/)
- Lees JA, Harris SR, Tonkin-Hill G, Gladstone RA, Lo SW, Weiser JN, Corander J, Bentley SD, Croucher NJ. Fast and flexible bacterial genomic epidemiology with PopPUNK. *Genome Research* **29**:1-13 (2019). doi:[10.1101/gr.241455.118](https://dx.doi.org/10.1101/gr.241455.118)
- License (Apache 2.0): https://github.com/bacpop/PopPUNK/blob/master/LICENSE
- This tool is used in `LINEAGE` process of the `lineage.nf` module

[QUAST](https://quast.sourceforge.net/)
- Alla Mikheenko, Andrey Prjibelski, Vladislav Saveliev, Dmitry Antipov, Alexey Gurevich, Versatile genome assembly evaluation with QUAST-LG, *Bioinformatics* (2018) 34 (13): i142-i150. doi: [10.1093/bioinformatics/bty266](https://doi.org/10.1093/bioinformatics/bty266). First published online: June 27, 2018
- License (GPL-2.0): https://github.com/ablab/quast/blob/master/LICENSE.txt
- This tool is used in `ASSEMBLY_ASSESS` process of the `assembly.nf` module

[SeroBA](https://sanger-pathogens.github.io/seroba/)
- **SeroBA: rapid high-throughput serotyping of Streptococcus pneumoniae from whole genome sequence data**. Epping L, van Tonder, AJ, Gladstone RA, GPS Consortium, Bentley SD, Page AJ, Keane JA, Microbial Genomics 2018, doi: [10.1099/mgen.0.000186](http://mgen.microbiologyresearch.org/content/journal/mgen/10.1099/mgen.0.000186)
- License (GPL-3.0): https://github.com/sanger-pathogens/seroba/blob/master/LICENSE
- This project uses a Docker image of a [fork](https://github.com/sanger-bentley-group/seroba)
  - The fork provides SeroBA with the latest updates as the original repository is no longer maintained
  - The Docker image provides the containerised environment with SeroBA for `GET_SEROBA_DB` and `SEROTYPE` processes of the `serotype.nf` module

[resistanceDatabase](https://github.com/kumarnaren/resistanceDatabase)
- Narender Kumar ([@kumarnaren](https://github.com/kumarnaren))
- License (GPL-3.0): https://github.com/kumarnaren/resistanceDatabase/blob/main/LICENSE
- `sequences.fasta` is renamed to `ariba_ref_sequences.fasta` and used as-is
- `metadata.tsv` is renamed to `ariba_metadata.tsv` and modified
- The files are used as the default inputs of `GET_ARIBA_DB` process of the `amr.nf` module

[Shovill](https://github.com/tseemann/shovill)
- Torsten Seemann ([@tseemann](https://github.com/tseemann))
- License (GPL-3.0): https://github.com/tseemann/shovill/blob/master/LICENSE
- This tool is used in `ASSEMBLY_SHOVILL` process of the `assembly.nf` module

[SPN-PBP-AMR](https://cgps.gitbook.io/pathogenwatch/technical-descriptions/antimicrobial-resistance-prediction/spn-pbp-amr)
- [Pathogenwatch](https://pathogen.watch/) ([@pathogenwatch-oss](https://github.com/pathogenwatch-oss))
- License (MIT): https://github.com/pathogenwatch-oss/spn-resistance-pbp/blob/main/LICENSE
- This is a modified version of [AMR predictor](https://github.com/BenJamesMetcalf/Spn_Scripts_Reference) by Ben Metcalf ([@BenJamesMetcalf](https://github.com/BenJamesMetcalf)) at the Centre for Disease Control (CDC)
- This project uses a Docker image of a [fork](https://github.com/sanger-bentley-group/spn-pbp-amr)
  - The fork changes the Docker image from a Docker executable image to a Docker environment for Nextflow integration
  - The Docker image provides the containerised environment with SPN-PBP-MAR for `PBP_RESISTANCE` process of the `amr.nf` module 

[Unicycler](https://github.com/rrwick/Unicycler)
- **Wick RR, Judd LM, Gorrie CL, Holt KE**. Unicycler: resolving bacterial genome assemblies from short and long sequencing reads. *PLoS Comput Biol* 2017.
- License (GPL-3.0): https://github.com/rrwick/Unicycler/blob/main/LICENSE
- This tool is used in `ASSEMBLY_UNICYCLER` process of the `assembly.nf` module