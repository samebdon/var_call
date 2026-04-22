process INTERSECT_BEDS_NO_REPEATS {
    tag "$species"
    publishDir "${params.outdir}/bed", mode: 'copy'

    memory '4 GB'

    input:
    path(beds, stageAs: 'inputs/*')
    path(genome_index)
    val(species)

    output:
    tuple val(species), path("${species}.callable.all.bed"), emit: all
    tuple val(species), path("${species}.callable.freebayes.norepeats.bed"), emit: freebayes

    script:
    """
    N_FILES="\$(ls inputs/*.bed | wc -l)"
    bedtools multiinter -i inputs/*.bed | cut -f1-5 | bedtools sort -faidx ${genome_index} > ${species}.callable.all.bed
    awk -v var=\$N_FILES '\$4==var' ${species}.callable.all.bed | cut -f1-3 |         bedtools sort -faidx ${genome_index} |         bedtools merge > ${species}.callable.freebayes.norepeats.bed
    """
}
