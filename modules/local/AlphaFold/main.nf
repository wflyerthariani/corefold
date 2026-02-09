process ALPHAFOLD {
    tag "alphafold_${fasta.baseName}"
    label 'process_single'

    conda 'envs/helper-env.yml'
    container "${params.alphafold_sif_path}"

    input:
        tuple path(fasta), val(config_path), val(config_name)

    output:
        path "results/", emit: results

    script:
        """
        output_dir="\$PWD/results"
        mkdir -p "\$output_dir"

        get_args=\$(python ${projectDir}/helper/yaml_to_args.py "${config_path}/${config_name}" || true)

        singularity exec --nv --bind ${params.alphafold_data_dir}:${params.alphafold_data_dir} "${params.alphafold_sif_path}" /opt/run_alphafold.sh -f ${fasta} -d ${params.alphafold_data_dir} -o "\${output_dir}" \${get_args}
        """
}
