# Run Shovill to get assembly
# Set to use all available threads if not specify

if [ "$THREAD" = '0' ]; then 
    THREAD=$(nproc)
fi

shovill --R1 "$READ1" --R2 "$READ2" --outdir results --cpus "$THREAD" --minlen "$MIN_CONTIG_LENGTH" --force
mv results/contigs.fa "$FASTA"
