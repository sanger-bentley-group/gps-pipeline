# Call SNPs and save to .vcf
# Remove source sorted BAM file if $LITE is true

bcftools mpileup --threads "$(nproc)" -f "$REFERENCE" "$SORTED_BAM" | bcftools call --threads "$(nproc)" -mv -O v -o "$VCF"

if [ "$LITE" = true ]; then
    rm "$(readlink -f "$SORTED_BAM")"
fi
