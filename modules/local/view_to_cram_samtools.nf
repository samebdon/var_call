process VIEW_TO_CRAM_SAMTOOLS {
    tag "$meta"
    publishDir "${params.outdir}/crams", mode: 'copy'

    input:
    path(genome)
    tuple val(meta), path(bam_f)

    output:
    tuple val(meta), path("${meta}.deduped.cram")

    script:
    """
    set -euo pipefail
    samtools view -@ ${task.cpus} -T ${genome} -C -o ${meta}.deduped.cram ${bam_f}
    """
}
