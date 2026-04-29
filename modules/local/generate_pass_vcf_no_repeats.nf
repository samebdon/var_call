process GENERATE_PASS_VCF_NO_REPEATS {
    tag "$species"

    input:
    tuple val(species), path(vcf_f)
    path(repeat_bed)

    output:
    tuple val(species), path("${vcf_f.baseName}.hard_filtered.vcf.gz")

    script:
    """
    bcftools view --threads ${task.cpus} -f PASS -Ou ${vcf_f}         | bcftools view --threads ${task.cpus} -T ^${repeat_bed} -Oz         > ${vcf_f.baseName}.hard_filtered.vcf.gz
    """
}
