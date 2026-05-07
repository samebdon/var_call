process MARK_DUPES_SAMTOOLS {
    tag "$meta"

    input:
    tuple val(meta), path(bam_f)

    output:
    tuple val(meta), path("${meta}.deduped.bam")

    script:
    """
    set -euo pipefail
    samtools markdup -@ ${task.cpus} ${bam_f} ${meta}.deduped.bam
    """
}
