process PREPARE_CRAM_SAMTOOLS {
    tag "$meta"
    publishDir "${params.outdir}/crams", mode: 'copy'

    memory '8 GB'

    input:
    path(genome)
    tuple val(meta), path(alignment_f)
    val(bam_rg_mode)

    output:
    tuple val(meta), path("${meta}.deduped.cram"), path("${meta}.deduped.cram.crai"), emit: alignment

    script:
    def rg_mode = bam_rg_mode == 'overwrite' ? 'overwrite_all' : 'orphan_only'
    """
    samtools addreplacerg -@ ${task.cpus} \
        -m ${rg_mode} \
        -r ID:${meta} \
        -r SM:${meta} \
        -r LB:${meta} \
        -r PL:ILLUMINA \
        -r PU:${meta} \
        -o ${meta}.rg.cram \
        ${alignment_f}
    samtools sort -@ ${task.cpus} -n -T ${meta}.name_sort -O bam -o ${meta}.name_sorted.bam ${meta}.rg.cram
    samtools fixmate -@ ${task.cpus} -m ${meta}.name_sorted.bam ${meta}.fixmate.bam
    samtools sort -@ ${task.cpus} -T ${meta}.coord_sort -O bam -o ${meta}.coord_sorted.bam ${meta}.fixmate.bam
    samtools markdup -@ ${task.cpus} ${meta}.coord_sorted.bam ${meta}.deduped.bam
    samtools view -@ ${task.cpus} -T ${genome} -C -o ${meta}.deduped.cram ${meta}.deduped.bam
    samtools index -@ ${task.cpus} ${meta}.deduped.cram
    """
}
