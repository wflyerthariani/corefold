process RFDIFFUSION {
    tag "rfdiffusion_${task.index}"
    label 'process_single'

    container "${params.rfdiff_sif_path}"

    input:
        tuple val(output_prefix), val(design_startnum), val(config_path), val(config_name)

    output:
        tuple path("RFDresults_*.pdb"), path("RFDresults_*.trb"), emit: designs

    script:
        """
        export SCHEDULE_DIR="${params.rfdiff_editables_dir}/schedules"
        export MODEL_DIR="${params.rfdiff_editables_dir}/models"

        /opt/miniconda/envs/SE3nv/bin/python \
            /opt/RFdiffusion/scripts/run_inference.py \
            --config-path ${config_path} \
            --config-name ${config_name} \
            +inference.output_prefix="\${PWD}/RFDresults" \
            +inference.num_designs=1 \
            +inference.design_startnum="${design_startnum}"
        """
}
