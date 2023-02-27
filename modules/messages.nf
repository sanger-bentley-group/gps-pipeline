// Start message
def startMessage() {
    log.info """
        |
        |=================================================
        |G P S   U N I F I E D   P I P E L I N E   v ${params.pipeline_version} 
        |=================================================
       """.stripMargin()
} 

// Workflow selection message
def workflowSelectMessage(selectedWorkflow) {
    String msg

    switch(selectedWorkflow){
        case 'pipeline':
            msg = "The main pipeline workflow was selected."
            break
        case 'init':
            msg = "The alternative workflow for initialisation was selected."
            break
        case 'version':
            msg = "The alternative workflow for getting versions of pipeline and tools was selected."
            break
    }

    Date date = new Date()
    String dateStr = date.format("yyyy-MM-dd")
    String timeStr = date.format("HH:mm:ss")

    log.info(
        """
        |${msg}
        |The workflow started at ${dateStr} ${timeStr}.
        |
        |Current Progress:
        """.stripMargin()
    )
}

// End message
def endMessage(selectedWorkflow) {
    String successMsg
    String failMsg

    switch(selectedWorkflow){
        case 'pipeline':
            successMsg = """
                |The pipeline has been completed successfully.
                |Check the outputs at ${params.output}.
                """.stripMargin()
            failMsg = """
                |The pipeline has failed.
                |If you think it is caused by a bug, submit an issue at \"https://github.com/HarryHung/gps-unified-pipeline/issues\".
                """.stripMargin()
            break
        case 'init':
            successMsg = """
                |Initialisation has been completed successfully.
                |The pipeline can now be used offline (unless any pipeline option is changed).
                """.stripMargin()
            failMsg = """
                |Initialisation has failed.
                |Please ensure Docker is running and your machine is conneted to the Internet.
                """.stripMargin()
            break
        case 'version':
            successMsg = """
                |All the version information is printed above.
                """.stripMargin()
            failMsg = """
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
        |${workflow.success ? successMsg : failMsg}
        """.stripMargin()
    )
}