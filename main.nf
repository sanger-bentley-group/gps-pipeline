#!/usr/bin/env nextflow


// Import workflow modules
include { PIPELINE } from "$projectDir/workflows/pipeline"
include { INIT } from "$projectDir/workflows/init"
include { GET_VERSION } from "$projectDir/workflows/version"

// Import supporting modules
include { startMessage; workflowSelectMessage; endMessage } from "$projectDir/modules/messages" 


// Start message
startMessage()


// Select workflow with PIPELINE as default
workflow {
    if (params.init) {
        workflowSelectMessage("init")
        INIT()
    } else if (params.version) {
        workflowSelectMessage("version")
        GET_VERSION()
    } else {
        workflowSelectMessage("pipeline")
        PIPELINE()
    }
}


// End message
workflow.onComplete {
    if (params.init) {
        endMessage("init")
    } else if (params.version) {
        endMessage("version")
    } else {
        endMessage("pipeline")
    }
}