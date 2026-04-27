process FREEBAYES {
    tag "$meta"

    input:
    path(genome_f)
    path(genome_index)
    tuple val(meta), path(bam_f), path(bam_index)
    tuple val(species), path(bed_f)

    output:
    tuple val(species), path("${species}.vcf")

    script:
    """
    freebayes -f ${genome_f} -b ${bam_f} -t ${bed_f} --strict-vcf -v ${species}.vcf -T 0.01 -k -w -j -E 1
    """
}

process FREEBAYES_PARALLEL {
    tag "$meta"

    input:
    path(genome_f)
    path(genome_index)
    path(bam_list)
    tuple val(species), path(bed_f)
    path(bams_staged)

    output:
    tuple val(species), path("${species}.vcf.gz")

    script:
    def bam_args = bam_list.collect { bam_file -> "--bam ${bam_file}" }.join(' ')
    """
    freebayes-parallel <(fasta_generate_regions.py ${genome} 100000000) ${task.cpus} \
        -f ${genome} \
        --limit-coverage 250 \
        --use-best-n-alleles 8 \
        --no-population-priors \
        --use-mapping-quality \
        --ploidy 2 \
        --haplotype-length -1 \
        -t ${bed_f} \
        --strict-vcf \
        -E 1 \
        -w \
        -k \
        -j \
        ${bam_args}
      | gzip -c > ${species}.vcf.gz

    """
}
