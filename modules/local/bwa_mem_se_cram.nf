process BWA_MEM_SE_CRAM {
    tag "$meta"
    label 'align_reads'

    memory '8 GB'

    input:
    path(genome_f)
    path(genome_index)
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta}.name_sorted.bam")

    script:
    """
    set -euo pipefail
    bwa mem \
        -t ${task.cpus} \
        -R "@RG\tID:${meta}\tSM:${meta}\tPL:ILLUMINA\tPU:${meta}\tLB:${meta}\tDS:${meta}" \
        ${genome_f} \
        ${reads} \
      | samtools sort -@ ${task.cpus} -n -T ${meta}.name_sort -O bam -o ${meta}.name_sorted.bam -
    """
}
