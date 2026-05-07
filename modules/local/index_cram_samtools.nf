process INDEX_CRAM_SAMTOOLS {
    tag "$meta"

    input:
    tuple val(meta), path(cram_f)

    output:
    tuple val(meta), path("${cram_f}.crai")

    script:
    """
    set -euo pipefail
    samtools index -@ ${task.cpus} ${cram_f}
    """
}
