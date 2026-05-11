include { PREPARE_REFERENCE; PREPARE_ALIGNMENT_REFERENCE } from './prepare_reference'
include { CALLABLE_REGIONS } from './callable_regions'
include { FILTER_VARIANTS } from './filter_variants'

include { TRIM_READS } from '../modules/local/trim_reads'
include { BWA_MEM } from '../modules/local/bwa_mem'
include { BWA_MEM_SE } from '../modules/local/bwa_mem_se'
include { BWA_MEM_CRAM } from '../modules/local/bwa_mem_cram'
include { BWA_MEM_SE_CRAM } from '../modules/local/bwa_mem_se_cram'
include { READS_CRAM_TO_FASTQ_PAIRED } from '../modules/local/reads_cram_to_fastq_paired'
include { READS_CRAM_TO_FASTQ_SINGLE } from '../modules/local/reads_cram_to_fastq_single'
include { ADD_RGS } from '../modules/local/add_rgs'
include { ADD_RGS_SAMTOOLS } from '../modules/local/add_rgs_samtools'
include { SORT_NAME_SAMTOOLS } from '../modules/local/sort_name_samtools'
include { FIXMATE_SAMTOOLS } from '../modules/local/fixmate_samtools'
include { SORT_COORD_SAMTOOLS } from '../modules/local/sort_coord_samtools'
include { MARK_DUPES_SAMTOOLS } from '../modules/local/mark_dupes_samtools'
include { VIEW_TO_CRAM_SAMTOOLS } from '../modules/local/view_to_cram_samtools'
include { INDEX_CRAM_SAMTOOLS } from '../modules/local/index_cram_samtools'
include { SORT_BAM_SAMBAMBA } from '../modules/local/sort_bam_sambamba'
include { MARK_DUPES_SAMBAMBA } from '../modules/local/mark_dupes_sambamba'
include { VALIDATE_ALIGNMENT } from '../modules/local/validate_alignment'
include { MERGE_SAMPLE_STATUS } from '../modules/local/merge_sample_status'
include { FREEBAYES_PARALLEL } from '../modules/local/freebayes'

workflow VAR_CALL_PAIRED {
    take:
    genome
    read_files
    repeat_bed
    species
    dataset_id
    skip_trimming
    read_format
    alignment_format

    main:
    PREPARE_ALIGNMENT_REFERENCE(genome)

    if (read_format == 'cram') {
        READS_CRAM_TO_FASTQ_PAIRED(read_files)
        input_reads = READS_CRAM_TO_FASTQ_PAIRED.out
    } else {
        input_reads = read_files
    }

    if (skip_trimming) {
        trimmed_reads = input_reads
    } else {
        TRIM_READS(input_reads)
        trimmed_reads = TRIM_READS.out
    }

    if (alignment_format == 'cram') {
        BWA_MEM_CRAM(genome, PREPARE_ALIGNMENT_REFERENCE.out.bwa_index, trimmed_reads)
        alignment_status = BWA_MEM_CRAM.out.status
        FIXMATE_SAMTOOLS(BWA_MEM_CRAM.out.alignment)
        SORT_COORD_SAMTOOLS(FIXMATE_SAMTOOLS.out)
        MARK_DUPES_SAMTOOLS(SORT_COORD_SAMTOOLS.out)
        VIEW_TO_CRAM_SAMTOOLS(genome, MARK_DUPES_SAMTOOLS.out)
        INDEX_CRAM_SAMTOOLS(VIEW_TO_CRAM_SAMTOOLS.out)
        prepared_alignments = VIEW_TO_CRAM_SAMTOOLS.out.join(INDEX_CRAM_SAMTOOLS.out).map { meta, cram_f, crai_f -> [meta, cram_f, crai_f] }
    } else {
        BWA_MEM(genome, PREPARE_ALIGNMENT_REFERENCE.out.bwa_index, trimmed_reads)
        alignment_status = BWA_MEM.out.status
        SORT_BAM_SAMBAMBA(BWA_MEM.out.alignment)
        MARK_DUPES_SAMBAMBA(SORT_BAM_SAMBAMBA.out)
        prepared_alignments = MARK_DUPES_SAMBAMBA.out.bam
    }

    VALIDATE_ALIGNMENT(prepared_alignments)
    valid_alignments = VALIDATE_ALIGNMENT.out.valid_alignment
    valid_alignments.ifEmpty { error "No valid alignments available after alignment/preparation checks" }

    CALLABLE_REGIONS(genome, valid_alignments, params.min_depth, PREPARE_ALIGNMENT_REFERENCE.out.fasta_index, dataset_id)

    status_files = alignment_status.map { meta, status -> status }
        .mix(VALIDATE_ALIGNMENT.out.status.map { meta, status -> status })
        .mix(CALLABLE_REGIONS.out.callable_status.map { meta, status -> status })
        .collect()
    MERGE_SAMPLE_STATUS(status_files, dataset_id)

    bam_list = valid_alignments.map { meta, alignment, alignment_index -> alignment }.collect()
    staged_bams = valid_alignments.map { meta, alignment, alignment_index -> [alignment, alignment_index] }.collect()

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
        ADD_RGS_SAMTOOLS(cram_inputs, params.bam_rg_mode)
        SORT_NAME_SAMTOOLS(ADD_RGS_SAMTOOLS.out)
        FIXMATE_SAMTOOLS(SORT_NAME_SAMTOOLS.out)
        SORT_COORD_SAMTOOLS(FIXMATE_SAMTOOLS.out)
        MARK_DUPES_SAMTOOLS(SORT_COORD_SAMTOOLS.out)
        VIEW_TO_CRAM_SAMTOOLS(genome, MARK_DUPES_SAMTOOLS.out)
        INDEX_CRAM_SAMTOOLS(VIEW_TO_CRAM_SAMTOOLS.out)
        prepared_crams = VIEW_TO_CRAM_SAMTOOLS.out.join(INDEX_CRAM_SAMTOOLS.out).map { meta, cram_f, crai_f -> [meta, cram_f, crai_f] }
    } else {
        prepared_crams = Channel.empty()
    }

    prepared_alignments = prepared_bams.mix(prepared_crams)
    VALIDATE_ALIGNMENT(prepared_alignments)
    valid_alignments = VALIDATE_ALIGNMENT.out.valid_alignment
    valid_alignments.ifEmpty { error "No valid alignments available after preparation checks" }

    CALLABLE_REGIONS(genome, valid_alignments, params.min_depth, PREPARE_REFERENCE.out.fasta_index, dataset_id)

    status_files = VALIDATE_ALIGNMENT.out.status.map { meta, status -> status }
        .mix(CALLABLE_REGIONS.out.callable_status.map { meta, status -> status })
        .collect()
    MERGE_SAMPLE_STATUS(status_files, dataset_id)

    bam_list = valid_alignments.map { meta, alignment, alignment_index -> alignment }.collect()
    staged_bams = valid_alignments.map { meta, alignment, alignment_index -> [alignment, alignment_index] }.collect()

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
    read_format
    alignment_format

    main:
    PREPARE_ALIGNMENT_REFERENCE(genome)

    if (read_format == 'cram') {
        READS_CRAM_TO_FASTQ_SINGLE(reads)
        input_reads = READS_CRAM_TO_FASTQ_SINGLE.out
    } else {
        input_reads = reads
    }

    if (alignment_format == 'cram') {
        BWA_MEM_SE_CRAM(genome, PREPARE_ALIGNMENT_REFERENCE.out.bwa_index, input_reads)
        alignment_status = BWA_MEM_SE_CRAM.out.status
        FIXMATE_SAMTOOLS(BWA_MEM_SE_CRAM.out.alignment)
        SORT_COORD_SAMTOOLS(FIXMATE_SAMTOOLS.out)
        MARK_DUPES_SAMTOOLS(SORT_COORD_SAMTOOLS.out)
        VIEW_TO_CRAM_SAMTOOLS(genome, MARK_DUPES_SAMTOOLS.out)
        INDEX_CRAM_SAMTOOLS(VIEW_TO_CRAM_SAMTOOLS.out)
        prepared_alignments = VIEW_TO_CRAM_SAMTOOLS.out.join(INDEX_CRAM_SAMTOOLS.out).map { meta, cram_f, crai_f -> [meta, cram_f, crai_f] }
    } else {
        BWA_MEM_SE(genome, PREPARE_ALIGNMENT_REFERENCE.out.bwa_index, input_reads)
        alignment_status = BWA_MEM_SE.out.status
        SORT_BAM_SAMBAMBA(BWA_MEM_SE.out.alignment)
        MARK_DUPES_SAMBAMBA(SORT_BAM_SAMBAMBA.out)
        prepared_alignments = MARK_DUPES_SAMBAMBA.out.bam
    }

    VALIDATE_ALIGNMENT(prepared_alignments)
    valid_alignments = VALIDATE_ALIGNMENT.out.valid_alignment
    valid_alignments.ifEmpty { error "No valid alignments available after alignment/preparation checks" }

    CALLABLE_REGIONS(genome, valid_alignments, params.min_depth, PREPARE_ALIGNMENT_REFERENCE.out.fasta_index, dataset_id)

    status_files = alignment_status.map { meta, status -> status }
        .mix(VALIDATE_ALIGNMENT.out.status.map { meta, status -> status })
        .mix(CALLABLE_REGIONS.out.callable_status.map { meta, status -> status })
        .collect()
    MERGE_SAMPLE_STATUS(status_files, dataset_id)

    bam_list = valid_alignments.map { meta, alignment, alignment_index -> alignment }.collect()
    staged_bams = valid_alignments.map { meta, alignment, alignment_index -> [alignment, alignment_index] }.collect()

    FREEBAYES_PARALLEL(genome, PREPARE_ALIGNMENT_REFERENCE.out.fasta_index, bam_list, dataset_id, staged_bams)
    FILTER_VARIANTS(genome, FREEBAYES_PARALLEL.out, CALLABLE_REGIONS.out.multi_callable_bed, CALLABLE_REGIONS.out.depth_thresholds, PREPARE_ALIGNMENT_REFERENCE.out.fasta_index, repeat_bed)
}
