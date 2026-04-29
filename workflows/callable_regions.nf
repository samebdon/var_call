include { MOSDEPTH_CALLABLE } from '../modules/local/mosdepth_callable'
include { MULTIINTER_CALLABLE } from '../modules/local/multiinter_callable'

workflow CALLABLE_REGIONS {
    take:
    deduped_bams
    min_depth
    genome_index
    dataset_id

    main:
    MOSDEPTH_CALLABLE(deduped_bams, min_depth)

    callable_bed_inputs = MOSDEPTH_CALLABLE.out.callable_bed
        .join(MOSDEPTH_CALLABLE.out.sample_name)
        .collect()
        .map { rows -> [rows.collect { it[2].text.trim() }, rows.collect { it[1] }] }

    MULTIINTER_CALLABLE(callable_bed_inputs, genome_index, dataset_id)

    depth_thresholds = MOSDEPTH_CALLABLE.out.depth_thresholds
        .map { meta, threshold_file -> threshold_file }
        .collect()

    emit:
    multi_callable_bed = MULTIINTER_CALLABLE.out.multi_callable
    joint_callable_bed = MULTIINTER_CALLABLE.out.joint_callable
    depth_thresholds = depth_thresholds
    callable_size_mb = MOSDEPTH_CALLABLE.out.callable_size_mb
}
