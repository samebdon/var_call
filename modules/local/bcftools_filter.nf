process BCFTOOLS_FILTER {
    tag "$species"
    publishDir "${params.outdir}/vcf", mode: 'copy'

    input:
    path(genome)
    tuple val(species), path(vcf_f)

    output:
    tuple val(species), path("${vcf_f.baseName}.soft_filtered.vcf.gz")

    script:
    """
    bcftools norm --threads ${task.cpus} -Ov -f ${genome} ${vcf_f} |     vcfallelicprimitives --keep-info --keep-geno -t decomposed |     bcftools +fill-tags --threads ${task.cpus} -Oz -- -t AN,AC,F_MISSING |     bcftools filter --threads ${task.cpus} -Oz -s Qual -m+ -e 'QUAL<10' |     bcftools filter --threads ${task.cpus} -Oz -s Balance -m+ -e 'RPL<1 | RPR<1 | SAF<1 | SAR<1' |     bcftools filter --threads ${task.cpus} -Oz -m+ -s+ --SnpGap 2 |     bcftools filter --threads ${task.cpus} -Oz -e 'TYPE!="snp"' -s NonSnp -m+ > ${vcf_f.baseName}.soft_filtered.vcf.gz
    """
}
