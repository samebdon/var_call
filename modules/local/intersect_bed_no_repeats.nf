process INTERSECT_BED_NO_REPEATS {
    tag "$species"
    publishDir "${params.outdir}/bed", mode: 'copy'

    memory '4 GB'

    input:
    path(bed)
    path(genome_index)
    val(species)

    output:
    tuple val(species), path("${species}.callable.freebayes.norepeats.bed")

    script:
    """
    bedtools sort -faidx ${genome_index} -i ${bed} |         bedtools merge > ${species}.callable.freebayes.norepeats.bed
    """
}
