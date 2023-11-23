// Import for PARSE process
import groovy.json.JsonSlurper

// Extract containers information from nextflow.config and save into a JSON file
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

    source save_images_info.sh
    """
}

// Save received databases information into a JSON file
process DATABASES {
    label 'bash_container'
    label 'farm_low'

    input:
    path bwa_db_path
    path ariba_db_path
    path kraken2_db_path
    path seroba_db_path
    path poppunk_db_path
    path poppunk_ext_path
    path resistance_to_mic

    output:
    path(json), emit: json

    script:
    json='databases.json'
    bwa_json='done_bwa_db.json'
    ariba_json='done_ariba_db.json'
    seroba_json='done_seroba.json'
    kraken2_json='done_kraken.json'
    poppunk_json='done_poppunk.json'
    poppunk_ext_json='done_poppunk_ext.json'
    """
    BWA_DB_PATH="$bwa_db_path"
    BWA_JSON="$bwa_json"
    ARIBA_DB_PATH="$ariba_db_path"
    ARIBA_JSON="$ariba_json"
    KRAKEN2_DB_PATH="$kraken2_db_path"
    KRAKEN2_JSON="$kraken2_json"
    SEROBA_DB_PATH="$seroba_db_path"
    SEROBA_JSON="$seroba_json"
    POPPUNK_DB_PATH="$poppunk_db_path"
    POPPUNK_JSON="$poppunk_json"
    POPPUNK_EXT_PATH="$poppunk_ext_path"
    POPPUNK_EXT_JSON="$poppunk_ext_json"
    RESISTANCE_TO_MIC="$resistance_to_mic"
    JSON_FILE="$json"

    source save_databases_info.sh
    """
}

// Save received tools versions into a JSON file
process TOOLS {
    label 'bash_container'
    label 'farm_low'

    input:
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
    val ariba_version

    output:
    path(json), emit: json

    script:
    json='tools.json'
    """
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
    ARIBA_VERSION="$ariba_version"
    JSON_FILE="$json"
                
    source save_tools_info.sh
    """
}

// Combine pipeline version, Nextflow version, databases information, container images, tools version JSON files into the a single JSON file
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

    source save_combined_info.sh
    """
}

// Parse information from JSON into human-readable tables
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
        textRow(25, 67, leftContent, rightContent)
    }

    coreText = """\
        |┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ Core Software Versions ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
        |╔═══════════════════════════╤═════════════════════════════════════════════════════════════════════╗
        |${coreTextRow('Software', 'Version')}
        |╠═══════════════════════════╪═════════════════════════════════════════════════════════════════════╣
        |${coreTextRow('GPS Unified Pipeline', json.pipeline.version)}
        |${coreTextRow('Nextflow', json.nextflow.version)}
        |╚═══════════════════════════╧═════════════════════════════════════════════════════════════════════╝
        |""".stripMargin()

    def dbTextRow = { leftContent, rightContent ->
        textRow(13, 79, leftContent, rightContent)
    }

    dbText = """\
        |┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ Databases Information ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
        |╔═════════════════════════════════════════════════════════════════════════════════════════════════╗
        |║ BWA reference genome FM-index database                                                          ║
        |╟───────────────┬─────────────────────────────────────────────────────────────────────────────────╢
        |${dbTextRow('Reference', json.bwa_db.reference)}
        |${dbTextRow('Reference MD5', json.bwa_db.reference_md5)}
        |${dbTextRow('Created', json.bwa_db.create_time)}
        |╠═══════════════╧═════════════════════════════════════════════════════════════════════════════════╣
        |║ Kraken 2 database                                                                               ║
        |╟───────────────┬─────────────────────────────────────────────────────────────────────────────────╢
        |${dbTextRow('Source', json.kraken2_db.url)}
        |${dbTextRow('Saved', json.kraken2_db.save_time)}
        |╠═══════════════╧═════════════════════════════════════════════════════════════════════════════════╣
        |║ PopPUNK database                                                                                ║
        |╟───────────────┬─────────────────────────────────────────────────────────────────────────────────╢
        |${dbTextRow('Source', json.poppunnk_db.url)}
        |${dbTextRow('Saved', json.poppunnk_db.save_time)}
        |╠═══════════════╧═════════════════════════════════════════════════════════════════════════════════╣
        |║ PopPUNK external clusters file                                                                  ║
        |╟───────────────┬─────────────────────────────────────────────────────────────────────────────────╢
        |${dbTextRow('Source', json.poppunk_ext.url)}
        |${dbTextRow('Saved', json.poppunk_ext.save_time)}
        |╠═══════════════╧═════════════════════════════════════════════════════════════════════════════════╣
        |║ SeroBA database                                                                                 ║
        |╟───────────────┬─────────────────────────────────────────────────────────────────────────────────╢
        |${dbTextRow('Source', json.seroba_db.url)}
        |${dbTextRow('Kmer size', json.seroba_db.kmer)}
        |${dbTextRow('Created', json.seroba_db.create_time)}
        |╠═══════════════╧═════════════════════════════════════════════════════════════════════════════════╣
        |║ ARIBA database                                                                                  ║
        |╟───────────────┬─────────────────────────────────────────────────────────────────────────────────╢
        |${dbTextRow('Reference', json.ariba_db.reference)}
        |${dbTextRow('Reference MD5', json.ariba_db.reference_md5)}
        |${dbTextRow('Metadata', json.ariba_db.metadata)}
        |${dbTextRow('Metadata MD5', json.ariba_db.metadata_md5)}
        |${dbTextRow('Created', json.ariba_db.create_time)}
        |╠═══════════════╧═════════════════════════════════════════════════════════════════════════════════╣
        |║ Resistance phenotypes to MIC (minimum inhibitory concentration) lookup table                    ║
        |╟───────────────┬─────────────────────────────────────────────────────────────────────────────────╢
        |${dbTextRow('Table', json.resistance_to_mic.table)}
        |${dbTextRow('Table MD5', json.resistance_to_mic.table_md5)}
        |╚═══════════════╧═════════════════════════════════════════════════════════════════════════════════╝
        |""".stripMargin()

    def getVersion = { tool ->
        if (json[tool] && json[tool]['version']) {
            return json[tool]['version']
        }

        return 'no version information'
    }

    def toolTextRow = { leftContent, rightContent ->
        textRow(30, 62, leftContent, getVersion(rightContent))
    }

    toolText = """\
        |┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ Tool Versions ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
        |╔════════════════════════════════╤════════════════════════════════════════════════════════════════╗
        |${textRow(30, 62, 'Tool', 'Version')}
        |╠════════════════════════════════╪════════════════════════════════════════════════════════════════╣
        |${toolTextRow('Python', 'python')}
        |${toolTextRow('fastp', 'fastp')}
        |${toolTextRow('Unicycler', 'unicycler')}
        |${toolTextRow('Shovill', 'shovill')}
        |${toolTextRow('QUAST', 'quast')}
        |${toolTextRow('BWA', 'bwa')}
        |${toolTextRow('SAMtools', 'samtools')}
        |${toolTextRow('BCFtools', 'bcftools')}
        |${toolTextRow('PopPUNK', 'poppunk')}
        |${toolTextRow('CDC PBP AMR Predictor', 'spn_pbp_amr')}
        |${toolTextRow('ARIBA', 'ariba')}
        |${toolTextRow('mlst', 'mlst')}
        |${toolTextRow('Kraken 2', 'kraken2')}
        |${toolTextRow('SeroBA', 'seroba')}
        |╚════════════════════════════════╧════════════════════════════════════════════════════════════════╝
        |""".stripMargin()

    def getImage = { tool ->
        if (json[tool] && json[tool]['container']) {
            return json[tool]['container']
        }

        return 'no image information'
    }

    def imageTextRow = { leftContent, rightContent ->
        textRow(30, 62, leftContent, getImage(rightContent))
    }

    imageText = """\
        |┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ Container Images ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
        |╔════════════════════════════════╤════════════════════════════════════════════════════════════════╗
        |${textRow(30, 62, 'Environment For', 'Image')}
        |╠════════════════════════════════╪════════════════════════════════════════════════════════════════╣
        |${imageTextRow('Bash', 'bash')}
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
        |${imageTextRow('ARIBA', 'ariba')}
        |${imageTextRow('mlst', 'mlst')}
        |${imageTextRow('Kraken 2', 'kraken2')}
        |${imageTextRow('SeroBA', 'seroba')}
        |╚════════════════════════════════╧════════════════════════════════════════════════════════════════╝
        |""".stripMargin()
}

// Print parsed version information
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
        |╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍
        |╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍ Version Information ╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍
        |╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍╍
        |
        |${coreText}
        |${dbText}
        |${toolText}
        |${imageText}
        |""".stripMargin()
    )
}

// Save core software, I/O, assembler, QC parameters, databases, tools, container engine and images information to info.txt at output dir
process SAVE {
    label 'farm_local'
    
    publishDir "${params.output}", mode: "copy"

    input:
    val coreText
    val dbText
    val toolText
    val imageText

    output:
    path "info.txt", emit: info

    exec:
    File readsDir = new File(params.reads)
    File outputDir = new File(params.output)

    def textRow = { leftSpace, rightSpace, leftContent, rightContent ->
        String.format("║ %-${leftSpace}s │ %-${rightSpace}s ║", leftContent, rightContent)
    }

    def ioTextRow = { leftContent, rightContent ->
        textRow(8, 84, leftContent, rightContent)
    }

    String ioText = """\
    |┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ Input and Output ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
    |╔══════════╤══════════════════════════════════════════════════════════════════════════════════════╗
    |${ioTextRow('Type', 'Path')}
    |╠══════════╪══════════════════════════════════════════════════════════════════════════════════════╣
    |${ioTextRow('Input', readsDir.canonicalPath)}
    |${ioTextRow('Output', outputDir.canonicalPath)}
    |╚══════════╧══════════════════════════════════════════════════════════════════════════════════════╝
    |""".stripMargin()

    def assemblerTextRow = { leftContent, rightContent ->
        textRow(25, 67, leftContent, rightContent)
    }

    String assemblerText = """\
    |┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ Assembler Options ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
    |╔═══════════════════════════╤═════════════════════════════════════════════════════════════════════╗
    |${assemblerTextRow('Option', 'Value')}
    |╠═══════════════════════════╪═════════════════════════════════════════════════════════════════════╣
    |${assemblerTextRow('Assembler', params.assembler.capitalize())}
    |${assemblerTextRow('Minimum contig length', params.min_contig_length)}
    |╚═══════════════════════════╧═════════════════════════════════════════════════════════════════════╝
    |""".stripMargin()

    def qcTextRow = { leftContent, rightContent ->
        textRow(60, 32, leftContent, rightContent)
    }

    String qcText = """\
    |┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ QC Parameters ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
    |╔═════════════════════════════════════════════════════════════════════════════════════════════════╗
    |║ Read QC                                                                                         ║
    |╟──────────────────────────────────────────────────────────────┬──────────────────────────────────╢
    |${qcTextRow('Minimum bases in processed reads', String.format("%.0f", Math.ceil(params.length_low * params.depth)))}
    |╠══════════════════════════════════════════════════════════════╧══════════════════════════════════╣
    |║ Taxonomy QC                                                                                     ║
    |╟──────────────────────────────────────────────────────────────┬──────────────────────────────────╢
    |${qcTextRow('Minimum S. pneumoniae percentage in reads', params.spneumo_percentage)}
    |${qcTextRow('Maximum non-Streptococcus genus percentage in reads', params.non_strep_percentage)}
    |╠══════════════════════════════════════════════════════════════╧══════════════════════════════════╣
    |║ Mapping QC                                                                                      ║
    |╟──────────────────────────────────────────────────────────────┬──────────────────────────────────╢
    |${qcTextRow('Minimum reference coverage percentage by the reads', params.ref_coverage)}
    |${qcTextRow('Maximum non-cluster heterozygous SNP (Het-SNP) site count', params.het_snp_site)}
    |╠══════════════════════════════════════════════════════════════╧══════════════════════════════════╣
    |║ Assembly QC                                                                                     ║
    |╟──────────────────────────────────────────────────────────────┬──────────────────────────────────╢
    |${qcTextRow('Maximum contig count in assembly', params.contigs)}
    |${qcTextRow('Minimum assembly length', params.length_low)}
    |${qcTextRow('Maximum assembly length', params.length_high)}
    |${qcTextRow('Minimum sequencing depth', params.depth)}
    |╚══════════════════════════════════════════════════════════════╧══════════════════════════════════╝
    |""".stripMargin()

    def containerEngineTextRow = { leftContent, rightContent ->
        textRow(25, 67, leftContent, rightContent)
    }

    String containerEngineText = """\
    |┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ Container Engine Options ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
    |╔═══════════════════════════╤═════════════════════════════════════════════════════════════════════╗
    |${containerEngineTextRow('Option', 'Value')}
    |╠═══════════════════════════╪═════════════════════════════════════════════════════════════════════╣
    |${containerEngineTextRow('Container Engine', workflow.containerEngine.capitalize())}
    |╚═══════════════════════════╧═════════════════════════════════════════════════════════════════════╝
    |""".stripMargin()

    File output = new File("${task.workDir}/info.txt")
    output.write(
        """\
        |${coreText}
        |${ioText}
        |${assemblerText}
        |${qcText}
        |${dbText}
        |${toolText}
        |${containerEngineText}
        |${imageText}
        |""".stripMargin()
    )
}

// Below processes get tool versions within container images by running their containers

process PYTHON_VERSION {
    label 'python_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    $/
    VERSION=$(python3 --version | sed -r "s/.*\s(.+)/\1/")
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

process ARIBA_VERSION {
    label 'ariba_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    $/
    VERSION=$(ariba version | grep ARIBA | sed -r "s/.*:\s(.+)/\1/")
    /$
}
