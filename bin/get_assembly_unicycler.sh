# Run Unicycler to get assembly
# Set to use all available threads if not specify; not using unpaired read if it is empty to prevent Unicycler from crashing

if [ "$THREAD" = '0' ]; then 
    THREAD=$(nproc)
fi

if [ -s "$UNPAIRED" ]; then 
    unicycler -1 "$READ1" -2 "$READ2" -s "$UNPAIRED" -o results -t "$THREAD" --min_fasta_length "$MIN_CONTIG_LENGTH"
else 
    unicycler -1 "$READ1" -2 "$READ2" -o results -t "$THREAD" --min_fasta_length "$MIN_CONTIG_LENGTH"
fi

mv results/assembly.fasta "$FASTA"
