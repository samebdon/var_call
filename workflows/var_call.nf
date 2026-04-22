include {
    TRIM_READS
    BWA_INDEX
    BWA_MEM
    BWA_MEM_SE
    ADD_RGS
    SORT_BAM_SAMBAMBA
    MARK_DUPES_SAMBAMBA
    INDEX_BAM_SAMBAMBA
    MOSDEPTH_CALLABLE
    INTERSECT_BEDS
    INTERSECT_BEDS_NO_REPEATS
    INTERSECT_BED
    INTERSECT_BED_NO_REPEATS
    SAMBAMBA_MERGE
    FREEBAYES
    BCFTOOLS_FILTER
    GENERATE_FAIL_BED
    GENERATE_PASS_VCF
    BEDTOOLS_SUBTRACT
    BCFTOOLS_SORT
    BCFTOOLS_INDEX
} from '../modules/local/var_call'

def selectMultiSampleCallableBeds(mosdepth_beds, repeat_bed, genome_index, species) {
    if (repeat_bed) {
        INTERSECT_BEDS(mosdepth_beds, repeat_bed, genome_index, species)
        return INTERSECT_BEDS.out.freebayes
    }

    INTERSECT_BEDS_NO_REPEATS(mosdepth_beds, genome_index, species)
    return INTERSECT_BEDS_NO_REPEATS.out.freebayes
}

def selectSingleSampleCallableBed(mosdepth_bed, repeat_bed, genome_index, species) {
    if (repeat_bed) {
        INTERSECT_BED(mosdepth_bed, repeat_bed, genome_index, species)
        return INTERSECT_BED.out
    }

    INTERSECT_BED_NO_REPEATS(mosdepth_bed, genome_index, species)
    return INTERSECT_BED_NO_REPEATS.out
}

workflow VAR_CALL_PAIRED {
    take:
    genome
    genome_index
    read_files
    repeat_bed
    species
    dataset_id
    skip_trimming

    main:
    BWA_INDEX(genome)
    if (skip_trimming) {
        trimmed_reads = read_files
    } else {
        TRIM_READS(read_files)
        trimmed_reads = TRIM_READS.out
    }
    BWA_MEM(genome, BWA_INDEX.out, trimmed_reads)
    SORT_BAM_SAMBAMBA(BWA_MEM.out)
    MARK_DUPES_SAMBAMBA(SORT_BAM_SAMBAMBA.out)
    INDEX_BAM_SAMBAMBA(MARK_DUPES_SAMBAMBA.out.meta_bam)
    MOSDEPTH_CALLABLE(MARK_DUPES_SAMBAMBA.out.meta_bam.join(INDEX_BAM_SAMBAMBA.out), params.min_depth)
    callable_bed = selectMultiSampleCallableBeds(MOSDEPTH_CALLABLE.out.collect(), repeat_bed, genome_index, dataset_id)
    SAMBAMBA_MERGE(MARK_DUPES_SAMBAMBA.out.bam_only.collect(), dataset_id)
    FREEBAYES(genome, genome_index, SAMBAMBA_MERGE.out, callable_bed)
    BCFTOOLS_FILTER(genome, FREEBAYES.out)
    GENERATE_FAIL_BED(BCFTOOLS_FILTER.out, genome_index)
    GENERATE_PASS_VCF(BCFTOOLS_FILTER.out)
    BEDTOOLS_SUBTRACT(callable_bed, GENERATE_FAIL_BED.out, genome_index)
    BCFTOOLS_SORT(GENERATE_PASS_VCF.out)
    BCFTOOLS_INDEX(BCFTOOLS_SORT.out)
}

workflow VAR_CALL_BAMS {
    take:
    genome
    genome_index
    bams
    repeat_bed
    species
    dataset_id

    main:
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
    MOSDEPTH_CALLABLE(MARK_DUPES_SAMBAMBA.out.meta_bam.join(INDEX_BAM_SAMBAMBA.out), params.min_depth)
    callable_bed = selectMultiSampleCallableBeds(MOSDEPTH_CALLABLE.out.collect(), repeat_bed, genome_index, dataset_id)
    SAMBAMBA_MERGE(MARK_DUPES_SAMBAMBA.out.bam_only.collect(), dataset_id)
    FREEBAYES(genome, genome_index, SAMBAMBA_MERGE.out, callable_bed)
    BCFTOOLS_FILTER(genome, FREEBAYES.out)
    GENERATE_FAIL_BED(BCFTOOLS_FILTER.out, genome_index)
    GENERATE_PASS_VCF(BCFTOOLS_FILTER.out)
    BEDTOOLS_SUBTRACT(callable_bed, GENERATE_FAIL_BED.out, genome_index)
    BCFTOOLS_SORT(GENERATE_PASS_VCF.out)
    BCFTOOLS_INDEX(BCFTOOLS_SORT.out)
}

workflow VAR_CALL_SINGLE_PAIRED {
    take:
    genome
    genome_index
    read_files
    repeat_bed
    species
    dataset_id
    skip_trimming

    main:
    BWA_INDEX(genome)
    if (skip_trimming) {
        trimmed_reads = read_files
    } else {
        TRIM_READS(read_files)
        trimmed_reads = TRIM_READS.out
    }
    BWA_MEM(genome, BWA_INDEX.out, trimmed_reads)
    SORT_BAM_SAMBAMBA(BWA_MEM.out)
    MARK_DUPES_SAMBAMBA(SORT_BAM_SAMBAMBA.out)
    INDEX_BAM_SAMBAMBA(MARK_DUPES_SAMBAMBA.out.meta_bam)
    MOSDEPTH_CALLABLE(MARK_DUPES_SAMBAMBA.out.meta_bam.join(INDEX_BAM_SAMBAMBA.out), params.min_depth)
    callable_bed = selectSingleSampleCallableBed(MOSDEPTH_CALLABLE.out, repeat_bed, genome_index, dataset_id)
    FREEBAYES(genome, genome_index, MARK_DUPES_SAMBAMBA.out.meta_bam.join(INDEX_BAM_SAMBAMBA.out), callable_bed)
    BCFTOOLS_FILTER(genome, FREEBAYES.out)
    GENERATE_FAIL_BED(BCFTOOLS_FILTER.out, genome_index)
    GENERATE_PASS_VCF(BCFTOOLS_FILTER.out)
    BEDTOOLS_SUBTRACT(callable_bed, GENERATE_FAIL_BED.out, genome_index)
    BCFTOOLS_SORT(GENERATE_PASS_VCF.out)
    BCFTOOLS_INDEX(BCFTOOLS_SORT.out)
}

workflow VAR_CALL_SINGLE_END {
    take:
    genome
    genome_index
    reads
    repeat_bed
    species
    dataset_id

    main:
    BWA_INDEX(genome)
    BWA_MEM_SE(genome, BWA_INDEX.out, reads)
    SORT_BAM_SAMBAMBA(BWA_MEM_SE.out)
    MARK_DUPES_SAMBAMBA(SORT_BAM_SAMBAMBA.out)
    INDEX_BAM_SAMBAMBA(MARK_DUPES_SAMBAMBA.out.meta_bam)
    MOSDEPTH_CALLABLE(MARK_DUPES_SAMBAMBA.out.meta_bam.join(INDEX_BAM_SAMBAMBA.out), params.min_depth)
    callable_bed = selectSingleSampleCallableBed(MOSDEPTH_CALLABLE.out, repeat_bed, genome_index, dataset_id)
    FREEBAYES(genome, genome_index, MARK_DUPES_SAMBAMBA.out.meta_bam.join(INDEX_BAM_SAMBAMBA.out), callable_bed)
    BCFTOOLS_FILTER(genome, FREEBAYES.out)
    GENERATE_FAIL_BED(BCFTOOLS_FILTER.out, genome_index)
    GENERATE_PASS_VCF(BCFTOOLS_FILTER.out)
    BEDTOOLS_SUBTRACT(callable_bed, GENERATE_FAIL_BED.out, genome_index)
    BCFTOOLS_SORT(GENERATE_PASS_VCF.out)
    BCFTOOLS_INDEX(BCFTOOLS_SORT.out)
}
