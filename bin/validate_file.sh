# Basic file validation of input files
# Check if read length is the same as quality-score length on all entries; if input is Gzipped, check file integrity first
# Report if any read is corrupted

FILE_VALIDITY=""

case "$READ_ONE" in
    *.gz)
        { 
            gzip -t "$READ_ONE" && zcat "$READ_ONE" | paste - - - - | awk -F"\t" '{ if (length($2) != length($4)) exit 1 }' ;
        } || { 
            FILE_VALIDITY+="READ_ONE_CORRUPTED;"; 
        }
        { 
            gzip -t "$READ_TWO" && zcat "$READ_TWO" | paste - - - - | awk -F"\t" '{ if (length($2) != length($4)) exit 1 }' ;
        } || { 
            FILE_VALIDITY+="READ_TWO_CORRUPTED;"; 
        }
        ;;
    *) 
        { 
            cat "$READ_ONE" | paste - - - - | awk -F"\t" '{ if (length($2) != length($4)) exit 1 }' ;
        } || { 
            FILE_VALIDITY+="READ_ONE_CORRUPTED;"; 
        }
        {
            cat "$READ_TWO" | paste - - - - | awk -F"\t" '{ if (length($2) != length($4)) exit 1 }' ;
        } || { 
            FILE_VALIDITY+="READ_TWO_CORRUPTED;"; 
        }
        ;;
esac

if [[ "$FILE_VALIDITY" == "" ]]; then
    FILE_VALIDITY="PASS"
else
    FILE_VALIDITY="${FILE_VALIDITY%;}"
fi