// Start message
def startMessage() {
    log.info """
        |
        |=================================================
        |G P S   U N I F I E D   P I P E L I N E   v ${params.pipeline_version} 
        |=================================================
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
        |--reads=PATH    Path to the input directory that contains the reads to be processed
        |--output=PATH   Path to the output directory that save the results
        |--init          Alternative workflow for initialisation
        |--version       Alternative workflow for getting versions of pipeline and tools
        |
        |For all available options, refer to https://github.com/HarryHung/gps-unified-pipeline/blob/master/README.md
        """.stripMargin()
    )
}


// Workflow selection message
def workflowSelectMessage(selectedWorkflow) {
    String message

    switch(selectedWorkflow){
        case 'pipeline':
            message = "The main pipeline workflow was selected."
            break
        case 'init':
            message = "The alternative workflow for initialisation was selected."
            break
        case 'version':
            message = "The alternative workflow for getting versions of pipeline and tools was selected."
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

    switch(selectedWorkflow){
        case 'pipeline':
            successMessage = """
                |The pipeline has been completed successfully.
                |Check the outputs at ${params.output}.
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
                |Failed to get version information on all tools.
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