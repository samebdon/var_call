process BWA_MEM_SE_CRAM {
    tag "$meta"
    publishDir "${params.outdir}/crams", mode: 'copy'

    memory '8 GB'

    input:
    path(genome_f)
    path(genome_index)
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta}.deduped.cram"), path("${meta}.deduped.cram.crai"), emit: alignment

    script:
    """
    bwa mem \
        -t ${task.cpus} \
        -R "@RG\tID:${meta}\tSM:${meta}\tPL:ILLUMINA\tPU:${meta}\tLB:${meta}\tDS:${meta}" \
        ${genome_f} \
        ${reads} \
      | samtools sort -@ ${task.cpus} -n -T ${meta}.name_sort -O bam -o ${meta}.name_sorted.bam -
    samtools fixmate -@ ${task.cpus} -m ${meta}.name_sorted.bam ${meta}.fixmate.bam
    samtools sort -@ ${task.cpus} -T ${meta}.coord_sort -O bam -o ${meta}.coord_sorted.bam ${meta}.fixmate.bam
    samtools markdup -@ ${task.cpus} ${meta}.coord_sorted.bam ${meta}.deduped.bam
    samtools view -@ ${task.cpus} -T ${genome_f} -C -o ${meta}.deduped.cram ${meta}.deduped.bam
    samtools index -@ ${task.cpus} ${meta}.deduped.cram
    """
}
