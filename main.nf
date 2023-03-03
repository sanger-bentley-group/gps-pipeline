#!/usr/bin/env nextflow


// Version of this release
pipeline_version='0.6.0'


// Import workflow modules
include { PIPELINE } from "$projectDir/workflows/pipeline"
include { INIT } from "$projectDir/workflows/init"
include { GET_VERSION } from "$projectDir/workflows/version"

// Import supporting modules
include { startMessage; helpMessage; workflowSelectMessage; endMessage } from "$projectDir/modules/messages" 
include { validate } from "$projectDir/modules/validate"


// Start message
startMessage(pipeline_version)

// Validate parameters
validate(params)

// Select workflow with PIPELINE as default
workflow {
    if (params.help) {
        helpMessage()
    } else if (params.init) {
        workflowSelectMessage("init")
        INIT()
    } else if (params.version) {
        workflowSelectMessage("version")
        GET_VERSION(pipeline_version)
    } else {
        workflowSelectMessage("pipeline")
        PIPELINE()
        GET_VERSION(pipeline_version)
    }
}


// End message
workflow.onComplete {
    if (params.help) {
        return
    } else if (params.init) {
        endMessage("init")
    } else if (params.version) {
        endMessage("version")
    } else {
        endMessage("pipeline")
    }
}