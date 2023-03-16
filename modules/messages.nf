// Start message
def startMessage(pipeline_version) {
    log.info """
        |
        |╔══════════════════════════════════════════════════════════════════════════════════════════╗
        |║                                                                                          ║░
        |║   ____ ____  ____    _   _       _  __ _          _   ____  _            _ _             ║░
        |║  / ___|  _ \\/ ___|  | | | |_ __ (_)/ _(_) ___  __| | |  _ \\(_)_ __   ___| (_)_ __   ___  ║░
        |║ | |  _| |_) \\___ \\  | | | | '_ \\| | |_| |/ _ \\/ _` | | |_) | | '_ \\ / _ | | | '_ \\ / _ \\ ║░
        |║ | |_| |  __/ ___) | | |_| | | | | |  _| |  __| (_| | |  __/| | |_) |  __| | | | | |  __/ ║░
        |║  \\____|_|   |____/   \\___/|_| |_|_|_| |_|\\___|\\__,_| |_|   |_| .__/ \\___|_|_|_| |_|\\___| ║░
        |${String.format("║  v %-57s |_|                         ║░", pipeline_version)}
        |╚══════════════════════════════════════════════════════════════════════════════════════════╝░
        |  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
       """.stripMargin()
} 


// Help message
def helpMessage() {
    log.info (
        """
        |This is a Nextflow Pipeline for processing Streptococcus pneumoniae sequencing raw reads (FASTQ files) 
        |
        |Usage: 
        |./run_pipeline [option] [value]
        |
        |All options are optional, some common options:
        |--reads [PATH]    Path to the input directory that contains the reads to be processed
        |--output [PATH]   Path to the output directory that save the results
        |--init          Alternative workflow for initialisation
        |--version       Alternative workflow for getting versions of pipeline, tools and databases
        |
        |For all available options, please refer to README.md
        """.stripMargin()
    )
}


// Workflow selection message
def workflowSelectMessage(selectedWorkflow) {
    String message
    File reads_dir = new File(params.reads)
    File output_dir = new File(params.output)

    switch(selectedWorkflow){
        case 'pipeline':
            message = """
            |The main pipeline workflow was selected.
            |
            |Input Directory: ${reads_dir.getAbsolutePath()}
            |Output Directory: ${output_dir.getAbsolutePath()}
            """.stripMargin()
            break
        case 'init':
            message = """
            |The alternative workflow for initialisation was selected.
            """.stripMargin()
            break
        case 'version':
            message = """
            |The alternative workflow for getting versions of pipeline, tools and databases was selected.
            """.stripMargin()
            break
    }

    Date date = new Date()
    String dateStr = date.format("yyyy-MM-dd")
    String timeStr = date.format("HH:mm:ss")

    log.info(
        """
        |${message}
        |The workflow started at ${dateStr} ${timeStr}.
        |
        |Current Progress:
        """.stripMargin()
    )
}

// End message
def endMessage(selectedWorkflow) {
    String successMessage
    String failMessage
    File output_dir = new File(params.output)

    switch(selectedWorkflow){
        case 'pipeline':
            successMessage = """
                |The pipeline has been completed successfully.
                |Check the outputs at ${output_dir.getAbsolutePath()}.
                """.stripMargin()
            failMessage = """
                |The pipeline has failed.
                |If you think it is caused by a bug, submit an issue at \"https://github.com/HarryHung/gps-unified-pipeline/issues\".
                """.stripMargin()
            break
        case 'init':
            successMessage = """
                |Initialisation has been completed successfully.
                |The pipeline can now be used offline (unless any pipeline option is changed).
                """.stripMargin()
            failMessage = """
                |Initialisation has failed.
                |Please ensure Docker is running and your machine is conneted to the Internet.
                """.stripMargin()
            break
        case 'version':
            successMessage = """
                |All the version information is printed above.
                """.stripMargin()
            failMessage = """
                |Failed to get version information on pipeline, tools or databases.
                |If you think it is caused by a bug, submit an issue at \"https://github.com/HarryHung/gps-unified-pipeline/issues\"
                """.stripMargin()
            break
    }

    Date date = new Date()
    String dateStr = date.format("yyyy-MM-dd")
    String timeStr = date.format("HH:mm:ss")

    log.info(
        """
        |The workflow ended at ${dateStr} ${timeStr}. The duration was ${workflow.duration}
        |${workflow.success ? successMessage : failMessage}
        """.stripMargin()
    )
}