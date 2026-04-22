include { MOSDEPTH_CALLABLE } from '../modules/local/mosdepth_callable'
include { INTERSECT_BEDS } from '../modules/local/intersect_beds'
include { INTERSECT_BEDS_NO_REPEATS } from '../modules/local/intersect_beds_no_repeats'
include { INTERSECT_BED } from '../modules/local/intersect_bed'
include { INTERSECT_BED_NO_REPEATS } from '../modules/local/intersect_bed_no_repeats'

workflow CALLABLE_REGIONS_MULTI {
    take:
    deduped_bams
    min_depth
    repeat_bed
    genome_index
    dataset_id

    main:
    MOSDEPTH_CALLABLE(deduped_bams, min_depth)
    if (repeat_bed) {
        INTERSECT_BEDS(MOSDEPTH_CALLABLE.out.collect(), repeat_bed, genome_index, dataset_id)
        callable_bed = INTERSECT_BEDS.out.freebayes
    } else {
        INTERSECT_BEDS_NO_REPEATS(MOSDEPTH_CALLABLE.out.collect(), genome_index, dataset_id)
        callable_bed = INTERSECT_BEDS_NO_REPEATS.out.freebayes
    }

    emit:
    callable_bed = callable_bed
}

workflow CALLABLE_REGIONS_SINGLE {
    take:
    deduped_bams
    min_depth
    repeat_bed
    genome_index
    dataset_id

    main:
    MOSDEPTH_CALLABLE(deduped_bams, min_depth)
    if (repeat_bed) {
        INTERSECT_BED(MOSDEPTH_CALLABLE.out, repeat_bed, genome_index, dataset_id)
        callable_bed = INTERSECT_BED.out
    } else {
        INTERSECT_BED_NO_REPEATS(MOSDEPTH_CALLABLE.out, genome_index, dataset_id)
        callable_bed = INTERSECT_BED_NO_REPEATS.out
    }

    emit:
    callable_bed = callable_bed
}
