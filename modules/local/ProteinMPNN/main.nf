process PROTEINMPNN {
    tag "mpnn_${pdb.baseName}"
    label 'process_single'

    conda 'envs/helper-env.yml'
    container "${params.mpnn_sif_path}"

    input:
        tuple file(pdb), file(parsed_chains_jsonl), file(fixed_positions_jsonl), val(config_path), val(config_name)

    output:
        path "seqs/", emit: sequences

    script:
        """
        output_dir="\$PWD"

        get_args=\$(python ${projectDir}/helper/yaml_to_args.py "${config_path}/${config_name}" || true)

        singularity exec --nv \
            --bind "${params.mpnn_editables_dir}":"${params.mpnn_editables_dir}" \
            --pwd  "${params.mpnn_editables_dir}" \
            "${params.mpnn_sif_path}" \
            python /opt/ProteinMPNN/protein_mpnn_run.py \
                --jsonl_path ${parsed_chains_jsonl} \
                --out_folder \${output_dir} \
                --fixed_positions_jsonl ${fixed_positions_jsonl} \
                --num_seq_per_target ${params.mpnn_num_sequences} \
                --batch_size 1 \${get_args}
        """
}
