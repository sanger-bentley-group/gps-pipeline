# Generate a Docker compose file that includes all images used in $CONTAINERS_LIST

COUNT=0

echo "services:" >> "$COMPOSE"

sort -u "$CONTAINERS_LIST" \
|   while read -r IMAGE ; do
        COUNT=$((COUNT+1))
        echo "  SERVICE${COUNT}:" >> "$COMPOSE"
        echo "      image: $IMAGE" >> "$COMPOSE"
    done
