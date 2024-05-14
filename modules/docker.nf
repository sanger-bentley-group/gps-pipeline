// Return a docker compose file that includes all images used in nextflow.config
process GET_DOCKER_COMPOSE {
    label 'bash_container'
    label 'farm_low'

    input:
    path containersList

    output:
    path compose, emit: compose

    script:
    compose='docker-compose.yml'
    """
    CONTAINERS_LIST="$containersList"
    COMPOSE="$compose"
    
    source create_docker_compose.sh
    """
}

// Pull all images in the genetared docker compose file
process PULL_IMAGES {
    input:
    path compose

    script:
    """
    docker-compose --file "$compose" pull
    """
}
