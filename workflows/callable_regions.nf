include { MOSDEPTH_CALLABLE } from '../modules/local/mosdepth_callable'
include { MULTIINTER_CALLABLE } from '../modules/local/multiinter_callable'
include { PLOT_MOSDEPTH_DIST } from '../modules/local/plot_mosdepth_dist'

workflow CALLABLE_REGIONS {
    take:
    genome
    deduped_bams
    min_depth
    genome_index
    dataset_id

    main:
    MOSDEPTH_CALLABLE(genome, deduped_bams, min_depth)

    callable_beds = MOSDEPTH_CALLABLE.out.callable_bed
        .map { meta, bed -> bed }
        .collect()

    sample_name_files = MOSDEPTH_CALLABLE.out.sample_name
        .map { meta, sample_name_file -> sample_name_file }
        .collect()

    MULTIINTER_CALLABLE(callable_beds, sample_name_files, genome_index, dataset_id)

    depth_thresholds = MOSDEPTH_CALLABLE.out.depth_thresholds
        .map { meta, threshold_file -> threshold_file }
        .collect()

    global_dist_files = MOSDEPTH_CALLABLE.out.global_dist
        .map { meta, dist_file -> dist_file }
        .collect()

    PLOT_MOSDEPTH_DIST(
        global_dist_files,
        dataset_id,
        min_depth,
        params.mosdepth_plot_max_cov,
        params.mosdepth_plot_min_fraction
    )

    emit:
    multi_callable_bed = MULTIINTER_CALLABLE.out.multi_callable
    joint_callable_bed = MULTIINTER_CALLABLE.out.joint_callable
    depth_thresholds = depth_thresholds
    callable_size_mb = MOSDEPTH_CALLABLE.out.callable_size_mb
    callable_status = MOSDEPTH_CALLABLE.out.callable_status
    mosdepth_plot = PLOT_MOSDEPTH_DIST.out
}
