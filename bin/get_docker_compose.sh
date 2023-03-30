NEXTFLOW_CONFIG=$1
COMPOSE=$2

COUNT=0

echo "services:" >> $COMPOSE

grep -E "container\s?=" $NEXTFLOW_CONFIG \
    | sort -u \
    | sed -r "s/\s+container\s?=\s?'(.+)'/\1/" \
    |   while read -r IMAGE ; do
            COUNT=$((COUNT+1))
            echo "  SERVICE${COUNT}:" >> $COMPOSE
            echo "      image: $IMAGE" >> $COMPOSE
        done
