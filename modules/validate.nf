// Map of valid parameters and their value types
validParams = [
    pipeline_version: "alphanumeric",
    help: "boolean",
    init: "boolean",
    version: "boolean",
    reads: "path",
    output: "path",
    assembler: "assemblers",
    seroba_remote: "url_git",
    seroba_local: "path",
    kraken2_db_remote: "url_targz",
    kraken2_db_local: "path",
    kraken2_memory_mapping: "boolean",
    ref_genome: "path_fasta",
    ref_genome_bwa_db_local: "path",
    poppunk_db_remote: "url_targz",
    poppunk_ext_remote: "url_csv",
    poppunk_local: "path",
    spneumo_percentage: "int_float",
    ref_coverage: "int_float",
    het_snp_site: "int",
    contigs: "int",
    length_low: "int",
    length_high: "int",
    depth: "int_float"
]

// Validate whether all provided parameters are valid
def validate(params) {
    invalidParams = []

    params.each{
        k, v -> 
        if (!validParams.keySet().contains(k)) {
            invalidParams.add(k)
        }
    }

    if (invalidParams) {
        log.error("The following invalid option(s) were provided: ${invalidParams.join(', ')}. The pipeline will now be terminated.")
        System.exit(0)
    }
}