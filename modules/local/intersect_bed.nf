process INTERSECT_BED {
    tag "$species"
    publishDir "${params.outdir}/bed", mode: 'copy'

    memory '4 GB'

    input:
    tuple val(species), path(bed)
    path(repeat_bed)
    path(genome_index)

    output:
    tuple val(species), path("${species}.callable.freebayes.norepeats.bed")

    script:
    """
    bedtools subtract -a ${bed} -b ${repeat_bed}         | bedtools sort -faidx ${genome_index}         | bedtools merge         > ${species}.callable.freebayes.norepeats.bed
    """
}
