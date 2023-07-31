// Import process modules
include { GET_REF_GENOME_BWA_DB } from "$projectDir/modules/mapping"
include { GET_KRAKEN2_DB } from "$projectDir/modules/taxonomy"
include { GET_POPPUNK_DB; GET_POPPUNK_EXT_CLUSTERS } from "$projectDir/modules/lineage"
include { CHECK_SEROBA_DB; GET_SEROBA_DB } from "$projectDir/modules/serotype"
include { GET_DOCKER_COMPOSE; PULL_IMAGES } from "$projectDir/modules/docker"
include { GET_ARIBA_DB } from "$projectDir/modules/amr"

// Alternative workflow for initialisation only
workflow INIT {
    // Check Reference Genome BWA Database, generate from assembly if necessary
    GET_REF_GENOME_BWA_DB(params.ref_genome, params.ref_genome_bwa_db_local)

    // Check ARIBA database, generate from reference sequences and metadata if ncessary
    GET_ARIBA_DB(params.ariba_ref, params.ariba_metadata, params.ariba_db_local)

    // Check Kraken2 Database, download if necessary
    GET_KRAKEN2_DB(params.kraken2_db_remote, params.kraken2_db_local)

    // Check SeroBA Databases, clone and rebuild if necessary
    CHECK_SEROBA_DB(params.seroba_remote, params.seroba_local, params.seroba_kmer)
    GET_SEROBA_DB(params.seroba_remote, params.seroba_local, CHECK_SEROBA_DB.out.create_db, params.seroba_kmer)

    // Check to PopPUNK Database and External Clusters, download if necessary
    GET_POPPUNK_DB(params.poppunk_db_remote, params.poppunk_local)
    GET_POPPUNK_EXT_CLUSTERS(params.poppunk_ext_remote, params.poppunk_local)

    // Pull all Docker images mentioned in nextflow.config if using Docker
    if (workflow.containerEngine === 'docker') {
        GET_DOCKER_COMPOSE(Channel.fromPath("${workflow.configFiles[0]}"))
        PULL_IMAGES(GET_DOCKER_COMPOSE.out.compose)
    }
}
