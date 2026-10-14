process MINIBWA_MAP {
    tag "$meta"

    input:
    path(genome_f)
    path(genome_index)
    tuple val(meta), path(read1), path(read2)

    output:
    tuple val(meta), path("minibwa/${meta}.${genome_f.baseName}.bam"), emit: alignment, optional: true
    tuple val(meta), path("${meta}.alignment_status.tsv"), emit: status

    script:
    """
    set -uo pipefail
    mkdir -p minibwa
    if ! minibwa map \
        -t ${task.cpus} \
        -b MD \
        -R "@RG\\tID:${meta}\\tSM:${meta}\\tPL:ILLUMINA\\tPU:${meta}\\tLB:${meta}\\tDS:${meta}" \
        ${genome_f} \
        ${read1} \
        ${read2} \
      | sambamba view -t ${task.cpus} -S -f bam /dev/stdin \
      > minibwa/${meta}.${genome_f.baseName}.bam; then
        rm -f minibwa/${meta}.${genome_f.baseName}.bam
        printf '%s\talignment\tfailed\tminibwa_map_failed\n' '${meta}' > ${meta}.alignment_status.tsv
        exit 1
    fi

    if ! samtools quickcheck minibwa/${meta}.${genome_f.baseName}.bam 2>/dev/null; then
        rm -f minibwa/${meta}.${genome_f.baseName}.bam
        printf '%s\talignment\tfailed\tinvalid_bam\n' '${meta}' > ${meta}.alignment_status.tsv
        exit 0
    fi

    READ_COUNT="\$(samtools view -c minibwa/${meta}.${genome_f.baseName}.bam)"
    if [ "\$READ_COUNT" -eq 0 ]; then
        rm -f minibwa/${meta}.${genome_f.baseName}.bam
        printf '%s\talignment\tfailed\tempty_bam\n' '${meta}' > ${meta}.alignment_status.tsv
        exit 0
    fi

    printf '%s\talignment\tok\treads=%s\n' '${meta}' "\$READ_COUNT" > ${meta}.alignment_status.tsv
    """
}
