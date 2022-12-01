// Remove any pre-existing summary.csv in the ouput directory 
process CLEAN_SUMMARY {
    input:
    val summary_csv

    output:
    val true, emit: ready

    shell:
    '''
    rm -rf !{summary_csv}
    '''
}

// Add row to summary.csv in the ouput directory
// Only add header if summary.csv does not exist yet
process SUMMARY {
    maxForks 1

    input:
    val ready
    val summary_csv
    tuple val(sample_id), val(contigs), val(length), val(depth), val(assembly_qc), val(serotype), val(seroba_comment)

    """
    #!/usr/bin/env python
    import pandas as pd
    import os

    df = pd.DataFrame.from_records([{
            'Sample_ID':'$sample_id',
            'No_of_Contigs':'$contigs',
            'Seq_Depth':'$depth',
            'Assembly_QC':'$assembly_qc',
            'Serotype': '$serotype',
            'SeroBA_Comment': '$seroba_comment'
        }])
    
    df.to_csv("$summary_csv", mode='a', header=(not os.path.exists("$summary_csv")), index=False)
    """
}