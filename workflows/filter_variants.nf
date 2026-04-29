include { BCFTOOLS_FILTER } from '../modules/local/bcftools_filter'
include { GENERATE_FAIL_BED } from '../modules/local/generate_fail_bed'
include { GENERATE_PASS_VCF } from '../modules/local/generate_pass_vcf'
include { GENERATE_PASS_VCF_NO_REPEATS } from '../modules/local/generate_pass_vcf_no_repeats'
include { BEDTOOLS_SUBTRACT } from '../modules/local/bedtools_subtract'
include { INTERSECT_BED } from '../modules/local/intersect_bed'
include { BCFTOOLS_MASK_BY_DEPTH } from '../modules/local/bcftools_mask_by_depth'
include { BCFTOOLS_SORT } from '../modules/local/bcftools_sort'
include { BCFTOOLS_INDEX } from '../modules/local/bcftools_index'

workflow FILTER_VARIANTS {
    take:
    genome
    vcf
    multi_callable_bed
    depth_thresholds
    genome_index
    repeat_bed

    main:
    BCFTOOLS_FILTER(genome, vcf)
    GENERATE_FAIL_BED(BCFTOOLS_FILTER.out, genome_index)
    BEDTOOLS_SUBTRACT(multi_callable_bed, GENERATE_FAIL_BED.out, genome_index)

    if (repeat_bed) {
        GENERATE_PASS_VCF_NO_REPEATS(BCFTOOLS_FILTER.out, repeat_bed)
        INTERSECT_BED(BEDTOOLS_SUBTRACT.out, repeat_bed, genome_index)
        pass_vcf = GENERATE_PASS_VCF_NO_REPEATS.out
        callable_bed = INTERSECT_BED.out
    } else {
        GENERATE_PASS_VCF(BCFTOOLS_FILTER.out)
        pass_vcf = GENERATE_PASS_VCF.out
        callable_bed = BEDTOOLS_SUBTRACT.out
    }

    BCFTOOLS_MASK_BY_DEPTH(pass_vcf, depth_thresholds)
    BCFTOOLS_SORT(BCFTOOLS_MASK_BY_DEPTH.out)
    BCFTOOLS_INDEX(BCFTOOLS_SORT.out)

    emit:
    filtered_vcf = BCFTOOLS_SORT.out
    filtered_vcf_index = BCFTOOLS_INDEX.out
    callable_bed = callable_bed
}
