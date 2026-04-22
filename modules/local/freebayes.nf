process FREEBAYES {
    tag "$meta"

    memory '20 GB'
    cpus 1

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
