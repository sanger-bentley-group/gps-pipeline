#!/usr/bin/env nextflow

params.os = System.properties['os.name']

params.reads = "${projectDir}/data"

params.spades_local = "${projectDir}/bin/spades"

params.seroba_remote = "https://github.com/sanger-pathogens/seroba.git"
params.seroba_local = "${projectDir}/bin/seroba"


include { PREPROCESSING } from './modules/preprocessing'
include { GET_SPADES; ASSEMBLING } from './modules/assembling'
include { GET_SEROBA_DB; SEROTYPING; SEROTYPE_SUMMARY } from './modules/serotyping'


workflow {
    spades_py = GET_SPADES(params.os, params.spades_local)
    seroba_db = GET_SEROBA_DB(params.seroba_remote, params.seroba_local)

    raw_read_pairs_ch = Channel.fromFilePairs( "$params.reads/*_{1,2}.fastq.gz", checkIfExists: true )

    prcoessed_reads_ch = PREPROCESSING(raw_read_pairs_ch)

    ASSEMBLING(spades_py, prcoessed_reads_ch)

    serotype_ch = SEROTYPING(seroba_db, prcoessed_reads_ch)
    SEROTYPE_SUMMARY(serotype_ch.collect())
}