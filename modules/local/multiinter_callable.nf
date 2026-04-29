process MULTIINTER_CALLABLE {
    tag "$species"
    publishDir "${params.outdir}/bed", mode: 'copy'

    memory '4 GB'

    input:
    tuple val(sample_names), path(beds, stageAs: 'inputs/*')
    path(genome_index)
    val(species)

    output:
    tuple val(species), path("${species}.callable.multiinter.bed"), emit: multi_callable
    tuple val(species), path("${species}.callable.all_samples.bed"), emit: joint_callable
    tuple val(species), path("${species}.callable.samples.txt"), emit: sample_names

    script:
    def quotedNames = sample_names.collect { "'${it.replace("'", "'\''")}'" }.join(' ')
    def escapedNames = sample_names.join("\n")
    """
    N_FILES="\$(ls inputs/*.bed | wc -l)"
    cat <<'EOF' > ${species}.callable.samples.txt
${escapedNames}
EOF
    bedtools multiinter -names ${quotedNames} -i inputs/*.bed         | bedtools sort -faidx ${genome_index}         > ${species}.callable.multiinter.bed
    awk -v var=\$N_FILES '\$4==var {print \$1"\t"\$2"\t"\$3}' ${species}.callable.multiinter.bed         | bedtools sort -faidx ${genome_index}         | bedtools merge         > ${species}.callable.all_samples.bed
    """
}
