#!/usr/bin/env nextflow

// Version of this release
pipelineVersion = '0.6.0'

// Import workflow modules
include { PIPELINE } from "$projectDir/workflows/pipeline"
include { INIT } from "$projectDir/workflows/init"
include { PRINT_VERSION; SAVE_INFO } from "$projectDir/workflows/info_and_version"

// Import supporting modules
include { startMessage; helpMessage; workflowSelectMessage; endMessage } from "$projectDir/modules/messages"
include { validate } from "$projectDir/modules/validate"
include { singularityPreflight } from "$projectDir/modules/singularity"

// Safeguard Nextflow minimum version, in case user is not using the included executable
nextflowMinVersion = '22.10' 
if( !nextflow.version.matches("${nextflowMinVersion}+") ) {
    log.error("The pipeline requires Nextflow version ${nextflowMinVersion} or greater -- You are running version $nextflow.version") 
    System.exit(1)
}

// Start message
startMessage(pipelineVersion)

// Validate parameters
validate(params)

// If Singularity is used as the container engine and not showing help message, do preflight check to prevent parallel pull issues
// Related issue: https://github.com/nextflow-io/nextflow/issues/1210
if (workflow.containerEngine === 'singularity' & !params.help) {
    singularityPreflight(workflow.configFiles[0], params.singularity_cachedir)
}

// Select workflow with PIPELINE as default
workflow {
    if (params.help) {
        helpMessage()
    } else if (params.init) {
        workflowSelectMessage('init')
        INIT()
    } else if (params.version) {
        workflowSelectMessage('version')
        PRINT_VERSION(pipelineVersion)
    } else {
        workflowSelectMessage('pipeline')
        PIPELINE()
        SAVE_INFO(PIPELINE.out.databases_info, pipelineVersion)
    }
}

// End message
workflow.onComplete {
    if (params.help) {
        return
    } else if (params.init) {
        endMessage('init')
    } else if (params.version) {
        endMessage('version')
    } else {
        endMessage('pipeline')
    }
}
