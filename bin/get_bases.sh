# Extract total base count from output JSON file of fastp

BASES=$(< $JSON jq -r .summary.after_filtering.total_bases)
