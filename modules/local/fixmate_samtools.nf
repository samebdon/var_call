process FIXMATE_SAMTOOLS {
    tag "$meta"

    input:
    tuple val(meta), path(bam_f)

    output:
    tuple val(meta), path("${meta}.fixmate.bam")

    script:
    """
    set -euo pipefail
    samtools fixmate -@ ${task.cpus} -m ${bam_f} ${meta}.fixmate.bam
    """
}
