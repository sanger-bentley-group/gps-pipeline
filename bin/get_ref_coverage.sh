# Return reference coverage percentage by the reads

samtools index -@ "$(nproc)" "$SORTED_BAM"
COVERAGE=$(samtools coverage "$SORTED_BAM" | awk -F'\t' 'FNR==2 {print $6}')
