include { BCFTOOLS_FILTER } from '../modules/local/bcftools_filter'
include { GENERATE_FAIL_BED } from '../modules/local/generate_fail_bed'
include { GENERATE_PASS_VCF } from '../modules/local/generate_pass_vcf'
include { BEDTOOLS_SUBTRACT } from '../modules/local/bedtools_subtract'
include { BCFTOOLS_SORT } from '../modules/local/bcftools_sort'
include { BCFTOOLS_INDEX } from '../modules/local/bcftools_index'

workflow FILTER_VARIANTS {
    take:
    genome
    vcf
    callable_bed
    genome_index

    main:
    BCFTOOLS_FILTER(genome, vcf)
    GENERATE_FAIL_BED(BCFTOOLS_FILTER.out, genome_index)
    GENERATE_PASS_VCF(BCFTOOLS_FILTER.out)
    BEDTOOLS_SUBTRACT(callable_bed, GENERATE_FAIL_BED.out, genome_index)
    BCFTOOLS_SORT(GENERATE_PASS_VCF.out)
    BCFTOOLS_INDEX(BCFTOOLS_SORT.out)

    emit:
    filtered_vcf = BCFTOOLS_SORT.out
    filtered_vcf_index = BCFTOOLS_INDEX.out
    callable_bed = BEDTOOLS_SUBTRACT.out
}
