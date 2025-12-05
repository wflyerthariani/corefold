#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-core/corefold
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/nf-core/corefold
    Website: https://nf-co.re/corefold
    Slack  : https://nfcore.slack.com/channels/corefold
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { COREFOLD  } from './workflows/corefold'
include { design_pipeline } from './subworkflows/local/design_pipeline.nf'
include { input_prep } from './subworkflows/local/inputprep.nf'

workflow {

    // Validate required params (nf-core style pipelines enforce params.outdir at least)
    if (!params.outdir) {
        log.error "Missing required param --outdir"
        exit 1
    }
    if (!params.num_designs) {
        log.error "Missing required param --num_designs"
        exit 1
    }
    if (!params.output_prefix) {
        log.error "Missing required param --output_prefix"
        exit 1
    }

    // Build the rf input tuples (output_prefix, start_index)
    ch_designs = input_prep(params.output_prefix, params.num_designs)

    // Run the pipeline subworkflow (RFdiffusion -> ProteinMPNN -> AlphaFold)
    results = design_pipeline(ch_designs)

    // Optionally write a simple view (you can remove this in production)
    results.view { it -> "ALPHAFOLD_DONE: ${it}" }
}
