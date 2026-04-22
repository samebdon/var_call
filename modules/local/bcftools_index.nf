process BCFTOOLS_INDEX {
    tag "$meta"
    publishDir "${params.outdir}/vcf", mode: 'copy'

    cpus 1

    input:
    tuple val(meta), path(vcf_f)

    output:
    tuple val(meta), path("${vcf_f}.csi")

    script:
    """
    bcftools index -c ${vcf_f} -o ${vcf_f}.csi
    """
}
