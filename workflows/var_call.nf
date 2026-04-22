include { PREPARE_REFERENCE } from './prepare_reference'
include { CALLABLE_REGIONS } from './callable_regions'
include { FILTER_VARIANTS } from './filter_variants'

include { TRIM_READS } from '../modules/local/trim_reads'
include { BWA_MEM } from '../modules/local/bwa_mem'
include { BWA_MEM_SE } from '../modules/local/bwa_mem_se'
include { ADD_RGS } from '../modules/local/add_rgs'
include { SORT_BAM_SAMBAMBA } from '../modules/local/sort_bam_sambamba'
include { MARK_DUPES_SAMBAMBA } from '../modules/local/mark_dupes_sambamba'
include { INDEX_BAM_SAMBAMBA } from '../modules/local/index_bam_sambamba'
include { SAMBAMBA_MERGE } from '../modules/local/sambamba_merge'
include { FREEBAYES } from '../modules/local/freebayes'

workflow VAR_CALL_PAIRED {
    take:
    genome
    read_files
    repeat_bed
    species
    dataset_id
    skip_trimming

    main:
    PREPARE_REFERENCE(genome)

    if (skip_trimming) {
        trimmed_reads = read_files
    } else {
        TRIM_READS(read_files)
        trimmed_reads = TRIM_READS.out
    }

    BWA_MEM(genome, PREPARE_REFERENCE.out.bwa_index, trimmed_reads)
    SORT_BAM_SAMBAMBA(BWA_MEM.out)
    MARK_DUPES_SAMBAMBA(SORT_BAM_SAMBAMBA.out)
    INDEX_BAM_SAMBAMBA(MARK_DUPES_SAMBAMBA.out.meta_bam)
    aligned_bams = MARK_DUPES_SAMBAMBA.out.meta_bam.join(INDEX_BAM_SAMBAMBA.out)
    CALLABLE_REGIONS(aligned_bams, params.min_depth, repeat_bed, PREPARE_REFERENCE.out.fasta_index, dataset_id)
    SAMBAMBA_MERGE(MARK_DUPES_SAMBAMBA.out.bam_only.collect(), dataset_id)
    FREEBAYES(genome, PREPARE_REFERENCE.out.fasta_index, SAMBAMBA_MERGE.out, CALLABLE_REGIONS.out.callable_bed)
    FILTER_VARIANTS(genome, FREEBAYES.out, CALLABLE_REGIONS.out.callable_bed, PREPARE_REFERENCE.out.fasta_index)
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

    bams
        .map { bam ->
            def prefix = bam.baseName.tokenize('.')[0]
            [prefix, bam]
        }
        .set { bam_ch }

    ADD_RGS(bam_ch)
    SORT_BAM_SAMBAMBA(ADD_RGS.out)
    MARK_DUPES_SAMBAMBA(SORT_BAM_SAMBAMBA.out)
    INDEX_BAM_SAMBAMBA(MARK_DUPES_SAMBAMBA.out.meta_bam)
    aligned_bams = MARK_DUPES_SAMBAMBA.out.meta_bam.join(INDEX_BAM_SAMBAMBA.out)
    CALLABLE_REGIONS(aligned_bams, params.min_depth, repeat_bed, PREPARE_REFERENCE.out.fasta_index, dataset_id)
    SAMBAMBA_MERGE(MARK_DUPES_SAMBAMBA.out.bam_only.collect(), dataset_id)
    FREEBAYES(genome, PREPARE_REFERENCE.out.fasta_index, SAMBAMBA_MERGE.out, CALLABLE_REGIONS.out.callable_bed)
    FILTER_VARIANTS(genome, FREEBAYES.out, CALLABLE_REGIONS.out.callable_bed, PREPARE_REFERENCE.out.fasta_index)
}

workflow VAR_CALL_SINGLE_END {
    take:
    genome
    reads
    repeat_bed
    species
    dataset_id

    main:
    PREPARE_REFERENCE(genome)

    BWA_MEM_SE(genome, PREPARE_REFERENCE.out.bwa_index, reads)
    SORT_BAM_SAMBAMBA(BWA_MEM_SE.out)
    MARK_DUPES_SAMBAMBA(SORT_BAM_SAMBAMBA.out)
    INDEX_BAM_SAMBAMBA(MARK_DUPES_SAMBAMBA.out.meta_bam)
    aligned_bams = MARK_DUPES_SAMBAMBA.out.meta_bam.join(INDEX_BAM_SAMBAMBA.out)
    CALLABLE_REGIONS(aligned_bams, params.min_depth, repeat_bed, PREPARE_REFERENCE.out.fasta_index, dataset_id)
    SAMBAMBA_MERGE(MARK_DUPES_SAMBAMBA.out.bam_only.collect(), dataset_id)
    FREEBAYES(genome, PREPARE_REFERENCE.out.fasta_index, SAMBAMBA_MERGE.out, CALLABLE_REGIONS.out.callable_bed)
    FILTER_VARIANTS(genome, FREEBAYES.out, CALLABLE_REGIONS.out.callable_bed, PREPARE_REFERENCE.out.fasta_index)
}
