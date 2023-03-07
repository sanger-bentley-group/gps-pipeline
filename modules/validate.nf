// Map of valid parameters and their value types
validParams = [
    help: "boolean",
    init: "boolean",
    version: "boolean",
    reads: "path_exist",
    output: "path",
    assembler: "assembler",
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
    // Skip validation when help option is used
    if (params.help) {
        return
    }

    // For initalisation, skip input and output directories checks
    // For version, skip all file paths related checks
    skippedParams = []
    if (params.init) {
        skippedParams = ['reads', 'output']
    } else if (params.version) {
        validParams.each{
            key, value ->
            if (["path", "path_exist", "path_fasta"].contains(value) ) {
                skippedParams.add(key)
            }
        }
    }
    skippedParams.each { key -> validParams[key] = 'skip' }

    // To save invalid parameters in this list
    invalidParams = []
    // To save invalid parameter values as "parameter : [value, issue]" in this map
    invalidValues = [:]

    params.each{
        key, value -> 

        // If parameter is invalid, add it to invalidParams list and skip the following checks
        if (!validParams.keySet().contains(key)) {
            invalidParams.add(key)
            return
        }
        
        // Based on the value type of the parameter, perform the appropriate check
        switch(validParams[key]){
            case 'skip':
                break

            case 'boolean':
                if (value !instanceof Boolean) {
                    invalidValues[key] = [value, "boolean value"]
                }
                break
            
            case 'int':
                if (value !instanceof Integer) {
                    invalidValues[key] = [value, "integer value"]
                }
                break
            
            case 'int_float':
                if (value !instanceof Integer && value !instanceof BigDecimal && value !instanceof Double) {
                    invalidValues[key] = [value, "integer or float value"]
                }
                break

            case 'assembler':
                if (!["shovill", "unicycler"].contains(value)) {
                    invalidValues[key] = [value, "assembler"]
                }
                break
        
            case 'path_exist':
                File dir = new File(value)
                if (!dir.exists()) {
                    invalidValues[key] = [value, "existing directory"]
                }
                break

            case 'path':
                File dir = new File(value)
                if (!(dir.exists() || dir.mkdirs())) {
                    invalidValues[key] = [value, "directory path (invalid path or insufficient permissions)"]
                }
                break
            
            case 'path_fasta':
                File fasta = new File(value)
                if (!fasta.exists()) {
                    invalidValues[key] = [value, "path to a fasta file (file does not exist)"]
                } else if (!(value ==~ /.+\.(fa|fasta)$/)) {
                    invalidValues[key] = [value, "path to a fasta file (file does not have an filename extension of .fasta or .fa)"]
                }
                break

            case 'url_git':
                if (!(value ==~ /^(https?:\/\/)?(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)\.git$/)) {
                    invalidValues[key] = [value, "URL that points a Git remote repository (valid URL ending with .git)"]
                }
                break
            
            case 'url_targz':
                if (!(value ==~ /^(https?:\/\/)?(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)\.tar\.gz$/)) {
                    invalidValues[key] = [value, "URL that points a .tar.gz file (valid URL ending with .tar.gz)"]
                }
                break

            case 'url_csv':
                if (!(value ==~ /^(https?:\/\/)?(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)\.csv$/)) {
                    invalidValues[key] = [value, "URL that points a .csv file (valid URL ending with .csv)"]
                }
                break
            
            // Should only reach this statement if a new value type is added to validParams without adding its case above
            default:
                log.error("""
                    |Unknown value type \"${valueType}\"
                    |Please submit an issue at \"https://github.com/HarryHung/gps-unified-pipeline/issues\"}
                    """.stripMargin())
                System.exit(0)
        }
    }

    // If invalidParams list or invalidValues map is not empty, log error messages and terminate the pipeline
    if (invalidParams || invalidValues){
        log.error("The pipeline will now be terminated due to the following critical error(s):")

        if (invalidParams) {
            log.error("The following invalid option(s) were provided: --${invalidParams.join(', --')}.")
        }

        if (invalidValues) {
            invalidValues.each{
                key, values ->
                log.error("The provided value \"${values[0]}\" for option --${key} is not a valid ${values[1]}.")
            }
        }

        System.exit(0)
    }
}