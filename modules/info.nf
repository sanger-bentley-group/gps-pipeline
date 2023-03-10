// Import for PARSE
import groovy.json.JsonSlurper


// Extract containers information and saved into a JSON file
process IMAGES {
    label 'bash_container'

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


process DATABASES {
    label 'bash_container'
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

// TBC - Add databases and tools version information into the JSON file generated by GET_IMAGES
process COMBINE_INFO {
    label 'bash_container'

    input:
    val pipeline_version
    val nextflow_version
    path database
    path images
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
    path("result.json"), emit: json

    shell:
    '''
    jq -s '.[0] * .[1]' !{database} !{images} > working.json

    add_version () {
        jq --arg entry $1 --arg version "$2" '.[$entry] += {"version": $version}' working.json > tmp.json && mv tmp.json working.json
    }

    add_version pipeline "!{pipeline_version}"

    add_version nextflow "!{nextflow_version}"

    add_version git "!{git_version}"
    add_version python "!{python_version}"
    add_version fastp "!{fastp_version}"
    add_version unicycler "!{unicycler_version}"
    add_version shovill "!{shovill_version}"
    add_version quast "!{quast_version}"
    add_version bwa "!{bwa_version}"
    add_version samtools "!{samtools_version}"
    add_version bcftools "!{bcftools_version}"
    add_version poppunk "!{poppunk_version}"
    add_version mlst "!{mlst_version}"
    add_version kraken2 "!{kraken2_version}"
    add_version seroba "!{seroba_version}"

    mv working.json result.json
    '''
}

// Parse information from JSON into human-readable format
process PARSE {
    input:
    val json_file

    output:
    val titleText
    val dbText
    val toolText
    val imageText

    exec:
    def jsonSlurper = new JsonSlurper()
    
    def json = jsonSlurper.parse(new File("${json_file}")) 

    titleText = """\
        |=== GPS Unified Pipeline version ===
        |${json.pipeline.version}
        |
        |=== Nextflow version ===
        |${json.nextflow.version}
        """.stripMargin()
    
    dbText = """\
        |=== Databases Information ===
        |BWA reference genome FM-index database:
        |- Reference: ${json.bwa_db.reference}
        |- Created: ${json.bwa_db.create_time}
        |Kraken 2 database:
        |- Source: ${json.kraken2_db.url}
        |- Saved: ${json.kraken2_db.save_time}
        |PopPUNK database:
        |- Source: ${json.poppunnk_db.url}
        |- Saved: ${json.poppunnk_db.save_time}
        |PopPUNK external clusters file:
        |- Source: ${json.poppunk_ext.url}
        |- Saved: ${json.poppunk_ext.save_time}
        |SeroBA database:
        |- Source: ${json.seroba_db.git}
        |- Kmer size for creating the KMC database: ${json.seroba_db.kmer} 
        |- Created: ${json.seroba_db.create_time}
        """.stripMargin()

    toolText = """\
        |=== Tool Verions ===
        |Git: ${json.git.version}
        |Python: ${json.python.version}
        |fastp: ${json.fastp.version}
        |Unicycler: ${json.unicycler.version}
        |Shovill: ${json.shovill.version}
        |QUAST: ${json.quast.version}
        |BWA: ${json.bwa.version}
        |SAMtools: ${json.samtools.version}
        |BCFtools: ${json.bcftools.version}
        |PopPUNK: ${json.poppunk.version}
        |SPN_PBP_AMR: no version information available
        |AMRSEARCH: no version information available
        |mlst: ${json.mlst.version}
        |Kraken 2: ${json.kraken2.version}
        |SeroBA: ${json.seroba.version}
        """.stripMargin()
    
    imageText = """\
        |=== Docker Images ===
        |Bash: ${json.bash.container}
        |Git: ${json.git.container}
        |Python: ${json.python.container}
        |fastp: ${json.fastp.container}
        |Unicycler: ${json.unicycler.container}
        |Shovill: ${json.shovill.container}
        |QUAST: ${json.quast.container}
        |BWA: ${json.bwa.container}
        |SAMtools: ${json.samtools.container}
        |BCFtools: ${json.bcftools.container}
        |PopPUNK: ${json.poppunk.container}
        |SPN_PBP_AMR: ${json.spn_pbp_amr.container}
        |AMRSEARCH: ${json.amrsearch.container}
        |mlst: ${json.mlst.container}
        |Kraken 2: ${json.kraken2.container}
        |SeroBA: ${json.seroba.container}
        """.stripMargin()
}

// Print version information
process PRINT {
    input:
    val titleText
    val dbText
    val toolText
    val imageText

    exec:
    log.info(
        """
        |
        |========== Version Information ==========
        |
        |${titleText}
        |${dbText}
        |${toolText}
        |${imageText}
        """.stripMargin()
    )
}

// Save version and QC parameters information to info.txt at output dir
process SAVE {
    input:
    val titleText
    val dbText
    val toolText
    val imageText

    exec:
    File output_dir = new File("${params.output}")
    output_dir.mkdirs()

    assemblerText = """\
    |=== Selected assembler ===
    |${params.assembler.capitalize()}
    """.stripMargin()

    qcText= """\
    |=== QC Parameters ===
    |= Taxonomy QC =
    |Minimum S. pneumoniae percentage in reads: ${params.spneumo_percentage}
    |= Mapping QC =
    |Minimum reference coverage percentage by the reads: ${params.ref_coverage}
    |Maximum non-cluster heterozygous SNP (Het-SNP) site count: ${params.het_snp_site}
    |= Assembly QC =
    |Maximum contig count in assembly: ${params.contigs}
    |Minimum assembly length: ${params.length_low}
    |Maximum assembly length: ${params.length_high}
    |Minimum sequencing depth: ${params.depth}
    """.stripMargin()

    File output = new File("${params.output}/info.txt")
    output.write(
        """\
        |${titleText}
        |${assemblerText}
        |${qcText}
        |${dbText}
        |${toolText}
        |${imageText}
        """.stripMargin()
    )
}


// Below processes get tool versions within Docker images by running their containers

process GIT_VERSION {
    label 'git_container'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(git -v | sed -r "s/.*\s(.+)/\\1/")
    '''
}

process PYTHON_VERSION {
    label 'python_container'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(python --version | sed -r "s/.*\s(.+)/\\1/")
    '''
}

process FASTP_VERSION {
    label 'fastp_container'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(fastp -v 2>&1 | sed -r "s/.*\s(.+)/\\1/")
    '''
}

process UNICYCLER_VERSION {
    label 'unicycler_container'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(unicycler --version | sed -r "s/.*\sv(.+)/\\1/")
    '''
}

process SHOVILL_VERSION {
    label 'shovill_container'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(shovill -v | sed -r "s/.*\s(.+)/\\1/")
    '''
}

process QUAST_VERSION {
    label 'quast_container'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(quast.py -v | sed -r "s/.*\sv(.+)/\\1/")
    '''
}

process BWA_VERSION {
    label 'bwa_container'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(bwa 2>&1 | grep Version | sed -r "s/.*:\s(.+)/\\1/")
    '''
}

process SAMTOOLS_VERSION {
    label 'samtools_container'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(samtools 2>&1 | grep Version | sed -r "s/.*:\s(.+)/\\1/")
    '''
}

process BCFTOOLS_VERSION {
    label 'bcftools_container'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(bcftools 2>&1 | grep Version | sed -r "s/.*:\s(.+)/\\1/")
    '''
}

process POPPUNK_VERSION {
    label 'poppunk_container'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(poppunk --version | sed -r "s/.*\s(.+)/\\1/")
    '''
}

process MLST_VERSION {
    label 'mlst_container'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(mlst -v | sed -r "s/.*\s(.+)/\\1/")
    '''
}

process KRAKEN2_VERSION {
    label 'kraken2_container'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(kraken2 -v | grep version | sed -r "s/.*\s(.+)/\\1/")
    '''
}

process SEROBA_VERSION {
    label 'seroba_container'

    output:
    env VERSION

    shell:
    '''
    VERSION=$(seroba version)
    '''
}

