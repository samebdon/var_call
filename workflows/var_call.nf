include { PREPARE_REFERENCE; PREPARE_ALIGNMENT_REFERENCE } from './prepare_reference'
include { CALLABLE_REGIONS } from './callable_regions'
include { FILTER_VARIANTS } from './filter_variants'

include { TRIM_READS } from '../modules/local/trim_reads'
include { BWA_MEM } from '../modules/local/bwa_mem'
include { BWA_MEM_SE } from '../modules/local/bwa_mem_se'
include { BWA_MEM_CRAM } from '../modules/local/bwa_mem_cram'
include { BWA_MEM_SE_CRAM } from '../modules/local/bwa_mem_se_cram'
include { ADD_RGS } from '../modules/local/add_rgs'
include { PREPARE_CRAM_SAMTOOLS } from '../modules/local/prepare_cram_samtools'
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
    alignment_format

    main:
    PREPARE_ALIGNMENT_REFERENCE(genome)

    if (skip_trimming) {
        trimmed_reads = read_files
    } else {
        TRIM_READS(read_files)
        trimmed_reads = TRIM_READS.out
    }

    if (alignment_format == 'cram') {
        BWA_MEM_CRAM(genome, PREPARE_ALIGNMENT_REFERENCE.out.bwa_index, trimmed_reads)
        prepared_alignments = BWA_MEM_CRAM.out.alignment
    } else {
        BWA_MEM(genome, PREPARE_ALIGNMENT_REFERENCE.out.bwa_index, trimmed_reads)
        SORT_BAM_SAMBAMBA(BWA_MEM.out)
        MARK_DUPES_SAMBAMBA(SORT_BAM_SAMBAMBA.out)
        prepared_alignments = MARK_DUPES_SAMBAMBA.out.bam
    }

    CALLABLE_REGIONS(prepared_alignments, params.min_depth, PREPARE_ALIGNMENT_REFERENCE.out.fasta_index, dataset_id)

    bam_list = prepared_alignments
        .map { meta, alignment, alignment_index -> alignment }
        .collect()

    staged_bams = prepared_alignments
        .map { meta, alignment, alignment_index -> [alignment, alignment_index] }
        .collect()

    FREEBAYES_PARALLEL(genome, PREPARE_ALIGNMENT_REFERENCE.out.fasta_index, bam_list, dataset_id, staged_bams)
    FILTER_VARIANTS(genome, FREEBAYES_PARALLEL.out, CALLABLE_REGIONS.out.multi_callable_bed, CALLABLE_REGIONS.out.depth_thresholds, PREPARE_ALIGNMENT_REFERENCE.out.fasta_index, repeat_bed)
}

workflow VAR_CALL_ALIGNMENTS {
    take:
    genome
    alignments
    repeat_bed
    species
    dataset_id

    main:
    PREPARE_REFERENCE(genome)

    split_alignments = alignments.branch { meta, alignment, format ->
        bam: format == 'bam'
        cram: format == 'cram'
    }

    if (split_alignments.bam) {
        bam_inputs = split_alignments.bam.map { meta, alignment, format -> [meta, alignment] }
        ADD_RGS(bam_inputs, params.bam_rg_mode)
        SORT_BAM_SAMBAMBA(ADD_RGS.out)
        MARK_DUPES_SAMBAMBA(SORT_BAM_SAMBAMBA.out)
        prepared_bams = MARK_DUPES_SAMBAMBA.out.bam
    } else {
        prepared_bams = Channel.empty()
    }

    if (split_alignments.cram) {
        cram_inputs = split_alignments.cram.map { meta, alignment, format -> [meta, alignment] }
        PREPARE_CRAM_SAMTOOLS(genome, cram_inputs, params.bam_rg_mode)
        prepared_crams = PREPARE_CRAM_SAMTOOLS.out.alignment
    } else {
        prepared_crams = Channel.empty()
    }

    prepared_alignments = prepared_bams.mix(prepared_crams)

    CALLABLE_REGIONS(prepared_alignments, params.min_depth, PREPARE_REFERENCE.out.fasta_index, dataset_id)

    bam_list = prepared_alignments
        .map { meta, alignment, alignment_index -> alignment }
        .collect()

    staged_bams = prepared_alignments
        .map { meta, alignment, alignment_index -> [alignment, alignment_index] }
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
    alignment_format

    main:
    PREPARE_ALIGNMENT_REFERENCE(genome)

    if (alignment_format == 'cram') {
        BWA_MEM_SE_CRAM(genome, PREPARE_ALIGNMENT_REFERENCE.out.bwa_index, reads)
        prepared_alignments = BWA_MEM_SE_CRAM.out.alignment
    } else {
        BWA_MEM_SE(genome, PREPARE_ALIGNMENT_REFERENCE.out.bwa_index, reads)
        SORT_BAM_SAMBAMBA(BWA_MEM_SE.out)
        MARK_DUPES_SAMBAMBA(SORT_BAM_SAMBAMBA.out)
        prepared_alignments = MARK_DUPES_SAMBAMBA.out.bam
    }

    CALLABLE_REGIONS(prepared_alignments, params.min_depth, PREPARE_ALIGNMENT_REFERENCE.out.fasta_index, dataset_id)

    bam_list = prepared_alignments
        .map { meta, alignment, alignment_index -> alignment }
        .collect()

    staged_bams = prepared_alignments
        .map { meta, alignment, alignment_index -> [alignment, alignment_index] }
        .collect()

    FREEBAYES_PARALLEL(genome, PREPARE_ALIGNMENT_REFERENCE.out.fasta_index, bam_list, dataset_id, staged_bams)
    FILTER_VARIANTS(genome, FREEBAYES_PARALLEL.out, CALLABLE_REGIONS.out.multi_callable_bed, CALLABLE_REGIONS.out.depth_thresholds, PREPARE_ALIGNMENT_REFERENCE.out.fasta_index, repeat_bed)
}
