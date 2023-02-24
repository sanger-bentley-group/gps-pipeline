// Start message
def startMessage(version) {
    log.info """\
        \n
        =================================================
        G P S   U N I F I E D   P I P E L I N E   v ${version} 
        =================================================
        """
        .stripIndent()
} 

// Workflow selection message
def workflowSelectMessage(workflowName) {
    log.info """\
    The ${workflowName} is selected and will now be executed.
    """
    .stripIndent()
}

// End message
def endMessage(selectedWorkflow) {
    switch(selectedWorkflow){
        case 'pipeline':
            log.info (
                workflow.success ?
                "\nThe pipeline has been completed successfully.\nCheck the outputs at ${params.output}.\n" :
                "\nThe pipeline has failed.\nIf you think it is caused by a bug, submit an issue at \"https://github.com/HarryHung/gps-unified-pipeline/issues\".\n"
            )
            break
        case 'init':
            log.info (
                workflow.success ?
                "\nInitialisation has been completed successfully.\nThe pipeline can now be used offline (unless any pipeline option is changed).\n" :
                "\nInitialisation has failed.\nPlease ensure Docker is running and your machine is conneted to the Internet.\n"
            )
            break
    }
}