nextflow.enable.dsl = 2

workflow input_prep {
    take:
        output_prefix
        num_designs

    main:
        ch = Channel.from(0..(num_designs-1))
            .map { idx -> tuple(output_prefix, idx) }

    emit:
        ch
}
