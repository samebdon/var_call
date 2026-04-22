process GENERATE_FAIL_BED {
    tag "$species"
    publishDir "${params.outdir}/bed", mode: 'copy'

    memory '4 GB'

    input:
    tuple val(species), path(vcf_f)
    path(genome_index)

    output:
    tuple val(species), path("${species}.vcf_filter_fails.bed")

    script:
    """
    bcftools view --threads ${task.cpus} -H -i "FILTER!='PASS'" ${vcf_f} |     perl -lane '\$pad=0; print(\$F[0]."\t".(\$F[1]-1)."\t".((\$F[1]-1)+length(\$F[3]))."\t".\$F[6])' |     bedtools sort -faidx ${genome_index} |     bedtools merge > ${species}.vcf_filter_fails.bed
    """
}
