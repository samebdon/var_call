include { MOSDEPTH_CALLABLE } from '../modules/local/mosdepth_callable'
include { INTERSECT_BEDS } from '../modules/local/intersect_beds'
include { INTERSECT_BEDS_NO_REPEATS } from '../modules/local/intersect_beds_no_repeats'

workflow CALLABLE_REGIONS {
    take:
    deduped_bams
    min_depth
    repeat_bed
    genome_index
    dataset_id

    main:
    MOSDEPTH_CALLABLE(deduped_bams, min_depth)
    MOSDEPTH_CALLABLE.out.callable_bed
        .map{ meta, bed -> bed}
        .collect()
        .set{ callable_bed_ch }
        
    if (repeat_bed) {
        INTERSECT_BEDS(callable_bed_ch, repeat_bed, genome_index, dataset_id)
        callable_bed = INTERSECT_BEDS.out.freebayes
    } else {
        INTERSECT_BEDS_NO_REPEATS(callable_bed_ch, genome_index, dataset_id)
        callable_bed = INTERSECT_BEDS_NO_REPEATS.out.freebayes
    }

    emit:
    callable_bed = callable_bed
    callable_size_mb = MOSDEPTH_CALLABLE.out.callable_size_mb
}
