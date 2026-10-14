process MINIBWA_MAP_CRAM {
    tag "$meta"

    input:
    path(genome_f)
    path(genome_index)
    tuple val(meta), path(read1), path(read2)

    output:
    tuple val(meta), path("${meta}.name_sorted.bam"), emit: alignment, optional: true
    tuple val(meta), path("${meta}.alignment_status.tsv"), emit: status

    script:
    def sort_mem_mb = Math.max(768, ((task.memory.mega * 0.75) / task.cpus).intValue())
    """
    set -uo pipefail
    mkdir -p ${meta}.sort_tmp
    if ! minibwa map \
        -t ${task.cpus} \
        -b MD \
        -R "@RG\\tID:${meta}\\tSM:${meta}\\tPL:ILLUMINA\\tPU:${meta}\\tLB:${meta}\\tDS:${meta}" \
        ${genome_f} \
        ${read1} \
        ${read2} \
      | samtools sort -@ ${task.cpus} -m ${sort_mem_mb}M -n -T ${meta}.sort_tmp/${meta}.name_sort -O bam -o ${meta}.name_sorted.bam -; then
        rm -f ${meta}.name_sorted.bam
        rm -rf ${meta}.sort_tmp
        printf '%s\talignment\tfailed\tminibwa_map_failed\n' '${meta}' > ${meta}.alignment_status.tsv
        exit 1
    fi

    if ! samtools quickcheck ${meta}.name_sorted.bam 2>/dev/null; then
        rm -f ${meta}.name_sorted.bam
        printf '%s\talignment\tfailed\tinvalid_name_sorted_bam\n' '${meta}' > ${meta}.alignment_status.tsv
        exit 0
    fi

    READ_COUNT="\$(samtools view -c ${meta}.name_sorted.bam)"
    if [ "\$READ_COUNT" -eq 0 ]; then
        rm -f ${meta}.name_sorted.bam
        printf '%s\talignment\tfailed\tempty_name_sorted_bam\n' '${meta}' > ${meta}.alignment_status.tsv
        exit 0
    fi

    printf '%s\talignment\tok\treads=%s\n' '${meta}' "\$READ_COUNT" > ${meta}.alignment_status.tsv
    rm -rf ${meta}.sort_tmp
    """
}
