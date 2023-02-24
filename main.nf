#!/usr/bin/env nextflow


// Version number of this release
version='0.6.0'


// Import workflow modules
include { PIPELINE } from "$projectDir/workflows/pipeline"
include { INIT } from "$projectDir/workflows/init"

// Import supporting modules
include { startMessage } from "$projectDir/modules/messages" 


// Start message
startMessage(version)


// Main pipeline workflow
workflow {
    PIPELINE()
}

// Alternative workflow for initialisation only
workflow init {
    INIT()
}