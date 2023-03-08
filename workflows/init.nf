// Import process modules
include { GET_REF_GENOME_BWA_DB_PREFIX } from "$projectDir/modules/mapping"
include { GET_KRAKEN_DB } from "$projectDir/modules/taxonomy"
include { GET_POPPUNK_DB; GET_POPPUNK_EXT_CLUSTERS } from "$projectDir/modules/lineage"
include { GET_SEROBA_DB; CREATE_SEROBA_DB } from "$projectDir/modules/serotype"
include { GET_DOCKER_COMPOSE; PULL_IMAGES } from "$projectDir/modules/docker"


// Alternative workflow for initialisation only
workflow INIT {
    // Check Reference Genome BWA Database, generate from assembly if necessary
    GET_REF_GENOME_BWA_DB_PREFIX(params.ref_genome, params.ref_genome_bwa_db_local)

    // Check Kraken2 Database, download if necessary
    kraken2_db = GET_KRAKEN_DB(params.kraken2_db_remote, params.kraken2_db_local)

    // Check SeroBA Databases, clone and rebuild if necessary
    GET_SEROBA_DB(params.seroba_remote, params.seroba_local, params.seroba_kmer)
    CREATE_SEROBA_DB(params.seroba_remote, params.seroba_local, GET_SEROBA_DB.out.create_db, params.seroba_kmer)

    // Check to PopPUNK Database and External Clusters, download if necessary
    GET_POPPUNK_DB(params.poppunk_db_remote, params.poppunk_local)
    GET_POPPUNK_EXT_CLUSTERS(params.poppunk_ext_remote, params.poppunk_local)

    // Pull all Docker images mentioned in nextflow.config
    GET_DOCKER_COMPOSE(Channel.fromPath( "${workflow.configFiles[0]}" ))
    PULL_IMAGES(GET_DOCKER_COMPOSE.out.compose)
}