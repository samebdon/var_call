process SORT_NAME_SAMTOOLS {
    tag "$meta"

    input:
    tuple val(meta), path(alignment_f)

    output:
    tuple val(meta), path("${meta}.name_sorted.bam")

    script:
    """
    set -euo pipefail
    samtools sort -@ ${task.cpus} -n -T ${meta}.name_sort -O bam -o ${meta}.name_sorted.bam ${alignment_f}
    """
}
