process BCFTOOLS_SORT {
    tag "$species"
    publishDir "${params.outdir}/vcf", mode: 'copy'

    cpus 1

    input:
    tuple val(species), path(vcf_f)

    output:
    tuple val(species), path("${species}.hard_filtered.sorted.vcf.gz")

    script:
    """
    bcftools sort -Oz ${vcf_f} > ${species}.hard_filtered.sorted.vcf.gz
    """
}
