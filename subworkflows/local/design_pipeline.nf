nextflow.enable.dsl = 2

include { RFDIFFUSION } from '../../modules/local/RFdiffusion/main.nf'
include { PROTEINMPNN } from '../../modules/local/ProteinMPNN/main.nf'
include { ALPHAFOLD } from '../../modules/local/AlphaFold/main.nf'

workflow design_pipeline {
    take:
        start_ch

    main:
        ch_versions = Channel.empty()

        //
        // 1) RFdiffusion: start_ch emits tuple(output_prefix, start_index)
        //    Prepare config path and name for the module
        //
        rf_in = start_ch.map { output_prefix, design_startnum ->
            tuple(output_prefix, design_startnum, params.config_dir, params.rfdiff_config_name)
        }

        RFDIFFUSION(rf_in)
        rf_out_ch = RFDIFFUSION.out.designs

        //
        // 2) ProteinMPNN: Parse PDB files and prepare chains
        //    - Parse multiple chains from PDB
        //    - Generate fixed positions JSONL
        //    - Run ProteinMPNN
        //
        mpnn_in = rf_out_ch.map { pdb, trb ->
            // Parse chains from PDB
            def folder_with_pdbs = "\$PWD/MPNNdiv_${pdb.baseName}/"
            // This would need to be done via a process or separate step
            // For now, we pass the files and let the subworkflow orchestrate
            tuple(pdb, trb)
        }

        // Create a process for PDB parsing (part of subworkflow orchestration)
        mpnn_prep = mpnn_in | PREPARE_PROTEINMPNN_INPUTS
        
        mpnn_main = mpnn_prep.map { pdb, parsed_chains, fixed_positions ->
            tuple(pdb, parsed_chains, fixed_positions, params.config_dir, params.mpnn_config_name)
        }

        PROTEINMPNN(mpnn_main)
        mpnn_out_ch = PROTEINMPNN.out.sequences

        //
        // 3) AlphaFold: Split FASTA files and run structure prediction
        //
        af_split = mpnn_out_ch | SPLIT_FASTAS
        af_in = af_split.map { fasta ->
            tuple(fasta, params.config_dir, params.alphafold_config_name)
        }

        ALPHAFOLD(af_in)
        af_out = ALPHAFOLD.out.results

    emit:
        af_out
}

//
// Process to prepare ProteinMPNN inputs (PDB parsing, fixed positions)
//
process PREPARE_PROTEINMPNN_INPUTS {
    tag "prep_mpnn_${pdb.baseName}"
    label 'process_single'
    conda 'envs/helper-env.yml'

    input:
        tuple file(pdb), file(trb)

    output:
        tuple path(pdb), path("parsed_pdbs.jsonl"), path("fixed_pdbs.jsonl"), emit: mpnn_inputs

    script:
        """
        mkdir -p pdb_folder
        cp ${pdb} pdb_folder/

        # Parse chains
        python /opt/ProteinMPNN/helper_scripts/parse_multiple_chains.py \
            --input_path pdb_folder \
            --output_path parsed_pdbs.jsonl

        # Process fixed residues
        get_fixed=\$(python ${projectDir}/helper/reformat_fixed_residues.py --input-file ${trb} || true)

        chains_to_design=\$(echo "\$get_fixed" | grep -- '--chains_to_design' | cut -d'"' -f2 || true)
        fixed_positions=\$(echo "\$get_fixed" | grep -- '--fixed_positions' | cut -d'"' -f2 || true)

        python /opt/ProteinMPNN/helper_scripts/make_fixed_positions_dict.py \
            --input_path=parsed_pdbs.jsonl \
            --output_path=fixed_pdbs.jsonl \
            --chain_list "\$chains_to_design" \
            --position_list "\$fixed_positions"
        """
}

//
// Process to split FASTA files from ProteinMPNN output
//
process SPLIT_FASTAS {
    tag "split_fastas"
    label 'process_single'

    input:
        path seqs_dir

    output:
        path "split/*.fasta", emit: fasta_files

    script:
        """
        python ${projectDir}/helper/split_mpnn_fastas.py \
            --input-folder ${seqs_dir} \
            --output-folder split
        """
}
