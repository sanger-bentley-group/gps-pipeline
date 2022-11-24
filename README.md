# GPS Unified Pipeline - Work-in-progress

GPS Unified Pipeline is a Nextflow Pipeline for processing Streptococcus pneumoniae sequencing raw reads (FASTQ files) by the GPS Project ([Global Pneumococcal Sequencing Project](https://www.pneumogen.net/gps/)). 

&nbsp;
## Current workflow and progress
![Workflow](doc/workflow.drawio.svg)

&nbsp;
## Usage
### Requirement
- Conda / Mamba
- Git
### Setup
1. Clone the repository
    ```
    git clone https://github.com/HarryHung/gps-unified-pipeline.git
    ```
2. Go into the local copy of the repository
    ```
    cd gps-unified-pipeline
    ```
3. Setup Conda Environment (If using Mamba, replace `conda` with `mamba` in the following commands)
   - MacOS (Intel CPU)
     ```
     conda env create -f environment_mac.yml
     conda activate pipeline
     ```
   - MacOS (Apple Silicon)
     ```
     CONDA_SUBDIR=osx-64 conda env create -f environment_mac.yml
     conda activate pipeline
     conda config --env --set subdir osx-64
     ```
   - Linux
     ```
     conda env create -f environment_linux.yml
     conda activate pipeline
     ```

### Run
- You can run the pipeline without arguments/parameters. It will attempt to get the raw reads from the default location (`data` directory inside the `gps-unified-pipeline` local repository)
  ```
  nextflow run main.nf
  ```
- You can also specific the location of the raw reads by adding argument `--reads`
  ```
  nextflow run main.nf --reads /path/to/raw-reads-directory
  ```