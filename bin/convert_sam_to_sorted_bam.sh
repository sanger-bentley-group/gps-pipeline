# Convet SAM to sorted BAM file
# Remove source SAM file if $LITE is true

samtools view -@ "$(nproc)" -b "$SAM" > "$BAM"

samtools sort -@ "$(nproc)" -o "$SORTED_BAM" "$BAM"
rm "$BAM"

if [ "$LITE" = true ]; then
    rm "$(readlink -f "$SAM")"
fi
