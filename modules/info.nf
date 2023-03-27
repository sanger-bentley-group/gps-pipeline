// Import for PARSE
import groovy.json.JsonSlurper

// Extract containers information and saved into a JSON file
process IMAGES {
    label 'bash_container'
    label 'farm_low'

    input:
    path nextflowConfig

    output:
    path("images.json"), emit: json

    shell:
    '''
    IMAGES=$(grep -E "container\s?=" !{nextflowConfig} \
                | sort -u \
                | sed -r "s/\s+container\s?=\s?'(.+)'/\\1/")

    BASH=$(grep network-multitool <<< $IMAGES)
    GIT=$(grep git <<< $IMAGES)
    PYTHON=$(grep python <<< $IMAGES)
    FASTP=$(grep fastp <<< $IMAGES)
    UNICYCLER=$(grep unicycler <<< $IMAGES)
    SHOVILL=$(grep shovill <<< $IMAGES)
    QUAST=$(grep quast <<< $IMAGES)
    BWA=$(grep bwa <<< $IMAGES)
    SAMTOOLS=$(grep samtools <<< $IMAGES)
    BCFTOOLS=$(grep bcftools <<< $IMAGES)
    POPPUNK=$(grep poppunk <<< $IMAGES)
    SPN_PBP_AMR=$(grep spn-pbp-amr <<< $IMAGES)
    AMRSEARCH=$(grep amrsearch <<< $IMAGES)
    MLST=$(grep mlst <<< $IMAGES)
    KRAKEN2=$(grep kraken2 <<< $IMAGES)
    SEROBA=$(grep seroba <<< $IMAGES)

    add_container () {
        jq -n --arg container $1 '.container = $container'
    }

    jq -n \
        --argjson bash "$(add_container $BASH)" \
        --argjson git "$(add_container $GIT)" \
        --argjson python "$(add_container $PYTHON)" \
        --argjson fastp "$(add_container $FASTP)" \
        --argjson unicycler "$(add_container $UNICYCLER)" \
        --argjson shovill "$(add_container $SHOVILL)" \
        --argjson quast "$(add_container $QUAST)" \
        --argjson bwa "$(add_container $BWA)" \
        --argjson samtools "$(add_container $SAMTOOLS)" \
        --argjson bcftools "$(add_container $BCFTOOLS)" \
        --argjson poppunk "$(add_container $POPPUNK)" \
        --argjson spn_pbp_amr "$(add_container $SPN_PBP_AMR)" \
        --argjson amrsearch "$(add_container $AMRSEARCH)" \
        --argjson mlst "$(add_container $MLST)" \
        --argjson kraken2 "$(add_container $KRAKEN2)" \
        --argjson seroba "$(add_container $SEROBA)" \
        '$ARGS.named' > images.json
    '''
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
    path("databases.json"), emit: json

    shell:
    '''
    add_bwa_db () {
        BWA_DB_JSON=!{bwa_db_path}/done_bwa_db.json
        if [ -f "$BWA_DB_JSON" ]; then
            REFERENCE=$(jq -r .reference $BWA_DB_JSON)
            CREATE_TIME=$(jq -r .create_time $BWA_DB_JSON)
        else
            REFERENCE="Not yet created"
            CREATE_TIME="Not yet created"
        fi
        jq -n --arg ref "$REFERENCE" --arg create_time "$CREATE_TIME" '. = {"reference": $ref, "create_time": $create_time}'
    }

    add_seroba_db () {
        SEROBA_DB_JSON=!{seroba_db_path}/done_seroba.json
        if [ -f "$SEROBA_DB_JSON" ]; then
            GIT=$(jq -r .git $SEROBA_DB_JSON)
            KMER=$(jq -r .kmer $SEROBA_DB_JSON)
            CREATE_TIME=$(jq -r .create_time $SEROBA_DB_JSON)
        else
            GIT="Not yet created"
            KMER="Not yet created"
            CREATE_TIME="Not yet created"
        fi
        jq -n --arg git "$GIT" --arg kmer "$KMER" --arg create_time "$CREATE_TIME" '. = {"git": $git, "kmer": $kmer, "create_time": $create_time}'
    }

    add_url_db () {
        DB_JSON=$1
        if [ -f "$DB_JSON" ]; then
            URL=$(jq -r .url $DB_JSON)
            SAVE_TIME=$(jq -r .save_time $DB_JSON)
        else
            URL="Not yet downloaded"
            SAVE_TIME="Not yet downloaded"
        fi
        jq -n --arg url "$URL" --arg save_time "$SAVE_TIME" '. = {"url": $url, "save_time": $save_time}'
    }

    jq -n \
        --argjson bwa_db "$(add_bwa_db)" \
        --argjson seroba_db "$(add_seroba_db)" \
        --argjson kraken2_db "$(add_url_db "!{kraken2_db_path}/done_kraken.json")" \
        --argjson poppunnk_db "$(add_url_db "!{poppunk_db_path}/done_poppunk.json")" \
        --argjson poppunk_ext "$(add_url_db "!{poppunk_db_path}/done_poppunk_ext.json")" \
        '$ARGS.named' > databases.json
    '''
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
    path("tools.json"), emit: json

    shell:
    '''
    add_version () {
        jq -n --arg version $1 '.version = $version'
    }

    jq -n \
        --argjson git "$(add_version '!{git_version}')" \
        --argjson python "$(add_version '!{python_version}')" \
        --argjson fastp "$(add_version '!{fastp_version}')" \
        --argjson unicycler "$(add_version '!{unicycler_version}')" \
        --argjson shovill "$(add_version '!{shovill_version}')" \
        --argjson quast "$(add_version '!{quast_version}')" \
        --argjson bwa "$(add_version '!{bwa_version}')" \
        --argjson samtools "$(add_version '!{samtools_version}')" \
        --argjson bcftools "$(add_version '!{bcftools_version}')" \
        --argjson poppunk "$(add_version '!{poppunk_version}')" \
        --argjson mlst "$(add_version '!{mlst_version}')" \
        --argjson kraken2 "$(add_version '!{kraken2_version}')" \
        --argjson seroba "$(add_version '!{seroba_version}')" \
        '$ARGS.named' > tools.json
    '''
}

// Combine pipeline, Nextflow, databases, Docker images, tools version information into the a single JSON file
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
    path("result.json"), emit: json

    shell:
    '''
    jq -s '.[0] * .[1] * .[2]' !{database} !{images} !{tools} > working.json

    add_version () {
        jq --arg entry $1 --arg version "$2" '.[$entry] += {"version": $version}' working.json > tmp.json && mv tmp.json working.json
    }

    add_version pipeline "!{pipeline_version}"
    add_version nextflow "!{nextflow_version}"

    mv working.json result.json
    '''
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
        |┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈ Docker Images ┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
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

// Below processes get tool versions within Docker images by running their containers

process GIT_VERSION {
    label 'git_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(git -v | sed -r "s/.*\s(.+)/\\1/")
    '''
}

process PYTHON_VERSION {
    label 'python_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(python --version | sed -r "s/.*\s(.+)/\\1/")
    '''
}

process FASTP_VERSION {
    label 'fastp_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(fastp -v 2>&1 | sed -r "s/.*\s(.+)/\\1/")
    '''
}

process UNICYCLER_VERSION {
    label 'unicycler_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(unicycler --version | sed -r "s/.*\sv(.+)/\\1/")
    '''
}

process SHOVILL_VERSION {
    label 'shovill_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(shovill -v | sed -r "s/.*\s(.+)/\\1/")
    '''
}

process QUAST_VERSION {
    label 'quast_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(quast.py -v | sed -r "s/.*\sv(.+)/\\1/")
    '''
}

process BWA_VERSION {
    label 'bwa_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(bwa 2>&1 | grep Version | sed -r "s/.*:\s(.+)/\\1/")
    '''
}

process SAMTOOLS_VERSION {
    label 'samtools_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(samtools 2>&1 | grep Version | sed -r "s/.*:\s(.+)\s\\(.+/\\1/")
    '''
}

process BCFTOOLS_VERSION {
    label 'bcftools_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(bcftools 2>&1 | grep Version | sed -r "s/.*:\s(.+)\s\\(.+/\\1/")
    '''
}

process POPPUNK_VERSION {
    label 'poppunk_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(poppunk --version | sed -r "s/.*\s(.+)/\\1/")
    '''
}

process MLST_VERSION {
    label 'mlst_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(mlst -v | sed -r "s/.*\s(.+)/\\1/")
    '''
}

process KRAKEN2_VERSION {
    label 'kraken2_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(kraken2 -v | grep version | sed -r "s/.*\s(.+)/\\1/")
    '''
}

process SEROBA_VERSION {
    label 'seroba_container'
    label 'farm_low'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(seroba version)
    '''
}
