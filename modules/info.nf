// Import for PARSE
import groovy.json.JsonSlurper

// Extract containers information and saved into a JSON file
process IMAGES {
    label 'bash_container'
    label 'farm_low'

    input:
    path nextflowConfig

    output:
    path(json), emit: json

    script:
    json='images.json'
    """
    NEXTFLOW_CONFIG="$nextflowConfig"
    JSON_FILE="$json"

    source get_images_info.sh
    """
}

// Get databases information and saved into a JSON file
process DATABASES {
    label 'bash_container'
    label 'farm_low'

    input:
    val bwa_db_path
    val kraken2_db_path
    val seroba_db_path
    val poppunk_db_path

    output:
    path(json), emit: json

    script:
    json='databases.json'
    """
    BWA_DB_PATH="$bwa_db_path"
    KRAKEN2_DB_PATH="$kraken2_db_path"
    SEROBA_DB_PATH="$seroba_db_path"
    POPPUNK_DB_PATH="$poppunk_db_path"
    JSON_FILE="$json"

    source get_databases_info.sh
    """
}

// Get tools versions and saved into a JSON file
process TOOLS {
    label 'bash_container'
    label 'farm_low'

    input:
    val git_version
    val python_version
    val fastp_version
    val unicycler_version
    val shovill_version
    val quast_version
    val bwa_version
    val samtools_version
    val bcftools_version
    val poppunk_version
    val mlst_version
    val kraken2_version
    val seroba_version

    output:
    path(json), emit: json

    script:
    json='tools.json'
    """
    GIT_VERSION="$git_version"
    PYTHON_VERSION="$python_version"
    FASTP_VERSION="$fastp_version"
    UNICYCLER_VERSION="$unicycler_version"
    SHOVILL_VERSION="$shovill_version"
    QUAST_VERSION="$quast_version"
    BWA_VERSION="$bwa_version"
    SAMTOOLS_VERSION="$samtools_version"
    BCFTOOLS_VERSION="$bcftools_version"
    POPPUNK_VERSION="$poppunk_version"
    MLST_VERSION="$mlst_version"
    KRAKEN2_VERSION="$kraken2_version"
    SEROBA_VERSION="$seroba_version"
    JSON_FILE="$json"
                
    source get_tools_info.sh
    """
}

// Combine pipeline, Nextflow, databases, container images, tools version information into the a single JSON file
process COMBINE_INFO {
    label 'bash_container'
    label 'farm_low'

    input:
    val pipeline_version
    val nextflow_version
    path database
    path images
    path tools

    output:
    path(json), emit: json

    script:
    json='result.json'
    """
    PIPELINE_VERSION="$pipeline_version"
    NEXTFLOW_VERSION="$nextflow_version"
    DATABASE="$database"
    IMAGES="$images"
    TOOLS="$tools"
    JSON_FILE="$json"

    source combine_info.sh
    """
}

// Parse information from JSON into human-readable format
process PARSE {
    label 'farm_local'

    input:
    val json_file

    output:
    val coreText
    val dbText
    val toolText
    val imageText

    exec:
    def jsonSlurper = new JsonSlurper()

    def json = jsonSlurper.parse(new File("${json_file}"))

    def textRow = { leftSpace, rightSpace, leftContent, rightContent ->
        String.format("║ %-${leftSpace}s │ %-${rightSpace}s ║", leftContent, rightContent)
    }

    def coreTextRow = { leftContent, rightContent ->
        textRow(25, 61, leftContent, rightContent)
    }

    coreText = """\
        |┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ Core Software Versions ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
        |╔═══════════════════════════╤═══════════════════════════════════════════════════════════════╗
        |${coreTextRow('Software', 'Version')}
        |╠═══════════════════════════╪═══════════════════════════════════════════════════════════════╣
        |${coreTextRow('GPS Unified Pipeline', json.pipeline.version)}
        |${coreTextRow('Nextflow', json.nextflow.version)}
        |╚═══════════════════════════╧═══════════════════════════════════════════════════════════════╝
        |""".stripMargin()

    def dbTextRow = { leftContent, rightContent ->
        textRow(9, 77, leftContent, rightContent)
    }

    dbText = """\
        |┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ Databases Information ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
        |╔═══════════════════════════════════════════════════════════════════════════════════════════╗
        |║ BWA reference genome FM-index database                                                    ║
        |╟───────────┬───────────────────────────────────────────────────────────────────────────────╢
        |${dbTextRow('Reference', json.bwa_db.reference)}
        |${dbTextRow('Created', json.bwa_db.create_time)}
        |╠═══════════╧═══════════════════════════════════════════════════════════════════════════════╣
        |║ Kraken 2 database                                                                         ║
        |╟───────────┬───────────────────────────────────────────────────────────────────────────────╢
        |${dbTextRow('Source', json.kraken2_db.url)}
        |${dbTextRow('Saved', json.kraken2_db.save_time)}
        |╠═══════════╧═══════════════════════════════════════════════════════════════════════════════╣
        |║ PopPUNK database                                                                          ║
        |╟───────────┬───────────────────────────────────────────────────────────────────────────────╢
        |${dbTextRow('Source', json.poppunnk_db.url)}
        |${dbTextRow('Saved', json.poppunnk_db.save_time)}
        |╠═══════════╧═══════════════════════════════════════════════════════════════════════════════╣
        |║ PopPUNK external clusters file                                                            ║
        |╟───────────┬───────────────────────────────────────────────────────────────────────────────╢
        |${dbTextRow('Source', json.poppunk_ext.url)}
        |${dbTextRow('Saved', json.poppunk_ext.save_time)}
        |╠═══════════╧═══════════════════════════════════════════════════════════════════════════════╣
        |║ SeroBA database                                                                           ║
        |╟───────────┬───────────────────────────────────────────────────────────────────────────────╢
        |${dbTextRow('Source', json.seroba_db.git)}
        |${dbTextRow('Kmer size', json.seroba_db.kmer)}
        |${dbTextRow('Created', json.seroba_db.create_time)}
        |╚═══════════╧═══════════════════════════════════════════════════════════════════════════════╝
        |""".stripMargin()

    def getVersion = { tool ->
        if (json[tool] && json[tool]['version']) {
            return json[tool]['version']
        }

        return 'no version information'
    }

    def toolTextRow = { leftContent, rightContent ->
        textRow(30, 56, leftContent, getVersion(rightContent))
    }

    toolText = """\
        |┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ Tool Versions ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
        |╔════════════════════════════════╤══════════════════════════════════════════════════════════╗
        |${textRow(30, 56, 'Tool', 'Version')}
        |╠════════════════════════════════╪══════════════════════════════════════════════════════════╣
        |${toolTextRow('Git', 'git')}
        |${toolTextRow('Python', 'python')}
        |${toolTextRow('fastp', 'fastp')}
        |${toolTextRow('Unicycler', 'unicycler')}
        |${toolTextRow('Shovill', 'shovill')}
        |${toolTextRow('QUAST', 'quast')}
        |${toolTextRow('BWA', 'bwa')}
        |${toolTextRow('SAMtools', 'samtools')}
        |${toolTextRow('BCFtools', 'bcftools')}
        |${toolTextRow('Het-SNP Counter', 'het_snp_count')}
        |${toolTextRow('PopPUNK', 'poppunk')}
        |${toolTextRow('CDC PBP AMR Predictor', 'spn_pbp_amr')}
        |${toolTextRow('AMRsearch', 'amrsearch')}
        |${toolTextRow('mlst', 'mlst')}
        |${toolTextRow('Kraken 2', 'kraken2')}
        |${toolTextRow('SeroBA', 'seroba')}
        |╚════════════════════════════════╧══════════════════════════════════════════════════════════╝
        |""".stripMargin()

    def getImage = { tool ->
        if (json[tool] && json[tool]['container']) {
            return json[tool]['container']
        }

        return 'no image information'
    }

    def imageTextRow = { leftContent, rightContent ->
        textRow(30, 56, leftContent, getImage(rightContent))
    }

    imageText = """\
        |┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ Container Images ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
        |╔════════════════════════════════╤══════════════════════════════════════════════════════════╗
        |${textRow(30, 56, 'Environment For', 'Image')}
        |╠════════════════════════════════╪══════════════════════════════════════════════════════════╣
        |${imageTextRow('Bash', 'bash')}
        |${imageTextRow('Git', 'git')}
        |${imageTextRow('Python', 'python')}
        |${imageTextRow('fastp', 'fastp')}
        |${imageTextRow('Unicycler', 'unicycler')}
        |${imageTextRow('Shovill', 'shovill')}
        |${imageTextRow('QUAST', 'quast')}
        |${imageTextRow('BWA', 'bwa')}
        |${imageTextRow('SAMtools', 'samtools')}
        |${imageTextRow('BCFtools', 'bcftools')}
        |${imageTextRow('PopPUNK', 'poppunk')}
        |${imageTextRow('CDC PBP AMR Predictor', 'spn_pbp_amr')}
        |${imageTextRow('AMRsearch', 'amrsearch')}
        |${imageTextRow('mlst', 'mlst')}
        |${imageTextRow('Kraken 2', 'kraken2')}
        |${imageTextRow('SeroBA', 'seroba')}
        |╚════════════════════════════════╧══════════════════════════════════════════════════════════╝
        |""".stripMargin()
}

// Print version information
process PRINT {
    label 'farm_local'

    input:
    val coreText
    val dbText
    val toolText
    val imageText

    exec:
    log.info(
        """
        |╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍
        |╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍ Version Information ╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍
        |╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍
        |
        |${coreText}
        |${dbText}
        |${toolText}
        |${imageText}
        |""".stripMargin()
    )
}

// Save version and QC parameters information to info.txt at output dir
process SAVE {
    label 'farm_local'
    
    input:
    val coreText
    val dbText
    val toolText
    val imageText

    exec:
    File readsDir = new File(params.reads)
    File outputDir = new File(params.output)
    outputDir.mkdirs()

    def textRow = { leftSpace, rightSpace, leftContent, rightContent ->
        String.format("║ %-${leftSpace}s │ %-${rightSpace}s ║", leftContent, rightContent)
    }

    def ioTextRow = { leftContent, rightContent ->
        textRow(8, 78, leftContent, rightContent)
    }

    String ioText = """\
    |┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ Input and Output ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
    |╔══════════╤════════════════════════════════════════════════════════════════════════════════╗
    |${ioTextRow('Type', 'Path')}
    |╠══════════╪════════════════════════════════════════════════════════════════════════════════╣
    |${ioTextRow('Input', readsDir.absolutePath)}
    |${ioTextRow('Output', outputDir.absolutePath)}
    |╚══════════╧════════════════════════════════════════════════════════════════════════════════╝
    |""".stripMargin()

    def moduleTextRow = { leftContent, rightContent ->
        textRow(15, 71, leftContent, rightContent)
    }

    String moduleText = """\
    |┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ Module Selection ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
    |╔═════════════════╤═════════════════════════════════════════════════════════════════════════╗
    |${moduleTextRow('Module', 'Selection')}
    |╠═════════════════╪═════════════════════════════════════════════════════════════════════════╣
    |${moduleTextRow('Assembler', params.assembler.capitalize())}
    |╚═════════════════╧═════════════════════════════════════════════════════════════════════════╝
    |""".stripMargin()

    def qcTextRow = { leftContent, rightContent ->
        textRow(60, 26, leftContent, rightContent)
    }

    String qcText = """\
    |┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ QC Parameters ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
    |╔═══════════════════════════════════════════════════════════════════════════════════════════╗
    |║ Taxonomy QC                                                                               ║
    |╟──────────────────────────────────────────────────────────────┬────────────────────────────╢
    |${qcTextRow('Minimum S. pneumoniae percentage in reads', params.spneumo_percentage)}
    |╠══════════════════════════════════════════════════════════════╧════════════════════════════╣
    |║ Mapping QC                                                                                ║
    |╟──────────────────────────────────────────────────────────────┬────────────────────────────╢
    |${qcTextRow('Minimum reference coverage percentage by the reads', params.ref_coverage)}
    |${qcTextRow('Maximum non-cluster heterozygous SNP (Het-SNP) site count', params.het_snp_site)}
    |╠══════════════════════════════════════════════════════════════╧════════════════════════════╣
    |║ Assembly QC                                                                               ║
    |╟──────────────────────────────────────────────────────────────┬────────────────────────────╢
    |${qcTextRow('Maximum contig count in assembly', params.contigs)}
    |${qcTextRow('Minimum assembly length', params.length_low)}
    |${qcTextRow('Maximum assembly length', params.length_high)}
    |${qcTextRow('Minimum sequencing depth', params.depth)}
    |╚══════════════════════════════════════════════════════════════╧════════════════════════════╝
    |""".stripMargin()

    File output = new File("${params.output}/info.txt")
    output.write(
        """\
        |${coreText}
        |${ioText}
        |${moduleText}
        |${qcText}
        |${dbText}
        |${toolText}
        |${imageText}
        |""".stripMargin()
    )
}

// Below processes get tool versions within container images by running their containers

process GIT_VERSION {
    label 'git_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    $/
    VERSION=$(git -v | sed -r "s/.*\s(.+)/\1/")
    /$
}

process PYTHON_VERSION {
    label 'python_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    $/
    VERSION=$(python --version | sed -r "s/.*\s(.+)/\1/")
    /$
}

process FASTP_VERSION {
    label 'fastp_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    $/
    VERSION=$(fastp -v 2>&1 | sed -r "s/.*\s(.+)/\1/")
    /$
}

process UNICYCLER_VERSION {
    label 'unicycler_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    $/
    VERSION=$(unicycler --version | sed -r "s/.*\sv(.+)/\1/")
    /$
}

process SHOVILL_VERSION {
    label 'shovill_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    $/
    VERSION=$(shovill -v | sed -r "s/.*\s(.+)/\1/")
    /$
}

process QUAST_VERSION {
    label 'quast_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    $/
    VERSION=$(quast.py -v | sed -r "s/.*\sv(.+)/\1/")
    /$
}

process BWA_VERSION {
    label 'bwa_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    $/
    VERSION=$(bwa 2>&1 | grep Version | sed -r "s/.*:\s(.+)/\1/")
    /$
}

process SAMTOOLS_VERSION {
    label 'samtools_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    $/
    VERSION=$(samtools 2>&1 | grep Version | sed -r "s/.*:\s(.+)\s\(.+/\1/")
    /$
}

process BCFTOOLS_VERSION {
    label 'bcftools_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    $/
    VERSION=$(bcftools 2>&1 | grep Version | sed -r "s/.*:\s(.+)\s\(.+/\1/")
    /$
}

process POPPUNK_VERSION {
    label 'poppunk_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    $/
    VERSION=$(poppunk --version | sed -r "s/.*\s(.+)/\1/")
    /$
}

process MLST_VERSION {
    label 'mlst_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    $/
    VERSION=$(mlst -v | sed -r "s/.*\s(.+)/\1/")
    /$
}

process KRAKEN2_VERSION {
    label 'kraken2_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    $/
    VERSION=$(kraken2 -v | grep version | sed -r "s/.*\s(.+)/\1/")
    /$
}

process SEROBA_VERSION {
    label 'seroba_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    $/
    VERSION=$(seroba version)
    /$
}
