process GENERATE_PASS_VCF {
    tag "$species"

    input:
    tuple val(species), path(vcf_f)

    output:
    tuple val(species), path("${vcf_f.baseName}.hard_filtered.vcf.gz")

    script:
    """
    bcftools view --threads ${task.cpus} -Oz -f "PASS" ${vcf_f} > ${vcf_f.baseName}.hard_filtered.vcf.gz
    """
}
