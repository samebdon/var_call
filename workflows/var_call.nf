include { PREPARE_REFERENCE; PREPARE_ALIGNMENT_REFERENCE } from './prepare_reference'
include { CALLABLE_REGIONS } from './callable_regions'
include { FILTER_VARIANTS } from './filter_variants'

include { TRIM_READS } from '../modules/local/trim_reads'
include { BWA_MEM } from '../modules/local/bwa_mem'
include { BWA_MEM_SE } from '../modules/local/bwa_mem_se'
include { ADD_RGS } from '../modules/local/add_rgs'
include { SORT_BAM_SAMBAMBA } from '../modules/local/sort_bam_sambamba'
include { MARK_DUPES_SAMBAMBA } from '../modules/local/mark_dupes_sambamba'
include { FREEBAYES_PARALLEL } from '../modules/local/freebayes'

workflow VAR_CALL_PAIRED {
    take:
    genome
    read_files
    repeat_bed
    species
    dataset_id
    skip_trimming

    main:
    PREPARE_ALIGNMENT_REFERENCE(genome)

    if (skip_trimming) {
        trimmed_reads = read_files
    } else {
        TRIM_READS(read_files)
        trimmed_reads = TRIM_READS.out
    }

    BWA_MEM(genome, PREPARE_ALIGNMENT_REFERENCE.out.bwa_index, trimmed_reads)
    SORT_BAM_SAMBAMBA(BWA_MEM.out)
    MARK_DUPES_SAMBAMBA(SORT_BAM_SAMBAMBA.out)
    CALLABLE_REGIONS(MARK_DUPES_SAMBAMBA.out.bam, params.min_depth, PREPARE_ALIGNMENT_REFERENCE.out.fasta_index, dataset_id)

    bam_list = MARK_DUPES_SAMBAMBA.out.bam
        .map { meta, bam, bai -> bam }
        .collect()

    staged_bams = MARK_DUPES_SAMBAMBA.out.bam
        .map { meta, bam, bai -> [bam, bai] }
        .collect()

    FREEBAYES_PARALLEL(genome, PREPARE_ALIGNMENT_REFERENCE.out.fasta_index, bam_list, dataset_id, staged_bams)
    FILTER_VARIANTS(genome, FREEBAYES_PARALLEL.out, CALLABLE_REGIONS.out.multi_callable_bed, CALLABLE_REGIONS.out.depth_thresholds, PREPARE_ALIGNMENT_REFERENCE.out.fasta_index, repeat_bed)
}

workflow VAR_CALL_BAMS {
    take:
    genome
    bams
    repeat_bed
    species
    dataset_id

    main:
    PREPARE_REFERENCE(genome)

    ADD_RGS(bams, params.bam_rg_mode)
    SORT_BAM_SAMBAMBA(ADD_RGS.out)
    MARK_DUPES_SAMBAMBA(SORT_BAM_SAMBAMBA.out)
    CALLABLE_REGIONS(MARK_DUPES_SAMBAMBA.out.bam, params.min_depth, PREPARE_REFERENCE.out.fasta_index, dataset_id)

    bam_list = MARK_DUPES_SAMBAMBA.out.bam
        .map { meta, bam, bai -> bam }
        .collect()

    staged_bams = MARK_DUPES_SAMBAMBA.out.bam
        .map { meta, bam, bai -> [bam, bai] }
        .collect()

    FREEBAYES_PARALLEL(genome, PREPARE_REFERENCE.out.fasta_index, bam_list, dataset_id, staged_bams)
    FILTER_VARIANTS(genome, FREEBAYES_PARALLEL.out, CALLABLE_REGIONS.out.multi_callable_bed, CALLABLE_REGIONS.out.depth_thresholds, PREPARE_REFERENCE.out.fasta_index, repeat_bed)
}

workflow VAR_CALL_SINGLE_END {
    take:
    genome
    reads
    repeat_bed
    species
    dataset_id

    main:
    PREPARE_ALIGNMENT_REFERENCE(genome)

    BWA_MEM_SE(genome, PREPARE_ALIGNMENT_REFERENCE.out.bwa_index, reads)
    SORT_BAM_SAMBAMBA(BWA_MEM_SE.out)
    MARK_DUPES_SAMBAMBA(SORT_BAM_SAMBAMBA.out)
    CALLABLE_REGIONS(MARK_DUPES_SAMBAMBA.out.bam, params.min_depth, PREPARE_ALIGNMENT_REFERENCE.out.fasta_index, dataset_id)

    bam_list = MARK_DUPES_SAMBAMBA.out.bam
        .map { meta, bam, bai -> bam }
        .collect()

    staged_bams = MARK_DUPES_SAMBAMBA.out.bam
        .map { meta, bam, bai -> [bam, bai] }
        .collect()

    FREEBAYES_PARALLEL(genome, PREPARE_ALIGNMENT_REFERENCE.out.fasta_index, bam_list, dataset_id, staged_bams)
    FILTER_VARIANTS(genome, FREEBAYES_PARALLEL.out, CALLABLE_REGIONS.out.multi_callable_bed, CALLABLE_REGIONS.out.depth_thresholds, PREPARE_ALIGNMENT_REFERENCE.out.fasta_index, repeat_bed)
}
