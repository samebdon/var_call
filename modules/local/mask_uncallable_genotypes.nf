process MASK_UNCALLABLE_GENOTYPES {
    tag "$species"

    input:
    tuple val(species), path(vcf_f)
    tuple val(bed_species), path(multi_callable_bed)
    tuple val(sample_species), path(callable_samples)

    output:
    tuple val(species), path("${vcf_f.baseName}.callable_masked.vcf.gz")

    when:
    species == bed_species && species == sample_species

    script:
    """
    mask_uncallable_genotypes.py         --vcf ${vcf_f}         --multiinter-bed ${multi_callable_bed}         --sample-names ${callable_samples}         | bgzip -c > ${vcf_f.baseName}.callable_masked.vcf.gz
    """
}
