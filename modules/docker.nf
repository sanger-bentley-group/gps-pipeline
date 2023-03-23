// Return a docker compose file that includes all images used in nextflow.config
process GET_DOCKER_COMPOSE {
    label 'bash_container'
    label 'farm_low'

    input:
    path nextflowConfig

    output:
    path 'docker-compose.yml', emit: compose

    shell:
    '''
    COMPOSE="docker-compose.yml"
    COUNT=0

    echo "services:" >> $COMPOSE

    grep -E "container\s?=" !{nextflowConfig} \
        | sort -u \
        | sed -r "s/\s+container\s?=\s?'(.+)'/\\1/" \
        |   while read -r IMAGE ; do
                COUNT=$((COUNT+1))
                echo "  SERVICE${COUNT}:" >> $COMPOSE
                echo "      image: $IMAGE" >> $COMPOSE
            done
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
