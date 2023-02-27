#!/usr/bin/env nextflow


// Version number of this release
pipeline_version='0.6.0'


// Import workflow modules
include { PIPELINE } from "$projectDir/workflows/pipeline"
include { INIT } from "$projectDir/workflows/init"
include { GET_VERSION } from "$projectDir/workflows/version"

// Import supporting modules
include { startMessage; workflowSelectMessage; endMessage } from "$projectDir/modules/messages" 


// Start message
startMessage(pipeline_version)


// Main pipeline workflow
workflow {
    if (params.init) {
        workflowSelectMessage("Alternative workflow for initialisation")
        INIT()
    } else if (params.version) {
        workflowSelectMessage("Alternative workflow for getting versions of pipeline and tools")
        GET_VERSION()
    } else {
        workflowSelectMessage("The main pipeline")
        PIPELINE()
    }
}


// End message
workflow.onComplete {
    String selectedWorkflow; 

    if (params.init) {
        selectedWorkflow = "init"
    } else if (params.version) {
        selectedWorkflow = "version"
    } else {
        selectedWorkflow = "pipeline"
    }

    endMessage(selectedWorkflow)
}