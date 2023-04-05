# Return reference coverage percentage by the reads

samtools index -@ `nproc` "$BAM"
COVERAGE=$(samtools coverage "$BAM" | awk -F'\t' 'FNR==2 {print $6}')
