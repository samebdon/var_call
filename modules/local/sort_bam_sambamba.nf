process SORT_BAM_SAMBAMBA {
    tag "$meta"
    publishDir "${params.outdir}/bams", mode: 'copy'

    memory '8 GB'

    input:
    tuple val(meta), path(bam_f)

    output:
    tuple val(meta), path("${bam_f.baseName}.coord_sorted.bam")

    script:
    def avail_mem = (task.memory.mega * 1).intValue()
    """
    sambamba sort -t ${task.cpus} -m ${avail_mem}MB -o ${bam_f.baseName}.coord_sorted.bam ${bam_f}
    """
}
