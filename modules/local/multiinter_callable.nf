process MULTIINTER_CALLABLE {
    tag "$species"
    publishDir "${params.outdir}/bed", mode: 'copy'

    memory '4 GB'

    input:
    path(beds, stageAs: 'inputs/*.bed')
    path(sample_name_files, stageAs: 'samples/*.txt')
    path(genome_index)
    val(species)

    output:
    tuple val(species), path("${species}.callable.multiinter.bed"), emit: multi_callable
    tuple val(species), path("${species}.callable.all_samples.bed"), emit: joint_callable
    tuple val(species), path("${species}.callable.samples.txt"), emit: sample_names

    script:
    """
    mapfile -t SAMPLE_NAMES < <(cat samples/*.txt)
    QUOTED_NAMES="\$(printf "'%s' " "\${SAMPLE_NAMES[@]}")"
    N_FILES="\$(ls inputs/*.bed | wc -l)"

    printf '%s\\n' "\${SAMPLE_NAMES[@]}" > ${species}.callable.samples.txt
    eval bedtools multiinter -names \$QUOTED_NAMES -i inputs/*.bed \
        | bedtools sort -faidx ${genome_index} \
        > ${species}.callable.multiinter.bed
    awk -v var=\$N_FILES '\$4==var {print \$1"\\t"\$2"\\t"\$3}' ${species}.callable.multiinter.bed \
        | bedtools sort -faidx ${genome_index} \
        | bedtools merge \
        > ${species}.callable.all_samples.bed
    """
}
