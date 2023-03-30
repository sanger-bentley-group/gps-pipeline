// Return a docker compose file that includes all images used in nextflow.config
process GET_DOCKER_COMPOSE {
    label 'bash_container'
    label 'farm_low'

    input:
    path nextflowConfig

    output:
    path compose, emit: compose

    shell:
    compose='docker-compose.yml'
    '''
    get_docker_compose.sh !{nextflowConfig} !{compose}
    '''
}

// Pull all images in the genetared docker compose file
process PULL_IMAGES {
    input:
    path compose

    shell:
    '''
    docker-compose --file !{compose} pull
    '''
}
