process BEDTOOLS_SUBTRACT {
    tag "$species"
    publishDir "${params.outdir}/bed", mode: 'copy'

    cpus 1

    input:
    tuple val(species), path(a_bed)
    tuple val(species), path(b_bed)
    path(genome_index)

    output:
    tuple val(species), path("${species}.callable.bed")

    script:
    """
    bedtools subtract -a ${a_bed} -b ${b_bed} |         bedtools sort -faidx ${genome_index} |         bedtools merge > ${species}.callable.bed
    """
}
