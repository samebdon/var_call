process SORT_NAME_SAMTOOLS {
    tag "$meta"

    input:
    tuple val(meta), path(alignment_f)

    output:
    tuple val(meta), path("${meta}.name_sorted.bam")

    script:
    def sort_mem_mb = Math.max(768, ((task.memory.mega * 0.75) / task.cpus).intValue())
    """
    set -euo pipefail
    mkdir -p ${meta}.sort_tmp
    samtools sort -@ ${task.cpus} -m ${sort_mem_mb}M -n -T ${meta}.sort_tmp/${meta}.name_sort -O bam -o ${meta}.name_sorted.bam ${alignment_f}
    rm -rf ${meta}.sort_tmp
    """
}
