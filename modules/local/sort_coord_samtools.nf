process SORT_COORD_SAMTOOLS {
    tag "$meta"

    input:
    tuple val(meta), path(bam_f)

    output:
    tuple val(meta), path("${meta}.coord_sorted.bam")

    script:
    """
    set -euo pipefail
    samtools sort -@ ${task.cpus} -T ${meta}.coord_sort -O bam -o ${meta}.coord_sorted.bam ${bam_f}
    """
}
