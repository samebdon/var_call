process ADD_RGS_SAMTOOLS {
    tag "$meta"

    input:
    tuple val(meta), path(alignment_f)
    val(bam_rg_mode)

    output:
    tuple val(meta), path("${meta}.rg.cram")

    script:
    def rg_mode = bam_rg_mode == 'overwrite' ? 'overwrite_all' : 'orphan_only'
    """
    set -euo pipefail
    samtools addreplacerg -@ ${task.cpus} \
        -m ${rg_mode} \
        -r ID:${meta} \
        -r SM:${meta} \
        -r LB:${meta} \
        -r PL:ILLUMINA \
        -r PU:${meta} \
        -o ${meta}.rg.cram \
        ${alignment_f}
    """
}
