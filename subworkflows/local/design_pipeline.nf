nextflow.enable.dsl = 2

include { RFdiffusion } from '../../modules/local/RFdiffusion/main.nf'
include { ProteinMPNN } from '../../modules/local/ProteinMPNN/main.nf'
include { AlphaFold } from '../../modules/local/AlphaFold/main.nf'

workflow design_pipeline {
    take:
        start_ch

    main:
        //
        // 1) RFdiffusion: start_ch emits tuple(output_prefix, start_index)
        //
        rf_out_ch = start_ch | RFdiffusion

        //
        // 2) ProteinMPNN: RFdiffusion emits tuples (pdb, trb)
        //
        mpnn_out_ch = rf_out_ch | ProteinMPNN

        //
        // 3) AlphaFold: ProteinMPNN emits fasta_files (glob). Flatten them then feed AlphaFold
        //
        af_in = mpnn_out_ch.fasta_files.flatten()
        af_out = af_in | AlphaFold

    emit:
        af_out
}
